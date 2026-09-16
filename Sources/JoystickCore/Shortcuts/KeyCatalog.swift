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

/// Sinal da grade de montagem que corresponde a uma tecla do catálogo com um modificador implícito
/// (`005-sinais-matematicos` D-01): `+` é `equal` com ⇧, como no teclado físico. Fica fora de `KeyCatalog.entries`,
/// de modo que o arquivo, a validação e a captura continuam só com os nomes do catálogo.
public struct ComposedKey: Equatable, Sendable {
    /// Identificador da escolha na grade; nunca gravado no arquivo.
    public let name: String
    public let display: String
    /// Tecla do catálogo usada no acorde.
    public let keyCode: UInt16
    public let modifier: KeyModifier
    public let group: KeyGroup
    /// Nome da entrada do catálogo que precede o sinal na grade.
    public let after: String

    public init(name: String, display: String, keyCode: UInt16, modifier: KeyModifier, group: KeyGroup, after: String) {
        self.name = name
        self.display = display
        self.keyCode = keyCode
        self.modifier = modifier
        self.group = group
        self.after = after
    }

    public func matches(_ chord: KeyChord) -> Bool {
        chord.keyCode == keyCode && chord.modifiers.contains(modifier)
    }
}

/// Escolha da grade de montagem de acordes (`005-sinais-matematicos` D-03): tecla do catálogo ou sinal composto.
public enum KeyChoice: Equatable, Sendable {
    case key(KeyEntry)
    case composed(ComposedKey)

    public var id: String {
        switch self {
        case .key(let entry): entry.name
        case .composed(let composed): composed.name
        }
    }

    public var display: String {
        switch self {
        case .key(let entry): entry.display
        case .composed(let composed): composed.display
        }
    }

    /// O sinal fica marcado quando casa o acorde; a tecla, quando é a do acorde e nenhum sinal o casa, para que
    /// `+` e `=` nunca fiquem marcados juntos.
    public func isSelected(in chord: KeyChord) -> Bool {
        switch self {
        case .key(let entry): entry.keyCode == chord.keyCode && KeyCatalog.composedKey(matching: chord) == nil
        case .composed(let composed): composed.matches(chord)
        }
    }

    /// O sinal acrescenta seu modificador aos do acorde (RN-02); a tecla mantém os modificadores, menos o do sinal
    /// que casava o acorde, de modo que acionar `=` a partir de ⌘+ dá ⌘=.
    public func applied(to chord: KeyChord) -> KeyChord {
        switch self {
        case .key(let entry):
            var modifiers = chord.modifiers
            if let composed = KeyCatalog.composedKey(matching: chord) { modifiers.remove(composed.modifier) }
            return KeyChord(entry.keyCode, modifiers)
        case .composed(let composed):
            return KeyChord(composed.keyCode, chord.modifiers.union([composed.modifier]))
        }
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
        KeyEntry("equal", KeyChord.equal, "=", .punctuation),
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
        KeyEntry("return", KeyChord.returnKey, "Enter", .editing),
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

    /// Sinais compostos (`005-sinais-matematicos` D-01), fora de `entries`, `byName` e `byKeyCode`.
    public static let composedKeys: [ComposedKey] = [
        ComposedKey(name: "plus", display: "+", keyCode: KeyChord.equal, modifier: .shift, group: .punctuation, after: "minus"),
    ]

    private static let byName = Dictionary(uniqueKeysWithValues: entries.map { ($0.name, $0) })
    private static let byKeyCode = Dictionary(uniqueKeysWithValues: entries.map { ($0.keyCode, $0) })

    public static func entry(named name: String) -> KeyEntry? { byName[name] }

    public static func entry(keyCode: UInt16) -> KeyEntry? { byKeyCode[keyCode] }

    public static func entries(in group: KeyGroup) -> [KeyEntry] { entries.filter { $0.group == group } }

    /// Escolhas da grade de um grupo: as teclas do catálogo, com cada sinal composto logo após a entrada `after`.
    public static func choices(in group: KeyGroup) -> [KeyChoice] {
        entries(in: group).flatMap { entry in
            [KeyChoice.key(entry)] + composedKeys.filter { $0.group == group && $0.after == entry.name }.map(KeyChoice.composed)
        }
    }

    static func composedKey(matching chord: KeyChord) -> ComposedKey? {
        composedKeys.first { $0.matches(chord) }
    }

    /// Acorde legível, com os modificadores na ordem do macOS (⌃ ⌥ ⇧ ⌘) antes da tecla. Acorde que casa um sinal
    /// composto mostra o sinal sem o modificador implícito (`005-sinais-matematicos` D-02): ⇧⌘= aparece como ⌘+.
    public static func display(_ chord: KeyChord) -> String {
        if let composed = composedKey(matching: chord) {
            return symbols(chord.modifiers.subtracting([composed.modifier])) + composed.display
        }
        return symbols(chord.modifiers) + (entry(keyCode: chord.keyCode)?.display ?? "tecla \(chord.keyCode)")
    }

    /// Símbolos das teclas modificadoras na ordem do macOS.
    public static func symbols(_ modifiers: Set<KeyModifier>) -> String {
        modifiers.sorted().map { modifier in
            switch modifier {
            case .control: "⌃"
            case .option: "⌥"
            case .shift: "⇧"
            case .command: "⌘"
            }
        }.joined()
    }
}
