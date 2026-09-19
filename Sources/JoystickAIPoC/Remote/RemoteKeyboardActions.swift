import AppKit
import Carbon.HIToolbox
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
///
/// Sugestões de palavras (`009-sugestao-de-palavras` D-02, D-05 a D-07): cada tecla é injetada e só depois traduzida e
/// levada ao `SuggestionContext` (RN-09); o contexto recente vive só aqui, em memória, da conexão à queda.
final class RemoteKeyboardActions {
    static let watchdogPeriod: DispatchTimeInterval = .milliseconds(250)

    private let context: InputContext
    private let keyboard: KeyboardInjector
    private let translator: KeyTextTranslator
    private let probe = SuggestionProbe()
    private var geometry: RemoteKeyGeometry
    private var machine: RemoteKeyboardMachine?
    private var repeatTimer: DispatchSourceTimer?
    private var watchdogTimer: DispatchSourceTimer?

    private var suggestions = SuggestionContext()
    private var language = SuggestionLanguage.pt
    private var suggestionsVisible = true
    /// A página conhece as sugestões; uma página antiga nunca envia `prefs` e não recebe `suggest`.
    private var suggestionsEnabled = false
    /// Última lista enviada à página, para resolver o índice do `pick`.
    private var offered: (revision: UInt64, words: [String])?

    /// Estado dos modificadores para a página; chamado na fila `input`.
    var onModifiers: (([KeyModifier: ModifierState]) -> Void)?
    /// Estado da trava do Caps Lock do sistema para a página; chamado na fila `input`.
    var onCapsLock: ((Bool) -> Void)?
    /// Consulta a fazer ao motor depois de cada mudança do contexto ou das preferências, com o idioma; `nil` pede faixa
    /// vazia na revisão informada. Chamado na fila `input`.
    var onSuggestionQuery: ((_ query: SuggestionQuery?, _ revision: UInt64, _ language: SuggestionLanguage) -> Void)?

    init(context: InputContext, keyboard: KeyboardInjector, translator: KeyTextTranslator, geometry: RemoteKeyGeometry) {
        self.context = context
        self.keyboard = keyboard
        self.translator = translator
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
        translator.reset()
        let timer = DispatchSource.makeTimerSource(queue: context.queue)
        timer.schedule(deadline: .now() + Self.watchdogPeriod, repeating: Self.watchdogPeriod, leeway: .milliseconds(20))
        timer.setEventHandler { [weak self] in self?.watchdogTick() }
        timer.resume()
        watchdogTimer = timer
        onModifiers?(machine!.modifierStates)
        if let on = keyboard.capsLockOn { onCapsLock?(on) }
    }

    /// Fim da sessão: solta tudo, apaga o contexto recente e devolve as teclas pressionadas e as sugestões aceitas
    /// nela, para `remote.disconnected`.
    @discardableResult
    func end() -> (keys: Int, suggestions: Int) {
        context.assertOnQueue()
        guard machine != nil else { return (0, 0) }
        releaseAll()
        watchdogTimer?.cancel()
        watchdogTimer = nil
        let counts = (machine?.keyCount ?? 0, suggestions.accepted)
        machine = nil
        suggestions = SuggestionContext()
        translator.reset()
        language = .pt
        suggestionsVisible = true
        suggestionsEnabled = false
        offered = nil
        return counts
    }

    /// Fonte de entrada nova: o tradutor passa a usá-la e o contexto é descartado (RN-03).
    func setLayout(_ layout: KeyTextTranslator.Layout?) {
        context.assertOnQueue()
        translator.setLayout(layout)
        discard()
    }

    /// Descarte do contexto recente quando o ponto de escrita pode ter mudado sem o app saber (RN-03, D-06): entrada do
    /// controle, troca de aplicativo em foco ou de fonte de entrada.
    func discard() {
        context.assertOnQueue()
        guard machine != nil else { return }
        suggestions.apply(.discard)
        translator.reset()
        publishSuggestions()
    }

