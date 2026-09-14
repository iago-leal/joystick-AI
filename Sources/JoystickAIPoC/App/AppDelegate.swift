import AppKit
import JoystickCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    /// Tomado na criação do delegate, antes de `NSApplication.run()`: base da janela de 2 s de D-25.
    private let processStartNs = MonotonicClock.nowNs()
    private let inputQueue = DispatchQueue(label: "input", qos: .userInteractive)
    private var log: DiagnosticLog!
    private var permissionMonitor: PermissionMonitor!
    private var inputContext: InputContext!
    private var controllerReader: ControllerReader!
    private var injector: EventInjector!
    private var buttonActions: ButtonActions!
    private var shortcutActions: ShortcutActions!
    private var motionLoop: MotionLoop!
    private var router: InputRouter!
    private var gate: InjectionGate!
    private var lifecycle: Lifecycle!
    private var displayMonitor: DisplayMonitor!
    private var targetSession: TargetSession?
    private var targetAbortMonitor: TargetAbortMonitor?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if anotherInstanceIsRunning() {
            NSApp.terminate(nil)
            return
        }

        let rawArguments = Array(CommandLine.arguments.dropFirst())
        let arguments = LaunchArguments.parse(rawArguments)
        log = DiagnosticLog(debug: arguments.debug)
        log.log(LogEventCatalog.sessionStart(
            appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev",
            macOS: ProcessInfo.processInfo.operatingSystemVersionString,
            pid: ProcessInfo.processInfo.processIdentifier,
            debug: log.debugEnabled,
            args: rawArguments,
            signing: SigningInfo.current().jsonValue))

        // Configuração antes da leitura do controle; o arquivo nunca é criado pela PoC (RF-26).
        let config = ConfigLoader.load(from: ConfigLoader.defaultURL)
        LogEventCatalog.config(config).forEach(log.log)
        let settings = config.settings

        injector = EventInjector(log: log)
        let scrollInjector = ScrollInjector(injector: injector, unit: arguments.scrollUnit)
        inputContext = InputContext(queue: inputQueue, log: log, settings: settings, sink: LoggingInputSink(log: log))
        buttonActions = ButtonActions(injector: injector, settings: settings)
        motionLoop = MotionLoop(context: inputContext, injector: injector, scrollInjector: scrollInjector, buttons: buttonActions)
        // Protótipo de atalhos pedido no PM-3, fora do escopo da PoC (`action-mapping`).
        shortcutActions = ShortcutActions(context: inputContext, keyboard: KeyboardInjector(injector: injector))
        router = InputRouter(buttons: buttonActions, motion: motionLoop, shortcuts: shortcutActions)
        inputContext.sink = router
        gate = InjectionGate(context: inputContext, injector: injector, buttons: buttonActions, shortcuts: shortcutActions)

        lifecycle = Lifecycle(context: inputContext, buttons: buttonActions, shortcuts: shortcutActions)
        lifecycle.start()

        displayMonitor = DisplayMonitor(log: log, injector: injector, inputQueue: inputQueue)
        displayMonitor.start()
        ScreenCatalog.emit(log: log)

        permissionMonitor = PermissionMonitor(log: log)
        permissionMonitor.onInjectionEnabledChange = { [gate] allowed in gate?.setAllowed(allowed) }
        permissionMonitor.start()

        controllerReader = ControllerReader(context: inputContext, processStartNs: processStartNs)
        controllerReader.start()

        if arguments.targets {
            openTargets(arguments: arguments, settings: settings)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        lifecycle?.cleanUp(reason: .quit)
    }

    /// `targets.screens` já foi registrado; aqui só a validação e a abertura (RF-27, D-20).
    private func openTargets(arguments: LaunchArguments, settings: PointerSettings) {
        for error in arguments.errors {
            switch error {
            case .invalidScreen: continue
            default: log.log(LogEventCatalog.targetsInvalidArgs(message: error.message))
            }
        }
        guard let environment = arguments.env else { return }

        let screens = NSScreen.screens
        guard !screens.isEmpty else {
            log.log(LogEventCatalog.targetsInvalidArgs(message: "nenhuma tela ativa"))
            return
        }
        var index = arguments.screen
        let invalidScreen = arguments.errors.first { if case .invalidScreen = $0 { true } else { false } }
        if let invalidScreen {
            log.log(LogEventCatalog.targetsScreenFallback(message: invalidScreen.message + "; usando a tela 1"))
            index = 1
        } else if index > screens.count {
            log.log(LogEventCatalog.targetsScreenFallback(
                message: "--screen \(index) fora da faixa de 1 a \(screens.count); usando a tela 1"))
            index = 1
        }
        let seed = arguments.seed ?? UInt64.random(in: 0...UInt64(UInt32.max))

        let session = TargetSession(
            log: log, writer: TargetRunWriter(log: log), context: inputContext, screen: screens[index - 1],
            environment: environment, seed: seed, settings: settings, scrollUnit: arguments.scrollUnit)
        let abortMonitor = TargetAbortMonitor(
            session: session, context: inputContext, router: router, displayMonitor: displayMonitor, gate: gate)
        session.onFinish = { [weak self] in
            self?.targetAbortMonitor?.stop()
            self?.targetAbortMonitor = nil
            self?.targetSession = nil
        }
        targetSession = session
        targetAbortMonitor = abortMonitor
        abortMonitor.start()
        session.start()
    }

    private func anotherInstanceIsRunning() -> Bool {
        guard let bundleID = Bundle.main.bundleIdentifier else { return false }
        let ownPID = ProcessInfo.processInfo.processIdentifier
        return NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            .contains { $0.processIdentifier != ownPID }
    }
}
