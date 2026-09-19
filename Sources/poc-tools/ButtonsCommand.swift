import Foundation
import JoystickCore

/// Cobertura dos 18 botões do modelo do log para o bloco (a) (RF-25 a; `007-controle-ipega` D-10).
enum ButtonsCommand {
    static let usage = """
    uso: poc-tools buttons <log>

    Lista os 18 identificadores do modelo do último `controller.connected` do log (DualSense sem
    `share`, Ipega sem `touchpadClick`; DualSense quando o campo `model` falta) com pressionar (down)
    e soltar (up) observados em eventos `input.button` não sintéticos. O log precisa ter sido gravado
    com --debug.
    """

    static func run(_ arguments: [String]) -> Int32 {
        let (read, status) = ToolInput.readLog(arguments, usage: usage)
        guard let read else { return status }
        let coverage = LogAnalysis.buttonCoverage(read.records)
        var lines = ["Modelo: \(coverage.model.rawValue)", "", "| Botão | down | up |", "|-------|------|----|"]
        for button in coverage.expected {
            let observation = coverage.observed[button]!
            lines.append("| `\(button.rawValue)` | \(observation.down ? "✓" : "✗") | \(observation.up ? "✓" : "✗") |")
        }
        print(lines.joined(separator: "\n"))
        print("")
        print("Total: \(coverage.covered) de \(coverage.expected.count).")
        return 0
    }
}
