import Foundation
import JoystickCore

/// Grava o resultado de uma sequência da tela de alvos (`target-run-result.md` §3 a §5).
final class TargetRunWriter {
    private let log: DiagnosticLog
    private let directory: URL

    init(log: DiagnosticLog, directory: URL = TargetRunWriter.defaultDirectory) {
        self.log = log
        self.directory = directory
    }

    static var defaultDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/joystick-ai/target-runs", isDirectory: true)
    }

    /// Grava um arquivo novo, nunca sobrescreve; em falha, registra o JSON completo no log para recuperação manual.
    @discardableResult
    func write(_ run: TargetRun, startedAt: Date) -> URL? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        let payload: Data
        do {
            payload = try encoder.encode(run)
        } catch {
            log.log(LogEventCatalog.targetsWriteFailed(message: "falha ao codificar: \(error.localizedDescription)", payload: ""))
            return nil
        }

        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let name = TargetRun.fileName(startedAt: startedAt, environment: run.environment) { candidate in
                FileManager.default.fileExists(atPath: self.directory.appendingPathComponent(candidate).path)
            }
            let url = directory.appendingPathComponent(name)
            try payload.write(to: url, options: .withoutOverwriting)
            log.log(LogEventCatalog.targetsFinished(
                environment: run.environment, seed: run.seed, complete: run.complete, abortReason: run.abortReason, file: url.path))
            return url
        } catch {
            let compact = (try? JSONEncoder().encode(run)).map { String(decoding: $0, as: UTF8.self) } ?? ""
            log.log(LogEventCatalog.targetsWriteFailed(message: error.localizedDescription, payload: compact))
            return nil
        }
    }
}
