import Foundation
import Testing
@testable import JoystickCore

@Suite struct ConfigLineLocatorTests {
    static let text = """
    {
      "pointer": {
        "stickMaxSpeed": 1800
      },
      "shortcuts": {
        "version": 1,
        "modifiers": { "l1": [], "l3": ["control",
          "shift"] },
        "layers": {
          "base": {
            "cross": { "type": "text", "text": "chave } e ] e { dentro \\" da cadeia" },
            "circle": {
              "type": "chord",
              "key": "escape"
            }
          },
          "l1": {
            "cross": { "type": "none" }
          }
        }
      },
      "palette": {
        "version": 1,
        "items": [
          { "text": "a" },
          { "text": "b", "label": "[x]" },
          {
            "text": "c"
          }
        ]
      }
    }
    """

    static func line(_ path: String, _ text: String = text) -> Int? {
        ConfigLineLocator.line(of: path, in: Data(text.utf8))
    }

    @Test func caminhosAninhados() {
        #expect(Self.line("pointer") == 2)
        #expect(Self.line("pointer.stickMaxSpeed") == 3)
        #expect(Self.line("shortcuts.version") == 6)
        #expect(Self.line("shortcuts.layers.base.circle") == 12)
        #expect(Self.line("shortcuts.layers.base.circle.key") == 14)
    }

    @Test func caminhosComIndice() {
        #expect(Self.line("palette.items[0]") == 25)
        #expect(Self.line("palette.items[1].label") == 26)
        #expect(Self.line("palette.items[2]") == 27)
        #expect(Self.line("palette.items[2].text") == 28)
        #expect(Self.line("shortcuts.modifiers.l3[1]") == 8)
    }

    @Test func delimitadoresEAspasDentroDeCadeias() {
        #expect(Self.line("shortcuts.layers.base.cross.text") == 11)
        // Depois da cadeia com chaves, colchetes e aspas escapadas, a varredura continua sincronizada.
        #expect(Self.line("shortcuts.layers.l1.cross.type") == 18)
    }

    @Test func mesmaChaveEmObjetosDiferentes() {
        #expect(Self.line("shortcuts.layers.base.cross") == 11)
        #expect(Self.line("shortcuts.layers.l1.cross") == 18)
        #expect(Self.line("palette.version") == 23)
    }

    @Test func caminhoInexistente() {
        #expect(Self.line("shortcuts.layers.l2") == nil)
        #expect(Self.line("palette.items[3]") == nil)
        #expect(Self.line("shortcuts.version.x") == nil)
        #expect(Self.line("pointer[0]") == nil)
        #expect(Self.line("palette.items[") == nil)
        #expect(ConfigLineLocator.nearestLine(of: "shortcuts.layers.l1.cross.key", in: Data(Self.text.utf8)) == 18)
        #expect(ConfigLineLocator.nearestLine(of: "outra.coisa", in: Data(Self.text.utf8)) == nil)
    }

    @Test func quebrasDeLinhaCRLF() {
        let crlf = Self.text.replacingOccurrences(of: "\n", with: "\r\n")
        #expect(Self.line("shortcuts.layers.base.circle.key", crlf) == 14)
        #expect(Self.line("palette.items[2].text", crlf) == 28)
    }

    @Test func chaveComEscapeUnicode() {
        let text = "{\n  \"a\\u0062\": {\n    \"c\": 1\n  }\n}"
        #expect(Self.line("ab.c", text) == 3)
    }
}
