import Foundation

/// Rótulo do ambiente, sem acento; corresponde a "mesa" e "sofá" do requirements.
public enum TargetEnvironment: String, Codable, Sendable {
    case mesa, sofa
}

public enum AbortReason: String, Codable, Sendable {
    case user
    case screenRemoved = "screen_removed"
    case injectionSuspended = "injection_suspended"
}

/// Retângulo do alvo em pt, relativo à tela escolhida; nunca descreve o cursor (RN-12).
public struct RectPt: Codable, Equatable, Sendable {
    public var x: Int
    public var y: Int
    public var w: Int
    public var h: Int

    public init(x: Int, y: Int, w: Int, h: Int) {
        self.x = x
        self.y = y
        self.w = w
        self.h = h
    }
}

public struct ScreenDescriptor: Codable, Equatable, Sendable {
    public var name: String
    public var widthPx: Int
    public var heightPx: Int
    public var widthPt: Int
    public var heightPt: Int
    public var backingScale: Double

    public init(name: String, widthPx: Int, heightPx: Int, widthPt: Int, heightPt: Int, backingScale: Double) {
        self.name = name
        self.widthPx = widthPx
        self.heightPx = heightPx
        self.widthPt = widthPt
        self.heightPt = heightPt
        self.backingScale = backingScale
    }
}

public struct TargetAttempt: Codable, Equatable, Sendable {
    public var index: Int
    public var targetRectPt: RectPt
    public var hit: Bool
    public var timeToClickMs: Int
    public var l1Held: Bool

    public init(index: Int, targetRectPt: RectPt, hit: Bool, timeToClickMs: Int, l1Held: Bool) {
        self.index = index
        self.targetRectPt = targetRectPt
        self.hit = hit
        self.timeToClickMs = timeToClickMs
        self.l1Held = l1Held
    }
}

public struct TargetSummary: Codable, Equatable, Sendable {
    public var hits: Int
    public var total: Int
    public var hitRate: Double
    public var meanTimeMs: Int
    public var hitRateWithL1: Double?
    public var hitRateWithoutL1: Double?
}

/// Resultado de uma sequência da tela de alvos (`data-delta.md` §3.2, `target-run-result.md` §3).
public struct TargetRun: Codable, Equatable, Sendable {
    public static let attemptsPerRun = 20
    public static let targetSize = 16
    public static let marginPt = 40

    public var schemaVersion = 1
    public var startedAt: String
    public var environment: TargetEnvironment
    public var complete: Bool
    public var abortReason: AbortReason?
    public var seed: UInt64
    public var screen: ScreenDescriptor
    public var targetSizePt = TargetRun.targetSize
    public var settings: PointerSettings
    public var scrollUnit: ScrollUnit
    public var attempts: [TargetAttempt]
    public var summary: TargetSummary
    public var ignoredPhysicalClicks: Int

    public init(
        startedAt: String, environment: TargetEnvironment, complete: Bool, abortReason: AbortReason?, seed: UInt64,
        screen: ScreenDescriptor, settings: PointerSettings, scrollUnit: ScrollUnit, attempts: [TargetAttempt],
        ignoredPhysicalClicks: Int
    ) {
        self.startedAt = startedAt
        self.environment = environment
        self.complete = complete
        self.abortReason = complete ? nil : abortReason
        self.seed = seed
        self.screen = screen
        self.settings = settings
        self.scrollUnit = scrollUnit
        self.attempts = attempts
        self.summary = Self.summarize(attempts)
        self.ignoredPhysicalClicks = ignoredPhysicalClicks
    }

    public static func summarize(_ attempts: [TargetAttempt]) -> TargetSummary {
        func rate(_ group: [TargetAttempt]) -> Double? {
            group.isEmpty ? nil : Double(group.filter(\.hit).count) / Double(group.count)
        }
        let hits = attempts.filter(\.hit).count
        let meanTime = attempts.isEmpty ? 0 : Int((Double(attempts.map(\.timeToClickMs).reduce(0, +)) / Double(attempts.count)).rounded())
        return TargetSummary(
            hits: hits,
            total: attempts.count,
            hitRate: rate(attempts) ?? 0,
            meanTimeMs: meanTime,
            hitRateWithL1: rate(attempts.filter(\.l1Held)),
            hitRateWithoutL1: rate(attempts.filter { !$0.l1Held })
        )
    }

    /// Carimbo ISO 8601 local, com deslocamento de fuso.
    public static func timestamp(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = .current
        return formatter.string(from: date)
    }

    /// `<AAAAMMDD-HHMMSS>-<env>.json`, com sufixo `-2`, `-3`... em colisão.
    public static func fileName(startedAt: Date, environment: TargetEnvironment, exists: (String) -> Bool) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let stem = "\(formatter.string(from: startedAt))-\(environment.rawValue)"
        var name = "\(stem).json"
        var suffix = 2
        while exists(name) {
            name = "\(stem)-\(suffix).json"
            suffix += 1
        }
        return name
    }
}

/// Gerador determinístico (SplitMix64): a mesma semente reproduz as mesmas posições.
public struct SeededGenerator: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

public enum TargetLayout {
    public static func positions(
        seed: UInt64, widthPt: Int, heightPt: Int,
        count: Int = TargetRun.attemptsPerRun, size: Int = TargetRun.targetSize, margin: Int = TargetRun.marginPt
    ) -> [RectPt] {
        var generator = SeededGenerator(seed: seed)
        let maxX = max(margin, widthPt - margin - size)
        let maxY = max(margin, heightPt - margin - size)
        return (0..<count).map { _ in
            RectPt(x: Int.random(in: margin...maxX, using: &generator), y: Int.random(in: margin...maxY, using: &generator), w: size, h: size)
        }
    }
}
