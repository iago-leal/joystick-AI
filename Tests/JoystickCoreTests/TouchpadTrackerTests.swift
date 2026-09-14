import Testing
@testable import JoystickCore

/// Evidência automatizada de RF-08 (esclarecimento 6): o log não registra posições do toque.
@Suite struct TouchpadTrackerTests {
    @Test func posicaoNormalizadaDeMenosUmAUmNosDoisEixos() {
        var tracker = TouchpadTracker()
        #expect(tracker.update(finger: 0, phase: .began, x: -1.0, y: -1.0, sensitivity: 1.0) == nil)
        let d = tracker.update(finger: 0, phase: .moved, x: 1.0, y: 1.0, sensitivity: 1.0)
        #expect(d == PointDelta(dx: 800, dy: -800))
    }

    @Test func deslizeDaEsquerdaParaADireitaGeraDeltaXPositivo() {
        var tracker = TouchpadTracker()
        _ = tracker.update(finger: 0, phase: .began, x: -0.5, y: 0.0, sensitivity: 1.0)
        let first = tracker.update(finger: 0, phase: .moved, x: -0.2, y: 0.0, sensitivity: 1.0)
        let second = tracker.update(finger: 0, phase: .moved, x: 0.3, y: 0.0, sensitivity: 1.0)
        #expect((first?.dx ?? 0) > 0)
        #expect((second?.dx ?? 0) > 0)
    }

    @Test func pousarODedoNaoGeraDelta() {
        var tracker = TouchpadTracker()
        #expect(tracker.update(finger: 0, phase: .began, x: 0.9, y: -0.7, sensitivity: 1.0) == nil)
    }

    @Test func primeiraAmostraMovidaSemInicioTambemEhDescartada() {
        var tracker = TouchpadTracker()
        #expect(tracker.update(finger: 0, phase: .moved, x: 0.4, y: 0.4, sensitivity: 1.0) == nil)
        #expect(tracker.update(finger: 0, phase: .moved, x: 0.5, y: 0.4, sensitivity: 1.0) != nil)
    }

    @Test func soOPrimeiroDedoMove() {
        var tracker = TouchpadTracker()
        _ = tracker.update(finger: 0, phase: .began, x: 0.05, y: 0.1, sensitivity: 1.0)
        _ = tracker.update(finger: 1, phase: .began, x: 0.5, y: 0.5, sensitivity: 1.0)
        #expect(tracker.update(finger: 1, phase: .moved, x: 0.9, y: 0.5, sensitivity: 1.0) == nil)
        #expect(tracker.update(finger: 0, phase: .moved, x: 0.1, y: 0.1, sensitivity: 1.0) != nil)
    }

    @Test func deltaEscalaPelaSensibilidade() {
        var tracker = TouchpadTracker()
        _ = tracker.update(finger: 0, phase: .began, x: 0.0, y: 0.0, sensitivity: 2.5)
        let d = tracker.update(finger: 0, phase: .moved, x: 0.1, y: -0.05, sensitivity: 2.5)
        #expect(abs((d?.dx ?? 0) - 100.0) < 1e-9)
        #expect(abs((d?.dy ?? 0) - 50.0) < 1e-9)
    }

    @Test func fimEReinicioDeToqueNaoSaltam() {
        var tracker = TouchpadTracker()
        _ = tracker.update(finger: 0, phase: .began, x: -0.8, y: 0.0, sensitivity: 1.0)
        _ = tracker.update(finger: 0, phase: .moved, x: -0.7, y: 0.0, sensitivity: 1.0)
        #expect(tracker.update(finger: 0, phase: .ended, x: 0.0, y: 0.0, sensitivity: 1.0) == nil)
        #expect(tracker.update(finger: 0, phase: .began, x: 0.9, y: 0.0, sensitivity: 1.0) == nil)
        let d = tracker.update(finger: 0, phase: .moved, x: 0.95, y: 0.0, sensitivity: 1.0)
        #expect(abs((d?.dx ?? 0) - 20.0) < 1e-9)
    }

    @Test func segundoDedoAssumeAoSairOPrimeiroSemSalto() {
        var tracker = TouchpadTracker()
        _ = tracker.update(finger: 0, phase: .began, x: 0.0, y: 0.0, sensitivity: 1.0)
        _ = tracker.update(finger: 1, phase: .began, x: 0.5, y: 0.5, sensitivity: 1.0)
        _ = tracker.update(finger: 0, phase: .ended, x: 0.0, y: 0.0, sensitivity: 1.0)
        #expect(tracker.update(finger: 1, phase: .moved, x: 0.6, y: 0.5, sensitivity: 1.0) == nil)
        #expect(tracker.update(finger: 1, phase: .moved, x: 0.7, y: 0.5, sensitivity: 1.0) != nil)
    }

    @Test func inferenciaPelaTransicaoDeEParaZero() {
        var inference = ZeroTransitionPhaseInference()
        #expect(inference.phase(x: 0.0, y: 0.0) == nil)
        #expect(inference.phase(x: 0.3, y: -0.2) == .began)
        #expect(inference.phase(x: 0.35, y: -0.2) == .moved)
        #expect(inference.phase(x: 0.0, y: 0.0) == .ended)
        #expect(inference.phase(x: 0.0, y: 0.0) == nil)
        #expect(inference.phase(x: -0.1, y: 0.0) == .began)
    }

    @Test func eixosAtualizadosUmDeCadaVezNaoSaltam() {
        var tracker = TouchpadTracker()
        // Pouso: (x, 0) e depois (x, y), sem salto vertical.
        #expect(tracker.update(finger: 0, phase: .began, x: -0.6, y: 0.0, sensitivity: 1.0) == nil)
        #expect(tracker.update(finger: 0, phase: .moved, x: -0.6, y: 0.3, sensitivity: 1.0) == nil)
        let slide = tracker.update(finger: 0, phase: .moved, x: 0.4, y: 0.3, sensitivity: 1.0)
        #expect(slide == PointDelta(dx: 400, dy: 0))
        // Retirada: (0, y) e depois (0, 0), sem salto horizontal de volta.
        #expect(tracker.update(finger: 0, phase: .moved, x: 0.0, y: 0.3, sensitivity: 1.0) == nil)
        #expect(tracker.update(finger: 0, phase: .ended, x: 0.0, y: 0.0, sensitivity: 1.0) == nil)
    }
}
