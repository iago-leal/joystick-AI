import Foundation

/// Modelo de controle aceito pelo app (`007-controle-ipega` D-01, RN-01; `012-controle-dualshock-4` D-01).
///
/// A interface de controles do sistema não expõe fabricante nem produto. O DualSense é reconhecido só pelo perfil
/// `GCDualSenseGamepad`. O Ipega, pela categoria "Switch Pro Controller" somada à presença, no IORegistry, de um
/// dispositivo com o par (0x057E, 0x2009), a mesma correlação por exclusão de `TransportResolver` (sondas de
/// 2026-09-19, por cabo). O DualShock 4, pelo perfil `GCDualShockGamepad` somado a um par Sony do modelo no
/// IORegistry (sonda de 2026-09-22, por Bluetooth, com o GameSir G8+ no modo PlayStation, que emula o par 0x05C4).
public enum ControllerModel: String, CaseIterable, Codable, Sendable {
    case dualSense, ipega, dualShock4

    /// Perfil que o sistema atribuiu ao controle, derivado no app da classe de `extendedGamepad`
    /// (`012-controle-dualshock-4` D-01): `dualSense` para `GCDualSenseGamepad`, `dualShock` para
    /// `GCDualShockGamepad` e `extended` para qualquer outro `GCExtendedGamepad`.
    public enum SystemProfile: Sendable {
        case dualSense, dualShock, extended
    }

    /// Par (fabricante, produto) de um dispositivo HID presente no IORegistry.
    public struct HIDIdentity: Hashable, Sendable {
        public var vendorID: Int
        public var productID: Int

        public init(vendorID: Int, productID: Int) {
            self.vendorID = vendorID
            self.productID = productID
        }
    }

    /// `GCController.productCategory` do Ipega no modo Switch.
    public static let switchProCategory = "Switch Pro Controller"

    public var vendorID: Int {
        switch self {
        case .dualSense, .dualShock4: 0x054C
        case .ipega: 0x057E
        }
    }

    /// DualSense e DualSense Edge; o Ipega se apresenta como Switch Pro Controller; DualShock 4 de primeira geração
    /// (CUH-ZCT1, 0x05C4, a identidade que os clones emulam) e de segunda (CUH-ZCT2, 0x09CC). O adaptador USB sem fio
    /// da Sony (0x0BA0) fica fora: ninguém pôde sondar o relatório que chega por ele, e o rito do projeto exige a
    /// sonda antes do código; incluí-lo custa esta constante e um caso de teste (`012-controle-dualshock-4` roadmap §4).
    public var productIDs: Set<Int> {
        switch self {
        case .dualSense: [0x0CE6, 0x0DF2]
        case .ipega: [0x2009]
        case .dualShock4: [0x05C4, 0x09CC]
        }
    }

    public func matches(_ device: HIDIdentity) -> Bool {
        device.vendorID == vendorID && productIDs.contains(device.productID)
    }

    /// Botões físicos do modelo, na ordem de `ButtonID`: o DualSense e o DualShock 4 não têm Share (o Share do
    /// DualShock 4 ocupa a posição do Create e chega como `create`, `012-controle-dualshock-4` D-02); o Ipega não tem
    /// touchpad (D-10).
    public var buttons: [ButtonID] {
        switch self {
        case .dualSense, .dualShock4: ButtonID.allCases.filter { $0 != .share }
        case .ipega: ButtonID.allCases.filter { $0 != .touchpadClick }
        }
    }

    /// `dualSense` pelo perfil; `dualShock4` pelo perfil DualShock com um par do modelo presente no IORegistry;
    /// `ipega` pela categoria com o par do Ipega presente; `nil` nos demais casos, inclusive perfil DualShock sem o
    /// par (um DualShock 4 pelo adaptador da Sony, por exemplo) e outro Switch Pro sem o par.
    public static func classify(productCategory: String, profile: SystemProfile, hidDevices: [HIDIdentity]) -> ControllerModel? {
        switch profile {
        case .dualSense:
            return .dualSense
        case .dualShock:
            return hidDevices.contains(where: dualShock4.matches) ? .dualShock4 : nil
        case .extended:
            if productCategory == switchProCategory, hidDevices.contains(where: ipega.matches) { return .ipega }
            return nil
        }
    }
}
