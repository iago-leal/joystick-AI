import Foundation
import Testing
@testable import JoystickCore

/// Quando uma leitura de carga vira evento de log (`011-bateria-e-cursor-no-menu` D-09, RN-12).
///
/// O log não tem rotação nem limpeza (TD-07) e a consulta ocorre a cada 60 s enquanto uma interface estiver aberta.
/// Registrar toda leitura somaria uma linha por minuto de editor aberto, sem ganho: a curva de descarga de um
/// controle não precisa de resolução de um minuto para servir ao diagnóstico.
///
/// `shouldLog` é mutante, e o `#expect` do Swift Testing captura o valor sem poder mutá-lo; daí cada chamada sair
/// para uma constante antes da asserção.
@Suite struct ChargeLogPolicyTests {
    static let conexao = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    static let outra = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

    @Test func primeiraLeituraDaConexaoRegistra() {
        var policy = ChargeLogPolicy()
        let registrou = policy.shouldLog(connection: Self.conexao, percent: 84, state: .discharging)
        #expect(registrou)
    }

    @Test func leituraNaMesmaFaixaDeDezNaoRegistra() {
        var policy = ChargeLogPolicy()
        _ = policy.shouldLog(connection: Self.conexao, percent: 84, state: .discharging)
        for percent in [83, 82, 81, 80, 89] {
            let registrou = policy.shouldLog(connection: Self.conexao, percent: percent, state: .discharging)
            #expect(!registrou, "\(percent)% está na mesma dezena de 84%")
        }
    }

    @Test func mudancaDeDezenaRegistra() {
        var policy = ChargeLogPolicy()
        _ = policy.shouldLog(connection: Self.conexao, percent: 84, state: .discharging)
        let caiuParaSetenta = policy.shouldLog(connection: Self.conexao, percent: 79, state: .discharging)
        let seguiuNaMesma = policy.shouldLog(connection: Self.conexao, percent: 71, state: .discharging)
        let caiuParaSessenta = policy.shouldLog(connection: Self.conexao, percent: 69, state: .discharging)
        #expect(caiuParaSetenta)
        #expect(!seguiuNaMesma)
        #expect(caiuParaSessenta)
    }

    @Test func trocaDeEstadoRegistraMesmoNaMesmaDezena() {
        var policy = ChargeLogPolicy()
        _ = policy.shouldLog(connection: Self.conexao, percent: 38, state: .discharging)
        let ligouOCabo = policy.shouldLog(connection: Self.conexao, percent: 38, state: .charging)
        let seguiuCarregando = policy.shouldLog(connection: Self.conexao, percent: 39, state: .charging)
        let tirouOCabo = policy.shouldLog(connection: Self.conexao, percent: 39, state: .discharging)
        #expect(ligouOCabo)
        #expect(!seguiuCarregando)
        #expect(tirouOCabo)
    }

    /// Cada conexão tem histórico próprio: promover um controle da fila não herda a dezena do anterior.
    @Test func conexaoNovaReiniciaOEstado() {
        var policy = ChargeLogPolicy()
        _ = policy.shouldLog(connection: Self.conexao, percent: 84, state: .discharging)
        let outraConexao = policy.shouldLog(connection: Self.outra, percent: 84, state: .discharging)
        let mesmaDezenaDaOutra = policy.shouldLog(connection: Self.outra, percent: 85, state: .discharging)
        let voltouAPrimeira = policy.shouldLog(connection: Self.conexao, percent: 84, state: .discharging)
        #expect(outraConexao)
        #expect(!mesmaDezenaDaOutra)
        #expect(voltouAPrimeira, "a volta à primeira conexão é leitura nova, porque o histórico guardado é o da outra")
    }

    /// Uma descarga completa cabe em pouco mais de dez registros, como a cardinalidade esperada do
    /// `interfaces/diagnostic-log.md` §3 promete, e não num por minuto de editor aberto.
    @Test func descargaCompletaCabeEmPoucosRegistros() {
        var policy = ChargeLogPolicy()
        var registros: [Int] = []
        for percent in stride(from: 100, through: 0, by: -1) where policy.shouldLog(connection: Self.conexao, percent: percent, state: .discharging) {
            registros.append(percent)
        }
        #expect(registros == [100, 99, 89, 79, 69, 59, 49, 39, 29, 19, 9])
    }
}
