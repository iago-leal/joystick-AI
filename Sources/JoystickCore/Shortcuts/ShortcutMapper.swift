import Foundation

/// Modificadores de teclado usados pelos atalhos.
public enum KeyModifier: String, CaseIterable, Sendable, Comparable {
    case control, option, shift, command

    private var order: Int { Self.allCases.firstIndex(of: self)! }

    public static func < (lhs: KeyModifier, rhs: KeyModifier) -> Bool { lhs.order < rhs.order }
}

/// Tecla virtual do macOS (`kVK_*`) com os modificadores que a acompanham.
public struct KeyChord: Equatable, Hashable, Sendable {
    public var keyCode: UInt16
    public var modifiers: Set<KeyModifier>

    public init(_ keyCode: UInt16, _ modifiers: Set<KeyModifier> = []) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    public static let returnKey: UInt16 = 36
    public static let tab: UInt16 = 48
    public static let space: UInt16 = 49
    public static let grave: UInt16 = 50
    public static let delete: UInt16 = 51
    public static let escape: UInt16 = 53
    public static let m: UInt16 = 46
    public static let leftArrow: UInt16 = 123
    public static let rightArrow: UInt16 = 124
    public static let downArrow: UInt16 = 125
    public static let upArrow: UInt16 = 126

    public var isArrow: Bool { (Self.leftArrow...Self.upArrow).contains(keyCode) }
}

/// Atalhos de sistema cujo acorde vem de `com.apple.symbolichotkeys`, pois o usuário pode tê-los alterado.
public enum SystemShortcut: Int, CaseIterable, Sendable {
    case nextWindow = 27
    case missionControl = 32
    case applicationWindows = 33
    case spaceLeft = 79
    case spaceRight = 81

    /// Nome estável no arquivo de configuração (`003-editor-atalhos` D-03).
    public var name: String {
        switch self {
        case .nextWindow: "nextWindow"
        case .missionControl: "missionControl"
        case .applicationWindows: "applicationWindows"
        case .spaceLeft: "spaceLeft"
        case .spaceRight: "spaceRight"
        }
    }

    public init?(name: String) {
        guard let shortcut = Self.allCases.first(where: { $0.name == name }) else { return nil }
        self = shortcut
    }

    /// Rótulo exibido no editor (`003-editor-atalhos` RN-07, RF-08).
    public var displayName: String {
        switch self {
        case .nextWindow: "próxima janela"
        case .missionControl: "Mission Control"
        case .applicationWindows: "janelas do aplicativo"
        case .spaceLeft: "mesa à esquerda"
        case .spaceRight: "mesa à direita"
        }
    }

    public var defaultChord: KeyChord {
        switch self {
        case .nextWindow: KeyChord(KeyChord.grave, [.command])
        case .missionControl: KeyChord(KeyChord.upArrow, [.control])
        case .applicationWindows: KeyChord(KeyChord.downArrow, [.control])
        case .spaceLeft: KeyChord(KeyChord.leftArrow, [.control])
        case .spaceRight: KeyChord(KeyChord.rightArrow, [.control])
        }
    }

    /// Acordes de `AppleSymbolicHotKeys`: `parameters` é (caractere, tecla virtual, máscara de modificadores).
    /// Entrada ausente, desativada ou malformada mantém o acorde padrão.
    public static func chords(fromSymbolicHotKeys hotKeys: [String: Any]?) -> [SystemShortcut: KeyChord] {
        var result: [SystemShortcut: KeyChord] = [:]
        for shortcut in allCases {
            result[shortcut] = shortcut.defaultChord
            guard let entry = hotKeys?[String(shortcut.rawValue)] as? [String: Any],
                  (entry["enabled"] as? NSNumber)?.boolValue ?? false,
                  let value = entry["value"] as? [String: Any],
                  let parameters = value["parameters"] as? [NSNumber], parameters.count >= 3,
                  let keyCode = UInt16(exactly: parameters[1].intValue)
            else { continue }
            let mask = parameters[2].intValue
            var modifiers: Set<KeyModifier> = []
            if mask & 0x20000 != 0 { modifiers.insert(.shift) }
            if mask & 0x40000 != 0 { modifiers.insert(.control) }
            if mask & 0x80000 != 0 { modifiers.insert(.option) }
            if mask & 0x100000 != 0 { modifiers.insert(.command) }
            result[shortcut] = KeyChord(keyCode, modifiers)
        }
        return result
    }
}

