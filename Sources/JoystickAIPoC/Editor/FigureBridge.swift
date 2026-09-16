import AppKit
import Combine
import JoystickCore
import WebKit

/// `WKWebView` da figura (`004-figura-controle-web` D-09): não rola (a página tem 830 × 620 px exatos), não toma o
/// teclado e não abre menu de contexto. A rolagem vai ao primeiro `NSScrollView` da cadeia de respondedores, para a
/// janela do editor continuar rolando com o ponteiro sobre a figura.
final class FigureWebView: WKWebView {
    override var acceptsFirstResponder: Bool { false }

    override func scrollWheel(with event: NSEvent) {
        var responder = nextResponder
        while let current = responder {
            if let scrollView = current as? NSScrollView {
                scrollView.scrollWheel(with: event)
                return
            }
            responder = current.nextResponder
        }
        super.scrollWheel(with: event)
    }

    override func menu(for event: NSEvent) -> NSMenu? { nil }

    override func willOpenMenu(_ menu: NSMenu, with event: NSEvent) {
        menu.removeAllItems()
    }
}

/// Ponte entre o editor e a página da figura (`004-figura-controle-web` D-05 a D-08, D-10, D-14, D-15;
/// `interfaces/figure-bridge.md`). Só na main thread; dona única do `WKWebView`, criada uma vez no `AppDelegate`.
///
/// App → página: `figure.render(state)` por `callAsyncJavaScript`, sem JSON interpolado, só quando o `FigureState`
/// difere do último enviado e depois de `didFinish`. Página → app: `messageHandlers.figure` com `{ button }`, que
/// vira `model.select`. Falhas viram `model.figureUnavailable` e `editor.figure_unavailable`, uma vez por abertura.
final class FigureBridge: NSObject {
    static let size = NSSize(width: 830, height: 620)
    static let messageName = "figure"
    /// Segunda queda do processo WebContent dentro deste intervalo desiste da página (D-10 c).
    static let terminationWindow: TimeInterval = 60

    private let model: EditorViewModel
    private let log: DiagnosticLog
    private var subscription: AnyCancellable?

    /// `nil` quando `index.html` não está no bundle (`resourceMissing`).
    private(set) var webView: FigureWebView?
    private var indexURL: URL?
    private var isLoaded = false
    private var lastSent: FigureState?
    /// Motivo persistente; republicado no modelo a cada abertura enquanto a página não voltar.
    private(set) var failure: FigureFailureReason?
    /// Verdadeiro entre o registro no log e a próxima abertura da janela (`figureUnavailable` zerado pelo modelo).
    private var reportedFailure = false
    private var lastTermination: Date?

    init(model: EditorViewModel, log: DiagnosticLog) {
        self.model = model
        self.log = log
        super.init()
        dispatchPrecondition(condition: .onQueue(.main))

        if let index = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "ControllerFigure") {
            indexURL = index
            webView = makeWebView()
            load()
        } else {
            // Antes de qualquer abertura: só guarda o motivo; o registro sai na primeira abertura (D-10).
            failure = .resourceMissing
            model.figureUnavailable = .resourceMissing
        }

        subscription = model.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.modelChanged() }
    }

    // MARK: WKWebView (D-04, D-06)

    private func makeWebView() -> FigureWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        configuration.userContentController.add(self, name: Self.messageName)
        let webView = FigureWebView(frame: NSRect(origin: .zero, size: Self.size), configuration: configuration)
        webView.allowsMagnification = false
        webView.allowsBackForwardNavigationGestures = false
        webView.underPageBackgroundColor = .clear
        webView.navigationDelegate = self
        return webView
    }

    private func load() {
        guard let webView, let indexURL else { return }
        isLoaded = false
        lastSent = nil
        webView.loadFileURL(indexURL, allowingReadAccessTo: indexURL.deletingLastPathComponent())
    }

    private func isIndex(_ url: URL?) -> Bool {
        guard let url, let indexURL, url.isFileURL else { return false }
        return url.standardizedFileURL.path == indexURL.standardizedFileURL.path
    }

    // MARK: estado (D-07, D-14)

    private func modelChanged() {
        if model.figureUnavailable == nil {
            reportedFailure = false
        }
        if let failure {
            publish(failure)
            return
        }
        sendStateIfNeeded()
    }

    private func sendStateIfNeeded() {
        guard isLoaded, let webView, failure == nil else { return }
        let state = model.figureState
        guard state != lastSent else { return }
        lastSent = state
        let object: Any
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            object = try JSONSerialization.jsonObject(with: encoder.encode(state))
        } catch {
            publish(.loadFailed)
            return
        }
        webView.callAsyncJavaScript("figure.render(state)", arguments: ["state": object], in: nil, in: .page) { [weak self] result in
            if case .failure = result {
                self?.publish(.loadFailed)
            }
        }
    }

    // MARK: falhas (D-10, D-15)

    private func publish(_ reason: FigureFailureReason) {
        dispatchPrecondition(condition: .onQueue(.main))
        failure = reason
        if model.figureUnavailable != reason {
            model.figureUnavailable = reason
        }
        if !reportedFailure {
            reportedFailure = true
            log.log(LogEventCatalog.editorFigureUnavailable(reason: reason))
        }
    }
}

// MARK: - WKNavigationDelegate (D-06, D-07, D-10)

extension FigureBridge: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(isIndex(navigationAction.request.url) ? .allow : .cancel)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoaded = true
        lastSent = nil
        sendStateIfNeeded()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        publish(.loadFailed)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        publish(.loadFailed)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        let now = Date()
        if let last = lastTermination, now.timeIntervalSince(last) < Self.terminationWindow {
            publish(.processTerminated)
            return
        }
        lastTermination = now
        load()
    }
}

// MARK: - WKScriptMessageHandler (D-08)

extension FigureBridge: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == Self.messageName,
              let body = message.body as? [String: Any],
              let raw = body["button"] as? String,
              let button = ButtonID(rawValue: raw) else { return }
        model.select(button)
    }
}
