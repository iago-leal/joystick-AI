import JoystickCore
import SwiftUI

/// Painel do botão selecionado na camada escolhida (`003-editor-atalhos` D-21, RF-09, RF-11).
///
/// Tipo de ação com o detalhe de cada tipo, alternador "Este botão é modificador" com as teclas mantidas, confirmação
/// ao desmarcar e estado fixo para os botões de apontamento.
struct ActionPanel: View {
    enum Kind: CaseIterable {
        case chord, systemShortcut, text, openPalette, none, inherit

        var title: String {
            switch self {
            case .chord: "Acorde"
            case .systemShortcut: "Atalho de sistema"
            case .text: "Texto"
            case .openPalette: "Abrir paleta"
            case .none: "Nenhuma"
            case .inherit: "Herdar da base"
            }
        }
    }

    @ObservedObject var model: EditorViewModel
    @State private var confirmingUnset = false

    var body: some View {
        VStack(alignment: .leading, spacing: EditorMetrics.spacing) {
            if let button = model.selectedButton {
                content(button)
            } else {
                Text("Escolha um botão na figura ou ligue a identificação e pressione-o no controle.")
                    .font(EditorMetrics.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func content(_ button: ButtonID) -> some View {
        let layer = model.selectedLayer
        let config = model.draft.document.shortcuts

        Text("\(button.displayName) na camada \(EditorLabels.layerName(layer))").font(EditorMetrics.title)

        if ShortcutConfig.pointerButtons.contains(button) {
            Text(ActionSummary.text(for: button, layer: layer, in: config).capitalizedFirst + ": não recebe atalho nem pode ser modificador.")
                .font(EditorMetrics.body)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            issuesView(button, layer: layer)
            modifierSection(button, config: config)
            if !config.isModifier(button) {
                actionSection(button, layer: layer, config: config)
            } else if config.layers[layer]?[button] != nil {
                // Modificador com ação própria nesta camada (RF-12): a remoção desbloqueia "Salvar".
                Button("Remover a ação de \(button.displayName) nesta camada") {
                    model.setAction(nil, for: button, in: layer)
                }
                .buttonStyle(TVButtonStyle(prominent: true))
            }
        }
    }

    @ViewBuilder
    private func issuesView(_ button: ButtonID, layer: ButtonID?) -> some View {
        let issues = model.issues(for: .trigger(layer: layer, button: button)) + model.issues(for: .modifier(button))
        ForEach(Array(issues.enumerated()), id: \.offset) { _, issue in
            Label(EditorLabels.message(issue.rule), systemImage: "exclamationmark.triangle.fill")
                .font(EditorMetrics.body)
                .foregroundColor(.red)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func modifierSection(_ button: ButtonID, config: ShortcutConfig) -> some View {
        let keys = config.modifiers[button]
        Toggle("Este botão é modificador", isOn: Binding(
            get: { keys != nil },
            set: { on in
                if on {
                    model.setModifier(button, keys: [])
                } else {
                    confirmingUnset = true
                }
            }))
        .toggleStyle(TVToggleStyle())
        .confirmationDialog("Deixar \(button.displayName) de ser modificador?", isPresented: $confirmingUnset) {
            Button("Remover a camada \(button.displayName) e as ações dela", role: .destructive) { model.unsetModifier(button) }
            Button("Cancelar", role: .cancel) {}
        }

        if let keys {
            Text("Enquanto segurado, mantém pressionadas:").font(EditorMetrics.body)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 8)], alignment: .leading, spacing: 0) {
                ForEach([KeyModifier.command, .option, .control, .shift], id: \.self) { modifier in
                    Toggle(EditorLabels.modifierName(modifier), isOn: Binding(
                        get: { keys.contains(modifier) },
                        set: { on in
                            var updated = keys
                            if on { updated.insert(modifier) } else { updated.remove(modifier) }
                            model.setModifier(button, keys: updated)
                        }))
                    .toggleStyle(TVToggleStyle())
                }
            }
            Text("Escolha a camada \(button.displayName) acima para definir o que os outros botões fazem com ele segurado.")
                .font(.system(size: 24))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func actionSection(_ button: ButtonID, layer: ButtonID?, config: ShortcutConfig) -> some View {
        let own = config.layers[layer]?[button]
        let resolved = config.resolvedAction(for: button, in: layer)
        let kind = Self.kind(own: own, layer: layer)

        Text("Ação").font(EditorMetrics.body.weight(.semibold))
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(Kind.allCases.filter { $0 != .inherit || layer != nil }, id: \.self) { candidate in
                Button(candidate.title) {
                    guard candidate != kind else { return }
                    model.setAction(Self.defaultAction(candidate, current: resolved.action), for: button, in: layer)
                }
                .buttonStyle(TVButtonStyle(prominent: candidate == kind))
            }
        }

        switch own ?? (layer == nil ? TriggerAction.none : nil) {
        case .chord(let chord, let repeats)?:
            ChordEditor(chord: chord) { model.setAction(.chord($0, repeats: repeats), for: button, in: layer) }
            Toggle("Repetir enquanto segurado", isOn: Binding(
                get: { repeats },
                set: { model.setAction(.chord(chord, repeats: $0), for: button, in: layer) }))
            .toggleStyle(TVToggleStyle())
        case .systemShortcut(let current)?:
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(SystemShortcut.allCases, id: \.self) { shortcut in
                    Button(shortcut.displayName) { model.setAction(.systemShortcut(shortcut), for: button, in: layer) }
                        .buttonStyle(TVButtonStyle(prominent: shortcut == current))
                }
            }
            Text("O acorde vem dos Ajustes do Sistema no momento do uso.")
                .font(.system(size: 24))
                .foregroundColor(.secondary)
        case .text(let text, let pressEnter)?:
            TextField("Texto digitado, uma linha", text: Binding(
                get: { text },
                set: { model.setAction(.text($0, pressEnter: pressEnter), for: button, in: layer) }))
            .tvField()
            Toggle("Enviar Enter ao final", isOn: Binding(
                get: { pressEnter },
                set: { model.setAction(.text(text, pressEnter: $0), for: button, in: layer) }))
            .toggleStyle(TVToggleStyle())
        case .openPalette?, .none?:
            EmptyView()
        case nil:
            Text("Herdado da base: \(ActionSummary.text(for: resolved.action)).")
                .font(EditorMetrics.body)
                .foregroundColor(.secondary)
        }
    }

    private static func kind(own: TriggerAction?, layer: ButtonID?) -> Kind {
        switch own {
        case .chord?: .chord
        case .systemShortcut?: .systemShortcut
        case .text?: .text
        case .openPalette?: .openPalette
        case .none?: .none
        case nil: layer == nil ? .none : .inherit
        }
    }

    /// Ação inicial ao trocar de tipo; aproveita a ação vigente quando ela já é desse tipo. O acorde aproveitado começa
    /// sem repetição: a vigente vem da herança ou de outro tipo, e ⌘Tab herdado de ↓ não deve repetir (PM-2).
    private static func defaultAction(_ kind: Kind, current: TriggerAction) -> TriggerAction? {
        switch kind {
        case .chord:
            if case .chord(let chord, _) = current { return .chord(chord, repeats: false) }
            return .chord(KeyChord(KeyChord.returnKey), repeats: false)
        case .systemShortcut:
            if case .systemShortcut = current { return current }
            return .systemShortcut(.missionControl)
        case .text:
            if case .text = current { return current }
            return .text("", pressEnter: false)
        case .openPalette:
            return .openPalette
        case .none:
            return TriggerAction.none
        case .inherit:
            return nil
        }
    }
}

private extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}
