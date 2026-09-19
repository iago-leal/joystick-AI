import Foundation
import GameController
import JoystickCore

/// Os 18 botões físicos do controle ativo, com os gatilhos pela normalização (D-06, RF-05, RF-07, RF-11).
///
/// A tabela depende do modelo (`007-controle-ipega` D-03): o Ipega chega com a mesma correspondência por posição do
/// DualSense (sondas de 2026-09-19), troca o clique do touchpad pelo Share e não entrega o Home por esta via.
enum ButtonReader {
    /// Mapeamento de D-06; `options` e `create` a confirmar no roteiro de 18 botões (P-05).
    static func digitalButtons(
        _ pad: GCExtendedGamepad, profile: GCPhysicalInputProfile, model: ControllerModel
    ) -> [(ButtonID, GCControllerButtonInput?)] {
        let modelButton: (ButtonID, GCControllerButtonInput?) = switch model {
        case .dualSense: (.touchpadClick, (pad as? GCDualSenseGamepad)?.touchpadButton)
        case .ipega: (.share, profile.buttons[GCInputButtonShare])
        }
        return [
            (.cross, pad.buttonA), (.circle, pad.buttonB), (.square, pad.buttonX), (.triangle, pad.buttonY),
            (.l1, pad.leftShoulder), (.r1, pad.rightShoulder),
            (.l3, pad.leftThumbstickButton), (.r3, pad.rightThumbstickButton),
            (.options, pad.buttonMenu), (.create, pad.buttonOptions), (.ps, pad.buttonHome),
            modelButton,
            (.dpadUp, pad.dpad.up), (.dpadDown, pad.dpad.down), (.dpadLeft, pad.dpad.left), (.dpadRight, pad.dpad.right),
        ]
    }

    static func attach(
        controller: GCController, gamepad: GCExtendedGamepad, model: ControllerModel, key: ObjectIdentifier,
        info: ControllerInfo, context: InputContext
    ) {
        for (button, input) in digitalButtons(gamepad, profile: controller.physicalInputProfile, model: model) {
            guard let input else {
                context.log.log(LogEventCatalog.controllerError(message: "elemento ausente para \(button.rawValue)"))
                continue
            }
            input.pressedChangedHandler = { _, _, pressed in
                let tArrival = MonotonicClock.nowNs()
                deliver(button, pressed: pressed, value: nil, tArrival: tArrival, controller: controller, key: key, context: context)
            }
        }

        for (button, trigger) in [(ButtonID.l2, gamepad.leftTrigger), (ButtonID.r2, gamepad.rightTrigger)] {
            var tracker = TriggerTracker()
            trigger.valueChangedHandler = { _, value, _ in
                let tArrival = MonotonicClock.nowNs()
                guard let pressed = tracker.update(Double(value)) else { return }
                deliver(button, pressed: pressed, value: Double(value), tArrival: tArrival, controller: controller, key: key, context: context)
            }
        }
    }

    /// Também chamado pelo leitor HID (`ExtendedReportActivator`) para o PS e o Home, sem controlador e na fila `input`.
    static func deliver(
        _ button: ButtonID, pressed: Bool, value: Double?, tArrival: UInt64,
        controller: GCController?, key: ObjectIdentifier, context: InputContext
    ) {
        // RN-01: entradas de controles que não são o ativo não produzem efeito.
        let changed = pressed ? context.registry.press(button, from: key) : context.registry.release(button, from: key)
        guard changed else { return }
        let tDelivered = MonotonicClock.nowNs()
        let frameworkTimestamp = controller?.physicalInputProfile.lastEventTimestamp
        context.log.log(LogEventCatalog.inputButton(
            button, phase: pressed ? .down : .up, synthetic: false,
            tArrival: tArrival, tDelivered: tDelivered, tFramework: frameworkTimestamp))
        context.sink.handle(InputEvent(
            kind: pressed ? .buttonDown : .buttonUp, element: .button(button), value: value,
            synthetic: false, timestamp: tArrival, frameworkTimestamp: frameworkTimestamp))
    }
}
