import Foundation
import JoystickCore
import os

/// Log de diagnóstico em JSON Lines, um arquivo por sessão (D-18, `diagnostic-log.md`).
final class DiagnosticLog {
    static let subsystem = "dev.iagoleal.joystick-ai.poc"
    static let flushInterval: DispatchTimeInterval = .milliseconds(250)
    static let flushThresholdBytes = 256 * 1024
    static let debugLimitBytes = 50 * 1024 * 1024

    let debugEnabled: Bool
    private(set) var fileURL: URL?

    private let queue = DispatchQueue(label: "log", qos: .utility)
    private var handle: FileHandle?
    private var buffer = Data()
    private var bytesWritten = 0
    private var debugSuspended = false
    private var timer: DispatchSourceTimer?
    private let wallFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter
    }()

    init(debug: Bool, directory: URL = DiagnosticLog.defaultDirectory, now: Date = Date()) {
        self.debugEnabled = debug
        open(in: directory, now: now)
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + Self.flushInterval, repeating: Self.flushInterval)
        timer.setEventHandler { [weak self] in self?.flushLocked() }
        timer.resume()
        self.timer = timer
    }

    static var defaultDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/joystick-ai", isDirectory: true)
    }

    /// Envia um evento à fila `log`. `ts_ns` é tomado aqui, no instante lógico do evento.
    func log(_ event: LogEvent) {
        if event.level == .debug && !debugEnabled { return }
        let tsNs = MonotonicClock.nowNs()
        let date = Date()
        queue.async { [weak self] in
            guard let self else { return }
            if event.level == .debug && self.debugSuspended { return }
            let line = LogLineFormatter.line(event, tsNs: tsNs, wall: self.wallFormatter.string(from: date))
            self.append(line)
        }
    }

    /// Descarrega o *buffer* de forma síncrona (usado em `app.terminating`).
    func flushSync() {
        queue.sync { flushLocked() }
    }

    // MARK: fila `log`

    private func open(in directory: URL, now: Date) {
        let nameFormatter = DateFormatter()
        nameFormatter.locale = Locale(identifier: "en_US_POSIX")
        nameFormatter.dateFormat = "yyyyMMdd-HHmmss"
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let stem = "poc-\(nameFormatter.string(from: now))"
            var url = directory.appendingPathComponent("\(stem).jsonl")
            var suffix = 2
            while FileManager.default.fileExists(atPath: url.path) {
                url = directory.appendingPathComponent("\(stem)-\(suffix).jsonl")
                suffix += 1
            }
            guard FileManager.default.createFile(atPath: url.path, contents: nil) else {
                throw CocoaError(.fileWriteUnknown)
            }
            handle = try FileHandle(forWritingTo: url)
            fileURL = url
        } catch {
            Logger(subsystem: Self.subsystem, category: "log")
                .error("log de diagnóstico indisponível em \(directory.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }

    private func append(_ line: String) {
        guard handle != nil else { return }
        buffer.append(Data(line.utf8))
        if buffer.count >= Self.flushThresholdBytes { flushLocked() }
    }

    private func flushLocked() {
        guard let handle, !buffer.isEmpty else { return }
        do {
            try handle.write(contentsOf: buffer)
            bytesWritten += buffer.count
        } catch {
            // Falha no meio da sessão: descarta o pendente e tenta de novo no próximo flush.
        }
        buffer.removeAll(keepingCapacity: true)
        if !debugSuspended && bytesWritten > Self.debugLimitBytes {
            debugSuspended = true
            let event = LogEventCatalog.logDebugSuspended(sizeBytes: bytesWritten)
            buffer.append(Data(LogLineFormatter.line(event, tsNs: MonotonicClock.nowNs(), wall: wallFormatter.string(from: Date())).utf8))
        }
    }
}
