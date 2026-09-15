import Foundation
import JoystickCore

/// Executa a `PaletteMachine`: repetição do direcional, digitação do item, log e publicação do estado ao painel.
///
/// Todo acesso ocorre na fila `input` (`002-paleta-comandos` D-11); o painel recebe cópias pela main thread.
final class PaletteActions {
    /// Intervalo entre o texto e o Enter quando `--palette-enter-delay-ms` não é informado (D-06, sonda P-01).
    static let defaultEnterDelayMs = 0
    static let idleTimeoutNs: UInt64 = 60_000_000_000
    static let idleCheckInterval: DispatchTimeInterval = .seconds(1)

    private let context: InputContext
    private let keyboard: KeyboardInjector
    private let enterDelayMs: Int
    private var machine = PaletteMachine()
    private var repeatTimer: DispatchSourceTimer?
    private var idleTimer: DispatchSourceTimer?
    private var lastInputNs: UInt64 = 0

    /// Verdadeiro com a tela de alvos aberta: PS não abre a paleta (D-13).
    var blocked = false
    /// Chamado na main thread a cada mudança de estado; defina antes de o controle começar a ser lido.
    var onRender: ((PaletteSnapshot) -> Void)?
    /// Chamado na main thread ao confirmar "Editar atalhos" (`003-editor-atalhos` RF-07); defina antes de ler o controle.
    var onOpenEditor: (() -> Void)?

    init(context: InputContext, keyboard: KeyboardInjector, enterDelayMs: Int) {
        self.context = context
        self.keyboard = keyboard
        self.enterDelayMs = enterDelayMs
    }

    var isOpen: Bool {
        context.assertOnQueue()
        return machine.isOpen
    }

    func open() {
        context.assertOnQueue()
        guard !blocked else {
            context.log.log(LogEventCatalog.paletteBlocked())
            return
        }
        let effects = machine.open()
        guard !effects.isEmpty else { return }
        context.log.log(LogEventCatalog.paletteOpened(selection: machine.selection + 1))
        lastInputNs = MonotonicClock.nowNs()
        startIdleTimer()
        perform(effects)
    }

    func handle(_ event: InputEvent) {
        context.assertOnQueue()
        guard case .button(let button)? = event.element else { return }
        switch event.kind {
        case .buttonDown: perform(machine.press(button))
        case .buttonUp: perform(machine.release(button))
        default: break
        }
    }

    func close(_ reason: PaletteCloseReason) {
        context.assertOnQueue()
        perform(machine.close(reason))
    }

    /// Qualquer entrada do controle adia o fechamento por inatividade (RF-09).
    func noteActivity() {
        context.assertOnQueue()
        if machine.isOpen { lastInputNs = MonotonicClock.nowNs() }
    }

    private func perform(_ effects: [PaletteEffect]) {
        for effect in effects {
            switch effect {
            case .render(let snapshot):
                if !snapshot.isOpen { stopIdleTimer() }
                let onRender = onRender
                DispatchQueue.main.async { onRender?(snapshot) }
            case .startRepeat:
                startRepeat()
            case .stopRepeat:
                stopRepeat()
            case .confirm(let index, let item):
                context.log.log(LogEventCatalog.paletteConfirmed(index: index, enter: item.pressEnter))
                type(item)
            case .closed(let reason):
                context.log.log(LogEventCatalog.paletteClosed(reason: reason))
            case .openEditor:
                // Sem `palette.confirmed`: o editor registra `editor.opened` com `source: palette`.
                let onOpenEditor = onOpenEditor
                DispatchQueue.main.async { onOpenEditor?() }
            }
        }
    }

    private func type(_ item: PaletteItem) {
        keyboard.type(item.text, pressEnter: false)
        guard item.pressEnter else { return }
        guard enterDelayMs > 0 else {
            pressReturn()
            return
        }
        context.queue.asyncAfter(deadline: .now() + .milliseconds(enterDelayMs)) { [weak self] in self?.pressReturn() }
    }

    private func pressReturn() {
        let chord = KeyChord(KeyChord.returnKey)
        keyboard.chordDown(chord)
        keyboard.chordUp(chord)
    }

    private func startRepeat() {
        stopRepeat()
        let timer = DispatchSource.makeTimerSource(queue: context.queue)
        timer.schedule(deadline: .now() + KeyRepeat.delay, repeating: KeyRepeat.interval, leeway: .milliseconds(5))
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            self.perform(self.machine.repeatTick())
        }
        timer.resume()
        repeatTimer = timer
    }

    private func stopRepeat() {
        repeatTimer?.cancel()
        repeatTimer = nil
    }

    private func startIdleTimer() {
        stopIdleTimer()
        let timer = DispatchSource.makeTimerSource(queue: context.queue)
        timer.schedule(deadline: .now() + Self.idleCheckInterval, repeating: Self.idleCheckInterval, leeway: .milliseconds(100))
        timer.setEventHandler { [weak self] in
            guard let self, self.machine.isOpen else { return }
            if MonotonicClock.nowNs() - self.lastInputNs >= Self.idleTimeoutNs {
                self.close(.idle)
            }
        }
        timer.resume()
        idleTimer = timer
    }

    private func stopIdleTimer() {
        idleTimer?.cancel()
        idleTimer = nil
    }
}
