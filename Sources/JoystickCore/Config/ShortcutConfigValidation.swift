import Foundation

/// Validação conjunta das seções `shortcuts` e `palette` (`003-editor-atalhos` D-05, RN-08, `interfaces/config-file.md` §2).
///
/// Duas camadas: `decode(root:)` cuida da estrutura JSON e chama `validate(_:)`, que aplica as regras semânticas sobre o
/// documento já decodificado e também serve ao rascunho do editor. Os problemas citam caminho e regra, nunca o valor.
public enum ShortcutConfigValidation {
    public static let supportedVersion: Int64 = 1

    // MARK: regras semânticas

    public static func validate(_ document: ShortcutsDocument) -> [ShortcutIssue] {
        validate(document.shortcuts) + validate(palette: document.palette)
    }

    static func validate(_ config: ShortcutConfig) -> [ShortcutIssue] {
        var issues: [ShortcutIssue] = []
        for button in config.modifiers.keys.sorted() where ShortcutConfig.pointerButtons.contains(button) {
            issues.append(ShortcutIssue(path: "shortcuts.modifiers.\(button.rawValue)", rule: .pointerButtonNotAllowed))
        }
        for layer in sortedLayers(config.layers.keys) {
            let layerPath = path(layer: layer)
            if let layer, !config.isModifier(layer) {
                issues.append(ShortcutIssue(path: layerPath, rule: .layerWithoutModifier))
            }
            guard let actions = config.layers[layer] else { continue }
            for button in actions.keys.sorted() {
                let triggerPath = "\(layerPath).\(button.rawValue)"
                if ShortcutConfig.pointerButtons.contains(button) {
                    issues.append(ShortcutIssue(path: triggerPath, rule: .pointerButtonNotAllowed))
                } else if config.isModifier(button) {
                    issues.append(ShortcutIssue(path: triggerPath, rule: .modifierHasAction))
                }
                switch actions[button]! {
                case .text(let text, _):
                    if let rule = textRule(text) { issues.append(ShortcutIssue(path: "\(triggerPath).text", rule: rule)) }
                case .chord(let chord, _) where KeyCatalog.entry(keyCode: chord.keyCode) == nil:
                    issues.append(ShortcutIssue(path: "\(triggerPath).key", rule: .unknownKey))
                default:
                    break
                }
            }
        }
        return issues
    }

    static func validate(palette items: [PaletteItem]) -> [ShortcutIssue] {
        if items.isEmpty { return [ShortcutIssue(path: "palette.items", rule: .paletteEmpty)] }
        var issues: [ShortcutIssue] = []
        if items.count > ShortcutsDocument.paletteItemLimit.upperBound {
            issues.append(ShortcutIssue(path: "palette.items", rule: .paletteTooLong))
        }
        for (index, item) in items.enumerated() {
            if let rule = textRule(item.text) {
                issues.append(ShortcutIssue(path: "palette.items[\(index)].text", rule: rule))
            }
            if let rule = labelRule(item.label) {
                issues.append(ShortcutIssue(path: "palette.items[\(index)].label", rule: rule))
            }
        }
        return issues
    }

    /// Texto de ação ou de item: uma linha, de 1 a 1.000 caracteres (RN-12, RN-13).
    public static func textRule(_ text: String) -> ShortcutIssue.Rule? {
        if text.isEmpty { return .textEmpty }
        if isMultiline(text) { return .multiline }
        if text.count > ShortcutsDocument.maxTextLength { return .textTooLong }
        return nil
    }

    /// Rótulo de item: uma linha, até 80 caracteres; vazio exibe o texto.
    public static func labelRule(_ label: String) -> ShortcutIssue.Rule? {
        if isMultiline(label) { return .multiline }
        if label.count > ShortcutsDocument.maxLabelLength { return .labelTooLong }
        return nil
    }

    public static func isMultiline(_ text: String) -> Bool {
        text.rangeOfCharacter(from: .newlines) != nil
    }

    /// `shortcuts.layers.base` ou `shortcuts.layers.<botão>`.
    public static func path(layer: ButtonID?) -> String {
        "shortcuts.layers.\(layer?.rawValue ?? baseLayerName)"
    }

    public static let baseLayerName = "base"

