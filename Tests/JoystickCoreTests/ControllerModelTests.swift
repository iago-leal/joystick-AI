import Testing
@testable import JoystickCore

/// Classificação do controle conectado (`007-controle-ipega` D-01, RN-01).
@Suite struct ControllerModelTests {
    static let ipegaPair = ControllerModel.HIDIdentity(vendorID: 0x057E, productID: 0x2009)
    static let dualSensePair = ControllerModel.HIDIdentity(vendorID: 0x054C, productID: 0x0CE6)

    @Test func dualSensePeloPerfil() {
        #expect(ControllerModel.classify(productCategory: "DualSense", isDualSenseProfile: true, hidDevices: []) == .dualSense)
        #expect(ControllerModel.classify(productCategory: "DualSense", isDualSenseProfile: true, hidDevices: [Self.dualSensePair]) == .dualSense)
    }

    @Test func ipegaPelaCategoriaComOPar() {
        let devices = [Self.dualSensePair, Self.ipegaPair]
        #expect(ControllerModel.classify(productCategory: "Switch Pro Controller", isDualSenseProfile: false, hidDevices: devices) == .ipega)
    }

    @Test func switchProSemOParEhRecusado() {
        let other = ControllerModel.HIDIdentity(vendorID: 0x057E, productID: 0x2017)
        #expect(ControllerModel.classify(productCategory: "Switch Pro Controller", isDualSenseProfile: false, hidDevices: [other]) == nil)
        #expect(ControllerModel.classify(productCategory: "Switch Pro Controller", isDualSenseProfile: false, hidDevices: []) == nil)
    }

    @Test func parSemACategoriaEhRecusado() {
        #expect(ControllerModel.classify(productCategory: "Xbox One", isDualSenseProfile: false, hidDevices: [Self.ipegaPair]) == nil)
        #expect(ControllerModel.classify(productCategory: "", isDualSenseProfile: false, hidDevices: [Self.ipegaPair]) == nil)
    }

    @Test func outraCategoriaEhRecusada() {
        #expect(ControllerModel.classify(productCategory: "Xbox One", isDualSenseProfile: false, hidDevices: []) == nil)
    }

    @Test func paresDeCadaModelo() {
        #expect(ControllerModel.dualSense.vendorID == 0x054C)
        #expect(ControllerModel.dualSense.productIDs == [0x0CE6, 0x0DF2])
        #expect(ControllerModel.ipega.vendorID == 0x057E)
        #expect(ControllerModel.ipega.productIDs == [0x2009])
        #expect(ControllerModel.dualSense.matches(.init(vendorID: 0x054C, productID: 0x0DF2)))
        #expect(!ControllerModel.dualSense.matches(Self.ipegaPair))
        #expect(!ControllerModel.ipega.matches(.init(vendorID: 0x054C, productID: 0x2009)))
    }

    /// D-10: cada modelo tem 18 botões físicos; o DualSense não tem Share e o Ipega não tem touchpad.
    @Test func botoesDeCadaModelo() {
        #expect(ControllerModel.dualSense.buttons.count == 18)
        #expect(ControllerModel.ipega.buttons.count == 18)
        #expect(!ControllerModel.dualSense.buttons.contains(.share))
        #expect(!ControllerModel.ipega.buttons.contains(.touchpadClick))
        #expect(ControllerModel.ipega.buttons.last == .share)
        #expect(ControllerModel.dualSense.rawValue == "dualSense")
        #expect(ControllerModel.ipega.rawValue == "ipega")
    }
}
