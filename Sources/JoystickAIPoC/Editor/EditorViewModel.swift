import Combine
import Foundation
import JoystickCore

/// Adapta o `EditorDraft` à interface do editor (`003-editor-atalhos` D-20). Só na main thread.
///
/// As regras ficam no rascunho; aqui ficam seleção, aba, modo de identificação, mensagens e a ponte com o
/// `ConfigStore`, que grava, aplica e informa as releituras externas (D-25, D-26).
final class EditorViewModel: ObservableObject {
    enum Tab: Equatable {
        case shortcuts, palette
    }

    enum Conflict: Equatable {
        /// O arquivo mudou por fora com o rascunho sujo (RF-18).
        case externalChange
        /// A última leitura do arquivo foi recusada; a vigente foi mantida (RF-04).
        case externalInvalid(ShortcutIssue)
    }

    /// Gravação que espera a confirmação da cópia do arquivo com erro de sintaxe (D-17).
    struct PendingBackup: Equatable {
        var line: Int?
        var restore: Bool
    }

    @Published private(set) var draft: EditorDraft
    @Published var tab: Tab = .shortcuts
    @Published var selectedLayer: ButtonID?
    @Published var selectedButton: ButtonID? = .cross
    @Published var identifying = false {
        didSet {
            guard identifying != oldValue else { return }
            onIdentifyingChange?(identifying)
        }
    }
    /// Operação recusada pelo rascunho, com o motivo.
    @Published var operationError: String?
    /// Erro da última gravação, com caminho e erro do sistema.
    @Published private(set) var saveError: String?
    @Published private(set) var pendingBackup: PendingBackup?
    @Published private(set) var conflict: Conflict?
    /// Motivo pelo qual a figura do controle não pôde ser exibida; `nil` com a figura normal
    /// (`004-figura-controle-web` D-10, D-14). Zerado a cada abertura; o `FigureBridge` o republica se a falha persistir.
    @Published var figureUnavailable: FigureFailureReason?
    /// Modelo do controle ativo, vindo do `ControllerReader`; `nil` sem controle (`007-controle-ipega` D-08).
    @Published var activeModel: ControllerModel?
    /// Carga do controle ativo já decidida pelo núcleo, vinda do `ChargePoller`
    /// (`011-bateria-e-cursor-no-menu` D-03, D-05). O editor desenha o que chega e não raciocina sobre nível.
    @Published var charge: ChargeDisplay = .noController

    private let store: ConfigStore
    private let log: DiagnosticLog

    /// Chamado a cada mudança do modo de identificação; leva o estado à fila `input` (D-24).
    var onIdentifyingChange: ((Bool) -> Void)?

    init(store: ConfigStore, log: DiagnosticLog) {
        self.store = store
        self.log = log
        draft = EditorDraft(base: store.state.current)
        store.addObserver { [weak self] state, trigger in self?.configChanged(state, trigger: trigger) }
    }

    // MARK: abertura e estado derivado

    /// Estado inicial lido do `ConfigStore` a cada abertura da janela (RF-04).
    func prepareForOpen() {
        let state = store.state
        if !draft.isDirty {
            draft.rebase(to: state.current, keepChanges: false)
        }
        if case .invalid(let issue) = state.status {
            conflict = .externalInvalid(issue)
        } else if conflict != .externalChange {
            conflict = nil
        }
        operationError = nil
        saveError = nil
        pendingBackup = nil
        figureUnavailable = nil
        if let layer = selectedLayer, draft.document.shortcuts.modifiers[layer] == nil {
            selectedLayer = nil
        }
    }

    var canSave: Bool { draft.isDirty && draft.issues.isEmpty }

    /// Estado da figura na camada selecionada, derivado do rascunho a cada leitura (`004-figura-controle-web` D-14).
    /// O `FigureBridge` compara com o último enviado e só fala com a página quando difere.
    var figureState: FigureState {
        FigureState(config: draft.document.shortcuts, layer: selectedLayer, selected: selectedButton, issues: draft.issues,
                    model: activeModel)
    }

    func issues(for target: EditorTarget) -> [EditorIssue] {
        draft.issues.filter { $0.target == target }
    }

    /// Problemas do botão em qualquer camada ou como modificador, para o destaque na figura.
    func hasIssue(_ button: ButtonID, in layer: ButtonID?) -> Bool {
        draft.issues.contains { issue in
            switch issue.target {
            case .trigger(let issueLayer, let issueButton): issueButton == button && issueLayer == layer
            case .modifier(let modifier): modifier == button
            default: false
            }
        }
    }

    // MARK: intenções de atalho

    func select(_ button: ButtonID) {
        selectedButton = button
    }

    /// Botão pressionado no controle com o modo de identificação ligado (RF-16).
    func identified(_ button: ButtonID) {
        tab = .shortcuts
        selectedButton = button
    }

