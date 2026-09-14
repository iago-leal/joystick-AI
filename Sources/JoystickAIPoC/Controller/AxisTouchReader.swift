import Foundation
import GameController
import JoystickCore

/// Analógicos e touchpad do controle ativo (D-05, RF-06, RF-08, RN-12, P-01, P-02).
///
/// Nenhum valor de eixo nem posição do toque vai ao log: só inícios e fins de toque e as transições brutas.
enum AxisTouchReader {
    /// Leitura por dedo, mantida pelo *closure* do elemento na fila `input`.
    private final class FingerState {
        var inference = ZeroTransitionPhaseInference()
    }

    private final class StickState {
        var last = (x: 0.0, y: 0.0)
    }

    static func attach(controller: GCController, gamepad: GCDualSenseGamepad, key: ObjectIdentifier, info: ControllerInfo, context: InputContext) {
        attachStick(gamepad.leftThumbstick, element: .leftStick, key: key, context: context)
        attachStick(gamepad.rightThumbstick, element: .rightStick, key: key, context: context)

        let touchpads = controller.physicalInputProfile.touchpads
        let source: TouchSource = touchpads.isEmpty ? .zeroTransition : .touchState
        context.log.log(LogEventCatalog.controllerTouchSource(id: info.id, source: source))

        for (finger, surface) in [(0, gamepad.touchpadPrimary), (1, gamepad.touchpadSecondary)] {
            let state = FingerState()
            surface.valueChangedHandler = { _, x, y in
                let tArrival = MonotonicClock.nowNs()
                guard context.registry.isActive(key), let phase = state.inference.phase(x: Double(x), y: Double(y)) else { return }
                // A transição bruta é registrada em qualquer via, para responder a P-02.
                if phase != .moved {
                    context.log.log(LogEventCatalog.touchRawTransition(finger: finger, toZero: phase == .ended))
                }
                if source == .zeroTransition {
                    deliverTouch(finger: finger, phase: phase, x: Double(x), y: Double(y), tArrival: tArrival, context: context)
                }
            }
        }

        guard source == .touchState else { return }
        for (finger, name) in touchpads.keys.sorted().prefix(2).enumerated() {
            guard let touchpad = touchpads[name] else { continue }
            let handler: (TouchPhase) -> GCControllerTouchpadHandler = { phase in
                { _, x, y, _, _ in
                    let tArrival = MonotonicClock.nowNs()
                    guard context.registry.isActive(key) else { return }
                    deliverTouch(finger: finger, phase: phase, x: Double(x), y: Double(y), tArrival: tArrival, context: context)
                }
            }
            touchpad.touchDown = handler(.began)
            touchpad.touchMoved = handler(.moved)
            touchpad.touchUp = handler(.ended)
        }
    }

    private static func attachStick(_ stick: GCControllerDirectionPad, element: InputElement, key: ObjectIdentifier, context: InputContext) {
        let state = StickState()
        stick.valueChangedHandler = { _, x, y in
            let tArrival = MonotonicClock.nowNs()
            guard context.registry.isActive(key) else { return }
            let normalized = Normalization.stick(x: Double(x), y: Double(y), deadzone: context.settings.deadzone)
            // Repetições do mesmo valor normalizado (repouso, sobretudo) não geram entrega.
            guard normalized != state.last else { return }
            state.last = normalized
            context.sink.handle(InputEvent(kind: .axis, element: element, x: normalized.x, y: normalized.y, timestamp: tArrival))
        }
    }

    private static func deliverTouch(finger: Int, phase: TouchPhase, x: Double, y: Double, tArrival: UInt64, context: InputContext) {
        let position = Normalization.touchPosition(x: x, y: y)
        let tDelivered = MonotonicClock.nowNs()
        switch phase {
        case .began:
            context.log.log(LogEventCatalog.inputTouch(finger: finger, phase: .began, tArrival: tArrival, tDelivered: tDelivered))
        case .ended:
            context.log.log(LogEventCatalog.inputTouch(finger: finger, phase: .ended, tArrival: tArrival, tDelivered: tDelivered))
        case .moved:
            break
        }
        context.sink.handle(InputEvent(
            kind: .touch, element: .touch(finger), x: position.x, y: position.y,
            touchIndex: finger, touchPhase: phase, timestamp: tArrival))
    }
}
