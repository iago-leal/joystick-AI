import Foundation
import Testing
@testable import JoystickCore

/// Contrato do estado da figura (`004-figura-controle-web` D-12, D-13, `data-delta.md` §4).
@Suite struct FigureStateTests {
    static func state(layer: ButtonID? = nil, selected: ButtonID? = .cross, config: ShortcutConfig = ShortcutDefaults.config,
                      issues: [EditorIssue] = [], model: ControllerModel? = nil) -> FigureState {
        FigureState(config: config, layer: layer, selected: selected, issues: issues, model: model)
    }

    static func button(_ id: ButtonID, in state: FigureState) -> FigureButton {
        state.buttons.first { $0.id == id.rawValue }!
    }

    @Test func ordemEContagem() {
        let state = Self.state()
        #expect(state.buttons.count == 19)
        #expect(state.buttons.map(\.id) == ButtonID.allCases.map(\.rawValue))
        #expect(state.buttons.last?.id == "share")
        #expect(state.layer == "base")
        #expect(Self.state(layer: .options).layer == "options")
    }

    /// Cenário "Figura fiel com a configuração padrão". O acorde de ✕ aparece como "Enter", nome de exibição de
    /// `KeyCatalog` para a tecla Return.
    @Test func padraoNaBase() {
        let state = Self.state()
        #expect(Self.button(.cross, in: state).summary == "Enter")
        #expect(Self.button(.cross, in: state).kind == .own)
        #expect(Self.button(.ps, in: state).summary == "abrir paleta")
        #expect(Self.button(.r1, in: state).summary == "clique esquerdo, fixo")
        #expect(Self.button(.r1, in: state).kind == .fixed)
        #expect(Self.button(.r2, in: state).kind == .fixed)
        #expect(Self.button(.touchpadClick, in: state).kind == .fixed)
        #expect(Self.button(.l1, in: state).kind == .modifier)
        #expect(Self.button(.l1, in: state).summary == "modificador")
        #expect(Self.button(.options, in: state).summary == "modificador ⌘")
        #expect(state.buttons.allSatisfy { !$0.problem })
    }

    /// Cenário "Resumo por camada", na camada L2 do padrão.
    @Test func camadaL2() {
        let state = Self.state(layer: .l2)
        #expect(state.layer == "l2")
        let left = Self.button(.dpadLeft, in: state)
        #expect(left.summary == "mesa à esquerda")
        #expect(left.kind == .own)
        let cross = Self.button(.cross, in: state)
        #expect(cross.kind == .inherited)
        #expect(cross.summary == "Enter (herdado)")
        // Fixos e modificadores continuam como tais em qualquer camada.
        #expect(Self.button(.r1, in: state).kind == .fixed)
        #expect(Self.button(.l2, in: state).kind == .modifier)
    }

    /// Cenário "Problema em vermelho": texto vazio em ✕; problema de modificador marca o botão em qualquer camada.
    @Test func problema() throws {
        var draft = EditorDraft(base: ShortcutDefaults.document)
        try draft.setAction(.text("", pressEnter: false), for: .cross, in: nil)
        #expect(!draft.issues.isEmpty)
        let base = Self.state(config: draft.document.shortcuts, issues: draft.issues)
        #expect(Self.button(.cross, in: base).problem)
        #expect(base.buttons.filter(\.problem).map(\.id) == ["cross"])
        // Na camada L1, o problema é do gatilho da base, não de ✕ em L1.
        let l1 = Self.state(layer: .l1, config: draft.document.shortcuts, issues: draft.issues)
        #expect(!Self.button(.cross, in: l1).problem)

        let modifierIssue = [EditorIssue(target: .modifier(.l1), rule: .modifierHasAction)]
        #expect(Self.button(.l1, in: Self.state(issues: modifierIssue)).problem)
        #expect(Self.button(.l1, in: Self.state(layer: .options, issues: modifierIssue)).problem)
        #expect(!Self.button(.l2, in: Self.state(issues: modifierIssue)).problem)
    }

    @Test func selecao() {
        let selected = Self.state(selected: .triangle)
        #expect(selected.buttons.filter(\.selected).map(\.id) == ["triangle"])
        #expect(Self.state(selected: nil).buttons.allSatisfy { !$0.selected })
    }

    /// Cenário "Sem modificadores": nenhum botão herdado nem modificador.
    @Test func semModificadores() {
        let config = ShortcutConfig(modifiers: [:], layers: [nil: [.cross: .openPalette]])
        let state = Self.state(config: config)
        let kinds = Set(state.buttons.map(\.kind))
        #expect(!kinds.contains(.inherited))
        #expect(!kinds.contains(.modifier))
        #expect(kinds == [.fixed, .own])
        #expect(state.buttons.allSatisfy { !$0.summary.hasSuffix("(herdado)") })
    }

