import Foundation
import Testing
@testable import JoystickCore

/// Pareamento do teclado remoto (`008-iphone-teclado-remoto` D-05, D-06, RN-04, RN-05).
@Suite struct RemotePairingTests {
    /// Gerador determinístico: devolve bytes crescentes a partir de uma semente, a cada chamada.
    final class Sequence: @unchecked Sendable {
        private var next: UInt8
        init(_ seed: UInt8) { next = seed }
        func bytes(_ count: Int) -> [UInt8] {
            (0..<count).map { _ in
                defer { next &+= 1 }
                return next
            }
        }
    }

    static func pairing(seed: UInt8 = 1) -> RemotePairing {
        let sequence = Sequence(seed)
        return RemotePairing { sequence.bytes($0) }
    }

    static func wrongCode(_ pairing: RemotePairing) -> String {
        pairing.code == "000000" ? "000001" : "000000"
    }

    @Test func codigoDeSeisDigitos() {
        for seed: UInt8 in [0, 1, 77, 250] {
            let code = Self.pairing(seed: seed).code
            #expect(code.count == 6 && code.allSatisfy(\.isNumber), "\(code)")
        }
        // 0x01020304 = 16909060 → 909060
        #expect(Self.pairing(seed: 1).code == "909060")
    }

    @Test func codigoCertoGeraTokenEZeraFalhas() throws {
        let pairing = Box(Self.pairing())
        #expect(pairing.present(code: Self.wrongCode(pairing.value)) == .rejected(.badCode))
        #expect(pairing.value.failures == 1)
        guard case .accepted(let token) = pairing.present(code: pairing.value.code) else {
            Issue.record("código certo recusado")
            return
        }
        #expect(token.count == 16)
        #expect(pairing.value.token == token)
        #expect(pairing.value.failures == 0)
        #expect(pairing.value.activeSession)
    }

    @Test func quintaFalhaGiraOCodigo() {
        let pairing = Box(Self.pairing())
        let original = pairing.value.code
        for _ in 1...4 {
            #expect(pairing.present(code: Self.wrongCode(pairing.value)) == .rejected(.badCode))
        }
        #expect(pairing.present(code: Self.wrongCode(pairing.value)) == .codeRotated)
        #expect(pairing.value.code != original)
        #expect(pairing.value.failures == 0)
        #expect(pairing.present(code: original) == .rejected(.badCode))
    }

    @Test func tokenReconectaSemSessaoAtiva() {
        let pairing = Box(Self.pairing())
        guard case .accepted(let token) = pairing.present(code: pairing.value.code) else { return }
        pairing.value.endSession()
        #expect(!pairing.value.activeSession)
        #expect(pairing.present(token: token) == .resumed(token: token, replacesActive: false))
        #expect(pairing.value.activeSession)
    }

    /// D-06 revista: o token da sessão substitui a conexão ativa.
    @Test func tokenDaSessaoSubstituiAConexaoAtiva() {
        let pairing = Box(Self.pairing())
        guard case .accepted(let token) = pairing.present(code: pairing.value.code) else { return }
        #expect(pairing.present(token: token) == .resumed(token: token, replacesActive: true))
        #expect(pairing.value.activeSession)
    }

    @Test func codigoOuTokenDesconhecidoComSessaoAtivaDaBusySemSomarFalha() {
        let pairing = Box(Self.pairing())
        let code = pairing.value.code
        guard case .accepted = pairing.present(code: code) else { return }
        #expect(pairing.present(code: code) == .rejected(.busy))
        #expect(pairing.present(code: Self.wrongCode(pairing.value)) == .rejected(.busy))
        #expect(pairing.present(token: [UInt8](repeating: 9, count: 16)) == .rejected(.busy))
        #expect(pairing.value.failures == 0)
    }

    @Test func tokenDesconhecidoSemSessaoDaBadToken() {
        let pairing = Box(Self.pairing())
        #expect(pairing.present(token: [UInt8](repeating: 9, count: 16)) == .rejected(.badToken))
        #expect(pairing.value.failures == 0)
    }

    @Test func desligarInvalidaCodigoEToken() {
        let pairing = Box(Self.pairing())
        let code = pairing.value.code
        guard case .accepted(let token) = pairing.present(code: code) else { return }
        pairing.value.reset()
        #expect(pairing.value.token == nil)
        #expect(!pairing.value.activeSession)
        #expect(pairing.value.code != code)
        #expect(pairing.present(token: token) == .rejected(.badToken))
    }

    @Test func comparacaoEmTempoConstante() {
        #expect(RemotePairing.constantTimeEqual([1, 2, 3], [1, 2, 3]))
        #expect(!RemotePairing.constantTimeEqual([1, 2, 3], [1, 2, 4]))
        #expect(!RemotePairing.constantTimeEqual([1, 2], [1, 2, 3]))
    }
}
