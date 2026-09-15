import Foundation
import Testing
@testable import JoystickCore

@Suite struct KeyCatalogTests {
    @Test func nomesETeclasVirtuaisUnicos() {
        let names = KeyCatalog.entries.map(\.name)
        let keyCodes = KeyCatalog.entries.map(\.keyCode)
        #expect(Set(names).count == names.count)
        #expect(Set(keyCodes).count == keyCodes.count)
    }

    @Test func idaEVoltaEntreNomeETecla() {
        for entry in KeyCatalog.entries {
            #expect(KeyCatalog.entry(named: entry.name) == entry, "\(entry.name)")
            #expect(KeyCatalog.entry(keyCode: entry.keyCode) == entry, "\(entry.name)")
        }
        #expect(KeyCatalog.entry(named: "Return") == nil)
        #expect(KeyCatalog.entry(named: "capsLock") == nil)
        #expect(KeyCatalog.entry(keyCode: 0x39) == nil)
    }

    @Test func rotulosNaoVazios() {
        for entry in KeyCatalog.entries {
            #expect(!entry.display.trimmingCharacters(in: .whitespaces).isEmpty, "\(entry.name)")
        }
    }

    @Test func todosOsGruposPresentes() {
        for group in KeyGroup.allCases {
            #expect(!KeyCatalog.entries(in: group).isEmpty, "\(group)")
        }
        #expect(KeyCatalog.entries(in: .letters).count == 26)
        #expect(KeyCatalog.entries(in: .digits).count == 10)
        #expect(KeyCatalog.entries(in: .function).count == 12)
        #expect(KeyGroup.allCases.map { KeyCatalog.entries(in: $0).count }.reduce(0, +) == KeyCatalog.entries.count)
    }

    /// Teclas listadas em D-03, com as teclas virtuais já usadas pelo mapeador.
    @Test func teclasDeD03() {
        let expected: [(String, UInt16, KeyGroup)] = [
            ("a", 0x00, .letters), ("m", KeyChord.m, .letters), ("z", 0x06, .letters),
            ("0", 0x1D, .digits), ("9", 0x19, .digits),
            ("comma", 0x2B, .punctuation), ("leftBracket", 0x21, .punctuation), ("grave", KeyChord.grave, .punctuation),
            ("return", KeyChord.returnKey, .editing), ("tab", KeyChord.tab, .editing), ("space", KeyChord.space, .editing),
            ("delete", KeyChord.delete, .editing), ("forwardDelete", 0x75, .editing), ("escape", KeyChord.escape, .editing),
            ("upArrow", KeyChord.upArrow, .navigation), ("downArrow", KeyChord.downArrow, .navigation),
            ("leftArrow", KeyChord.leftArrow, .navigation), ("rightArrow", KeyChord.rightArrow, .navigation),
            ("home", 0x73, .navigation), ("end", 0x77, .navigation), ("pageUp", 0x74, .navigation), ("pageDown", 0x79, .navigation),
            ("f1", 0x7A, .function), ("f5", 0x60, .function), ("f12", 0x6F, .function),
        ]
        for (name, keyCode, group) in expected {
            let entry = KeyCatalog.entry(named: name)
            #expect(entry?.keyCode == keyCode, "\(name)")
            #expect(entry?.group == group, "\(name)")
        }
        for n in 1...12 {
            #expect(KeyCatalog.entry(named: "f\(n)")?.display == "F\(n)")
        }
    }

    @Test func exibicaoDeAcorde() {
        #expect(KeyCatalog.display(KeyChord(0x06, [.command, .shift])) == "⇧⌘Z")
        #expect(KeyCatalog.display(KeyChord(KeyChord.tab, [.command, .option, .control])) == "⌃⌥⌘Tab")
        #expect(KeyCatalog.display(KeyChord(KeyChord.upArrow)) == "↑")
    }
}
