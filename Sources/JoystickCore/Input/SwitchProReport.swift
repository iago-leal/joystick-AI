/// Leitura mínima dos relatórios HID de entrada do Ipega no modo Switch: o bit do Home e os dois analógicos
/// (`007-controle-ipega` D-04 e revisão de D-03 no PM-1).
///
/// O sistema não entrega o Home do Ipega à interface de controles (sondas de 2026-09-19, por cabo); ele chega no
/// relatório completo `0x30`, de 64 bytes, com o identificador no byte 0. Os botões ocupam os bytes 3 a 5, e o Home é
/// o bit `0x10` do byte 4. Os analógicos também não chegam por lá: o driver do sistema zera os eixos deste clone, que
/// os envia nos bytes 6 a 8 (esquerdo) e 9 a 11 (direito), com 12 bits por eixo, de 0 a 4095 e centro perto de 2048
/// (sonda do PM-1, 2026-09-19). O mínimo de 13 bytes cobre o cabeçalho, os botões e os dois analógicos.
public enum SwitchProReport {
    public static let fullReportID: UInt32 = 0x30
    static let minimumLength = 13
    static let stickCenter = 2048.0

    /// Posição de um analógico em −1…1, com y positivo para cima, a convenção do `GameController`.
    public struct Stick: Equatable, Sendable {
        public var x: Double
        public var y: Double

        public init(x: Double, y: Double) {
            self.x = x
            self.y = y
        }
    }

    public static func homeButton(reportID: UInt32, bytes: [UInt8]) -> Bool? {
        guard reportID == fullReportID, bytes.count >= minimumLength else { return nil }
        return bytes[4] & 0x10 != 0
    }

    /// Analógicos esquerdo e direito, sem zona morta; a normalização do app a aplica depois.
    public static func sticks(reportID: UInt32, bytes: [UInt8]) -> (left: Stick, right: Stick)? {
        guard reportID == fullReportID, bytes.count >= minimumLength else { return nil }
        return (stick(bytes, at: 6), stick(bytes, at: 9))
    }

    private static func stick(_ bytes: [UInt8], at offset: Int) -> Stick {
        let x = Int(bytes[offset]) | (Int(bytes[offset + 1]) & 0x0F) << 8
        let y = Int(bytes[offset + 1]) >> 4 | Int(bytes[offset + 2]) << 4
        return Stick(x: axis(x), y: axis(y))
    }

    private static func axis(_ raw: Int) -> Double {
        min(max((Double(raw) - stickCenter) / stickCenter, -1), 1)
    }
}
