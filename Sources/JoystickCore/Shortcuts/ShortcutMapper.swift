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
}

/// Protótipo de atalhos do controle, fora do escopo da PoC (`action-mapping`, pedido do usuário no PM-3).
///
/// Mapeamento fixo: combinações decididas no pressionar (`action-mapping` EC-04) e soltas pelo mesmo botão.
/// L1 e L2 são modificadores; Options segura Command para alternar aplicativos com o direcional.
/// PS abre a paleta de comandos na camada base e, por repasse, com L1 ou L2 segurados (`002-paleta-comandos` RN-01).
public struct ShortcutMapper: Sendable {
    public static let continueText = "CONTINUAR"

    public private(set) var held: Set<ButtonID> = []
    /// Tecla mantida por cada botão, para soltá-la quando o botão soltar.
    public private(set) var activeChords: [ButtonID: KeyChord] = [:]
    public private(set) var commandHeldByOptions = false
    public var systemChords: [SystemShortcut: KeyChord]

    public init(systemChords: [SystemShortcut: KeyChord] = SystemShortcut.chords(fromSymbolicHotKeys: nil)) {
        self.systemChords = systemChords
    }

    public mutating func press(_ button: ButtonID) -> [ShortcutAction] {
        let modifiers = held
        guard held.insert(button).inserted else { return [] }

        if button == .options {
            commandHeldByOptions = true
            return [.modifierDown(.command)]
        }
        if modifiers.contains(.options) {
            switch button {
            case .dpadRight: return hold(button, KeyChord(KeyChord.tab, [.command]), repeats: false)
            case .dpadLeft: return hold(button, KeyChord(KeyChord.tab, [.command, .shift]), repeats: false)
            default: return []
            }
        }
        if modifiers.contains(.l2) {
            switch button {
            case .dpadLeft: return hold(button, .spaceLeft)
            case .dpadRight: return hold(button, .spaceRight)
            case .dpadDown: return hold(button, .applicationWindows)
            case .dpadUp: return hold(button, .missionControl)
            case .triangle: return hold(button, .nextWindow)
            default: break
            }
        }
        if modifiers.contains(.l1) {
            switch button {
            case .cross: return [.text(Self.continueText, pressEnter: true)]
            case .triangle: return hold(button, KeyChord(KeyChord.tab, [.shift]), repeats: false)
            default: break
            }
        }
        switch button {
        case .dpadUp: return hold(button, KeyChord(KeyChord.upArrow), repeats: true)
        case .dpadDown: return hold(button, KeyChord(KeyChord.downArrow), repeats: true)
        case .dpadLeft: return hold(button, KeyChord(KeyChord.leftArrow), repeats: true)
        case .dpadRight: return hold(button, KeyChord(KeyChord.rightArrow), repeats: true)
        case .cross: return hold(button, KeyChord(KeyChord.returnKey), repeats: false)
        case .circle: return hold(button, KeyChord(KeyChord.escape), repeats: false)
        case .square: return hold(button, KeyChord(KeyChord.delete), repeats: true)
        case .triangle: return hold(button, KeyChord(KeyChord.tab), repeats: false)
        case .create: return hold(button, .missionControl)
        // Atalho do transcritor do Raycast, configurado pelo usuário.
        case .r3: return hold(button, KeyChord(KeyChord.m, [.command]), repeats: false)
        case .ps: return [.openPalette]
        default: return []
        }
    }

    public mutating func release(_ button: ButtonID) -> [ShortcutAction] {
        guard held.remove(button) != nil else { return [] }
        if button == .options {
            guard commandHeldByOptions else { return [] }
            commandHeldByOptions = false
            return [.modifierUp(.command)]
        }
        guard let chord = activeChords.removeValue(forKey: button) else { return [] }
        return [.keyUp(chord)]
    }

    /// Solta toda tecla e modificador mantidos (desconexão, encerramento, perda de permissão).
    public mutating func releaseAll() -> [ShortcutAction] {
        var actions = activeChords.sorted { $0.key < $1.key }.map { ShortcutAction.keyUp($0.value) }
        if commandHeldByOptions { actions.append(.modifierUp(.command)) }
        held.removeAll()
        activeChords.removeAll()
        commandHeldByOptions = false
        return actions
    }

    private mutating func hold(_ button: ButtonID, _ shortcut: SystemShortcut) -> [ShortcutAction] {
        hold(button, systemChords[shortcut] ?? shortcut.defaultChord, repeats: false)
    }

    private mutating func hold(_ button: ButtonID, _ chord: KeyChord, repeats: Bool) -> [ShortcutAction] {
        activeChords[button] = chord
        return [.keyDown(chord, repeats: repeats)]
    }
}
