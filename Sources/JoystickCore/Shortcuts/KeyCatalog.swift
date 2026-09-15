import Foundation

/// Grupo de exibição de uma tecla na lista de montagem de acordes do editor.
public enum KeyGroup: String, CaseIterable, Sendable {
    case letters, digits, punctuation, editing, navigation, function
}

/// Tecla com nome estável no arquivo de configuração, tecla virtual e rótulo de exibição.
public struct KeyEntry: Equatable, Sendable {
    /// Nome gravado no arquivo: `z`, `return`, `upArrow`, `f5`, `leftBracket`.
    public let name: String
    /// Tecla virtual do macOS (`kVK_*`): posição física, independente do *layout*.
    public let keyCode: UInt16
    public let display: String
    public let group: KeyGroup

    public init(_ name: String, _ keyCode: UInt16, _ display: String, _ group: KeyGroup) {
        self.name = name
        self.keyCode = keyCode
        self.display = display
        self.group = group
    }
}

/// Tabela fixa nome ↔ tecla virtual (`003-editor-atalhos` D-03). Tecla fora da tabela não pode ser gravada.
public enum KeyCatalog {
    public static let entries: [KeyEntry] = letters + digits + punctuation + editing + navigation + function

    private static let letters: [KeyEntry] = [
        ("a", 0x00), ("b", 0x0B), ("c", 0x08), ("d", 0x02), ("e", 0x0E), ("f", 0x03), ("g", 0x05), ("h", 0x04),
        ("i", 0x22), ("j", 0x26), ("k", 0x28), ("l", 0x25), ("m", 0x2E), ("n", 0x2D), ("o", 0x1F), ("p", 0x23),
        ("q", 0x0C), ("r", 0x0F), ("s", 0x01), ("t", 0x11), ("u", 0x20), ("v", 0x09), ("w", 0x0D), ("x", 0x07),
        ("y", 0x10), ("z", 0x06),
    ].map { KeyEntry($0.0, $0.1, $0.0.uppercased(), .letters) }

    private static let digits: [KeyEntry] = [
        ("0", 0x1D), ("1", 0x12), ("2", 0x13), ("3", 0x14), ("4", 0x15),
        ("5", 0x17), ("6", 0x16), ("7", 0x1A), ("8", 0x1C), ("9", 0x19),
    ].map { KeyEntry($0.0, $0.1, $0.0, .digits) }

    private static let punctuation: [KeyEntry] = [
        KeyEntry("minus", 0x1B, "-", .punctuation),
        KeyEntry("equal", 0x18, "=", .punctuation),
        KeyEntry("leftBracket", 0x21, "[", .punctuation),
        KeyEntry("rightBracket", 0x1E, "]", .punctuation),
        KeyEntry("backslash", 0x2A, "\\", .punctuation),
        KeyEntry("semicolon", 0x29, ";", .punctuation),
        KeyEntry("quote", 0x27, "'", .punctuation),
        KeyEntry("comma", 0x2B, ",", .punctuation),
        KeyEntry("period", 0x2F, ".", .punctuation),
        KeyEntry("slash", 0x2C, "/", .punctuation),
        KeyEntry("grave", KeyChord.grave, "`", .punctuation),
    ]

    private static let editing: [KeyEntry] = [
        KeyEntry("return", KeyChord.returnKey, "Return", .editing),
        KeyEntry("tab", KeyChord.tab, "Tab", .editing),
        KeyEntry("space", 0x31, "Space", .editing),
        KeyEntry("delete", KeyChord.delete, "Delete", .editing),
        KeyEntry("forwardDelete", 0x75, "Forward Delete", .editing),
        KeyEntry("escape", KeyChord.escape, "Esc", .editing),
    ]

    private static let navigation: [KeyEntry] = [
        KeyEntry("upArrow", KeyChord.upArrow, "↑", .navigation),
        KeyEntry("downArrow", KeyChord.downArrow, "↓", .navigation),
        KeyEntry("leftArrow", KeyChord.leftArrow, "←", .navigation),
        KeyEntry("rightArrow", KeyChord.rightArrow, "→", .navigation),
        KeyEntry("home", 0x73, "Home", .navigation),
        KeyEntry("end", 0x77, "End", .navigation),
        KeyEntry("pageUp", 0x74, "Page Up", .navigation),
        KeyEntry("pageDown", 0x79, "Page Down", .navigation),
    ]

    private static let function: [KeyEntry] = [
        (1, 0x7A), (2, 0x78), (3, 0x63), (4, 0x76), (5, 0x60), (6, 0x61),
        (7, 0x62), (8, 0x64), (9, 0x65), (10, 0x6D), (11, 0x67), (12, 0x6F),
    ].map { KeyEntry("f\($0.0)", $0.1, "F\($0.0)", .function) }

    private static let byName = Dictionary(uniqueKeysWithValues: entries.map { ($0.name, $0) })
    private static let byKeyCode = Dictionary(uniqueKeysWithValues: entries.map { ($0.keyCode, $0) })

    public static func entry(named name: String) -> KeyEntry? { byName[name] }

    public static func entry(keyCode: UInt16) -> KeyEntry? { byKeyCode[keyCode] }

    public static func entries(in group: KeyGroup) -> [KeyEntry] { entries.filter { $0.group == group } }

    /// Acorde legível, com os modificadores na ordem do macOS (⌃ ⌥ ⇧ ⌘) antes da tecla.
    public static func display(_ chord: KeyChord) -> String {
        let symbols = chord.modifiers.sorted().map { modifier in
            switch modifier {
            case .control: "⌃"
            case .option: "⌥"
            case .shift: "⇧"
            case .command: "⌘"
            }
        }
        return symbols.joined() + (entry(keyCode: chord.keyCode)?.display ?? "tecla \(chord.keyCode)")
    }
}
