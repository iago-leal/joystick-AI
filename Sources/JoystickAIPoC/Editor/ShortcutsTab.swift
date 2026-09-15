import JoystickCore
import SwiftUI

/// Aba de atalhos: seletor de camada, figura do controle e painel do botão selecionado (`003-editor-atalhos` D-21).
struct ShortcutsTab: View {
    @ObservedObject var model: EditorViewModel

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
                ControllerFigureView(model: model)
                ActionPanel(model: model)
            }
        }
    }
}
