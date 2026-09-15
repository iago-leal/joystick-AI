import AppKit
import JoystickCore
import SwiftUI

/// Janela do editor de atalhos (`003-editor-atalhos` D-19, D-23). Só na main thread.
///
/// O app é `.accessory`: para a janela receber teclado e ditado, ele precisa se ativar. O aplicativo em foco na
/// abertura é guardado e reativado ao fechar (RF-19).
final class EditorWindowController: NSObject, NSWindowDelegate {
    /// Espera antes de conferir se a janela ficou ativa (sonda P-01).
    static let activationCheckDelay: DispatchTimeInterval = .milliseconds(500)

    private let log: DiagnosticLog
    private let makeContent: () -> AnyView
    private var window: NSWindow?
    private var previousApp: NSRunningApplication?

    init(log: DiagnosticLog, content: @escaping () -> AnyView) {
        self.log = log
        makeContent = content
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
        window.makeKeyAndOrderFront(nil)
        log.log(LogEventCatalog.editorOpened(source: source))

        DispatchQueue.main.asyncAfter(deadline: .now() + Self.activationCheckDelay) { [weak self, weak window] in
            guard let self, let window, window.isVisible else { return }
            if !(NSApp.isActive && window.isKeyWindow) {
                self.log.log(LogEventCatalog.editorActivationFailed())
            }
        }
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: EditorMetrics.minWindowSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.title = "Editar atalhos"
        window.contentMinSize = EditorMetrics.minWindowSize
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.moveToActiveSpace]
        window.contentView = NSHostingView(rootView: ScrollView([.vertical, .horizontal]) { makeContent() })
        window.delegate = self
        window.center()
        return window
    }

    func windowWillClose(_ notification: Notification) {
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
