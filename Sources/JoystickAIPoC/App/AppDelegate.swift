import AppKit
import JoystickCore
import SwiftUI

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
    private var paletteActions: PaletteActions!
    private var palettePanel: PalettePanel!
    private var configStore: ConfigStore!
    private var configWatcher: ConfigWatcher!
    private var statusMenu: StatusMenu!
    private var editorModel: EditorViewModel!
    private var figureBridge: FigureBridge!
    private var editorWindow: EditorWindowController!
    private var motionLoop: MotionLoop!
    private var router: InputRouter!
    private var gate: InjectionGate!
    private var lifecycle: Lifecycle!
    private var displayMonitor: DisplayMonitor!
    private var remoteActions: RemoteKeyboardActions!
    private var remoteService: RemoteKeyboardService!
    private var virtualController: VirtualControllerActions!
    private var layoutReader: KeyboardLayoutReader!
    private var appActivationObserver: NSObjectProtocol?
    private var pairingWindow: PairingWindow!
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

        // Configuração antes da leitura do controle; o arquivo só é criado ao salvar pelo editor (`003-editor-atalhos` RN-10).
        // `pointer` é lido só aqui; atalhos e paleta ficam com o `ConfigStore`, que os relê a cada alteração (D-15).
        let config = ConfigLoader.load(from: ConfigLoader.defaultURL)
        LogEventCatalog.config(config).forEach(log.log)
        let settings = config.settings
        configStore = ConfigStore(url: ConfigLoader.defaultURL, log: log)
        configStore.start(with: config)
        let shortcuts = configStore.state.current

        injector = EventInjector(log: log)
        let scrollInjector = ScrollInjector(injector: injector, unit: arguments.scrollUnit)
        inputContext = InputContext(queue: inputQueue, log: log, settings: settings, sink: LoggingInputSink(log: log))
        buttonActions = ButtonActions(injector: injector, settings: settings)
        motionLoop = MotionLoop(context: inputContext, injector: injector, scrollInjector: scrollInjector, buttons: buttonActions)
        // Atalhos pela configuração vigente (`003-editor-atalhos` D-09).
        // Um único injetor de teclado, para uma só contagem de modificadores (`002-paleta-comandos` D-05).
        let keyboard = KeyboardInjector(injector: injector)
        shortcutActions = ShortcutActions(context: inputContext, keyboard: keyboard, config: shortcuts.shortcuts)

        // Paleta de comandos (`002-paleta-comandos`): painel criado oculto, para abrir sem atraso (D-08).
        for error in arguments.errors where error.concernsPalette {
            log.log(LogEventCatalog.paletteInvalidArgs(message: error.message))
        }
        palettePanel = PalettePanel(items: shortcuts.palette)
        paletteActions = PaletteActions(
            context: inputContext, keyboard: keyboard,
            enterDelayMs: arguments.paletteEnterDelayMs ?? PaletteActions.defaultEnterDelayMs, items: shortcuts.palette)
        paletteActions.onRender = { [palettePanel] snapshot in palettePanel?.show(snapshot) }
        paletteActions.onItems = { [palettePanel] items in palettePanel?.update(items: items) }
        shortcutActions.onOpenPalette = { [paletteActions] in paletteActions?.open() }

        // Configuração nova aplicada na fila `input`: primeiro a paleta, depois os atalhos (D-12).
        configStore.onApply = { [inputQueue, paletteActions, shortcutActions] document in
            inputQueue.async {
                paletteActions?.apply(items: document.palette)
                shortcutActions?.apply(document.shortcuts)
            }
        }

        // Editor de atalhos (`003-editor-atalhos`): ícone na barra de menus e entrada fixa da paleta (D-18, D-13).
        let editorModel = EditorViewModel(store: configStore, log: log)
        self.editorModel = editorModel
        // Figura do controle em página web (`004-figura-controle-web` D-05): uma ponte por processo, carregada uma vez.
        let figureBridge = FigureBridge(model: editorModel, log: log)
        self.figureBridge = figureBridge
        editorWindow = EditorWindowController(
            log: log,
            activateByClick: { [injector, inputQueue] point in inputQueue.async { injector?.activationClick(at: point) } }
        ) { AnyView(EditorRootView(model: editorModel, figure: figureBridge)) }
        editorWindow.onWillShow = { [weak editorModel] in editorModel?.prepareForOpen() }
        editorWindow.isDirty = { [weak editorModel] in editorModel?.draft.isDirty ?? false }
        editorWindow.saveForClose = { [weak editorModel] in editorModel?.save() ?? true }
        editorWindow.discardForClose = { [weak editorModel] in editorModel?.discard() }
        editorWindow.onIdentifyOff = { [weak editorModel] in editorModel?.identifying = false }
        EditMenu.install()
        statusMenu = StatusMenu()
        statusMenu.onEditShortcuts = { [editorWindow] in editorWindow?.show(source: .menu) }
        statusMenu.onOpenFromAlert = { [editorWindow] in editorWindow?.show(source: .alert) }
        statusMenu.update(status: configStore.state.status)
        configStore.addObserver { [statusMenu] state, _ in statusMenu?.update(status: state.status) }
        paletteActions.onOpenEditor = { [editorWindow] in editorWindow?.show(source: .palette) }

        // Alterações externas do arquivo, sem varredura (D-16, RF-03).
        configWatcher = ConfigWatcher(url: ConfigLoader.defaultURL) { [configStore] in configStore?.reload(trigger: .external) }
        configWatcher.start()

        router = InputRouter(buttons: buttonActions, motion: motionLoop, shortcuts: shortcutActions, palette: paletteActions)
        // Modo de identificação do editor (D-24): o botão pressionado seleciona o cartão, e o estado vai à fila `input`.
        router.onIdentify = { [weak editorModel] button in editorModel?.identified(button) }
        editorModel.onIdentifyingChange = { [router, inputQueue, log] on in
            log?.log(LogEventCatalog.editorIdentify(on: on))
            inputQueue.async { router?.setIdentifying(on) }
        }
        inputContext.sink = router
        gate = InjectionGate(
            context: inputContext, injector: injector, buttons: buttonActions, shortcuts: shortcutActions, palette: paletteActions)

        lifecycle = Lifecycle(context: inputContext, buttons: buttonActions, shortcuts: shortcutActions)
        lifecycle.start()

        // Teclado remoto (`008-iphone-teclado-remoto`): mesmo injetor de teclado do controle, para uma só contagem de
        // modificadores (D-09, RN-08); desligado a cada abertura (RN-02) e ligado só pelo menu (D-14).
        remoteActions = RemoteKeyboardActions(
            context: inputContext, keyboard: keyboard, translator: KeyTextTranslator(),
            geometry: .standard(KeyboardLayoutReader.physicalLayout))
        // Controle virtual do iPhone (`010-joystick-virtual-iphone` D-03): mesma fila e mesmo roteador do controle
        // físico, sem entrar na fila de controles (D-13).
        virtualController = VirtualControllerActions(context: inputContext)
        layoutReader = KeyboardLayoutReader()
        let remoteResources = Bundle.main.resourceURL?.appendingPathComponent("RemoteKeyboard", isDirectory: true)
        remoteService = RemoteKeyboardService(
            context: inputContext, actions: remoteActions, controller: virtualController,
            suggester: WordSuggester(queue: inputQueue), layoutReader: layoutReader,
            resources: remoteResources.flatMap { FileManager.default.fileExists(atPath: $0.path) ? $0 : nil })
        // Sugestões (`009-sugestao-de-palavras` D-06): entrada do controle e troca do aplicativo em foco podem mover o
        // ponto de escrita sem o app saber, e descartam o contexto recente.
        router.onControllerButtonDown = { [remoteActions] in remoteActions?.discard() }
        appActivationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: nil
        ) { [remoteActions, inputQueue] _ in inputQueue.async { remoteActions?.discard() } }
        pairingWindow = PairingWindow()
        remoteService.onStatusChange = { [statusMenu, pairingWindow] status in
            statusMenu?.update(remote: status)
            pairingWindow?.update(status)
        }
        remoteService.onConnected = { [pairingWindow] in pairingWindow?.close() }
        statusMenu.onToggleRemote = { [remoteService, pairingWindow] on in
            remoteService?.setEnabled(on)
            if on { pairingWindow?.show() }
        }
        statusMenu.onShowPairing = { [pairingWindow] in pairingWindow?.show() }
        gate.remote = remoteActions
        gate.virtualController = virtualController
        gate.onAllowedChange = { [remoteService] allowed in remoteService?.injectionChanged(allowed) }
        lifecycle.remote = remoteActions
        lifecycle.virtualController = virtualController
        lifecycle.onCleanUp = { [remoteService] in remoteService?.disable(reason: .quit) }

        displayMonitor = DisplayMonitor(log: log, injector: injector, inputQueue: inputQueue)
        displayMonitor.start()
        ScreenCatalog.emit(log: log)

        permissionMonitor = PermissionMonitor(log: log)
        permissionMonitor.onInjectionEnabledChange = { [gate] allowed in gate?.setAllowed(allowed) }
        permissionMonitor.start()

        controllerReader = ControllerReader(context: inputContext, processStartNs: processStartNs)
        controllerReader.onActiveModelChange = { [weak editorModel] model in editorModel?.activeModel = model }
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
        for error in arguments.errors where !error.concernsPalette {
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
        // A paleta não abre sobre a tela de alvos (`002-paleta-comandos` D-13).
        let palette: PaletteActions = paletteActions
        inputContext.queue.async { palette.blocked = true }
        session.onFinish = { [weak self] in
            self?.inputContext.queue.async { palette.blocked = false }
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
