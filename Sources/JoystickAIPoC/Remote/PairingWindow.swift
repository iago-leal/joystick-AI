import AppKit
import CoreImage
import SwiftUI

/// Janela de pareamento do teclado remoto, legível a 3 m (`008-iphone-teclado-remoto` D-14, RF-02): QR com a URL e o
/// código no fragmento, o endereço e o código em dígitos grandes. Fecha ao parear e reabre pelo menu. Só na main thread.
final class PairingWindow {
    final class Model: ObservableObject {
        @Published var status = RemoteKeyboardStatus()
    }

    private let model = Model()
    private var window: NSWindow?

    func update(_ status: RemoteKeyboardStatus) {
        model.status = status
        if !status.enabled { close() }
    }

    func show() {
        guard model.status.enabled else { return }
        if window == nil {
            let hosting = NSHostingView(rootView: PairingView(model: model))
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 900, height: 820),
                styleMask: [.titled, .closable], backing: .buffered, defer: false)
            window.title = "Teclado remoto"
            window.contentView = hosting
            window.isReleasedWhenClosed = false
            // Aberta pelo menu com o ponteiro do controle, fica à frente mesmo sem ativação do app (RI-23).
            window.level = .floating
            window.center()
            self.window = window
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func close() {
        window?.orderOut(nil)
    }
}

private struct PairingView: View {
    @ObservedObject var model: PairingWindow.Model

    var body: some View {
        VStack(spacing: EditorMetrics.spacing) {
            if let url = model.status.url, let code = model.status.code {
                Text("Escaneie com a câmera do iPhone")
                    .font(EditorMetrics.title)
                if let image = QRCode.image(for: url) {
                    Image(nsImage: image)
                        .interpolation(.none)
                        .resizable()
                        .frame(width: 420, height: 420)
                        .accessibilityLabel("Código QR do teclado remoto")
                }
                Text(Self.spaced(code))
                    .font(.system(size: 72, weight: .bold, design: .monospaced))
                Text(url.replacingOccurrences(of: "/#c=\(code)", with: ""))
                    .font(EditorMetrics.body)
                    .foregroundColor(.secondary)
                    .textSelection(.enabled)
                Text(model.status.connected ? "Conectado" : "Aguardando o iPhone")
                    .font(EditorMetrics.body)
                    .foregroundColor(model.status.connected ? .green : .secondary)
            } else {
                Text("Ligando o teclado remoto…")
                    .font(EditorMetrics.title)
            }
        }
        .padding(EditorMetrics.padding)
        .frame(minWidth: 900, minHeight: 820)
    }

    /// "042917" → "042 917", para ler de longe.
    static func spaced(_ code: String) -> String {
        guard code.count == 6 else { return code }
        return String(code.prefix(3)) + " " + String(code.suffix(3))
    }
}

/// QR pelo `CIQRCodeGenerator`, ampliado sem suavização.
enum QRCode {
    static func image(for text: String) -> NSImage? {
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(Data(text.utf8), forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 12, y: 12)) else { return nil }
        let representation = NSCIImageRep(ciImage: output)
        let image = NSImage(size: representation.size)
        image.addRepresentation(representation)
        return image
    }
}
