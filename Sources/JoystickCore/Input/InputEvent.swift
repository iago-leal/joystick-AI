import Foundation

/// Os 18 identificadores de botão do DualSense (RF-05, `data-delta.md` §1.1).
public enum ButtonID: String, CaseIterable, Codable, Sendable, Comparable {
    case cross, circle, square, triangle
    case l1, r1, l2, r2, l3, r3
    case options, create, ps, touchpadClick
    case dpadUp, dpadDown, dpadLeft, dpadRight

    private var order: Int { Self.allCases.firstIndex(of: self)! }

    public static func < (lhs: ButtonID, rhs: ButtonID) -> Bool { lhs.order < rhs.order }
}

public enum ButtonPhase: String, Sendable {
    case down, up
}

/// Fase de um toque no touchpad; necessária para RN-05 (D-05).
public enum TouchPhase: String, Sendable {
    case began, moved, ended
}

public enum ConnectionType: String, Codable, Sendable {
    case usb, bluetooth, unknown
}

/// Controle conectado (`controller-input` §9, sem bateria).
public struct ControllerInfo: Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let connection: ConnectionType
    /// `t_arrival` da conexão; ordena a fila de RN-01.
    public let connectedAt: UInt64
    /// Veio da enumeração inicial ou de notificação nos primeiros 2 s do processo (D-25).
    public let atStartup: Bool

    public init(id: UUID, name: String, connection: ConnectionType, connectedAt: UInt64, atStartup: Bool) {
        self.id = id
        self.name = name
        self.connection = connection
        self.connectedAt = connectedAt
        self.atStartup = atStartup
    }
}

/// Elemento de origem de uma entrada.
public enum InputElement: Equatable, Sendable {
    case button(ButtonID)
    case leftStick
    case rightStick
    case touch(Int)
}

public enum InputEventKind: String, Sendable {
    case controllerConnected, controllerDisconnected
    case buttonDown, buttonUp
    case axis, touch
    case controllerError
}

/// Entrada normalizada entregue pela leitura do controle (`controller-input` §9).
public struct InputEvent: Equatable, Sendable {
    public var kind: InputEventKind
    public var element: InputElement?
    /// Gatilhos, de 0,0 a 1,0.
    public var value: Double?
    /// Analógicos (com zona morta aplicada) e toque; nunca vão ao log (RN-12).
    public var x: Double?
    public var y: Double?
    public var touchIndex: Int?
    public var touchPhase: TouchPhase?
    /// `buttonUp` gerado por RN-04 antes da desconexão.
    public var synthetic: Bool
    /// `t_arrival`, em nanossegundos de `CLOCK_UPTIME_RAW`.
    public var timestamp: UInt64
    /// `lastEventTimestamp` do perfil físico, apenas informativo.
    public var frameworkTimestamp: Double?

    public init(
        kind: InputEventKind, element: InputElement? = nil, value: Double? = nil, x: Double? = nil, y: Double? = nil,
        touchIndex: Int? = nil, touchPhase: TouchPhase? = nil, synthetic: Bool = false, timestamp: UInt64,
        frameworkTimestamp: Double? = nil
    ) {
        self.kind = kind
        self.element = element
        self.value = value
        self.x = x
        self.y = y
        self.touchIndex = touchIndex
        self.touchPhase = touchPhase
        self.synthetic = synthetic
        self.timestamp = timestamp
        self.frameworkTimestamp = frameworkTimestamp
    }
}
