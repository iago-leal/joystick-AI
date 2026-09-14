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
    private lazy var extendedReportActivator = ExtendedReportActivator(log: context.log)

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
        // O PS vem do relatório bruto; se o GameController também o entregar, o registro descarta a repetição.
        extendedReportActivator.onHomeButton = { [weak self] pressed, tArrival in
            guard let self else { return }
            self.context.queue.async {
                guard let key = self.context.registry.activeKey else { return }
                ButtonReader.deliver(.ps, pressed: pressed, value: nil, tArrival: tArrival, controller: nil, key: key, context: self.context)
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

        guard let gamepad = controller.extendedGamepad as? GCDualSenseGamepad else {
            ignored.insert(key)
            controllers[key] = controller
            context.log.log(LogEventCatalog.controllerIgnored(
                name: controller.vendorName ?? "desconhecido", productCategory: controller.productCategory, reason: "not_dualsense"))
            return
        }

        let elapsed = tArrival >= processStartNs ? tArrival - processStartNs : 0
        let info = ControllerInfo(
            id: UUID(),
            name: controller.vendorName ?? "DualSense",
            connection: TransportResolver.resolve(),
            connectedAt: tArrival,
            atStartup: StartupAdoption.isAtStartup(source: source, elapsedNs: elapsed))
        let outcome = context.registry.connect(key: key, info: info, isDualSense: true)
        guard outcome != .duplicate else { return }

        controllers[key] = controller
        controller.handlerQueue = context.queue
        context.log.log(LogEventCatalog.controllerConnected(info, tArrival: tArrival))
        if case .queued(let position) = outcome {
            context.log.log(LogEventCatalog.controllerQueued(id: info.id, position: position))
        }

        ButtonReader.attach(controller: controller, gamepad: gamepad, key: key, info: info, context: context)
        AxisTouchReader.attach(controller: controller, gamepad: gamepad, key: key, info: info, context: context)
        ControllerDiagnostics.attach(controller: controller, gamepad: gamepad, context: context)
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
    }
}
