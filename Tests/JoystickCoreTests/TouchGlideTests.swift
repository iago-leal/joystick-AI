import Foundation
import Testing
@testable import JoystickCore

@Suite struct TouchGlideTests {
    let dt = 1.0 / 120.0

    @Test func planadorVazioNaoDevolveNada() {
        var glide = TouchGlide()
        #expect(glide.isEmpty)
        #expect(glide.drain(dt: dt) == .zero)
    }

    @Test func umTickGastaSoUmaFracaoDoQueFaltaAndar() {
        var glide = TouchGlide()
        glide.add(PointDelta(dx: 100, dy: 0))
        let step = glide.drain(dt: dt)
        #expect(step.dx > 0)
        #expect(step.dx < 100)
        #expect(!glide.isEmpty)
    }

    @Test func aSomaDosTicksEntregaODeslocamentoInteiro() {
        var glide = TouchGlide()
        glide.add(PointDelta(dx: 100, dy: -40))
        var total = PointDelta.zero
        var ticks = 0
        while !glide.isEmpty {
            total = total + glide.drain(dt: dt)
            ticks += 1
            if ticks > 240 { break }
        }
        #expect(abs(total.dx - 100) < 0.001)
        #expect(abs(total.dy + 40) < 0.001)
        // Constante de tempo curta: o caminho se esgota numa fração de segundo, não numa cauda longa.
        #expect(ticks < 120)
    }

    @Test func rajadaNovaSomaAoQueFaltavaEmVezDeRecomecar() {
        var glide = TouchGlide()
        glide.add(PointDelta(dx: 10, dy: 0))
        var total = glide.drain(dt: dt)
        glide.add(PointDelta(dx: 10, dy: 0))
        while !glide.isEmpty { total = total + glide.drain(dt: dt) }
        #expect(abs(total.dx - 20) < 0.001)
    }

    @Test func oRestoMinusculoSaiInteiroEEncerraASerie() {
        var glide = TouchGlide()
        glide.add(PointDelta(dx: 0.3, dy: 0.2))
        let step = glide.drain(dt: dt)
        #expect(step == PointDelta(dx: 0.3, dy: 0.2))
        #expect(glide.isEmpty)
    }

    @Test func oResetDescartaOQueFaltava() {
        var glide = TouchGlide()
        glide.add(PointDelta(dx: 50, dy: 50))
        glide.reset()
        #expect(glide.isEmpty)
    }
}
