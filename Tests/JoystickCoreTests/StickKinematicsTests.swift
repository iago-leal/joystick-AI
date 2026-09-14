import Foundation
import Testing
@testable import JoystickCore

@Suite struct StickKinematicsTests {
    let settings = PointerSettings()

    @Test func velocidadeRadialComExpoente() {
        let v = StickKinematics.velocity(x: 0.5, y: 0.0, maxSpeed: 1500, exponent: 2.0)
        #expect(abs(v.vx - 375.0) < 1e-9)
        #expect(v.vy == 0.0)
    }

    @Test func inclinacaoDeTrintaPorCentoAbaixoDeDezPorCento() {
        let v = StickKinematics.velocity(x: 0.3, y: 0.0, maxSpeed: 1500, exponent: 2.0)
        #expect(v.vx < 150.0)
    }

    @Test func travessiaDaTelaEmAteUmSegundoEMeio() {
        var accumulator = SubpixelAccumulator()
        var traveled = 0.0
        let dt = 1.0 / 120.0
        for _ in 0..<Int(1.5 * 120) {
            let d = StickKinematics.displacement(x: 1.0, y: 0.0, settings: settings, dt: dt, precision: false)
            traveled += accumulator.take(dx: d.dx, dy: d.dy).dx
        }
        #expect(traveled >= 1920.0)
    }

    @Test func magnitudeLimitadaAUmNaDiagonal() {
        let v = StickKinematics.velocity(x: 1.0, y: 1.0, maxSpeed: 1500, exponent: 2.0)
        #expect(abs(hypot(v.vx, v.vy) - 1500.0) < 1e-6)
    }

    @Test func eixoYInvertidoParaCoordenadasDeTela() {
        let up = StickKinematics.velocity(x: 0.0, y: 1.0, maxSpeed: 1500, exponent: 2.0)
        #expect(up.vy < 0)
        let down = StickKinematics.velocity(x: 0.0, y: -1.0, maxSpeed: 1500, exponent: 2.0)
        #expect(down.vy > 0)
    }

    @Test func repousoNaoMove() {
        let v = StickKinematics.velocity(x: 0.0, y: 0.0, maxSpeed: 1500, exponent: 2.0)
        #expect(v.vx == 0.0 && v.vy == 0.0)
    }

    @Test func precisaoReduzAoFator() {
        let normal = StickKinematics.displacement(x: 1.0, y: 0.0, settings: settings, dt: 1.0, precision: false)
        let precise = StickKinematics.displacement(x: 1.0, y: 0.0, settings: settings, dt: 1.0, precision: true)
        #expect(abs(precise.dx - normal.dx * 0.3) < 1e-9)
    }

    @Test func restoSubpixelAcumula() {
        var accumulator = SubpixelAccumulator()
        #expect(accumulator.take(dx: 0.4, dy: -0.4) == PointDelta(dx: 0, dy: 0))
        #expect(accumulator.take(dx: 0.4, dy: -0.4) == PointDelta(dx: 0, dy: 0))
        #expect(accumulator.take(dx: 0.4, dy: -0.4) == PointDelta(dx: 1, dy: -1))
        let rest = accumulator.remainder
        #expect(abs(rest.dx - 0.2) < 1e-9)
        #expect(abs(rest.dy + 0.2) < 1e-9)
    }
}
