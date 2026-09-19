import Foundation

/// Rótulo de cada botão como aparece no editor e na figura do controle (`004-figura-controle-web` D-13, RF-02).
///
/// Vivia em `EditorLabels.swift` do app; migrou para o núcleo porque o `FigureState` leva o rótulo até a página
/// (RN-04). Os 18 textos do DualSense são os mesmos, mais "Share" (`007-controle-ipega` RN-13); `FigureStateTests` os fixa.
extension ButtonID {
    public var displayName: String {
        switch self {
        case .cross: "✕"
        case .circle: "○"
        case .square: "□"
        case .triangle: "△"
        case .l1: "L1"
        case .r1: "R1"
        case .l2: "L2"
        case .r2: "R2"
        case .l3: "L3"
        case .r3: "R3"
        case .options: "Options"
        case .create: "Create"
        case .ps: "PS"
        case .touchpadClick: "Touchpad"
        case .dpadUp: "↑"
        case .dpadDown: "↓"
        case .dpadLeft: "←"
        case .dpadRight: "→"
        case .share: "Share"
        }
    }
}
