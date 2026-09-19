import Foundation

/// Máquina do controle ativo (D-09, D-25, RN-01, RN-04).
///
/// Não tem fila própria: o chamador serializa as transições na fila `input`.
/// A chave identifica o objeto do controle (no app, `ObjectIdentifier` do `GCController`).
public struct ActiveControllerRegistry<Key: Hashable> {
    public enum ConnectOutcome: Equatable {
        case active
        /// Posição na fila, em que o ativo ocupa a posição 0.
        case queued(position: Int)
        /// O mesmo controle já estava registrado.
        case duplicate
        /// Modelo não aceito (`007-controle-ipega` D-05).
        case ignored
    }

    public struct DisconnectOutcome: Equatable {
        public var removed: ControllerInfo?
        public var wasActive: Bool
        /// Botões soltos sinteticamente, em ordem estável, antes de `controllerDisconnected`.
        public var syntheticReleases: [ButtonID]
        public var promoted: ControllerInfo?
    }

    private var entries: [(key: Key, info: ControllerInfo)] = []
    public private(set) var pressed: Set<ButtonID> = []

    public init() {}

    public var queue: [ControllerInfo] { entries.map(\.info) }
    public var active: ControllerInfo? { entries.first?.info }
    public var activeKey: Key? { entries.first?.key }

    public func isActive(_ key: Key) -> Bool { entries.first?.key == key }

    public func info(for key: Key) -> ControllerInfo? { entries.first { $0.key == key }?.info }

    public mutating func connect(key: Key, info: ControllerInfo, accepted: Bool) -> ConnectOutcome {
        guard accepted else { return .ignored }
        guard !entries.contains(where: { $0.key == key }) else { return .duplicate }
        entries.append((key, info))
        return entries.count == 1 ? .active : .queued(position: entries.count - 1)
    }

    public mutating func disconnect(key: Key) -> DisconnectOutcome {
        guard let index = entries.firstIndex(where: { $0.key == key }) else {
            return DisconnectOutcome(removed: nil, wasActive: false, syntheticReleases: [], promoted: nil)
        }
        let removed = entries.remove(at: index).info
        guard index == 0 else {
            return DisconnectOutcome(removed: removed, wasActive: false, syntheticReleases: [], promoted: nil)
        }
        let releases = pressed.sorted()
        pressed.removeAll()
        return DisconnectOutcome(removed: removed, wasActive: true, syntheticReleases: releases, promoted: entries.first?.info)
    }

    /// Registra o pressionar de um botão do controle ativo; devolve `false` se ignorado.
    public mutating func press(_ button: ButtonID, from key: Key) -> Bool {
        guard isActive(key) else { return false }
        return pressed.insert(button).inserted
    }

    public mutating func release(_ button: ButtonID, from key: Key) -> Bool {
        guard isActive(key) else { return false }
        return pressed.remove(button) != nil
    }
}
