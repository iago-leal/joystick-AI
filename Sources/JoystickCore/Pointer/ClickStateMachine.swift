import Foundation

public enum MouseButton: String, Codable, Sendable, Comparable {
    case left, right

    public static func < (lhs: MouseButton, rhs: MouseButton) -> Bool { lhs == .left && rhs == .right }
}

public enum MouseAction: Equatable, Sendable {
    case down(MouseButton, clickState: Int)
    case up(MouseButton, clickState: Int)
}

public enum MoveKind: Equatable, Sendable {
    case move, leftDrag, rightDrag
}

/// Cliques, duplo clique e arraste (D-10, RN-09). R1 e o clique do touchpad fazem o botão esquerdo e R2 o direito:
/// inversão de RN-11 pedida pelo usuário no PM-3.
public struct ClickStateMachine: Sendable {
    public static let doubleClickDistancePt = 4.0

    public var settings: PointerSettings
    /// Botões de mouse pressionados pela PoC.
    public private(set) var heldMouseButtons: Set<MouseButton> = []
    /// Botões do controle que mantêm o clique esquerdo; o `mouseUp` só sai com o conjunto vazio.
    public private(set) var leftHolders: Set<ButtonID> = []
    /// Base de RN-09; o ponto fica só em memória, nunca no log.
    public private(set) var lastLeftClick: (timeNs: UInt64, point: ScreenPoint, clickState: Int)?
    private var currentLeftClickState = 1

    public init(settings: PointerSettings) {
        self.settings = settings
    }

    public var moveKind: MoveKind {
        if heldMouseButtons.contains(.left) { return .leftDrag }
        if heldMouseButtons.contains(.right) { return .rightDrag }
        return .move
    }

    public mutating func press(_ button: ButtonID, at point: ScreenPoint, timeNs: UInt64) -> MouseAction? {
        switch button {
        case .r1, .touchpadClick:
            let wasEmpty = leftHolders.isEmpty
            leftHolders.insert(button)
            guard wasEmpty else { return nil }
            currentLeftClickState = nextClickState(at: point, timeNs: timeNs)
            lastLeftClick = (timeNs, point, currentLeftClickState)
            heldMouseButtons.insert(.left)
            return .down(.left, clickState: currentLeftClickState)
        case .r2:
            guard heldMouseButtons.insert(.right).inserted else { return nil }
            return .down(.right, clickState: 1)
        default:
            return nil
        }
    }

    public mutating func release(_ button: ButtonID, at point: ScreenPoint, timeNs: UInt64) -> MouseAction? {
        switch button {
        case .r1, .touchpadClick:
            guard leftHolders.remove(button) != nil, leftHolders.isEmpty, heldMouseButtons.remove(.left) != nil else { return nil }
            return .up(.left, clickState: currentLeftClickState)
        case .r2:
            guard heldMouseButtons.remove(.right) != nil else { return nil }
            return .up(.right, clickState: 1)
        default:
            return nil
        }
    }

    /// Solta todo botão de mouse mantido (RN-04, RF-23, perda de permissão).
    public mutating func releaseAll() -> [MouseAction] {
        var actions: [MouseAction] = []
        if heldMouseButtons.contains(.left) { actions.append(.up(.left, clickState: currentLeftClickState)) }
        if heldMouseButtons.contains(.right) { actions.append(.up(.right, clickState: 1)) }
        heldMouseButtons.removeAll()
        leftHolders.removeAll()
        return actions
    }

    private func nextClickState(at point: ScreenPoint, timeNs: UInt64) -> Int {
        guard let last = lastLeftClick, timeNs >= last.timeNs else { return 1 }
        let intervalNs = UInt64(settings.doubleClickIntervalMs) * 1_000_000
        let distance = hypot(point.x - last.point.x, point.y - last.point.y)
        guard timeNs - last.timeNs <= intervalNs, distance <= Self.doubleClickDistancePt else { return 1 }
        return last.clickState + 1
    }
}
