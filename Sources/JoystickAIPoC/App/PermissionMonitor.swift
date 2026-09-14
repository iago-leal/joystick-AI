import ApplicationServices
import CoreGraphics
import Foundation
import JoystickCore

/// Consulta as permissões de Acessibilidade e Input Monitoring (D-15, RF-22).
///
/// `CGEvent.post` não informa descarte, por isso a detecção é por consulta periódica. A Acessibilidade é lida por
/// `AXIsProcessTrusted()`: no PM-3, `CGPreflightPostEventAccess()` continuou verdadeiro após a revogação com o app
/// aberto (P-08), enquanto o sistema já descartava os eventos.
final class PermissionMonitor {
    static let pollInterval: DispatchTimeInterval = .seconds(2)
    static let guidance = "Conceda a permissão em Ajustes do Sistema > Privacidade e Segurança > Acessibilidade > JoystickAIPoC; a PoC retoma o cursor sozinha em até 2 s."

    private let log: DiagnosticLog
    private let queue: DispatchQueue
    private var timer: DispatchSourceTimer?
    private var lastPostEvent: Bool?
    private var lastListenEvent: Bool?

    /// Chamado na fila de consulta sempre que a possibilidade de injetar muda, e uma vez ao iniciar.
    var onInjectionEnabledChange: ((Bool) -> Void)?

    private(set) var postEventAllowed = false

    init(log: DiagnosticLog, queue: DispatchQueue = .main) {
        self.log = log
        self.queue = queue
    }

    func start() {
        queue.async { [weak self] in
            guard let self else { return }
            self.check(trigger: .startup)
            if !self.postEventAllowed {
                // Uma única vez por processo, sem estado persistido, apenas para o app entrar na lista (P-10, R-16).
                _ = CGRequestPostEventAccess()
            }
            let timer = DispatchSource.makeTimerSource(queue: self.queue)
            timer.schedule(deadline: .now() + Self.pollInterval, repeating: Self.pollInterval, leeway: .milliseconds(200))
            timer.setEventHandler { [weak self] in self?.check(trigger: .poll) }
            timer.resume()
            self.timer = timer
        }
    }

    private func check(trigger: PermissionTrigger) {
        let postEvent = AXIsProcessTrusted()
        let listenEvent = CGPreflightListenEventAccess()
        let changed = postEvent != lastPostEvent || listenEvent != lastListenEvent
        guard changed else { return }

        let postChanged = postEvent != lastPostEvent
        lastPostEvent = postEvent
        lastListenEvent = listenEvent
        postEventAllowed = postEvent

        log.log(LogEventCatalog.permissionsStatus(postEvent: postEvent, listenEvent: listenEvent, trigger: trigger))
        if postChanged {
            if !postEvent {
                log.log(LogEventCatalog.permissionsGuidance(message: Self.guidance))
            }
            onInjectionEnabledChange?(postEvent)
        }
    }
}
