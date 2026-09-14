import Foundation

/// Nível de um registro do log de diagnóstico (`diagnostic-log.md` §2).
public enum LogLevel: String, Sendable, Comparable {
    case debug, info, warn, error

    private var rank: Int {
        switch self {
        case .debug: 0
        case .info: 1
        case .warn: 2
        case .error: 3
        }
    }

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool { lhs.rank < rhs.rank }
}

/// Um evento do log: nome, nível e campos específicos.
public struct LogEvent: Equatable, Sendable {
    public let name: String
    public let level: LogLevel
    public let fields: [String: JSONValue]

    public init(_ name: String, level: LogLevel, fields: [String: JSONValue] = [:]) {
        self.name = name
        self.level = level
        self.fields = fields
    }
}

/// Formata uma linha JSON Lines com `ts_ns`, `wall`, `level` e `event` à frente dos demais campos.
public enum LogLineFormatter {
    public static func line(_ event: LogEvent, tsNs: UInt64, wall: String) -> String {
        var out = "{\"ts_ns\":\(tsNs),\"wall\":"
        JSONValue.writeString(wall, to: &out)
        out += ",\"level\":\"\(event.level.rawValue)\",\"event\":"
        JSONValue.writeString(event.name, to: &out)
        for key in event.fields.keys.sorted() where !["ts_ns", "wall", "level", "event"].contains(key) {
            out += ","
            JSONValue.writeString(key, to: &out)
            out += ":"
            event.fields[key]!.write(to: &out)
        }
        out += "}\n"
        return out
    }
}
