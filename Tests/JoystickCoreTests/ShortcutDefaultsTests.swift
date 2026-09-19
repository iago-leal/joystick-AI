import Foundation
import Testing
@testable import JoystickCore

/// Equivalência do mapeamento padrão com o protótipo (`003-editor-atalhos` D-04, RN-11).
///
/// A tabela registra as saídas do `switch` fixo anterior à configuração: os 18 botões pressionados e soltos na base e
/// com L1, L2 e Options segurados isoladamente. Botão ausente da tabela não produz nada ao pressionar nem ao soltar.
@Suite struct ShortcutDefaultsTests {
    struct Output: Equatable {
        var press: [ShortcutAction]
        var release: [ShortcutAction]
    }

    static func chord(_ keyCode: UInt16, _ modifiers: Set<KeyModifier> = [], repeats: Bool = false) -> Output {
        let chord = KeyChord(keyCode, modifiers)
        return Output(press: [.keyDown(chord, repeats: repeats)], release: [.keyUp(chord)])
    }

    static let baseLayer: [ButtonID: Output] = [
        .dpadUp: chord(KeyChord.upArrow, repeats: true),
        .dpadDown: chord(KeyChord.downArrow, repeats: true),
        .dpadLeft: chord(KeyChord.leftArrow, repeats: true),
        .dpadRight: chord(KeyChord.rightArrow, repeats: true),
        .cross: chord(KeyChord.returnKey),
        .circle: chord(KeyChord.escape),
        .square: chord(KeyChord.delete, repeats: true),
        .triangle: chord(KeyChord.tab),
        .create: chord(KeyChord.upArrow, [.control]),
        .r3: chord(KeyChord.m, [.command]),
        .ps: Output(press: [.openPalette], release: []),
        .options: Output(press: [.modifierDown(.command)], release: [.modifierUp(.command)]),
    ]

    /// Camada → saídas; `nil` é a base. Na camada de um modificador, o próprio modificador não é exercitado.
    static let table: [ButtonID?: [ButtonID: Output]] = [
        nil: baseLayer,
        .l1: baseLayer.merging([
            .cross: Output(press: [.text("CONTINUAR", pressEnter: true)], release: []),
            .triangle: chord(KeyChord.tab, [.shift]),
        ]) { $1 },
        .l2: baseLayer.merging([
            .dpadLeft: chord(KeyChord.leftArrow, [.control]),
            .dpadRight: chord(KeyChord.rightArrow, [.control]),
            .dpadDown: chord(KeyChord.downArrow, [.control]),
            .dpadUp: chord(KeyChord.upArrow, [.control]),
            .triangle: chord(KeyChord.grave, [.command]),
        ]) { $1 },
        .options: [
            .dpadRight: chord(KeyChord.tab, [.command]),
            .dpadLeft: chord(KeyChord.tab, [.command, .shift]),
        ],
    ]

    static let modifierOutputs: [ButtonID: Output] = [
        .l1: Output(press: [], release: []),
        .l2: Output(press: [], release: []),
        .options: Output(press: [.modifierDown(.command)], release: [.modifierUp(.command)]),
    ]

    func makeMapper() -> ShortcutMapper {
        ShortcutMapper(config: ShortcutDefaults.config)
    }

    /// Converte as saídas do mapeador para a forma registrada na tabela: o protótipo pressionava o acorde padrão do
    /// atalho de sistema, que agora é lido das preferências no uso (D-11).
    func normalized(_ actions: [ShortcutAction]) -> [ShortcutAction] {
        actions.map { action in
            switch action {
            case .systemDown(let shortcut): .keyDown(shortcut.defaultChord, repeats: false)
            case .systemUp(let shortcut): .keyUp(shortcut.defaultChord)
            default: action
            }
        }
    }

    @Test(arguments: [ButtonID?.none, .l1, .l2, .options])
    func camadaEquivalenteAoPrototipo(layer: ButtonID?) {
        let expected = Self.table[layer]!
        for button in ButtonID.allCases where button != layer {
            var mapper = makeMapper()
            if let layer {
                #expect(normalized(mapper.press(layer)) == Self.modifierOutputs[layer]!.press)
            }
            let press = normalized(mapper.press(button))
            let release = normalized(mapper.release(button))
            let output = expected[button] ?? Output(press: [], release: [])
            #expect(press == output.press, "\(layer?.rawValue ?? "base") + \(button): pressionar")
            #expect(release == output.release, "\(layer?.rawValue ?? "base") + \(button): soltar")
            if let layer {
                #expect(normalized(mapper.release(layer)) == Self.modifierOutputs[layer]!.release)
            }
        }
    }

    /// `006-teclado-virtual` D-04 e RF-06: nenhum botão de fábrica aciona o Atalho de Acessibilidade.
    @Test func padraoSemAtalhoDeAcessibilidade() {
        let actions = ShortcutDefaults.config.layers.values.flatMap(\.values)
        #expect(!actions.isEmpty)
        #expect(!actions.contains(.systemShortcut(.accessibilityShortcut)))
    }

    // MARK: `007-controle-ipega` D-02, RN-08

    /// O documento padrão não ganha `share` em nenhuma camada, e o Share não faz nada na base nem em Options. Fora do
    /// laço de Options, o Share herda ali a ação da base, ao contrário dos demais botões livres.
    @Test func padraoSemShare() {
        #expect(ShortcutDefaults.config.layers.values.allSatisfy { $0[.share] == nil })
        #expect(ShortcutDefaults.config.modifiers[.share] == nil)
        #expect(ShortcutDefaults.config.layers[.share] == nil)
        #expect(ActionSummary.text(for: .share, layer: nil, in: ShortcutDefaults.config) == "nenhuma")
        #expect(ActionSummary.text(for: .share, layer: .options, in: ShortcutDefaults.config) == "nenhuma (herdado)")
    }

    /// `share` entra no fim; os 18 identificadores anteriores mantêm a ordem (camadas, solturas sintéticas).
    @Test func ordemDosBotoesAnterioresPreservada() {
        let previous: [ButtonID] = [
            .cross, .circle, .square, .triangle, .l1, .r1, .l2, .r2, .l3, .r3,
            .options, .create, .ps, .touchpadClick, .dpadUp, .dpadDown, .dpadLeft, .dpadRight,
        ]
        #expect(Array(ButtonID.allCases.prefix(18)) == previous)
        #expect(ButtonID.allCases.count == 19)
        #expect(ButtonID.allCases.last == .share)
    }
}
