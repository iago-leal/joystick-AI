import Foundation

public struct LatencySummary: Equatable, Sendable {
    public var count: Int
    public var p50Ms: Double
    public var p95Ms: Double
    public var maxMs: Double

    public func passes(thresholdMs: Double) -> Bool { p95Ms <= thresholdMs }
}

/// Estatísticas das latências do bloco (d) (D-19, RF-11).
public enum LatencyStats {
    /// Percentis pelo método da posição mais próxima; `nil` para amostra vazia.
    public static func summarize(_ samplesNs: [UInt64]) -> LatencySummary? {
        guard !samplesNs.isEmpty else { return nil }
        let sorted = samplesNs.sorted()
        func percentile(_ p: Double) -> Double {
            let rank = max(1, Int((p * Double(sorted.count)).rounded(.up)))
            return Double(sorted[rank - 1]) / 1_000_000
        }
        return LatencySummary(count: sorted.count, p50Ms: percentile(0.50), p95Ms: percentile(0.95), maxMs: Double(sorted.last!) / 1_000_000)
    }
}
