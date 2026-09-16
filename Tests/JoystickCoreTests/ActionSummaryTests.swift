import Foundation
import Testing
@testable import JoystickCore

@Suite struct ActionSummaryTests {
    static func summary(_ button: ButtonID, _ layer: ButtonID?, _ config: ShortcutConfig = ShortcutDefaults.config) -> String {
        ActionSummary.text(for: button, layer: layer, in: config)
    }

    /// Critério de RF-08 e cenário "Visão de uma camada", na camada L2 do padrão.
    @Test func camadaL2DoPadrao() {
        #expect(Self.summary(.dpadLeft, .l2) == "mesa à esquerda")
        #expect(Self.summary(.cross, .l2) == "Enter (herdado)")
        #expect(Self.summary(.r1, .l2) == "clique esquerdo, fixo")
    }

    @Test func botoesFixosEModificadores() {
        #expect(Self.summary(.touchpadClick, nil) == "clique esquerdo, fixo")
        #expect(Self.summary(.r2, .options) == "clique direito, fixo")
        #expect(Self.summary(.l1, nil) == "modificador")
        #expect(Self.summary(.options, .l2) == "modificador ⌘")
    }

    @Test func tiposDeAcao() {
        #expect(Self.summary(.triangle, .l1) == "⇧Tab")
        #expect(Self.summary(.r3, nil) == "⌘M")
        #expect(Self.summary(.create, nil) == "Mission Control")
        #expect(Self.summary(.ps, nil) == "abrir paleta")
        #expect(Self.summary(.l3, nil) == "nenhuma")
        #expect(Self.summary(.cross, .l1) == "“CONTINUAR” + Enter")
        #expect(Self.summary(.ps, .options) == "nenhuma")
        #expect(Self.summary(.ps, .l1) == "abrir paleta (herdado)")
    }

    /// `005-sinais-matematicos` RF-03: o resumo, que alimenta a figura, mostra os acordes de zoom com o sinal.
    @Test func acordesDeZoom() {
        let config = ShortcutConfig(layers: [.l1: [
            .dpadUp: .chord(KeyChord(KeyChord.equal, [.command, .shift]), repeats: false),
            .dpadDown: .chord(KeyChord(0x1B, [.command]), repeats: false),
        ]])
        #expect(Self.summary(.dpadUp, .l1, config) == "⌘+")
        #expect(Self.summary(.dpadDown, .l1, config) == "⌘-")
    }

    @Test func textoLongoTruncado() {
        let config = ShortcutConfig(layers: [nil: [.square: .text(String(repeating: "a", count: 30), pressEnter: false)]])
        #expect(Self.summary(.square, nil, config) == "“" + String(repeating: "a", count: 24) + "…”")
        #expect(ActionSummary.truncated("curto") == "curto")
    }

    @Test func herdadoDeBaseSemAcao() {
        #expect(Self.summary(.square, .options) == "nenhuma")
        let config = ShortcutConfig(modifiers: [.l3: []], layers: [:])
        #expect(Self.summary(.square, .l3, config) == "nenhuma (herdado)")
    }
}
