import Foundation

/// Alvo de um problema no editor: gatilho, modificador, item da paleta ou a lista inteira.
public enum EditorTarget: Equatable, Hashable, Sendable {
    case trigger(layer: ButtonID?, button: ButtonID)
    case modifier(ButtonID)
    case paletteItem(Int)
    case palette
}

/// Problema que bloqueia "Salvar" (RF-12).
public struct EditorIssue: Equatable, Sendable {
    public let target: EditorTarget
    public let rule: ShortcutIssue.Rule

    public init(target: EditorTarget, rule: ShortcutIssue.Rule) {
        self.target = target
        self.rule = rule
    }
}

/// Aviso que não bloqueia a gravação.
public enum EditorWarning: Equatable, Sendable {
    /// Nenhum gatilho abre a paleta: o sofá fica sem acesso ao editor por ela (roadmap §9).
    case noPaletteTrigger
}

/// Operação recusada pelo rascunho, com o motivo exibido ao usuário (RF-14, RN-12).
public enum EditorOperationError: Error, Equatable, Sendable {
    case lastPaletteItem, paletteFull, multiline, textTooLong, labelTooLong, pointerButton

    public var message: String {
        switch self {
        case .lastPaletteItem: "A paleta precisa de ao menos um item."
        case .paletteFull: "A paleta aceita no máximo \(ShortcutsDocument.paletteItemLimit.upperBound) itens."
        case .multiline: "O texto deve ter uma única linha."
        case .textTooLong: "O texto aceita no máximo \(ShortcutsDocument.maxTextLength) caracteres."
        case .labelTooLong: "O rótulo aceita no máximo \(ShortcutsDocument.maxLabelLength) caracteres."
        case .pointerButton: "R1, R2 e o clique do touchpad são cliques fixos."
        }
    }
}

/// Rascunho puro do editor (`003-editor-atalhos` D-20): parte da configuração vigente, aplica as operações da
/// interface e expõe estado sujo, problemas por alvo e avisos. A validação é a mesma da leitura do arquivo (D-05).
public struct EditorDraft: Equatable, Sendable {
    /// Vigente quando o rascunho foi criado ou rebaseado.
    public private(set) var base: ShortcutsDocument
    public private(set) var document: ShortcutsDocument
    /// Camadas de onde a marcação de cada modificador tirou a "nenhuma" explícita; desmarcá-lo a devolve.
    private var removedNones: [ButtonID: [ButtonID?]] = [:]

    public init(base: ShortcutsDocument) {
        self.base = base
        self.document = base
    }

    public var isDirty: Bool { document != base }

    public var issues: [EditorIssue] {
        ShortcutConfigValidation.validate(document).compactMap { issue in
            Self.target(of: issue.path).map { EditorIssue(target: $0, rule: issue.rule) }
        }
    }

    public var warnings: [EditorWarning] {
        let config = document.shortcuts
        let opensPalette = config.layers.values.contains { actions in
            actions.contains { $0.value == .openPalette && !config.isModifier($0.key) && !ShortcutConfig.pointerButtons.contains($0.key) }
        }
        return opensPalette ? [] : [.noPaletteTrigger]
    }

    /// Camadas editáveis: a base e uma por modificador, na ordem de `ButtonID`.
    public var layers: [ButtonID?] {
        [nil] + document.shortcuts.modifiers.keys.sorted().map { Optional($0) }
    }

    /// Converte o caminho de um `ShortcutIssue` no alvo exibido pelo editor.
    public static func target(of path: String) -> EditorTarget? {
        let parts = path.split(separator: ".").map(String.init)
        switch parts.first {
        case "shortcuts":
            guard parts.count >= 3 else { return nil }
            let name = String(parts[2].prefix { $0 != "[" })
            if parts[1] == "modifiers" {
                return ButtonID(rawValue: name).map { .modifier($0) }
            }
            guard parts[1] == "layers" else { return nil }
            let layer = name == ShortcutConfigValidation.baseLayerName ? nil : ButtonID(rawValue: name)
            guard name == ShortcutConfigValidation.baseLayerName || layer != nil else { return nil }
            guard parts.count >= 4 else { return layer.map { .modifier($0) } }
            return ButtonID(rawValue: parts[3]).map { .trigger(layer: layer, button: $0) }
        case "palette":
            guard parts.count >= 2, parts[1].hasPrefix("items[") else { return .palette }
            let digits = parts[1].dropFirst("items[".count).prefix { $0 != "]" }
            return Int(digits).map { .paletteItem($0) } ?? .palette
        default:
            return nil
        }
    }

    // MARK: atalhos (RF-09, RF-11)

    /// Atribui `action` ao gatilho; `nil` volta a herdar da base (na base, equivale a "nenhuma" por ausência).
    public mutating func setAction(_ action: TriggerAction?, for button: ButtonID, in layer: ButtonID?) throws {
        guard !ShortcutConfig.pointerButtons.contains(button) else { throw EditorOperationError.pointerButton }
        if case .text(let text, _)? = action { try Self.checkText(text) }
        var actions = document.shortcuts.layers[layer] ?? [:]
        actions[button] = action
        setLayer(layer, actions)
    }

