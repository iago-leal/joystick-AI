import AppKit
import JoystickCore

/// Soltura feita pelo teclado remoto, guardada para repetir na retomada da injeção (RI-04).
enum RemoteRelease {
    case key(UInt16)
    case modifier(KeyModifier)
    case capsLock
}

/// Executa no `KeyboardInjector` os efeitos da `RemoteKeyboardMachine` (`008-iphone-teclado-remoto` D-09),
/// repete a última tecla comum na cadência do macOS (D-10) e roda o vigia de 1 s (D-11).
///
/// Todo acesso ocorre na fila `input`, a mesma do controle, de modo que as entradas das duas origens chegam ao Mac na
/// ordem de chegada (RN-14) e somam modificadores pela mesma contagem (RN-08).
final class RemoteKeyboardActions {
    static let watchdogPeriod: DispatchTimeInterval = .milliseconds(250)

    private let context: InputContext
    private let keyboard: KeyboardInjector
    private var geometry: RemoteKeyGeometry
    private var machine: RemoteKeyboardMachine?
    private var repeatTimer: DispatchSourceTimer?
    private var watchdogTimer: DispatchSourceTimer?

    /// Estado dos modificadores para a página; chamado na fila `input`.
    var onModifiers: (([KeyModifier: ModifierState]) -> Void)?
    /// Estado da trava do Caps Lock do sistema para a página; chamado na fila `input`.
    var onCapsLock: ((Bool) -> Void)?

    init(context: InputContext, keyboard: KeyboardInjector, geometry: RemoteKeyGeometry) {
        self.context = context
        self.keyboard = keyboard
        self.geometry = geometry
    }

    var isActive: Bool { machine != nil }

    /// Geometria em uso; vale a partir da próxima sessão.
    func setGeometry(_ geometry: RemoteKeyGeometry) {
        context.assertOnQueue()
        self.geometry = geometry
    }

    /// Sessão nova: máquina limpa e vigia ligado.
    func begin() {
        context.assertOnQueue()
        _ = end()
        machine = RemoteKeyboardMachine(geometry: geometry, nowNs: MonotonicClock.nowNs())
        let timer = DispatchSource.makeTimerSource(queue: context.queue)
        timer.schedule(deadline: .now() + Self.watchdogPeriod, repeating: Self.watchdogPeriod, leeway: .milliseconds(20))
        timer.setEventHandler { [weak self] in self?.watchdogTick() }
        timer.resume()
        watchdogTimer = timer
        onModifiers?(machine!.modifierStates)
        if let on = keyboard.capsLockOn { onCapsLock?(on) }
    }

    /// Fim da sessão: solta tudo e devolve as teclas pressionadas nela, para `remote.disconnected`.
    func end() -> Int {
        context.assertOnQueue()
        guard machine != nil else { return 0 }
        releaseAll()
        watchdogTimer?.cancel()
        watchdogTimer = nil
        let count = machine?.keyCount ?? 0
        machine = nil
        return count
    }

    func handle(_ message: RemoteKeyboardMessage.Client?) -> RemoteChannelVerdict {
        context.assertOnQueue()
        guard var machine else { return .ok }
        defer { self.machine = machine }
        let now = MonotonicClock.nowNs()
        let effects: [RemoteKeyboardEffect]?
        switch message {
        case .down(let code, _)?: effects = machine.down(code)
        case .up(let code, _)?: effects = machine.up(code)
        case .ping?: effects = []
        case .release?: effects = machine.releaseAll().effects
        case .bye?:
            machine.noteMessage(nowNs: now)
            return .close(.bye)
        case .hello?, nil: effects = nil
        }
        guard let effects else {
            return machine.noteInvalid() ? .close(.invalidMessages) : .ok
        }
        machine.noteMessage(nowNs: now)
        perform(effects)
        return .ok
    }

    /// Solta tudo o que o iPhone mantém (portão, ciclo de vida, fim de sessão) e devolve as solturas feitas.
    @discardableResult
    func releaseAll() -> [RemoteRelease] {
        context.assertOnQueue()
        guard var machine else { return [] }
        let effects = machine.releaseAll().effects
        self.machine = machine
        perform(effects)
        return effects.compactMap { effect in
            switch effect {
            case .keyUp(let code): .key(code)
            case .modifierUp(let modifier): .modifier(modifier)
            case .capsLock(down: false): .capsLock
            default: nil
            }
        }
    }

    /// Repete solturas já feitas, sem passar pela contagem de modificadores (retomada da injeção).
    func repeatReleases(_ releases: [RemoteRelease]) {
        context.assertOnQueue()
        for release in releases {
            switch release {
            case .key(let code): keyboard.forceUp(KeyChord(code))
            case .modifier(let modifier): keyboard.forceModifierUp(modifier)
            case .capsLock: break  // Soltar a trava não posta nada (D-17 revista).
            }
        }
    }

    private func watchdogTick() {
        guard var machine, let fired = machine.tick(nowNs: MonotonicClock.nowNs()) else { return }
        self.machine = machine
        perform(fired.effects)
        context.log.log(LogEventCatalog.remoteWatchdog(held: fired.released))
    }

    private func perform(_ effects: [RemoteKeyboardEffect]) {
        for effect in effects {
            switch effect {
            case .keyDown(let code): keyboard.chordDown(KeyChord(code))
            case .keyUp(let code): keyboard.chordUp(KeyChord(code))
            case .modifierDown(let modifier): keyboard.modifierDown(modifier)
            case .modifierUp(let modifier): keyboard.modifierUp(modifier)
            case .capsLock(let down):
                if let on = keyboard.capsLock(down: down), down { onCapsLock?(on) }
            case .startRepeat(let code): startRepeat(code)
            case .stopRepeat: stopRepeat()
            case .modifiers(let states): onModifiers?(states)
            }
        }
    }

    /// Atraso e intervalo das preferências de teclado do macOS, lidos a cada início (D-10).
    private func startRepeat(_ code: UInt16) {
        stopRepeat()
        let delay = max(NSEvent.keyRepeatDelay, 0.05)
        let interval = max(NSEvent.keyRepeatInterval, 0.01)
        let timer = DispatchSource.makeTimerSource(queue: context.queue)
        timer.schedule(
            deadline: .now() + delay, repeating: .nanoseconds(Int(interval * 1_000_000_000)), leeway: .milliseconds(2))
        timer.setEventHandler { [weak self] in self?.keyboard.chordRepeat(KeyChord(code)) }
        timer.resume()
        repeatTimer = timer
    }

    private func stopRepeat() {
        repeatTimer?.cancel()
        repeatTimer = nil
    }
}
