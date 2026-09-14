import Testing
@testable import JoystickCore

@Suite struct DualSenseReportTests {
    static func report(id: UInt8, length: Int, psIndex: Int, pressed: Bool) -> [UInt8] {
        var bytes = [UInt8](repeating: 0xFE, count: length)
        bytes[0] = id
        bytes[psIndex] = pressed ? 0xFF : 0xFE
        return bytes
    }

    @Test func bitDoPSNasTresFormas() {
        for (id, length, index) in [(UInt8(0x31), 78, 11), (UInt8(0x01), 64, 10), (UInt8(0x01), 10, 7)] {
            #expect(DualSenseReport.homeButton(reportID: UInt32(id), bytes: Self.report(id: id, length: length, psIndex: index, pressed: true)) == true)
            #expect(DualSenseReport.homeButton(reportID: UInt32(id), bytes: Self.report(id: id, length: length, psIndex: index, pressed: false)) == false)
        }
    }

    @Test func relatorioDesconhecidoNaoDecide() {
        #expect(DualSenseReport.homeButton(reportID: 0x05, bytes: [UInt8](repeating: 0, count: 41)) == nil)
        #expect(DualSenseReport.homeButton(reportID: 0x31, bytes: [0x31, 0]) == nil)
    }
}
