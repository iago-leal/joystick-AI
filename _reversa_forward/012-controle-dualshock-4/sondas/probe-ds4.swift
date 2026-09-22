// Sonda descartável da feature `012-controle-dualshock-4` (D-11, portão PM-0). NÃO faz parte do app.
//
// Uso, com o app fechado e o GameSir G8+ no modo PlayStation conectado por Bluetooth:
//
//     pkill -x JoystickAIPoC 2>/dev/null
//     cd _reversa_forward/012-controle-dualshock-4 && swift sondas/probe-ds4.swift
//
// Se o compilador reclamar do SDK, prefixe `SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk`.
// O terminal precisa de Input Monitoring (Ajustes › Privacidade e Segurança › Monitoramento de Entrada) para o
// leitor HID abrir o dispositivo; sem isso, `IOHIDManagerOpen` falha e só a interface de controles responde.
//
// O que o programa faz:
//   P-01  liga `shouldMonitorBackgroundEvents`, enumera `GCController.controllers()`, imprime a classe do perfil,
//         a categoria, os elementos e o dicionário `touchpads`; a cada mudança de botão imprime o nome do elemento
//         e, entre colchetes, a propriedade do `GCExtendedGamepad` que aponta para o mesmo objeto (`buttonOptions`,
//         `buttonMenu`, `buttonHome`, `touchpadButton`…), o que fixa por onde chegam o Share e o PS.
//   P-02  abre um `IOHIDManager` casando 0x054C com 0x05C4 e 0x09CC, imprime identificador e tamanho de cada
//         relatório de entrada na primeira vez e sempre que o tamanho muda; aprende por 3 s os bits que mudam em
//         repouso (contador, analógicos) e depois imprime índice, valor e bits de cada byte que muda fora desse
//         ruído. A tecla `f` (Enter) lê o relatório de recurso 0x05 e imprime o resultado; o formato que chegar em
//         seguida aparece como "primeira vez" ou "tamanho mudou".
//   P-03  imprime `battery` do controle na conexão e sob a tecla `b`; imprime `Transport` do dispositivo HID casado.
//
// Nenhuma escrita no dispositivo além do pedido de leitura do recurso 0x05, o mesmo que o app já faz no DualSense.
// Teclas: f = recurso 0x05 | b = bateria | e = elementos de novo | s = resumo do ruído | q = sair.

import Foundation
import GameController
import IOKit.hid

let sonyVendorID = 0x054C
let dualShock4ProductIDs = [0x05C4, 0x09CC]

// MARK: - Utilidades

let clock: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss.SSS"
    return formatter
}()

func log(_ message: String) {
    print("[\(clock.string(from: Date()))] \(message)")
    fflush(stdout)
}

func hex(_ byte: UInt8) -> String { String(format: "0x%02X", byte) }
func hex(_ id: UInt32) -> String { String(format: "0x%02X", id) }
func hex(_ result: IOReturn) -> String { "0x" + String(UInt32(bitPattern: result), radix: 16) }
func hex4(_ value: Int) -> String { String(format: "0x%04X", value) }

// MARK: - P-01 e P-03: interface de controles do sistema

GCController.shouldMonitorBackgroundEvents = true

var attached: [ObjectIdentifier: GCController] = [:]
var observers: [Any] = []

func batteryDescription(_ controller: GCController) -> String {
    guard let battery = controller.battery else { return "battery = nil (propriedade ausente)" }
    let state: String = switch battery.batteryState {
    case .discharging: "discharging"
    case .charging: "charging"
    case .full: "full"
    default: "unknown"
    }
    return "battery = \(Int((battery.batteryLevel * 100).rounded())) % \(state) (nível bruto \(battery.batteryLevel))"
}

