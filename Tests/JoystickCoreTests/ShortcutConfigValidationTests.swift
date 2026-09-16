import Foundation
import Testing
@testable import JoystickCore

@Suite struct ShortcutConfigValidationTests {
    static func root(_ json: String) -> JSONValue {
        try! JSONDecoder().decode(JSONValue.self, from: Data(json.utf8))
    }

    static func issues(_ json: String) -> [ShortcutIssue] {
        switch ShortcutConfigValidation.decode(root: root(json)) {
        case .success: []
        case .failure(let failure): failure.issues
        }
    }

    static func document(_ json: String) -> ShortcutsDocument? {
        try? ShortcutConfigValidation.decode(root: root(json)).get()
    }

    /// Seção `shortcuts` com uma camada `base` contendo `trigger` e, opcionalmente, outros trechos.
    static func shortcuts(base: String = "", modifiers: String = "", layers: String = "") -> String {
        var sections = [#""version": 1"#]
        if !modifiers.isEmpty { sections.append(#""modifiers": {\#(modifiers)}"#) }
        var layerList: [String] = []
        if !base.isEmpty { layerList.append(#""base": {\#(base)}"#) }
        if !layers.isEmpty { layerList.append(layers) }
        if !layerList.isEmpty { sections.append(#""layers": {\#(layerList.joined(separator: ", "))}"#) }
        return #"{"shortcuts": {\#(sections.joined(separator: ", "))}}"#
    }

    static func expectIssue(_ json: String, _ path: String, _ rule: ShortcutIssue.Rule, sourceLocation: SourceLocation = #_sourceLocation) {
        let found = issues(json)
        #expect(found.contains(ShortcutIssue(path: path, rule: rule)), "\(found)", sourceLocation: sourceLocation)
    }

    // MARK: shortcuts, estrutura (T024)

    @Test func secaoCompletaDecodificada() {
        let json = Self.shortcuts(
            base: """
            "dpadUp": {"type": "chord", "key": "upArrow", "repeat": true},
            "triangle": {"type": "chord", "key": "z", "modifiers": ["command", "shift"]},
            "create": {"type": "systemShortcut", "name": "missionControl"},
            "ps": {"type": "openPalette"},
            "l3": {"type": "none"},
            "square": {"type": "text", "text": "CONTINUAR", "pressEnter": true}
            """,
            modifiers: #""l1": [], "options": ["command"]"#,
            layers: #""l1": {"cross": {"type": "text", "text": "ok"}}"#
        )
        let document = Self.document(json)
        #expect(document?.shortcuts == ShortcutConfig(
            modifiers: [.l1: [], .options: [.command]],
            layers: [
                nil: [
                    .dpadUp: .chord(KeyChord(KeyChord.upArrow), repeats: true),
                    .triangle: .chord(KeyChord(0x06, [.command, .shift]), repeats: false),
                    .create: .systemShortcut(.missionControl),
                    .ps: .openPalette,
                    .l3: TriggerAction.none,
                    .square: .text("CONTINUAR", pressEnter: true),
                ],
                .l1: [.cross: .text("ok", pressEnter: false)],
            ]
        ))
        #expect(document?.palette == PaletteDefaults.items)
    }

    /// `006-teclado-virtual` D-02: o Atalho de Acessibilidade é aceito pelo nome.
    @Test func atalhoDeAcessibilidadeAceito() {
        let json = Self.shortcuts(base: #""l3": {"type": "systemShortcut", "name": "accessibilityShortcut"}"#)
        #expect(Self.issues(json).isEmpty)
        #expect(Self.document(json)?.shortcuts.layers[nil]?[.l3] == .systemShortcut(.accessibilityShortcut))
    }

    @Test func versaoNaoSuportada() {
        Self.expectIssue(#"{"shortcuts": {"version": 2}}"#, "shortcuts.version", .unsupportedVersion)
        Self.expectIssue(#"{"shortcuts": {}}"#, "shortcuts.version", .unsupportedVersion)
        Self.expectIssue(#"{"shortcuts": {"version": "1"}}"#, "shortcuts.version", .wrongType)
    }

    @Test func teclaDesconhecida() {
        Self.expectIssue(Self.shortcuts(base: #""cross": {"type": "chord", "key": "enter"}"#), "shortcuts.layers.base.cross.key", .unknownKey)
    }

    @Test func modificadorDeTeclaDesconhecido() {
        Self.expectIssue(Self.shortcuts(base: #""cross": {"type": "chord", "key": "z", "modifiers": ["cmd"]}"#),
                         "shortcuts.layers.base.cross.modifiers[0]", .unknownModifier)
        Self.expectIssue(Self.shortcuts(modifiers: #""l3": ["control", "hyper"]"#), "shortcuts.modifiers.l3[1]", .unknownModifier)
        Self.expectIssue(Self.shortcuts(modifiers: #""l3": ["shift", "shift"]"#), "shortcuts.modifiers.l3[1]", .wrongType)
    }

    @Test func atalhoDeSistemaDesconhecido() {
        Self.expectIssue(Self.shortcuts(base: #""create": {"type": "systemShortcut", "name": "launchpad"}"#),
                         "shortcuts.layers.base.create.name", .unknownSystemShortcut)
    }

    @Test func tipoDeAcaoDesconhecido() {
        Self.expectIssue(Self.shortcuts(base: #""cross": {"type": "openApp"}"#), "shortcuts.layers.base.cross.type", .unknownActionType)
    }

    @Test func tiposErrados() {
        Self.expectIssue(#"{"shortcuts": []}"#, "shortcuts", .wrongType)
        Self.expectIssue(#"{"shortcuts": {"version": 1, "modifiers": []}}"#, "shortcuts.modifiers", .wrongType)
        Self.expectIssue(#"{"shortcuts": {"version": 1, "layers": 3}}"#, "shortcuts.layers", .wrongType)
        Self.expectIssue(Self.shortcuts(modifiers: #""l4": []"#), "shortcuts.modifiers.l4", .wrongType)
        Self.expectIssue(Self.shortcuts(modifiers: #""l3": "control""#), "shortcuts.modifiers.l3", .wrongType)
        Self.expectIssue(Self.shortcuts(layers: #""top": {}"#), "shortcuts.layers.top", .wrongType)
        Self.expectIssue(Self.shortcuts(base: #""x": {"type": "none"}"#), "shortcuts.layers.base.x", .wrongType)
        Self.expectIssue(Self.shortcuts(base: #""cross": "return""#), "shortcuts.layers.base.cross", .wrongType)
        Self.expectIssue(Self.shortcuts(base: #""cross": {"key": "return"}"#), "shortcuts.layers.base.cross.type", .wrongType)
        Self.expectIssue(Self.shortcuts(base: #""cross": {"type": "chord"}"#), "shortcuts.layers.base.cross.key", .wrongType)
        Self.expectIssue(Self.shortcuts(base: #""cross": {"type": "chord", "key": "z", "repeat": 1}"#), "shortcuts.layers.base.cross.repeat", .wrongType)
        Self.expectIssue(Self.shortcuts(base: #""cross": {"type": "text"}"#), "shortcuts.layers.base.cross.text", .wrongType)
        Self.expectIssue(Self.shortcuts(base: #""cross": {"type": "text", "text": "a", "pressEnter": "sim"}"#),
                         "shortcuts.layers.base.cross.pressEnter", .wrongType)
    }

    // MARK: shortcuts, regras semânticas (T023)

    /// RN-05 e cenário "Botões de apontamento fixos".
    @Test func botoesDeApontamentoFixos() {
        Self.expectIssue(Self.shortcuts(modifiers: #""r1": []"#), "shortcuts.modifiers.r1", .pointerButtonNotAllowed)
        Self.expectIssue(Self.shortcuts(modifiers: #""touchpadClick": ["shift"]"#), "shortcuts.modifiers.touchpadClick", .pointerButtonNotAllowed)
        Self.expectIssue(Self.shortcuts(base: #""r1": {"type": "chord", "key": "z"}"#), "shortcuts.layers.base.r1", .pointerButtonNotAllowed)
        Self.expectIssue(Self.shortcuts(modifiers: #""l1": []"#, layers: #""l1": {"r2": {"type": "none"}}"#),
                         "shortcuts.layers.l1.r2", .pointerButtonNotAllowed)
    }

    @Test func camadaSemModificador() {
        Self.expectIssue(Self.shortcuts(layers: #""l3": {"circle": {"type": "none"}}"#), "shortcuts.layers.l3", .layerWithoutModifier)
    }

    /// RN-04 e RF-12: modificador fora de toda camada, inclusive a própria e a base.
    @Test func modificadorComAcao() {
        Self.expectIssue(Self.shortcuts(base: #""cross": {"type": "chord", "key": "return"}"#, modifiers: #""cross": []"#),
                         "shortcuts.layers.base.cross", .modifierHasAction)
        Self.expectIssue(Self.shortcuts(modifiers: #""l1": [], "l2": []"#, layers: #""l1": {"l2": {"type": "none"}}"#),
                         "shortcuts.layers.l1.l2", .modifierHasAction)
    }

    @Test func textoDeAcaoForaDosLimites() {
        let long = String(repeating: "a", count: 1_001)
        Self.expectIssue(Self.shortcuts(base: #""cross": {"type": "text", "text": ""}"#), "shortcuts.layers.base.cross.text", .textEmpty)
        Self.expectIssue(Self.shortcuts(base: #""cross": {"type": "text", "text": "a\nb"}"#), "shortcuts.layers.base.cross.text", .multiline)
        Self.expectIssue(Self.shortcuts(base: #""cross": {"type": "text", "text": "\#(long)"}"#), "shortcuts.layers.base.cross.text", .textTooLong)
        let limit = String(repeating: "á", count: 1_000)
        #expect(Self.issues(Self.shortcuts(base: #""cross": {"type": "text", "text": "\#(limit)"}"#)).isEmpty)
    }

    /// RN-14: a mensagem de um problema é caminho e regra; o valor recusado não aparece.
    @Test func problemaSemValorRecusado() {
        let found = Self.issues(Self.shortcuts(base: #""cross": {"type": "chord", "key": "segredoXYZ"}"#))
        #expect(found == [ShortcutIssue(path: "shortcuts.layers.base.cross.key", rule: .unknownKey)])
        for issue in found {
            #expect(!issue.path.contains("segredoXYZ"))
            #expect(!issue.rule.rawValue.contains("segredoXYZ"))
        }
    }

    @Test func formatoDoCaminho() {
        #expect(ShortcutConfigValidation.path(layer: nil) == "shortcuts.layers.base")
        #expect(ShortcutConfigValidation.path(layer: .l2) == "shortcuts.layers.l2")
        let config = ShortcutConfig(modifiers: [.l2: []], layers: [.l2: [.dpadLeft: .text("", pressEnter: false)]])
        #expect(ShortcutConfigValidation.validate(ShortcutsDocument(shortcuts: config, palette: PaletteDefaults.items))
            == [ShortcutIssue(path: "shortcuts.layers.l2.dpadLeft.text", rule: .textEmpty)])
    }

    // MARK: palette (T027)

    static func palette(_ items: [String]) -> String {
        #"{"palette": {"version": 1, "items": [\#(items.joined(separator: ", "))]}}"#
    }

    static func items(_ count: Int) -> [String] {
        (0..<count).map { #"{"text": "item \#($0)"}"# }
    }

    @Test func quantidadeDeItens() {
        Self.expectIssue(Self.palette([]), "palette.items", .paletteEmpty)
        #expect(Self.document(Self.palette(Self.items(1)))?.palette.count == 1)
        #expect(Self.document(Self.palette(Self.items(50)))?.palette.count == 50)
        Self.expectIssue(Self.palette(Self.items(51)), "palette.items", .paletteTooLong)
    }

    @Test func itemDecodificadoComPadroes() {
        let document = Self.document(Self.palette([
            #"{"text": "CONTINUAR"}"#,
            #"{"label": "Documentação", "text": "/reversa-docs", "pressEnter": true}"#,
        ]))
        #expect(document?.palette == [
            PaletteItem("CONTINUAR", pressEnter: false),
            PaletteItem("/reversa-docs", pressEnter: true, label: "Documentação"),
        ])
        #expect(document?.shortcuts == ShortcutDefaults.config)
    }

    @Test func textoERotuloNosLimites() {
        let text1000 = String(repeating: "x", count: 1_000)
        let label80 = String(repeating: "r", count: 80)
        #expect(Self.issues(Self.palette([#"{"text": "\#(text1000)", "label": "\#(label80)"}"#])).isEmpty)
        Self.expectIssue(Self.palette([#"{"text": "\#(text1000)x"}"#]), "palette.items[0].text", .textTooLong)
        Self.expectIssue(Self.palette([#"{"text": "a", "label": "\#(label80)r"}"#]), "palette.items[0].label", .labelTooLong)
        Self.expectIssue(Self.palette([#"{"text": ""}"#]), "palette.items[0].text", .textEmpty)
        Self.expectIssue(Self.palette([#"{"text": "a"}"#, #"{"text": "b\r\nc"}"#]), "palette.items[1].text", .multiline)
        Self.expectIssue(Self.palette([#"{"text": "a", "label": "x\ny"}"#]), "palette.items[0].label", .multiline)
        Self.expectIssue(Self.palette([#"{"text": 3}"#]), "palette.items[0].text", .wrongType)
        Self.expectIssue(Self.palette([#""solto""#]), "palette.items[0]", .wrongType)
        Self.expectIssue(#"{"palette": {"version": 1}}"#, "palette.items", .wrongType)
        Self.expectIssue(#"{"palette": {"items": []}}"#, "palette.version", .unsupportedVersion)
    }

    // MARK: seções e RN-08

    @Test func secoesAusentesValemOPadrao() throws {
        let root = Self.root(#"{"pointer": {"stickMaxSpeed": 1800}}"#)
        #expect(try ShortcutConfigValidation.decode(root: root).get() == ShortcutDefaults.document)
        #expect(ShortcutConfigValidation.sections(in: root) == .init(shortcuts: false, palette: false))
    }

    @Test func soUmaSecaoPresente() {
        let json = Self.shortcuts(base: #""triangle": {"type": "chord", "key": "z", "modifiers": ["command"]}"#)
        let document = Self.document(json)
        #expect(document?.shortcuts.layers[nil]?[.triangle] == .chord(KeyChord(0x06, [.command]), repeats: false))
        #expect(document?.palette == PaletteDefaults.items)
        #expect(ShortcutConfigValidation.sections(in: Self.root(json)) == .init(shortcuts: true, palette: false))
    }

    /// RN-08: um erro em qualquer das seções recusa as duas.
    @Test func erroNumaSecaoRecusaAsDuas() {
        let paletteError = #"{"shortcuts": {"version": 1}, "palette": {"version": 1, "items": []}}"#
        #expect(Self.document(paletteError) == nil)
        #expect(Self.issues(paletteError) == [ShortcutIssue(path: "palette.items", rule: .paletteEmpty)])
        let shortcutsError = #"{"shortcuts": {"version": 3}, "palette": {"version": 1, "items": [{"text": "ok"}]}}"#
        #expect(Self.document(shortcutsError) == nil)
        #expect(Self.issues(shortcutsError) == [ShortcutIssue(path: "shortcuts.version", rule: .unsupportedVersion)])
        let both = #"{"shortcuts": {"version": 3}, "palette": {"version": 1, "items": []}}"#
        #expect(Self.issues(both).count == 2)
    }

    @Test func padraoSemProblemas() {
        #expect(ShortcutConfigValidation.validate(ShortcutDefaults.document).isEmpty)
    }
}