    func setAction(_ action: TriggerAction?, for button: ButtonID, in layer: ButtonID?) {
        perform { try $0.setAction(action, for: button, in: layer) }
    }

    func setModifier(_ button: ButtonID, keys: Set<KeyModifier>) {
        perform { try $0.setModifier(button, keys: keys) }
    }

    func unsetModifier(_ button: ButtonID) {
        perform { $0.unsetModifier(button) }
        if selectedLayer == button { selectedLayer = nil }
    }

    // MARK: intenções de paleta

    func insertPaletteItem(at index: Int) {
        perform { try $0.insertPaletteItem(PaletteItem("", pressEnter: false), at: index) }
    }

    func removePaletteItem(at index: Int) {
        perform { try $0.removePaletteItem(at: index) }
    }

    func movePaletteItemUp(at index: Int) {
        perform { $0.movePaletteItemUp(at: index) }
    }

    func movePaletteItemDown(at index: Int) {
        perform { $0.movePaletteItemDown(at: index) }
    }

    func movePaletteItem(from source: Int, to destination: Int) {
        perform { $0.movePaletteItems(fromOffsets: IndexSet(integer: source), toOffset: destination) }
    }

    func setPaletteText(_ text: String, at index: Int) {
        perform { try $0.setPaletteText(text, at: index) }
    }

    func setPaletteLabel(_ label: String, at index: Int) {
        perform { try $0.setPaletteLabel(label, at: index) }
    }

    func setPalettePressEnter(_ pressEnter: Bool, at index: Int) {
        perform { $0.setPalettePressEnter(pressEnter, at: index) }
    }

    private func perform(_ operation: (inout EditorDraft) throws -> Void) {
        var copy = draft
        do {
            try operation(&copy)
            draft = copy
            operationError = nil
        } catch let error as EditorOperationError {
            operationError = error.message
        } catch {
            operationError = error.localizedDescription
        }
    }

    // MARK: gravação, descarte e restauração (RF-13, RF-15)

    /// Grava o rascunho; devolve verdadeiro se gravou.
    @discardableResult
    func save(confirmBackup: Bool = false) -> Bool {
        guard canSave || confirmBackup else { return false }
        return handle(store.save(draft.document, confirmBackup: confirmBackup), restore: false)
    }

    func discard() {
        draft.rebase(to: store.state.current, keepChanges: false)
        operationError = nil
        saveError = nil
        pendingBackup = nil
        if conflict == .externalChange { conflict = nil }
    }

    /// Chamado depois da confirmação de "Restaurar padrão".
    @discardableResult
    func restoreDefaults(confirmBackup: Bool = false) -> Bool {
        handle(store.restoreDefaults(confirmBackup: confirmBackup), restore: true)
    }

    func confirmBackup() {
        guard let pending = pendingBackup else { return }
        pendingBackup = nil
        if pending.restore {
            restoreDefaults(confirmBackup: true)
        } else {
            save(confirmBackup: true)
        }
    }

    func cancelBackup() {
        pendingBackup = nil
    }

    private func handle(_ outcome: ConfigStore.SaveOutcome, restore: Bool) -> Bool {
        switch outcome {
        case .saved:
            // A vigente gravada vira a base; as notificações de `editor` e `restore` não abrem conflito.
            draft.rebase(to: store.state.current, keepChanges: false)
            saveError = nil
            pendingBackup = nil
            conflict = nil
            selectedLayer = selectedLayer.flatMap { draft.document.shortcuts.modifiers[$0] == nil ? nil : $0 }
            return true
        case .needsBackupConfirmation(let line):
            pendingBackup = PendingBackup(line: line, restore: restore)
            return false
        case .failed(let message):
            saveError = message
            return false
        }
    }

    // MARK: conflito com gravação externa (D-25, RF-18)

    private func configChanged(_ state: ConfigState, trigger: ShortcutsTrigger) {
        guard trigger == .external else { return }
        if case .invalid(let issue) = state.status {
            // Leitura inválida: o erro aparece na faixa, sem tocar no rascunho.
            conflict = .externalInvalid(issue)
            return
        }
        if draft.isDirty {
            conflict = .externalChange
            log.log(LogEventCatalog.editorConflict(choice: .pending))
        } else {
            draft.rebase(to: state.current, keepChanges: false)
            conflict = nil
        }
    }

    /// "Recarregar do arquivo": descarta o rascunho.
    func reloadFromFile() {
        draft.rebase(to: store.state.current, keepChanges: false)
        conflict = nil
        log.log(LogEventCatalog.editorConflict(choice: .reload))
    }

    /// "Manter minhas alterações": a próxima gravação funde sobre o arquivo novo.
    func keepChanges() {
        draft.rebase(to: store.state.current, keepChanges: true)
        conflict = nil
        log.log(LogEventCatalog.editorConflict(choice: .keep))
    }

    func dismissInvalidNotice() {
        if case .externalInvalid = conflict { conflict = nil }
    }
}
