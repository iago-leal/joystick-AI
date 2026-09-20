import Foundation

/// Quando uma leitura de carga merece virar evento de log (`011-bateria-e-cursor-no-menu` D-09, RN-12).
///
/// O log não tem rotação nem limpeza (TD-07) e a consulta corre a cada 60 s enquanto o editor ou a paleta
/// estiverem abertos. Registrar toda leitura somaria uma linha por minuto de sessão sem ganho de diagnóstico:
/// a curva de descarga de um controle não precisa de resolução de um minuto para ser útil. A política guarda,
/// por conexão, a faixa de dez e o estado já registrados, e só deixa passar a mudança.
///
/// Vive no núcleo, e não no consultor, para ser verificável sem hardware, pelo mesmo motivo de `ChargeDisplay`.
public struct ChargeLogPolicy: Equatable, Sendable {
    private var connection: UUID?
    private var lastTens: Int?
    private var lastState: ControllerChargeState?

    public init() {}

    /// Devolve verdadeiro quando a leitura deve ser registrada, e já anota o que passou.
    ///
    /// Registra a primeira leitura de cada conexão, a mudança da casa das dezenas e a troca de estado. Conexão
    /// nova reinicia o histórico: promover um controle da fila não herda a faixa do anterior.
    public mutating func shouldLog(connection id: UUID, percent: Int, state: ControllerChargeState) -> Bool {
        let tens = percent / 10
        guard connection == id, let lastTens, let lastState else {
            connection = id
            lastTens = tens
            lastState = state
            return true
        }
        guard tens != lastTens || state != lastState else { return false }
        self.lastTens = tens
        self.lastState = state
        return true
    }
}
