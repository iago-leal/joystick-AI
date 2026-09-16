import SwiftUI

/// Escala de TV do editor (`003-editor-atalhos` D-19, RNF de legibilidade): legível e clicável com o ponteiro do
/// controle a 3 m. O `controlSize` do sistema não chega aos alvos pedidos, daí os estilos próprios abaixo.
///
/// Os mínimos do requisito (24 pt e 44 pt) ficaram pequenos na sonda P-05; os valores abaixo são os do reteste.
/// A janela cabe numa tela de 900 pt de altura, a menor em uso.
enum EditorMetrics {
    static let bodySize: CGFloat = 32
    static let titleSize: CGFloat = 40
    /// Menor lado de qualquer alvo de clique.
    static let minTarget: CGFloat = 60
    static let minWindowSize = NSSize(width: 1_400, height: 800)
    static let spacing: CGFloat = 20
    static let padding: CGFloat = 40
    static let cornerRadius: CGFloat = 12
    static let horizontalInset: CGFloat = 24

    static var body: Font { .system(size: bodySize) }
    static var title: Font { .system(size: titleSize, weight: .semibold) }
}

/// Botão com texto e altura mínima da escala de TV; `prominent` destaca a ação principal.
struct TVButtonStyle: ButtonStyle {
    var prominent = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(EditorMetrics.body)
            .foregroundColor(prominent ? .white : .primary)
            .padding(.horizontal, EditorMetrics.horizontalInset)
            .frame(minWidth: EditorMetrics.minTarget, minHeight: EditorMetrics.minTarget)
            .background(
                RoundedRectangle(cornerRadius: EditorMetrics.cornerRadius)
                    .fill(prominent ? Color.accentColor : Color.secondary.opacity(0.18)))
            .contentShape(RoundedRectangle(cornerRadius: EditorMetrics.cornerRadius))
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

/// Alternador em forma de caixa de marcação grande; toda a linha é alvo de clique.
struct TVToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .font(.system(size: EditorMetrics.titleSize))
                    .foregroundColor(configuration.isOn ? .accentColor : .secondary)
                configuration.label.font(EditorMetrics.body)
            }
            .frame(minHeight: EditorMetrics.minTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Campo de texto com fonte e altura mínima da escala de TV.
struct TVFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)
            .font(EditorMetrics.body)
            .padding(.horizontal, 16)
            .frame(minHeight: EditorMetrics.minTarget)
            .background(
                RoundedRectangle(cornerRadius: EditorMetrics.cornerRadius)
                    .stroke(Color.secondary.opacity(0.5), lineWidth: 2))
    }
}

extension View {
    func tvField() -> some View { modifier(TVFieldModifier()) }
}

/// Fileira de botões que quebra linha pelo tamanho ideal de cada um, sem espremer o texto (emenda E001 da
/// `004-figura-controle-web`): a `LazyVGrid` adaptativa dividia a largura em colunas estreitas demais para a fonte de
/// 32 pt, e "Forward Delete" virava uma coluna de sílabas.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        let arranged = arrange(width: width, subviews: subviews)
        return CGSize(width: width.isFinite ? width : arranged.width, height: arranged.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let arranged = arrange(width: bounds.width, subviews: subviews)
        for (index, origin) in arranged.origins.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), anchor: .topLeading, proposal: .unspecified)
        }
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> (width: CGFloat, height: CGFloat, origins: [CGPoint]) {
        var origins: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var widest: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            widest = max(widest, x - spacing)
        }
        return (widest, y + rowHeight, origins)
    }
}
