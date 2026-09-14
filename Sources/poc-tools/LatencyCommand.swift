import Foundation
import JoystickCore

/// Latências do bloco (d) (RF-11, RF-25 d, D-19).
enum LatencyCommand {
    static let processingTargetMs = 5.0
    static let inputToMotionTargetMs = 20.0

    static let usage = """
    uso: poc-tools latency <log>

    Calcula contagem, p50, p95 e máximo de `t_delivered − t_arrival` (processamento, meta 5 ms)
    e de `t_posted − t_arrival` (entrada ao movimento, meta 20 ms). O log precisa de --debug.
    A medida termina no CGEvent.post, e não no pixel exibido (R-12).
    """

    static func run(_ arguments: [String]) -> Int32 {
        let (read, status) = ToolInput.readLog(arguments, usage: usage)
        guard let read else { return status }
        let samples = LogAnalysis.latencySamples(read.records)
        var lines = [
            "| Medida | Amostras | p50 (ms) | p95 (ms) | Máximo (ms) | Aprovada |",
            "|--------|----------|----------|----------|-------------|----------|",
        ]
        lines.append(row("Processamento (`t_delivered − t_arrival`)", samples.processing, target: processingTargetMs))
        lines.append(row("Entrada ao movimento (`t_posted − t_arrival`)", samples.inputToMotion, target: inputToMotionTargetMs))
        print(lines.joined(separator: "\n"))
        return 0
    }

    static func row(_ label: String, _ samples: [UInt64], target: Double) -> String {
        guard let summary = LatencyStats.summarize(samples) else {
            return "| \(label) | 0 | - | - | - | sem amostras |"
        }
        let verdict = summary.passes(thresholdMs: target) ? "sim (p95 ≤ \(Int(target)) ms)" : "não (p95 > \(Int(target)) ms)"
        return "| \(label) | \(summary.count) | \(ms(summary.p50Ms)) | \(ms(summary.p95Ms)) | \(ms(summary.maxMs)) | \(verdict) |"
    }

    static func ms(_ value: Double) -> String { String(format: "%.3f", value) }
}
