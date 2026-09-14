import Foundation

/// Tabela do bloco (b) a partir dos resultados da tela de alvos (`target-run-result.md` §7).
public enum RunsReport {
    public static let outlierThresholdMs = 60_000

    public static func markdown(runs: [TargetRun], environment: TargetEnvironment?) -> String {
        let selected = runs
            .filter { $0.complete && (environment == nil || $0.environment == environment) }
            .sorted { $0.startedAt < $1.startedAt }
        guard !selected.isEmpty else {
            return "_(nenhuma sequência completa encontrada)_\n"
        }
        var lines = [
            "| Data | Ambiente | Resolução (px) | Escala | Parâmetros diferentes do padrão | Taxa de acerto | Com L1 | Sem L1 | Tempo médio (ms) | Discrepantes |",
            "|------|----------|----------------|--------|----------------------------------|----------------|--------|--------|------------------|--------------|",
        ]
        for run in selected {
            let outliers = run.attempts.filter { $0.timeToClickMs > outlierThresholdMs }.count
            lines.append([
                run.startedAt,
                run.environment.rawValue,
                "\(run.screen.widthPx) × \(run.screen.heightPx)",
                String(run.screen.backingScale),
                changedParameters(run),
                percent(run.summary.hitRate),
                percent(run.summary.hitRateWithL1),
                percent(run.summary.hitRateWithoutL1),
                String(run.summary.meanTimeMs),
                outliers == 0 ? "0" : "\(outliers) (>60 s)",
            ].joined(separator: " | ").wrappedInPipes)
        }
        return lines.joined(separator: "\n") + "\n"
    }

    static func changedParameters(_ run: TargetRun) -> String {
        let defaults = PointerSettings()
        var changes = PointerSettings.fieldNames.compactMap { field -> String? in
            guard let value = run.settings.jsonValue(of: field), value != defaults.jsonValue(of: field) else { return nil }
            return "\(field)=\(format(value))"
        }
        if run.scrollUnit != .pixel {
            changes.append("scrollUnit=\(run.scrollUnit.rawValue)")
        }
        return changes.isEmpty ? "padrão" : changes.joined(separator: ", ")
    }

    static func format(_ value: JSONValue) -> String {
        switch value {
        case .double(let d) where d == d.rounded() && abs(d) < 1e15: String(Int64(d))
        case .double(let d): String(d)
        case .int(let i): String(i)
        case .bool(let b): String(b)
        default: value.jsonString()
        }
    }

    static func percent(_ rate: Double?) -> String {
        guard let rate else { return "-" }
        return "\(Int((rate * 100).rounded()))%"
    }
}

private extension String {
    var wrappedInPipes: String { "| \(self) |" }
}
