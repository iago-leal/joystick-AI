import Foundation
import IOKit.hid
import JoystickCore

/// Tira o DualSense por Bluetooth do relatório simplificado (`0x01`, 10 bytes, sem touchpad).
///
/// Por Bluetooth o controle só passa ao relatório completo (`0x31`) quando o host lê o relatório de recurso
/// `0x05` (calibração); o GameController do macOS não faz esse pedido, e o touchpad fica mudo (PM-2, P-02).
/// Diverge de D-07: o dispositivo é aberto para esse pedido e para ler o PS, que o macOS retém antes do
/// GameController (P-07); dos relatórios de entrada só o bit do PS é examinado.
final class ExtendedReportActivator {
    static let calibrationReportID: CFIndex = 0x05

    private let log: DiagnosticLog
    private let manager: IOHIDManager
    private var homePressed = false
    /// Chamado na main thread a cada mudança do PS, com o carimbo de chegada.
    var onHomeButton: ((Bool, UInt64) -> Void)?

    init(log: DiagnosticLog) {
        self.log = log
        manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
    }

    /// Deve ser chamado na main thread: o gerenciador é agendado no *run loop* principal e
    /// chama de volta a cada DualSense conectado, inclusive nas reconexões.
    func start() {
        let matching = TransportResolver.dualSenseProductIDs.map {
            [kIOHIDVendorIDKey: TransportResolver.sonyVendorID, kIOHIDProductIDKey: $0] as NSDictionary
        }
        IOHIDManagerSetDeviceMatchingMultiple(manager, matching as CFArray)
        let context = Unmanaged.passUnretained(self).toOpaque()
        IOHIDManagerRegisterDeviceMatchingCallback(manager, { context, _, _, device in
            guard let context else { return }
            Unmanaged<ExtendedReportActivator>.fromOpaque(context).takeUnretainedValue().activate(device)
        }, context)
        IOHIDManagerRegisterInputReportWithTimeStampCallback(manager, { context, _, _, _, reportID, report, length, _ in
            let tArrival = MonotonicClock.nowNs()
            guard let context else { return }
            let bytes = [UInt8](UnsafeBufferPointer(start: report, count: length))
            Unmanaged<ExtendedReportActivator>.fromOpaque(context).takeUnretainedValue()
                .handleReport(reportID: reportID, bytes: bytes, tArrival: tArrival)
        }, context)
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        let result = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        if result != kIOReturnSuccess {
            log.log(LogEventCatalog.controllerError(message: "IOHIDManagerOpen falhou: \(Self.hex(result))"))
        }
    }

    private func handleReport(reportID: UInt32, bytes: [UInt8], tArrival: UInt64) {
        guard let pressed = DualSenseReport.homeButton(reportID: reportID, bytes: bytes), pressed != homePressed else { return }
        homePressed = pressed
        onHomeButton?(pressed, tArrival)
    }

    private func activate(_ device: IOHIDDevice) {
        let transport = (IOHIDDeviceGetProperty(device, kIOHIDTransportKey as CFString) as? String ?? "").lowercased()
        guard transport.contains("bluetooth") else { return }
        var buffer = [UInt8](repeating: 0, count: 64)
        var length = CFIndex(buffer.count)
        let result = IOHIDDeviceGetReport(device, kIOHIDReportTypeFeature, Self.calibrationReportID, &buffer, &length)
        log.log(LogEventCatalog.controllerExtendedReport(
            transport: .bluetooth, result: result == kIOReturnSuccess ? "ok" : Self.hex(result)))
    }

    private static func hex(_ value: IOReturn) -> String {
        "0x" + String(UInt32(bitPattern: value), radix: 16)
    }
}
