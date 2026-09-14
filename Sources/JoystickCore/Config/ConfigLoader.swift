import Foundation

public enum ConfigStatus: String, Sendable {
    case defaults, loaded, invalidJSON
}

public struct ConfigLoadResult: Equatable, Sendable {
    public var settings: PointerSettings
    public var status: ConfigStatus
    /// `file_missing` ou `section_missing` quando os padrões vêm da ausência.
    public var reason: String?
    public var issues: [ConfigIssue]

    public init(settings: PointerSettings, status: ConfigStatus, reason: String?, issues: [ConfigIssue]) {
        self.settings = settings
        self.status = status
        self.reason = reason
        self.issues = issues
    }
}

/// Leitura única de `~/.config/joystick-ai/config.json` ao iniciar (D-17, RF-26). Nunca cria o arquivo.
public enum ConfigLoader {
    public static let maxBytes = 1 << 20

    public static var defaultURL: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".config/joystick-ai/config.json")
    }

    public static func load(from url: URL, fileManager: FileManager = .default) -> ConfigLoadResult {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return ConfigLoadResult(settings: PointerSettings(), status: .defaults, reason: "file_missing", issues: [])
        }
        guard !isDirectory.boolValue else {
            return unreadable("\(url.path) é um diretório, não um arquivo")
        }
        if let size = (try? fileManager.attributesOfItem(atPath: url.path))?[.size] as? NSNumber, size.intValue > maxBytes {
            return unreadable("\(url.path) tem \(size.intValue) bytes, acima do limite de \(maxBytes)")
        }
        do {
            let data = try Data(contentsOf: url)
            guard data.count <= maxBytes else {
                return unreadable("\(url.path) tem \(data.count) bytes, acima do limite de \(maxBytes)")
            }
            return parse(data: data)
        } catch {
            return unreadable(error.localizedDescription)
        }
    }

    public static func parse(data: Data) -> ConfigLoadResult {
        let root: JSONValue
        do {
            root = try JSONDecoder().decode(JSONValue.self, from: data)
        } catch {
            let (line, message) = describe(error, data: data)
            return ConfigLoadResult(settings: PointerSettings(), status: .invalidJSON, reason: nil, issues: [.invalidJSON(line: line, message: message)])
        }
        guard case .object(let fields) = root else {
            return ConfigLoadResult(settings: PointerSettings(), status: .invalidJSON, reason: nil,
                                    issues: [.invalidJSON(line: nil, message: "a raiz do arquivo não é um objeto JSON")])
        }
        guard let pointer = fields["pointer"], case .object = pointer else {
            return ConfigLoadResult(settings: PointerSettings(), status: .defaults, reason: "section_missing", issues: [])
        }
        let validated = PointerSettingsValidation.validate(pointer)
        return ConfigLoadResult(settings: validated.settings, status: .loaded, reason: nil, issues: validated.issues)
    }

    /// Linha pela descrição do Foundation ("around line N") ou, na falta dela, pelo deslocamento do erro (R-11).
    static func describe(_ error: Error, data: Data) -> (line: Int?, message: String) {
        var underlying: NSError?
        var message = String(describing: error)
        if case DecodingError.dataCorrupted(let context) = error {
            underlying = context.underlyingError as NSError?
            message = context.debugDescription
        }
        if let underlying {
            let description = underlying.userInfo[NSDebugDescriptionErrorKey] as? String ?? underlying.localizedDescription
            message = description
            if let line = line(fromDescription: description) {
                return (line, message)
            }
            if let offset = underlying.userInfo["NSJSONSerializationErrorIndex"] as? Int {
                return (line(atOffset: offset, in: data), message)
            }
        }
        return (line(fromDescription: message), message)
    }

    public static func line(fromDescription description: String) -> Int? {
        guard let range = description.range(of: #"line (\d+)"#, options: .regularExpression) else { return nil }
        return Int(description[range].dropFirst("line ".count))
    }

    public static func line(atOffset offset: Int, in data: Data) -> Int {
        let prefix = data.prefix(max(0, offset))
        return prefix.reduce(1) { $1 == 0x0A ? $0 + 1 : $0 }
    }

    private static func unreadable(_ message: String) -> ConfigLoadResult {
        ConfigLoadResult(settings: PointerSettings(), status: .defaults, reason: nil, issues: [.unreadable(message: message)])
    }
}
