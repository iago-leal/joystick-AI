import Foundation
import JoystickCore

/// Botões do controle convertidos em teclas pelo `ShortcutMapper`, conforme a configuração de atalhos vigente.
///
/// Todo acesso ocorre na fila `input`. A repetição segue `KeyRepeat` (`action-mapping` RF-10).
final class ShortcutActions {
    private let context: InputContext
    private let keyboard: KeyboardInjector
    private var mapper: ShortcutMapper
    private var repeatTimer: DispatchSourceTimer?
    private var repeatingChord: KeyChord?
    /// Acorde efetivamente pressionado por atalho de sistema, para soltá-lo ainda que as preferências mudem.
    private var systemChordsDown: [SystemShortcut: KeyChord] = [:]

    /// Chamado na fila `input` depois de soltas as teclas mantidas (`002-paleta-comandos` D-04).
    var onOpenPalette: (() -> Void)?

    init(context: InputContext, keyboard: KeyboardInjector, config: ShortcutConfig) {
        self.context = context
        self.keyboard = keyboard
        mapper = ShortcutMapper(config: config)
    }

    func handle(_ event: InputEvent) {
        context.assertOnQueue()
        switch event.kind {
        case .buttonDown:
            guard case .button(let button)? = event.element else { return }
            let actions = mapper.press(button)
            // Lido antes de executar: abrir a paleta solta tudo e zera o gatilho no mapeador.
            let trigger = mapper.lastTrigger
            perform(actions)
            if let trigger {
                context.log.log(LogEventCatalog.shortcutTriggered(button: trigger.button, layer: trigger.layer, type: trigger.type))
            }
        case .buttonUp:
            guard case .button(let button)? = event.element else { return }
            perform(mapper.release(button))
        case .controllerDisconnected:
            releaseAll()
        default:
            break
        }
    }

    /// Aplica uma configuração nova (`003-editor-atalhos` D-12, RN-09): interrompe a repetição, solta o que estiver
    /// mantido e recria o mapeador. Botões segurados durante a troca são ignorados até serem soltos, pois o mapeador
    /// novo não os tem como pressionados.
    func apply(_ config: ShortcutConfig) {
        context.assertOnQueue()
        stopRepeat()
        releaseAll()
        mapper = ShortcutMapper(config: config)
    }

    /// Solta teclas e modificadores mantidos e devolve as solturas feitas, com cada `systemUp` convertido no `keyUp` do
    /// acorde pressionado, para que `repeatReleases` o repita na retomada da injeção (adendo 001 `pointer-control` EC-01).
    @discardableResult
    func releaseAll() -> [ShortcutAction] {
        context.assertOnQueue()
        let actions = mapper.releaseAll()
        let released = actions.map { action in
            guard case .systemUp(let shortcut) = action, let chord = systemChordsDown[shortcut] else { return action }
            return .keyUp(chord)
        }
        perform(actions)
        return released
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
            case .systemDown(let shortcut):
                let chord = Self.currentChord(for: shortcut)
                systemChordsDown[shortcut] = chord
                keyboard.chordDown(chord)
            case .systemUp(let shortcut):
                guard let chord = systemChordsDown.removeValue(forKey: shortcut) else { continue }
                keyboard.chordUp(chord)
            }
        }
    }

    /// Acorde do atalho nas preferências do macOS no instante do uso; a leitura passa pelo *cache* do `cfprefsd`
    /// (`003-editor-atalhos` D-11, RN-07).
    static func currentChord(for shortcut: SystemShortcut) -> KeyChord {
        let hotKeys = CFPreferencesCopyAppValue("AppleSymbolicHotKeys" as CFString, "com.apple.symbolichotkeys" as CFString) as? [String: Any]
        return SystemShortcut.chords(fromSymbolicHotKeys: hotKeys)[shortcut] ?? shortcut.defaultChord
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
