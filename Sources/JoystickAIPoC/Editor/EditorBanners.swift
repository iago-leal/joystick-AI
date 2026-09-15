import JoystickCore
import SwiftUI

/// Faixas do editor (`003-editor-atalhos` D-17, D-20, D-25): conflito com gravação externa, arquivo inválido, erro de
/// gravação, confirmação da cópia do arquivo com erro de sintaxe, operação recusada e aviso sem gatilho da paleta.
struct EditorBanners: View {
    @ObservedObject var model: EditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: EditorMetrics.spacing) {
            switch model.conflict {
            case .externalChange?:
                banner("O arquivo de configuração foi alterado por outro programa enquanto você editava.", color: .orange) {
                    Button("Recarregar do arquivo") { model.reloadFromFile() }.buttonStyle(TVButtonStyle())
                    Button("Manter minhas alterações") { model.keepChanges() }.buttonStyle(TVButtonStyle(prominent: true))
                }
            case .externalInvalid(let issue)?:
                banner(EditorLabels.invalidFile(issue), color: .red) {
                    Button("Ocultar") { model.dismissInvalidNotice() }.buttonStyle(TVButtonStyle())
                }
            case nil:
                EmptyView()
            }

            if let pending = model.pendingBackup {
                let line = pending.line.map { " na linha \($0)" } ?? ""
                banner("O arquivo atual tem erro de sintaxe\(line). Para gravar, o conteúdo dele será copiado para config.json.bak.",
                       color: .orange) {
                    Button("Cancelar") { model.cancelBackup() }.buttonStyle(TVButtonStyle())
                    Button("Copiar e gravar") { model.confirmBackup() }.buttonStyle(TVButtonStyle(prominent: true))
                }
            }

            if let error = model.saveError {
                banner("Não foi possível gravar. \(error)", color: .red) { EmptyView() }
            }

            if let error = model.operationError {
                banner(error, color: .orange) {
                    Button("Ok") { model.operationError = nil }.buttonStyle(TVButtonStyle())
                }
            }

            if model.draft.warnings.contains(.noPaletteTrigger) {
                banner("Nenhum botão abre a paleta: o editor continuará acessível só pelo ícone da barra de menus.", color: .yellow) {
                    EmptyView()
                }
            }
        }
    }

    private func banner<Actions: View>(_ text: String, color: Color, @ViewBuilder actions: () -> Actions) -> some View {
        HStack(spacing: EditorMetrics.spacing) {
            Text(text)
                .font(EditorMetrics.body)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            actions()
        }
        .padding(EditorMetrics.spacing)
        .background(RoundedRectangle(cornerRadius: EditorMetrics.cornerRadius).fill(color.opacity(0.18)))
    }
}
