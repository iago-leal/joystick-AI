import JoystickCore
import SwiftUI

/// Aba de atalhos: seletor de camada, figura do controle e painel do botão selecionado (`003-editor-atalhos` D-21).
/// A figura é a página web do `FigureBridge` ou, sem ela, o quadro com a mensagem de RN-12
/// (`004-figura-controle-web` D-04, D-10).
struct ShortcutsTab: View {
    static let unavailableMessage = "A figura do controle não pôde ser carregada; reinstale o app."

    @ObservedObject var model: EditorViewModel
    let figure: FigureBridge

    var body: some View {
        VStack(alignment: .leading, spacing: EditorMetrics.spacing) {
            HStack(spacing: EditorMetrics.spacing) {
                Text("Camada").font(EditorMetrics.body.weight(.semibold))
                ForEach(model.draft.layers, id: \.self) { layer in
                    Button(EditorLabels.layerName(layer)) { model.selectedLayer = layer }
                        .buttonStyle(TVButtonStyle(prominent: model.selectedLayer == layer))
                }
            }
            HStack(alignment: .top, spacing: EditorMetrics.spacing) {
                if model.figureUnavailable != nil {
                    unavailable
                } else {
                    ControllerFigureWebView(bridge: figure)
                        .frame(width: FigureBridge.size.width, height: FigureBridge.size.height)
                }
                ActionPanel(model: model)
            }
        }
    }

    /// Quadro do tamanho da figura com o texto de RN-12; o restante da aba segue operável.
    private var unavailable: some View {
        Text(Self.unavailableMessage)
            .font(EditorMetrics.body)
            .multilineTextAlignment(.center)
            .padding(EditorMetrics.padding)
            .frame(width: FigureBridge.size.width, height: FigureBridge.size.height)
            .background(RoundedRectangle(cornerRadius: 48).fill(Color.secondary.opacity(0.08)))
    }
}