/// Propriedades nomeadas do perfil que apontam para o mesmo objeto do elemento; é isso que resolve D-02.
func aliases(of button: GCControllerButtonInput, in gamepad: GCExtendedGamepad?) -> String {
    guard let gamepad else { return "" }
    var named: [(String, GCControllerButtonInput?)] = [
        ("buttonA", gamepad.buttonA), ("buttonB", gamepad.buttonB), ("buttonX", gamepad.buttonX), ("buttonY", gamepad.buttonY),
        ("leftShoulder", gamepad.leftShoulder), ("rightShoulder", gamepad.rightShoulder),
        ("leftTrigger", gamepad.leftTrigger), ("rightTrigger", gamepad.rightTrigger),
        ("leftThumbstickButton", gamepad.leftThumbstickButton), ("rightThumbstickButton", gamepad.rightThumbstickButton),
        ("buttonOptions", gamepad.buttonOptions), ("buttonMenu", gamepad.buttonMenu), ("buttonHome", gamepad.buttonHome),
        ("dpad.up", gamepad.dpad.up), ("dpad.down", gamepad.dpad.down), ("dpad.left", gamepad.dpad.left), ("dpad.right", gamepad.dpad.right),
    ]
    if let pad = gamepad as? GCDualShockGamepad { named.append(("touchpadButton (GCDualShockGamepad)", pad.touchpadButton)) }
    if let pad = gamepad as? GCDualSenseGamepad { named.append(("touchpadButton (GCDualSenseGamepad)", pad.touchpadButton)) }
    let matches = named.compactMap { name, candidate in candidate === button ? name : nil }
    return matches.isEmpty ? "sem propriedade nomeada" : matches.joined(separator: ", ")
}

func printElements(_ controller: GCController) {
    let gamepad = controller.extendedGamepad
    let profile = controller.physicalInputProfile
    log("P-01 classe do perfil: \(gamepad.map { String(describing: type(of: $0)) } ?? "sem extendedGamepad")")
    log("P-01 is GCDualShockGamepad = \(gamepad is GCDualShockGamepad) | is GCDualSenseGamepad = \(gamepad is GCDualSenseGamepad) | is GCExtendedGamepad = \(gamepad != nil)")
    log("P-01 elementos (\(profile.elements.count)): \(profile.elements.keys.sorted().joined(separator: ", "))")
    log("P-01 botões (\(profile.buttons.count)): \(profile.buttons.keys.sorted().joined(separator: ", "))")
    log("P-01 dicionário touchpads (\(profile.touchpads.count)): \(profile.touchpads.keys.sorted())")
    log("P-01 buttonHome presente = \(gamepad?.buttonHome != nil) | buttonOptions presente = \(gamepad?.buttonOptions != nil) | buttonMenu presente = \(gamepad?.buttonMenu != nil)")
    if let pad = gamepad as? GCDualShockGamepad {
        let button: GCControllerButtonInput? = pad.touchpadButton
        let primary: GCControllerDirectionPad? = pad.touchpadPrimary
        let secondary: GCControllerDirectionPad? = pad.touchpadSecondary
        log("P-01 GCDualShockGamepad: touchpadButton \(button == nil ? "nil" : "presente") | touchpadPrimary \(primary == nil ? "nil" : "presente") | touchpadSecondary \(secondary == nil ? "nil" : "presente")")
    }
}

func describe(_ controller: GCController) {
    let key = ObjectIdentifier(controller)
    guard attached[key] == nil else { return }
    attached[key] = controller
    let gamepad = controller.extendedGamepad
    log("=== controle: \"\(controller.vendorName ?? "sem nome")\" | productCategory = \"\(controller.productCategory)\"")
    printElements(controller)
    log("P-03 \(batteryDescription(controller))")

    // Como o app: pede a supressão de gestos no PS antes de escutar, para a P-01 medir a mesma condição.
    if let home = gamepad?.buttonHome {
        home.preferredSystemGestureState = .disabled
        log("P-01 buttonHome.preferredSystemGestureState = disabled (como o app)")
    }

    for (name, button) in profile(controller).buttons {
        let alias = aliases(of: button, in: gamepad)
        button.pressedChangedHandler = { _, _, pressed in
            log("P-01 botão \"\(name)\" [\(alias)]: \(pressed ? "PRESSIONADO" : "solto")")
        }
    }
    for (name, touchpad) in profile(controller).touchpads {
        touchpad.touchDown = { _, x, y, _, _ in log("P-01 touchDown em \"\(name)\" (x=\(x) y=\(y))") }
        touchpad.touchUp = { _, _, _, _, _ in log("P-01 touchUp em \"\(name)\"") }
    }
    if let pad = gamepad as? GCDualShockGamepad {
        // No SDK, as superfícies do `GCDualShockGamepad` são opcionais (as do `GCDualSenseGamepad` não são): D-03 precisa
        // saber se elas existem neste aparelho.
        let surfaces: [(String, GCControllerDirectionPad?)] = [("touchpadPrimary", pad.touchpadPrimary), ("touchpadSecondary", pad.touchpadSecondary)]
        for (label, optionalSurface) in surfaces {
            guard let surface = optionalSurface else {
                log("P-01 superfície \(label) = nil neste perfil")
                continue
            }
            log("P-01 superfície \(label) presente")
            var lastPrinted = Date.distantPast
            surface.valueChangedHandler = { _, x, y in
                guard Date().timeIntervalSince(lastPrinted) > 0.25 else { return }
                lastPrinted = Date()
                log("P-01 superfície \(label) mudou: x=\(x) y=\(y)  (num clone sem touchpad isto NÃO deve aparecer)")
            }
        }
    }
}

