import Foundation
import JoystickCore

/// Gravação de `shortcuts` e `palette` no arquivo de configuração (`003-editor-atalhos` D-17, `interfaces/config-file.md` §4).
///
/// Resolve *link* simbólico, lê a raiz atual, funde por `ConfigDocument.merge` e grava por troca atômica no destino,
/// de modo que uma gravação interrompida não trunque o arquivo e o *link* dos dotfiles continue sendo *link*.
struct ConfigWriter {
    enum Outcome: Equatable {
        /// `bytes` são os gravados; `created` indica arquivo novo e `backup`, cópia do conteúdo anterior.
        case written(bytes: Data, created: Bool, backup: Bool)
        /// O arquivo atual tem erro de sintaxe: gravar exige confirmar a cópia para `config.json.bak`.
        case needsBackupConfirmation(line: Int?)
        /// Nada foi gravado; `message` traz o caminho e o erro do sistema.
        case failed(message: String)
    }

    static let backupSuffix = ".bak"
    static let maxLinkDepth = 16

    let url: URL
    var fileManager: FileManager = .default

    func write(_ document: ShortcutsDocument, confirmBackup: Bool) -> Outcome {
        let destination = Self.resolveLinks(url, fileManager: fileManager)
        var existing: JSONValue?
        var created = true
        var backup = false

        if fileManager.fileExists(atPath: destination.path) {
            created = false
            let data: Data
            do {
                data = try Data(contentsOf: destination)
            } catch {
                return .failed(message: Self.message(destination, error))
            }
            switch ConfigLoader.parse(data: data).shortcutIssues.first {
            case let issue? where issue.rule == .syntax || (issue.rule == .wrongType && issue.path.isEmpty):
                guard confirmBackup else { return .needsBackupConfirmation(line: issue.line) }
                let backupURL = destination.deletingLastPathComponent().appendingPathComponent(destination.lastPathComponent + Self.backupSuffix)
                do {
                    try data.write(to: backupURL, options: .atomic)
                } catch {
                    return .failed(message: Self.message(backupURL, error))
                }
                backup = true
            default:
                existing = try? JSONDecoder().decode(JSONValue.self, from: data)
            }
        }

        let bytes = ConfigDocument.merge(existing: existing, document: document)
        do {
            try fileManager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
            try bytes.write(to: destination, options: .atomic)
        } catch {
            return .failed(message: Self.message(destination, error))
        }
        return .written(bytes: bytes, created: created, backup: backup)
    }

    /// Segue *links* simbólicos até o destino final, inclusive um destino ainda inexistente.
    static func resolveLinks(_ url: URL, fileManager: FileManager = .default) -> URL {
        var current = url.standardizedFileURL
        for _ in 0..<maxLinkDepth {
            guard let target = try? fileManager.destinationOfSymbolicLink(atPath: current.path) else { break }
            current = URL(fileURLWithPath: target, relativeTo: current.deletingLastPathComponent()).standardizedFileURL
        }
        return current
    }

    /// Caminho e erro do sistema, sem conteúdo do arquivo (RN-14).
    static func message(_ url: URL, _ error: Error) -> String {
        let nsError = error as NSError
        let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? NSError
        return "\(url.path): \(underlying?.localizedDescription ?? nsError.localizedDescription)"
    }
}
