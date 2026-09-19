import Foundation
import IOKit
import IOKit.hid
import JoystickCore

/// Tipo de conexão e dispositivos presentes pelo IORegistry, sem abrir nenhum dispositivo (D-07, RF-01, R-04).
///
/// Consultar propriedades do registro não depende de Input Monitoring. `GCController` não expõe fabricante,
/// produto nem transporte, e a correlação é por exclusão: com candidatos de transportes diferentes, `unknown`.
/// Os pares (fabricante, produtos) vêm de `ControllerModel` (`007-controle-ipega` D-01, D-06).
enum TransportResolver {
    static func resolve(for model: ControllerModel) -> ConnectionType {
        let transports = Set(candidateTransports(for: model))
        guard transports.count == 1, let transport = transports.first else { return .unknown }
        return transport
    }

    static func candidateTransports(for model: ControllerModel) -> [ConnectionType] {
        devices(vendorID: model.vendorID).compactMap { device in
            guard model.matches(device.identity) else { return nil }
            let raw = device.transport.lowercased()
            if raw.contains("bluetooth") { return .bluetooth }
            if raw.contains("usb") { return .usb }
            return .unknown
        }
    }

    /// Pares (fabricante, produto) dos dispositivos HID presentes, para `ControllerModel.classify`.
    static func presentDevices() -> [ControllerModel.HIDIdentity] {
        devices(vendorID: nil).map(\.identity)
    }

    private static func devices(vendorID: Int?) -> [(identity: ControllerModel.HIDIdentity, transport: String)] {
        guard let matching = IOServiceMatching(kIOHIDDeviceKey) as NSMutableDictionary? else { return [] }
        if let vendorID { matching[kIOHIDVendorIDKey] = vendorID }

        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else { return [] }
        defer { IOObjectRelease(iterator) }

        var found: [(identity: ControllerModel.HIDIdentity, transport: String)] = []
        var service = IOIteratorNext(iterator)
        while service != 0 {
            defer {
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }
            guard let vendor = property(service, kIOHIDVendorIDKey) as? Int,
                  let product = property(service, kIOHIDProductIDKey) as? Int else { continue }
            found.append((ControllerModel.HIDIdentity(vendorID: vendor, productID: product),
                          property(service, kIOHIDTransportKey) as? String ?? ""))
        }
        return found
    }

    private static func property(_ service: io_object_t, _ key: String) -> Any? {
        IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()
    }
}
