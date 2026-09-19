import Foundation

/// Modelo de controle aceito pelo app (`007-controle-ipega` D-01, RN-01).
///
/// A interface de controles do sistema não expõe fabricante nem produto; o Ipega é reconhecido pela categoria
/// "Switch Pro Controller" somada à presença, no IORegistry, de um dispositivo com o par (0x057E, 0x2009), a mesma
/// correlação por exclusão de `TransportResolver`. Sondas de 2026-09-19, por cabo.
public enum ControllerModel: String, CaseIterable, Codable, Sendable {
    case dualSense, ipega

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
        case .dualSense: 0x054C
        case .ipega: 0x057E
        }
    }

    /// DualSense e DualSense Edge; o Ipega se apresenta como Switch Pro Controller.
    public var productIDs: Set<Int> {
        switch self {
        case .dualSense: [0x0CE6, 0x0DF2]
        case .ipega: [0x2009]
        }
    }

    public func matches(_ device: HIDIdentity) -> Bool {
        device.vendorID == vendorID && productIDs.contains(device.productID)
    }

    /// Botões físicos do modelo, na ordem de `ButtonID`: o DualSense não tem Share; o Ipega não tem touchpad (D-10).
    public var buttons: [ButtonID] {
        switch self {
        case .dualSense: ButtonID.allCases.filter { $0 != .share }
        case .ipega: ButtonID.allCases.filter { $0 != .touchpadClick }
        }
    }

    /// `dualSense` pelo perfil `GCDualSenseGamepad`; `ipega` pela categoria com o par do Ipega presente;
    /// `nil` nos demais casos, inclusive outro Switch Pro sem o par.
    public static func classify(productCategory: String, isDualSenseProfile: Bool, hidDevices: [HIDIdentity]) -> ControllerModel? {
        if isDualSenseProfile { return .dualSense }
        if productCategory == switchProCategory, hidDevices.contains(where: ipega.matches) { return .ipega }
        return nil
    }
}
