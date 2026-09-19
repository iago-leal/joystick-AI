import Foundation

/// Estado de um modificador mostrado na página (RF-06): solto, mantido pelo dedo ou preso por toque.
public enum ModifierState: String, Equatable, Sendable {
    case released, held, latched
}

/// Efeito da máquina, executado pelo app no `KeyboardInjector` (D-08, D-09, D-10, D-17).
public enum RemoteKeyboardEffect: Equatable, Sendable {
    case keyDown(UInt16)
    case keyUp(UInt16)
    case modifierDown(KeyModifier)
    case modifierUp(KeyModifier)
    case capsLock(down: Bool)
    case startRepeat(UInt16)
    case stopRepeat
    /// Estado dos quatro modificadores, emitido a cada mudança, para a página.
    case modifiers([KeyModifier: ModifierState])
}

/// Máquina pura do teclado remoto (`008-iphone-teclado-remoto` D-08): pressionar e soltar por código de tecla,
/// modificadores mantidos ou presos (RN-07), repetição só da última tecla comum (RN-09), soltura geral (RN-10),
/// vigia de 1 s (D-11) e contagem de mensagens inválidas seguidas (D-16).
///
/// Cada modificador lógico é injetado uma única vez, ainda que ⌘ esquerdo e direito estejam pressionados juntos; a
/// soma com o controle fica com a contagem do `KeyboardInjector` (RN-08).
public struct RemoteKeyboardMachine: Sendable {
    public static let watchdogNs: UInt64 = 1_000_000_000
    public static let maxInvalidMessages = 5

    public let geometry: RemoteKeyGeometry
    /// Teclas comuns pressionadas.
    public private(set) var regularDown: Set<UInt16> = []
    /// Teclas de modificador pressionadas (esquerda e direita separadas).
    public private(set) var modifierKeysDown: Set<UInt16> = []
    public private(set) var latched: Set<KeyModifier> = []
    public private(set) var capsLockDown = false
    /// Tecla comum cuja soltura solta os modificadores presos.
    public private(set) var pendingLatchRelease: UInt16?
    public private(set) var repeating: UInt16?
    public private(set) var lastMessageNs: UInt64
    /// Teclas pressionadas na sessão, para `remote.disconnected` (D-18).
    public private(set) var keyCount = 0
    public private(set) var invalidInARow = 0

    /// Modificadores injetados no Mac pela máquina.
    private var injected: Set<KeyModifier> = []
    /// Modificador pressionado sem tecla comum no meio desde o pressionar.
    private var clean: Set<KeyModifier> = []
    /// Modificador que já estava preso ao ser pressionado: soltá-lo o libera (RN-07, "tocar de novo").
    private var wasLatchedAtPress: Set<KeyModifier> = []

    public init(geometry: RemoteKeyGeometry, nowNs: UInt64 = 0) {
        self.geometry = geometry
        lastMessageNs = nowNs
    }

    public func state(of modifier: KeyModifier) -> ModifierState {
        if modifierKeysDown.contains(where: { geometry.key(code: $0)?.kind == .modifier(modifier) }) { return .held }
        return latched.contains(modifier) ? .latched : .released
    }

    public var modifierStates: [KeyModifier: ModifierState] {
        Dictionary(uniqueKeysWithValues: KeyModifier.allCases.map { ($0, state(of: $0)) })
    }

    /// Algo mantido ou preso, que o vigia soltaria.
    public var holdsAnything: Bool {
        !regularDown.isEmpty || !modifierKeysDown.isEmpty || !latched.isEmpty || capsLockDown
    }

    /// Toda mensagem válida renova o vigia e zera a sequência de inválidas.
    public mutating func noteMessage(nowNs: UInt64) {
        lastMessageNs = nowNs
        invalidInARow = 0
    }

    /// Conta uma mensagem inválida; `true` quando a sequência chega ao limite e a sessão deve encerrar (código 4003).
    public mutating func noteInvalid() -> Bool {
        invalidInARow += 1
        return invalidInARow >= Self.maxInvalidMessages
    }

