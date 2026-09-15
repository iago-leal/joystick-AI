import JoystickCore
import SwiftUI
import UniformTypeIdentifiers

/// Aba da paleta (`003-editor-atalhos` D-21, RF-14): rótulo, texto e Enter de cada item, inclusão, remoção e
/// reordenação por botões ou por arrastar. Os limites de RN-12 aparecem como mensagem da operação recusada.
struct PaletteTab: View {
    @ObservedObject var model: EditorViewModel
    @State private var dragging: Int?

    var body: some View {
        let items = model.draft.document.palette
        VStack(alignment: .leading, spacing: EditorMetrics.spacing) {
            HStack(spacing: EditorMetrics.spacing) {
                Text("\(items.count) de \(ShortcutsDocument.paletteItemLimit.upperBound) itens; \"\(PaletteMachine.editorEntryTitle)\" fica sempre no fim.")
                    .font(EditorMetrics.body)
                Spacer()
                Button("Incluir no topo") { model.insertPaletteItem(at: 0) }
                    .buttonStyle(TVButtonStyle())
            }
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                row(index: index, item: item, count: items.count)
                    .onDrag {
                        dragging = index
                        return NSItemProvider(object: String(index) as NSString)
                    }
                    .onDrop(of: [UTType.text], delegate: RowDropDelegate(index: index, dragging: $dragging, model: model))
            }
            Button("Incluir no fim") { model.insertPaletteItem(at: items.count) }
                .buttonStyle(TVButtonStyle())
        }
    }

    private func row(index: Int, item: PaletteItem, count: Int) -> some View {
        let issues = model.issues(for: .paletteItem(index))
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 28))
                    .foregroundColor(.secondary)
                    .frame(width: 40)
                Text("\(index + 1)")
                    .font(EditorMetrics.body.monospacedDigit())
                    .frame(width: 56, alignment: .trailing)
                TextField("Rótulo (opcional)", text: Binding(
                    get: { item.label },
                    set: { model.setPaletteLabel($0, at: index) }))
                .tvField()
                .frame(width: 280)
                TextField("Texto digitado", text: Binding(
                    get: { item.text },
                    set: { model.setPaletteText($0, at: index) }))
                .tvField()
                Toggle("Enter", isOn: Binding(
                    get: { item.pressEnter },
                    set: { model.setPalettePressEnter($0, at: index) }))
                .toggleStyle(TVToggleStyle())
                Button { model.movePaletteItemUp(at: index) } label: { Image(systemName: "arrow.up") }
                    .buttonStyle(TVButtonStyle())
                    .disabled(index == 0)
                    .help("Mover para cima")
                Button { model.movePaletteItemDown(at: index) } label: { Image(systemName: "arrow.down") }
                    .buttonStyle(TVButtonStyle())
                    .disabled(index == count - 1)
                    .help("Mover para baixo")
                Button { model.removePaletteItem(at: index) } label: { Image(systemName: "trash") }
                    .buttonStyle(TVButtonStyle())
                    .help("Remover")
            }
            ForEach(Array(issues.enumerated()), id: \.offset) { _, issue in
                Label(EditorLabels.message(issue.rule), systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.red)
                    .padding(.leading, 108)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: EditorMetrics.cornerRadius)
                .fill(dragging == index ? Color.accentColor.opacity(0.15) : issues.isEmpty ? Color.clear : Color.red.opacity(0.12)))
    }
}

/// Reordenação por arrastar: soltar sobre uma linha coloca o item arrastado na posição dela.
private struct RowDropDelegate: DropDelegate {
    let index: Int
    @Binding var dragging: Int?
    let model: EditorViewModel

    func performDrop(info: DropInfo) -> Bool {
        defer { dragging = nil }
        guard let source = dragging, source != index else { return false }
        // Convenção de `onMove`: o destino conta posições antes da remoção do item arrastado.
        model.movePaletteItem(from: source, to: source < index ? index + 1 : index)
        return true
    }

    func dropExited(info: DropInfo) {}

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}
