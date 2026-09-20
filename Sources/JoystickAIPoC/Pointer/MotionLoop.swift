import Foundation
import JoystickCore

/// Movimento e rolagem com o temporizador único de 120 Hz (D-11, D-13, RF-12 a RF-14, RF-20).
///
/// Todo acesso ocorre na fila `input`; o temporizador também dispara nela.
final class MotionLoop {
    private let context: InputContext
    private let injector: EventInjector
    private let scrollInjector: ScrollInjector
    private let buttons: ButtonActions
    private var engine: PointerMotionEngine
    private var scrollMapper: ScrollMapper
    private var tracker = TouchpadTracker()
    private var timer: DispatchSourceTimer?
    private var lastTickNs: UInt64 = 0

    /// Maior intervalo aceito entre ticks, para que um atraso do sistema não vire salto do cursor.
    private static let maxTickSeconds = 0.05

    init(context: InputContext, injector: EventInjector, scrollInjector: ScrollInjector, buttons: ButtonActions) {
        self.context = context
        self.injector = injector
        self.scrollInjector = scrollInjector
        self.buttons = buttons
        engine = PointerMotionEngine(settings: context.settings)
        scrollMapper = ScrollMapper(unit: scrollInjector.unit, settings: context.settings)
    }

    func handle(_ event: InputEvent) {
        context.assertOnQueue()
        let pressed = context.pressedAll
        switch (event.kind, event.element) {
        case (.axis, .leftStick?):
            let out = engine.setLeftStick(x: event.x ?? 0, y: event.y ?? 0, pressed: pressed)
            apply(out, origin: out.stickOnset ? .stickOnset : nil, tArrival: event.timestamp)
        case (.axis, .rightStick?):
            let out = engine.setRightStick(x: event.x ?? 0, y: event.y ?? 0)
            if out.scrollOnset {
                // Primeira amostra fora da zona morta: rola na hora, sem esperar o tick.
                scrollMapper.reset()
                scrollStep(dt: PointerMotionEngine.tickInterval, origin: .stickOnset, tArrival: event.timestamp)
            }
            apply(out, origin: nil, tArrival: nil)
        case (.touch, _):
            guard let finger = event.touchIndex, let phase = event.touchPhase else { return }
            guard let delta = tracker.update(
                finger: finger, phase: phase, x: event.x ?? 0, y: event.y ?? 0, sensitivity: engine.settings.touchpadSensitivity)
            else { return }
            if event.remote {
                // O arrasto do iPhone não vira movimento na chegada: entra no planador e sai pelo tick, com a
                // cadência regular que a rede não tem (010 E-10). Por sair depois, não carrega `t_arrival`.
                apply(engine.remoteTouchDelta(delta, pressed: pressed), origin: nil, tArrival: nil)
            } else {
                apply(engine.touchDelta(delta, pressed: pressed), origin: .touch, tArrival: event.timestamp)
            }
        case (.controllerDisconnected, _):
            apply(engine.setLeftStick(x: 0, y: 0, pressed: []), origin: nil, tArrival: nil)
            apply(engine.setRightStick(x: 0, y: 0), origin: nil, tArrival: nil)
            tracker = TouchpadTracker()
            engine.clearTouchGlide()
            scrollMapper.reset()
        default:
            break
        }
    }

    private func apply(_ out: MotionOutput, origin: PostSource?, tArrival: UInt64?) {
        if let move = out.move {
            injector.move(by: move, kind: buttons.moveKind, origin: origin, tArrival: origin == nil ? nil : tArrival)
        }
        switch out.timer {
        case .start: startTimer()
        case .stop: stopTimer()
        case .none: break
        }
    }

    private func tick() {
        let now = MonotonicClock.nowNs()
        let dt = min(Self.maxTickSeconds, Double(now &- lastTickNs) / 1e9)
        lastTickNs = now
        let out = engine.tick(dt: dt, pressed: context.pressedAll)
        if let move = out.move {
            injector.move(by: move, kind: buttons.moveKind, origin: nil, tArrival: nil)
        }
        // Só o tick sabe que o planador esvaziou; sem isto o temporizador ficaria ligado depois do último arrasto.
        if out.timer == .stop { stopTimer() }
        let right = engine.state.rightStick
        if right.x != 0 || right.y != 0 {
            scrollStep(dt: dt, origin: nil, tArrival: nil)
        }
    }

    private func scrollStep(dt: Double, origin: PostSource?, tArrival: UInt64?) {
        let right = engine.state.rightStick
        let precision = PointerMotionEngine.precisionActive(pressed: context.pressedAll)
        let step = scrollMapper.step(x: right.x, y: right.y, dt: dt, precision: precision)
        scrollInjector.scroll(vertical: step.vertical, horizontal: step.horizontal, origin: origin, tArrival: tArrival)
    }

    private func startTimer() {
        guard timer == nil else { return }
        lastTickNs = MonotonicClock.nowNs()
        let source = DispatchSource.makeTimerSource(flags: .strict, queue: context.queue)
        let interval = DispatchTimeInterval.nanoseconds(Int(PointerMotionEngine.tickInterval * 1e9))
        source.schedule(deadline: .now() + interval, repeating: interval, leeway: .milliseconds(1))
        source.setEventHandler { [weak self] in self?.tick() }
        source.resume()
        timer = source
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }
}
