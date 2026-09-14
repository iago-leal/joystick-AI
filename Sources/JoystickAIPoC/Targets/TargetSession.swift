import AppKit
import JoystickCore

/// Uma sequência de 20 tentativas da tela de alvos (RF-27, D-20, RN-12). Só na main thread.
final class TargetSession {
    static let summaryDuration: TimeInterval = 3
    private static let escapeKeyCode: UInt16 = 53

    private let log: DiagnosticLog
    private let writer: TargetRunWriter
    private let context: InputContext
    let screen: NSScreen
    private let environment: TargetEnvironment
    private let seed: UInt64
    private let settings: PointerSettings
    private let scrollUnit: ScrollUnit

    private var window: TargetWindow?
    private var monitor: Any?
    private var positions: [RectPt] = []
    private var attempts: [TargetAttempt] = []
    private var ignoredPhysicalClicks = 0
    private var targetShownNs: UInt64 = 0
    private var startedAt = Date()
    private(set) var isActive = false

    /// Chamado ao fechar a janela, com a sequência completa ou interrompida.
    var onFinish: (() -> Void)?

    init(
        log: DiagnosticLog, writer: TargetRunWriter, context: InputContext, screen: NSScreen,
        environment: TargetEnvironment, seed: UInt64, settings: PointerSettings, scrollUnit: ScrollUnit
    ) {
        self.log = log
        self.writer = writer
        self.context = context
        self.screen = screen
        self.environment = environment
        self.seed = seed
        self.settings = settings
        self.scrollUnit = scrollUnit
    }

    func start() {
        startedAt = Date()
        positions = TargetLayout.positions(seed: seed, widthPt: Int(screen.frame.width), heightPt: Int(screen.frame.height))
        let window = TargetWindow(screen: screen)
        self.window = window
        isActive = true

        monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .keyDown]) { [weak self] event in
            self?.handle(event) ?? event
        }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        log.log(LogEventCatalog.targetsStarted(environment: environment, seed: seed))
        showNextTarget()
    }

    /// Interrompe como incompleta (○, Esc, tela removida, injeção suspensa).
    func abort(_ reason: AbortReason) {
        guard isActive else { return }
        finish(complete: false, abortReason: reason)
    }

    private func handle(_ event: NSEvent) -> NSEvent? {
        guard isActive else { return event }
        switch event.type {
        case .keyDown where event.keyCode == Self.escapeKeyCode:
            abort(.user)
            return nil
        case .leftMouseDown where event.window === window:
            let injected = event.cgEvent?.getIntegerValueField(.eventSourceUserData) == EventInjector.sourceMark
            guard injected else {
                ignoredPhysicalClicks += 1
                return nil
            }
            recordAttempt(at: event)
            return nil
        default:
            return event
        }
    }

    private func recordAttempt(at event: NSEvent) {
        let index = attempts.count
        guard index < positions.count, let view = window?.targetView else { return }
        let elapsedMs = Int((MonotonicClock.nowNs() &- targetShownNs) / 1_000_000)
        // O ponto do clique serve só para o acerto e não é guardado (RN-12).
        let hit = view.rect(of: positions[index]).contains(view.convert(event.locationInWindow, from: nil))
        let l1Held = context.queue.sync { context.registry.pressed.contains(.l1) }
        attempts.append(TargetAttempt(index: index + 1, targetRectPt: positions[index], hit: hit, timeToClickMs: elapsedMs, l1Held: l1Held))
        showNextTarget()
    }

    private func showNextTarget() {
        guard let view = window?.targetView else { return }
        guard attempts.count < positions.count else {
            finish(complete: true, abortReason: nil)
            return
        }
        view.counter = "\(attempts.count + 1) / \(positions.count)"
        view.target = positions[attempts.count]
        targetShownNs = MonotonicClock.nowNs()
    }

    private func finish(complete: Bool, abortReason: AbortReason?) {
        isActive = false
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        let run = TargetRun(
            startedAt: TargetRun.timestamp(startedAt), environment: environment, complete: complete, abortReason: abortReason,
            seed: seed, screen: ScreenCatalog.descriptor(for: screen), settings: settings, scrollUnit: scrollUnit,
            attempts: attempts, ignoredPhysicalClicks: ignoredPhysicalClicks)

        guard complete, let view = window?.targetView else {
            writer.write(run, startedAt: startedAt)
            close()
            return
        }
        view.target = nil
        let percent = Int((run.summary.hitRate * 100).rounded())
        view.summary = "\(run.summary.hits) de \(run.summary.total) acertos (\(percent)%), tempo médio \(run.summary.meanTimeMs) ms"
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.summaryDuration) { [weak self] in
            guard let self else { return }
            self.writer.write(run, startedAt: self.startedAt)
            self.close()
        }
    }

    private func close() {
        window?.orderOut(nil)
        window = nil
        onFinish?()
    }
}
