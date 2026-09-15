import Foundation

public enum ScrollUnit: String, Codable, Sendable {
    case pixel, line
}

/// Rolagem pelo analógico direito (D-13, RF-14).
///
/// Os valores seguem a convenção do `CGEvent`: `vertical` negativo rola em direção ao fim do
/// documento e `horizontal` negativo rola para a direita. Com precisão ativa (RN-08, só L1
/// pressionado), a velocidade é multiplicada por `precisionFactor`, como no analógico esquerdo.
public struct ScrollMapper: Sendable {
    public static let pixelsPerLine = 20.0

    public var unit: ScrollUnit
    public var settings: PointerSettings
    /// Fração de rolagem não emitida.
    public private(set) var remainder = (vertical: 0.0, horizontal: 0.0)

    public init(unit: ScrollUnit, settings: PointerSettings) {
        self.unit = unit
        self.settings = settings
    }

    /// Recebe o analógico já com zona morta aplicada.
    public mutating func step(x: Double, y: Double, dt: Double, precision: Bool = false) -> (vertical: Int32, horizontal: Int32) {
        let factor = precision ? settings.precisionFactor : 1.0
        let perSecond = settings.scrollSpeed * (unit == .pixel ? Self.pixelsPerLine : 1.0) * factor
        let vertical = y * perSecond * dt * (settings.invertScrollY ? -1 : 1)
        let horizontal = -x * perSecond * dt
        let totalV = remainder.vertical + vertical
        let totalH = remainder.horizontal + horizontal
        let wholeV = totalV.rounded(.towardZero)
        let wholeH = totalH.rounded(.towardZero)
        remainder = (totalV - wholeV, totalH - wholeH)
        return (Int32(clamping: Int(wholeV)), Int32(clamping: Int(wholeH)))
    }

    public mutating func reset() {
        remainder = (0, 0)
    }
}
