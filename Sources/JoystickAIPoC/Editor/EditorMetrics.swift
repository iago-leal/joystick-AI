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
