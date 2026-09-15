import JoystickCore
import SwiftUI

/// Editor mínimo, provisório, para as sondas do portão PM-1a (`003-editor-atalhos` roadmap §8, Fase 0):
/// legibilidade e alvos (P-05), ditado num campo de texto (P-03) e gravação de acorde (P-02).
/// Substituído pelo editor completo em T073.
struct EditorProbeView: View {
    @State private var text = ""
    @State private var recording = false
    @State private var captured: KeyChord?
    @State private var clicks = 0
    @State private var option = false

    var body: some View {
        VStack(alignment: .leading, spacing: EditorMetrics.spacing * 1.5) {
            Text("Editor de atalhos (sondas)").font(EditorMetrics.title)
            Text("Texto de exemplo a 24 pt: ✕ Enter, ○ Esc, △ Tab, L2 + ← mesa à esquerda, L1 + ✕ CONTINUAR.")
                .font(EditorMetrics.body)

            VStack(alignment: .leading, spacing: EditorMetrics.spacing) {
                Text("P-03: campo de texto para ditado com R3").font(EditorMetrics.body).foregroundColor(.secondary)
                TextField("Clique aqui e dite", text: $text).tvField()
            }

            VStack(alignment: .leading, spacing: EditorMetrics.spacing) {
                Text("P-02: gravação de acorde pelo teclado").font(EditorMetrics.body).foregroundColor(.secondary)
                HStack(spacing: EditorMetrics.spacing) {
                    Button(recording ? "Gravando: pressione um acorde" : "Gravar pelo teclado") {
                        recording.toggle()
                    }
                    .buttonStyle(TVButtonStyle(prominent: recording))
                    .background(KeyCaptureField(isActive: $recording) { captured = $0 })
                    Text(captured.map(KeyCatalog.display) ?? "nenhum acorde gravado").font(EditorMetrics.body)
                }
            }

            VStack(alignment: .leading, spacing: EditorMetrics.spacing) {
                Text("P-05: alvos de 44 pt").font(EditorMetrics.body).foregroundColor(.secondary)
                HStack(spacing: EditorMetrics.spacing) {
                    Button("Clique aqui (\(clicks))") { clicks += 1 }.buttonStyle(TVButtonStyle())
                    Button("Zerar") { clicks = 0 }.buttonStyle(TVButtonStyle())
                    Toggle("Este botão é modificador", isOn: $option).toggleStyle(TVToggleStyle())
                }
            }
        }
        .padding(EditorMetrics.padding)
        .frame(minWidth: EditorMetrics.minWindowSize.width, alignment: .topLeading)
    }
}
