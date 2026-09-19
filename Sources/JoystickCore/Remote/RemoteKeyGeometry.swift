import Foundation

/// Papel de uma tecla da página no Mac (`008-iphone-teclado-remoto` D-08, D-17).
public enum RemoteKeyKind: Equatable, Hashable, Sendable {
    case regular
    case modifier(KeyModifier)
    case capsLock
}

/// Tecla da geometria: código virtual (`kVK_*`) da posição física e o seu papel.
public struct RemoteKey: Equatable, Hashable, Sendable {
    public let code: UInt16
    public let kind: RemoteKeyKind

    public init(_ code: UInt16, _ kind: RemoteKeyKind = .regular) {
        self.code = code
        self.kind = kind
    }
}

/// Disposição física do teclado do Mac: ANSI (americano) ou ISO (europeu, com a tecla § e o Return alto).
public enum PhysicalLayout: String, Codable, CaseIterable, Sendable {
    case ansi, iso
}

/// Teclas que a página desenha e o canal aceita, em linhas (RF-04, D-16).
///
/// Os modificadores direitos (54, 60, 61, 62) resolvem para o mesmo `KeyModifier` dos esquerdos, de modo que a
/// contagem do `KeyboardInjector` os soma (D-09).
public struct RemoteKeyGeometry: Equatable, Sendable {
    public let physical: PhysicalLayout
    public let rows: [[RemoteKey]]
    private let byCode: [UInt16: RemoteKey]

    public init(physical: PhysicalLayout, rows: [[RemoteKey]]) {
        self.physical = physical
        self.rows = rows
        byCode = Dictionary(rows.joined().map { ($0.code, $0) }, uniquingKeysWith: { first, _ in first })
    }

    public func contains(code: UInt16) -> Bool { byCode[code] != nil }

    public func key(code: UInt16) -> RemoteKey? { byCode[code] }

    public var codes: [UInt16] { rows.flatMap { $0.map(\.code) } }

    public static let capsLockCode: UInt16 = 57

    /// Geometria do teclado do Mac. `capsLock` segue a sonda P-04 (D-17): reprovada, a tecla sai.
    public static func standard(_ physical: PhysicalLayout, capsLock: Bool = true) -> RemoteKeyGeometry {
        let functionRow: [RemoteKey] = [53, 122, 120, 99, 118, 96, 97, 98, 100, 101, 109, 103, 111].map { RemoteKey($0) }
        let digits: [UInt16] = [18, 19, 20, 21, 23, 22, 26, 28, 25, 29, 27, 24]
        let top: [UInt16] = [12, 13, 14, 15, 17, 16, 32, 34, 31, 35, 33, 30]
        let home: [UInt16] = [0, 1, 2, 3, 5, 4, 38, 40, 37, 41, 39]
        let bottom: [UInt16] = [6, 7, 8, 9, 11, 45, 46, 43, 47, 44]
        let capsKey: [RemoteKey] = capsLock ? [RemoteKey(capsLockCode, .capsLock)] : []
        let leftShift = RemoteKey(56, .modifier(.shift))
        let rightShift = RemoteKey(60, .modifier(.shift))
        let bottomRow: [RemoteKey] = [
            RemoteKey(59, .modifier(.control)), RemoteKey(58, .modifier(.option)), RemoteKey(55, .modifier(.command)),
            RemoteKey(KeyChord.space),
            RemoteKey(54, .modifier(.command)), RemoteKey(61, .modifier(.option)), RemoteKey(62, .modifier(.control)),
            RemoteKey(KeyChord.leftArrow), RemoteKey(KeyChord.downArrow), RemoteKey(KeyChord.upArrow), RemoteKey(KeyChord.rightArrow),
        ]
        let rows: [[RemoteKey]]
        switch physical {
        case .ansi:
            rows = [
                functionRow,
                [RemoteKey(KeyChord.grave)] + digits.map { RemoteKey($0) } + [RemoteKey(KeyChord.delete)],
                [RemoteKey(KeyChord.tab)] + top.map { RemoteKey($0) } + [RemoteKey(42)],
                capsKey + home.map { RemoteKey($0) } + [RemoteKey(KeyChord.returnKey)],
                [leftShift] + bottom.map { RemoteKey($0) } + [rightShift],
                bottomRow,
            ]
        case .iso:
            // ISO: § (10) no lugar do `, que desce para junto do ⇧ esquerdo; \ (42) passa para antes do Return.
            rows = [
                functionRow,
                [RemoteKey(10)] + digits.map { RemoteKey($0) } + [RemoteKey(KeyChord.delete)],
                [RemoteKey(KeyChord.tab)] + top.map { RemoteKey($0) },
                capsKey + home.map { RemoteKey($0) } + [RemoteKey(42), RemoteKey(KeyChord.returnKey)],
                [leftShift, RemoteKey(KeyChord.grave)] + bottom.map { RemoteKey($0) } + [rightShift],
                bottomRow,
            ]
        }
        return RemoteKeyGeometry(physical: physical, rows: rows)
    }
}
