import Foundation
import JoystickCore

/// Suspende e retoma a injeção conforme a Acessibilidade (RF-22, D-15, R-08).
final class InjectionGate {
    private let context: InputContext
    private let injector: EventInjector
    private let buttons: ButtonActions
    private let shortcuts: ShortcutActions
    private let palette: PaletteActions
    private var allowed: Bool?
    /// Solturas feitas na suspensão, que o sistema provavelmente descartou; repetidas na retomada.
    private var pendingMouseReleases: [MouseButton] = []
    private var pendingKeyReleases: [ShortcutAction] = []
    private var pendingRemoteReleases: [RemoteRelease] = []

    /// Chamado na main thread quando a injeção é suspensa.
    var onSuspended: (() -> Void)?
    /// Teclado remoto (`008-iphone-teclado-remoto` D-13): solto na suspensão, com as solturas repetidas na retomada.
    var remote: RemoteKeyboardActions?
    /// Controle virtual do iPhone: solto com a injeção suspensa, para não deixar botão preso na união (D-04).
    var virtualController: VirtualControllerActions?
    /// Chamado na fila `input` com o estado inicial e a cada mudança, para avisar a página (RN-11, RF-10).
    var onAllowedChange: ((Bool) -> Void)?

    init(context: InputContext, injector: EventInjector, buttons: ButtonActions, shortcuts: ShortcutActions, palette: PaletteActions) {
        self.context = context
        self.injector = injector
        self.buttons = buttons
        self.shortcuts = shortcuts
        self.palette = palette
    }

    /// Pode ser chamado de qualquer fila.
    func setAllowed(_ value: Bool) {
        context.queue.async { [self] in
            let previous = allowed
            allowed = value
            guard let previous else {
                // Estado inicial: sem suspensão nem retomada a registrar.
                injector.enabled = value
                onAllowedChange?(value)
                return
            }
            guard previous != value else { return }
            if value {
                injector.enabled = true
                // A revogação já descartava os eventos quando a PoC soltou os botões; sem repetir, o sistema
                // ficaria com botão de mouse ou Command pressionado.
                buttons.postReleases(pendingMouseReleases)
                shortcuts.repeatReleases(pendingKeyReleases)
                remote?.repeatReleases(pendingRemoteReleases)
                pendingMouseReleases = []
                pendingKeyReleases = []
                pendingRemoteReleases = []
                context.log.log(LogEventCatalog.injectionResumed(heldButtons: []))
            } else {
                // A paleta fecha sem digitar (`002-paleta-comandos` RF-09, D-12).
                palette.close(.injectionSuspended)
                // Solta antes de desativar, para não deixar botão de mouse preso quando a permissão voltar.
                pendingKeyReleases = shortcuts.releaseAll()
                pendingRemoteReleases = remote?.releaseAll() ?? []
                virtualController?.releaseAll()
                let held = buttons.releaseAll()
                pendingMouseReleases = held
                injector.enabled = false
                context.log.log(LogEventCatalog.injectionSuspended(heldButtons: held))
                DispatchQueue.main.async { self.onSuspended?() }
            }
            onAllowedChange?(value)
        }
    }
}
