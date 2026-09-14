import Foundation

/// Parâmetros do ponteiro, com os nomes e padrões de `pointer-control` §9 e as faixas de RF-26.
public struct PointerSettings: Codable, Equatable, Sendable {
    public var touchpadSensitivity: Double = 1.0
    public var stickMaxSpeed: Double = 1500
    public var stickExponent: Double = 2.0
    public var deadzone: Double = 0.12
    public var scrollSpeed: Double = 40
    public var invertScrollY: Bool = false
    public var precisionFactor: Double = 0.3
    public var doubleClickIntervalMs: Int = 400

    public init() {}

    public struct FieldRange: Equatable, Sendable {
        public let min: Double
        public let max: Double
        public let integerOnly: Bool
    }

    /// Campos na ordem da spec; `invertScrollY` é booleano e não tem faixa.
    public static let fieldNames = [
        "touchpadSensitivity", "stickMaxSpeed", "stickExponent", "deadzone",
        "scrollSpeed", "invertScrollY", "precisionFactor", "doubleClickIntervalMs",
    ]

    public static func range(for field: String) -> FieldRange? {
        switch field {
        case "touchpadSensitivity": FieldRange(min: 0.1, max: 5.0, integerOnly: false)
        case "stickMaxSpeed": FieldRange(min: 150, max: 7500, integerOnly: false)
        case "stickExponent": FieldRange(min: 0.5, max: 4.0, integerOnly: false)
        case "deadzone": FieldRange(min: 0.0, max: 0.5, integerOnly: false)
        case "scrollSpeed": FieldRange(min: 1, max: 1000, integerOnly: false)
        case "precisionFactor": FieldRange(min: 0.05, max: 1.0, integerOnly: false)
        case "doubleClickIntervalMs": FieldRange(min: 100, max: 2000, integerOnly: true)
        default: nil
        }
    }

    /// Valor de um campo como JSON, para o log e o relatório.
    public func jsonValue(of field: String) -> JSONValue? {
        switch field {
        case "touchpadSensitivity": .double(touchpadSensitivity)
        case "stickMaxSpeed": .double(stickMaxSpeed)
        case "stickExponent": .double(stickExponent)
        case "deadzone": .double(deadzone)
        case "scrollSpeed": .double(scrollSpeed)
        case "invertScrollY": .bool(invertScrollY)
        case "precisionFactor": .double(precisionFactor)
        case "doubleClickIntervalMs": .int(Int64(doubleClickIntervalMs))
        default: nil
        }
    }

    public var jsonValue: JSONValue {
        .object(Dictionary(uniqueKeysWithValues: Self.fieldNames.map { ($0, jsonValue(of: $0)!) }))
    }
}
