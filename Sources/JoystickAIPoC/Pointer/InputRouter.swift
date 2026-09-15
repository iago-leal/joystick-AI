import Foundation
import JoystickCore

/// Distribui as entradas entre cliques e movimento (roadmap Fase 2), no lugar do destino que só registrava.
///
/// Com a paleta aberta, os botões vão a ela em vez dos atalhos; cliques e movimento seguem (`002-paleta-comandos` D-03).
final class InputRouter: InputSink {
    private let buttons: ButtonActions
    private let motion: MotionLoop
    private let shortcuts: ShortcutActions
    private let palette: PaletteActions

    /// Observador de botões pressionados, usado pela tela de alvos; altere só na fila `input`.
    var onButtonDown: ((ButtonID) -> Void)?

    init(buttons: ButtonActions, motion: MotionLoop, shortcuts: ShortcutActions, palette: PaletteActions) {
        self.buttons = buttons
        self.motion = motion
        self.shortcuts = shortcuts
        self.palette = palette
    }

    func handle(_ event: InputEvent) {
        switch event.kind {
        case .buttonDown, .buttonUp:
            buttons.handle(event)
            palette.noteActivity()
            if palette.isOpen {
                palette.handle(event)
            } else {
                shortcuts.handle(event)
            }
            if event.kind == .buttonDown, !event.synthetic, case .button(let button)? = event.element {
                onButtonDown?(button)
            }
        case .axis, .touch:
            palette.noteActivity()
            motion.handle(event)
        case .controllerDisconnected:
            palette.close(.disconnected)
            buttons.handle(event)
            shortcuts.handle(event)
            motion.handle(event)
        case .controllerConnected, .controllerError:
            break
        }
    }
}