func profile(_ controller: GCController) -> GCPhysicalInputProfile { controller.physicalInputProfile }

let center = NotificationCenter.default
observers.append(center.addObserver(forName: .GCControllerDidConnect, object: nil, queue: .main) { note in
    guard let controller = note.object as? GCController else { return }
    log("GCControllerDidConnect")
    describe(controller)
})
observers.append(center.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: .main) { note in
    guard let controller = note.object as? GCController else { return }
    log("GCControllerDidDisconnect: \"\(controller.vendorName ?? "sem nome")\"")
    attached[ObjectIdentifier(controller)] = nil
})

// MARK: - P-02: relatórios HID

final class ReportWatch {
    var last: [UInt32: [UInt8]] = [:]
    var noisy: [UInt32: [UInt8]] = [:]
    var seen: [UInt32: (length: Int, count: Int)] = [:]
    var learnUntil = Date().addingTimeInterval(3)
    var printedThisSecond = 0
    var second = Int(Date().timeIntervalSince1970)
}

var watches: [UnsafeMutableRawPointer: ReportWatch] = [:]
var openDevices: [IOHIDDevice] = []

func handleReport(sender: UnsafeMutableRawPointer, reportID: UInt32, bytes: [UInt8]) {
    let watch: ReportWatch
    if let existing = watches[sender] {
        watch = existing
    } else {
        watch = ReportWatch()
        watches[sender] = watch
    }

    if let entry = watch.seen[reportID], entry.length == bytes.count {
        watch.seen[reportID] = (entry.length, entry.count + 1)
    } else {
        let note = watch.seen[reportID].map { "tamanho mudou de \($0.length)" } ?? "primeira vez"
        log("P-02 relatório \(hex(reportID)) com \(bytes.count) bytes (\(note))")
        log("     bytes 0…15: \(bytes.prefix(16).map(hex).joined(separator: " "))\(bytes.count > 16 ? " …" : "")")
        watch.seen[reportID] = (bytes.count, 1)
        watch.last[reportID] = bytes
        watch.noisy[reportID] = [UInt8](repeating: 0, count: bytes.count)
        watch.learnUntil = Date().addingTimeInterval(3)
        log("     aprendendo o ruído de repouso por 3 s: não toque em nada")
        return
    }

    guard let last = watch.last[reportID], last.count == bytes.count else {
        watch.last[reportID] = bytes
        return
    }
    var noisy = watch.noisy[reportID] ?? [UInt8](repeating: 0, count: bytes.count)
    let learning = Date() < watch.learnUntil
    var changes: [String] = []
    for index in 0..<bytes.count where last[index] != bytes[index] {
        let diff = last[index] ^ bytes[index]
        if learning {
            noisy[index] |= diff
            continue
        }
        let visible = diff & ~noisy[index]
        guard visible != 0 else { continue }
        let bits = (0..<8).filter { visible & (1 << $0) != 0 }
        changes.append("byte \(index): \(hex(last[index]))→\(hex(bytes[index])) bit(s) \(bits)")
    }
    watch.last[reportID] = bytes
    watch.noisy[reportID] = noisy
    guard !changes.isEmpty else { return }

    let now = Int(Date().timeIntervalSince1970)
    if now != watch.second {
        if watch.printedThisSecond > 40 { log("     … \(watch.printedThisSecond - 40) linha(s) suprimida(s) neste segundo") }
        watch.second = now
        watch.printedThisSecond = 0
    }
    watch.printedThisSecond += 1
    guard watch.printedThisSecond <= 40 else { return }
    log("P-02 rel \(hex(reportID))/\(bytes.count) B: " + changes.joined(separator: "; "))
}

func noiseSummary() {
    guard !watches.isEmpty else {
        log("P-02 nenhum relatório recebido ainda")
        return
    }
    for watch in watches.values {
        for (id, entry) in watch.seen.sorted(by: { $0.key < $1.key }) {
            let noisy = watch.noisy[id] ?? []
            let described = noisy.enumerated().compactMap { index, mask -> String? in
                guard mask != 0 else { return nil }
                return "byte \(index) bits \((0..<8).filter { mask & (1 << $0) != 0 })"
            }
            log("P-02 resumo: relatório \(hex(id)) com \(entry.length) bytes, \(entry.count) recebido(s); ruído de repouso: \(described.isEmpty ? "nenhum" : described.joined(separator: "; "))")
        }
    }
}