    /// `nil` quando o código está fora da geometria: mensagem inválida (D-16).
    public mutating func down(_ code: UInt16) -> [RemoteKeyboardEffect]? {
        guard let key = geometry.key(code: code) else { return nil }
        let before = modifierStates
        var effects: [RemoteKeyboardEffect] = []
        switch key.kind {
        case .modifier(let modifier):
            guard !modifierKeysDown.contains(code) else { return [] }
            let alreadyDown = state(of: modifier) == .held
            modifierKeysDown.insert(code)
            if !alreadyDown {
                clean.insert(modifier)
                if latched.contains(modifier) { wasLatchedAtPress.insert(modifier) } else { wasLatchedAtPress.remove(modifier) }
            }
            if injected.insert(modifier).inserted { effects.append(.modifierDown(modifier)) }
        case .regular:
            guard !regularDown.contains(code) else { return [] }
            regularDown.insert(code)
            keyCount += 1
            clean.removeAll()
            if !latched.isEmpty, pendingLatchRelease == nil { pendingLatchRelease = code }
            if repeating != nil { effects.append(.stopRepeat) }
            effects.append(.keyDown(code))
            repeating = code
            effects.append(.startRepeat(code))
        case .capsLock:
            guard !capsLockDown else { return [] }
            capsLockDown = true
            keyCount += 1
            effects.append(.capsLock(down: true))
        }
        appendStates(before, to: &effects)
        return effects
    }

    /// `nil` quando o código está fora da geometria.
    public mutating func up(_ code: UInt16) -> [RemoteKeyboardEffect]? {
        guard let key = geometry.key(code: code) else { return nil }
        let before = modifierStates
        var effects: [RemoteKeyboardEffect] = []
        switch key.kind {
        case .modifier(let modifier):
            guard modifierKeysDown.remove(code) != nil else { return [] }
            guard state(of: modifier) != .held else { break }
            if clean.contains(modifier), !wasLatchedAtPress.contains(modifier) {
                latched.insert(modifier)
            } else {
                latched.remove(modifier)
                injected.remove(modifier)
                effects.append(.modifierUp(modifier))
            }
            clean.remove(modifier)
            wasLatchedAtPress.remove(modifier)
            if latched.isEmpty { pendingLatchRelease = nil }
        case .regular:
            guard regularDown.remove(code) != nil else { return [] }
            if repeating == code {
                effects.append(.stopRepeat)
                repeating = nil
            }
            effects.append(.keyUp(code))
            if pendingLatchRelease == code {
                pendingLatchRelease = nil
                for modifier in KeyModifier.allCases where latched.contains(modifier) {
                    latched.remove(modifier)
                    if state(of: modifier) != .held {
                        injected.remove(modifier)
                        effects.append(.modifierUp(modifier))
                    }
                }
            }
        case .capsLock:
            guard capsLockDown else { return [] }
            capsLockDown = false
            effects.append(.capsLock(down: false))
        }
        appendStates(before, to: &effects)
        return effects
    }

    /// Solta tudo o que o iPhone mantinha e interrompe a repetição (RN-10); `released` conta teclas e modificadores.
    public mutating func releaseAll() -> (effects: [RemoteKeyboardEffect], released: Int) {
        let before = modifierStates
        var effects: [RemoteKeyboardEffect] = []
        if repeating != nil { effects.append(.stopRepeat) }
        for code in regularDown.sorted() { effects.append(.keyUp(code)) }
        if capsLockDown { effects.append(.capsLock(down: false)) }
        for modifier in KeyModifier.allCases.sorted().reversed() where injected.contains(modifier) {
            effects.append(.modifierUp(modifier))
        }
        let released = regularDown.count + (capsLockDown ? 1 : 0) + injected.count
        regularDown = []
        modifierKeysDown = []
        latched = []
        injected = []
        clean = []
        wasLatchedAtPress = []
        capsLockDown = false
        pendingLatchRelease = nil
        repeating = nil
        appendStates(before, to: &effects)
        return (effects, released)
    }

    /// Vigia (D-11): 1 s sem mensagem com algo mantido ou preso solta tudo, sem encerrar a sessão.
    /// Devolve `nil` quando nada muda.
    public mutating func tick(nowNs: UInt64) -> (effects: [RemoteKeyboardEffect], released: Int)? {
        guard holdsAnything, nowNs >= lastMessageNs, nowNs - lastMessageNs >= Self.watchdogNs else { return nil }
        return releaseAll()
    }

    private func appendStates(_ before: [KeyModifier: ModifierState], to effects: inout [RemoteKeyboardEffect]) {
        let after = modifierStates
        if after != before { effects.append(.modifiers(after)) }
    }
}
