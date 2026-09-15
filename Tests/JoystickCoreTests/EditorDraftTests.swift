import Foundation
import Testing
@testable import JoystickCore

@Suite struct EditorDraftTests {
    static let undo = TriggerAction.chord(KeyChord(0x06, [.command]), repeats: false)

    static func draft() -> EditorDraft {
        EditorDraft(base: ShortcutDefaults.document)
    }

    // MARK: atalhos (T047)

    @Test func atribuirEVoltarAHerdar() throws {
        var draft = Self.draft()
        #expect(!draft.isDirty)
        try draft.setAction(Self.undo, for: .circle, in: .l1)
        #expect(draft.isDirty)
        #expect(draft.document.shortcuts.resolvedAction(for: .circle, in: .l1) == .init(action: Self.undo, inherited: false))
        try draft.setAction(nil, for: .circle, in: .l1)
        #expect(draft.document.shortcuts.resolvedAction(for: .circle, in: .l1).inherited)
        #expect(!draft.isDirty)
    }

    @Test func nenhumaPropriaNaCamada() throws {
        var draft = Self.draft()
        try draft.setAction(TriggerAction.none, for: .cross, in: .l2)
        #expect(draft.document.shortcuts.resolvedAction(for: .cross, in: .l2) == .init(action: .none, inherited: false))
        #expect(draft.issues.isEmpty)
    }

    /// RF-11 e cenário "Marcar modificador": L3 com Control ganha camada; desmarcar remove camada e ações próprias.
    @Test func marcarEDesmarcarModificador() throws {
        var draft = Self.draft()
        try draft.setModifier(.l3, keys: [.control])
        #expect(draft.layers == [nil, .l1, .l2, .l3, .options])
        // A "nenhuma" explícita de L3 na base e na camada Options sai com a marcação.
        #expect(draft.issues.isEmpty)
        try draft.setAction(.systemShortcut(.missionControl), for: .circle, in: .l3)
        try draft.setModifier(.l3, keys: [.control, .shift])
        #expect(draft.document.shortcuts.modifiers[.l3] == [.control, .shift])
        #expect(draft.document.shortcuts.layers[.l3]?[.circle] == .systemShortcut(.missionControl))
        draft.unsetModifier(.l3)
        #expect(draft.document.shortcuts.modifiers[.l3] == nil)
        #expect(draft.document.shortcuts.layers[.l3] == nil)
        #expect(draft.layers == [nil, .l1, .l2, .options])
    }

    /// Achado do PM-2: marcar e desmarcar devolve a "nenhuma" que a marcação tirou (R3 na camada Options).
    @Test func desmarcarDevolveNenhumaRemovida() throws {
        var draft = Self.draft()
        #expect(draft.document.shortcuts.layers[.options]?[.r3] == TriggerAction.none)
        try draft.setModifier(.r3, keys: [])
        #expect(draft.document.shortcuts.layers[.options]?[.r3] == nil)
        draft.unsetModifier(.r3)
        #expect(draft.document.shortcuts.layers[.options]?[.r3] == TriggerAction.none)
        #expect(!draft.isDirty)

        try draft.setModifier(.l3, keys: [])
        draft.unsetModifier(.l3)
        #expect(!draft.isDirty)
    }

    /// A "nenhuma" não volta a camada de modificador desmarcado nem por cima de ação escolhida depois.
    @Test func desmarcarNaoDevolveNenhumaSobreAcaoNova() throws {
        var draft = Self.draft()
        try draft.setModifier(.l3, keys: [])
        try draft.setAction(.chord(KeyChord(KeyChord.tab), repeats: false), for: .l3, in: .options)
        draft.unsetModifier(.l3)
        #expect(draft.document.shortcuts.layers[.options]?[.l3] == .chord(KeyChord(KeyChord.tab), repeats: false))
        #expect(draft.document.shortcuts.layers[nil]?[.l3] == TriggerAction.none)

        try draft.setModifier(.l3, keys: [])
        draft.rebase(to: draft.document, keepChanges: false)
        draft.unsetModifier(.options)
        draft.unsetModifier(.l3)
        #expect(draft.document.shortcuts.layers[.options] == nil)
        #expect(draft.document.shortcuts.layers[nil]?[.l3] == TriggerAction.none)
    }

