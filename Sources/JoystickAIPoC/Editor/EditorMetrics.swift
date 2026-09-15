import SwiftUI

/// Escala de TV do editor (`003-editor-atalhos` D-19, RNF de legibilidade): legível e clicável com o ponteiro do
/// controle a 3 m. O `controlSize` do sistema não chega a 44 pt no macOS 13, daí os estilos próprios abaixo.
enum EditorMetrics {
    static let bodySize: CGFloat = 24
    static let titleSize: CGFloat = 30
    /// Menor lado de qualquer alvo de clique.
    static let minTarget: CGFloat = 44
    static let minWindowSize = NSSize(width: 1_100, height: 720)
    static let spacing: CGFloat = 16
    static let padding: CGFloat = 32
    static let cornerRadius: CGFloat = 10
    static let horizontalInset: CGFloat = 20

    static var body: Font { .system(size: bodySize) }
    static var title: Font { .system(size: titleSize, weight: .semibold) }
}

/// Botão com texto de 24 pt e altura mínima de 44 pt; `prominent` destaca a ação principal.
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

/// Campo de texto com fonte de 24 pt e altura mínima de 44 pt.
struct TVFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)
            .font(EditorMetrics.body)
            .padding(.horizontal, 12)
            .frame(minHeight: EditorMetrics.minTarget)
            .background(
                RoundedRectangle(cornerRadius: EditorMetrics.cornerRadius)
                    .stroke(Color.secondary.opacity(0.5), lineWidth: 2))
    }
}

extension View {
    func tvField() -> some View { modifier(TVFieldModifier()) }
}
