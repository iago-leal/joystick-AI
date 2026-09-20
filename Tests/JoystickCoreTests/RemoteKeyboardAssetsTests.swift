import Foundation
import Testing

/// Isolamento da página do teclado remoto, verificado no repositório a cada `./scripts/test.sh`
/// (`008-iphone-teclado-remoto` D-15, `010-joystick-virtual-iphone` D-12), com a mesma leitura por `#filePath` de
/// `FigureAssetsTests`.
@Suite struct RemoteKeyboardAssetsTests {
    static let files = ["index.html", "keyboard.css", "keyboard.js", "controller.js"]
    static let scripts = ["keyboard.js", "controller.js"]

    static var folder: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Resources/RemoteKeyboard", isDirectory: true)
    }

    static func contents(_ name: String) throws -> String {
        try String(contentsOf: folder.appendingPathComponent(name), encoding: .utf8)
    }

    @Test func osArquivosDaPaginaExistem() throws {
        for name in Self.files {
            #expect(FileManager.default.fileExists(atPath: Self.folder.appendingPathComponent(name).path), "\(name)")
        }
    }

    /// Sem marcação a partir de texto nem avaliação de código, nos dois scripts da página.
    @Test func semMarcacaoNemAvaliacao() throws {
        for name in Self.scripts {
            let script = try Self.contents(name)
            for token in ["innerHTML", "outerHTML", "insertAdjacentHTML", "document.write", "eval"] {
                let regex = try Regex(#"\b"# + NSRegularExpression.escapedPattern(for: token) + #"\b"#)
                #expect(script.firstMatch(of: regex) == nil, "\(name): \(token)")
            }
            #expect(!script.contains("Function("), "\(name)")
            #expect(script.contains("textContent"), "\(name)")
        }
    }

    /// Nada embutido: um só `<script src>` e um só `<link href>`, ambos irmãos; sem `style` nem manipuladores inline.
    @Test func htmlSemScriptNemEstiloEmbutidos() throws {
        let html = try Self.contents("index.html")
        let sources = html.matches(of: try Regex(#"<(?:script|link)\b[^>]*\b(?:src|href)\s*=\s*["']([^"']*)["']"#))
            .map { String($0.output[1].substring!) }
        #expect(Set(sources) == ["keyboard.css", "keyboard.js", "controller.js"], "\(sources)")
        #expect(html.matches(of: try Regex(#"<script\b"#)).count == 2)
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

    /// Sugestões de palavras (`009-sugestao-de-palavras` D-10 a D-12): mensagens novas e preferências no `localStorage`.
    @Test func scriptConheceAsSugestoes() throws {
        let script = try Self.contents("keyboard.js")
        for type in ["prefs", "pick", "suggest"] {
            #expect(script.contains(#""\#(type)""#), "\(type)")
        }
        #expect(script.contains("localStorage"))
        #expect(script.contains("remoteKeyboardPrefs"))
        let html = try Self.contents("index.html")
        #expect(html.matches(of: try Regex(#"class="suggestion""#)).count == 3)
    }

    /// Controle virtual (`010-joystick-virtual-iphone` D-02, D-06, D-12 a D-15): mensagens novas, rastreio de dedos,
    /// quadro de animação, preferências e tela acesa.
    @Test func scriptConheceOControle() throws {
        let script = try Self.contents("controller.js")
        for type in ["btn", "stick", "pad", "mode"] {
            #expect(script.contains(#""\#(type)""#), "\(type)")
        }
        for mode in ["pointer", "compact", "full"] {
            #expect(script.contains(#""\#(mode)""#), "\(mode)")
        }
        // Todo botão do protocolo tem lugar na tela (§2 do protocolo), e `share` não entra (007 D-02).
        for button in [
            "cross", "circle", "square", "triangle", "dpadUp", "dpadDown", "dpadLeft", "dpadRight",
            "l1", "r1", "l2", "r2", "l3", "r3", "options", "create", "ps", "touchpadClick",
        ] {
            #expect(script.contains(#""\#(button)""#), "\(button)")
        }
        #expect(!script.contains(#""share""#), "share é do controle da 007, não da página")
        #expect(script.contains("requestAnimationFrame"))
        #expect(script.contains("identifier"))
        #expect(script.contains("touchcancel"))
        #expect(script.contains("remoteKeyboardPrefs") || script.contains("channel.prefs"))
        #expect(script.contains("wakeLock"))
    }

    /// As colunas e a faixa central do novo desenho existem na página (D-02, E-04, E-05).
    @Test func htmlTemOArranjoDoControle() throws {
        let html = try Self.contents("index.html")
        for id in ["stick-left", "stick-right", "dpad", "faces", "tray",
                   "shoulders-left", "shoulders-right", "controls",
                   "center", "pointer", "center-mode", "sensitivity"] {
            #expect(html.contains(#"id="\#(id)""#), "\(id)")
        }
        // A barra de estado e sugestões continua de pé (009 D-09).
        #expect(html.contains(#"id="strip""#))
        #expect(html.contains(#"id="keyboard""#))
    }

    /// Gatilhos aderentes e controle que se esconde (E-04, E-05): a página conhece os dois estados e não deixa
    /// nenhum caminho de saída sem soltura.
    @Test func scriptConheceAsEmendasDoToque() throws {
        let script = try Self.contents("controller.js")
        #expect(script.contains("LATCHABLE"))
        #expect(script.contains("LATCH_MS"))
        #expect(script.contains("releaseLatched"))
        #expect(script.contains(#""latched""#))
        #expect(script.contains("aria-pressed"))
        let css = try Self.contents("keyboard.css")
        #expect(css.contains(#"[data-state="latched"]"#))
        #expect(css.contains(#"[data-controls="off"]"#))
    }

    /// Arrasto coalescido na área de apontamento (E-09): um envio por quadro e por dedo, e a caixa da área medida
    /// por série em vez de por amostra, que era o que fazia o cursor andar aos pulos.
    @Test func scriptCoalesceOArrastoDaAreaDeApontamento() throws {
        let script = try Self.contents("controller.js")
        #expect(script.contains("schedulePad"))
        #expect(script.contains("flushPad"))
        #expect(script.contains("padBox"))
        // O movimento não chama mais o envio direto; pousar e levantar continuam imediatos.
        #expect(script.contains(#"sendPad(entry.finger, "e""#))
        #expect(script.firstMatch(of: try Regex(#"sendPad\(entry\.finger, "m""#)) == nil)
        #expect(script.contains("padPending"))
    }

    /// Analógico de origem dinâmica (E-06): a área de toque é maior que o desenho, e o curso não depende dele.
    @Test func scriptConheceOAnalogicoDeOrigemDinamica() throws {
        let script = try Self.contents("controller.js")
        #expect(script.contains("STICK_TRAVEL"))
        #expect(script.contains("stick.origin"))
        #expect(script.contains("placeStick"))
        let html = try Self.contents("index.html")
        #expect(html.matches(of: try Regex(#"class="stick-zone""#)).count == 2)
        let css = try Self.contents("keyboard.css")
        #expect(css.contains(".stick-zone"))
    }
    /// Sonda P-03 (`010-joystick-virtual-iphone`): a página se mede sozinha no aparelho, em vez de exigir cabo e
    /// inspetor. Só com `?p03` na URL, sem estilo inline, porque a política de conteúdo é `style-src 'self'`.
    @Test func scriptAferirOsAlvosSoComAChaveNaURL() throws {
        let script = try Self.contents("controller.js")
        #expect(script.contains("P03_MIN = 44"))
        #expect(script.contains("getBoundingClientRect"))
        #expect(script.contains(#"window.location.search.indexOf("p03")"#))
        #expect(script.contains(#"window.location.hash.indexOf("p03")"#))
        #expect(script.contains("p03Iniciar"))
        #expect(!script.contains("cssText"))

        let css = try Self.contents("keyboard.css")
        #expect(css.contains(".p03 {"))
        #expect(css.contains(".p03-falha"))
    }

    /// E-11, saída da P-03: o alvo dos botões da barra cresceu dentro da barra, sem a barra crescer.
    @Test func botoesDaBarraTomamAAlturaDaBarra() throws {
        let css = try Self.contents("keyboard.css")
        let control = try #require(css.range(of: ".control {"))
        let bloco = String(css[control.lowerBound...].prefix(while: { $0 != "}" }))
        #expect(bloco.contains("align-self: stretch"))
        #expect(bloco.contains("min-width: 44px"))
        #expect(!bloco.contains("align-self: center"))

        // A faixa precisa da altura da barra: sem isso, as sugestões, que deixaram de ter altura fixa, ficam com
        // alvo de altura zero, que é o que a remedição da P-03 flagrou.
        let strip = try #require(css.range(of: ".strip {"))
        #expect(String(css[strip.lowerBound...].prefix(while: { $0 != "}" })).contains("align-self: stretch"))
    }

}