public enum ShortcutAction: Equatable, Sendable {
    /// Pressiona a tecla; com `repeats`, o executor repete enquanto o botão continuar pressionado.
    case keyDown(KeyChord, repeats: Bool)
    case keyUp(KeyChord)
    case text(String, pressEnter: Bool)
    case modifierDown(KeyModifier)
    case modifierUp(KeyModifier)
    /// Abre a paleta de comandos; o executor solta antes as teclas mantidas (`002-paleta-comandos` D-02, D-04).
    case openPalette
    /// Pressiona o atalho de sistema com o acorde lido das preferências do macOS no instante do uso
    /// (`003-editor-atalhos` D-11, RN-07); o executor guarda o acorde para o soltar.
    case systemDown(SystemShortcut)
    case systemUp(SystemShortcut)
}

/// Botões do controle convertidos em ações pela configuração de atalhos (`003-editor-atalhos` D-09, D-10,
/// `data-delta.md` §4).
///
/// A ação é resolvida no pressionar e guardada até o soltar, mesmo que o modificador seja solto antes (RN-01). Com
/// mais de um modificador segurado, vale a camada do segurado há mais tempo, com herança só da base (RN-03). R1, R2 e
/// o clique do touchpad não produzem nada aqui: os cliques ficam em `ButtonActions` (RN-05).
public struct ShortcutMapper: Sendable {
    /// Gatilho do último pressionar que executou ação, para `shortcut.triggered` (D-14).
    public struct Trigger: Equatable, Sendable {
        public let button: ButtonID
        /// `nil` é a camada base.
        public let layer: ButtonID?
        public let type: TriggerActionType

        public init(button: ButtonID, layer: ButtonID?, type: TriggerActionType) {
            self.button = button
            self.layer = layer
            self.type = type
        }
    }

    enum HeldAction: Equatable, Sendable {
        case chord(KeyChord)
        case system(SystemShortcut)
    }

    public let config: ShortcutConfig
    public private(set) var held: Set<ButtonID> = []
    /// Modificadores segurados, do mais antigo ao mais recente.
    public private(set) var modifierOrder: [ButtonID] = []
    /// Tecla ou atalho mantido por cada botão, para soltá-lo quando o botão soltar.
    private(set) var resolved: [ButtonID: HeldAction] = [:]
    /// Zerado a cada pressionar que não executa ação.
    public private(set) var lastTrigger: Trigger?

    public init(config: ShortcutConfig = ShortcutDefaults.config) {
        self.config = config
    }

    /// Camada vigente: a do modificador segurado há mais tempo, ou a base.
    public var currentLayer: ButtonID? { modifierOrder.first }

    public mutating func press(_ button: ButtonID) -> [ShortcutAction] {
        lastTrigger = nil
        guard held.insert(button).inserted else { return [] }
        if ShortcutConfig.pointerButtons.contains(button) { return [] }
        if let keys = config.modifiers[button] {
            modifierOrder.append(button)
            return keys.sorted().map { .modifierDown($0) }
        }

        let layer = currentLayer
        let action = config.resolvedAction(for: button, in: layer).action
        let actions: [ShortcutAction]
        switch action {
        case .chord(let chord, let repeats):
            resolved[button] = .chord(chord)
            actions = [.keyDown(chord, repeats: repeats)]
        case .systemShortcut(let shortcut):
            resolved[button] = .system(shortcut)
            actions = [.systemDown(shortcut)]
        case .text(let text, let pressEnter):
            actions = [.text(text, pressEnter: pressEnter)]
        case .openPalette:
            actions = [.openPalette]
        case .none:
            actions = []
        }
        if let type = action.type {
            lastTrigger = Trigger(button: button, layer: layer, type: type)
        }
        return actions
    }

    public mutating func release(_ button: ButtonID) -> [ShortcutAction] {
        guard held.remove(button) != nil else { return [] }
        if let index = modifierOrder.firstIndex(of: button) {
            modifierOrder.remove(at: index)
            return (config.modifiers[button] ?? []).sorted().map { .modifierUp($0) }
        }
        return resolved.removeValue(forKey: button).map { [Self.up($0)] } ?? []
    }

    /// Solta toda tecla, atalho e modificador mantidos (desconexão, encerramento, perda de permissão, troca de
    /// configuração) e zera o estado.
    public mutating func releaseAll() -> [ShortcutAction] {
        var actions = resolved.sorted { $0.key < $1.key }.map { Self.up($0.value) }
        for modifier in modifierOrder {
            actions += (config.modifiers[modifier] ?? []).sorted().map { .modifierUp($0) }
        }
        held.removeAll()
        modifierOrder.removeAll()
        resolved.removeAll()
        lastTrigger = nil
        return actions
    }

    private static func up(_ action: HeldAction) -> ShortcutAction {
        switch action {
        case .chord(let chord): .keyUp(chord)
        case .system(let shortcut): .systemUp(shortcut)
        }
    }
}
