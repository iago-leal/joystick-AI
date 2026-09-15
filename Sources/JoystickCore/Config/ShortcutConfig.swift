import Foundation

/// Tipo de uma ação diferente de "nenhuma", como aparece no arquivo e no log (`shortcut.triggered`).
public enum TriggerActionType: String, Sendable {
    case chord, systemShortcut, text, openPalette
}

/// Ação de um gatilho (`003-editor-atalhos` D-02, RN-06). "Herdar" não é caso: é a ausência na camada de modificador.
public enum TriggerAction: Equatable, Hashable, Sendable {
    /// Com `repeats`, repete após 400 ms e a cada 50 ms enquanto o botão estiver pressionado.
    case chord(KeyChord, repeats: Bool)
    /// Acorde lido das preferências do macOS no momento do uso (RN-07).
    case systemShortcut(SystemShortcut)
    /// Uma linha, de 1 a 1.000 caracteres (RN-13).
    case text(String, pressEnter: Bool)
    case openPalette
    case none

    public var type: TriggerActionType? {
        switch self {
        case .chord: .chord
        case .systemShortcut: .systemShortcut
        case .text: .text
        case .openPalette: .openPalette
        case .none: nil
        }
    }
}

/// Mapeamento dos botões em camadas (`data-delta.md` §2).
public struct ShortcutConfig: Equatable, Sendable {
    /// R1, R2 e clique do touchpad: cliques fixos, sem atalho e nunca modificadores (RN-05).
    public static let pointerButtons: Set<ButtonID> = [.r1, .r2, .touchpadClick]

    /// Botão modificador → teclas modificadoras mantidas enquanto ele estiver segurado (RN-04).
    public var modifiers: [ButtonID: Set<KeyModifier>]
    /// Chave `nil` é a camada base. Numa camada de modificador, botão ausente herda da base (RN-02).
    public var layers: [ButtonID?: [ButtonID: TriggerAction]]

    public init(modifiers: [ButtonID: Set<KeyModifier>] = [:], layers: [ButtonID?: [ButtonID: TriggerAction]] = [:]) {
        self.modifiers = modifiers
        self.layers = layers
    }

    public func isModifier(_ button: ButtonID) -> Bool { modifiers[button] != nil }

    public struct Resolution: Equatable, Sendable {
        public let action: TriggerAction
        /// Verdadeiro quando a ação vem da camada base por ausência na camada de modificador pedida.
        public let inherited: Bool

        public init(action: TriggerAction, inherited: Bool) {
            self.action = action
            self.inherited = inherited
        }
    }

    /// Ação de `button` em `layer` (`nil` é a base): própria, herdada da base ou "nenhuma".
    /// Não trata modificadores nem botões de apontamento; quem executa decide antes (`data-delta.md` §4).
    public func resolvedAction(for button: ButtonID, in layer: ButtonID?) -> Resolution {
        if let layer, let own = layers[layer]?[button] {
            return Resolution(action: own, inherited: false)
        }
        return Resolution(action: layers[nil]?[button] ?? .none, inherited: layer != nil)
    }
}

/// Mapeamento e paleta, validados e aplicados em conjunto (RN-08).
public struct ShortcutsDocument: Equatable, Sendable {
    public static let maxTextLength = 1_000
    public static let maxLabelLength = 80
    public static let paletteItemLimit = 1...50

    public var shortcuts: ShortcutConfig
    public var palette: [PaletteItem]

    public init(shortcuts: ShortcutConfig, palette: [PaletteItem]) {
        self.shortcuts = shortcuts
        self.palette = palette
    }
}

/// Problema de uma leitura ou de um rascunho: caminho e regra, nunca o valor recusado (RN-14).
public struct ShortcutIssue: Equatable, Sendable {
    public enum Rule: String, Sendable {
        case unsupportedVersion, pointerButtonNotAllowed, layerWithoutModifier, modifierHasAction
        case unknownKey, unknownModifier, unknownSystemShortcut, unknownActionType
        case textEmpty, textTooLong, multiline, labelTooLong, paletteEmpty, paletteTooLong, wrongType
        /// Só na leitura do arquivo: JSON malformado e arquivo ilegível ou grande demais.
        case syntax, unreadable
    }

    /// Posição no arquivo: `shortcuts.layers.l2.dpadLeft`, `palette.items[3].text`.
    public var path: String
    public var rule: Rule
    /// Linha do valor no arquivo, quando conhecida (`003-editor-atalhos` D-06).
    public var line: Int?

    public init(path: String, rule: Rule, line: Int? = nil) {
        self.path = path
        self.rule = rule
        self.line = line
    }

    /// Caminho para o log; vazio quando o problema é do arquivo inteiro (`syntax`, `unreadable`).
    public var logPath: String? { path.isEmpty ? nil : path }
}

/// Problemas que recusaram uma leitura, na ordem em que foram encontrados.
public struct ShortcutIssues: Error, Equatable, Sendable {
    public var issues: [ShortcutIssue]

    public init(_ issues: [ShortcutIssue]) {
        self.issues = issues
    }
}
