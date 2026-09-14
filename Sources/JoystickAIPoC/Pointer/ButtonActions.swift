import Foundation
import JoystickCore

/// Botões do controle convertidos em cliques pelo mapeamento fixo de RN-11 (RF-10, RF-15 a RF-19, RN-04).
///
/// Todo acesso ocorre na fila `input`.
final class ButtonActions {
    private let injector: EventInjector
    private var clicks: ClickStateMachine

    init(injector: EventInjector, settings: PointerSettings) {
        self.injector = injector
        clicks = ClickStateMachine(settings: settings)
    }

    var moveKind: MoveKind { clicks.moveKind }

    func handle(_ event: InputEvent) {
        switch event.kind {
        case .buttonDown, .buttonUp:
            guard case .button(let button)? = event.element else { return }
            let point = injector.currentLocation()
            let action = event.kind == .buttonDown
                ? clicks.press(button, at: point, timeNs: event.timestamp)
                : clicks.release(button, at: point, timeNs: event.timestamp)
            if let action {
                injector.post(action, tArrival: event.timestamp)
            }
        case .controllerDisconnected:
            // Chega antes do registro de `controller.disconnected` (RN-04).
            releaseAll()
        default:
            break
        }
    }

    /// Posta de novo o `mouseUp` de botões já soltos pela máquina de cliques (retomada após perda de permissão).
    func postReleases(_ released: [MouseButton]) {
        let now = MonotonicClock.nowNs()
        for button in released {
            injector.post(.up(button, clickState: 1), tArrival: now)
        }
    }

    /// Solta os botões de mouse mantidos e devolve quais eram.
    @discardableResult
    func releaseAll() -> [MouseButton] {
        let now = MonotonicClock.nowNs()
        return clicks.releaseAll().map { action in
            injector.post(action, tArrival: now)
            switch action {
            case .down(let button, _), .up(let button, _): return button
            }
        }
    }
}