func readCalibrationFeature() {
    guard !openDevices.isEmpty else {
        log("P-02 nenhum dispositivo HID aberto; confira o Input Monitoring do terminal")
        return
    }
    for device in openDevices {
        var buffer = [UInt8](repeating: 0, count: 64)
        var length = CFIndex(buffer.count)
        let result = IOHIDDeviceGetReport(device, kIOHIDReportTypeFeature, 0x05, &buffer, &length)
        let status = result == kIOReturnSuccess ? "ok" : hex(result)
        log("P-02 recurso 0x05: \(status), \(length) bytes: \(buffer.prefix(max(0, Int(length))).map(hex).joined(separator: " "))")
    }
    for watch in watches.values { watch.learnUntil = Date().addingTimeInterval(3) }
    log("     observe se o próximo relatório aparece como \"primeira vez\" ou \"tamanho mudou\"; ruído reaprendido por 3 s")
}

let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
let matching = dualShock4ProductIDs.map { [kIOHIDVendorIDKey: sonyVendorID, kIOHIDProductIDKey: $0] as NSDictionary }
IOHIDManagerSetDeviceMatchingMultiple(manager, matching as CFArray)
IOHIDManagerRegisterDeviceMatchingCallback(manager, { _, _, _, device in
    let product = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as? String ?? "?"
    let vendor = IOHIDDeviceGetProperty(device, kIOHIDVendorIDKey as CFString) as? Int ?? 0
    let productID = IOHIDDeviceGetProperty(device, kIOHIDProductIDKey as CFString) as? Int ?? 0
    let transport = IOHIDDeviceGetProperty(device, kIOHIDTransportKey as CFString) as? String ?? "?"
    let maxInput = IOHIDDeviceGetProperty(device, kIOHIDMaxInputReportSizeKey as CFString) as? Int ?? 0
    let maxFeature = IOHIDDeviceGetProperty(device, kIOHIDMaxFeatureReportSizeKey as CFString) as? Int ?? 0
    log("P-02/P-03 dispositivo HID casado: \"\(product)\" \(hex4(vendor))/\(hex4(productID)) Transport = \"\(transport)\" maxInputReport = \(maxInput) maxFeatureReport = \(maxFeature)")
    openDevices.append(device)
    watches[Unmanaged.passUnretained(device).toOpaque()] = ReportWatch()
}, nil)
IOHIDManagerRegisterDeviceRemovalCallback(manager, { _, _, _, device in
    log("P-02 dispositivo HID removido")
    openDevices.removeAll { $0 === device }
    watches[Unmanaged.passUnretained(device).toOpaque()] = nil
}, nil)
IOHIDManagerRegisterInputReportWithTimeStampCallback(manager, { _, _, sender, _, reportID, report, length, _ in
    guard let sender else { return }
    let bytes = [UInt8](UnsafeBufferPointer(start: report, count: length))
    handleReport(sender: sender, reportID: reportID, bytes: bytes)
}, nil)
IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
let openResult = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
log("IOHIDManagerOpen: \(openResult == kIOReturnSuccess ? "ok" : hex(openResult) + " (Input Monitoring negado ao terminal?)")")

// MARK: - Teclado do terminal

DispatchQueue.global().async {
    while let line = readLine() {
        let command = line.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        DispatchQueue.main.async {
            switch command {
            case "f", "5": readCalibrationFeature()
            case "b": attached.values.forEach { log("P-03 \(batteryDescription($0))") }
            case "e": attached.values.forEach(printElements)
            case "s": noiseSummary()
            case "q": log("fim"); exit(0)
            default: log("teclas: f = recurso 0x05 | b = bateria | e = elementos | s = resumo do ruído | q = sair")
            }
        }
    }
}

// MARK: - Início

log("sonda da feature 012 iniciada; teclas: f = recurso 0x05 | b = bateria | e = elementos | s = resumo do ruído | q = sair")
for controller in GCController.controllers() { describe(controller) }
let retry = Timer(timeInterval: 1.5, repeats: false) { _ in
    if attached.isEmpty { log("P-01 nenhum controle na interface de controles ainda; aguardando GCControllerDidConnect") }
    for controller in GCController.controllers() { describe(controller) }
}
RunLoop.main.add(retry, forMode: .common)
let periodic = Timer(timeInterval: 10, repeats: true) { _ in noiseSummary() }
RunLoop.main.add(periodic, forMode: .common)
RunLoop.main.run()
