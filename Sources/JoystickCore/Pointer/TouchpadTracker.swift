import Foundation

/// Movimento relativo pelo touchpad, só pelo primeiro dedo (D-05, D-12, RN-05).
///
/// Não depende da origem da fase do toque: `touchState` do framework ou `ZeroTransitionPhaseInference`.
public struct TouchpadTracker: Sendable {
    /// Pontos de tela por unidade normalizada; a calibração age por `touchpadSensitivity`.
    public static let pointsPerUnit = 400.0

    private var contacts: Set<Int> = []
    private var primary: Int?
    private var baseline: (x: Double, y: Double)?

    public init() {}

    /// Devolve o deslocamento em pt, ou `nil` quando a amostra não move o cursor.
    public mutating func update(finger: Int, phase: TouchPhase, x: Double, y: Double, sensitivity: Double) -> PointDelta? {
        let position = Normalization.touchPosition(x: x, y: y)

        if phase == .ended {
            contacts.remove(finger)
            if primary == finger {
                // Um dedo que continua em contato assume, a partir da próxima amostra, sem salto.
                primary = contacts.min()
                baseline = nil
            }
            return nil
        }

        contacts.insert(finger)
        if primary == nil {
            primary = finger
            baseline = nil
        }
        guard primary == finger else { return nil }

        guard phase == .moved, let last = baseline else {
            // Primeira amostra de cada toque: só fixa a referência (pousar o dedo não move).
            baseline = position
            return nil
        }
        baseline = position
        guard !Self.isAxisSplit(from: last, to: position) else { return nil }
        let scale = Self.pointsPerUnit * sensitivity
        // O eixo Y do touchpad cresce para cima; o da tela, para baixo.
        return PointDelta(dx: (position.x - last.x) * scale, dy: -(position.y - last.y) * scale)
    }
}

extension TouchpadTracker {
    /// O GameController atualiza um eixo do touchpad de cada vez e chama o *handler* a cada eixo: ao pousar o dedo
    /// chega (x, 0) antes de (x, y), e ao retirá-lo chega (0, y) antes de (0, 0) (achado da Fase 2). Uma amostra em
    /// que um eixo fica igual e o outro entra ou sai do zero exato é esse estado intermediário, não movimento; sem o
    /// descarte, cada toque terminaria com um salto horizontal que desfaz o deslize.
    static func isAxisSplit(from last: (x: Double, y: Double), to next: (x: Double, y: Double)) -> Bool {
        (next.x == last.x && (next.y == 0) != (last.y == 0)) || (next.y == last.y && (next.x == 0) != (last.x == 0))
    }
}

/// Infere início e fim do toque pela transição de e para (0, 0) (D-05, P-02).
public struct ZeroTransitionPhaseInference: Sendable {
    public private(set) var touching = false

    public init() {}

    public mutating func phase(x: Double, y: Double) -> TouchPhase? {
        let atZero = x == 0 && y == 0
        switch (touching, atZero) {
        case (false, true): return nil
        case (false, false):
            touching = true
            return .began
        case (true, false): return .moved
        case (true, true):
            touching = false
            return .ended
        }
    }
}
