import Foundation
import Testing
@testable import JoystickCore

@Suite struct ShortcutMapperTests {
    @Test func botoesSozinhos() {
        var mapper = ShortcutMapper()
        #expect(mapper.press(.cross) == [.keyDown(KeyChord(KeyChord.returnKey), repeats: false)])
        #expect(mapper.release(.cross) == [.keyUp(KeyChord(KeyChord.returnKey))])
        #expect(mapper.press(.circle) == [.keyDown(KeyChord(KeyChord.escape), repeats: false)])
        #expect(mapper.press(.square) == [.keyDown(KeyChord(KeyChord.delete), repeats: true)])
        #expect(mapper.press(.dpadDown) == [.keyDown(KeyChord(KeyChord.downArrow), repeats: true)])
        #expect(mapper.press(.create) == [.keyDown(KeyChord(KeyChord.upArrow, [.control]), repeats: false)])
    }

    @Test func botoesDoPonteiroNaoGeramTeclas() {
        var mapper = ShortcutMapper()
        for button in [ButtonID.l1, .l2, .r1, .r2, .touchpadClick, .l3, .ps] {
            #expect(mapper.press(button).isEmpty)
            #expect(mapper.release(button).isEmpty)
        }
    }

    @Test func l1ComXDigitaContinuar() {
        var mapper = ShortcutMapper()
        _ = mapper.press(.l1)
        #expect(mapper.press(.cross) == [.text("CONTINUAR", pressEnter: true)])
        #expect(mapper.release(.cross).isEmpty)
        #expect(mapper.press(.triangle) == [.keyDown(KeyChord(KeyChord.tab, [.shift]), repeats: false)])
    }

    @Test func l2ComDirecionalTrocaDeMesa() {
        var mapper = ShortcutMapper()
        _ = mapper.press(.l2)
        #expect(mapper.press(.dpadLeft) == [.keyDown(KeyChord(KeyChord.leftArrow, [.control]), repeats: false)])
        #expect(mapper.press(.dpadDown) == [.keyDown(KeyChord(KeyChord.downArrow, [.control]), repeats: false)])
        #expect(mapper.press(.triangle) == [.keyDown(KeyChord(KeyChord.grave, [.command]), repeats: false)])
    }

    @Test func optionsSeguraCommandParaAlternarApps() {
        var mapper = ShortcutMapper()
        #expect(mapper.press(.options) == [.modifierDown(.command)])
        #expect(mapper.press(.dpadRight) == [.keyDown(KeyChord(KeyChord.tab, [.command]), repeats: false)])
        #expect(mapper.release(.dpadRight) == [.keyUp(KeyChord(KeyChord.tab, [.command]))])
        #expect(mapper.press(.dpadLeft) == [.keyDown(KeyChord(KeyChord.tab, [.command, .shift]), repeats: false)])
        #expect(mapper.press(.cross).isEmpty)
        #expect(mapper.release(.options) == [.modifierUp(.command)])
    }

    @Test func combinacaoDecididaNoPressionar() {
        var mapper = ShortcutMapper()
        _ = mapper.press(.l2)
        _ = mapper.press(.dpadRight)
        _ = mapper.release(.l2)
        // L2 solto antes: a tecla solta é a mesma que foi pressionada.
        #expect(mapper.release(.dpadRight) == [.keyUp(KeyChord(KeyChord.rightArrow, [.control]))])
        #expect(mapper.press(.dpadRight) == [.keyDown(KeyChord(KeyChord.rightArrow), repeats: true)])
    }

    @Test func releaseAllSoltaTeclasEModificador() {
        var mapper = ShortcutMapper()
        _ = mapper.press(.square)
        _ = mapper.press(.options)
        _ = mapper.press(.dpadRight)
        #expect(mapper.releaseAll() == [
            .keyUp(KeyChord(KeyChord.delete)), .keyUp(KeyChord(KeyChord.tab, [.command])), .modifierUp(.command),
        ])
        #expect(mapper.releaseAll().isEmpty)
        #expect(mapper.release(.options).isEmpty)
    }

    @Test func atalhosDeSistemaLidosDaConfiguracao() {
        let hotKeys: [String: Any] = [
            "27": ["enabled": true, "value": ["type": "standard", "parameters": [65535, 48, 524288]]],
            "32": ["enabled": false, "value": ["type": "standard", "parameters": [65535, 99, 1048576]]],
            "79": ["enabled": true, "value": ["parameters": [65535]]],
        ]
        let chords = SystemShortcut.chords(fromSymbolicHotKeys: hotKeys)
        #expect(chords[.nextWindow] == KeyChord(KeyChord.tab, [.option]))
        #expect(chords[.missionControl] == SystemShortcut.missionControl.defaultChord)
        #expect(chords[.spaceLeft] == SystemShortcut.spaceLeft.defaultChord)
        var mapper = ShortcutMapper(systemChords: chords)
        _ = mapper.press(.l2)
        #expect(mapper.press(.triangle) == [.keyDown(KeyChord(KeyChord.tab, [.option]), repeats: false)])
    }

    @Test func r3AcionaOTranscritorDoRaycast() {
        var mapper = ShortcutMapper()
        #expect(mapper.press(.r3) == [.keyDown(KeyChord(KeyChord.m, [.command]), repeats: false)])
        #expect(mapper.release(.r3) == [.keyUp(KeyChord(KeyChord.m, [.command]))])
    }

    @Test func pressionarRepetidoNaoDuplica() {
        var mapper = ShortcutMapper()
        _ = mapper.press(.cross)
        #expect(mapper.press(.cross).isEmpty)
    }
}