    /// Base primeiro, depois os modificadores na ordem de `ButtonID`.
    public static func sortedLayers<S: Sequence>(_ layers: S) -> [ButtonID?] where S.Element == ButtonID? {
        let modifiers = layers.compactMap { $0 }.sorted()
        return (layers.contains(where: { $0 == nil }) ? [nil] : []) + modifiers.map { Optional($0) }
    }
}

// MARK: decodificação

extension ShortcutConfigValidation {
    /// Seções presentes na raiz; a ausente vale o padrão (`interfaces/config-file.md` §3).
    public struct Sections: Equatable, Sendable {
        public var shortcuts: Bool
        public var palette: Bool

        public init(shortcuts: Bool, palette: Bool) {
            self.shortcuts = shortcuts
            self.palette = palette
        }
    }

    public static func sections(in root: JSONValue) -> Sections {
        Sections(shortcuts: root["shortcuts"] != nil, palette: root["palette"] != nil)
    }

    /// Decodifica e valida as duas seções; qualquer erro em uma delas recusa ambas (RN-08).
    public static func decode(root: JSONValue) -> Result<ShortcutsDocument, ShortcutIssues> {
        var decoder = SectionDecoder()
        let shortcuts = root["shortcuts"].map { decoder.shortcuts($0) } ?? ShortcutDefaults.config
        let palette = root["palette"].map { decoder.palette($0) } ?? PaletteDefaults.items
        // Cada seção decodificada passa pelas regras semânticas, para que a recusa liste os problemas das duas.
        var issues = decoder.issues
        issues += shortcuts.map { validate($0) } ?? []
        issues += palette.map { validate(palette: $0) } ?? []
        guard issues.isEmpty, let shortcuts, let palette else { return .failure(ShortcutIssues(issues)) }
        return .success(ShortcutsDocument(shortcuts: shortcuts, palette: palette))
    }

    /// Estrutura JSON de `interfaces/config-file.md` §2; as regras semânticas ficam em `validate(_:)`.
    struct SectionDecoder {
        var issues: [ShortcutIssue] = []

        mutating func shortcuts(_ value: JSONValue) -> ShortcutConfig? {
            let path = "shortcuts"
            guard case .object(let fields) = value else { return fail(path, .wrongType) }
            guard version(fields["version"], path: "\(path).version") else { return nil }
            var config = ShortcutConfig()
            var ok = true

            switch fields["modifiers"] {
            case nil: break
            case .object(let modifiers)?:
                for name in modifiers.keys.sorted() {
                    let modifierPath = "\(path).modifiers.\(name)"
                    guard let button = ButtonID(rawValue: name) else { record(modifierPath, .wrongType); ok = false; continue }
                    guard let keys = keyModifiers(modifiers[name]!, path: modifierPath) else { ok = false; continue }
                    config.modifiers[button] = keys
                }
            case _?:
                record("\(path).modifiers", .wrongType); ok = false
            }

            switch fields["layers"] {
            case nil: break
            case .object(let layers)?:
                for name in layers.keys.sorted() {
                    let layerPath = "\(path).layers.\(name)"
                    let layer: ButtonID?
                    if name == ShortcutConfigValidation.baseLayerName {
                        layer = nil
                    } else if let button = ButtonID(rawValue: name) {
                        layer = button
                    } else {
                        record(layerPath, .wrongType); ok = false
                        continue
                    }
                    guard case .object(let triggers) = layers[name]! else { record(layerPath, .wrongType); ok = false; continue }
                    var actions: [ButtonID: TriggerAction] = [:]
                    for buttonName in triggers.keys.sorted() {
                        let triggerPath = "\(layerPath).\(buttonName)"
                        guard let button = ButtonID(rawValue: buttonName) else { record(triggerPath, .wrongType); ok = false; continue }
                        guard let action = action(triggers[buttonName]!, path: triggerPath) else { ok = false; continue }
                        actions[button] = action
                    }
                    // Camada vazia equivale a camada ausente: tudo herdado da base.
                    if !actions.isEmpty { config.layers[layer] = actions }
                }
            case _?:
                record("\(path).layers", .wrongType); ok = false
            }
            return ok ? config : nil
        }

