import AppKit
import JoystickCore

/// Painel da paleta de comandos: sem borda, não ativador, sem foco e transparente ao mouse (`002-paleta-comandos` D-08).
///
/// Não tira o foco do aplicativo em uso (RN-02) e deixa os cliques passarem (RF-06). Só na main thread.
final class PalettePanel: NSPanel {
    static let screenMargin: CGFloat = 24

    let paletteView: PaletteView

    init(items: [PaletteItem]) {
        paletteView = PaletteView(items: items)
        super.init(contentRect: NSRect(x: 0, y: 0, width: 1, height: 1), styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered, defer: false)
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        ignoresMouseEvents = true
        hidesOnDeactivate = false
        isFloatingPanel = true
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isReleasedWhenClosed = false
        animationBehavior = .none
        contentView = paletteView
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func show(_ snapshot: PaletteSnapshot) {
        guard snapshot.isOpen else {
            orderOut(nil)
            return
        }
        if !isVisible {
            place()
        }
        paletteView.selection = snapshot.selection
        orderFrontRegardless()
    }

    /// Centro da área visível da tela que contém o cursor, calculado só na abertura (D-10).
    private func place() {
        let mouse = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) }) ?? NSScreen.main else { return }
        let visible = screen.visibleFrame
        paletteView.fit(maxHeight: visible.height - 2 * Self.screenMargin)
        let size = paletteView.frame.size
        setFrame(NSRect(x: visible.midX - size.width / 2, y: visible.midY - size.height / 2, width: size.width, height: size.height),
                 display: false)
    }
}

/// Lista legível a 3 m (D-09): texto monoespaçado de 26 pt, linha de 40 pt, seleção por cor e por marcador.
final class PaletteView: NSView {
    static let fontSize: CGFloat = 26
    static let rowHeight: CGFloat = 40
    static let padding: CGFloat = 16
    static let markerWidth: CGFloat = 40
    static let minWidth: CGFloat = 520
    static let background = NSColor(calibratedWhite: 0.1, alpha: 0.96)
    static let highlight = NSColor.systemBlue
    /// Itens terminados em espaço esperam descrição; o sufixo deixa isso visível.
    static let continuationSuffix = " …"

    private let items: [PaletteItem]
    private var visibleRows: Int
    private var firstVisible = 0

    var selection = 0 {
        didSet {
            scrollToSelection()
            needsDisplay = true
        }
    }

    init(items: [PaletteItem]) {
        self.items = items
        visibleRows = items.count
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) não é usado")
    }

    override var isFlipped: Bool { true }

    private static func font(selected: Bool) -> NSFont {
        NSFont.monospacedSystemFont(ofSize: fontSize, weight: selected ? .semibold : .regular)
    }

    private func label(_ item: PaletteItem) -> String {
        item.text.hasSuffix(" ") ? item.text.trimmingCharacters(in: .whitespaces) + Self.continuationSuffix : item.text
    }

    /// Ajusta o tamanho ao espaço disponível; sem espaço para todas as linhas, mostra as que cabem e rola (RNF de legibilidade).
    func fit(maxHeight: CGFloat) {
        let fitting = Int(((maxHeight - 2 * Self.padding) / Self.rowHeight).rounded(.down))
        visibleRows = max(1, min(items.count, fitting))
        let attributes: [NSAttributedString.Key: Any] = [.font: Self.font(selected: true)]
        let textWidth = items.map { label($0).size(withAttributes: attributes).width }.max() ?? 0
        let width = max(Self.minWidth, Self.markerWidth + textWidth + 3 * Self.padding)
        setFrameSize(NSSize(width: width.rounded(.up), height: CGFloat(visibleRows) * Self.rowHeight + 2 * Self.padding))
        scrollToSelection()
    }

    private func scrollToSelection() {
        if selection < firstVisible {
            firstVisible = selection
        } else if selection >= firstVisible + visibleRows {
            firstVisible = selection - visibleRows + 1
        }
        firstVisible = min(max(0, firstVisible), items.count - visibleRows)
    }

    override func draw(_ dirtyRect: NSRect) {
        let panel = NSBezierPath(roundedRect: bounds, xRadius: 14, yRadius: 14)
        Self.background.setFill()
        panel.fill()

        for row in 0..<visibleRows {
            let index = firstVisible + row
            let selected = index == selection
            let rowRect = NSRect(x: Self.padding / 2, y: Self.padding + CGFloat(row) * Self.rowHeight,
                                 width: bounds.width - Self.padding, height: Self.rowHeight)
            if selected {
                Self.highlight.setFill()
                NSBezierPath(roundedRect: rowRect.insetBy(dx: 0, dy: 2), xRadius: 8, yRadius: 8).fill()
            }
            let attributes: [NSAttributedString.Key: Any] = [
                .font: Self.font(selected: selected),
                .foregroundColor: selected ? NSColor.white : NSColor(calibratedWhite: 0.82, alpha: 1),
            ]
            let text = label(items[index])
            let textY = rowRect.midY - text.size(withAttributes: attributes).height / 2
            if selected {
                "▶".draw(at: NSPoint(x: Self.padding, y: textY), withAttributes: attributes)
            }
            text.draw(at: NSPoint(x: Self.padding + Self.markerWidth, y: textY), withAttributes: attributes)
        }
    }
}
