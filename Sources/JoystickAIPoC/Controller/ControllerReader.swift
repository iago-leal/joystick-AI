import Foundation
import GameController
import JoystickCore

/// Conexão, adoção, desconexão e controle ativo (D-04, D-25, RF-01 a RF-04, RF-09).
final class ControllerReader {
    private let context: InputContext
    private let processStartNs: UInt64
    private var controllers: [ObjectIdentifier: GCController] = [:]
    private var ignored: Set<ObjectIdentifier> = []
    private var observers: [NSObjectProtocol] = []
    /// Última amostra entregue de cada analógico do Ipega ativo, por controle; só na fila `input`.
    private var ipegaStickStates: [ObjectIdentifier: (left: AxisTouchReader.StickState, right: AxisTouchReader.StickState)] = [:]
    private lazy var extendedReportActivator = ExtendedReportActivator(log: context.log)
    /// Modelo e carga do controle ativo, publicados juntos na main thread após conexão, desconexão e promoção;
    /// ausentes sem controle (`007-controle-ipega` D-08, `011-bateria-e-cursor-no-menu` D-05). Um canal só evita
    /// dois caminhos concorrentes de verdade sobre o mesmo controle ativo. Deve ser atribuído antes de `start()`.
    var onActiveControllerChange: ((ActiveController?) -> Void)?

    /// O que o canal leva: o modelo, a carga no instante da publicação e o identificador da conexão, que a
    /// política de registro do log usa para não herdar a faixa do controle anterior.
    ///
    /// Leva também o próprio controle, para que o consultor periódico releia a carga da main thread sem voltar à
    /// fila de entrada. A referência serve **só** à leitura da propriedade de bateria: tudo o mais que se faz com
    /// um `GCController` continua acontecendo na fila `input`, onde o `handlerQueue` o coloca.
    struct ActiveController {
        var id: UUID
        var model: ControllerModel
        var charge: ControllerCharge?
        var device: GCController?
    }

    init(context: InputContext, processStartNs: UInt64) {
        self.context = context
        self.processStartNs = processStartNs
    }