    /// Marca `button` como modificador ou altera as teclas que ele mantém. Ao marcar, "nenhuma" explícita do botão sai
    /// das camadas, porque modificador não tem ação (RN-04); ações reais permanecem e aparecem como problema até serem
    /// removidas (RF-12).
    public mutating func setModifier(_ button: ButtonID, keys: Set<KeyModifier>) throws {
        guard !ShortcutConfig.pointerButtons.contains(button) else { throw EditorOperationError.pointerButton }
        if document.shortcuts.modifiers[button] == nil {
            let layers = document.shortcuts.layers.keys.filter { document.shortcuts.layers[$0]?[button] == TriggerAction.none }
            for layer in layers {
                var actions = document.shortcuts.layers[layer]!
                actions[button] = nil
                setLayer(layer, actions)
            }
            removedNones[button] = layers
        }
        document.shortcuts.modifiers[button] = keys
    }

    /// Desmarca o modificador, removendo a camada dele com as ações próprias e devolvendo a "nenhuma" que a marcação
    /// tirou das camadas que ainda existem e não ganharam ação para o botão.
    public mutating func unsetModifier(_ button: ButtonID) {
        document.shortcuts.modifiers[button] = nil
        document.shortcuts.layers[button] = nil
        for layer in removedNones.removeValue(forKey: button) ?? [] where layer != button {
            guard layer.map({ document.shortcuts.modifiers[$0] != nil }) ?? true,
                  document.shortcuts.layers[layer]?[button] == nil else { continue }
            var actions = document.shortcuts.layers[layer] ?? [:]
            actions[button] = TriggerAction.none
            setLayer(layer, actions)
        }
    }

    /// Camada vazia sai do dicionário, para que o rascunho compare igual ao documento lido do arquivo.
    private mutating func setLayer(_ layer: ButtonID?, _ actions: [ButtonID: TriggerAction]) {
        document.shortcuts.layers[layer] = actions.isEmpty ? nil : actions
    }

    // MARK: paleta (RF-14, RN-12)

    public mutating func insertPaletteItem(_ item: PaletteItem, at index: Int) throws {
        guard document.palette.count < ShortcutsDocument.paletteItemLimit.upperBound else { throw EditorOperationError.paletteFull }
        try Self.checkText(item.text)
        try Self.checkLabel(item.label)
        document.palette.insert(item, at: min(max(index, 0), document.palette.count))
    }

    public mutating func removePaletteItem(at index: Int) throws {
        guard document.palette.count > 1 else { throw EditorOperationError.lastPaletteItem }
        guard document.palette.indices.contains(index) else { return }
        document.palette.remove(at: index)
    }

    /// Move o item uma posição para cima; sem efeito no primeiro.
    public mutating func movePaletteItemUp(at index: Int) {
        guard index > 0, document.palette.indices.contains(index) else { return }
        document.palette.swapAt(index, index - 1)
    }

    /// Move o item uma posição para baixo; sem efeito no último.
    public mutating func movePaletteItemDown(at index: Int) {
        guard document.palette.indices.contains(index), index < document.palette.count - 1 else { return }
        document.palette.swapAt(index, index + 1)
    }

    /// Reordenação por arrastar, na convenção de `onMove` do SwiftUI.
    public mutating func movePaletteItems(fromOffsets source: IndexSet, toOffset destination: Int) {
        let moving = source.filter { document.palette.indices.contains($0) }.map { document.palette[$0] }
        let before = source.filter { $0 < destination }.count
        var remaining = document.palette.enumerated().filter { !source.contains($0.offset) }.map(\.element)
        remaining.insert(contentsOf: moving, at: min(max(destination - before, 0), remaining.count))
        document.palette = remaining
    }

    /// Texto vazio é aceito durante a edição e aparece como problema; quebra de linha e excesso são recusados.
    public mutating func setPaletteText(_ text: String, at index: Int) throws {
        guard document.palette.indices.contains(index) else { return }
        try Self.checkText(text)
        let item = document.palette[index]
        document.palette[index] = PaletteItem(text, pressEnter: item.pressEnter, label: item.label)
    }

    public mutating func setPaletteLabel(_ label: String, at index: Int) throws {
        guard document.palette.indices.contains(index) else { return }
        try Self.checkLabel(label)
        let item = document.palette[index]
        document.palette[index] = PaletteItem(item.text, pressEnter: item.pressEnter, label: label)
    }

    public mutating func setPalettePressEnter(_ pressEnter: Bool, at index: Int) {
        guard document.palette.indices.contains(index) else { return }
        let item = document.palette[index]
        document.palette[index] = PaletteItem(item.text, pressEnter: pressEnter, label: item.label)
    }

    private static func checkText(_ text: String) throws {
        if ShortcutConfigValidation.isMultiline(text) { throw EditorOperationError.multiline }
        if text.count > ShortcutsDocument.maxTextLength { throw EditorOperationError.textTooLong }
    }

    private static func checkLabel(_ label: String) throws {
        if ShortcutConfigValidation.isMultiline(label) { throw EditorOperationError.multiline }
        if label.count > ShortcutsDocument.maxLabelLength { throw EditorOperationError.labelTooLong }
    }

    // MARK: restauração e conflito (D-25, D-26)

    /// Substitui mapeamento e paleta pelos padrões; a base continua a vigente até a gravação.
    public mutating func restoreDefaults() {
        document = ShortcutDefaults.document
        forgetRemovedNones()
    }

    /// Troca a base pela vigente nova; sem `keepChanges`, o rascunho passa a ser a própria base.
    public mutating func rebase(to newBase: ShortcutsDocument, keepChanges: Bool) {
        base = newBase
        if !keepChanges { document = newBase }
        forgetRemovedNones()
    }

    /// Só vale lembrar a "nenhuma" de botões que continuam modificadores no rascunho.
    private mutating func forgetRemovedNones() {
        removedNones = removedNones.filter { document.shortcuts.modifiers[$0.key] != nil }
    }
}
