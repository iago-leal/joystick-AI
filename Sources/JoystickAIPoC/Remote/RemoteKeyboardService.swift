import Foundation
import JoystickCore

/// Estado do teclado remoto para o menu e a janela de pareamento (D-14).
struct RemoteKeyboardStatus: Equatable {
    var enabled = false
    var url: String?
    var code: String?
    var connected = false
    /// Linha de erro do menu: identidade ausente, vencida ou de outro nome, ou porta ocupada.
    var error: String?
}

/// Liga e desliga o teclado remoto (`008-iphone-teclado-remoto` D-02, D-14, D-18): identidade, listeners, pareamento,
/// mensagens `layout`, `modifiers` e `status` para a página, e os eventos `remote.*` do log.
///
/// A API pública é da main thread; o canal e as ações correm na fila `input`. O recurso nasce desligado (RN-02).
///
/// Sugestões de palavras (`009-sugestao-de-palavras` D-01, D-06, D-08): as consultas das ações vão ao `WordSuggester`
/// na main thread, e a resposta volta à fila `input`, onde só segue para a página se a revisão ainda for a atual.
final class RemoteKeyboardService: RemoteChannelDelegate {
    private let context: InputContext
    private let actions: RemoteKeyboardActions
    private let suggester: WordSuggester
    private let layoutReader: KeyboardLayoutReader
    private let resources: URL?

    private var page: RemotePageListener?
    /// Na fila `input`.
    private var channel: RemoteChannelListener?
    private var geometry = RemoteKeyGeometry.standard(.ansi)
    /// Na fila `input`: geometria, últimos rótulos e estado do portão, reenviados a cada sessão.
    private var sessionGeometry = RemoteKeyGeometry.standard(.ansi)
    private var labels = KeyLabelTable()
    private var injectionOn = true
    private var readyCount = 0
    private var host = ""

    private(set) var status = RemoteKeyboardStatus() {
        didSet { if status != oldValue { onStatusChange?(status) } }
    }

    /// Main thread.
    var onStatusChange: ((RemoteKeyboardStatus) -> Void)?
    /// Main thread: um aparelho acabou de parear ou retomar a sessão.
    var onConnected: (() -> Void)?

    init(
        context: InputContext, actions: RemoteKeyboardActions, suggester: WordSuggester, layoutReader: KeyboardLayoutReader,
        resources: URL?
    ) {
        self.context = context
        self.actions = actions
        self.suggester = suggester
        self.layoutReader = layoutReader
        self.resources = resources
        actions.onModifiers = { [weak self] states in self?.channel?.send(.modifiers(states)) }
        actions.onCapsLock = { [weak self] on in self?.channel?.send(.capsLock(on: on)) }
        actions.onSuggestionQuery = { [weak self] query, revision, language in
            self?.suggestionQuery(query, revision: revision, language: language)
        }
        suggester.onCandidates = { [weak self] query, candidates in self?.candidates(candidates, for: query) }
        layoutReader.onChange = { [weak self] table in self?.labelsChanged(table) }
    }

    // MARK: - Main thread

    func setEnabled(_ on: Bool) {
        dispatchPrecondition(condition: .onQueue(.main))
        if on { enable() } else { disable(reason: .menu) }
    }

    private func enable() {
        guard !status.enabled else { return }
        let identity: RemoteKeyboardIdentity.Loaded
        switch RemoteKeyboardIdentity.load() {
        case .failure(let failure):
            context.log.log(LogEventCatalog.remoteRejected(reason: failure.reason))
            status = RemoteKeyboardStatus(error: failure.message)
            return
        case .success(let loaded):
            identity = loaded
        }
        guard let resources else {
            status = RemoteKeyboardStatus(error: "Página do teclado remoto ausente do app")
            return
        }
        geometry = RemoteKeyGeometry.standard(KeyboardLayoutReader.physicalLayout)
        let table = KeyboardLayoutReader.labels(for: geometry.codes)
        let layout = KeyboardLayoutReader.currentLayout()
        host = identity.host
        let channel: RemoteChannelListener
        let page: RemotePageListener
        do {
            page = try RemotePageListener(identity: identity, resources: resources) { [weak self] reason in
                self?.context.queue.async { self?.channelRejected(reason) }
            }
            channel = try RemoteChannelListener(identity: identity, queue: context.queue)
        } catch {
            context.log.log(LogEventCatalog.remoteDisabled(reason: .listenerFailed))
            status = RemoteKeyboardStatus(error: Self.portsMessage)
            return
        }
        channel.delegate = self
        self.page = page
        readyCount = 0
        status = RemoteKeyboardStatus(enabled: true, url: nil, code: nil, connected: false, error: nil)
        let geometry = geometry
        context.queue.async { [self] in
            self.channel = channel
            sessionGeometry = geometry
            labels = table
            actions.setGeometry(geometry)
            actions.setLayout(layout)
            let code = channel.pairing.code
            DispatchQueue.main.async { self.publish(code: code) }
            channel.start { [weak self] ready in DispatchQueue.main.async { self?.listenerState(ready) } }
        }
        page.start { [weak self] ready in DispatchQueue.main.async { self?.listenerState(ready) } }
        layoutReader.start()
    }