    /// Cenário "Texto do usuário não vira marcação": o núcleo não escapa nem trunca diferente; a proteção é da página.
    @Test func textoDoUsuarioIntacto() {
        let config = ShortcutConfig(layers: [nil: [.square: .text("<b>x</b>", pressEnter: false)]])
        #expect(Self.button(.square, in: Self.state(config: config)).summary == "“<b>x</b>”")
        let long = ShortcutConfig(layers: [nil: [.square: .text("<img src=x onerror=alert(1)>", pressEnter: true)]])
        #expect(Self.button(.square, in: Self.state(config: long)).summary == "“<img src=x onerror=alert…” + Enter")
    }

    /// Instantâneo das chaves codificadas (`data-delta.md` §3): é o que `callAsyncJavaScript` recebe.
    @Test func codificacao() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let state = Self.state()
        let data = try encoder.encode(state)
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object.keys.sorted() == ["buttons", "controller", "layer"])
        #expect(object["controller"] as? String == "dualSense")
        let buttons = try #require(object["buttons"] as? [[String: Any]])
        #expect(buttons.count == 19)
        #expect(buttons[0].keys.sorted() == ["id", "kind", "label", "problem", "selected", "summary"])
        #expect(buttons[0]["kind"] as? String == "own")
        #expect(buttons[0]["selected"] as? Bool == true)

        let first = try String(decoding: encoder.encode(state.buttons[0]), as: UTF8.self)
        #expect(first == #"{"id":"cross","kind":"own","label":"✕","problem":false,"selected":true,"summary":"Enter"}"#)
        #expect(try String(decoding: encoder.encode(FigureButton.Kind.inherited), as: UTF8.self) == #""inherited""#)
        #expect(try JSONDecoder().decode(FigureState.self, from: data) == state)
    }

    /// Os 18 rótulos de `EditorLabels.swift` da feature 003, agora no núcleo (D-13), mais o Share (`007-controle-ipega` RN-13).
    @Test func rotulosDos19Botoes() {
        let expected: [ButtonID: String] = [
            .cross: "✕", .circle: "○", .square: "□", .triangle: "△",
            .l1: "L1", .r1: "R1", .l2: "L2", .r2: "R2", .l3: "L3", .r3: "R3",
            .options: "Options", .create: "Create", .ps: "PS", .touchpadClick: "Touchpad",
            .dpadUp: "↑", .dpadDown: "↓", .dpadLeft: "←", .dpadRight: "→", .share: "Share",
        ]
        #expect(expected.count == ButtonID.allCases.count)
        for button in ButtonID.allCases {
            #expect(button.displayName == expected[button], "\(button)")
        }
        let state = Self.state()
        for button in ButtonID.allCases {
            #expect(Self.button(button, in: state).label == expected[button])
        }
    }

    /// `007-controle-ipega` D-08, RN-12, RN-13: o controle ativo decide o `controller` e o resumo do touchpad.
    @Test func controleAtivo() {
        #expect(Self.state().controller == "dualSense")
        #expect(Self.state(model: .dualSense).controller == "dualSense")
        let ipega = Self.state(model: .ipega)
        #expect(ipega.controller == "ipega")
        let touchpad = Self.button(.touchpadClick, in: ipega)
        #expect(touchpad.kind == .fixed)
        #expect(touchpad.summary == "ausente neste controle")
        #expect(Self.button(.share, in: ipega).summary == "nenhuma")
        #expect(Self.button(.share, in: ipega).kind == .own)
        #expect(Self.button(.touchpadClick, in: Self.state()).summary == "clique esquerdo, fixo")
        // A ação do Share aparece também com o DualSense ativo: a configuração é única (RN-07).
        let config = ShortcutConfig(layers: [nil: [.share: .openPalette]])
        #expect(Self.button(.share, in: Self.state(config: config)).summary == "abrir paleta")
        #expect(Self.button(.share, in: Self.state(config: config, model: .ipega)).summary == "abrir paleta")
    }

    /// `012-controle-dualshock-4` D-08, RN-10: o DualShock 4 vai à página com o próprio valor e a figura do DualSense,
    /// com o touchpad presente (resumo normal) e o botão à esquerda do touchpad chamado "Create".
    @Test func dualShock4NaFigura() {
        let state = Self.state(model: .dualShock4)
        #expect(state.controller == "dualShock4")
        #expect(state.buttons.count == 19)
        #expect(state.buttons.map(\.id) == ButtonID.allCases.map(\.rawValue))
        let touchpad = Self.button(.touchpadClick, in: state)
        #expect(touchpad.kind == .fixed)
        #expect(touchpad.summary == "clique esquerdo, fixo")
        #expect(touchpad.summary != FigureState.absentSummary)
        #expect(Self.button(.create, in: state).label == "Create")
        #expect(Self.button(.share, in: state).summary == "nenhuma")
        #expect(Self.button(.share, in: state).kind == .own)
        // Fora o `controller`, o estado é o mesmo do DualSense.
        var asDualSense = state
        asDualSense.controller = ControllerModel.dualSense.rawValue
        #expect(asDualSense == Self.state(model: .dualSense))
    }

    @Test func motivoDeFalhaEmSnakeCase() {
        #expect(FigureFailureReason.resourceMissing.rawValue == "resource_missing")
        #expect(FigureFailureReason.loadFailed.rawValue == "load_failed")
        #expect(FigureFailureReason.processTerminated.rawValue == "process_terminated")
    }
}
