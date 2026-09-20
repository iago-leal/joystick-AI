import Foundation
import JoystickCore

/// Executa no roteador de entradas o que a `VirtualControllerMachine` decide
/// (`010-joystick-virtual-iphone` D-03, D-04, D-08).
///
/// Todo acesso ocorre na fila `input`, a mesma do controle e a mesma do teclado remoto, de modo que as entradas das
/// três origens chegam ao Mac na ordem de chegada (008 RN-14).
///
/// O executor não registra o iPhone como controle (D-13): mantém à parte o conjunto de botões, que o `InputContext`
/// soma ao do controle ativo, e entrega os eventos pelo mesmo caminho da leitura do controle, de modo que cliques,
/// camadas de atalho, paleta e apontamento valham sem nenhuma regra duplicada. Por esse mesmo caminho, o botão do
/// iPhone já descarta o contexto das sugestões no `InputRouter` (`009-sugestao-de-palavras` D-06).
final class VirtualControllerActions {
    /// Mesma cadência do vigia do teclado remoto, na mesma fila.
    static let watchdogPeriod: DispatchTimeInterval = .milliseconds(250)
    /// Teto de mensagens de entrada por segundo (§4 do protocolo): as excedentes caem em silêncio, sem encerrar a
    /// sessão, porque excesso aqui é página apressada, não aparelho hostil.
    static let maxMessagesPerSecond = 240

    private let context: InputContext
    private var machine: VirtualControllerMachine?
    private var watchdogTimer: DispatchSourceTimer?
    /// Última amostra normalizada entregue de cada analógico, para não repetir o valor depois da zona morta, como
    /// `AxisTouchReader.deliverStick` faz com o controle físico.
    private var lastStick: [VirtualStick: (x: Double, y: Double)] = [:]
    /// Janela de um segundo do limite de cadência, com o instante em que começou.
    private var windowStartNs: UInt64 = 0
    private var windowCount = 0

    init(context: InputContext) {
        self.context = context
    }

    var isActive: Bool { machine != nil }

    /// Estado do bloco central em vigor; a página o confirma pela mensagem `mode`.
    var mode: CenterMode? { machine?.mode }

    /// Sessão nova: máquina limpa, no estado que a página ainda vai confirmar, e vigia ligado.
    func begin() {
        context.assertOnQueue()
        end()
        let now = MonotonicClock.nowNs()
        machine = VirtualControllerMachine(nowNs: now)
        lastStick = [:]
        windowStartNs = now
        windowCount = 0
        let timer = DispatchSource.makeTimerSource(queue: context.queue)
        timer.schedule(deadline: .now() + Self.watchdogPeriod, repeating: Self.watchdogPeriod, leeway: .milliseconds(20))
        timer.setEventHandler { [weak self] in self?.watchdogTick() }
        timer.resume()
        watchdogTimer = timer
    }

    /// Fim da sessão: solta tudo e devolve as contagens para `remote.disconnected` (D-10).
    @discardableResult
    func end() -> (buttons: Int, clicks: Int) {
        context.assertOnQueue()
        guard let machine else { return (0, 0) }
        releaseAll()
        watchdogTimer?.cancel()
        watchdogTimer = nil
        let counts = (machine.buttonCount, machine.clickCount)
        self.machine = nil
        context.virtualPressed = []
        lastStick = [:]
        return counts
    }

    /// Mensagem do controle vinda da página; devolve `false` quando não é de sua alçada.
    @discardableResult
    func handle(_ message: RemoteKeyboardMessage.Client) -> Bool {
        context.assertOnQueue()
        guard machine != nil else { return false }
        let now = MonotonicClock.nowNs()
        machine!.noteMessage(nowNs: now)
        switch message {
        case .button, .stick, .pad:
            // A excedente conta como atividade da sessão, mas não produz entrada (§4 do protocolo). A troca de
            // estado do bloco central fica de fora: é mensagem de estado, e descartá-la poria Mac e página em
            // desacordo, que é justamente o estado preso que o limite existe para evitar.
            guard withinBudget(nowNs: now) else { return true }
        case .mode:
            break
        default:
            return false
        }
        switch message {
        case .button(let button, let down):
            deliver(machine!.button(button, down: down, nowNs: now))
        case .stick(let stick, let sample):
            deliver(machine!.stick(stick, sample: sample, nowNs: now))
        case .pad(let sample):
            deliver(machine!.pad(sample, nowNs: now))
        case .mode(let mode):
            deliver(machine!.apply(mode: mode, nowNs: now))
        default:
            return false
        }
        return true
    }

    /// Solta tudo o que o iPhone mantém: vigia, `release`, `bye`, silêncio, substituição de sessão e desligamento
    /// (§5 do protocolo). Segura sem sessão aberta.
    func releaseAll() {
        context.assertOnQueue()
        guard machine != nil else { return }
        deliver(machine!.releaseAll(nowNs: MonotonicClock.nowNs()))
    }

    /// Limite de cadência por janela de um segundo (§4 do protocolo).
    private func withinBudget(nowNs: UInt64) -> Bool {
        if nowNs < windowStartNs || nowNs - windowStartNs >= 1_000_000_000 {
            windowStartNs = nowNs
            windowCount = 0
        }
        windowCount += 1
        return windowCount <= Self.maxMessagesPerSecond
    }

    /// Vigia (§5 do protocolo): com algo mantido e um segundo sem mensagem da página, solta tudo.
    private func watchdogTick() {
        guard machine != nil, let events = machine!.tick(nowNs: MonotonicClock.nowNs()) else { return }
        deliver(events)
        context.log.log(LogEventCatalog.remoteWatchdog(held: events.filter { $0.kind == .buttonUp }.count))
    }

    /// Entrega os eventos ao roteador pelo mesmo caminho da leitura do controle, depois de atualizar o conjunto de
    /// botões do contexto, para que quem ler a união já veja o estado novo.
    private func deliver(_ events: [InputEvent]) {
        guard !events.isEmpty, let machine else { return }
        context.virtualPressed = Set(machine.pressed.map(\.buttonID))
        for event in events {
            switch (event.kind, event.element) {
            case (.axis, .leftStick?), (.axis, .rightStick?):
                deliverStick(event)
            default:
                context.sink.handle(event)
            }
        }
    }

    /// A zona morta e o limite de `pointer` são aplicados aqui, e não na máquina pura, pelo mesmo motivo e com a mesma
    /// regra do controle físico: o motor de movimento recebe valores já com a zona morta (D-05).
    private func deliverStick(_ event: InputEvent) {
        guard let stick: VirtualStick = event.element == .leftStick ? .left : (event.element == .rightStick ? .right : nil)
        else { return }
        let normalized = Normalization.stick(x: event.x ?? 0, y: event.y ?? 0, deadzone: context.settings.deadzone)
        // Repetições do mesmo valor normalizado (tremor dentro da zona morta, sobretudo) não geram entrega.
        guard lastStick[stick].map({ $0 != normalized }) ?? (normalized != (x: 0.0, y: 0.0)) else { return }
        lastStick[stick] = normalized
        var delivered = event
        delivered.x = normalized.x
        delivered.y = normalized.y
        context.sink.handle(delivered)
    }
}
