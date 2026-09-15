import CoreGraphics
import Foundation
import JoystickCore

/// Movimento e botões do mouse por `CGEvent` (D-10, RF-15 a RF-18, RN-10).
///
/// Todo acesso ocorre na fila `input`. Com a injeção desativada (D-15), os eventos são descartados.
final class EventInjector {
    /// Marca em `eventSourceUserData` que separa os eventos da PoC dos do mouse físico ("JOYS").
    static let sourceMark: Int64 = 0x4A4F_5953

    let eventSource: CGEventSource?
    private let log: DiagnosticLog

    /// Sem emissão por esse intervalo, o sistema já refletiu tudo e a leitura dele volta a valer.
    private static let resyncAfterNs: UInt64 = 100_000_000
    private static let recentLimit = 32
    private var trackedPosition: ScreenPoint?
    private var recentPositions: [ScreenPoint] = []
    private var lastPostNs: UInt64 = 0

    var enabled = false
    /// União dos retângulos das telas, mantida pelo `DisplayMonitor`.
    var screens = ScreenUnion(rects: [])

    init(log: DiagnosticLog) {
        self.log = log
        eventSource = CGEventSource(stateID: .hidSystemState)
    }

    /// Posição de onde partir a próxima emissão, que também reflete o mouse físico.
    ///
    /// `CGEvent(source: nil).location` só muda depois que o sistema processa o evento postado. O GameController
    /// chama o *handler* do touchpad uma vez por eixo, e a segunda emissão, lida logo após a primeira, partia da
    /// posição antiga e desfazia o movimento horizontal (achado da Fase 2). Enquanto a leitura do sistema for
    /// uma das posições que a própria PoC acabou de postar, vale a posição acompanhada; qualquer outra leitura
    /// vem do mouse físico e passa a valer.
    func currentLocation() -> ScreenPoint {
        let actual = systemLocation()
        if let tracked = trackedPosition,
           MonotonicClock.nowNs() &- lastPostNs < Self.resyncAfterNs,
           recentPositions.contains(actual) {
            return tracked
        }
        trackedPosition = nil
        recentPositions = [actual]
        return actual
    }

    private func systemLocation() -> ScreenPoint {
        let point = CGEvent(source: nil)?.location ?? .zero
        return ScreenPoint(x: Double(point.x), y: Double(point.y))
    }

    private func track(_ position: ScreenPoint) {
        trackedPosition = position
        recentPositions.append(position)
        if recentPositions.count > Self.recentLimit {
            recentPositions.removeFirst(recentPositions.count - Self.recentLimit)
        }
        lastPostNs = MonotonicClock.nowNs()
    }

    /// `origin` nulo nos ticks de 120 Hz, que não geram `pointer.posted` (D-19).
    func move(by delta: PointDelta, kind: MoveKind, origin: PostSource?, tArrival: UInt64?) {
        guard enabled else { return }
        let from = currentLocation()
        var to = ScreenPoint(x: from.x + delta.dx, y: from.y + delta.dy)
        if !screens.rects.isEmpty {
            to = screens.clamp(to)
        }
        let type: CGEventType
        let button: CGMouseButton
        let mouseButton: MouseButton?
        switch kind {
        case .move: (type, button, mouseButton) = (.mouseMoved, .left, nil)
        case .leftDrag: (type, button, mouseButton) = (.leftMouseDragged, .left, .left)
        case .rightDrag: (type, button, mouseButton) = (.rightMouseDragged, .right, .right)
        }
        guard let event = CGEvent(
            mouseEventSource: eventSource, mouseType: type, mouseCursorPosition: CGPoint(x: to.x, y: to.y), mouseButton: button)
        else { return }
        event.setIntegerValueField(.mouseEventDeltaX, value: Int64((to.x - from.x).rounded()))
        event.setIntegerValueField(.mouseEventDeltaY, value: Int64((to.y - from.y).rounded()))
        track(to)
        deliver(event, kind: kind == .move ? .move : .drag, button: mouseButton, origin: origin, clickState: nil, tArrival: tArrival)
    }

    func post(_ action: MouseAction, tArrival: UInt64) {
        guard enabled else { return }
        let type: CGEventType
        let button: MouseButton
        let clickState: Int
        let kind: PostedKind
        switch action {
        case .down(let b, let state):
            (type, button, clickState, kind) = (b == .left ? .leftMouseDown : .rightMouseDown, b, state, .down)
        case .up(let b, let state):
            (type, button, clickState, kind) = (b == .left ? .leftMouseUp : .rightMouseUp, b, state, .up)
        }
        let at = currentLocation()
        guard let event = CGEvent(
            mouseEventSource: eventSource, mouseType: type, mouseCursorPosition: CGPoint(x: at.x, y: at.y),
            mouseButton: button == .left ? .left : .right)
        else { return }
        event.setIntegerValueField(.mouseEventClickState, value: Int64(clickState))
        deliver(event, kind: kind, button: button, origin: .button, clickState: clickState, tArrival: tArrival)
    }

    /// Clique esquerdo em `point` e volta do cursor à posição anterior, sem registro.
    ///
    /// Usado pelo editor para se ativar (`003-editor-atalhos` E003): o macOS 26 recusa `NSApp.activate()` pedido pelo
    /// controle, mas um clique na janela, já posta por cima, ativa o app. As duas posições entram no acompanhamento,
    /// para o próximo movimento partir da posição restaurada.
    func activationClick(at point: CGPoint) {
        guard enabled else { return }
        let from = currentLocation()
        for type in [CGEventType.leftMouseDown, .leftMouseUp] {
            guard let event = CGEvent(mouseEventSource: eventSource, mouseType: type, mouseCursorPosition: point, mouseButton: .left)
            else { return }
            event.setIntegerValueField(.mouseEventClickState, value: 1)
            deliver(event)
        }
        guard let back = CGEvent(
            mouseEventSource: eventSource, mouseType: .mouseMoved, mouseCursorPosition: CGPoint(x: from.x, y: from.y),
            mouseButton: .left)
        else { return }
        deliver(back)
        track(ScreenPoint(x: Double(point.x), y: Double(point.y)))
        track(from)
    }

    /// Marca e posta sem registrar; usado pelo `KeyboardInjector`, cujas teclas e textos não vão ao log.
    func deliver(_ event: CGEvent) {
        event.setIntegerValueField(.eventSourceUserData, value: Self.sourceMark)
        event.post(tap: .cghidEventTap)
    }

    /// Marca, posta e registra; usado também pelo `ScrollInjector`.
    func deliver(_ event: CGEvent, kind: PostedKind, button: MouseButton?, origin: PostSource?, clickState: Int?, tArrival: UInt64?) {
        event.setIntegerValueField(.eventSourceUserData, value: Self.sourceMark)
        event.post(tap: .cghidEventTap)
        guard let origin, let tArrival else { return }
        let tPosted = MonotonicClock.nowNs()
        log.log(LogEventCatalog.pointerPosted(
            kind: kind, button: button, source: origin, clickState: clickState, tArrival: tArrival, tPosted: tPosted))
    }
}
