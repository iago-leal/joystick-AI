import Testing
@testable import JoystickCore

/// Evidência automatizada de RF-06 e RF-07 (esclarecimento 6): o log não registra valores de eixo.
@Suite struct NormalizationTests {
    @Test func desvioFisicoDentroDaZonaMortaViraZero() {
        #expect(Normalization.applyDeadzone(0.08, deadzone: 0.12) == 0.0)
        #expect(Normalization.applyDeadzone(-0.08, deadzone: 0.12) == 0.0)
    }

    @Test func repousoResultaEmZero() {
        let stick = Normalization.stick(x: 0.0, y: 0.0, deadzone: 0.12)
        #expect(stick.x == 0.0)
        #expect(stick.y == 0.0)
    }

    @Test func limiteDaZonaMortaEhMantido() {
        #expect(Normalization.applyDeadzone(0.12, deadzone: 0.12) == 0.12)
        #expect(Normalization.applyDeadzone(0.1199, deadzone: 0.12) == 0.0)
        #expect(Normalization.applyDeadzone(-0.12, deadzone: 0.12) == -0.12)
    }

    @Test func cursoMaximoResultaEmUm() {
        #expect(Normalization.applyDeadzone(1.0, deadzone: 0.12) == 1.0)
        #expect(Normalization.applyDeadzone(-1.0, deadzone: 0.12) == -1.0)
        #expect(Normalization.applyDeadzone(1.3, deadzone: 0.12) == 1.0)
    }

    @Test func zonaMortaPorEixo() {
        let stick = Normalization.stick(x: 0.08, y: 0.9, deadzone: 0.12)
        #expect(stick.x == 0.0)
        #expect(stick.y == 0.9)
    }

    @Test func zonaMortaConfiguravel() {
        #expect(Normalization.applyDeadzone(0.2, deadzone: 0.25) == 0.0)
        #expect(Normalization.applyDeadzone(0.05, deadzone: 0.0) == 0.05)
    }

    @Test func gatilhoPressionadoAPartirDeMeioCurso() {
        #expect(Normalization.isTriggerPressed(0.5))
        #expect(Normalization.isTriggerPressed(1.0))
        #expect(!Normalization.isTriggerPressed(0.4999))
    }

    @Test func gatilhoSemHisterese() {
        var trigger = TriggerTracker()
        #expect(trigger.update(0.3) == nil)
        #expect(trigger.update(0.5) == true)
        #expect(trigger.update(0.7) == nil)
        #expect(trigger.update(0.49) == false)
        #expect(trigger.update(0.51) == true)
        #expect(trigger.update(0.49) == false)
    }

    @Test func posicaoDoToqueLimitadaAoIntervalo() {
        let p = Normalization.touchPosition(x: 1.2, y: -1.5)
        #expect(p.x == 1.0)
        #expect(p.y == -1.0)
    }
}
