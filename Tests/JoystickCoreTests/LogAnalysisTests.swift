import Testing
@testable import JoystickCore

@Suite struct LogAnalysisTests {
    func line(_ event: String, _ fields: [String: JSONValue] = [:]) -> String {
        LogLineFormatter.line(LogEvent(event, level: .info, fields: fields), tsNs: 1, wall: "2026-09-14T10:00:00.000-03:00")
    }

    @Test func linhasMalformadasContadasAParte() {
        let text = line("session.start") + "{quebrado\n" + "\n" + line("controller.connected", ["id": "a"]) + "texto solto\n"
        let read = LogAnalysis.read(contents: text)
        #expect(read.records.count == 2)
        #expect(read.malformedLines == 2)
    }

    @Test func coberturaIgnoraEventosSinteticos() {
        var text = ""
        for button in ButtonID.allCases where button != .ps {
            text += line("input.button", ["button": .string(button.rawValue), "phase": "down", "synthetic": false])
            text += line("input.button", ["button": .string(button.rawValue), "phase": "up", "synthetic": false])
        }
        text += line("input.button", ["button": "ps", "phase": "down", "synthetic": false])
        text += line("input.button", ["button": "ps", "phase": "up", "synthetic": true])
        let coverage = LogAnalysis.buttonCoverage(LogAnalysis.read(contents: text).records)
        #expect(coverage.covered == 17)
        #expect(coverage.observed[.ps] == ButtonObservation(down: true, up: false))
        #expect(coverage.observed[.cross] == ButtonObservation(down: true, up: true))
    }

    @Test func ciclosConexoesSemDesconexaoESessoes() {
        var text = line("session.start")
        for n in 0..<3 {
            text += line("controller.connected", ["id": .string("c\(n)")])
            text += line("controller.disconnected", ["id": .string("c\(n)")])
        }
        text += line("controller.connected", ["id": "sobra"])
        text += line("session.start")
        text += line("controller.disconnected", ["id": "desconhecido"])
        let cycles = LogAnalysis.cycles(LogAnalysis.read(contents: text).records)
        #expect(cycles.completeCycles == 3)
        #expect(cycles.unmatchedConnections == 1)
        #expect(cycles.sessions == 2)
    }

    @Test func amostrasDeLatencia() {
        var text = ""
        text += line("input.button", ["button": "r2", "phase": "down", "synthetic": false, "t_arrival": 1_000, "t_delivered": 3_000])
        text += line("input.button", ["button": "r2", "phase": "up", "synthetic": true, "t_arrival": 5_000, "t_delivered": 5_500])
        text += line("input.touch", ["finger": 0, "phase": "began", "t_arrival": 10_000, "t_delivered": 10_400])
        text += line("pointer.posted", ["kind": "move", "source": "touch", "t_arrival": 20_000, "t_posted": 26_000])
        text += line("pointer.posted", ["kind": "move", "source": "stick_onset", "t_arrival": 30_000, "t_posted": 31_000])
        text += line("pointer.posted", ["kind": "down", "source": "button", "t_arrival": 40_000, "t_posted": 41_000])
        let samples = LogAnalysis.latencySamples(LogAnalysis.read(contents: text).records)
        #expect(samples.processing == [2_000, 400])
        #expect(samples.inputToMotion == [6_000, 1_000])
    }
}
