import Foundation

/// Deslocamento em pontos de tela.
public struct PointDelta: Equatable, Sendable {
    public var dx: Double
    public var dy: Double

    public init(dx: Double, dy: Double) {
        self.dx = dx
        self.dy = dy
    }

    public static let zero = PointDelta(dx: 0, dy: 0)

    public var isZero: Bool { dx == 0 && dy == 0 }

    public static func + (lhs: PointDelta, rhs: PointDelta) -> PointDelta {
        PointDelta(dx: lhs.dx + rhs.dx, dy: lhs.dy + rhs.dy)
    }

    public static func * (lhs: PointDelta, factor: Double) -> PointDelta {
        PointDelta(dx: lhs.dx * factor, dy: lhs.dy * factor)
    }
}

/// Cinemática do analógico esquerdo (D-12, RN-07, RF-13).
public enum StickKinematics {
    /// Velocidade em pt/s: `stickMaxSpeed · m^stickExponent` na direção de (x, y), com Y invertido para a tela.
    public static func velocity(x: Double, y: Double, maxSpeed: Double, exponent: Double) -> (vx: Double, vy: Double) {
        let h = hypot(x, y)
        guard h > 0 else { return (0, 0) }
        let m = min(1.0, h)
        let speed = maxSpeed * pow(m, exponent)
        return (speed * x / h, -speed * y / h)
    }

    public static func displacement(x: Double, y: Double, settings: PointerSettings, dt: Double, precision: Bool) -> PointDelta {
        let v = velocity(x: x, y: y, maxSpeed: settings.stickMaxSpeed, exponent: settings.stickExponent)
        let factor = precision ? settings.precisionFactor : 1.0
        return PointDelta(dx: v.vx * dt * factor, dy: v.vy * dt * factor)
    }
}

/// Emite deslocamentos em pontos inteiros e guarda o resto fracionário para a emissão seguinte.
public struct SubpixelAccumulator: Sendable {
    public private(set) var remainder = PointDelta.zero

    public init() {}

    public mutating func take(dx: Double, dy: Double) -> PointDelta {
        let totalX = remainder.dx + dx
        let totalY = remainder.dy + dy
        let wholeX = totalX.rounded(.towardZero)
        let wholeY = totalY.rounded(.towardZero)
        remainder = PointDelta(dx: totalX - wholeX, dy: totalY - wholeY)
        return PointDelta(dx: wholeX, dy: wholeY)
    }
}
