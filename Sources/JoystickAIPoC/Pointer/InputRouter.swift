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
    private let context: InputContext
    private let keyboard: KeyboardInjector
    /// Quantas teclas de navegação foram enviadas ao menu desde a abertura; vai para o `menu.cycle`.
    private(set) var menuKeys = 0

    /// Observador de botões pressionados, usado pela tela de alvos; altere só na fila `input`.
    var onButtonDown: ((ButtonID) -> Void)?
    /// Botão do controle pressionado, fora os sintéticos, independente da paleta e do modo de identificação; chamado na
    /// fila `input`. O teclado remoto descarta o contexto das sugestões (`009-sugestao-de-palavras` D-06).
    var onControllerButtonDown: (() -> Void)?
    /// Botão pressionado no modo de identificação, entregue na main thread; defina antes de ler o controle.
    var onIdentify: ((ButtonID) -> Void)?
    private var identifying = false

    init(buttons: ButtonActions, motion: MotionLoop, shortcuts: ShortcutActions, palette: PaletteActions,
         context: InputContext, keyboard: KeyboardInjector) {
        self.buttons = buttons
        self.motion = motion
        self.shortcuts = shortcuts
        self.palette = palette
        self.context = context
        self.keyboard = keyboard
    }

    /// Navegação do menu do ícone pelo controle (`011-bateria-e-cursor-no-menu` E-03).
    ///
    /// Menu se navega por teclado, e teclado é o que o app já sabe injetar. O direcional vira seta, ✕ vira Return,
    /// ○ e PS viram Esc. Os botões de apontamento ficam de fora: o clique continua valendo, porque é assim que o
    /// menu se abre e se descarta clicando fora.
    private static func menuKey(for button: ButtonID) -> KeyChord? {
        switch button {
        case .dpadUp: KeyChord(KeyChord.upArrow, [])
        case .dpadDown: KeyChord(KeyChord.downArrow, [])
        case .dpadLeft: KeyChord(KeyChord.leftArrow, [])
        case .dpadRight: KeyChord(KeyChord.rightArrow, [])
        case .cross: KeyChord(KeyChord.returnKey, [])
        case .circle, .ps: KeyChord(KeyChord.escape, [])
        default: nil
        }
    }

    /// Enquanto o menu rastreia, nenhum botão que não seja de apontamento pode chegar ao mapeador de atalhos.
    ///
    /// Devolve verdadeiro quando consumiu o evento. Engolir o que não tem tradução é tão importante quanto
    /// traduzir o que tem: sem isso, ○ e △ seguiriam disparando acordes no aplicativo atrás do menu, que foi o
    /// vazamento que a sonda P-05 flagrou.
    private func handleWhileMenuTracking(_ event: InputEvent) -> Bool {
        guard context.menuTracking, case .button(let button)? = event.element,
              !ShortcutConfig.pointerButtons.contains(button) else { return false }
        guard let chord = Self.menuKey(for: button) else { return true }
        if event.kind == .buttonDown {
            keyboard.chordDown(chord)
            menuKeys += 1
        } else {
            keyboard.chordUp(chord)
        }
        return true
    }

    /// Zera a contagem na abertura do menu; o fechamento a lê para o `menu.cycle`.
    func menuTrackingBegan() {
        context.assertOnQueue()
        context.menuTracking = true
        menuKeys = 0
    }

    func menuTrackingEnded() -> Int {
        context.assertOnQueue()
        context.menuTracking = false
        return menuKeys
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
            if handleWhileMenuTracking(event) { return }
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
