import Testing
@testable import JoystickCore

/// PS no relatório bruto do DualShock 4 (`012-controle-dualshock-4` D-04, D-10). Índices fixados pela sonda P-02 de
/// 2026-09-22 (`0x11`, byte 9) e pela literatura (`0x01`, byte 7).
@Suite struct DualShock4ReportTests {
    static func report(id: UInt8, length: Int, psIndex: Int, pressed: Bool) -> [UInt8] {
        var bytes = [UInt8](repeating: 0xFE, count: length)
        bytes[0] = id
        bytes[psIndex] = pressed ? 0xFF : 0xFE
        return bytes
    }

    /// Relatório `0x11` em repouso, tal como a sonda o mostrou (bytes 0 a 15; o resto é zero aqui).
    static var restingBluetoothReport: [UInt8] {
        var bytes = [UInt8](repeating: 0, count: 78)
        for (index, value) in [0x11, 0xC0, 0x00, 0x80, 0x80, 0x80, 0x80, 0x08, 0x00, 0x18, 0x00, 0x00, 0x00, 0xE6, 0x12, 0xF6].enumerated() {
            bytes[index] = UInt8(value)
        }
        return bytes
    }

    @Test func bitDoPSNasTresFormas() {
        for (id, length, index) in [(UInt8(0x11), 78, 9), (UInt8(0x01), 64, 7), (UInt8(0x01), 10, 7)] {
            #expect(DualShock4Report.homeButton(reportID: UInt32(id), bytes: Self.report(id: id, length: length, psIndex: index, pressed: true)) == true, "\(id) \(length)")
            #expect(DualShock4Report.homeButton(reportID: UInt32(id), bytes: Self.report(id: id, length: length, psIndex: index, pressed: false)) == false, "\(id) \(length)")
        }
    }

    /// A amostra real da sonda: em repouso o byte 9 vale 0x18 (contador nos bits 3 e 4) e o PS está solto; com o
    /// bit 0 ligado, pressionado. O clique do touchpad (bit 1) e o contador não afetam a leitura.
    @Test func amostraDaSondaEOutrosBitsDoMesmoByte() {
        var bytes = Self.restingBluetoothReport
        #expect(DualShock4Report.homeButton(reportID: 0x11, bytes: bytes) == false)
        bytes[9] = 0x19
        #expect(DualShock4Report.homeButton(reportID: 0x11, bytes: bytes) == true)
        bytes[9] = 0xFE
        #expect(DualShock4Report.homeButton(reportID: 0x11, bytes: bytes) == false)
        bytes[9] = 0x01
        #expect(DualShock4Report.homeButton(reportID: 0x11, bytes: bytes) == true)
        // O byte 7 do `0x11` é o direcional e as faces, não o PS.
        bytes[9] = 0x18
        bytes[7] = 0xFF
        #expect(DualShock4Report.homeButton(reportID: 0x11, bytes: bytes) == false)
    }

    @Test func relatorioCurtoNaoDecide() {
        #expect(DualShock4Report.homeButton(reportID: 0x11, bytes: [UInt8](repeating: 0xFF, count: 11)) == nil)
        #expect(DualShock4Report.homeButton(reportID: 0x11, bytes: Self.report(id: 0x11, length: 12, psIndex: 9, pressed: true)) == true)
        #expect(DualShock4Report.homeButton(reportID: 0x01, bytes: [UInt8](repeating: 0xFF, count: 9)) == nil)
        #expect(DualShock4Report.homeButton(reportID: 0x01, bytes: []) == nil)
    }

    @Test func relatorioDesconhecidoNaoDecide() {
        #expect(DualShock4Report.homeButton(reportID: 0x05, bytes: [UInt8](repeating: 0xFF, count: 41)) == nil)
        // O `0x31` é do DualSense; o intérprete do DualShock 4 não o reconhece.
        #expect(DualShock4Report.homeButton(reportID: 0x31, bytes: [UInt8](repeating: 0xFF, count: 78)) == nil)
        #expect(DualShock4Report.homeButton(reportID: 0x30, bytes: [UInt8](repeating: 0xFF, count: 64)) == nil)
    }

    /// Os intérpretes dos três modelos discordam no índice: o mesmo relatório `0x01` de 64 bytes lê o PS no byte 7
    /// para o DualShock 4 e no byte 10 para o DualSense, e é `ExtendedReportActivator` quem escolhe pelo modelo.
    @Test func indicesDiferemDosDoDualSense() {
        let bytes = Self.report(id: 0x01, length: 64, psIndex: 7, pressed: true)
        #expect(DualShock4Report.homeButton(reportID: 0x01, bytes: bytes) == true)
        #expect(DualSenseReport.homeButton(reportID: 0x01, bytes: bytes) == false)
    }
}
