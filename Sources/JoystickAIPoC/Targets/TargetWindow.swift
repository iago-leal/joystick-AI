import AppKit
import JoystickCore

/// Janela sem borda da tela de alvos, sobre a tela escolhida (RF-27, `target-run-result.md` §2).
final class TargetWindow: NSWindow {
    let targetView: TargetView

    init(screen: NSScreen) {
        targetView = TargetView(frame: NSRect(origin: .zero, size: screen.frame.size))
        super.init(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
        setFrame(screen.frame, display: false)
        level = .statusBar
        isOpaque = true
        backgroundColor = TargetView.background
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isReleasedWhenClosed = false
        contentView = targetView
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// Desenha o contador, o alvo de 16 × 16 pt e o resumo. Coordenadas com origem no canto superior esquerdo,
/// as mesmas de `TargetLayout`.
final class TargetView: NSView {
    static let background = NSColor(calibratedWhite: 0.55, alpha: 1)

    var target: RectPt? { didSet { needsDisplay = true } }
    var counter = "" { didSet { needsDisplay = true } }
    var summary: String? { didSet { needsDisplay = true } }

    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    func rect(of target: RectPt) -> NSRect {
        NSRect(x: target.x, y: target.y, width: target.w, height: target.h)
    }

    override func draw(_ dirtyRect: NSRect) {
        Self.background.setFill()
        bounds.fill()

        if let target {
            NSColor.black.setFill()
            rect(of: target).fill()
            NSColor.white.setStroke()
            let border = NSBezierPath(rect: rect(of: target).insetBy(dx: -1, dy: -1))
            border.lineWidth = 1
            border.stroke()
        }

        let counterAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 18, weight: .medium), .foregroundColor: NSColor.black,
        ]
        let counterSize = counter.size(withAttributes: counterAttributes)
        counter.draw(at: NSPoint(x: (bounds.width - counterSize.width) / 2, y: 12), withAttributes: counterAttributes)

        if let summary {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 28, weight: .semibold), .foregroundColor: NSColor.black,
            ]
            let size = summary.size(withAttributes: attributes)
            summary.draw(at: NSPoint(x: (bounds.width - size.width) / 2, y: (bounds.height - size.height) / 2), withAttributes: attributes)
        }
    }
}
