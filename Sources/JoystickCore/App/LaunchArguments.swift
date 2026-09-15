import Foundation

public enum LaunchArgumentError: Equatable, Sendable {
    case missingEnv
    case invalidEnv(String)
    case invalidScreen(String)
    case invalidSeed(String)
    case invalidScrollUnit(String)
    case invalidPaletteEnterDelay(String)
    case missingValue(String)

    public var message: String {
        switch self {
        case .missingEnv: "--targets exige --env mesa ou --env sofa"
        case .invalidEnv(let value): "--env inválido: \"\(value)\"; use mesa ou sofa, sem acento"
        case .invalidScreen(let value): "--screen inválido: \"\(value)\"; use um inteiro a partir de 1"
        case .invalidSeed(let value): "--seed inválido: \"\(value)\"; use um inteiro sem sinal"
        case .invalidScrollUnit(let value): "--scroll-unit inválido: \"\(value)\"; use pixel ou line"
        case .invalidPaletteEnterDelay(let value):
            "--palette-enter-delay-ms inválido: \"\(value)\"; use um inteiro de \(LaunchArguments.paletteEnterDelayRange.lowerBound) a \(LaunchArguments.paletteEnterDelayRange.upperBound)"
        case .missingValue(let flag): "\(flag) sem valor"
        }
    }

    /// Erros de argumentos da paleta, registrados em `palette.invalid_args` e não em `targets.invalid_args`.
    public var concernsPalette: Bool {
        switch self {
        case .invalidPaletteEnterDelay: true
        case .missingValue(let flag): flag == LaunchArguments.paletteEnterDelayFlag
        default: false
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
    /// Intervalo entre o texto de um item da paleta e o Enter; `nil` usa o padrão do app
    /// (`002-paleta-comandos/interfaces/launch-arguments.md`).
    public var paletteEnterDelayMs: Int?
    public var errors: [LaunchArgumentError] = []

    public static let paletteEnterDelayFlag = "--palette-enter-delay-ms"
    public static let paletteEnterDelayRange = 0...500

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
            case paletteEnterDelayFlag:
                if let raw = value(for: argument) {
                    if let delay = Int(raw), paletteEnterDelayRange.contains(delay) {
                        result.paletteEnterDelayMs = delay
                    } else {
                        result.errors.append(.invalidPaletteEnterDelay(raw))
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
