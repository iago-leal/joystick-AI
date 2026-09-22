import Foundation
import IOKit.hid
import JoystickCore

/// Leitor HID do botão PS do DualSense e do DualShock 4 e do Home do Ipega, e ativador do relatório completo dos
/// modelos Sony sem fio.
///
/// Por Bluetooth o DualSense só passa ao relatório completo (`0x31`) quando o host lê o relatório de recurso
/// `0x05` (calibração); o GameController do macOS não faz esse pedido, e o touchpad fica mudo (PM-2, P-02).
/// Diverge de D-07: o dispositivo é aberto para esse pedido e para ler o PS, que o macOS retém antes do
/// GameController (P-07). O Home do Ipega também não chega à interface de controles e é lido do relatório `0x30`
/// (`007-controle-ipega` D-04), assim como os analógicos do Ipega, que o driver do sistema zera (revisão de D-03 no
/// PM-1). O PS do DualShock 4 é retido do mesmo modo e lido do relatório `0x11` (ou `0x01`) por `DualShock4Report`;
/// o pedido do recurso `0x05` é estendido a ele por ser o mesmo mecanismo da literatura, embora a sonda P-02 de
/// 2026-09-22 tenha mostrado o sistema já entregando o `0x11` sem o pedido, que resultou `ok` e inócuo
/// (`012-controle-dualshock-4` D-04, D-05). Dos relatórios de entrada só o bit do PS ou do Home e os analógicos do
/// Ipega são examinados, por dispositivo.
final class ExtendedReportActivator {
    static let calibrationReportID: CFIndex = 0x05

    private struct DeviceState {
        var model: ControllerModel?
        var homePressed = false
        var sticks: (left: SwitchProReport.Stick, right: SwitchProReport.Stick)?
    }

    private let log: DiagnosticLog
    private let manager: IOHIDManager
    /// Por dispositivo emissor, chaveado pelo ponteiro do `IOHIDDevice`; limpo na remoção.
    private var devices: [UnsafeMutableRawPointer: DeviceState] = [:]
    /// Chamado na main thread a cada mudança do PS ou do Home, com o modelo do emissor e o carimbo de chegada.
    var onHomeButton: ((Bool, ControllerModel, UInt64) -> Void)?
    /// Chamado na main thread quando os analógicos do Ipega mudam no relatório bruto (revisão de D-03 no PM-1).
    var onIpegaSticks: ((SwitchProReport.Stick, SwitchProReport.Stick, UInt64) -> Void)?

    init(log: DiagnosticLog) {
        self.log = log
        manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
    }

    /// Deve ser chamado na main thread: o gerenciador é agendado no *run loop* principal e
    /// chama de volta a cada controle conectado, inclusive nas reconexões.
    func start() {
        let matching = ControllerModel.allCases.flatMap { model in
            model.productIDs.map { [kIOHIDVendorIDKey: model.vendorID, kIOHIDProductIDKey: $0] as NSDictionary }
        }
        IOHIDManagerSetDeviceMatchingMultiple(manager, matching as CFArray)
        let context = Unmanaged.passUnretained(self).toOpaque()
        IOHIDManagerRegisterDeviceMatchingCallback(manager, { context, _, _, device in
            guard let context else { return }
            Unmanaged<ExtendedReportActivator>.fromOpaque(context).takeUnretainedValue().activate(device)
        }, context)
        IOHIDManagerRegisterDeviceRemovalCallback(manager, { context, _, _, device in
            guard let context else { return }
            Unmanaged<ExtendedReportActivator>.fromOpaque(context).takeUnretainedValue()
                .devices[Unmanaged.passUnretained(device).toOpaque()] = nil
        }, context)
        IOHIDManagerRegisterInputReportWithTimeStampCallback(manager, { context, _, sender, _, reportID, report, length, _ in
            let tArrival = MonotonicClock.nowNs()
            guard let context, let sender else { return }
            let bytes = [UInt8](UnsafeBufferPointer(start: report, count: length))
            Unmanaged<ExtendedReportActivator>.fromOpaque(context).takeUnretainedValue()
                .handleReport(sender: sender, reportID: reportID, bytes: bytes, tArrival: tArrival)
        }, context)
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        let result = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        if result != kIOReturnSuccess {
            log.log(LogEventCatalog.controllerError(message: "IOHIDManagerOpen falhou: \(Self.hex(result))"))
        }
    }

    private func handleReport(sender: UnsafeMutableRawPointer, reportID: UInt32, bytes: [UInt8], tArrival: UInt64) {
        var state = devices[sender] ?? DeviceState(model: Self.model(of: Unmanaged<IOHIDDevice>.fromOpaque(sender).takeUnretainedValue()))
        let pressed: Bool? = switch state.model {
        case .dualSense: DualSenseReport.homeButton(reportID: reportID, bytes: bytes)
        case .ipega: SwitchProReport.homeButton(reportID: reportID, bytes: bytes)
        case .dualShock4: DualShock4Report.homeButton(reportID: reportID, bytes: bytes)
        case nil: nil
        }
        defer { devices[sender] = state }
        // Só mudanças seguem para a fila `input`: o Ipega envia o relatório a cada 8 ms, parado ou não.
        if state.model == .ipega, let sticks = SwitchProReport.sticks(reportID: reportID, bytes: bytes),
           state.sticks.map({ $0.left != sticks.left || $0.right != sticks.right }) ?? true {
            state.sticks = sticks
            onIpegaSticks?(sticks.left, sticks.right, tArrival)
        }
        guard let model = state.model, let pressed, pressed != state.homePressed else { return }
        state.homePressed = pressed
        onHomeButton?(pressed, model, tArrival)
    }

    private func activate(_ device: IOHIDDevice) {
        let model = Self.model(of: device)
        devices[Unmanaged.passUnretained(device).toOpaque()] = DeviceState(model: model)
        // O pedido do relatório de recurso vale para os modelos Sony sem fio; o Ipega não tem esse mecanismo.
        guard model == .dualSense || model == .dualShock4 else { return }
        let transport = (IOHIDDeviceGetProperty(device, kIOHIDTransportKey as CFString) as? String ?? "").lowercased()
        guard transport.contains("bluetooth") else { return }
        var buffer = [UInt8](repeating: 0, count: 64)
        var length = CFIndex(buffer.count)
        let result = IOHIDDeviceGetReport(device, kIOHIDReportTypeFeature, Self.calibrationReportID, &buffer, &length)
        log.log(LogEventCatalog.controllerExtendedReport(
            transport: .bluetooth, result: result == kIOReturnSuccess ? "ok" : Self.hex(result)))
    }

    private static func model(of device: IOHIDDevice) -> ControllerModel? {
        guard let vendor = IOHIDDeviceGetProperty(device, kIOHIDVendorIDKey as CFString) as? Int,
              let product = IOHIDDeviceGetProperty(device, kIOHIDProductIDKey as CFString) as? Int else { return nil }
        let identity = ControllerModel.HIDIdentity(vendorID: vendor, productID: product)
        return ControllerModel.allCases.first { $0.matches(identity) }
    }

    private static func hex(_ value: IOReturn) -> String {
        "0x" + String(UInt32(bitPattern: value), radix: 16)
    }
}
