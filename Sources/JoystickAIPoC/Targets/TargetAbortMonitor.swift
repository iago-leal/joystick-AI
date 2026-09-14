import AppKit
import JoystickCore

/// Interrupções da tela de alvos (`target-run-result.md` §2, §4). Só na main thread.
///
/// Esc é tratado pela própria `TargetSession`; aqui ficam ○ no controle, a remoção da tela e a suspensão da injeção.
final class TargetAbortMonitor {
    private let session: TargetSession
    private let context: InputContext
    private let router: InputRouter
    private let displayMonitor: DisplayMonitor
    private let gate: InjectionGate
    private let screenID: CGDirectDisplayID?

    init(session: TargetSession, context: InputContext, router: InputRouter, displayMonitor: DisplayMonitor, gate: InjectionGate) {
        self.session = session
        self.context = context
        self.router = router
        self.displayMonitor = displayMonitor
        self.gate = gate
        screenID = ScreenCatalog.displayID(of: session.screen)
    }

    func start() {
        context.queue.async { [router, session] in
            router.onButtonDown = { button in
                guard button == .circle else { return }
                DispatchQueue.main.async { session.abort(.user) }
            }
        }
        displayMonitor.onChange = { [weak self] in
            guard let self, let screenID = self.screenID else { return }
            if !NSScreen.screens.contains(where: { ScreenCatalog.displayID(of: $0) == screenID }) {
                self.session.abort(.screenRemoved)
            }
        }
        gate.onSuspended = { [weak self] in self?.session.abort(.injectionSuspended) }
    }

    func stop() {
        context.queue.async { [router] in router.onButtonDown = nil }
        displayMonitor.onChange = nil
        gate.onSuspended = nil
    }
}
