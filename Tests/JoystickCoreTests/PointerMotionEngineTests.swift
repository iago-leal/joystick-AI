import Testing
@testable import JoystickCore

@Suite struct PointerMotionEngineTests {
    let dt = 1.0 / 120.0

    @Test func deltaDeToqueSemTemporizadorEhEmitidoDeImediato() {
        var engine = PointerMotionEngine(settings: PointerSettings())
        let out = engine.touchDelta(PointDelta(dx: 5, dy: -3), pressed: [])
        #expect(out.move == PointDelta(dx: 5, dy: -3))
        #expect(out.timer == .none)
    }

    @Test func primeiraAmostraDoAnalogicoEsquerdoEhEmitidaEPedeTemporizador() {
        var engine = PointerMotionEngine(settings: PointerSettings())
        let out = engine.setLeftStick(x: 1.0, y: 0.0, pressed: [])
        #expect(out.stickOnset)
        #expect((out.move?.dx ?? 0) >= 12)
        #expect(out.timer == .start)
        #expect(engine.timerRunning)
    }

    @Test func deltaDeToqueComTemporizadorAcumulaESomaNoTick() {
        var engine = PointerMotionEngine(settings: PointerSettings())
        _ = engine.setLeftStick(x: 1.0, y: 0.0, pressed: [])
        let held = engine.touchDelta(PointDelta(dx: 10, dy: 0), pressed: [])
        #expect(held.move == nil)
        let tick = engine.tick(dt: dt, pressed: [])
        let stickOnly = 1500.0 * dt
        #expect(abs((tick.move?.dx ?? 0) - (10 + stickOnly).rounded(.towardZero)) <= 1)
    }

    @Test func toqueContrarioDesaceleraOAnalogico() {
        var engine = PointerMotionEngine(settings: PointerSettings())
        _ = engine.setLeftStick(x: 1.0, y: 0.0, pressed: [])
        _ = engine.touchDelta(PointDelta(dx: -8, dy: 0), pressed: [])
        let tick = engine.tick(dt: dt, pressed: [])
        #expect((tick.move?.dx ?? 0) < 1500.0 * dt - 6)
    }

    @Test func analogicoDireitoTambemLigaOTemporizador() {
        var engine = PointerMotionEngine(settings: PointerSettings())
        let out = engine.setRightStick(x: 0.0, y: -1.0)
        #expect(out.scrollOnset)
        #expect(out.timer == .start)
        #expect(out.move == nil)
    }

    @Test func temporizadorUnicoParaSoComOsDoisEmRepouso() {
        var engine = PointerMotionEngine(settings: PointerSettings())
        _ = engine.setLeftStick(x: 0.5, y: 0.0, pressed: [])
        let right = engine.setRightStick(x: 0.0, y: 0.8)
        #expect(right.timer == .none)
        #expect(engine.setLeftStick(x: 0.0, y: 0.0, pressed: []).timer == .none)
        #expect(engine.timerRunning)
        #expect(engine.setRightStick(x: 0.0, y: 0.0).timer == .stop)
        #expect(!engine.timerRunning)
    }

    @Test func ticksSemAnalogicoNaoMovem() {
        var engine = PointerMotionEngine(settings: PointerSettings())
        _ = engine.setRightStick(x: 0.0, y: 1.0)
        let tick = engine.tick(dt: dt, pressed: [])
        #expect(tick.move == nil)
    }

    @Test func toquePendenteSaiAoPararOTemporizador() {
        var engine = PointerMotionEngine(settings: PointerSettings())
        _ = engine.setLeftStick(x: 1.0, y: 0.0, pressed: [])
        _ = engine.touchDelta(PointDelta(dx: 4, dy: 2), pressed: [])
        let stop = engine.setLeftStick(x: 0.0, y: 0.0, pressed: [])
        #expect(stop.timer == .stop)
        #expect(stop.move == PointDelta(dx: 4, dy: 2))
    }

    @Test func precisaoSoComL1SemOutroBotao() {
        #expect(PointerMotionEngine.precisionActive(pressed: [.l1]))
        #expect(!PointerMotionEngine.precisionActive(pressed: [.l1, .r2]))
        #expect(!PointerMotionEngine.precisionActive(pressed: []))
        #expect(!PointerMotionEngine.precisionActive(pressed: [.cross]))
    }

    @Test func precisaoReduzToqueEAnalogico() {
        var engine = PointerMotionEngine(settings: PointerSettings())
        let touch = engine.touchDelta(PointDelta(dx: 100, dy: 0), pressed: [.l1])
        #expect(touch.move == PointDelta(dx: 30, dy: 0))

        var normal = PointerMotionEngine(settings: PointerSettings())
        var precise = PointerMotionEngine(settings: PointerSettings())
        _ = normal.setLeftStick(x: 1.0, y: 0.0, pressed: [])
        _ = precise.setLeftStick(x: 1.0, y: 0.0, pressed: [.l1])
        var sumNormal = 0.0, sumPrecise = 0.0
        for _ in 0..<120 {
            sumNormal += normal.tick(dt: dt, pressed: []).move?.dx ?? 0
            sumPrecise += precise.tick(dt: dt, pressed: [.l1]).move?.dx ?? 0
        }
        #expect(abs(sumPrecise / sumNormal - 0.3) < 0.05)
    }
}
