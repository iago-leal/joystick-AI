import Foundation

public enum ConfigIssue: Equatable, Sendable {
    case valueRejected(field: String, rejected: JSONValue, min: Double?, max: Double?, defaultValue: JSONValue)
    case invalidJSON(line: Int?, message: String)
    case unreadable(message: String)
}

/// Validação campo a campo da seção `pointer` (D-17, RF-26, `config-pointer.md`).
public enum PointerSettingsValidation {
    public static func validate(_ pointer: JSONValue) -> (settings: PointerSettings, issues: [ConfigIssue]) {
        var settings = PointerSettings()
        var issues: [ConfigIssue] = []
        guard case .object(let fields) = pointer else { return (settings, issues) }

        for field in PointerSettings.fieldNames {
            guard let raw = fields[field], raw != .null else { continue }
            let defaults = PointerSettings()

            if field == "invertScrollY" {
                if let flag = raw.boolValue {
                    settings.invertScrollY = flag
                } else {
                    issues.append(.valueRejected(field: field, rejected: raw, min: nil, max: nil, defaultValue: .bool(defaults.invertScrollY)))
                }
                continue
            }

            let range = PointerSettings.range(for: field)!
            let accepted: Double? = {
                guard let number = raw.doubleValue else { return nil }
                if range.integerOnly && number != number.rounded() { return nil }
                return (range.min...range.max).contains(number) ? number : nil
            }()
            guard let value = accepted else {
                issues.append(.valueRejected(field: field, rejected: raw, min: range.min, max: range.max, defaultValue: defaults.jsonValue(of: field)!))
                continue
            }
            switch field {
            case "touchpadSensitivity": settings.touchpadSensitivity = value
            case "stickMaxSpeed": settings.stickMaxSpeed = value
            case "stickExponent": settings.stickExponent = value
            case "deadzone": settings.deadzone = value
            case "scrollSpeed": settings.scrollSpeed = value
            case "precisionFactor": settings.precisionFactor = value
            case "doubleClickIntervalMs": settings.doubleClickIntervalMs = Int(value)
            default: break
            }
        }
        return (settings, issues)
    }
}