    /// Deve ser chamado na main thread, uma única vez.
    func start() {
        // Antes de qualquer observador: sem isso, as entradas só chegam com o app em primeiro plano.
        GCController.shouldMonitorBackgroundEvents = true

        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: .GCControllerDidConnect, object: nil, queue: nil) { [weak self] note in
            let tArrival = MonotonicClock.nowNs()
            guard let self, let controller = note.object as? GCController else { return }
            self.context.queue.async { self.connect(controller, source: .notification, tArrival: tArrival) }
        })
        observers.append(center.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: nil) { [weak self] note in
            let tArrival = MonotonicClock.nowNs()
            guard let self, let controller = note.object as? GCController else { return }
            self.context.queue.async { self.disconnect(controller, tArrival: tArrival) }
        })

        // Por Bluetooth, sem este pedido o DualSense não envia o touchpad.
        // O PS do DualSense e do DualShock 4 e o Home do Ipega vêm do relatório bruto; se o GameController também os
        // entregar, o registro descarta a repetição. Só o emissor do mesmo modelo do ativo conta (RN-01).
        extendedReportActivator.onHomeButton = { [weak self] pressed, model, tArrival in
            guard let self else { return }
            self.context.queue.async {
                guard let key = self.context.registry.activeKey, self.context.registry.active?.model == model else { return }
                ButtonReader.deliver(.ps, pressed: pressed, value: nil, tArrival: tArrival, controller: nil, key: key, context: self.context)
            }
        }
        // Os analógicos do Ipega vêm do relatório bruto; valem só com um Ipega ativo (revisão de D-03 no PM-1).
        extendedReportActivator.onIpegaSticks = { [weak self] left, right, tArrival in
            guard let self else { return }
            self.context.queue.async {
                guard let key = self.context.registry.activeKey, self.context.registry.active?.model == .ipega,
                      let states = self.ipegaStickStates[key] else { return }
                for (element, stick, state) in [(InputElement.leftStick, left, states.left), (.rightStick, right, states.right)] {
                    AxisTouchReader.deliverStick(element, x: stick.x, y: stick.y, tArrival: tArrival, state: state, key: key, context: self.context)
                }
            }
        }
        extendedReportActivator.start()

        // Só depois dos observadores: um controle que chegue pelas duas vias é deduplicado pela identidade.
        let existing = GCController.controllers()
        let tArrival = MonotonicClock.nowNs()
        context.queue.async {
            for controller in existing {
                self.connect(controller, source: .enumeration, tArrival: tArrival)
            }
        }
    }

    // MARK: fila `input`

    private func connect(_ controller: GCController, source: ConnectionSource, tArrival: UInt64) {
        context.assertOnQueue()
        let key = ObjectIdentifier(controller)
        guard controllers[key] == nil, !ignored.contains(key) else { return }

        // RN-01: DualSense pelo perfil; DualShock 4 pelo perfil e por um par Sony do modelo no IORegistry; Ipega pela
        // categoria e pelo par no IORegistry (`007-controle-ipega` D-01, `012-controle-dualshock-4` D-01). O IORegistry
        // só é consultado quando o perfil não decide sozinho.
        let gamepad = controller.extendedGamepad
        let profile: ControllerModel.SystemProfile = if gamepad is GCDualSenseGamepad {
            .dualSense
        } else if gamepad is GCDualShockGamepad {
            .dualShock
        } else {
            .extended
        }
        let model = gamepad == nil ? nil : ControllerModel.classify(
            productCategory: controller.productCategory, profile: profile,
            hidDevices: profile == .dualSense ? [] : TransportResolver.presentDevices())
        guard let gamepad, let model else {
            ignored.insert(key)
            controllers[key] = controller
            context.log.log(LogEventCatalog.controllerIgnored(
                name: controller.vendorName ?? "desconhecido", productCategory: controller.productCategory, reason: "unsupported_model"))
            return
        }

        let elapsed = tArrival >= processStartNs ? tArrival - processStartNs : 0
        // Nome padrão por modelo, só quando o sistema não informa `vendorName` (`012-controle-dualshock-4` D-06).
        let defaultName = switch model {
        case .dualSense: "DualSense"
        case .ipega: "Pro Controller"
        case .dualShock4: "DualShock 4"
        }
        let info = ControllerInfo(
            id: UUID(),
            name: controller.vendorName ?? defaultName,
            connection: TransportResolver.resolve(for: model),
            connectedAt: tArrival,
            atStartup: StartupAdoption.isAtStartup(source: source, elapsedNs: elapsed),
            model: model)
        let outcome = context.registry.connect(key: key, info: info, accepted: true)
        guard outcome != .duplicate else { return }

        controllers[key] = controller
        controller.handlerQueue = context.queue
        context.log.log(LogEventCatalog.controllerConnected(info, charge: Self.charge(of: controller), tArrival: tArrival))
        if case .queued(let position) = outcome {
            context.log.log(LogEventCatalog.controllerQueued(id: info.id, position: position))
        }

        if model == .ipega { ipegaStickStates[key] = (AxisTouchReader.StickState(), AxisTouchReader.StickState()) }
        ButtonReader.attach(controller: controller, gamepad: gamepad, model: model, key: key, info: info, context: context)
        AxisTouchReader.attach(controller: controller, gamepad: gamepad, model: model, key: key, info: info, context: context)
        ControllerDiagnostics.attach(controller: controller, gamepad: gamepad, context: context)
        if outcome == .active { publishActiveController() }
    }

    private func disconnect(_ controller: GCController, tArrival: UInt64) {
        context.assertOnQueue()
        let key = ObjectIdentifier(controller)
        if ignored.remove(key) != nil {
            controllers[key] = nil
            return
        }
        let outcome = context.registry.disconnect(key: key)
        guard let removed = outcome.removed else { return }

        // RN-04: todo botão ainda pressionado é solto antes de o controle ser dado por desconectado.
        for button in outcome.syntheticReleases {
            let tDelivered = MonotonicClock.nowNs()
            context.log.log(LogEventCatalog.inputButton(
                button, phase: .up, synthetic: true, tArrival: tArrival, tDelivered: tDelivered, tFramework: nil))
            context.sink.handle(InputEvent(kind: .buttonUp, element: .button(button), synthetic: true, timestamp: tArrival))
        }
        if outcome.wasActive {
            context.sink.handle(InputEvent(kind: .controllerDisconnected, synthetic: false, timestamp: tArrival))
        }
        context.log.log(LogEventCatalog.controllerDisconnected(id: removed.id, tArrival: tArrival))
        controllers[key] = nil
        ipegaStickStates[key] = nil
        if outcome.wasActive { publishActiveController() }
    }

    /// Leva o ativo (o promovido, se houver) à main thread, com modelo e carga no mesmo envio.
    private func publishActiveController() {
        guard let onActiveControllerChange else { return }
        let current = activeController()
        DispatchQueue.main.async { onActiveControllerChange(current) }
    }

    /// Leitura do controle ativo, na fila `input`. Devolve a ausência quando não há ativo.
    private func activeController() -> ActiveController? {
        guard let info = context.registry.active, let key = context.registry.activeKey else { return nil }
        let device = controllers[key]
        return ActiveController(id: info.id, model: info.model, charge: device.flatMap(Self.charge(of:)), device: device)
    }

    /// Traduz a propriedade de bateria do sistema para o tipo do núcleo (D-01).
    ///
    /// A propriedade existe desde macOS 11, abaixo do mínimo de macOS 13 do projeto, e por isso não há verificação
    /// de versão em tempo de execução. Seu nível tem padrão 0 e seu estado tem padrão desconhecido, de modo que a
    /// ausência de informação chega como estado desconhecido, e não como propriedade ausente; quem trata disso é
    /// `ChargeDisplay.decide`, nunca esta função (D-02).
    ///
    /// Chamável da main thread pelo consultor periódico: é leitura de propriedade, sem estado do leitor e sem
    /// tocar o registro do controle ativo, e por isso não entra no caminho de tempo real que RN-11 protege.
    static func charge(of controller: GCController) -> ControllerCharge? {
        guard let battery = controller.battery else { return nil }
        let state: ControllerChargeState = switch battery.batteryState {
        case .discharging: .discharging
        case .charging: .charging
        case .full: .full
        default: .unknown
        }
        return ControllerCharge(level: Double(battery.batteryLevel), state: state)
    }
}
