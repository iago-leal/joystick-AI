import Foundation
import JoystickCore

/// Destino das entradas normalizadas. Chamado sempre na fila `input`.
protocol InputSink: AnyObject {
    func handle(_ event: InputEvent)
}

/// Destino da Fase 1: as entradas já foram registradas pelos leitores; aqui só vão ao log os erros.
final class LoggingInputSink: InputSink {
    private let log: DiagnosticLog

    init(log: DiagnosticLog) {
        self.log = log
    }

    func handle(_ event: InputEvent) {
        if event.kind == .controllerError {
            log.log(LogEventCatalog.controllerError(message: "erro reportado pela leitura do controle"))
        }
    }
}

/// Estado compartilhado da leitura do controle; todo acesso ocorre na fila `input` (D-04, D-09).
final class InputContext {
    let queue: DispatchQueue
    let log: DiagnosticLog
    var registry = ActiveControllerRegistry<ObjectIdentifier>()
    /// Botões mantidos pelo controle virtual do iPhone; fora do registro, que só descreve o hardware
    /// (`010-joystick-virtual-iphone` D-04, D-13). Mantido pelo `VirtualControllerActions`.
    var virtualPressed: Set<ButtonID> = []
    var settings: PointerSettings
    var sink: InputSink

    /// O que o resto do aplicativo consulta no lugar de `registry.pressed`: a união das duas origens, de modo que a
    /// precisão de L1, o clique com dois detentores e a tela de alvos valham com qualquer uma delas (D-04).
    var pressedAll: Set<ButtonID> { CombinedPressed(controller: registry.pressed, virtual: virtualPressed).all }

    init(queue: DispatchQueue, log: DiagnosticLog, settings: PointerSettings, sink: InputSink) {
        self.queue = queue
        self.log = log
        self.settings = settings
        self.sink = sink
    }

    func assertOnQueue() {
        dispatchPrecondition(condition: .onQueue(queue))
    }
}
