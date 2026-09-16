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

    /// `005-sinais-matematicos` RF-03 e RF-06: `equal` com ⇧ aparece como `+`, sem ampliar o catálogo.
    @Test func exibicaoDoSinalDeSoma() {
        #expect(KeyCatalog.display(KeyChord(KeyChord.equal, [.command, .shift])) == "⌘+")
        #expect(KeyCatalog.display(KeyChord(KeyChord.equal, [.option, .command, .shift])) == "⌥⌘+")
        #expect(KeyCatalog.display(KeyChord(KeyChord.equal, [.command])) == "⌘=")
        #expect(KeyCatalog.display(KeyChord(0x1B, [.command])) == "⌘-")
        #expect(KeyCatalog.display(KeyChord(KeyChord.equal, [.shift])) == "+")
        #expect(KeyCatalog.entries.count == 73)
        #expect(KeyCatalog.entry(named: "plus") == nil)
    }

    /// `005-sinais-matematicos` RF-01: `+` logo após `-`, só na pontuação.
    @Test func escolhasDaGrade() {
        #expect(KeyCatalog.choices(in: .punctuation).prefix(3).map(\.display) == ["-", "+", "="])
        #expect(KeyCatalog.choices(in: .punctuation).count == KeyCatalog.entries(in: .punctuation).count + 1)
        for group in KeyGroup.allCases where group != .punctuation {
            #expect(KeyCatalog.choices(in: group) == KeyCatalog.entries(in: group).map(KeyChoice.key), "\(group)")
        }
    }

    /// `005-sinais-matematicos` RF-02 e D-03: as cinco linhas da tabela de `data-delta.md` §3.
    @Test func aplicacaoESelecaoDasEscolhas() throws {
        let choices = KeyCatalog.choices(in: .punctuation)
        let plus = try #require(choices.first { $0.id == "plus" })
        let equal = try #require(choices.first { $0.id == "equal" })
        let minus = try #require(choices.first { $0.id == "minus" })
        let z = KeyChord(0x06, [.command])
        let cases: [(KeyChord, KeyChoice, KeyChord, String, Bool, Bool)] = [
            (z, plus, KeyChord(KeyChord.equal, [.command, .shift]), "⌘+", true, false),
            (KeyChord(0x06, [.option, .command]), plus, KeyChord(KeyChord.equal, [.option, .command, .shift]), "⌥⌘+", true, false),
            (KeyChord(KeyChord.equal, [.command, .shift]), equal, KeyChord(KeyChord.equal, [.command]), "⌘=", false, true),
            (KeyChord(KeyChord.equal, [.command, .shift]), minus, KeyChord(0x1B, [.command]), "⌘-", false, false),
            (KeyChord(0x06, [.command, .shift]), equal, KeyChord(KeyChord.equal, [.command, .shift]), "⌘+", true, false),
        ]
        for (current, choice, expected, display, plusSelected, equalSelected) in cases {
            let result = choice.applied(to: current)
            #expect(result == expected, "\(KeyCatalog.display(current)) + \(choice.id)")
            #expect(KeyCatalog.display(result) == display)
            #expect(plus.isSelected(in: result) == plusSelected, "\(display)")
            #expect(equal.isSelected(in: result) == equalSelected, "\(display)")
        }
        #expect(minus.isSelected(in: KeyChord(0x1B, [.command])))
        #expect(KeyChoice.key(try #require(KeyCatalog.entry(named: "z"))).isSelected(in: KeyChord(0x06, [.command, .shift])))
    }
}
