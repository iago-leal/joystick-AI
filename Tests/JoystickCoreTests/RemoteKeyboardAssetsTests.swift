import Foundation
import Testing

/// Isolamento da página do teclado remoto, verificado no repositório a cada `./scripts/test.sh`
/// (`008-iphone-teclado-remoto` D-15), com a mesma leitura por `#filePath` de `FigureAssetsTests`.
@Suite struct RemoteKeyboardAssetsTests {
    static let files = ["index.html", "keyboard.css", "keyboard.js"]

    static var folder: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Resources/RemoteKeyboard", isDirectory: true)
    }

    static func contents(_ name: String) throws -> String {
        try String(contentsOf: folder.appendingPathComponent(name), encoding: .utf8)
    }

    @Test func osTresArquivosExistem() throws {
        for name in Self.files {
            #expect(FileManager.default.fileExists(atPath: Self.folder.appendingPathComponent(name).path), "\(name)")
        }
    }

    /// Sem marcação a partir de texto nem avaliação de código.
    @Test func semMarcacaoNemAvaliacao() throws {
        let script = try Self.contents("keyboard.js")
        for token in ["innerHTML", "outerHTML", "insertAdjacentHTML", "document.write", "eval"] {
            let regex = try Regex(#"\b"# + NSRegularExpression.escapedPattern(for: token) + #"\b"#)
            #expect(script.firstMatch(of: regex) == nil, "\(token)")
        }
        #expect(!script.contains("Function("))
        #expect(script.contains("textContent"))
    }

    /// Nada embutido: um só `<script src>` e um só `<link href>`, ambos irmãos; sem `style` nem manipuladores inline.
    @Test func htmlSemScriptNemEstiloEmbutidos() throws {
        let html = try Self.contents("index.html")
        let sources = html.matches(of: try Regex(#"<(?:script|link)\b[^>]*\b(?:src|href)\s*=\s*["']([^"']*)["']"#))
            .map { String($0.output[1].substring!) }
        #expect(Set(sources) == ["keyboard.css", "keyboard.js"], "\(sources)")
        #expect(html.matches(of: try Regex(#"<script\b"#)).count == 1)
        #expect(html.firstMatch(of: try Regex(#"<script\b[^>]*>\s*[^<\s]"#)) == nil)
        #expect(html.firstMatch(of: try Regex(#"<style\b"#)) == nil)
        #expect(html.firstMatch(of: try Regex(#"\sstyle\s*="#)) == nil)
        #expect(html.firstMatch(of: try Regex(#"\son[a-z]+\s*="#)) == nil)
    }

    /// Nenhuma referência externa; o canal é montado a partir do próprio host da página.
    @Test func semReferenciasExternas() throws {
        for name in Self.files {
            let text = try Self.contents(name)
            #expect(text.firstMatch(of: try Regex(#"https?://"#)) == nil, "\(name)")
        }
    }

    /// O script conhece os tipos de mensagem do protocolo e os códigos de fechamento finais (D-06, D-11, D-15).
    @Test func scriptConheceOProtocolo() throws {
        let script = try Self.contents("keyboard.js")
        for type in ["hello", "down", "up", "ping", "release", "bye", "welcome", "reject", "layout", "modifiers", "status", "caps"] {
            #expect(script.contains(#""\#(type)""#), "\(type)")
        }
        for reason in ["busy", "bad_token", "code_rotated"] {
            #expect(script.contains(#""\#(reason)""#), "\(reason)")
        }
        for code in ["4001", "4002", "4003", "4004", "47811"] {
            #expect(script.contains(code), "\(code)")
        }
        #expect(script.contains("visibilitychange"))
        #expect(script.contains("pagehide"))
        #expect(script.contains("touchcancel"))
        #expect(script.contains("history.replaceState"))
    }
}
