import Foundation
import JoystickCore

/// Ciclos de conexão e reinícios para o RNF de robustez.
enum CyclesCommand {
    static let usage = """
    uso: poc-tools cycles <log>

    Conta ciclos completos de conexão e desconexão, conexões sem desconexão correspondente e
    sessões no arquivo; mais de uma sessão indica que a PoC reiniciou. Meta: 100 ciclos, 1 sessão.
    """

    static func run(_ arguments: [String]) -> Int32 {
        let (read, status) = ToolInput.readLog(arguments, usage: usage)
        guard let read else { return status }
        let cycles = LogAnalysis.cycles(read.records)
        print("| Medida | Valor |")
        print("|--------|-------|")
        print("| Ciclos completos | \(cycles.completeCycles) |")
        print("| Conexões sem desconexão correspondente | \(cycles.unmatchedConnections) |")
        print("| Sessões no arquivo | \(cycles.sessions)\(cycles.sessions > 1 ? " (reinício detectado)" : "") |")
        return 0
    }
}
