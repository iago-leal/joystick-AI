import Foundation
import IOKit
import IOKit.hid
import JoystickCore

/// Tipo de conexão do DualSense pelo IORegistry, sem abrir o dispositivo (D-07, RF-01, R-04).
///
/// Consultar propriedades do registro não depende de Input Monitoring. `GCController` não expõe
/// o transporte, e a correlação é por exclusão: com candidatos de transportes diferentes, `unknown`.
enum TransportResolver {
    static let sonyVendorID = 0x054C
    /// DualSense e DualSense Edge.
    static let dualSenseProductIDs: Set<Int> = [0x0CE6, 0x0DF2]

    static func resolve() -> ConnectionType {
        let transports = Set(candidateTransports())
        guard transports.count == 1, let transport = transports.first else { return .unknown }
        return transport
    }

    static func candidateTransports() -> [ConnectionType] {
        guard let matching = IOServiceMatching(kIOHIDDeviceKey) as NSMutableDictionary? else { return [] }
        matching[kIOHIDVendorIDKey] = sonyVendorID

        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else { return [] }
        defer { IOObjectRelease(iterator) }

        var transports: [ConnectionType] = []
        var service = IOIteratorNext(iterator)
        while service != 0 {
            defer {
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }
            guard let product = property(service, kIOHIDProductIDKey) as? Int, dualSenseProductIDs.contains(product) else { continue }
            let raw = (property(service, kIOHIDTransportKey) as? String ?? "").lowercased()
            if raw.contains("bluetooth") {
                transports.append(.bluetooth)
            } else if raw.contains("usb") {
                transports.append(.usb)
            } else {
                transports.append(.unknown)
            }
        }
        return transports
    }

    private static func property(_ service: io_object_t, _ key: String) -> Any? {
        IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()
    }
}