    /// Filtra os candidatos do motor para a página (D-04, D-08); `nil` se o contexto mudou desde o pedido.
    func offer(_ candidates: [String], for query: SuggestionQuery) -> [String]? {
        context.assertOnQueue()
        guard machine != nil, suggestionsEnabled, suggestionsVisible,
              let words = suggestions.filter(candidates, for: query)
        else { return nil }
        offered = (query.revision, words)
        return words
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
        case .prefs(let language, let visible)?:
            machine.noteMessage(nowNs: now)
            self.machine = machine
            setPreferences(language: language, visible: visible)
            return .ok
        case .pick(let revision, let index)?:
            machine.noteMessage(nowNs: now)
            self.machine = machine
            pick(revision: revision, index: index, modifiers: machine.modifierStates)
            return .ok
        case .bye?:
            machine.noteMessage(nowNs: now)
            return .close(.bye)
        case .hello?, nil: effects = nil
        }
        guard let effects else {
            return machine.noteInvalid() ? .close(.invalidMessages) : .ok
        }
        machine.noteMessage(nowNs: now)
        // `feed` lê a máquina já atualizada.
        self.machine = machine
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
            case .keyDown(let code):
                keyboard.chordDown(KeyChord(code))
                feed(code)
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
        timer.setEventHandler { [weak self] in
            self?.keyboard.chordRepeat(KeyChord(code))
            self?.feed(code)
        }
        timer.resume()
        repeatTimer = timer
    }

    private func stopRepeat() {
        repeatTimer?.cancel()
        repeatTimer = nil
    }

    // MARK: - Sugestões

    private static let escape: UInt16 = 53
    private static let delete: UInt16 = 51
    private static let arrows: Set<UInt16> = [123, 124, 125, 126]

    /// Leva ao contexto a tecla já injetada (D-02, D-06, D-07). Descarta quando o ponto de escrita pode ter mudado
    /// (setas, Esc, ⌘ ou ⌃ mantido ou preso, ⌥⌫), quando nada foi escrito (portão fechado) e em entrada segura, em que
    /// nada é guardado (RN-06).
    private func feed(_ code: UInt16) {
        guard let machine else { return }
        let states = machine.modifierStates
        func active(_ modifier: KeyModifier) -> Bool { states[modifier, default: .released] != .released }
        let secure = IsSecureEventInputEnabled()
        guard keyboard.enabled, !secure, !active(.command), !active(.control),
              code != Self.escape, !Self.arrows.contains(code), !(code == Self.delete && active(.option))
        else {
            probe?.record(code: code, secure: secure, text: nil)
            suggestions.apply(.discard)
            translator.reset()
            publishSuggestions()
            return
        }
        if code == Self.delete {
            probe?.record(code: code, secure: false, text: nil)
            translator.reset()
            suggestions.apply(.backspace)
        } else {
            let capsLock = CGEventSource.flagsState(.hidSystemState).contains(.maskAlphaShift)
            let text = translator.text(code: code, shift: active(.shift), option: active(.option), capsLock: capsLock)
            probe?.record(code: code, secure: false, text: text)
            suggestions.apply(.text(text))
        }
        publishSuggestions()
    }

    /// Preferências da página (D-11): valem só na sessão; a faixa oculta não consulta o motor (RN-14).
    private func setPreferences(language: SuggestionLanguage, visible: Bool) {
        self.language = language
        suggestionsVisible = visible
        suggestionsEnabled = true
        publishSuggestions()
    }

    /// Aceitação (D-05, RN-04, RN-10, RN-11): só na revisão da lista enviada, com o portão aberto e sem modificador do
    /// iPhone mantido ou preso; o texto sai por `type`, que ignora a fonte de entrada. Recusada, nada muda.
    private func pick(revision: UInt64, index: Int, modifiers: [KeyModifier: ModifierState]) {
        guard keyboard.enabled, modifiers.values.allSatisfy({ $0 == .released }),
              let offered, offered.revision == revision, offered.words.indices.contains(index),
              let typed = suggestions.accept(offered.words[index], revision: revision)
        else { return }
        translator.reset()
        keyboard.type(typed, pressEnter: false)
        publishSuggestions()
    }

    private func publishSuggestions() {
        offered = nil
        guard suggestionsEnabled else { return }
        onSuggestionQuery?(suggestions.query(visible: suggestionsVisible), suggestions.revision, language)
    }
}
