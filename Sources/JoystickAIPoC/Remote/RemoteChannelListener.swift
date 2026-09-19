import Foundation
import JoystickCore
import Network

/// Resposta do consumidor a uma mensagem da sessão ativa.
enum RemoteChannelVerdict {
    case ok
    /// Encerra a sessão: `bye` ou a quinta mensagem inválida seguida.
    case close(RemoteDisconnectReason)
}

/// Consumidor do canal, chamado sempre na fila `input`.
protocol RemoteChannelDelegate: AnyObject {
    func channelSessionStarted(resumed: Bool)
    /// `nil` é uma mensagem inválida (quadro binário, acima de 1 KiB, JSON ruim, `t` desconhecido).
    func channelMessage(_ message: RemoteKeyboardMessage.Client?) -> RemoteChannelVerdict
    /// A sessão acabou; o consumidor já deve ter soltado tudo quando retornar.
    func channelSessionEnded(reason: RemoteDisconnectReason)
    func channelRejected(_ reason: RemoteRejectReason)
    /// Código de pareamento novo (quinta falha); o consumidor o mostra na janela.
    func channelCodeChanged(_ code: String)
}

/// Canal do teclado remoto: WebSocket sobre TLS na porta 47811 (`008-iphone-teclado-remoto` D-02, D-05 a D-07, D-16;
/// `interfaces/remote-keyboard-protocol.md` §3).
///
/// Tudo corre na fila `input`: o listener, as conexões, o pareamento e os temporizadores. Um aparelho por vez; com
/// sessão ativa, a conexão nova só é examinada pelo `hello`, e o token da sessão a substitui (D-06).
final class RemoteChannelListener {
    static let port: UInt16 = 47811
    static let helloTimeout: DispatchTimeInterval = .seconds(5)
    static let idleTimeout: DispatchTimeInterval = .seconds(10)

    /// Códigos de fechamento de aplicação (§3).
    enum CloseCode: UInt16 {
        case busy = 4001, beforeHello = 4002, invalidMessages = 4003, replaced = 4004
    }

    private let queue: DispatchQueue
    private let listener: NWListener
    private let originGate = OriginGate()
    private(set) var pairing: RemotePairing
    weak var delegate: RemoteChannelDelegate?

    private var active: NWConnection?
    private var idleTimer: DispatchWorkItem?
    /// Conexões aguardando o `hello`, com o temporizador de 5 s; a referência forte as mantém vivas até lá.
    private var pending: [ObjectIdentifier: (connection: NWConnection, timeout: DispatchWorkItem)] = [:]

