import Foundation

/// Codificação das seções `shortcuts` e `palette` e fusão com o arquivo existente (`003-editor-atalhos` D-07, RN-10).
///
/// A codificação é a inversa de `ShortcutConfigValidation.decode(root:)`: campos com valor padrão (`modifiers` vazio,
/// `repeat` falso) e camadas sem ação própria são omitidos; `pressEnter` e `label` são sempre escritos.
public enum ConfigDocument {
    public static func encode(_ document: ShortcutsDocument) -> (shortcuts: JSONValue, palette: JSONValue) {
        (encode(document.shortcuts), encode(palette: document.palette))
    }

    static func encode(_ config: ShortcutConfig) -> JSONValue {
        var modifiers: [String: JSONValue] = [:]
        for (button, keys) in config.modifiers {
            modifiers[button.rawValue] = encode(keys)
        }
        var layers: [String: JSONValue] = [:]
        for (layer, actions) in config.layers where !actions.isEmpty {
            var triggers: [String: JSONValue] = [:]
            for (button, action) in actions {
                triggers[button.rawValue] = encode(action)
            }
            layers[layer?.rawValue ?? ShortcutConfigValidation.baseLayerName] = .object(triggers)
        }
        return .object([
            "version": .int(ShortcutConfigValidation.supportedVersion),
            "modifiers": .object(modifiers),
            "layers": .object(layers),
        ])
    }

    static func encode(palette items: [PaletteItem]) -> JSONValue {
        .object([
            "version": .int(ShortcutConfigValidation.supportedVersion),
            "items": .array(items.map { item in
                .object(["label": .string(item.label), "text": .string(item.text), "pressEnter": .bool(item.pressEnter)])
            }),
        ])
    }

    static func encode(_ action: TriggerAction) -> JSONValue {
        switch action {
        case .chord(let chord, let repeats):
            // Tecla fora do catálogo é recusada por `validate` antes de qualquer gravação.
            var fields: [String: JSONValue] = [
                "type": "chord",
                "key": .string(KeyCatalog.entry(keyCode: chord.keyCode)?.name ?? "keyCode\(chord.keyCode)"),
            ]
            if !chord.modifiers.isEmpty { fields["modifiers"] = encode(chord.modifiers) }
            if repeats { fields["repeat"] = true }
            return .object(fields)
        case .systemShortcut(let shortcut):
            return .object(["type": "systemShortcut", "name": .string(shortcut.name)])
        case .text(let text, let pressEnter):
            return .object(["type": "text", "text": .string(text), "pressEnter": .bool(pressEnter)])
        case .openPalette:
            return .object(["type": "openPalette"])
        case .none:
            return .object(["type": "none"])
        }
    }

    static func encode(_ keys: Set<KeyModifier>) -> JSONValue {
        .array(keys.sorted().map { .string($0.rawValue) })
    }

    /// Substitui só `shortcuts` e `palette` na raiz lida no instante da gravação; ausente ou não objeto, cria a raiz.
    /// Chaves em ordem alfabética e barras sem escape, de modo que o mesmo documento produza sempre os mesmos *bytes*.
    public static func merge(existing: JSONValue?, document: ShortcutsDocument) -> Data {
        var root: [String: JSONValue] = [:]
        if case .object(let fields)? = existing { root = fields }
        let sections = encode(document)
        root["shortcuts"] = sections.shortcuts
        root["palette"] = sections.palette
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        // `JSONValue` sempre serializa; a quebra final mantém o arquivo como texto de linhas completas.
        return (try! encoder.encode(JSONValue.object(root))) + Data("\n".utf8)
    }
}
