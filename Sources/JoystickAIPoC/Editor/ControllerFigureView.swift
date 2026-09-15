import JoystickCore
import SwiftUI

/// Figura do controle com os 18 botões nas posições físicas (`003-editor-atalhos` D-21, RF-08, RF-17).
///
/// Gatilhos e *bumpers* no topo, L1 acima de L2; direcional à esquerda; botões de ação à direita, com □ à esquerda
/// do grupo; touchpad, Create, Options e PS ao centro; analógicos embaixo. Cada botão mostra a ação resumida na
/// camada escolhida; herdados aparecem esmaecidos, e botões fixos e modificadores, em cinza.
struct ControllerFigureView: View {
    static let chipSize = CGSize(width: 160, height: 96)
    static let canvasSize = CGSize(width: 830, height: 620)
    static let summarySize: CGFloat = 24

    /// Centro de cada botão na tela da figura.
    static let positions: [ButtonID: CGPoint] = [
        .l1: CGPoint(x: 80, y: 48), .r1: CGPoint(x: 750, y: 48), .touchpadClick: CGPoint(x: 415, y: 48),
        .l2: CGPoint(x: 80, y: 150), .create: CGPoint(x: 250, y: 150), .options: CGPoint(x: 580, y: 150), .r2: CGPoint(x: 750, y: 150),
        .dpadUp: CGPoint(x: 165, y: 260), .dpadLeft: CGPoint(x: 80, y: 360), .dpadRight: CGPoint(x: 250, y: 360), .dpadDown: CGPoint(x: 165, y: 460),
        .triangle: CGPoint(x: 665, y: 260), .square: CGPoint(x: 580, y: 360), .circle: CGPoint(x: 750, y: 360), .cross: CGPoint(x: 665, y: 460),
        .ps: CGPoint(x: 415, y: 460),
        .l3: CGPoint(x: 250, y: 570), .r3: CGPoint(x: 580, y: 570),
    ]

    @ObservedObject var model: EditorViewModel

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 48)
                .fill(Color.secondary.opacity(0.08))
                .frame(width: Self.canvasSize.width, height: Self.canvasSize.height)
            ForEach(ButtonID.allCases, id: \.self) { button in
                chip(button).position(Self.positions[button]!)
            }
        }
        .frame(width: Self.canvasSize.width, height: Self.canvasSize.height)
    }

    private func chip(_ button: ButtonID) -> some View {
        let layer = model.selectedLayer
        let config = model.draft.document.shortcuts
        let fixed = ShortcutConfig.pointerButtons.contains(button) || config.isModifier(button)
        let inherited = !fixed && config.resolvedAction(for: button, in: layer).inherited
        let selected = model.selectedButton == button
        let problem = model.hasIssue(button, in: layer)

        return Button {
            model.select(button)
        } label: {
            VStack(spacing: 2) {
                Text(button.displayName)
                    .font(.system(size: 26, weight: .bold))
                Text(ActionSummary.text(for: button, layer: layer, in: config))
                    .font(.system(size: Self.summarySize))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .opacity(inherited ? 0.55 : 1)
            }
            .padding(6)
            .frame(width: Self.chipSize.width, height: Self.chipSize.height)
            .background(
                RoundedRectangle(cornerRadius: EditorMetrics.cornerRadius)
                    .fill(problem ? Color.red.opacity(0.25) : fixed ? Color.secondary.opacity(0.28) : Color.secondary.opacity(0.14)))
            .overlay(
                RoundedRectangle(cornerRadius: EditorMetrics.cornerRadius)
                    .stroke(selected ? Color.accentColor : problem ? Color.red : Color.clear, lineWidth: 5))
            .contentShape(RoundedRectangle(cornerRadius: EditorMetrics.cornerRadius))
        }
        .buttonStyle(.plain)
    }
}
