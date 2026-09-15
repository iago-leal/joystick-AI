import Foundation

/// Resumo da ação de um botão numa camada, como aparece na figura do controle (`003-editor-atalhos` D-21, RF-08).
public enum ActionSummary {
    /// Caracteres de texto exibidos antes das reticências.
    public static let textLimit = 24

    public static func text(for button: ButtonID, layer: ButtonID?, in config: ShortcutConfig) -> String {
        switch button {
        case .r1, .touchpadClick: return "clique esquerdo, fixo"
        case .r2: return "clique direito, fixo"
        default: break
        }
        if let keys = config.modifiers[button] {
            let held = keys.isEmpty ? "" : " " + KeyCatalog.symbols(keys)
            return "modificador\(held)"
        }
        let resolution = config.resolvedAction(for: button, in: layer)
        let summary = text(for: resolution.action)
        return resolution.inherited ? "\(summary) (herdado)" : summary
    }

    public static func text(for action: TriggerAction) -> String {
        switch action {
        case .chord(let chord, _):
            return KeyCatalog.display(chord)
        case .systemShortcut(let shortcut):
            return shortcut.displayName
        case .text(let text, let pressEnter):
            return "“\(truncated(text))”" + (pressEnter ? " + Enter" : "")
        case .openPalette:
            return "abrir paleta"
        case .none:
            return "nenhuma"
        }
    }

    public static func truncated(_ text: String, limit: Int = textLimit) -> String {
        text.count > limit ? String(text.prefix(limit)) + "…" : text
    }
}
