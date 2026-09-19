import Testing
@testable import JoystickCore

/// Bit do Home no relatório `0x30` do Ipega (`007-controle-ipega` D-04).
@Suite struct SwitchProReportTests {
    static func report(id: UInt8 = 0x30, length: Int = 64, byte4: UInt8) -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: length)
        bytes[0] = id
        bytes[4] = byte4
        return bytes
    }

    @Test func bitDoHome() {
        #expect(SwitchProReport.homeButton(reportID: 0x30, bytes: Self.report(byte4: 0x10)) == true)
        #expect(SwitchProReport.homeButton(reportID: 0x30, bytes: Self.report(byte4: 0x00)) == false)
    }

    /// Select, Start, L3, R3 e Share dividem o byte 4 sem afetar o Home.
    @Test func outrosBitsDoByte4NaoAfetam() {
        #expect(SwitchProReport.homeButton(reportID: 0x30, bytes: Self.report(byte4: 0xEF)) == false)
        #expect(SwitchProReport.homeButton(reportID: 0x30, bytes: Self.report(byte4: 0x20)) == false)
        #expect(SwitchProReport.homeButton(reportID: 0x30, bytes: Self.report(byte4: 0x30)) == true)
        #expect(SwitchProReport.homeButton(reportID: 0x30, bytes: Self.report(byte4: 0xFF)) == true)
    }

    @Test func relatorioCurtoOuDeOutroIdentificadorNaoDecide() {
        #expect(SwitchProReport.homeButton(reportID: 0x30, bytes: Self.report(length: 12, byte4: 0x10)) == nil)
        #expect(SwitchProReport.homeButton(reportID: 0x30, bytes: Self.report(length: 13, byte4: 0x10)) == true)
        #expect(SwitchProReport.homeButton(reportID: 0x21, bytes: Self.report(id: 0x21, byte4: 0x10)) == nil)
        #expect(SwitchProReport.homeButton(reportID: 0x3F, bytes: Self.report(id: 0x3F, byte4: 0x10)) == nil)
    }

    // MARK: analógicos (revisão de D-03 no PM-1)

    /// Grava os quatro eixos de 12 bits nos bytes 6 a 11, como o Ipega os envia.
    static func report(lx: Int, ly: Int, rx: Int, ry: Int) -> [UInt8] {
        var bytes = report(byte4: 0)
        for (offset, x, y) in [(6, lx, ly), (9, rx, ry)] {
            bytes[offset] = UInt8(x & 0xFF)
            bytes[offset + 1] = UInt8((x >> 8) & 0x0F) | UInt8((y & 0x0F) << 4)
            bytes[offset + 2] = UInt8(y >> 4)
        }
        return bytes
    }

    @Test func analogicosNoCentro() throws {
        let sticks = try #require(SwitchProReport.sticks(reportID: 0x30, bytes: Self.report(lx: 2048, ly: 2032, rx: 2048, ry: 2032)))
        #expect(sticks.left.x == 0)
        #expect(abs(sticks.left.y) < 0.01)
        #expect(sticks.right.x == 0)
        #expect(abs(sticks.right.y) < 0.01)
    }

    /// Faixa observada na sonda do PM-1: 0 a 4080 nos quatro eixos.
    @Test func analogicosNosExtremos() throws {
        let sticks = try #require(SwitchProReport.sticks(reportID: 0x30, bytes: Self.report(lx: 0, ly: 4080, rx: 4095, ry: 0)))
        #expect(sticks.left.x == -1)
        #expect(sticks.left.y > 0.99)
        #expect(sticks.right.x > 0.99)
        #expect(sticks.right.y == -1)
    }

    /// Eixos independentes: o nibble compartilhado do byte 7 (e do 10) não vaza de um eixo para o outro.
    @Test func eixosIndependentes() throws {
        let sticks = try #require(SwitchProReport.sticks(reportID: 0x30, bytes: Self.report(lx: 0x0FFF, ly: 0x0800, rx: 0x0800, ry: 0x0FFF)))
        #expect(sticks.left.x > 0.99)
        #expect(sticks.left.y == 0)
        #expect(sticks.right.x == 0)
        #expect(sticks.right.y > 0.99)
    }

    @Test func analogicosEmRelatorioCurtoOuDeOutroIdentificador() {
        #expect(SwitchProReport.sticks(reportID: 0x30, bytes: Self.report(length: 12, byte4: 0)) == nil)
        #expect(SwitchProReport.sticks(reportID: 0x21, bytes: Self.report(id: 0x21, byte4: 0)) == nil)
    }
}
