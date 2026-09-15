import Foundation
import JoystickCore

/// Botões do controle convertidos em teclas pelo `ShortcutMapper` (protótipo de atalhos, fora do escopo da PoC).
///
/// Todo acesso ocorre na fila `input`. A repetição segue `KeyRepeat` (`action-mapping` RF-10).
final class ShortcutActions {
    private let context: InputContext
    private let keyboard: KeyboardInjector
    private var mapper = ShortcutMapper(systemChords: SystemShortcut.chords(
        fromSymbolicHotKeys: CFPreferencesCopyAppValue("AppleSymbolicHotKeys" as CFString, "com.apple.symbolichotkeys" as CFString) as? [String: Any]))
    private var repeatTimer: DispatchSourceTimer?
    private var repeatingChord: KeyChord?

    /// Chamado na fila `input` depois de soltas as teclas mantidas (`002-paleta-comandos` D-04).
    var onOpenPalette: (() -> Void)?

    init(context: InputContext, keyboard: KeyboardInjector) {
        self.context = context
        self.keyboard = keyboard
    }

    func handle(_ event: InputEvent) {
        context.assertOnQueue()
        switch event.kind {
        case .buttonDown, .buttonUp:
            guard case .button(let button)? = event.element else { return }
            perform(event.kind == .buttonDown ? mapper.press(button) : mapper.release(button))
        case .controllerDisconnected:
            releaseAll()
        default:
            break
        }
    }

    /// Solta teclas e modificadores mantidos e devolve as solturas feitas.
    @discardableResult
    func releaseAll() -> [ShortcutAction] {
        context.assertOnQueue()
        let actions = mapper.releaseAll()
        perform(actions)
        return actions
    }

    /// Repete solturas já feitas, sem passar pelo mapeador nem pela contagem de modificadores.
    func repeatReleases(_ actions: [ShortcutAction]) {
        context.assertOnQueue()
        for action in actions {
            switch action {
            case .keyUp(let chord): keyboard.forceUp(chord)
            case .modifierUp(let modifier): keyboard.forceModifierUp(modifier)
            default: break
            }
        }
    }

    private func perform(_ actions: [ShortcutAction]) {
        for action in actions {
            switch action {
            case .keyDown(let chord, let repeats):
                keyboard.chordDown(chord)
                if repeats { startRepeat(chord) }
            case .keyUp(let chord):
                if chord == repeatingChord { stopRepeat() }
                keyboard.chordUp(chord)
            case .text(let text, let pressEnter):
                keyboard.type(text, pressEnter: pressEnter)
            case .modifierDown(let modifier):
                keyboard.modifierDown(modifier)
            case .modifierUp(let modifier):
                keyboard.modifierUp(modifier)
            case .openPalette:
                releaseAll()
                onOpenPalette?()
            }
        }
    }

    private func startRepeat(_ chord: KeyChord) {
        stopRepeat()
        repeatingChord = chord
        let timer = DispatchSource.makeTimerSource(queue: context.queue)
        timer.schedule(deadline: .now() + KeyRepeat.delay, repeating: KeyRepeat.interval, leeway: .milliseconds(5))
        timer.setEventHandler { [weak self] in self?.keyboard.chordRepeat(chord) }
        timer.resume()
        repeatTimer = timer
    }

    private func stopRepeat() {
        repeatTimer?.cancel()
        repeatTimer = nil
        repeatingChord = nil
    }
}
