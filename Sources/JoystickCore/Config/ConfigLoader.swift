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

    /// Mapeamento e paleta lidos, ou os padrões quando ausentes ou recusados (`003-editor-atalhos` D-08, RN-08).
    public var shortcuts: ShortcutsDocument
    public var shortcutsSource: ShortcutsSource
    /// Motivo dos padrões por ausência: arquivo inexistente ou nenhuma das duas seções.
    public var shortcutsReason: ShortcutsDefaultReason?
    /// Problemas que recusaram `shortcuts` e `palette`, com linha quando conhecida; vazio numa leitura aceita.
    public var shortcutIssues: [ShortcutIssue]
    /// *Bytes* lidos, para comparar releituras (`003-editor-atalhos` D-16); `nil` sem arquivo legível.
    public var data: Data?

    public init(settings: PointerSettings, status: ConfigStatus, reason: String?, issues: [ConfigIssue],
                shortcuts: ShortcutsDocument = ShortcutDefaults.document, shortcutsSource: ShortcutsSource = .defaults,
                shortcutsReason: ShortcutsDefaultReason? = nil, shortcutIssues: [ShortcutIssue] = [], data: Data? = nil) {
        self.settings = settings
        self.status = status
        self.reason = reason
        self.issues = issues
        self.shortcuts = shortcuts
        self.shortcutsSource = shortcutsSource
        self.shortcutsReason = shortcutsReason
        self.shortcutIssues = shortcutIssues
        self.data = data
    }
}

/// Leitura de `~/.config/joystick-ai/config.json` (D-17, RF-26). Nunca cria o arquivo.
///
/// A raiz é decodificada uma vez e entregue a `pointer` e às seções de atalhos (`003-editor-atalhos` D-08); o
/// resultado de `pointer` e os eventos `config.*` não mudam.
public enum ConfigLoader {
    public static let maxBytes = 1 << 20

    public static var defaultURL: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".config/joystick-ai/config.json")
    }

    public static func load(from url: URL, fileManager: FileManager = .default) -> ConfigLoadResult {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return ConfigLoadResult(settings: PointerSettings(), status: .defaults, reason: "file_missing", issues: [],
                                    shortcutsReason: .fileMissing)
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
            return ConfigLoadResult(settings: PointerSettings(), status: .invalidJSON, reason: nil, issues: [.invalidJSON(line: line, message: message)],
                                    shortcutIssues: [ShortcutIssue(path: "", rule: .syntax, line: line)], data: data)
        }
        guard case .object(let fields) = root else {
            return ConfigLoadResult(settings: PointerSettings(), status: .invalidJSON, reason: nil,
                                    issues: [.invalidJSON(line: nil, message: "a raiz do arquivo não é um objeto JSON")],
                                    shortcutIssues: [ShortcutIssue(path: "", rule: .wrongType, line: 1)], data: data)
        }

        var result: ConfigLoadResult
        if let pointer = fields["pointer"], case .object = pointer {
            let validated = PointerSettingsValidation.validate(pointer)
            result = ConfigLoadResult(settings: validated.settings, status: .loaded, reason: nil, issues: validated.issues)
        } else {
            result = ConfigLoadResult(settings: PointerSettings(), status: .defaults, reason: "section_missing", issues: [])
        }
        result.data = data

        switch ShortcutConfigValidation.decode(root: root) {
        case .success(let document):
            let sections = ShortcutConfigValidation.sections(in: root)
            let present = sections.shortcuts || sections.palette
            result.shortcuts = document
            result.shortcutsSource = present ? .file : .defaults
            result.shortcutsReason = present ? nil : .sectionMissing
        case .failure(let failure):
            result.shortcutIssues = failure.issues.map { issue in
                var located = issue
                located.line = ConfigLineLocator.nearestLine(of: issue.path, in: data)
                return located
            }
        }
        return result
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
        ConfigLoadResult(settings: PointerSettings(), status: .defaults, reason: nil, issues: [.unreadable(message: message)],
                         shortcutIssues: [ShortcutIssue(path: "", rule: .unreadable)])
    }
}
