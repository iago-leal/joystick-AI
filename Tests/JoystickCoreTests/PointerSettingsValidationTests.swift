import Testing
@testable import JoystickCore

@Suite struct PointerSettingsValidationTests {
    @Test func padroesDosOitoCampos() {
        let s = PointerSettings()
        #expect(s.touchpadSensitivity == 1.0)
        #expect(s.stickMaxSpeed == 1500)
        #expect(s.stickExponent == 2.0)
        #expect(s.deadzone == 0.12)
        #expect(s.scrollSpeed == 40)
        #expect(s.invertScrollY == false)
        #expect(s.precisionFactor == 0.3)
        #expect(s.doubleClickIntervalMs == 400)
    }

    @Test(arguments: [
        ("touchpadSensitivity", 0.1, 5.0),
        ("stickMaxSpeed", 150.0, 7500.0),
        ("stickExponent", 0.5, 4.0),
        ("deadzone", 0.0, 0.5),
        ("scrollSpeed", 1.0, 1000.0),
        ("precisionFactor", 0.05, 1.0),
        ("doubleClickIntervalMs", 100.0, 2000.0),
    ])
    func faixasDeRF26(field: String, min: Double, max: Double) {
        let range = PointerSettings.range(for: field)
        #expect(range?.min == min)
        #expect(range?.max == max)

        let atMin = PointerSettingsValidation.validate(.object([field: .double(min)]))
        #expect(atMin.issues.isEmpty)
        let atMax = PointerSettingsValidation.validate(.object([field: .double(max)]))
        #expect(atMax.issues.isEmpty)

        let above = PointerSettingsValidation.validate(.object([field: .double(max + 1)]))
        #expect(above.settings == PointerSettings())
        #expect(above.issues.count == 1)
    }

    @Test func nuloEAusenteSemAviso() {
        let result = PointerSettingsValidation.validate(.object(["deadzone": .null]))
        #expect(result.settings == PointerSettings())
        #expect(result.issues.isEmpty)
    }

    @Test func tipoErradoRejeitadoComDetalhes() {
        let result = PointerSettingsValidation.validate(.object(["stickMaxSpeed": "rápido"]))
        #expect(result.settings.stickMaxSpeed == 1500)
        #expect(result.issues == [.valueRejected(field: "stickMaxSpeed", rejected: "rápido", min: 150, max: 7500, defaultValue: .double(1500))])
    }

    @Test func foraDaFaixaRejeitadoComDetalhes() {
        let result = PointerSettingsValidation.validate(.object(["touchpadSensitivity": 9.0, "stickMaxSpeed": 1800]))
        #expect(result.settings.touchpadSensitivity == 1.0)
        #expect(result.settings.stickMaxSpeed == 1800)
        #expect(result.issues == [.valueRejected(field: "touchpadSensitivity", rejected: 9.0, min: 0.1, max: 5.0, defaultValue: .double(1.0))])
    }

    @Test func inteiroAceitoEmCampoDecimal() {
        let result = PointerSettingsValidation.validate(.object(["touchpadSensitivity": 2]))
        #expect(result.settings.touchpadSensitivity == 2.0)
        #expect(result.issues.isEmpty)
    }

    @Test func intervaloDeDuploCliqueSoInteiro() {
        let fractional = PointerSettingsValidation.validate(.object(["doubleClickIntervalMs": 350.5]))
        #expect(fractional.settings.doubleClickIntervalMs == 400)
        #expect(fractional.issues.count == 1)

        let integer = PointerSettingsValidation.validate(.object(["doubleClickIntervalMs": 350]))
        #expect(integer.settings.doubleClickIntervalMs == 350)
    }

    @Test func invertScrollYSoBooleano() {
        let wrong = PointerSettingsValidation.validate(.object(["invertScrollY": 1]))
        #expect(wrong.settings.invertScrollY == false)
        #expect(wrong.issues == [.valueRejected(field: "invertScrollY", rejected: 1, min: nil, max: nil, defaultValue: false)])

        let right = PointerSettingsValidation.validate(.object(["invertScrollY": true]))
        #expect(right.settings.invertScrollY == true)
    }
}
