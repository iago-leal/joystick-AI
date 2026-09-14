import Foundation

/// Normalização das leituras do controle (D-08, RN-02, RN-03).
public enum Normalization {
    public static let triggerThreshold = 0.5

    /// Zona morta por eixo: valores absolutos abaixo do limite valem 0,0; os demais são mantidos, limitados a ±1,0.
    public static func applyDeadzone(_ value: Double, deadzone: Double) -> Double {
        let clamped = min(1.0, max(-1.0, value))
        return abs(clamped) < deadzone ? 0.0 : clamped
    }

    public static func stick(x: Double, y: Double, deadzone: Double) -> (x: Double, y: Double) {
        (applyDeadzone(x, deadzone: deadzone), applyDeadzone(y, deadzone: deadzone))
    }

    /// Limiar fixo, sem histerese (R-07).
    public static func isTriggerPressed(_ value: Double) -> Bool {
        value >= triggerThreshold
    }

    /// Posição do toque limitada a [-1,0; 1,0] nos dois eixos.
    public static func touchPosition(x: Double, y: Double) -> (x: Double, y: Double) {
        (min(1.0, max(-1.0, x)), min(1.0, max(-1.0, y)))
    }
}

/// Converte a leitura analógica de L2 ou R2 em transições de botão.
public struct TriggerTracker: Sendable {
    public private(set) var pressed = false

    public init() {}

    /// Devolve o novo estado quando ele muda, e `nil` caso contrário.
    public mutating func update(_ value: Double) -> Bool? {
        let now = Normalization.isTriggerPressed(value)
        guard now != pressed else { return nil }
        pressed = now
        return now
    }
}
