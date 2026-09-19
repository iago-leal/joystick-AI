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
final class RemoteKeyboardService: RemoteChannelDelegate {
    private let context: InputContext
    private let actions: RemoteKeyboardActions
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

    init(context: InputContext, actions: RemoteKeyboardActions, layoutReader: KeyboardLayoutReader, resources: URL?) {
        self.context = context
        self.actions = actions
        self.layoutReader = layoutReader
        self.resources = resources
        actions.onModifiers = { [weak self] states in self?.channel?.send(.modifiers(states)) }
        actions.onCapsLock = { [weak self] on in self?.channel?.send(.capsLock(on: on)) }
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

    private func labelsChanged(_ table: KeyLabelTable) {
        context.queue.async { [self] in
            labels = table
            channel?.send(.layout(geometry: sessionGeometry, labels: table))
        }
    }

    func channelSessionStarted(resumed: Bool) {
        actions.begin()
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
        let keys = actions.end()
        context.log.log(LogEventCatalog.remoteDisconnected(reason: reason, keys: keys))
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
