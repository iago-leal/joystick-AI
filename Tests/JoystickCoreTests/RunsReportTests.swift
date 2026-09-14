import Testing
@testable import JoystickCore

@Suite struct RunsReportTests {
    func run(env: TargetEnvironment, complete: Bool = true, startedAt: String, settings: PointerSettings = PointerSettings(), slowAttempt: Bool = false) -> TargetRun {
        var attempts = (1...20).map {
            TargetAttempt(index: $0, targetRectPt: RectPt(x: 50, y: 50, w: 16, h: 16), hit: $0 <= 18, timeToClickMs: 2000, l1Held: $0 % 2 == 0)
        }
        if slowAttempt { attempts[0].timeToClickMs = 61_000 }
        return TargetRun(
            startedAt: startedAt, environment: env, complete: complete, abortReason: complete ? nil : .user, seed: 1,
            screen: ScreenDescriptor(name: "TV", widthPx: 3840, heightPx: 2160, widthPt: 1920, heightPt: 1080, backingScale: 2.0),
            settings: settings, scrollUnit: .pixel, attempts: attempts, ignoredPhysicalClicks: 0
        )
    }

    @Test func excluiSequenciasIncompletas() {
        let table = RunsReport.markdown(runs: [
            run(env: .sofa, startedAt: "2026-09-20T21:00:00-03:00"),
            run(env: .sofa, complete: false, startedAt: "2026-09-20T22:00:00-03:00"),
        ], environment: nil)
        #expect(table.contains("2026-09-20T21:00:00-03:00"))
        #expect(!table.contains("2026-09-20T22:00:00-03:00"))
    }

    @Test func filtroPorAmbiente() {
        let runs = [run(env: .sofa, startedAt: "S1"), run(env: .mesa, startedAt: "M1")]
        let table = RunsReport.markdown(runs: runs, environment: .mesa)
        #expect(table.contains("M1"))
        #expect(!table.contains("S1"))
    }

    @Test func parametrosDiferentesDoPadrao() {
        var settings = PointerSettings()
        settings.stickMaxSpeed = 1800
        settings.scrollSpeed = 100
        let table = RunsReport.markdown(runs: [run(env: .sofa, startedAt: "S1", settings: settings)], environment: nil)
        #expect(table.contains("stickMaxSpeed=1800"))
        #expect(table.contains("scrollSpeed=100"))
        #expect(!table.contains("deadzone="))
    }

    @Test func tentativaAcimaDeSessentaSegundosSinalizada() {
        let table = RunsReport.markdown(runs: [run(env: .sofa, startedAt: "S1", slowAttempt: true)], environment: nil)
        #expect(table.contains("1 (>60 s)"))
    }

    @Test func colunasDoContrato() {
        let table = RunsReport.markdown(runs: [run(env: .sofa, startedAt: "S1")], environment: nil)
        let lines = table.split(separator: "\n")
        #expect(lines[0] == "| Data | Ambiente | Resolução (px) | Escala | Parâmetros diferentes do padrão | Taxa de acerto | Com L1 | Sem L1 | Tempo médio (ms) | Discrepantes |")
        #expect(lines.count == 3)
        #expect(lines[2].contains("| sofa | 3840 × 2160 | 2.0 | padrão | 90% | 90% | 90% | 2000 |"))
    }

    @Test func semSequenciasCompletas() {
        #expect(RunsReport.markdown(runs: [], environment: nil).contains("nenhuma sequência completa"))
    }
}
