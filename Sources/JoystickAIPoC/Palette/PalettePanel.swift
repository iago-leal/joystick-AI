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

    /// Troca a lista exibida; o tamanho é recalculado na próxima abertura (`003-editor-atalhos` D-12).
    func update(items: [PaletteItem]) {
        paletteView.items = items
    }

    /// Troca só a carga do rodapé (`011-bateria-e-cursor-no-menu` RN-09, RF-10).
    ///
    /// Não mexe em itens nem em seleção, não reposiciona o painel, não o traz à frente e não o torna chave: o
    /// painel continua não ativador e transparente ao mouse, e a contagem dos 60 s de inatividade segue medindo
    /// apenas entrada do controle. Com o painel fechado, o valor fica guardado e aparece na próxima abertura.
    func update(charge: ChargeDisplay) {
        paletteView.charge = charge
    }

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
        paletteView.fit(maxHeight: visible.height - 2 * Self.screenMargin, maxWidth: visible.width - 2 * Self.screenMargin)
        let size = paletteView.frame.size
        setFrame(NSRect(x: visible.midX - size.width / 2, y: visible.midY - size.height / 2, width: size.width, height: size.height),
                 display: false)
    }
}

/// Lista legível a 3 m (D-09): texto monoespaçado de 26 pt, linha de 40 pt, seleção por cor e por marcador.
///
/// Depois dos itens vem a entrada fixa "Editar atalhos", separada por uma linha (`003-editor-atalhos` D-13).
final class PaletteView: NSView {
    static let fontSize: CGFloat = 26
    static let rowHeight: CGFloat = 40
    static let padding: CGFloat = 16
    static let markerWidth: CGFloat = 40
    static let minWidth: CGFloat = 520
    static let background = NSColor(calibratedWhite: 0.1, alpha: 0.96)
    static let highlight = NSColor.systemBlue
    static let separator = NSColor(calibratedWhite: 0.45, alpha: 1)
    /// Itens terminados em espaço esperam descrição; o sufixo deixa isso visível.
    static let continuationSuffix = " …"
    /// Altura do rodapé fixo da carga (`011-bateria-e-cursor-no-menu` D-07). Igual à da linha, para o rodapé ler
    /// na mesma escala dos itens a 3 m.
    static let footerHeight: CGFloat = 40
    static let lowCharge = NSColor.systemOrange

    /// Carga do controle ativo, desenhada no rodapé e **fora** do arranjo de linhas (RN-08): não entra em
    /// `rowCount`, não é alcançada por ↑ e ↓, não é confirmável por ✕, não desloca a entrada fixa "Editar atalhos"
    /// e não muda o índice do último confirmado. Acrescentá-la como linha faria todas essas coisas.
    var charge: ChargeDisplay = .noController {
        didSet { if charge != oldValue { needsDisplay = true } }
    }

    var items: [PaletteItem] {
        didSet {
            visibleRows = rowCount
            firstVisible = 0
            needsDisplay = true
        }
    }
    private var visibleRows: Int
    private var firstVisible = 0

    /// Itens configurados mais a entrada fixa.
    private var rowCount: Int { items.count + 1 }

    var selection = 0 {
        didSet {
            scrollToSelection()
            needsDisplay = true
        }
    }

