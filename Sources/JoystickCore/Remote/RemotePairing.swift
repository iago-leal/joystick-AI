import Foundation

/// Motivo de recusa do pareamento, enviado à página em `reject` (`interfaces/remote-keyboard-protocol.md` §3.4).
public enum PairingRejection: String, Equatable, Sendable {
    case badCode = "bad_code"
    case busy
    case badToken = "bad_token"
}

/// Resposta à primeira mensagem do canal (`008-iphone-teclado-remoto` D-05, D-06).
public enum PairingOutcome: Equatable, Sendable {
    /// Código aceito: token novo.
    case accepted(token: [UInt8])
    /// Token da sessão aceito; com `replacesActive`, o servidor solta e fecha a conexão ativa antes (código 4004).
    case resumed(token: [UInt8], replacesActive: Bool)
    case rejected(PairingRejection)
    /// Quinta falha seguida: o código mudou e a janela de pareamento mostra o novo.
    case codeRotated
}

/// Pareamento do teclado remoto: código de 6 dígitos por ligação do recurso, limite de falhas e token de 128 bits.
///
/// Com conexão ativa, só o token da sessão entra (e a substitui); qualquer outra credencial recebe `busy`, sem somar
/// falha nem revelar se o token é válido. As comparações são em tempo constante.
public struct RemotePairing: Sendable {
    public static let maxFailures = 5
    public static let tokenBytes = 16

    public private(set) var code: String
    public private(set) var failures = 0
    public private(set) var token: [UInt8]?
    public private(set) var activeSession = false
    private let random: @Sendable (Int) -> [UInt8]

    /// `random` devolve `n` bytes aleatórios; os testes passam um gerador determinístico.
    public init(random: @escaping @Sendable (Int) -> [UInt8] = RemotePairing.systemRandom) {
        self.random = random
        code = Self.makeCode(random)
    }

    public static let systemRandom: @Sendable (Int) -> [UInt8] = { count in
        var generator = SystemRandomNumberGenerator()
        return (0..<count).map { _ in UInt8.random(in: .min ... .max, using: &generator) }
    }

    public mutating func present(code candidate: String) -> PairingOutcome {
        guard !activeSession else { return .rejected(.busy) }
        if Self.constantTimeEqual(Array(candidate.utf8), Array(code.utf8)) {
            let newToken = random(Self.tokenBytes)
            token = newToken
            failures = 0
            activeSession = true
            return .accepted(token: newToken)
        }
        failures += 1
        guard failures >= Self.maxFailures else { return .rejected(.badCode) }
        rotateCode()
        return .codeRotated
    }

    public mutating func present(token candidate: [UInt8]) -> PairingOutcome {
        guard let token, Self.constantTimeEqual(candidate, token) else {
            return .rejected(activeSession ? .busy : .badToken)
        }
        let replaces = activeSession
        activeSession = true
        return .resumed(token: token, replacesActive: replaces)
    }

    /// Fim da conexão da sessão (`bye`, queda, vigia de 10 s); código e token seguem válidos para retomar.
    public mutating func endSession() {
        activeSession = false
    }

    /// Recurso desligado ou religado: código novo, token e falhas descartados (RN-04).
    public mutating func reset() {
        rotateCode()
        token = nil
        activeSession = false
    }

    private mutating func rotateCode() {
        code = Self.makeCode(random)
        failures = 0
    }

    /// Seis dígitos uniformes, por rejeição dos valores acima do maior múltiplo de 1.000.000.
    static func makeCode(_ random: (Int) -> [UInt8]) -> String {
        let limit = UInt32.max - UInt32.max % 1_000_000
        for _ in 0..<64 {
            let value = random(4).reduce(UInt32(0)) { $0 << 8 | UInt32($1) }
            if value < limit {
                let digits = String(value % 1_000_000)
                return String(repeating: "0", count: 6 - digits.count) + digits
            }
        }
        return "000000"
    }

    static func constantTimeEqual(_ lhs: [UInt8], _ rhs: [UInt8]) -> Bool {
        guard lhs.count == rhs.count else { return false }
        var difference: UInt8 = 0
        for index in lhs.indices { difference |= lhs[index] ^ rhs[index] }
        return difference == 0
    }
}
