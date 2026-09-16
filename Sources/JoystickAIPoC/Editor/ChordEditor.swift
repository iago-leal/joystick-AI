import JoystickCore
import SwiftUI

/// Definição de acorde de duas formas (`003-editor-atalhos` D-22, RF-10): gravado pelo teclado físico, só com o
/// campo ativo e a janela em foco (RN-15), ou montado com a tecla escolhida numa grade e quatro alternadores,
/// operável só pelo ponteiro do controle.
struct ChordEditor: View {
    let chord: KeyChord
    let onChange: (KeyChord) -> Void

    @State private var recording = false
    @State private var group: KeyGroup = .letters

    var body: some View {
        VStack(alignment: .leading, spacing: EditorMetrics.spacing) {
            HStack(spacing: EditorMetrics.spacing) {
                Text(KeyCatalog.display(chord))
                    .font(.system(size: EditorMetrics.titleSize, weight: .semibold, design: .monospaced))
                    .frame(minWidth: 160, alignment: .leading)
                Button(recording ? "Pressione o acorde…" : "Gravar pelo teclado") {
                    recording.toggle()
                }
                .buttonStyle(TVButtonStyle(prominent: recording))
                .background(KeyCaptureField(isActive: $recording) { onChange($0) })
            }
            Text("\(KeyCaptureField.consumedBeforeApp.map(KeyCatalog.display).joined(separator: " e ")) são tomados pelo sistema antes do editor; monte-os abaixo.")
                .font(.system(size: 24))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Montar").font(EditorMetrics.body.weight(.semibold))
            FlowLayout(spacing: 8) {
                ForEach([KeyModifier.command, .option, .control, .shift], id: \.self) { modifier in
                    Toggle(EditorLabels.modifierName(modifier), isOn: Binding(
                        get: { chord.modifiers.contains(modifier) },
                        set: { on in
                            var updated = chord
                            if on { updated.modifiers.insert(modifier) } else { updated.modifiers.remove(modifier) }
                            onChange(updated)
                        }))
                    .toggleStyle(TVToggleStyle())
                }
            }
            FlowLayout(spacing: 8) {
                ForEach(KeyGroup.allCases, id: \.self) { candidate in
                    Button(EditorLabels.groupName(candidate)) { group = candidate }
                        .buttonStyle(TVButtonStyle(prominent: group == candidate))
                }
            }
            FlowLayout(spacing: 8) {
                ForEach(KeyCatalog.entries(in: group), id: \.name) { entry in
                    Button(entry.display) {
                        onChange(KeyChord(entry.keyCode, chord.modifiers))
                    }
                    .buttonStyle(TVButtonStyle(prominent: entry.keyCode == chord.keyCode))
                }
            }
        }
        .onAppear {
            group = KeyCatalog.entry(keyCode: chord.keyCode)?.group ?? .letters
        }
    }
}
