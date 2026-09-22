import Foundation
import GameController
import JoystickCore

/// Analógicos e touchpad do controle ativo (D-05, RF-06, RF-08, RN-12, P-01, P-02).
///
/// Nenhum valor de eixo nem posição do toque vai ao log: só inícios e fins de toque e as transições brutas.
/// O touchpad vale para os dois modelos Sony, DualSense e DualShock 4, com as superfícies obtidas por modelo
/// (`007-controle-ipega` D-03, RN-06; `012-controle-dualshock-4` D-03); o Ipega não tem touchpad. Os analógicos dos
/// modelos Sony vêm da interface de controles; os do Ipega, do relatório HID, porque o driver do sistema zera os eixos
/// desse clone (revisão de D-03 no PM-1 da 007): `ControllerReader` os entrega por `deliverStick`.
///
/// Num clone sem touchpad físico, como o GameSir G8+ no modo PlayStation, as superfícies existem e ficam mudas, salvo
/// pelo clique do touchpad, que o clone acompanha de um ponto de toque fixo (sonda P-01 de 2026-09-22): o par de
/// eventos de toque resultante não move o cursor, porque `TouchpadTracker` descarta as amostras de eixo dividido.
enum AxisTouchReader {
    /// Leitura por dedo, mantida pelo *closure* do elemento na fila `input`.
    private final class FingerState {
        var inference = ZeroTransitionPhaseInference()
    }

    /// Última amostra normalizada entregue de um analógico.
    final class StickState {
        var last = (x: 0.0, y: 0.0)
    }

    static func attach(
        controller: GCController, gamepad: GCExtendedGamepad, model: ControllerModel, key: ObjectIdentifier,
        info: ControllerInfo, context: InputContext
    ) {
        guard let surfaces = touchSurfaces(of: gamepad, model: model) else { return }
        attachStick(gamepad.leftThumbstick, element: .leftStick, key: key, context: context)
        attachStick(gamepad.rightThumbstick, element: .rightStick, key: key, context: context)

        let touchpads = controller.physicalInputProfile.touchpads
        let source: TouchSource = touchpads.isEmpty ? .zeroTransition : .touchState
        context.log.log(LogEventCatalog.controllerTouchSource(id: info.id, source: source))

        for (finger, surface) in [(0, surfaces.primary), (1, surfaces.secondary)] {
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

    /// Superfícies do touchpad por modelo; `nil` para o Ipega, que não liga nada aqui. No SDK, as do `GCDualShockGamepad`
    /// são opcionais, ao contrário das do `GCDualSenseGamepad`; a sonda de 2026-09-22 as mostrou presentes no GameSir.
    /// Sem elas, o DualShock 4 ficaria sem analógicos e sem touchpad, e por isso a ausência vale como perfil incompleto.
    private static func touchSurfaces(
        of gamepad: GCExtendedGamepad, model: ControllerModel
    ) -> (primary: GCControllerDirectionPad, secondary: GCControllerDirectionPad)? {
        switch model {
        case .dualSense:
            guard let pad = gamepad as? GCDualSenseGamepad else { return nil }
            return (pad.touchpadPrimary, pad.touchpadSecondary)
        case .dualShock4:
            guard let pad = gamepad as? GCDualShockGamepad, let primary = pad.touchpadPrimary, let secondary = pad.touchpadSecondary else { return nil }
            return (primary, secondary)
        case .ipega:
            return nil
        }
    }

    private static func attachStick(_ stick: GCControllerDirectionPad, element: InputElement, key: ObjectIdentifier, context: InputContext) {
        let state = StickState()
        stick.valueChangedHandler = { _, x, y in
            let tArrival = MonotonicClock.nowNs()
            deliverStick(element, x: Double(x), y: Double(y), tArrival: tArrival, state: state, key: key, context: context)
        }
    }

    /// Na fila `input`: normaliza e entrega a amostra do analógico do controle ativo.
    static func deliverStick(
        _ element: InputElement, x: Double, y: Double, tArrival: UInt64, state: StickState, key: ObjectIdentifier,
        context: InputContext
    ) {
        guard context.registry.isActive(key) else { return }
        let normalized = Normalization.stick(x: x, y: y, deadzone: context.settings.deadzone)
        // Repetições do mesmo valor normalizado (repouso, sobretudo) não geram entrega.
        guard normalized != state.last else { return }
        state.last = normalized
        context.sink.handle(InputEvent(kind: .axis, element: element, x: normalized.x, y: normalized.y, timestamp: tArrival))
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
