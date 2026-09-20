import Foundation
import JoystickCore

/// Limpeza ao encerrar por Sair ou por sinal (RF-23, D-16, R-09). Só na main thread.
final class Lifecycle {
    private let context: InputContext
    private let buttons: ButtonActions
    private let shortcuts: ShortcutActions
    private var signalSources: [DispatchSourceSignal] = []
    private var cleanedUp = false
    /// Teclado remoto (`008-iphone-teclado-remoto` D-13, 001 RN-04): solto junto com o controle.
    var remote: RemoteKeyboardActions?
    /// Controle virtual do iPhone (`010-joystick-virtual-iphone` §5): solto pelo mesmo caminho.
    var virtualController: VirtualControllerActions?
    /// Chamado na main thread depois das solturas, para fechar os listeners do teclado remoto.
    var onCleanUp: (() -> Void)?

    init(context: InputContext, buttons: ButtonActions, shortcuts: ShortcutActions) {
        self.context = context
        self.buttons = buttons
        self.shortcuts = shortcuts
    }

    func start() {
        for (number, reason) in [(SIGTERM, TerminationReason.sigterm), (SIGINT, .sigint), (SIGHUP, .sighup)] {
            // Sem ignorar a forma padrão, o sinal encerraria o processo antes do DispatchSource.
            signal(number, SIG_IGN)
            let source = DispatchSource.makeSignalSource(signal: number, queue: .main)
            source.setEventHandler { [weak self] in
                self?.cleanUp(reason: reason)
                exit(0)
            }
            source.resume()
            signalSources.append(source)
        }
    }

    /// Solta os botões de mouse e as teclas, registra `app.terminating` e força o *flush* do log; só age uma vez.
    func cleanUp(reason: TerminationReason) {
        guard !cleanedUp else { return }
        cleanedUp = true
        let released = context.queue.sync { [remote, virtualController] in
            shortcuts.releaseAll()
            remote?.releaseAll()
            virtualController?.releaseAll()
            return buttons.releaseAll()
        }
        onCleanUp?()
        context.log.log(LogEventCatalog.appTerminating(reason: reason, releasedButtons: released))
        context.log.flushSync()
    }
}
