import Foundation
import Testing
@testable import JoystickCore

/// Isolamento da página da figura, verificado no repositório a cada `./scripts/test.sh`
/// (`004-figura-controle-web` D-03, RF-08, RF-09, RN-09).
///
/// Lê `Resources/ControllerFigure/` a partir de `#filePath`: é leitura de texto, fora de `Sources/`, aceita pelo
/// roadmap §3.1 para tornar o contrato verificável sem inspeção manual do bundle.
@Suite struct FigureAssetsTests {
    static let files = ["index.html", "figure.css", "figure.js"]

    static var folder: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Resources/ControllerFigure", isDirectory: true)
    }

    static func contents(_ name: String) throws -> String {
        try String(contentsOf: folder.appendingPathComponent(name), encoding: .utf8)
    }

    @Test func osTresArquivosExistem() throws {
        for name in Self.files {
            #expect(FileManager.default.fileExists(atPath: Self.folder.appendingPathComponent(name).path), "\(name)")
        }
    }

    /// Nenhuma referência externa: `http://`, `https://` ou `//` como início de URL em `src`, `href`, `url(` ou `@import`.
    @Test func semReferenciasExternas() throws {
        let patterns = [
            #"https?://"#,
            #"(src|href)\s*=\s*["']?\s*//"#,
            #"url\(\s*["']?\s*//"#,
            #"@import\s+(url\(\s*)?["']?\s*//"#,
        ]
        for name in Self.files {
            let text = try Self.contents(name)
            for pattern in patterns {
                let regex = try Regex(pattern)
                #expect(text.firstMatch(of: regex) == nil, "\(name): \(pattern)")
            }
        }
    }

    /// `<script src>` e `<link href>` só apontam para os irmãos.
    @Test func subrecursosSoIrmaos() throws {
        let html = try Self.contents("index.html")
        let sources = html.matches(of: try Regex(#"<(?:script|link)\b[^>]*\b(?:src|href)\s*=\s*["']([^"']*)["']"#))
            .map { String($0.output[1].substring!) }
        #expect(!sources.isEmpty)
        #expect(Set(sources) == ["figure.css", "figure.js"], "\(sources)")
        let scripts = html.matches(of: try Regex(#"<script\b"#)).count
        #expect(scripts == 1)
    }

    @Test func politicaDeSegurancaDeConteudo() throws {
        let html = try Self.contents("index.html")
        let meta = try Regex(
            #"<meta\s+http-equiv="Content-Security-Policy"\s+content="default-src 'none'; script-src 'self'; style-src 'self'">"#)
        #expect(html.firstMatch(of: meta) != nil)
        #expect(html.contains(#"<meta name="color-scheme" content="light dark">"#))
    }

    /// RN-09 e RF-09: sem marcação a partir de texto, sem armazenamento, sem rede, sem laço de animação.
    @Test func scriptSemMarcacaoArmazenamentoNemRede() throws {
        let script = try Self.contents("figure.js")
        let forbidden = [
            "innerHTML", "outerHTML", "insertAdjacentHTML", "document.write", "eval",
            "localStorage", "sessionStorage", "indexedDB", "fetch", "XMLHttpRequest", "WebSocket",
            "setInterval", "requestAnimationFrame", "document.cookie", "window.open",
        ]
        for token in forbidden {
            let regex = try Regex(#"\b"# + NSRegularExpression.escapedPattern(for: token) + #"\b"#)
            #expect(script.firstMatch(of: regex) == nil, "\(token)")
        }
        #expect(script.contains("textContent"))
        #expect(script.contains("messageHandlers.figure.postMessage"))
    }
}
