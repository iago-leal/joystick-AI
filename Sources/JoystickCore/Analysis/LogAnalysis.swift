import Foundation

public struct LogReadResult: Sendable {
    public var records: [[String: JSONValue]]
    public var malformedLines: Int
}

public struct ButtonObservation: Equatable, Sendable {
    public var down: Bool
    public var up: Bool

    public init(down: Bool, up: Bool) {
        self.down = down
        self.up = up
    }
}

public struct ButtonCoverage: Sendable {
    public var observed: [ButtonID: ButtonObservation]
    /// Botões com pressionar e soltar observados.
    public var covered: Int
}

public struct CycleSummary: Equatable, Sendable {
    public var completeCycles: Int
    public var unmatchedConnections: Int
    public var sessions: Int
}

/// Leitura do log JSON Lines e cálculos derivados de `diagnostic-log.md` §4.
public enum LogAnalysis {
    public static func read(contents: String) -> LogReadResult {
        var records: [[String: JSONValue]] = []
        var malformed = 0
        let decoder = JSONDecoder()
        contents.enumerateLines { line, _ in
            guard !line.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            if let value = try? decoder.decode(JSONValue.self, from: Data(line.utf8)), case .object(let object) = value {
                records.append(object)
            } else {
                malformed += 1
            }
        }
        return LogReadResult(records: records, malformedLines: malformed)
    }

    public static func buttonCoverage(_ records: [[String: JSONValue]]) -> ButtonCoverage {
        var observed = Dictionary(uniqueKeysWithValues: ButtonID.allCases.map { ($0, ButtonObservation(down: false, up: false)) })
        for record in records where record["event"]?.stringValue == "input.button" {
            guard record["synthetic"]?.boolValue != true,
                  let button = record["button"]?.stringValue.flatMap(ButtonID.init(rawValue:)) else { continue }
            switch record["phase"]?.stringValue {
            case "down": observed[button]!.down = true
            case "up": observed[button]!.up = true
            default: break
            }
        }
        return ButtonCoverage(observed: observed, covered: observed.values.filter { $0.down && $0.up }.count)
    }

    public static func cycles(_ records: [[String: JSONValue]]) -> CycleSummary {
        var open: Set<String> = []
        var complete = 0
        var sessions = 0
        for record in records {
            switch record["event"]?.stringValue {
            case "session.start":
                sessions += 1
            case "controller.connected":
                if let id = record["id"]?.stringValue { open.insert(id) }
            case "controller.disconnected":
                if let id = record["id"]?.stringValue, open.remove(id) != nil { complete += 1 }
            default:
                break
            }
        }
        return CycleSummary(completeCycles: complete, unmatchedConnections: open.count, sessions: sessions)
    }

    /// Amostras em nanossegundos: processamento das entradas reais e entrada ao movimento (D-19).
    public static func latencySamples(_ records: [[String: JSONValue]]) -> (processing: [UInt64], inputToMotion: [UInt64]) {
        var processing: [UInt64] = []
        var inputToMotion: [UInt64] = []
        for record in records {
            let event = record["event"]?.stringValue
            if event == "input.button" || event == "input.touch" {
                guard record["synthetic"]?.boolValue != true,
                      let arrival = record["t_arrival"]?.intValue, let delivered = record["t_delivered"]?.intValue,
                      delivered >= arrival else { continue }
                processing.append(UInt64(delivered - arrival))
            } else if event == "pointer.posted" {
                guard let source = record["source"]?.stringValue, source == "touch" || source == "stick_onset",
                      let arrival = record["t_arrival"]?.intValue, let posted = record["t_posted"]?.intValue,
                      posted >= arrival else { continue }
                inputToMotion.append(UInt64(posted - arrival))
            }
        }
        return (processing, inputToMotion)
    }
}
