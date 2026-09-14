import Testing
@testable import JoystickCore

@Suite struct ScrollMapperTests {
    func run(_ mapper: inout ScrollMapper, x: Double, y: Double, seconds: Double) -> (vertical: Int, horizontal: Int) {
        var v = 0, h = 0
        for _ in 0..<Int(seconds * 120) {
            let step = mapper.step(x: x, y: y, dt: 1.0 / 120.0)
            v += Int(step.vertical)
            h += Int(step.horizontal)
        }
        return (v, h)
    }

    @Test func linhasPorSegundoNaInclinacaoTotal() {
        var settings = PointerSettings()
        settings.scrollSpeed = 100
        var mapper = ScrollMapper(unit: .line, settings: settings)
        let total = run(&mapper, x: 0, y: -1.0, seconds: 1.0)
        #expect(abs(abs(total.vertical) - 100) <= 1)
    }

    @Test func proporcionalAInclinacao() {
        var settings = PointerSettings()
        settings.scrollSpeed = 100
        var mapper = ScrollMapper(unit: .line, settings: settings)
        let half = run(&mapper, x: 0, y: -0.5, seconds: 1.0)
        #expect(abs(abs(half.vertical) - 50) <= 1)
    }

    @Test func vintePixelsPorLinha() {
        var settings = PointerSettings()
        settings.scrollSpeed = 40
        var mapper = ScrollMapper(unit: .pixel, settings: settings)
        let total = run(&mapper, x: 0, y: -1.0, seconds: 1.0)
        #expect(abs(abs(total.vertical) - 800) <= 1)
    }

    @Test func fracaoDeLinhaAcumula() {
        var settings = PointerSettings()
        settings.scrollSpeed = 1
        var mapper = ScrollMapper(unit: .line, settings: settings)
        var emitted = 0
        for _ in 0..<119 { emitted += Int(mapper.step(x: 0, y: -1.0, dt: 1.0 / 120.0).vertical) }
        #expect(emitted == 0)
        emitted += Int(mapper.step(x: 0, y: -1.0, dt: 1.0 / 120.0 + 1e-9).vertical)
        #expect(abs(emitted) == 1)
    }

    @Test func analogicoParaBaixoRolaParaBaixo() {
        var mapper = ScrollMapper(unit: .pixel, settings: PointerSettings())
        let down = run(&mapper, x: 0, y: -1.0, seconds: 0.5)
        // Convenção do CGEvent: wheel1 negativo rola em direção ao fim do documento.
        #expect(down.vertical < 0)
    }

    @Test func invertScrollYTrocaOSinal() {
        var settings = PointerSettings()
        settings.invertScrollY = true
        var mapper = ScrollMapper(unit: .pixel, settings: settings)
        let down = run(&mapper, x: 0, y: -1.0, seconds: 0.5)
        #expect(down.vertical > 0)
    }

    @Test func eixoHorizontal() {
        var mapper = ScrollMapper(unit: .pixel, settings: PointerSettings())
        let right = run(&mapper, x: 1.0, y: 0, seconds: 0.5)
        // Convenção do CGEvent: wheel2 negativo rola para a direita.
        #expect(right.horizontal < 0)
        #expect(right.vertical == 0)
    }
}
