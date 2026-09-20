import Foundation

/// Estado de carga reportado pelo sistema para um controle (`011-bateria-e-cursor-no-menu` D-01, D-03).
///
/// Espelho puro dos quatro estados da interface de controles do sistema, escrito aqui para que a decisão de
/// exibição não precise importar o framework: o núcleo depende apenas de `Foundation` (ADR-001).
public enum ControllerChargeState: String, CaseIterable, Codable, Sendable {
    case unknown, discharging, charging, full
}

/// Leitura crua da carga de um controle, antes de qualquer decisão de exibição.
///
/// O cabeçalho do sistema documenta dois padrões que contrariam a intuição e governam D-02: o nível tem valor
/// padrão **0**, e não valor ausente, e o estado tem valor padrão **desconhecido**. Um controle que não informa
/// carga responde, portanto, com a propriedade presente, nível 0 e estado desconhecido, o que viraria "0%" na
/// tela se a decisão olhasse o número.
public struct ControllerCharge: Equatable, Sendable {
    /// De 0,0 a 1,0, como o sistema entrega.
    public var level: Double
    public var state: ControllerChargeState

    public init(level: Double, state: ControllerChargeState) {
        self.level = level
        self.state = state
    }
}

/// O que o editor e a paleta mostram na área da carga (`011-bateria-e-cursor-no-menu` D-03, RN-01 a RN-07).
///
/// Concentrar a decisão aqui é o único antídoto disponível para TD-01, que registra a ausência de teste
/// automatizado no alvo do aplicativo: as duas interfaces recebem o resultado pronto e nenhuma delas volta a
/// raciocinar sobre nível ou estado, o que também as impede de divergir na fronteira da faixa baixa.
public enum ChargeDisplay: Equatable, Sendable {
    /// Não há controle ativo: as interfaces dizem isso em texto, sem número e sem zero (RN-03).
    case noController
    /// Há controle ativo, mas o sistema não informa a carga dele (RN-04).
    case unavailable
    case known(percent: Int, charging: Bool, low: Bool)

    /// Limite da faixa baixa, decidido pelo usuário na clarificação de 2026-09-20 (RN-07). Constante do código,
    /// e não chave de configuração: um valor ajustável exigiria validação, faixa aceita e gravação por fusão,
    /// custo desproporcional para um número que o usuário não pediu para ajustar.
    public static let lowThreshold = 15

    public var isLow: Bool {
        if case .known(_, _, let low) = self { return low }
        return false
    }

    /// Decide o que mostrar a partir da presença de controle ativo e da leitura crua.
    ///
    /// A ordem de precedência é a de `data-delta.md` §2 e não admite atalho: a indisponibilidade nasce da ausência
    /// da leitura **ou** do estado desconhecido, nunca do valor do nível (D-02). O arredondamento acontece antes da
    /// comparação com o limite, de modo que a faixa baixa é definida sobre o número que o usuário lê; sem essa
    /// ordem, dois controles exibindo 15% poderiam receber marcações diferentes.
    public static func decide(hasActiveController: Bool, charge: ControllerCharge?) -> ChargeDisplay {
        guard hasActiveController else { return .noController }
        guard let charge, charge.state != .unknown else { return .unavailable }
        let percent = min(100, max(0, Int((charge.level * 100).rounded())))
        let charging = charge.state == .charging || charge.state == .full
        return .known(percent: percent, charging: charging, low: percent <= lowThreshold)
    }
}
