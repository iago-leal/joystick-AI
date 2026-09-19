import Testing
@testable import JoystickCore

/// Máquina das sugestões de palavras (`009-sugestao-de-palavras` D-03, D-04; RN-01 a RN-04, RN-12 a RN-14).
@Suite struct SuggestionContextTests {
    static func typed(_ text: String) -> SuggestionContext {
        var context = SuggestionContext()
        context.apply(.text(text))
        return context
    }

    // MARK: - Entrada (T007)

    @Test func textoAcumulaNaPalavraENoContexto() {
        var context = SuggestionContext()
        context.apply(.text("fun"))
        context.apply(.text("ç"))
        #expect(context.word == "funç")
        #expect(context.context == "funç")
        #expect(context.lastBoundary == nil)
    }

    @Test func fronteirasEncerramAPalavraEMantemOContexto() {
        for (input, expected) in [(SuggestionInput.boundary(.space), " "), (.boundary(.return), "\r"), (.boundary(.tab), "\t")] {
            var context = Self.typed("vamos")
            context.apply(input)
            #expect(context.word == "")
            #expect(context.context == "vamos" + expected)
        }
        var context = Self.typed("vamos impl")
        #expect(context.word == "impl")
        #expect(context.lastBoundary == .space)
        context.apply(.text("\tx"))
        #expect(context.word == "x")
        #expect(context.lastBoundary == .tab)
        context.apply(.text("\ny"))
        #expect(context.lastBoundary == .return)
    }

    @Test func controlesSaoIgnorados() {
        let context = Self.typed("a\u{1B}b\u{1C}\u{10}")
        #expect(context.context == "ab")
    }

    @Test func apagarRemoveOUltimoCaractere() {
        var context = Self.typed("vamos impl")
        context.apply(.backspace)
        #expect(context.word == "imp")
        for _ in 0..<3 { context.apply(.backspace) }
        #expect(context.word == "")
        #expect(context.context == "vamos ")
        context.apply(.backspace)
        #expect(context.word == "vamos")
    }

    @Test func apagarComContextoVazioDescarta() {
        var context = SuggestionContext()
        let before = context.revision
        context.apply(.backspace)
        #expect(context.context == "")
        #expect(context.revision > before)
        #expect(context.query(visible: true) == nil)
    }

    @Test func contextoGuardaSoOsUltimos200Caracteres() {
        var context = Self.typed(String(repeating: "ab ", count: 100))
        #expect(context.context.count == SuggestionContext.maxContext)
        context.apply(.text("xyz"))
        #expect(context.context.count == SuggestionContext.maxContext)
        #expect(context.context.hasSuffix("ab xyz"))
        context.apply(.boundary(.space))
        #expect(context.context.count == SuggestionContext.maxContext)
    }

    @Test func sinaisDeAberturaIniciaisFicamForaDaPalavra() {
        for text in ["(impl", "[impl", "\"impl", "'impl", "(\"impl"] {
            let context = Self.typed("vamos " + text)
            #expect(context.word == "impl", "\(text)")
            #expect(context.context == "vamos " + text)
        }
        #expect(Self.typed("a(b").word == "a(b")
    }

    @Test func cadaMudancaSobeARevisao() {
        var context = SuggestionContext()
        var last = context.revision
        for input in [SuggestionInput.text("a"), .backspace, .boundary(.space), .discard, .text("b")] {
            context.apply(input)
            #expect(context.revision > last)
            last = context.revision
        }
    }

    @Test func descarteEsvaziaTudo() {
        var context = Self.typed("vamos impl")
        context.apply(.discard)
        #expect(context.context == "")
        #expect(context.word == "")
        #expect(context.lastBoundary == nil)
        #expect(context.query(visible: true) == nil)
    }

    // MARK: - Consulta (T008)

    @Test func completaPalavraSoDeLetras() throws {
        let context = Self.typed("vamos impl")
        let query = try #require(context.query(visible: true))
        #expect(query == SuggestionQuery(text: "vamos impl", mode: .complete, revision: context.revision))
        #expect(Self.typed("funç").query(visible: true)?.mode == .complete)
        #expect(Self.typed("Olá").query(visible: true)?.mode == .complete)
    }

    @Test(arguments: ["cd ~/dev/joy", "ls -la", "a/b", "arq.txt", "snake_case", "x=1", "abc1", "~", "-"])
    func palavraComCaraDeCodigoNaoPede(_ text: String) {
        #expect(Self.typed(text).query(visible: true) == nil)
    }

