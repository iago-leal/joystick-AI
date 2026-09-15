import Foundation
import Testing
@testable import JoystickCore

@Suite struct ConfigDocumentTests {
    static func decode(_ data: Data) throws -> (root: JSONValue, document: ShortcutsDocument) {
        let root = try JSONDecoder().decode(JSONValue.self, from: data)
        return (root, try ShortcutConfigValidation.decode(root: root).get())
    }

    static let customDocument: ShortcutsDocument = {
        var config = ShortcutDefaults.config
        config.modifiers[.l3] = [.control]
        config.layers[.l3] = [.circle: .systemShortcut(.missionControl), .cross: TriggerAction.none]
        config.layers[nil]?[.triangle] = .chord(KeyChord(0x06, [.command, .shift]), repeats: false)
        config.layers[nil]?[.l3] = nil
        config.layers[.options]?[.l3] = nil
        let palette = [
            PaletteItem("/reversa-docs", pressEnter: true, label: "Documentação"),
            PaletteItem("texto com \"aspas\", barra / e acentuação", pressEnter: false),
        ]
        return ShortcutsDocument(shortcuts: config, palette: palette)
    }()

    @Test func idaEVoltaDoPadrao() throws {
        let data = ConfigDocument.merge(existing: nil, document: ShortcutDefaults.document)
        #expect(try Self.decode(data).document == ShortcutDefaults.document)
    }

    @Test func idaEVoltaComCamadaNova() throws {
        let data = ConfigDocument.merge(existing: nil, document: Self.customDocument)
        #expect(try Self.decode(data).document == Self.customDocument)
    }

    /// RN-10 e RF-05: `pointer` e chaves desconhecidas preservadas por valor.
    @Test func fusaoPreservaOutrasSecoes() throws {
        let existing = try JSONDecoder().decode(JSONValue.self, from: Data("""
        {
          "pointer": { "stickMaxSpeed": 1800, "deadzone": 0.12, "invertScrollY": true },
          "futuro": { "lista": [1, "dois", null] },
          "shortcuts": { "version": 1, "layers": { "base": { "cross": { "type": "none" } } } }
        }
        """.utf8))
        let data = ConfigDocument.merge(existing: existing, document: Self.customDocument)
        let (root, document) = try Self.decode(data)
        #expect(document == Self.customDocument)
        #expect(root["pointer"] == existing["pointer"])
        #expect(root["futuro"] == existing["futuro"])
        #expect(ConfigLoader.parse(data: data).settings.stickMaxSpeed == 1800)
    }

    @Test func raizAusenteOuNaoObjetoCriaObjeto() throws {
        for existing in [nil, JSONValue.array([1, 2]), .string("x")] {
            let (root, document) = try Self.decode(ConfigDocument.merge(existing: existing, document: ShortcutDefaults.document))
            guard case .object(let fields) = root else {
                Issue.record("raiz não é objeto")
                continue
            }
            #expect(Set(fields.keys) == ["shortcuts", "palette"])
            #expect(document == ShortcutDefaults.document)
        }
    }

    @Test func mesmosBytesEmDuasGravacoes() throws {
        let existing = try JSONDecoder().decode(JSONValue.self, from: Data(#"{"pointer": {"scrollSpeed": 90}}"#.utf8))
        let first = ConfigDocument.merge(existing: existing, document: Self.customDocument)
        let reread = try JSONDecoder().decode(JSONValue.self, from: first)
        let second = ConfigDocument.merge(existing: reread, document: Self.customDocument)
        #expect(first == second)
        #expect(ConfigDocument.merge(existing: existing, document: Self.customDocument) == first)
    }

    @Test func formatoLegivel() {
        let text = String(decoding: ConfigDocument.merge(existing: nil, document: Self.customDocument), as: UTF8.self)
        #expect(text.contains("\n  \"palette\" : {"))
        #expect(text.contains("/reversa-docs"))
        #expect(!text.contains("\\/"))
        #expect(text.hasSuffix("}\n"))
        // Padrões omitidos: sem `repeat` falso nem `modifiers` vazio nas ações.
        #expect(!text.contains("\"repeat\" : false"))
        #expect(text.contains("\"key\" : \"z\""))
    }

    @Test func camadaVaziaEquivaleAAusente() throws {
        var config = ShortcutDefaults.config
        config.modifiers[.l3] = []
        config.layers[nil]?[.l3] = nil
        config.layers[.options]?[.l3] = nil
        let withEmpty = ShortcutConfig(modifiers: config.modifiers, layers: config.layers.merging([.l3: [:]]) { $1 })
        let data = ConfigDocument.merge(existing: nil, document: ShortcutsDocument(shortcuts: withEmpty, palette: PaletteDefaults.items))
        #expect(try Self.decode(data).document.shortcuts == config)
    }

    @Test func teclaForaDoCatalogoRecusada() {
        var document = ShortcutDefaults.document
        document.shortcuts.layers[nil]?[.cross] = .chord(KeyChord(0x39), repeats: false)
        #expect(ShortcutConfigValidation.validate(document) == [ShortcutIssue(path: "shortcuts.layers.base.cross.key", rule: .unknownKey)])
    }
}
