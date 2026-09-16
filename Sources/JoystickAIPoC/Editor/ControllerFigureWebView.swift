import AppKit
import SwiftUI

/// Hospeda o `WKWebView` do `FigureBridge` na aba Atalhos (`004-figura-controle-web` D-04, D-05, RN-11).
///
/// Devolve sempre o mesmo `webView`: trocar de aba ou fechar a janela não recarrega a página. A área é fixa em
/// 830 × 620 pt (`FigureBridge.size`), aplicada pelo chamador com `.frame`, para o painel ao lado manter a largura.
struct ControllerFigureWebView: NSViewRepresentable {
    let bridge: FigureBridge

    func makeNSView(context: Context) -> NSView {
        bridge.webView ?? NSView(frame: NSRect(origin: .zero, size: FigureBridge.size))
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
