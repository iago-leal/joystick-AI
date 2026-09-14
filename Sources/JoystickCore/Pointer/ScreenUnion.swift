import Foundation

/// União dos retângulos das telas ativas, em coordenadas globais de origem superior esquerda (D-14, RN-10).
public struct ScreenUnion: Equatable, Sendable {
    public var rects: [ScreenRect]

    public init(rects: [ScreenRect]) {
        self.rects = rects
    }

    public func contains(_ p: ScreenPoint) -> Bool {
        rects.contains { p.x >= $0.minX && p.x < $0.maxX && p.y >= $0.minY && p.y < $0.maxY }
    }

    /// Devolve `p` se contido em algum retângulo; senão, o ponto mais próximo do retângulo mais próximo.
    public func clamp(_ p: ScreenPoint) -> ScreenPoint {
        guard !rects.isEmpty, !contains(p) else { return p }
        var best = p
        var bestDistance = Double.infinity
        for rect in rects {
            let candidate = ScreenPoint(
                x: min(max(p.x, rect.minX), max(rect.minX, rect.maxX - 1)),
                y: min(max(p.y, rect.minY), max(rect.minY, rect.maxY - 1)))
            let distance = (candidate.x - p.x) * (candidate.x - p.x) + (candidate.y - p.y) * (candidate.y - p.y)
            if distance < bestDistance {
                bestDistance = distance
                best = candidate
            }
        }
        return best
    }
}
