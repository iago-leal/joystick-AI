import Foundation
import JoystickCore

/// Cobertura dos 18 botões para o bloco (a) (RF-25 a).
enum ButtonsCommand {
    static let usage = """
    uso: poc-tools buttons <log>

    Lista os 18 identificadores com pressionar (down) e soltar (up) observados em eventos
    `input.button` não sintéticos. O log precisa ter sido gravado com --debug.
    """

    static func run(_ arguments: [String]) -> Int32 {
        let (read, status) = ToolInput.readLog(arguments, usage: usage)
        guard let read else { return status }
        let coverage = LogAnalysis.buttonCoverage(read.records)
        var lines = ["| Botão | down | up |", "|-------|------|----|"]
        for button in ButtonID.allCases {
            let observation = coverage.observed[button]!
            lines.append("| `\(button.rawValue)` | \(observation.down ? "✓" : "✗") | \(observation.up ? "✓" : "✗") |")
        }
        print(lines.joined(separator: "\n"))
        print("")
        print("Total: \(coverage.covered) de 18.")
        return 0
    }
}
