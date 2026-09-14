import Foundation

public enum LaunchArgumentError: Equatable, Sendable {
    case missingEnv
    case invalidEnv(String)
    case invalidScreen(String)
    case invalidSeed(String)
    case invalidScrollUnit(String)
    case missingValue(String)

    public var message: String {
        switch self {
        case .missingEnv: "--targets exige --env mesa ou --env sofa"
        case .invalidEnv(let value): "--env inválido: \"\(value)\"; use mesa ou sofa, sem acento"
        case .invalidScreen(let value): "--screen inválido: \"\(value)\"; use um inteiro a partir de 1"
        case .invalidSeed(let value): "--seed inválido: \"\(value)\"; use um inteiro sem sinal"
        case .invalidScrollUnit(let value): "--scroll-unit inválido: \"\(value)\"; use pixel ou line"
        case .missingValue(let flag): "\(flag) sem valor"
        }
    }
}

/// Argumentos de abertura por `open --args` (D-13, D-20, `target-run-result.md` §1).
public struct LaunchArguments: Equatable, Sendable {
    public var targets = false
    public var env: TargetEnvironment?
    public var screen = 1
    public var seed: UInt64?
    public var debug = false
    public var scrollUnit = ScrollUnit.pixel
    public var errors: [LaunchArgumentError] = []

    public init() {}

    /// A tela de alvos só abre com `--targets` e `--env` válido.
    public var targetsEnabled: Bool { targets && env != nil }

    public static func parse(_ arguments: [String]) -> LaunchArguments {
        var result = LaunchArguments()
        var envGiven = false
        var index = 0

        func value(for flag: String) -> String? {
            guard index + 1 < arguments.count else {
                result.errors.append(.missingValue(flag))
                return nil
            }
            index += 1
            return arguments[index]
        }

        while index < arguments.count {
            let argument = arguments[index]
            switch argument {
            case "--targets":
                result.targets = true
            case "--debug":
                result.debug = true
            case "--env":
                envGiven = true
                if let raw = value(for: argument) {
                    if let env = TargetEnvironment(rawValue: raw) {
                        result.env = env
                    } else {
                        result.errors.append(.invalidEnv(raw))
                    }
                }
            case "--screen":
                if let raw = value(for: argument) {
                    if let screen = Int(raw), screen >= 1 {
                        result.screen = screen
                    } else {
                        result.errors.append(.invalidScreen(raw))
                    }
                }
            case "--seed":
                if let raw = value(for: argument) {
                    if let seed = UInt64(raw) {
                        result.seed = seed
                    } else {
                        result.errors.append(.invalidSeed(raw))
                    }
                }
            case "--scroll-unit":
                if let raw = value(for: argument) {
                    if let unit = ScrollUnit(rawValue: raw) {
                        result.scrollUnit = unit
                    } else {
                        result.errors.append(.invalidScrollUnit(raw))
                    }
                }
            default:
                break
            }
            index += 1
        }

        if result.targets && !envGiven {
            result.errors.append(.missingEnv)
        }
        return result
    }
}
