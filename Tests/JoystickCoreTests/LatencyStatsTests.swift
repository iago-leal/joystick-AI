import Testing
@testable import JoystickCore

@Suite struct LatencyStatsTests {
    @Test func percentisPorPosicaoMaisProxima() throws {
        let samples: [UInt64] = (1...100).map { UInt64($0) * 100_000 } // 0,1 ms a 10 ms
        let summary = try #require(LatencyStats.summarize(samples.shuffled()))
        #expect(summary.count == 100)
        #expect(summary.p50Ms == 5.0)
        #expect(summary.p95Ms == 9.5)
        #expect(summary.maxMs == 10.0)
    }

    @Test func aprovacaoContraAsMetas() throws {
        let fast = try #require(LatencyStats.summarize([1_000_000, 2_000_000, 4_000_000]))
        #expect(fast.passes(thresholdMs: 5))
        let slow = try #require(LatencyStats.summarize([1_000_000, 25_000_000]))
        #expect(!slow.passes(thresholdMs: 20))
    }

    @Test func amostraUnica() throws {
        let one = try #require(LatencyStats.summarize([3_000_000]))
        #expect(one.p50Ms == 3.0 && one.p95Ms == 3.0 && one.maxMs == 3.0)
    }

    @Test func amostraVazia() {
        #expect(LatencyStats.summarize([]) == nil)
    }
}
