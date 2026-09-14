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
    }
}
