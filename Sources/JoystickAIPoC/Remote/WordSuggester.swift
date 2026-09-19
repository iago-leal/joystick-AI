import AppKit
import JoystickCore

/// Pedidos ao motor de previsão de texto do macOS (`009-sugestao-de-palavras` D-01, D-08): local, sem rede, com a
/// ortografia fixada pelo seletor PT / EN, porque a detecção automática erra o idioma em trechos curtos.
///
/// Só na main thread. Há no máximo um pedido em curso; chegando outro, o pendente é substituído pelo mais novo, para
/// não enfileirar consultas numa rajada de digitação. A resposta vai, com o pedido, à fila `input`, onde a revisão é
/// conferida. Nada do texto consultado ou das respostas é guardado aqui além do pedido pendente (RN-07).
///
/// Um pedido sem resposta em `timeout` é dado por encerrado, para que um motor mudo não congele a faixa pela sessão
/// inteira; a resposta tardia, se vier, é ignorada.
final class WordSuggester {
    static let timeout: DispatchTimeInterval = .seconds(1)

    private let queue: DispatchQueue
    private var tag: Int?
    /// Número do pedido em curso; `nil` sem pedido.
    private var inFlight: UInt64?
    private var nextRequest: UInt64 = 0
    private var pending: (query: SuggestionQuery, language: SuggestionLanguage)?

    /// Candidatos do motor, na ordem recebida, entregues na fila `input`.
    var onCandidates: ((SuggestionQuery, [String]) -> Void)?

    init(queue: DispatchQueue) {
        self.queue = queue
    }

    /// Início da sessão: etiqueta de documento nova e uma consulta vazia, que paga a primeira consulta lenta do motor
    /// antes da primeira tecla.
    func begin(language: SuggestionLanguage) {
        dispatchPrecondition(condition: .onQueue(.main))
        end()
        let tag = NSSpellChecker.uniqueSpellDocumentTag()
        self.tag = tag
        send("", language: language, tag: tag) { _ in }
    }

    /// Fim da sessão: descarta o pendente e ignora a resposta em curso.
    func end() {
        dispatchPrecondition(condition: .onQueue(.main))
        pending = nil
        inFlight = nil
        if let tag { NSSpellChecker.shared.closeSpellDocument(withTag: tag) }
        tag = nil
    }

    func request(_ query: SuggestionQuery, language: SuggestionLanguage) {
        dispatchPrecondition(condition: .onQueue(.main))
        guard let tag else { return }
        guard inFlight == nil else {
            pending = (query, language)
            return
        }
        send(query.text, language: language, tag: tag) { [weak self] words in
            guard let self else { return }
            let onCandidates = onCandidates
            queue.async { onCandidates?(query, words) }
        }
    }

    private func finished(_ number: UInt64) {
        guard inFlight == number else { return }
        inFlight = nil
        if let next = pending {
            pending = nil
            request(next.query, language: next.language)
        }
    }

    /// Cursor no fim do texto; o motor devolve a palavra que completa ou segue o trecho em `replacementString`.
    /// `completion` corre na main thread, só se a resposta chegar a tempo e na mesma sessão.
    private func send(_ text: String, language: SuggestionLanguage, tag: Int, completion: @escaping ([String]) -> Void) {
        nextRequest += 1
        let number = nextRequest
        inFlight = number
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.timeout) { [weak self] in self?.finished(number) }
        let orthography = NSOrthography.defaultOrthography(forLanguage: language == .pt ? "pt_BR" : "en")
        let length = (text as NSString).length
        NSSpellChecker.shared.requestCandidates(
            forSelectedRange: NSRange(location: length, length: 0), in: text, types: NSTextCheckingAllSystemTypes,
            options: [.orthography: orthography], inSpellDocumentWithTag: tag
        ) { [weak self] _, results in
            let words = results.compactMap(\.replacementString)
            DispatchQueue.main.async {
                guard let self, self.tag == tag, self.inFlight == number else { return }
                completion(words)
                self.finished(number)
            }
        }
    }
}
