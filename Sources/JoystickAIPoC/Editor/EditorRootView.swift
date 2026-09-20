import JoystickCore
import SwiftUI

/// Tela do editor de atalhos (`003-editor-atalhos` D-19, D-26, RF-12, RF-15): abas Atalhos e Paleta, modo de
/// identificação, faixas e rodapé com Salvar, Descartar e Restaurar padrão.
struct EditorRootView: View {
    @ObservedObject var model: EditorViewModel
    /// Ponte da figura do controle, repassada à aba Atalhos (`004-figura-controle-web` D-05).
    let figure: FigureBridge
    @State private var confirmingRestore = false

    var body: some View {
        VStack(alignment: .leading, spacing: EditorMetrics.spacing * 1.5) {
            HStack(spacing: EditorMetrics.spacing) {
                Button("Atalhos") { model.tab = .shortcuts }
                    .buttonStyle(TVButtonStyle(prominent: model.tab == .shortcuts))
                Button("Paleta") { model.tab = .palette }
                    .buttonStyle(TVButtonStyle(prominent: model.tab == .palette))
                Spacer()
                Toggle("Identificar pelo controle", isOn: $model.identifying)
                    .toggleStyle(TVToggleStyle())
                chargeView
            }
            if model.identifying {
                Text("Pressione um botão do controle para selecioná-lo; R1, R2 e o touchpad continuam clicando.")
                    .font(EditorMetrics.body)
                    .foregroundColor(.accentColor)
            }

            EditorBanners(model: model)

            switch model.tab {
            case .shortcuts: ShortcutsTab(model: model, figure: figure)
            case .palette: PaletteTab(model: model)
            }

            footer
        }
        .padding(EditorMetrics.padding)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    /// Carga do controle ativo (`011-bateria-e-cursor-no-menu` D-06, RF-01, RF-03, RF-05).
    ///
    /// Vive no cabeçalho porque é a única faixa do editor sempre visível sem rolagem, e a rolagem do editor é só
    /// vertical. O destaque da faixa baixa é por cor **e** por símbolo: a 3 m, e com o usuário de relance, matiz
    /// sozinha não sustenta o aviso (D-08).
    private var chargeView: some View {
        let low = model.charge.isLow
        return HStack(spacing: 8) {
            if let symbol = EditorLabels.chargeSymbol(model.charge) {
                Image(systemName: symbol)
                    .font(EditorMetrics.body)
            }
            Text(EditorLabels.charge(model.charge))
                .font(EditorMetrics.body)
        }
        .foregroundColor(low ? .orange : .secondary)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(EditorLabels.charge(model.charge))
    }

    private var footer: some View {
        let issues = model.draft.issues.count
        return HStack(spacing: EditorMetrics.spacing) {
            Button("Salvar") { model.save() }
                .buttonStyle(TVButtonStyle(prominent: model.canSave))
                .disabled(!model.canSave)
            Button("Descartar alterações") { model.discard() }
                .buttonStyle(TVButtonStyle())
                .disabled(!model.draft.isDirty)
            if issues > 0 {
                Label(issues == 1 ? "1 problema impede salvar" : "\(issues) problemas impedem salvar",
                      systemImage: "exclamationmark.triangle.fill")
                    .font(EditorMetrics.body)
                    .foregroundColor(.red)
            } else if model.draft.isDirty {
                Text("Alterações não salvas").font(EditorMetrics.body).foregroundColor(.secondary)
            }
            Spacer()
            Button("Restaurar padrão") { confirmingRestore = true }
                .buttonStyle(TVButtonStyle())
                .confirmationDialog("Restaurar os atalhos e a paleta padrão e gravar agora?", isPresented: $confirmingRestore) {
                    Button("Restaurar e gravar", role: .destructive) { model.restoreDefaults() }
                    Button("Cancelar", role: .cancel) {}
                }
        }
    }
}
