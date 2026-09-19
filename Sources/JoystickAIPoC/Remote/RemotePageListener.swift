import Foundation
import JoystickCore
import Network

/// Página do teclado remoto por HTTPS na porta 47810: só `GET` dos três arquivos do bundle, uma resposta por conexão
/// (`008-iphone-teclado-remoto` D-02, `interfaces/remote-keyboard-protocol.md` §2).
final class RemotePageListener {
    static let port: UInt16 = 47810
    static let maxRequestBytes = 8 * 1024
    static let requestTimeout: DispatchTimeInterval = .seconds(5)
    static let files: [String: String] = [
        "/": "index.html",
        "/keyboard.css": "keyboard.css",
        "/keyboard.js": "keyboard.js",
    ]

    private let queue = DispatchQueue(label: "remote.page", qos: .userInitiated)
    private let listener: NWListener
    private let host: String
    private let resources: URL
    private let onRejected: (RemoteRejectReason) -> Void

    /// `onRejected` e `onFailure` são chamados na fila própria do listener.
    init(identity: RemoteKeyboardIdentity.Loaded, resources: URL, onRejected: @escaping (RemoteRejectReason) -> Void) throws {
        let parameters = NWParameters(tls: identity.tlsOptions())
        parameters.allowLocalEndpointReuse = true
        listener = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: Self.port)!)
        host = identity.host
        self.resources = resources
        self.onRejected = onRejected
    }

    /// `onState` recebe `true` quando pronto e `false` em falha; chamado na fila do listener.
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

    func stop() {
        listener.stateUpdateHandler = nil
        listener.cancel()
    }

    private func accept(_ connection: NWConnection) {
        // Fora da rede local: fecha antes do aperto de mão TLS, sem bytes de resposta (§1).
        guard RemoteEndpoint.isLocal(connection.endpoint) else {
            connection.cancel()
            onRejected(.notLocal)
            return
        }
        connection.start(queue: queue)
        let timeout = DispatchWorkItem { connection.cancel() }
        queue.asyncAfter(deadline: .now() + Self.requestTimeout, execute: timeout)
        receive(connection, buffer: Data(), timeout: timeout)
    }

    private func receive(_ connection: NWConnection, buffer: Data, timeout: DispatchWorkItem) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: Self.maxRequestBytes) { [weak self] data, _, isComplete, error in
            guard let self else { return }
            var buffer = buffer
            if let data { buffer.append(data) }
            if buffer.count > Self.maxRequestBytes || error != nil {
                timeout.cancel()
                connection.cancel()
                return
            }
            guard let end = buffer.range(of: Data("\r\n\r\n".utf8)) else {
                if isComplete {
                    timeout.cancel()
                    connection.cancel()
                } else {
                    receive(connection, buffer: buffer, timeout: timeout)
                }
                return
            }
            timeout.cancel()
            respond(to: buffer[..<end.lowerBound], on: connection)
        }
    }

    private func respond(to head: Data, on connection: NWConnection) {
        let requestLine = String(decoding: head, as: UTF8.self).split(separator: "\r\n", maxSplits: 1).first ?? ""
        let parts = requestLine.split(separator: " ")
        let response: Data
        if parts.count != 3 {
            response = Self.empty(status: "400 Bad Request")
        } else if parts[0] != "GET" {
            response = Self.empty(status: "405 Method Not Allowed", extra: "Allow: GET\r\n")
        } else {
            // A consulta e o fragmento não escolhem arquivo; o fragmento nem chega ao servidor.
            let path = String(parts[1].split(separator: "?", maxSplits: 1).first ?? "")
            if let name = Self.files[path], let body = try? Data(contentsOf: resources.appendingPathComponent(name)) {
                response = ok(body: body, type: Self.contentType(name))
            } else {
                response = Self.empty(status: "404 Not Found")
            }
        }
        connection.send(content: response, isComplete: true, completion: .contentProcessed { _ in connection.cancel() })
    }

    private func ok(body: Data, type: String) -> Data {
        let head = "HTTP/1.1 200 OK\r\n"
            + "Content-Type: \(type)\r\n"
            + "Content-Length: \(body.count)\r\n"
            + "Cache-Control: no-store\r\n"
            + "Content-Security-Policy: default-src 'self'; connect-src wss://\(host):\(RemoteChannelListener.port); "
            + "script-src 'self'; style-src 'self'\r\n"
            + "X-Content-Type-Options: nosniff\r\n"
            + "Connection: close\r\n\r\n"
        return Data(head.utf8) + body
    }

    private static func empty(status: String, extra: String = "") -> Data {
        Data("HTTP/1.1 \(status)\r\nContent-Length: 0\r\n\(extra)Connection: close\r\n\r\n".utf8)
    }

    private static func contentType(_ name: String) -> String {
        switch (name as NSString).pathExtension {
        case "html": "text/html; charset=utf-8"
        case "css": "text/css; charset=utf-8"
        default: "text/javascript; charset=utf-8"
        }
    }
}

/// Endereço remoto de uma conexão, só para o filtro de `LocalAddressPolicy`; nunca vai ao log (RN-13).
enum RemoteEndpoint {
    static func isLocal(_ endpoint: NWEndpoint) -> Bool {
        guard case .hostPort(let host, _) = endpoint else { return false }
        switch host {
        case .ipv4(let address): return LocalAddressPolicy.isAllowed("\(address)")
        case .ipv6(let address): return LocalAddressPolicy.isAllowed("\(address)")
        default: return false
        }
    }
}
