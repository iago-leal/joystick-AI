import Foundation
import Testing
@testable import JoystickCore

@Suite struct TargetRunTests {
    @Test func mesmaSementeMesmasPosicoes() {
        let a = TargetLayout.positions(seed: 184467, widthPt: 1920, heightPt: 1080)
        let b = TargetLayout.positions(seed: 184467, widthPt: 1920, heightPt: 1080)
        let c = TargetLayout.positions(seed: 184468, widthPt: 1920, heightPt: 1080)
        #expect(a.count == 20)
        #expect(a == b)
        #expect(a != c)
    }

    @Test func margemEAlvoDentroDaTela() {
        for seed in UInt64(0)..<50 {
            for rect in TargetLayout.positions(seed: seed, widthPt: 1512, heightPt: 982) {
                #expect(rect.w == 16 && rect.h == 16)
                #expect(rect.x >= 40 && rect.y >= 40)
                #expect(rect.x + rect.w <= 1512 - 40)
                #expect(rect.y + rect.h <= 982 - 40)
            }
        }
    }

    func attempt(_ index: Int, hit: Bool, ms: Int, l1: Bool) -> TargetAttempt {
        TargetAttempt(index: index, targetRectPt: RectPt(x: 100, y: 100, w: 16, h: 16), hit: hit, timeToClickMs: ms, l1Held: l1)
    }

    @Test func resumoComTaxasPorGrupo() {
        let attempts = [
            attempt(1, hit: true, ms: 1000, l1: true),
            attempt(2, hit: false, ms: 3000, l1: false),
            attempt(3, hit: true, ms: 2000, l1: false),
            attempt(4, hit: true, ms: 2000, l1: true),
        ]
        let summary = TargetRun.summarize(attempts)
        #expect(summary.hits == 3)
        #expect(summary.total == 4)
        #expect(summary.hitRate == 0.75)
        #expect(summary.meanTimeMs == 2000)
        #expect(summary.hitRateWithL1 == 1.0)
        #expect(summary.hitRateWithoutL1 == 0.5)
    }

    @Test func omiteTaxaDeGrupoSemTentativas() throws {
        let summary = TargetRun.summarize([attempt(1, hit: true, ms: 900, l1: false)])
        #expect(summary.hitRateWithL1 == nil)
        let json = String(decoding: try JSONEncoder().encode(summary), as: UTF8.self)
        #expect(!json.contains("hitRateWithL1"))
        #expect(json.contains("hitRateWithoutL1"))
    }

    @Test func resumoParcialEmSequenciaIncompleta() {
        let attempts = (1...10).map { attempt($0, hit: $0 % 2 == 0, ms: 1500, l1: false) }
        let summary = TargetRun.summarize(attempts)
        #expect(summary.total == 10)
        #expect(summary.hits == 5)
    }

    @Test func resumoVazio() {
        let summary = TargetRun.summarize([])
        #expect(summary.total == 0 && summary.hitRate == 0 && summary.meanTimeMs == 0)
    }

    func sampleRun(complete: Bool = true) -> TargetRun {
        TargetRun(
            startedAt: "2026-09-20T21:14:03-03:00",
            environment: .sofa,
            complete: complete,
            abortReason: complete ? nil : .user,
            seed: 184467,
            screen: ScreenDescriptor(name: "LG TV", widthPx: 3840, heightPx: 2160, widthPt: 1920, heightPt: 1080, backingScale: 2.0),
            settings: PointerSettings(),
            scrollUnit: .pixel,
            attempts: [attempt(1, hit: true, ms: 2140, l1: true)],
            ignoredPhysicalClicks: 0
        )
    }

    @Test func chavesDoJSONIguaisAoContrato() throws {
        let data = try JSONEncoder().encode(sampleRun())
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(Set(object.keys) == ["schemaVersion", "startedAt", "environment", "complete", "seed", "screen", "targetSizePt", "settings", "scrollUnit", "attempts", "summary", "ignoredPhysicalClicks"])
        #expect(object["schemaVersion"] as? Int == 1)
        #expect(object["targetSizePt"] as? Int == 16)
        let screen = try #require(object["screen"] as? [String: Any])
        #expect(Set(screen.keys) == ["name", "widthPx", "heightPx", "widthPt", "heightPt", "backingScale"])
        let settings = try #require(object["settings"] as? [String: Any])
        #expect(Set(settings.keys) == ["touchpadSensitivity", "stickMaxSpeed", "stickExponent", "deadzone", "scrollSpeed", "invertScrollY", "precisionFactor", "doubleClickIntervalMs"])
        let attempts = try #require(object["attempts"] as? [[String: Any]])
        #expect(Set(attempts[0].keys) == ["index", "targetRectPt", "hit", "timeToClickMs", "l1Held"])
        #expect(Set(try #require(attempts[0]["targetRectPt"] as? [String: Any]).keys) == ["x", "y", "w", "h"])
    }

    @Test func abortReasonSoEmSequenciaIncompleta() throws {
        let data = try JSONEncoder().encode(sampleRun(complete: false))
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object["abortReason"] as? String == "user")
        #expect(object["complete"] as? Bool == false)
        let decoded = try JSONDecoder().decode(TargetRun.self, from: data)
        #expect(decoded == sampleRun(complete: false))
    }

    @Test func nomeDeArquivoComSufixoEmColisao() {
        var components = DateComponents()
        components.year = 2026; components.month = 9; components.day = 20
        components.hour = 21; components.minute = 14; components.second = 3
        let date = Calendar.current.date(from: components)!
        #expect(TargetRun.fileName(startedAt: date, environment: .mesa) { _ in false } == "20260920-211403-mesa.json")
        let taken: Set<String> = ["20260920-211403-mesa.json", "20260920-211403-mesa-2.json"]
        #expect(TargetRun.fileName(startedAt: date, environment: .mesa) { taken.contains($0) } == "20260920-211403-mesa-3.json")
    }
}
