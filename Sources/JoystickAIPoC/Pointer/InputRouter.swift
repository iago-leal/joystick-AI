import Foundation
import JoystickCore

/// Distribui as entradas entre cliques e movimento (roadmap Fase 2), no lugar do destino que só registrava.
final class InputRouter: InputSink {
    private let buttons: ButtonActions
    private let motion: MotionLoop
    private let shortcuts: ShortcutActions

    /// Observador de botões pressionados, usado pela tela de alvos; altere só na fila `input`.
    var onButtonDown: ((ButtonID) -> Void)?

    init(buttons: ButtonActions, motion: MotionLoop, shortcuts: ShortcutActions) {
        self.buttons = buttons
        self.motion = motion
        self.shortcuts = shortcuts
    }

    func handle(_ event: InputEvent) {
        switch event.kind {
        case .buttonDown, .buttonUp:
            buttons.handle(event)
            shortcuts.handle(event)
            if event.kind == .buttonDown, !event.synthetic, case .button(let button)? = event.element {
                onButtonDown?(button)
            }
        case .axis, .touch:
            motion.handle(event)
        case .controllerDisconnected:
            buttons.handle(event)
            shortcuts.handle(event)
            motion.handle(event)
        case .controllerConnected, .controllerError:
            break
        }
    }
}
