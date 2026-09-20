import Foundation
import JoystickCore

/// Consultor periódico da carga do controle ativo (`011-bateria-e-cursor-no-menu` D-04, RN-10, RN-11).
///
/// A interface de controles do sistema não emite notificação de mudança de carga: só há consulta, e por isso o
/// período é o que ele é. O temporizador acende apenas enquanto o editor ou a paleta estiverem abertos, o mesmo
/// critério de sob demanda do temporizador de movimento (ADR-006), e a leitura corre na main thread, sem entrar
/// na fila de entrada nem somar trabalho ao tique de 120 Hz. Só na main thread, como o `StatusMenu`.
final class ChargePoller {
    /// RN-10: com uma das interfaces aberta, o valor exibido se atualiza sozinho em no máximo 60 s.
    static let period: TimeInterval = 60

    private let log: DiagnosticLog
    private var timer: Timer?
    /// Quantas interfaces estão abertas; o temporizador segue a contagem, e não um booleano, porque editor e
    /// paleta abrem e fecham sem ordem entre si.
    private var openInterfaces = 0
    private var active: ControllerReader.ActiveController?
    private var policy = ChargeLogPolicy()

    /// Entregue a cada mudança, seja ela do canal do leitor ou da consulta periódica.
    var onDisplay: ((ChargeDisplay) -> Void)?

    private(set) var display: ChargeDisplay = .noController {
        didSet { if display != oldValue { onDisplay?(display) } }
    }

    init(log: DiagnosticLog) {
        self.log = log
    }

    /// Chamado pelo canal do leitor na conexão, na desconexão e na promoção do controle ativo: RN-10 exige que
    /// esses três reflitam de imediato, sem esperar o período.
    func activeChanged(to controller: ControllerReader.ActiveController?) {
        active = controller
        refresh()
    }

    func interfaceOpened() {
        openInterfaces += 1
        refresh()
        startTimerIfNeeded()
    }

    func interfaceClosed() {
        openInterfaces = max(0, openInterfaces - 1)
        stopTimerIfIdle()
    }

    /// Fechadas as duas interfaces, nenhuma leitura de carga acontece (RN-10, fim).
    private func startTimerIfNeeded() {
        guard timer == nil, openInterfaces > 0 else { return }
        let timer = Timer(timeInterval: Self.period, repeats: true) { [weak self] _ in
            self?.refresh()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func stopTimerIfIdle() {
        guard openInterfaces == 0 else { return }
        timer?.invalidate()
        timer = nil
    }

    /// Relê a carga do controle ativo e republica a decisão. Sem controle ativo não há o que ler.
    private func refresh() {
        guard let active else {
            display = .noController
            return
        }
        let charge = active.device.flatMap(ControllerReader.charge(of:))
        self.active?.charge = charge
        let decided = ChargeDisplay.decide(hasActiveController: true, charge: charge)
        display = decided
        logIfBandChanged(decided, connection: active.id, state: charge?.state)
    }

    /// RN-12: o log registra a carga na conexão e nas mudanças de faixa, nunca a cada leitura. Quem decide é a
    /// `ChargeLogPolicy`, no núcleo; aqui só se pergunta a ela. Carga indisponível não produz evento algum, pelo
    /// mesmo motivo que os campos são omitidos na conexão.
    private func logIfBandChanged(_ display: ChargeDisplay, connection: UUID, state: ControllerChargeState?) {
        guard case .known(let percent, _, _) = display, let state else { return }
        guard policy.shouldLog(connection: connection, percent: percent, state: state) else { return }
        log.log(LogEventCatalog.controllerCharge(id: connection, percent: percent, state: state))
    }
}
