import Foundation

/// Via pela qual um controle chegou ao leitor (D-25).
public enum ConnectionSource: String, Sendable {
    case enumeration, notification
}

/// Decide `atStartup` de `controller.connected` (RF-03, D-25, P-09).
public enum StartupAdoption {
    public static let windowNs: UInt64 = 2_000_000_000

    public static func isAtStartup(source: ConnectionSource, elapsedNs: UInt64) -> Bool {
        source == .enumeration || elapsedNs < windowNs
    }
}
