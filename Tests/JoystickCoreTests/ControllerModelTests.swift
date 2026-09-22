import Testing
@testable import JoystickCore

/// Classificação do controle conectado (`007-controle-ipega` D-01, RN-01; `012-controle-dualshock-4` D-01).
@Suite struct ControllerModelTests {
    static let ipegaPair = ControllerModel.HIDIdentity(vendorID: 0x057E, productID: 0x2009)
    static let dualSensePair = ControllerModel.HIDIdentity(vendorID: 0x054C, productID: 0x0CE6)
    static let dualShock4Pair = ControllerModel.HIDIdentity(vendorID: 0x054C, productID: 0x05C4)
    static let dualShock4SecondGenerationPair = ControllerModel.HIDIdentity(vendorID: 0x054C, productID: 0x09CC)
    static let sonyWirelessAdapterPair = ControllerModel.HIDIdentity(vendorID: 0x054C, productID: 0x0BA0)

    static func classify(_ category: String, _ profile: ControllerModel.SystemProfile, _ devices: [ControllerModel.HIDIdentity]) -> ControllerModel? {
        ControllerModel.classify(productCategory: category, profile: profile, hidDevices: devices)
    }

    @Test func dualSensePeloPerfil() {
        #expect(Self.classify("DualSense", .dualSense, []) == .dualSense)
        #expect(Self.classify("DualSense", .dualSense, [Self.dualSensePair]) == .dualSense)
    }

    @Test func ipegaPelaCategoriaComOPar() {
        let devices = [Self.dualSensePair, Self.ipegaPair]
        #expect(Self.classify("Switch Pro Controller", .extended, devices) == .ipega)
    }

    @Test func switchProSemOParEhRecusado() {
        let other = ControllerModel.HIDIdentity(vendorID: 0x057E, productID: 0x2017)
        #expect(Self.classify("Switch Pro Controller", .extended, [other]) == nil)
        #expect(Self.classify("Switch Pro Controller", .extended, []) == nil)
    }

    @Test func parSemACategoriaEhRecusado() {
        #expect(Self.classify("Xbox One", .extended, [Self.ipegaPair]) == nil)
        #expect(Self.classify("", .extended, [Self.ipegaPair]) == nil)
    }

    @Test func outraCategoriaEhRecusada() {
        #expect(Self.classify("Xbox One", .extended, []) == nil)
    }

    @Test func paresDeCadaModelo() {
        #expect(ControllerModel.dualSense.vendorID == 0x054C)
        #expect(ControllerModel.dualSense.productIDs == [0x0CE6, 0x0DF2])
        #expect(ControllerModel.ipega.vendorID == 0x057E)
        #expect(ControllerModel.ipega.productIDs == [0x2009])
        #expect(ControllerModel.dualShock4.vendorID == 0x054C)
        #expect(ControllerModel.dualShock4.productIDs == [0x05C4, 0x09CC])
        #expect(ControllerModel.dualSense.matches(.init(vendorID: 0x054C, productID: 0x0DF2)))
        #expect(!ControllerModel.dualSense.matches(Self.ipegaPair))
        #expect(!ControllerModel.ipega.matches(.init(vendorID: 0x054C, productID: 0x2009)))
        #expect(ControllerModel.dualShock4.matches(Self.dualShock4Pair))
        #expect(ControllerModel.dualShock4.matches(Self.dualShock4SecondGenerationPair))
        #expect(!ControllerModel.dualShock4.matches(Self.dualSensePair))
        #expect(!ControllerModel.dualSense.matches(Self.dualShock4Pair))
        // Nenhum par pertence a dois modelos: o leitor HID escolhe o intérprete pelo primeiro que casar.
        for model in ControllerModel.allCases {
            for product in model.productIDs {
                let identity = ControllerModel.HIDIdentity(vendorID: model.vendorID, productID: product)
                #expect(ControllerModel.allCases.filter { $0.matches(identity) } == [model], "\(model) \(product)")
            }
        }
    }

    /// D-10: cada modelo tem 18 botões físicos; o DualSense e o DualShock 4 não têm Share e o Ipega não tem touchpad.
    @Test func botoesDeCadaModelo() {
        #expect(ControllerModel.dualSense.buttons.count == 18)
        #expect(ControllerModel.ipega.buttons.count == 18)
        #expect(ControllerModel.dualShock4.buttons.count == 18)
        #expect(!ControllerModel.dualSense.buttons.contains(.share))
        #expect(!ControllerModel.dualShock4.buttons.contains(.share))
        #expect(ControllerModel.dualShock4.buttons.contains(.touchpadClick))
        #expect(ControllerModel.dualShock4.buttons.contains(.create))
        #expect(ControllerModel.dualShock4.buttons == ControllerModel.dualSense.buttons)
        #expect(!ControllerModel.ipega.buttons.contains(.touchpadClick))
        #expect(ControllerModel.ipega.buttons.last == .share)
        #expect(ControllerModel.dualSense.rawValue == "dualSense")
        #expect(ControllerModel.ipega.rawValue == "ipega")
        #expect(ControllerModel.dualShock4.rawValue == "dualShock4")
        #expect(ControllerModel(rawValue: "dualShock4") == .dualShock4)
    }

    // MARK: `012-controle-dualshock-4` D-01

    @Test func dualShock4PeloPerfilComOPar() {
        #expect(Self.classify("DualShock 4", .dualShock, [Self.dualShock4Pair]) == .dualShock4)
        #expect(Self.classify("DualShock 4", .dualShock, [Self.ipegaPair, Self.dualShock4SecondGenerationPair]) == .dualShock4)
        // O canal Bluetooth Low Energy do GameSir (0x3537/0x1108) ao lado não atrapalha.
        let gameSirChannel = ControllerModel.HIDIdentity(vendorID: 0x3537, productID: 0x1108)
        #expect(Self.classify("DualShock 4", .dualShock, [gameSirChannel, Self.dualShock4Pair]) == .dualShock4)
    }

    @Test func perfilDualShockSemOParEhRecusado() {
        #expect(Self.classify("DualShock 4", .dualShock, []) == nil)
        // Par Sony de outro modelo não serve.
        #expect(Self.classify("DualShock 4", .dualShock, [Self.dualSensePair]) == nil)
        #expect(Self.classify("DualShock 4", .dualShock, [Self.ipegaPair]) == nil)
    }

    /// Roadmap §4: o adaptador USB sem fio da Sony fica fora até ser sondado.
    @Test func adaptadorSemFioDaSonyFicaFora() {
        #expect(Self.classify("DualShock 4", .dualShock, [Self.sonyWirelessAdapterPair]) == nil)
        #expect(!ControllerModel.dualShock4.matches(Self.sonyWirelessAdapterPair))
        #expect(!ControllerModel.dualSense.matches(Self.sonyWirelessAdapterPair))
    }

    @Test func parSonySemOPerfilDualShockNaoEhDualShock4() {
        #expect(Self.classify("DualShock 4", .extended, [Self.dualShock4Pair]) == nil)
        #expect(Self.classify("Xbox One", .extended, [Self.dualShock4Pair]) == nil)
        // O DualSense continua pelo perfil só, mesmo com um DualShock 4 ao lado no IORegistry.
        #expect(Self.classify("DualSense", .dualSense, [Self.dualShock4Pair]) == .dualSense)
    }
}