        mutating func palette(_ value: JSONValue) -> [PaletteItem]? {
            let path = "palette"
            guard case .object(let fields) = value else { return fail(path, .wrongType) }
            guard version(fields["version"], path: "\(path).version") else { return nil }
            guard case .array(let entries)? = fields["items"] else { return fail("\(path).items", .wrongType) }
            var items: [PaletteItem] = []
            var ok = true
            for (index, entry) in entries.enumerated() {
                let itemPath = "\(path).items[\(index)]"
                guard case .object(let item) = entry else { record(itemPath, .wrongType); ok = false; continue }
                let text = string(item["text"], path: "\(itemPath).text")
                let label = item["label"] == nil ? "" : string(item["label"], path: "\(itemPath).label")
                let pressEnter = bool(item["pressEnter"], path: "\(itemPath).pressEnter")
                guard let text, let label, let pressEnter else { ok = false; continue }
                items.append(PaletteItem(text, pressEnter: pressEnter, label: label))
            }
            return ok ? items : nil
        }

        private mutating func action(_ value: JSONValue, path: String) -> TriggerAction? {
            guard case .object(let fields) = value else { return fail(path, .wrongType) }
            guard let type = fields["type"]?.stringValue else { return fail("\(path).type", .wrongType) }
            switch type {
            case "chord":
                guard let name = string(fields["key"], path: "\(path).key") else { return nil }
                guard let entry = KeyCatalog.entry(named: name) else { return fail("\(path).key", .unknownKey) }
                let modifiers = fields["modifiers"] == nil ? [] : keyModifiers(fields["modifiers"]!, path: "\(path).modifiers")
                let repeats = bool(fields["repeat"], path: "\(path).repeat")
                guard let modifiers, let repeats else { return nil }
                return .chord(KeyChord(entry.keyCode, modifiers), repeats: repeats)
            case "systemShortcut":
                guard let name = string(fields["name"], path: "\(path).name") else { return nil }
                guard let shortcut = SystemShortcut(name: name) else { return fail("\(path).name", .unknownSystemShortcut) }
                return .systemShortcut(shortcut)
            case "text":
                let text = string(fields["text"], path: "\(path).text")
                let pressEnter = bool(fields["pressEnter"], path: "\(path).pressEnter")
                guard let text, let pressEnter else { return nil }
                return .text(text, pressEnter: pressEnter)
            case "openPalette":
                return .openPalette
            case "none":
                return TriggerAction.none
            default:
                return fail("\(path).type", .unknownActionType)
            }
        }

        private mutating func keyModifiers(_ value: JSONValue, path: String) -> Set<KeyModifier>? {
            guard case .array(let names) = value else { return fail(path, .wrongType) }
            var result: Set<KeyModifier> = []
            for (index, name) in names.enumerated() {
                let elementPath = "\(path)[\(index)]"
                guard let string = name.stringValue else { return fail(elementPath, .wrongType) }
                guard let modifier = KeyModifier(rawValue: string) else { return fail(elementPath, .unknownModifier) }
                // Repetição é erro de forma: a lista descreve um conjunto.
                guard result.insert(modifier).inserted else { return fail(elementPath, .wrongType) }
            }
            return result
        }

        private mutating func version(_ value: JSONValue?, path: String) -> Bool {
            guard let value else { record(path, .unsupportedVersion); return false }
            guard let number = value.intValue else { record(path, .wrongType); return false }
            guard number == ShortcutConfigValidation.supportedVersion else { record(path, .unsupportedVersion); return false }
            return true
        }

        private mutating func string(_ value: JSONValue?, path: String) -> String? {
            guard let string = value?.stringValue else { return fail(path, .wrongType) }
            return string
        }

        /// Booleano opcional, falso quando ausente.
        private mutating func bool(_ value: JSONValue?, path: String) -> Bool? {
            guard let value else { return false }
            guard let flag = value.boolValue else { return fail(path, .wrongType) }
            return flag
        }

        private mutating func record(_ path: String, _ rule: ShortcutIssue.Rule) {
            issues.append(ShortcutIssue(path: path, rule: rule))
        }

        private mutating func fail<T>(_ path: String, _ rule: ShortcutIssue.Rule) -> T? {
            record(path, rule)
            return nil
        }
    }
}