    /// RF-12 e cenário "Salvar bloqueado": ✕ modificador com Enter na base destaca ✕ na base.
    @Test func modificadorComAcaoRealGeraProblema() throws {
        var draft = Self.draft()
        try draft.setModifier(.cross, keys: [])
        #expect(draft.issues.contains(EditorIssue(target: .trigger(layer: nil, button: .cross), rule: .modifierHasAction)))
        #expect(draft.issues.contains(EditorIssue(target: .trigger(layer: .l1, button: .cross), rule: .modifierHasAction)))
        try draft.setAction(nil, for: .cross, in: nil)
        try draft.setAction(nil, for: .cross, in: .l1)
        #expect(draft.issues.isEmpty)
    }

    /// RN-05: R1, R2 e o clique do touchpad não recebem ação nem viram modificadores.
    @Test func botoesDeApontamentoRecusados() {
        var draft = Self.draft()
        for button in ShortcutConfig.pointerButtons {
            #expect(throws: EditorOperationError.pointerButton) { try draft.setAction(Self.undo, for: button, in: nil) }
            #expect(throws: EditorOperationError.pointerButton) { try draft.setModifier(button, keys: []) }
        }
        #expect(!draft.isDirty)
    }

    @Test func textoDeAcaoRecusadoOuComProblema() throws {
        var draft = Self.draft()
        #expect(throws: EditorOperationError.multiline) { try draft.setAction(.text("a\nb", pressEnter: false), for: .square, in: nil) }
        #expect(throws: EditorOperationError.textTooLong) {
            try draft.setAction(.text(String(repeating: "x", count: 1_001), pressEnter: false), for: .square, in: nil)
        }
        try draft.setAction(.text("", pressEnter: true), for: .square, in: nil)
        #expect(draft.issues == [EditorIssue(target: .trigger(layer: nil, button: .square), rule: .textEmpty)])
    }

    @Test func isDirtyVoltaAFalsoAoDesfazer() throws {
        var draft = Self.draft()
        try draft.setAction(Self.undo, for: .triangle, in: nil)
        try draft.setAction(.chord(KeyChord(KeyChord.tab), repeats: false), for: .triangle, in: nil)
        #expect(!draft.isDirty)
        try draft.setModifier(.l1, keys: [.option])
        try draft.setModifier(.l1, keys: [])
        #expect(!draft.isDirty)
    }

    @Test func avisoSemGatilhoDaPaleta() throws {
        var draft = Self.draft()
        #expect(draft.warnings.isEmpty)
        try draft.setAction(TriggerAction.none, for: .ps, in: nil)
        #expect(draft.warnings == [.noPaletteTrigger])
        #expect(draft.issues.isEmpty)
        try draft.setAction(.openPalette, for: .l3, in: .l1)
        #expect(draft.warnings.isEmpty)
    }

    @Test func alvoPeloCaminho() {
        #expect(EditorDraft.target(of: "shortcuts.layers.base.cross") == .trigger(layer: nil, button: .cross))
        #expect(EditorDraft.target(of: "shortcuts.layers.l2.dpadLeft.text") == .trigger(layer: .l2, button: .dpadLeft))
        #expect(EditorDraft.target(of: "shortcuts.modifiers.r1") == .modifier(.r1))
        #expect(EditorDraft.target(of: "shortcuts.modifiers.l3[0]") == .modifier(.l3))
        #expect(EditorDraft.target(of: "shortcuts.layers.l3") == .modifier(.l3))
        #expect(EditorDraft.target(of: "palette.items[3].text") == .paletteItem(3))
        #expect(EditorDraft.target(of: "palette.items") == .palette)
        #expect(EditorDraft.target(of: "shortcuts.version") == nil)
        #expect(EditorDraft.target(of: "") == nil)
    }

    // MARK: paleta (T048)

    @Test func limitesDaPaleta() throws {
        var single = EditorDraft(base: ShortcutsDocument(shortcuts: ShortcutDefaults.config, palette: [PaletteItem("a", pressEnter: false)]))
        #expect(throws: EditorOperationError.lastPaletteItem) { try single.removePaletteItem(at: 0) }
        #expect(single.document.palette.count == 1)

        var full = Self.draft()
        while full.document.palette.count < 50 {
            try full.insertPaletteItem(PaletteItem("item", pressEnter: false), at: full.document.palette.count)
        }
        #expect(throws: EditorOperationError.paletteFull) { try full.insertPaletteItem(PaletteItem("51", pressEnter: false), at: 0) }
        #expect(full.document.palette.count == 50)
        #expect(full.issues.isEmpty)
    }

    /// Cenário "Editar a paleta": `/reversa-docs` no topo com Enter.
    @Test func incluirNoTopo() throws {
        var draft = Self.draft()
        try draft.insertPaletteItem(PaletteItem("/reversa-docs", pressEnter: true), at: 0)
        #expect(draft.document.palette.first == PaletteItem("/reversa-docs", pressEnter: true))
        #expect(draft.document.palette.count == 18)
        #expect(draft.isDirty)
    }

    @Test func edicoesRecusadasComMotivo() throws {
        var draft = Self.draft()
        #expect(throws: EditorOperationError.multiline) { try draft.insertPaletteItem(PaletteItem("a\nb", pressEnter: false), at: 0) }
        #expect(throws: EditorOperationError.multiline) { try draft.setPaletteText("colado\ncom quebra", at: 0) }
        #expect(throws: EditorOperationError.textTooLong) { try draft.setPaletteText(String(repeating: "y", count: 1_001), at: 0) }
        #expect(throws: EditorOperationError.labelTooLong) { try draft.setPaletteLabel(String(repeating: "r", count: 81), at: 0) }
        #expect(throws: EditorOperationError.multiline) { try draft.setPaletteLabel("a\rb", at: 0) }
        #expect(!draft.isDirty)
        #expect(!EditorOperationError.paletteFull.message.isEmpty)
    }

    @Test func edicoesDeItem() throws {
        var draft = Self.draft()
        try draft.setPaletteLabel("Continuar", at: 0)
        try draft.setPaletteText("CONTINUAR agora", at: 0)
        draft.setPalettePressEnter(true, at: 0)
        #expect(draft.document.palette[0] == PaletteItem("CONTINUAR agora", pressEnter: true, label: "Continuar"))
        try draft.setPaletteText("", at: 1)
        #expect(draft.issues == [EditorIssue(target: .paletteItem(1), rule: .textEmpty)])
    }

    @Test func reordenacao() throws {
        let items = ["a", "b", "c", "d"].map { PaletteItem($0, pressEnter: false) }
        var draft = EditorDraft(base: ShortcutsDocument(shortcuts: ShortcutDefaults.config, palette: items))
        func texts() -> [String] { draft.document.palette.map(\.text) }
        draft.movePaletteItemUp(at: 0)
        #expect(texts() == ["a", "b", "c", "d"])
        draft.movePaletteItemUp(at: 2)
        #expect(texts() == ["a", "c", "b", "d"])
        draft.movePaletteItemDown(at: 3)
        #expect(texts() == ["a", "c", "b", "d"])
        draft.movePaletteItemDown(at: 0)
        #expect(texts() == ["c", "a", "b", "d"])
        draft.movePaletteItems(fromOffsets: [3], toOffset: 0)
        #expect(texts() == ["d", "c", "a", "b"])
        draft.movePaletteItems(fromOffsets: [0, 1], toOffset: 4)
        #expect(texts() == ["a", "b", "d", "c"])
        draft.movePaletteItems(fromOffsets: [1], toOffset: 3)
        #expect(texts() == ["a", "d", "b", "c"])
        try draft.removePaletteItem(at: 1)
        #expect(texts() == ["a", "b", "c"])
    }

    // MARK: restauração e rebase (D-25, D-26)

    @Test func restaurarPadrao() throws {
        var custom = ShortcutDefaults.document
        custom.palette = [PaletteItem("x", pressEnter: true)]
        var draft = EditorDraft(base: custom)
        try draft.setAction(Self.undo, for: .triangle, in: nil)
        draft.restoreDefaults()
        #expect(draft.document == ShortcutDefaults.document)
        #expect(draft.base == custom)
        #expect(draft.isDirty)
    }

    @Test func rebaseDescartandoOuMantendo() throws {
        var external = ShortcutDefaults.document
        external.palette.insert(PaletteItem("de fora", pressEnter: false), at: 0)

        var reload = Self.draft()
        try reload.setAction(Self.undo, for: .triangle, in: nil)
        reload.rebase(to: external, keepChanges: false)
        #expect(reload.document == external)
        #expect(!reload.isDirty)

        var keep = Self.draft()
        try keep.setAction(Self.undo, for: .triangle, in: nil)
        let edited = keep.document
        keep.rebase(to: external, keepChanges: true)
        #expect(keep.base == external)
        #expect(keep.document == edited)
        #expect(keep.isDirty)
    }
}
