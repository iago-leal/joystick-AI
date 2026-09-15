import AppKit
import JoystickCore
import SwiftUI

/// Janela do editor de atalhos (`003-editor-atalhos` D-19, D-23). Só na main thread.
///
/// O app é `.accessory`: para a janela receber teclado e ditado, ele precisa se ativar. O aplicativo em foco na
/// abertura é guardado e reativado ao fechar (RF-19).
///
/// A sonda P-01 mostrou que, no macOS 26, `NSApp.activate()` é recusado quando o pedido vem do controle, e também
/// depois do clique do R1 no ícone da barra de menus; a janela ficava atrás do terminal. O que sempre ativou o app foi
/// o clique do R1 dentro da própria janela, tratado pelo servidor de janelas. Por isso a janela abre no nível
/// flutuante, acima das demais, e recebe um clique sintético na barra de título (emenda E003). Se o clique não
/// bastar, ela continua visível por cima até o usuário clicar nela; ao ativar o app, volta ao nível normal.
final class EditorWindowController: NSObject, NSWindowDelegate {
    /// Espera antes do clique de ativação, para o servidor de janelas já ter posto a janela por cima.
    static let clickDelay: DispatchTimeInterval = .milliseconds(150)
    /// Espera, depois do clique, antes de conferir se a janela ficou ativa.
    static let activationCheckDelay: DispatchTimeInterval = .milliseconds(500)

    private let log: DiagnosticLog
    private let makeContent: () -> AnyView
    /// Clique em coordenadas globais do Quartz (origem no canto superior esquerdo da tela principal).
    private let activateByClick: (CGPoint) -> Void
    private var window: NSWindow?
    private var previousApp: NSRunningApplication?

    init(log: DiagnosticLog, activateByClick: @escaping (CGPoint) -> Void, content: @escaping () -> AnyView) {
        self.log = log
        self.activateByClick = activateByClick
        makeContent = content
        super.init()
        NotificationCenter.default.addObserver(
            self, selector: #selector(appDidBecomeActive), name: NSApplication.didBecomeActiveNotification, object: nil)
    }

    func show(source: EditorOpenSource) {
        dispatchPrecondition(condition: .onQueue(.main))
        let front = NSWorkspace.shared.frontmostApplication
        if let front, front.processIdentifier != ProcessInfo.processInfo.processIdentifier {
            previousApp = front
        }
        let window = self.window ?? makeWindow()
        self.window = window
        if #available(macOS 14, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
        if !NSApp.isActive {
            window.level = .floating
        }
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        log.log(LogEventCatalog.editorOpened(source: source))

        DispatchQueue.main.asyncAfter(deadline: .now() + Self.clickDelay) { [weak self, weak window] in
            guard let self, let window, window.isVisible, !Self.isActive(window) else { return }
            if let point = Self.titleBarPoint(of: window) {
                self.activateByClick(point)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.activationCheckDelay) { [weak self, weak window] in
                guard let self, let window, window.isVisible, !Self.isActive(window) else { return }
                self.log.log(LogEventCatalog.editorActivationFailed())
            }
        }
    }

    @objc private func appDidBecomeActive(_ notification: Notification) {
        window?.level = .normal
    }

    private static func isActive(_ window: NSWindow) -> Bool {
        NSApp.isActive && window.isKeyWindow
    }

    /// Centro da barra de título em coordenadas do Quartz, ou `nil` sem tela principal.
    private static func titleBarPoint(of window: NSWindow) -> CGPoint? {
        guard let primary = NSScreen.screens.first else { return nil }
        let frame = window.frame
        let titleBarHeight = frame.height - window.contentLayoutRect.maxY
        let y = frame.maxY - max(titleBarHeight, 1) / 2
        return CGPoint(x: frame.midX, y: primary.frame.maxY - y)
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: EditorMetrics.minWindowSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.title = "Editar atalhos"
        window.contentMinSize = EditorMetrics.minWindowSize
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.moveToActiveSpace]
        // Só rolagem vertical: com os dois eixos, o conteúdo menor que a janela ficava centralizado e, depois de
        // redimensionar, os botões deixavam de responder ao clique (reteste do PM-1a).
        window.contentView = NSHostingView(rootView: ScrollView(.vertical) { makeContent() })
        window.delegate = self
        window.center()
        return window
    }

    func windowWillClose(_ notification: Notification) {
        window?.level = .normal
        log.log(LogEventCatalog.editorClosed(outcome: .clean))
        returnFocus()
    }

    /// Devolve o foco ao aplicativo guardado na abertura, se ele ainda estiver em execução.
    private func returnFocus() {
        guard let previousApp, !previousApp.isTerminated else {
            self.previousApp = nil
            return
        }
        if #available(macOS 14, *) {
            NSApp.yieldActivation(to: previousApp)
            previousApp.activate()
        } else {
            previousApp.activate(options: [.activateIgnoringOtherApps])
        }
        self.previousApp = nil
    }
}