    @Test func proximaPalavraSoAposEspacoDePalavraDeLetras() throws {
        let context = Self.typed("Olá, tudo ")
        let query = try #require(context.query(visible: true))
        #expect(query.mode == .next)
        #expect(query.text == "Olá, tudo ")
        #expect(Self.typed("vamos (impl ").query(visible: true)?.mode == .next)
    }

    @Test(arguments: ["tudo\r", "tudo\t", "Olá, ", "ls -la ", "a  ", " ", "abc1 "])
    func semPrevisaoForaDoEspacoAposLetras(_ text: String) {
        #expect(Self.typed(text).query(visible: true) == nil)
    }

    @Test func semPrevisaoComContextoVazioOuFaixaOculta() {
        #expect(SuggestionContext().query(visible: true) == nil)
        #expect(Self.typed("vamos impl").query(visible: false) == nil)
        #expect(Self.typed("tudo ").query(visible: false) == nil)
    }

    // MARK: - Filtro e aceitação (T009)

    @Test func filtroTiraEspacoEAPropriaPalavra() throws {
        let context = Self.typed("vamos impl")
        let query = try #require(context.query(visible: true))
        let words = context.filter(["impl ", "implementar ", "implementação "], for: query)
        #expect(words == ["implementar", "implementação"])
    }

    @Test func filtroSegueACaixaDaPrimeiraLetra() throws {
        let lower = Self.typed("vamos impl")
        #expect(lower.filter(["Implementar "], for: try #require(lower.query(visible: true))) == ["implementar"])
        let upper = Self.typed("Impl")
        #expect(upper.filter(["implementar ", "Implica "], for: try #require(upper.query(visible: true))) == ["Implementar", "Implica"])
        let accent = Self.typed("funç")
        #expect(accent.filter(["Funç ", "Função "], for: try #require(accent.query(visible: true))) == ["função"])
    }

    @Test func filtroMantemSoExtensoesExatasDeLetrasSemRepeticaoAteTres() throws {
        let context = Self.typed("rev")
        let query = try #require(context.query(visible: true))
        let candidates = ["revisar ", "reverter ", "Revisar ", "review-me ", "rev2 ", "reflexo ", "revelar ", "revogar "]
        #expect(context.filter(candidates, for: query) == ["revisar", "reverter", "revelar"])
        let long = "rev" + String(repeating: "a", count: SuggestionContext.maxWordLength)
        #expect(context.filter([long], for: query) == [])
    }

    @Test func filtroSemAcentoNaoCasaComAcento() throws {
        let context = Self.typed("funcao")
        #expect(context.filter(["função "], for: try #require(context.query(visible: true))) == [])
    }

    @Test func modoNextMantemACaixaDoMotor() throws {
        let context = Self.typed("Olá, tudo ")
        let query = try #require(context.query(visible: true))
        #expect(context.filter(["bem ", "Bom ", "bem ", "e.g. ", "certo "], for: query) == ["bem", "Bom", "certo"])
    }

    @Test func revisaoVelhaDevolveNil() throws {
        var context = Self.typed("vamos im")
        let query = try #require(context.query(visible: true))
        context.apply(.text("p"))
        #expect(context.filter(["implementar "], for: query) == nil)
        #expect(context.accept("implementar", revision: query.revision) == nil)
        #expect(context.accepted == 0)
    }

    @Test func aceitarDevolveSufixoEAtualizaOContexto() {
        var context = Self.typed("vamos impl")
        let revision = context.revision
        #expect(context.accept("implementar", revision: revision) == "ementar ")
        #expect(context.context == "vamos implementar ")
        #expect(context.word == "")
        #expect(context.lastBoundary == .space)
        #expect(context.accepted == 1)
        #expect(context.revision > revision)
        #expect(context.query(visible: true)?.mode == .next)
    }

    @Test func aceitarPrevisaoDigitaAPalavraInteira() {
        var context = Self.typed("Olá, tudo ")
        #expect(context.accept("bem", revision: context.revision) == "bem ")
        #expect(context.context == "Olá, tudo bem ")
        #expect(context.accepted == 1)
    }

    @Test func aceitarRecusaOQueNaoEstendeAPalavra() {
        var context = Self.typed("funç")
        #expect(context.accept("funç", revision: context.revision) == nil)
        #expect(context.accept("fazer", revision: context.revision) == nil)
        #expect(context.accept("funç1", revision: context.revision) == nil)
        #expect(context.accepted == 0)
        #expect(context.context == "funç")
    }
}