    init(items: [PaletteItem]) {
        self.items = items
        visibleRows = items.count + 1
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) não é usado")
    }

    override var isFlipped: Bool { true }

    private static func font(selected: Bool) -> NSFont {
        NSFont.monospacedSystemFont(ofSize: fontSize, weight: selected ? .semibold : .regular)
    }

    /// Rótulo quando houver; sem rótulo, o texto, com o sufixo " …" se terminar em espaço.
    private func label(row: Int) -> String {
        guard row < items.count else { return PaletteMachine.editorEntryTitle }
        let item = items[row]
        guard item.label.isEmpty, item.text.hasSuffix(" ") else { return item.displayText }
        return item.text.trimmingCharacters(in: .whitespaces) + Self.continuationSuffix
    }

    /// Ajusta o tamanho ao espaço disponível; sem espaço para todas as linhas, mostra as que cabem e rola
    /// (RNF de legibilidade). Textos mais largos que a tela são truncados no desenho.
    func fit(maxHeight: CGFloat, maxWidth: CGFloat) {
        // O rodapé da carga disputa altura com as linhas: sem descontá-lo aqui, o painel passaria da área visível
        // numa tela pequena, que é o risco registrado no `roadmap.md` §9.
        let forRows = maxHeight - 2 * Self.padding - Self.footerHeight
        let fitting = Int((forRows / Self.rowHeight).rounded(.down))
        visibleRows = max(1, min(rowCount, fitting))
        let attributes: [NSAttributedString.Key: Any] = [.font: Self.font(selected: true)]
        let textWidth = (0..<rowCount).map { label(row: $0).size(withAttributes: attributes).width }.max() ?? 0
        // A frase mais longa do rodapé é a de indisponibilidade; medi-la evita que o texto entre truncado.
        let footerWidth = Self.widestFooterText.size(withAttributes: attributes).width + Self.markerWidth
        let width = min(max(Self.minWidth, Self.markerWidth + max(textWidth, footerWidth) + 3 * Self.padding),
                        max(Self.minWidth, maxWidth))
        let height = CGFloat(visibleRows) * Self.rowHeight + 2 * Self.padding + Self.footerHeight
        setFrameSize(NSSize(width: width.rounded(.down), height: height))
        scrollToSelection()
    }

    /// Medida de pior caso do rodapé, para o painel já nascer largo o bastante.
    static let widestFooterText = footerText(.unavailable)

    private func scrollToSelection() {
        if selection < firstVisible {
            firstVisible = selection
        } else if selection >= firstVisible + visibleRows {
            firstVisible = selection - visibleRows + 1
        }
        firstVisible = min(max(0, firstVisible), rowCount - visibleRows)
    }

    override func draw(_ dirtyRect: NSRect) {
        let panel = NSBezierPath(roundedRect: bounds, xRadius: 14, yRadius: 14)
        Self.background.setFill()
        panel.fill()

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byTruncatingTail
        let textX = Self.padding + Self.markerWidth
        for row in 0..<visibleRows {
            let index = firstVisible + row
            let selected = index == selection
            let rowRect = NSRect(x: Self.padding / 2, y: Self.padding + CGFloat(row) * Self.rowHeight,
                                 width: bounds.width - Self.padding, height: Self.rowHeight)
            if index == items.count, row > 0 {
                Self.separator.setFill()
                NSRect(x: rowRect.minX + Self.padding, y: rowRect.minY - 1, width: rowRect.width - 2 * Self.padding, height: 2).fill()
            }
            if selected {
                Self.highlight.setFill()
                NSBezierPath(roundedRect: rowRect.insetBy(dx: 0, dy: 2), xRadius: 8, yRadius: 8).fill()
            }
            let attributes: [NSAttributedString.Key: Any] = [
                .font: Self.font(selected: selected),
                .foregroundColor: selected ? NSColor.white : NSColor(calibratedWhite: 0.82, alpha: 1),
                .paragraphStyle: paragraph,
            ]
            let text = label(row: index)
            let textHeight = text.size(withAttributes: attributes).height
            let textY = rowRect.midY - textHeight / 2
            if selected {
                "▶".draw(at: NSPoint(x: Self.padding, y: textY), withAttributes: attributes)
            }
            let textRect = NSRect(x: textX, y: textY, width: bounds.width - textX - Self.padding, height: textHeight)
            text.draw(with: textRect, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine], attributes: attributes)
        }

        drawFooter(paragraph: paragraph)
    }

    /// Rodapé da carga, desenhado depois das linhas e independente delas: nada aqui consulta `selection` nem
    /// `firstVisible`, e nada aqui altera qualquer um dos dois.
    private func drawFooter(paragraph: NSParagraphStyle) {
        let top = bounds.height - Self.padding - Self.footerHeight
        Self.separator.setFill()
        NSRect(x: Self.padding, y: top, width: bounds.width - 2 * Self.padding, height: 1).fill()

        let low = charge.isLow
        let attributes: [NSAttributedString.Key: Any] = [
            .font: Self.font(selected: low),
            .foregroundColor: low ? Self.lowCharge : NSColor(calibratedWhite: 0.7, alpha: 1),
            .paragraphStyle: paragraph,
        ]
        let text = Self.footerText(charge)
        let textHeight = text.size(withAttributes: attributes).height
        let rect = NSRect(x: Self.padding, y: top + (Self.footerHeight - textHeight) / 2,
                          width: bounds.width - 2 * Self.padding, height: textHeight)
        text.draw(with: rect, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine], attributes: attributes)
    }

    /// O texto do rodapé reaproveita a redação do editor, de propósito: duas redações da mesma informação
    /// divergiriam com o tempo, e é justamente a divergência entre as duas interfaces que D-03 existe para evitar.
    /// O glifo à frente é o segundo canal do destaque, ao lado da cor (D-08): a 3 m, sobre o fundo escuro do
    /// painel, matiz sozinha não sustenta o aviso.
    static func footerText(_ charge: ChargeDisplay) -> String {
        let label = EditorLabels.charge(charge)
        switch charge {
        case .noController, .unavailable: return label
        case .known(_, let charging, let low):
            if low { return "⚠ " + label }
            return charging ? "⚡ " + label : label
        }
    }
}
