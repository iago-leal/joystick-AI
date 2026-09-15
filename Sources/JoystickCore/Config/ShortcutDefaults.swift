import Foundation

/// Mapeamento padrão, usado sem arquivo ou sem a seção `shortcuts` (`003-editor-atalhos` RN-11, D-04): reproduz o
/// protótipo da feature 001 com PS abrindo a paleta (002). A equivalência é verificada por `ShortcutDefaultsTests`.
public enum ShortcutDefaults {
    public static let continueText = "CONTINUAR"

    public static let config = ShortcutConfig(
        modifiers: [.l1: [], .l2: [], .options: [.command]],
        layers: [
            nil: [
                .dpadUp: chord(KeyChord.upArrow, repeats: true),
                .dpadDown: chord(KeyChord.downArrow, repeats: true),
                .dpadLeft: chord(KeyChord.leftArrow, repeats: true),
                .dpadRight: chord(KeyChord.rightArrow, repeats: true),
                .cross: chord(KeyChord.returnKey),
                .circle: chord(KeyChord.escape),
                .square: chord(KeyChord.delete, repeats: true),
                .triangle: chord(KeyChord.tab),
                .create: .systemShortcut(.missionControl),
                // Atalho do transcritor do Raycast, configurado pelo usuário.
                .r3: chord(KeyChord.m, [.command]),
                .ps: .openPalette,
                .l3: .none,
            ],
            .l1: [
                .cross: .text(continueText, pressEnter: true),
                .triangle: chord(KeyChord.tab, [.shift]),
            ],
            .l2: [
                .dpadLeft: .systemShortcut(.spaceLeft),
                .dpadRight: .systemShortcut(.spaceRight),
                .dpadDown: .systemShortcut(.applicationWindows),
                .dpadUp: .systemShortcut(.missionControl),
                .triangle: .systemShortcut(.nextWindow),
            ],
            // Options mantém Command para alternar aplicativos; os demais botões não fazem nada nessa camada.
            .options: optionsLayer,
        ]
    )

    public static let document = ShortcutsDocument(shortcuts: config, palette: PaletteDefaults.items)

    private static var optionsLayer: [ButtonID: TriggerAction] {
        var layer: [ButtonID: TriggerAction] = [:]
        for button in ButtonID.allCases where !ShortcutConfig.pointerButtons.contains(button) && ![.l1, .l2, .options].contains(button) {
            layer[button] = TriggerAction.none
        }
        layer[.dpadRight] = chord(KeyChord.tab, [.command])
        layer[.dpadLeft] = chord(KeyChord.tab, [.command, .shift])
        return layer
    }

    private static func chord(_ keyCode: UInt16, _ modifiers: Set<KeyModifier> = [], repeats: Bool = false) -> TriggerAction {
        .chord(KeyChord(keyCode, modifiers), repeats: repeats)
    }
}
