import Foundation
import Testing
@testable import JoystickCore

@Suite struct ConfigLoaderTests {
    func tempDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("joystick-config-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    @Test func arquivoAusenteUsaPadroesSemCriarArquivo() throws {
        let url = try tempDir().appendingPathComponent("config.json")
        let result = ConfigLoader.load(from: url)
        #expect(result.status == .defaults)
        #expect(result.reason == "file_missing")
        #expect(result.settings == PointerSettings())
        #expect(!FileManager.default.fileExists(atPath: url.path))
    }

    @Test func semSecaoPointer() {
        let result = ConfigLoader.parse(data: Data(#"{"version": 1, "mappings": []}"#.utf8))
        #expect(result.status == .defaults)
        #expect(result.reason == "section_missing")
        #expect(result.issues.isEmpty)
    }

    @Test func jsonInvalidoComLinha() {
        let text = "{\n  \"pointer\": {\n    \"stickMaxSpeed\": 1800\n    \"scrollSpeed\": 100\n  }\n}\n"
        let result = ConfigLoader.parse(data: Data(text.utf8))
        #expect(result.status == .invalidJSON)
        #expect(result.settings == PointerSettings())
        guard case .invalidJSON(let line, let message)? = result.issues.first else {
            Issue.record("esperava invalidJSON")
            return
        }
        #expect(line == 4)
        #expect(!message.isEmpty)
    }

    @Test func linhaPeloDeslocamentoQuandoADescricaoNaoTraz() {
        let data = Data("{\n\n  x".utf8)
        #expect(ConfigLoader.line(atOffset: 4, in: data) == 3)
        #expect(ConfigLoader.line(fromDescription: "Unexpected character around line 12, column 3.") == 12)
        #expect(ConfigLoader.line(fromDescription: "sem linha") == nil)
    }

    @Test func diretorioNoLugarDoArquivo() throws {
        let dir = try tempDir()
        let result = ConfigLoader.load(from: dir)
        #expect(result.status == .defaults)
        guard case .unreadable? = result.issues.first else {
            Issue.record("esperava unreadable")
            return
        }
    }

    @Test func arquivoAcimaDeUmMiB() throws {
        let url = try tempDir().appendingPathComponent("config.json")
        try Data(repeating: 0x20, count: ConfigLoader.maxBytes + 1).write(to: url)
        let result = ConfigLoader.load(from: url)
        #expect(result.status == .defaults)
        guard case .unreadable? = result.issues.first else {
            Issue.record("esperava unreadable")
            return
        }
    }

    @Test func chavesExtrasIgnoradasEValoresLidos() throws {
        let url = try tempDir().appendingPathComponent("config.json")
        let text = #"{"version": 1, "dictation": {"x": 1}, "pointer": {"stickMaxSpeed": 1800, "futuro": true}}"#
        try Data(text.utf8).write(to: url)
        let result = ConfigLoader.load(from: url)
        #expect(result.status == .loaded)
        #expect(result.settings.stickMaxSpeed == 1800)
        #expect(result.issues.isEmpty)
    }

    @Test func raizQueNaoEhObjetoEhInvalida() {
        let result = ConfigLoader.parse(data: Data("[1, 2]".utf8))
        #expect(result.status == .invalidJSON)
        #expect(result.shortcuts == ShortcutDefaults.document)
        #expect(result.shortcutIssues.map(\.rule) == [.wrongType])
    }

    // MARK: atalhos e paleta (`003-editor-atalhos` D-08)

    @Test func arquivoAusenteComPadroesDeAtalhos() throws {
        let result = ConfigLoader.load(from: try tempDir().appendingPathComponent("config.json"))
        #expect(result.shortcuts == ShortcutDefaults.document)
        #expect(result.shortcutsSource == .defaults)
        #expect(result.shortcutsReason == .fileMissing)
        #expect(result.shortcutIssues.isEmpty)
        #expect(result.data == nil)
    }

    @Test func soPointerComPadroesDeAtalhos() {
        let data = Data(#"{"pointer": {"stickMaxSpeed": 1800}}"#.utf8)
        let result = ConfigLoader.parse(data: data)
        #expect(result.settings.stickMaxSpeed == 1800)
        #expect(result.shortcuts == ShortcutDefaults.document)
        #expect(result.shortcutsSource == .defaults)
        #expect(result.shortcutsReason == .sectionMissing)
        #expect(result.data == data)
    }

    @Test func secoesDeAtalhosLidas() {
        let text = #"{"palette": {"version": 1, "items": [{"text": "/reversa-docs", "pressEnter": true}]}}"#
        let result = ConfigLoader.parse(data: Data(text.utf8))
        #expect(result.shortcutsSource == .file)
        #expect(result.shortcutsReason == nil)
        #expect(result.shortcuts.palette == [PaletteItem("/reversa-docs", pressEnter: true)])
        #expect(result.shortcuts.shortcuts == ShortcutDefaults.config)
        #expect(result.status == .defaults)
        #expect(result.reason == "section_missing")
    }

    /// RN-08 e RF-04: `shortcuts` inválido mantém `pointer` lido, usa os padrões e cita a linha do problema.
    @Test func atalhosInvalidosMantemPointerLido() {
        let text = """
        {
          "pointer": { "stickMaxSpeed": 1800 },
          "shortcuts": {
            "version": 1,
            "layers": {
              "base": {
                "r1": { "type": "chord", "key": "z" }
              }
            }
          }
        }
        """
        let result = ConfigLoader.parse(data: Data(text.utf8))
        #expect(result.status == .loaded)
        #expect(result.settings.stickMaxSpeed == 1800)
        #expect(result.issues.isEmpty)
        #expect(result.shortcuts == ShortcutDefaults.document)
        #expect(result.shortcutsSource == .defaults)
        #expect(result.shortcutIssues == [ShortcutIssue(path: "shortcuts.layers.base.r1", rule: .pointerButtonNotAllowed, line: 7)])
    }

    @Test func campoAusenteCitaALinhaDoAncestral() {
        let text = "{\n  \"palette\": {\n    \"items\": []\n  }\n}\n"
        let result = ConfigLoader.parse(data: Data(text.utf8))
        #expect(result.shortcutIssues == [ShortcutIssue(path: "palette.version", rule: .unsupportedVersion, line: 2)])
    }

    @Test func erroDeSintaxeComRegraELinha() {
        let text = "{\n  \"shortcuts\": {\n    \"version\": 1\n    \"layers\": {}\n  }\n}\n"
        let result = ConfigLoader.parse(data: Data(text.utf8))
        #expect(result.status == .invalidJSON)
        #expect(result.shortcuts == ShortcutDefaults.document)
        #expect(result.shortcutIssues == [ShortcutIssue(path: "", rule: .syntax, line: 4)])
        #expect(result.shortcutIssues.first?.logPath == nil)
    }

    @Test func arquivoIlegivelComRegraUnreadable() throws {
        let big = try tempDir().appendingPathComponent("config.json")
        try Data(repeating: 0x20, count: ConfigLoader.maxBytes + 1).write(to: big)
        for url in [big, try tempDir()] {
            let result = ConfigLoader.load(from: url)
            #expect(result.shortcutIssues == [ShortcutIssue(path: "", rule: .unreadable)], "\(url.lastPathComponent)")
            #expect(result.shortcuts == ShortcutDefaults.document)
            #expect(result.data == nil)
        }
    }

    @Test func linkSimbolicoLidoPeloDestino() throws {
        let dir = try tempDir()
        let target = dir.appendingPathComponent("dotfiles.json")
        try Data(#"{"palette": {"version": 1, "items": [{"text": "a"}]}}"#.utf8).write(to: target)
        let link = dir.appendingPathComponent("config.json")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: target)
        let result = ConfigLoader.load(from: link)
        #expect(result.shortcuts.palette == [PaletteItem("a", pressEnter: false)])
    }
}