    /// `quit` vem do `Lifecycle`, que já soltou tudo; aqui só se fecham os listeners, de forma síncrona.
    func disable(reason: RemoteDisabledReason) {
        dispatchPrecondition(condition: .onQueue(.main))
        guard status.enabled || page != nil else { return }
        layoutReader.stop()
        page?.stop()
        page = nil
        context.queue.sync {
            channel?.stop()
            channel = nil
        }
        context.log.log(LogEventCatalog.remoteDisabled(reason: reason))
        status = RemoteKeyboardStatus()
    }

    private static let portsMessage = "Portas \(RemotePageListener.port) e \(RemoteChannelListener.port) indisponíveis"

    private func listenerState(_ ready: Bool) {
        guard status.enabled else { return }
        guard ready else {
            listenerFailed()
            return
        }
        readyCount += 1
        if readyCount == 2 {
            context.log.log(LogEventCatalog.remoteEnabled(port: RemotePageListener.port, channelPort: RemoteChannelListener.port))
        }
    }

    private func listenerFailed() {
        disable(reason: .listenerFailed)
        status.error = Self.portsMessage
    }

    private func publish(code: String) {
        guard status.enabled else { return }
        status.code = code
        status.url = "https://\(host):\(RemotePageListener.port)/#c=\(code)"
    }

    // MARK: - Fila `input`

    /// Portão de injeção (D-13, RN-11): avisa a página de "sem permissão" e da volta.
    func injectionChanged(_ allowed: Bool) {
        context.assertOnQueue()
        injectionOn = allowed
        channel?.send(.status(injectionOn: allowed))
    }

    /// Troca da fonte de entrada (main thread): rótulos novos para a página, layout novo para o tradutor e descarte do
    /// contexto recente (RN-03).
    private func labelsChanged(_ table: KeyLabelTable) {
        let layout = KeyboardLayoutReader.currentLayout()
        context.queue.async { [self] in
            labels = table
            actions.setLayout(layout)
            channel?.send(.layout(geometry: sessionGeometry, labels: table))
        }
    }

    /// Faixa vazia sem consulta; com consulta, o pedido vai ao motor na main thread (D-08).
    private func suggestionQuery(_ query: SuggestionQuery?, revision: UInt64, language: SuggestionLanguage) {
        guard let query else {
            channel?.send(.suggest(revision: revision, mode: .complete, words: []))
            return
        }
        DispatchQueue.main.async { [suggester] in suggester.request(query, language: language) }
    }

    /// Resposta do motor, na fila `input`: segue só se a revisão ainda for a atual.
    private func candidates(_ candidates: [String], for query: SuggestionQuery) {
        guard let words = actions.offer(candidates, for: query) else { return }
        channel?.send(.suggest(revision: query.revision, mode: query.mode, words: words))
    }

    func channelSessionStarted(resumed: Bool) {
        actions.begin()
        DispatchQueue.main.async { [suggester] in suggester.begin(language: .pt) }
        channel?.send(.layout(geometry: sessionGeometry, labels: labels))
        channel?.send(.status(injectionOn: injectionOn))
        context.log.log(LogEventCatalog.remoteConnected(resumed: resumed))
        DispatchQueue.main.async { [self] in
            guard status.enabled else { return }
            status.connected = true
            onConnected?()
        }
    }

    func channelMessage(_ message: RemoteKeyboardMessage.Client?) -> RemoteChannelVerdict {
        actions.handle(message)
    }

    func channelSessionEnded(reason: RemoteDisconnectReason) {
        let counts = actions.end()
        DispatchQueue.main.async { [suggester] in suggester.end() }
        context.log.log(LogEventCatalog.remoteDisconnected(reason: reason, keys: counts.keys, suggestions: counts.suggestions))
        // Na substituição, a sessão continua com a conexão nova.
        guard reason != .replaced else { return }
        DispatchQueue.main.async { [self] in status.connected = false }
    }

    func channelRejected(_ reason: RemoteRejectReason) {
        context.log.log(LogEventCatalog.remoteRejected(reason: reason))
    }

    func channelCodeChanged(_ code: String) {
        DispatchQueue.main.async { [self] in publish(code: code) }
    }
}
