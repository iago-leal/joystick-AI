import Foundation
import JoystickCore

/// Estado da configuração de atalhos e paleta (`003-editor-atalhos` `data-delta.md` §5).
struct ConfigState: Equatable {
    enum Status: Equatable {
        case valid
        /// Última leitura recusada; o primeiro problema identifica a linha exibida no alerta (RF-20).
        case invalid(ShortcutIssue)
    }

    /// Configuração vigente.
    var current: ShortcutsDocument
    var status: Status
    /// *Bytes* da última leitura ou gravação, para não reaplicar nem acusar conflito após a própria gravação (D-16).
    var lastBytes: Data?
    var source: ShortcutsSource
}

/// Dono da configuração vigente, só na main thread (`003-editor-atalhos` D-15).
///
/// Lê, valida, grava e publica a vigente à fila `input` por `onApply`, e o estado à barra de menus e ao editor pelos
/// observadores. Uma leitura inválida nunca substitui a vigente (RN-08).
final class ConfigStore {
    typealias Observer = (ConfigState, ShortcutsTrigger) -> Void

    enum SaveOutcome: Equatable {
        case saved
        case needsBackupConfirmation(line: Int?)
        case failed(message: String)
    }

    let url: URL
    private let log: DiagnosticLog
    private var observers: [Observer] = []
    private(set) var state = ConfigState(current: ShortcutDefaults.document, status: .valid, lastBytes: nil, source: .defaults)

    /// Recebe cada configuração que passa a vigorar depois do início; quem recebe a leva à fila `input` (D-12).
    var onApply: ((ShortcutsDocument) -> Void)?

    init(url: URL, log: DiagnosticLog) {
        self.url = url
        self.log = log
    }

    /// Observadores recebem o estado e o gatilho da mudança; na main thread.
    func addObserver(_ observer: @escaping Observer) {
        observers.append(observer)
    }

    /// Estado inicial pela leitura feita ao iniciar, antes do controle; não chama `onApply`, pois atalhos e paleta são
    /// criados já com a vigente.
    func start(with result: ConfigLoadResult) {
        dispatchPrecondition(condition: .onQueue(.main))
        state.lastBytes = result.data
        if let issue = result.shortcutIssues.first {
            state.status = .invalid(issue)
            logInvalid(result.shortcutIssues, trigger: .startup)
        } else {
            state.current = result.shortcuts
            state.source = result.shortcutsSource
            logLoaded(trigger: .startup, reason: result.shortcutsReason)
        }
    }

    /// Releitura do arquivo após evento de observação.
    func reload(trigger: ShortcutsTrigger) {
        dispatchPrecondition(condition: .onQueue(.main))
        let result = ConfigLoader.load(from: url)

        if result.shortcutsReason == .fileMissing {
            // Remover o arquivo mantém a vigente até o próximo início (RN-10).
            if state.lastBytes != nil {
                state.lastBytes = nil
                log.log(LogEventCatalog.shortcutsFileRemoved())
            } else {
                log.log(LogEventCatalog.shortcutsUnchanged(trigger: trigger))
            }
            return
        }
        if let data = result.data, data == state.lastBytes {
            log.log(LogEventCatalog.shortcutsUnchanged(trigger: trigger))
            return
        }
        state.lastBytes = result.data

        if let issue = result.shortcutIssues.first {
            state.status = .invalid(issue)
            logInvalid(result.shortcutIssues, trigger: trigger)
            notify(trigger)
            return
        }
        apply(result.shortcuts, source: result.shortcutsSource, reason: result.shortcutsReason, trigger: trigger)
    }

    /// Grava o documento pelo editor e o aplica (D-17). Falha não altera a vigente.
    func save(_ document: ShortcutsDocument, confirmBackup: Bool) -> SaveOutcome {
        write(document, confirmBackup: confirmBackup, trigger: .editor)
    }

    /// Grava e aplica mapeamento e paleta padrão (D-26).
    func restoreDefaults(confirmBackup: Bool) -> SaveOutcome {
        write(ShortcutDefaults.document, confirmBackup: confirmBackup, trigger: .restore)
    }

    private func write(_ document: ShortcutsDocument, confirmBackup: Bool, trigger: ShortcutsTrigger) -> SaveOutcome {
        dispatchPrecondition(condition: .onQueue(.main))
        switch ConfigWriter(url: url).write(document, confirmBackup: confirmBackup) {
        case .written(let bytes, let created, let backup):
            state.lastBytes = bytes
            if trigger == .restore {
                log.log(LogEventCatalog.shortcutsRestored())
            } else {
                log.log(LogEventCatalog.shortcutsSaved(created: created, backup: backup))
            }
            apply(document, source: .file, reason: nil, trigger: trigger)
            return .saved
        case .needsBackupConfirmation(let line):
            return .needsBackupConfirmation(line: line)
        case .failed(let message):
            log.log(LogEventCatalog.shortcutsSaveFailed(message: message))
            return .failed(message: message)
        }
    }

    private func apply(_ document: ShortcutsDocument, source: ShortcutsSource, reason: ShortcutsDefaultReason?, trigger: ShortcutsTrigger) {
        state.current = document
        state.status = .valid
        state.source = source
        logLoaded(trigger: trigger, reason: reason)
        onApply?(document)
        notify(trigger)
    }

    private func notify(_ trigger: ShortcutsTrigger) {
        let state = state
        observers.forEach { $0(state, trigger) }
    }

    private func logLoaded(trigger: ShortcutsTrigger, reason: ShortcutsDefaultReason?) {
        log.log(LogEventCatalog.shortcutsLoaded(
            trigger: trigger, source: state.source, reason: reason,
            modifiers: Array(state.current.shortcuts.modifiers.keys), items: state.current.palette.count))
    }

    private func logInvalid(_ issues: [ShortcutIssue], trigger: ShortcutsTrigger) {
        for issue in issues {
            log.log(LogEventCatalog.shortcutsInvalid(trigger: trigger, rule: issue.rule, path: issue.logPath, line: issue.line))
        }
    }
}
