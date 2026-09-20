import Foundation

/// Botões que a página do iPhone pode enviar (`010-joystick-virtual-iphone` D-03, D-07,
/// `interfaces/remote-controller-protocol.md` §2).
///
/// `share` fica de fora: é do controle da feature 007 e não tem lugar no desenho da página. Os gatilhos chegam como
/// botão, sem valor analógico (D-07), porque a página não tem curso para medir.
public enum VirtualButton: String, CaseIterable, Sendable, Comparable {
    case cross, circle, square, triangle
    case dpadUp, dpadDown, dpadLeft, dpadRight
    case l1, r1, l2, r2, l3, r3
    case options, create, ps, touchpadClick

    /// Botão do controle físico correspondente; é por ele que o resto do aplicativo trata a entrada.
    public var buttonID: ButtonID {
        switch self {
        case .cross: .cross
        case .circle: .circle
        case .square: .square
        case .triangle: .triangle
        case .dpadUp: .dpadUp
        case .dpadDown: .dpadDown
        case .dpadLeft: .dpadLeft
        case .dpadRight: .dpadRight
        case .l1: .l1
        case .r1: .r1
        case .l2: .l2
        case .r2: .r2
        case .l3: .l3
        case .r3: .r3
        case .options: .options
        case .create: .create
        case .ps: .ps
        case .touchpadClick: .touchpadClick
        }
    }

    /// A ordem segue a de `ButtonID`, para que as solturas sintéticas saiam na mesma sequência das do controle (RN-04).
    public static func < (lhs: VirtualButton, rhs: VirtualButton) -> Bool { lhs.buttonID < rhs.buttonID }
}

public enum VirtualStick: String, CaseIterable, Sendable {
    case left = "l", right = "r"

    public var element: InputElement { self == .left ? .leftStick : .rightStick }
}

/// Posição bruta de um analógico da página, antes da zona morta (D-05): de −1,0 a 1,0, com o Y positivo para cima,
/// como a interface de controles entrega os analógicos do DualSense.
public struct StickSample: Equatable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public static let centered = StickSample(x: 0, y: 0)

    /// Limitada a ±1,0 nos dois eixos, sem zona morta (§4 do protocolo: fora do intervalo se limita, não se recusa).
    public var clamped: StickSample {
        StickSample(x: min(1.0, max(-1.0, x)), y: min(1.0, max(-1.0, y)))
    }
}

/// Dedo na área de apontamento, no mesmo formato que o touchpad do controle entrega (D-05).
public struct PadSample: Equatable, Sendable {
    /// Teto de dedos simultâneos; o touchpad do DualSense entrega dois, e a área da página aceita quatro.
    public static let maxFingers = 4

    public var finger: Int
    public var phase: TouchPhase
    public var x: Double
    public var y: Double

    public init(finger: Int, phase: TouchPhase, x: Double, y: Double) {
        self.finger = finger
        self.phase = phase
        self.x = x
        self.y = y
    }
}

/// Estado do bloco central da página (D-02): apontamento, teclado reduzido ou teclado completo.
public enum CenterMode: String, CaseIterable, Sendable {
    case pointer, compact, full

    /// Teclado é o que `compact` e `full` mostram; sair de um deles solta teclas e modificadores (D-08).
    public var isKeyboard: Bool { self != .pointer }
}
