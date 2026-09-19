import Foundation
import JoystickCore

/// Distribui as entradas entre cliques e movimento (roadmap Fase 2), no lugar do destino que só registrava.
///
/// Com a paleta aberta, os botões vão a ela em vez dos atalhos; cliques e movimento seguem (`002-paleta-comandos` D-03).
/// No modo de identificação do editor, os botões que não são de apontamento vão só ao editor (`003-editor-atalhos` D-24).
final class InputRouter: InputSink {
    private let buttons: ButtonActions
    private let motion: MotionLoop
    private let shortcuts: ShortcutActions
    private let palette: PaletteActions

    /// Observador de botões pressionados, usado pela tela de alvos; altere só na fila `input`.
    var onButtonDown: ((ButtonID) -> Void)?
    /// Botão do controle pressionado, fora os sintéticos, independente da paleta e do modo de identificação; chamado na
    /// fila `input`. O teclado remoto descarta o contexto das sugestões (`009-sugestao-de-palavras` D-06).
    var onControllerButtonDown: (() -> Void)?
    /// Botão pressionado no modo de identificação, entregue na main thread; defina antes de ler o controle.
    var onIdentify: ((ButtonID) -> Void)?
    private var identifying = false

    init(buttons: ButtonActions, motion: MotionLoop, shortcuts: ShortcutActions, palette: PaletteActions) {
        self.buttons = buttons
        self.motion = motion
        self.shortcuts = shortcuts
        self.palette = palette
    }

    /// Liga ou desliga o modo de identificação, na fila `input`. Ao ligar, fecha a paleta e solta as teclas mantidas pelos atalhos, pois
    /// os botões soltos durante o modo não chegam ao mapeador.
    func setIdentifying(_ on: Bool) {
        guard on != identifying else { return }
        identifying = on
        if on {
            palette.close(.identify)
            shortcuts.releaseAll()
        }
    }

    func handle(_ event: InputEvent) {
        switch event.kind {
        case .buttonDown, .buttonUp:
            buttons.handle(event)
            if event.kind == .buttonDown, !event.synthetic { onControllerButtonDown?() }
            if identifying, case .button(let button)? = event.element, !ShortcutConfig.pointerButtons.contains(button) {
                if event.kind == .buttonDown, !event.synthetic {
                    let onIdentify = onIdentify
                    DispatchQueue.main.async { onIdentify?(button) }
                }
                return
            }
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
