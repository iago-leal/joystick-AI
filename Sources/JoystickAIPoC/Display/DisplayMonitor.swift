import AppKit
import CoreGraphics
import JoystickCore

/// Limites do cursor pela união das telas ativas e reação a reconfigurações (D-14, D-20, RF-21).
final class DisplayMonitor {
    private let log: DiagnosticLog
    private let injector: EventInjector
    private let inputQueue: DispatchQueue
    private var refreshPending = false

    /// Chamado na main thread após cada reconfiguração já aplicada.
    var onChange: (() -> Void)?

    init(log: DiagnosticLog, injector: EventInjector, inputQueue: DispatchQueue) {
        self.log = log
        self.injector = injector
        self.inputQueue = inputQueue
    }

    /// Deve ser chamado na main thread, uma única vez.
    func start() {
        let union = ScreenUnion(rects: Self.activeRects())
        inputQueue.async { self.injector.screens = union }
        CGDisplayRegisterReconfigurationCallback({ _, flags, context in
            guard let context, !flags.contains(.beginConfigurationFlag) else { return }
            let monitor = Unmanaged<DisplayMonitor>.fromOpaque(context).takeUnretainedValue()
            DispatchQueue.main.async { monitor.scheduleRefresh() }
        }, Unmanaged.passUnretained(self).toOpaque())
    }

    static func activeRects() -> [ScreenRect] {
        var count: UInt32 = 0
        guard CGGetActiveDisplayList(0, nil, &count) == .success, count > 0 else { return [] }
        var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
        guard CGGetActiveDisplayList(count, &ids, &count) == .success else { return [] }
        return ids.prefix(Int(count)).map { id in
            let b = CGDisplayBounds(id)
            return ScreenRect(x: Double(b.origin.x), y: Double(b.origin.y), width: Double(b.width), height: Double(b.height))
        }
    }

    /// O sistema chama de volta uma vez por tela afetada; as chamadas próximas viram uma única atualização.
    private func scheduleRefresh() {
        guard !refreshPending else { return }
        refreshPending = true
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) { [weak self] in
            guard let self else { return }
            self.refreshPending = false
            self.refresh()
        }
    }

    private func refresh() {
        let rects = Self.activeRects()
        log.log(LogEventCatalog.displaysChanged(count: rects.count))
        ScreenCatalog.emit(log: log)
        let union = ScreenUnion(rects: rects)
        inputQueue.async { [injector, log] in
            injector.screens = union
            guard !rects.isEmpty else { return }
            let location = injector.currentLocation()
            guard !union.contains(location) else { return }
            let target = union.clamp(location)
            CGWarpMouseCursorPosition(CGPoint(x: target.x, y: target.y))
            CGAssociateMouseAndMouseCursorPosition(1)
            log.log(LogEventCatalog.cursorReclamped())
        }
        onChange?()
    }
}
