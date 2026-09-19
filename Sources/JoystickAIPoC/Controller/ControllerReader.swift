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
    /// Modelo do controle ativo, publicado na main thread após conexão, desconexão e promoção; `nil` sem controle
    /// (`007-controle-ipega` D-08). Deve ser atribuído antes de `start()`.
    var onActiveModelChange: ((ControllerModel?) -> Void)?

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
        // O PS e o Home do Ipega vêm do relatório bruto; se o GameController também os entregar, o registro descarta
        // a repetição. Só o emissor do mesmo modelo do ativo conta (RN-01).
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

        // RN-01: DualSense pelo perfil; Ipega pela categoria e pelo par no IORegistry (`007-controle-ipega` D-01).
        let gamepad = controller.extendedGamepad
        let isDualSense = gamepad is GCDualSenseGamepad
        let model = gamepad == nil ? nil : ControllerModel.classify(
            productCategory: controller.productCategory, isDualSenseProfile: isDualSense,
            hidDevices: isDualSense ? [] : TransportResolver.presentDevices())
        guard let gamepad, let model else {
            ignored.insert(key)
            controllers[key] = controller
            context.log.log(LogEventCatalog.controllerIgnored(
                name: controller.vendorName ?? "desconhecido", productCategory: controller.productCategory, reason: "unsupported_model"))
            return
        }

        let elapsed = tArrival >= processStartNs ? tArrival - processStartNs : 0
        let info = ControllerInfo(
            id: UUID(),
            name: controller.vendorName ?? (model == .dualSense ? "DualSense" : "Pro Controller"),
            connection: TransportResolver.resolve(for: model),
            connectedAt: tArrival,
            atStartup: StartupAdoption.isAtStartup(source: source, elapsedNs: elapsed),
            model: model)
        let outcome = context.registry.connect(key: key, info: info, accepted: true)
        guard outcome != .duplicate else { return }

        controllers[key] = controller
        controller.handlerQueue = context.queue
        context.log.log(LogEventCatalog.controllerConnected(info, tArrival: tArrival))
        if case .queued(let position) = outcome {
            context.log.log(LogEventCatalog.controllerQueued(id: info.id, position: position))
        }

        if model == .ipega { ipegaStickStates[key] = (AxisTouchReader.StickState(), AxisTouchReader.StickState()) }
        ButtonReader.attach(controller: controller, gamepad: gamepad, model: model, key: key, info: info, context: context)
        AxisTouchReader.attach(controller: controller, gamepad: gamepad, model: model, key: key, info: info, context: context)
        ControllerDiagnostics.attach(controller: controller, gamepad: gamepad, context: context)
        if outcome == .active { publishActiveModel() }
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
        if outcome.wasActive { publishActiveModel() }
    }

    /// Leva o modelo do ativo (o promovido, se houver) à main thread.
    private func publishActiveModel() {
        let model = context.registry.active?.model
        guard let onActiveModelChange else { return }
        DispatchQueue.main.async { onActiveModelChange(model) }
    }
}