    init(identity: RemoteKeyboardIdentity.Loaded, queue: DispatchQueue, pairing: RemotePairing = RemotePairing()) throws {
        self.queue = queue
        self.pairing = pairing
        // O Safari envia o host em minúsculas; nomes de host não distinguem caixa (RFC 4343).
        let expectedOrigin = "https://\(identity.host):\(RemotePageListener.port)".lowercased()
        let parameters = NWParameters(tls: identity.tlsOptions())
        parameters.allowLocalEndpointReuse = true
        let websocket = NWProtocolWebSocket.Options()
        websocket.autoReplyPing = true
        // Acima de 1 KiB o quadro é inválido e contado; acima disto a conexão cai, para limitar a memória.
        websocket.maximumMessageSize = 16 * 1024
        // O `Origin` impede que outra página aberta no iPhone use o canal (D-07).
        websocket.setClientRequestHandler(queue) { [originGate] _, headers in
            let received = headers.first { $0.name.caseInsensitiveCompare("Origin") == .orderedSame }?.value
            guard received?.lowercased() == expectedOrigin else {
                originGate.onReject?()
                return NWProtocolWebSocket.Response(status: .reject, subprotocol: nil, additionalHeaders: nil)
            }
            return NWProtocolWebSocket.Response(status: .accept, subprotocol: nil, additionalHeaders: nil)
        }
        parameters.defaultProtocolStack.applicationProtocols.insert(websocket, at: 0)
        listener = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: Self.port)!)
        originGate.onReject = { [weak self] in self?.delegate?.channelRejected(.badOrigin) }
    }

    /// Ponte do tratador do aperto de mão, criado antes do listener, para o consumidor.
    private final class OriginGate {
        var onReject: (() -> Void)?
    }

    var hasSession: Bool { active != nil }

    /// `onState` recebe `true` quando pronto e `false` em falha; na fila `input`.
    func start(onState: @escaping (Bool) -> Void) {
        listener.stateUpdateHandler = { state in
            switch state {
            case .ready: onState(true)
            case .failed, .cancelled: onState(false)
            default: break
            }
        }
        listener.newConnectionHandler = { [weak self] connection in self?.accept(connection) }
        listener.start(queue: queue)
    }

    /// Recurso desligado: encerra a sessão (que o consumidor solta), fecha tudo e invalida código e token.
    func stop() {
        dispatchPrecondition(condition: .onQueue(queue))
        listener.stateUpdateHandler = nil
        listener.newConnectionHandler = nil
        listener.cancel()
        if let connection = active {
            endSession(connection, reason: .disabled, close: nil)
        }
        for item in pending.values {
            item.timeout.cancel()
            item.connection.cancel()
        }
        pending = [:]
        pairing.reset()
    }

    func send(_ message: RemoteKeyboardMessage.Server) {
        dispatchPrecondition(condition: .onQueue(queue))
        guard let active else { return }
        Self.send(message, on: active)
    }

    // MARK: - Conexões

    private func accept(_ connection: NWConnection) {
        guard RemoteEndpoint.isLocal(connection.endpoint) else {
            connection.cancel()
            delegate?.channelRejected(.notLocal)
            return
        }
        let id = ObjectIdentifier(connection)
        let timeout = DispatchWorkItem { [weak self, weak connection] in
            guard let self, let connection, pending.removeValue(forKey: id) != nil else { return }
            Self.close(connection, code: .beforeHello)
        }
        pending[id] = (connection, timeout)
        queue.asyncAfter(deadline: .now() + Self.helloTimeout, execute: timeout)
        connection.stateUpdateHandler = { [weak self, weak connection] state in
            guard let self, let connection else { return }
            switch state {
            case .failed, .cancelled: connectionEnded(connection)
            default: break
            }
        }
        connection.start(queue: queue)
        receive(on: connection)
    }

    private func receive(on connection: NWConnection) {
        connection.receiveMessage { [weak self, weak connection] data, context, _, error in
            guard let self, let connection else { return }
            if error != nil {
                connection.cancel()
                return
            }
            let metadata = context?.protocolMetadata(definition: NWProtocolWebSocket.definition) as? NWProtocolWebSocket.Metadata
            if metadata?.opcode == .close {
                connection.cancel()
                return
            }
            let message = metadata?.opcode == .text ? data.flatMap(RemoteKeyboardMessage.Client.decode) : nil
            if pending[ObjectIdentifier(connection)] != nil {
                handleHello(message, on: connection)
            } else if connection === active {
                handleSessionMessage(message, on: connection)
            }
            // A conexão pode ter sido fechada acima; só continua a ler as que seguem vivas.
            if connection === active || pending[ObjectIdentifier(connection)] != nil {
                receive(on: connection)
            }
        }
    }

    private func handleHello(_ message: RemoteKeyboardMessage.Client?, on connection: NWConnection) {
        pending.removeValue(forKey: ObjectIdentifier(connection))?.timeout.cancel()
        guard case .hello(let credential)? = message else {
            Self.close(connection, code: .beforeHello)
            return
        }
        let outcome: PairingOutcome = switch credential {
        case .code(let code): pairing.present(code: code)
        case .token(let token): pairing.present(token: token)
        }
        switch outcome {
        case .accepted(let token):
            begin(connection, token: token, resumed: false)
        case .resumed(let token, let replacesActive):
            if replacesActive, let old = active {
                // O pareamento já passou a sessão à conexão nova; só a antiga é solta e fechada.
                endSession(old, reason: .replaced, close: .replaced, releasePairing: false)
            }
            begin(connection, token: token, resumed: true)
        case .rejected(let rejection):
            let server: RemoteKeyboardMessage.ServerRejection = switch rejection {
            case .badCode: .badCode
            case .badToken: .badToken
            case .busy: .busy
            }
            delegate?.channelRejected(RemoteRejectReason(rawValue: rejection.rawValue) ?? .busy)
            Self.send(.reject(server), on: connection)
            Self.close(connection, code: rejection == .busy ? .busy : nil)
        case .codeRotated:
            delegate?.channelRejected(.codeRotated)
            delegate?.channelCodeChanged(pairing.code)
            Self.send(.reject(.codeRotated), on: connection)
            Self.close(connection, code: nil)
        }
    }

    private func begin(_ connection: NWConnection, token: [UInt8], resumed: Bool) {
        active = connection
        Self.send(.welcome(token: token), on: connection)
        restartIdleTimer(for: connection)
        delegate?.channelSessionStarted(resumed: resumed)
    }

    private func handleSessionMessage(_ message: RemoteKeyboardMessage.Client?, on connection: NWConnection) {
        restartIdleTimer(for: connection)
        let verdict = delegate?.channelMessage(message) ?? .ok
        switch verdict {
        case .ok: break
        case .close(let reason):
            endSession(connection, reason: reason, close: reason == .invalidMessages ? .invalidMessages : nil)
        }
    }

    private func restartIdleTimer(for connection: NWConnection) {
        idleTimer?.cancel()
        let timer = DispatchWorkItem { [weak self, weak connection] in
            guard let self, let connection, connection === active else { return }
            endSession(connection, reason: .timeout, close: nil)
        }
        idleTimer = timer
        queue.asyncAfter(deadline: .now() + Self.idleTimeout, execute: timer)
    }

    /// Solta tudo (pelo consumidor) antes de liberar a sessão, e só então fecha a conexão (§3.5).
    private func endSession(
        _ connection: NWConnection, reason: RemoteDisconnectReason, close code: CloseCode?, releasePairing: Bool = true
    ) {
        guard connection === active else { return }
        active = nil
        idleTimer?.cancel()
        idleTimer = nil
        if releasePairing { pairing.endSession() }
        delegate?.channelSessionEnded(reason: reason)
        Self.close(connection, code: code)
    }

    private func connectionEnded(_ connection: NWConnection) {
        pending.removeValue(forKey: ObjectIdentifier(connection))?.timeout.cancel()
        endSession(connection, reason: .closed, close: nil)
    }

    // MARK: - Envio

    private static func send(_ message: RemoteKeyboardMessage.Server, on connection: NWConnection) {
        let metadata = NWProtocolWebSocket.Metadata(opcode: .text)
        let context = NWConnection.ContentContext(identifier: "text", metadata: [metadata])
        connection.send(content: message.encoded(), contentContext: context, isComplete: true, completion: .idempotent)
    }

    /// Quadro de fechamento com o código de aplicação, ou normal (1000), e cancelamento em seguida.
    private static func close(_ connection: NWConnection, code: CloseCode?) {
        let metadata = NWProtocolWebSocket.Metadata(opcode: .close)
        metadata.closeCode = code.map { .applicationCode($0.rawValue) } ?? .protocolCode(.normalClosure)
        let context = NWConnection.ContentContext(identifier: "close", metadata: [metadata])
        connection.send(content: nil, contentContext: context, isComplete: true, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
}
