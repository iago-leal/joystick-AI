import Foundation
import Testing
@testable import JoystickCore

@Suite struct ShortcutMapperTests {
    // MARK: configuração padrão (T038)

    @Test func botoesSozinhos() {
        var mapper = ShortcutMapper()
        #expect(mapper.press(.cross) == [.keyDown(KeyChord(KeyChord.returnKey), repeats: false)])
        #expect(mapper.release(.cross) == [.keyUp(KeyChord(KeyChord.returnKey))])
        #expect(mapper.press(.circle) == [.keyDown(KeyChord(KeyChord.escape), repeats: false)])
        #expect(mapper.press(.square) == [.keyDown(KeyChord(KeyChord.delete), repeats: true)])
        #expect(mapper.press(.dpadDown) == [.keyDown(KeyChord(KeyChord.downArrow), repeats: true)])
        #expect(mapper.press(.create) == [.systemDown(.missionControl)])
        #expect(mapper.release(.create) == [.systemUp(.missionControl)])
    }

    /// RN-05: botões de apontamento nunca produzem ação; L1, L2 e L3 sozinhos também não.
    @Test func botoesDeApontamentoEModificadoresSemTeclas() {
        var mapper = ShortcutMapper()
        for button in [ButtonID.l1, .l2, .r1, .r2, .touchpadClick, .l3] {
            #expect(mapper.press(button).isEmpty, "\(button)")
            #expect(mapper.release(button).isEmpty, "\(button)")
        }
        var layered = ShortcutMapper()
        _ = layered.press(.l2)
        for button in ShortcutConfig.pointerButtons {
            #expect(layered.press(button).isEmpty)
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
        #expect(mapper.press(.dpadLeft) == [.systemDown(.spaceLeft)])
        #expect(mapper.press(.dpadDown) == [.systemDown(.applicationWindows)])
        #expect(mapper.press(.triangle) == [.systemDown(.nextWindow)])
        #expect(mapper.release(.dpadLeft) == [.systemUp(.spaceLeft)])
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

    /// RN-01: a ação solta é a resolvida no pressionar.
    @Test func combinacaoDecididaNoPressionar() {
        var mapper = ShortcutMapper()
        _ = mapper.press(.l2)
        _ = mapper.press(.dpadRight)
        _ = mapper.release(.l2)
        #expect(mapper.release(.dpadRight) == [.systemUp(.spaceRight)])
        #expect(mapper.press(.dpadRight) == [.keyDown(KeyChord(KeyChord.rightArrow), repeats: true)])
    }

    @Test func releaseAllSoltaTeclasAtalhosEModificador() {
        var mapper = ShortcutMapper()
        _ = mapper.press(.square)
        _ = mapper.press(.create)
        _ = mapper.press(.options)
        _ = mapper.press(.dpadRight)
        #expect(mapper.releaseAll() == [
            .keyUp(KeyChord(KeyChord.delete)), .systemUp(.missionControl), .keyUp(KeyChord(KeyChord.tab, [.command])), .modifierUp(.command),
        ])
        #expect(mapper.releaseAll().isEmpty)
        #expect(mapper.release(.options).isEmpty)
        #expect(mapper.modifierOrder.isEmpty)
        #expect(mapper.held.isEmpty)
        // Depois de soltar tudo, a camada volta à base.
        #expect(mapper.press(.cross) == [.keyDown(KeyChord(KeyChord.returnKey), repeats: false)])
    }

    @Test func r3AcionaOTranscritorDoRaycast() {
        var mapper = ShortcutMapper()
        #expect(mapper.press(.r3) == [.keyDown(KeyChord(KeyChord.m, [.command]), repeats: false)])
        #expect(mapper.release(.r3) == [.keyUp(KeyChord(KeyChord.m, [.command]))])
    }

    /// `002-paleta-comandos` RN-01: L1 e L2 repassam PS à camada base; Options não repassa.
    @Test func psAbreAPaleta() {
        var mapper = ShortcutMapper()
        #expect(mapper.press(.ps) == [.openPalette])
        #expect(mapper.release(.ps).isEmpty)
        for modifier in [ButtonID.l1, .l2] {
            var layered = ShortcutMapper()
            _ = layered.press(modifier)
            #expect(layered.press(.ps) == [.openPalette], "\(modifier)")
            #expect(layered.release(.ps).isEmpty)
        }
        var options = ShortcutMapper()
        _ = options.press(.options)
        #expect(options.press(.ps).isEmpty)
    }

    @Test func pressionarRepetidoNaoDuplica() {
        var mapper = ShortcutMapper()
        _ = mapper.press(.cross)
        #expect(mapper.press(.cross).isEmpty)
    }

    @Test func atalhosDeSistemaLidosDasPreferencias() {
        let hotKeys: [String: Any] = [
            "27": ["enabled": true, "value": ["type": "standard", "parameters": [65535, 48, 524288]]],
            "32": ["enabled": false, "value": ["type": "standard", "parameters": [65535, 99, 1048576]]],
            "79": ["enabled": true, "value": ["parameters": [65535]]],
        ]
        let chords = SystemShortcut.chords(fromSymbolicHotKeys: hotKeys)
        #expect(chords[.nextWindow] == KeyChord(KeyChord.tab, [.option]))
        #expect(chords[.missionControl] == SystemShortcut.missionControl.defaultChord)
        #expect(chords[.spaceLeft] == SystemShortcut.spaceLeft.defaultChord)
    }

    // MARK: configurações próprias (T039)

    static let enter = TriggerAction.chord(KeyChord(KeyChord.returnKey), repeats: false)

    /// L3 como modificador que mantém Control, com L3+○ em Mission Control (cenário "Camada nova com herança").
    static let l3Config = ShortcutConfig(
        modifiers: [.l3: [.control]],
        layers: [
            nil: [.cross: enter, .circle: .chord(KeyChord(KeyChord.escape), repeats: false), .triangle: .openPalette],
            .l3: [.circle: .systemShortcut(.missionControl), .triangle: TriggerAction.none],
        ]
    )

    @Test func camadaNovaComHeranca() {
        var mapper = ShortcutMapper(config: Self.l3Config)
        #expect(mapper.press(.l3) == [.modifierDown(.control)])
        #expect(mapper.press(.circle) == [.systemDown(.missionControl)])
        #expect(mapper.release(.circle) == [.systemUp(.missionControl)])
        #expect(mapper.press(.cross) == [.keyDown(KeyChord(KeyChord.returnKey), repeats: false)])
        #expect(mapper.release(.cross) == [.keyUp(KeyChord(KeyChord.returnKey))])
        #expect(mapper.release(.l3) == [.modifierUp(.control)])
    }

    @Test func nenhumaPropriaBloqueiaHeranca() {
        var mapper = ShortcutMapper(config: Self.l3Config)
        #expect(mapper.press(.triangle) == [.openPalette])
        _ = mapper.release(.triangle)
        _ = mapper.press(.l3)
        #expect(mapper.press(.triangle).isEmpty)
        #expect(mapper.release(.triangle).isEmpty)
    }

    /// RF-02 e RN-01: soltar L3 antes de ○ mantém a ação até ○ ser solto.
    @Test func modificadorSoltoAntes() {
        var mapper = ShortcutMapper(config: Self.l3Config)
        _ = mapper.press(.l3)
        _ = mapper.press(.circle)
        #expect(mapper.release(.l3) == [.modifierUp(.control)])
        #expect(mapper.currentLayer == nil)
        #expect(mapper.release(.circle) == [.systemUp(.missionControl)])
    }

    /// RN-03 e cenário "Precedência entre modificadores", nas duas ordens.
    @Test func precedenciaDoModificadorMaisAntigo() {
        var l1First = ShortcutMapper()
        _ = l1First.press(.l1)
        _ = l1First.press(.l2)
        #expect(l1First.currentLayer == .l1)
        #expect(l1First.press(.cross) == [.text("CONTINUAR", pressEnter: true)])

        var l2First = ShortcutMapper()
        _ = l2First.press(.l2)
        _ = l2First.press(.l1)
        #expect(l2First.currentLayer == .l2)
        #expect(l2First.press(.cross) == [.keyDown(KeyChord(KeyChord.returnKey), repeats: false)])
        // Soltar o mais antigo passa a camada ao seguinte.
        _ = l2First.release(.l2)
        #expect(l2First.currentLayer == .l1)
        _ = l2First.release(.cross)
        #expect(l2First.press(.cross) == [.text("CONTINUAR", pressEnter: true)])
    }

    @Test func modificadoresSobrepostosMantemTeclasEmOrdemEstavel() {
        let config = ShortcutConfig(modifiers: [.l3: [.shift, .command, .control], .options: [.command]], layers: [:])
        var mapper = ShortcutMapper(config: config)
        #expect(mapper.press(.l3) == [.modifierDown(.control), .modifierDown(.shift), .modifierDown(.command)])
        #expect(mapper.press(.options) == [.modifierDown(.command)])
        #expect(mapper.releaseAll() == [.modifierUp(.control), .modifierUp(.shift), .modifierUp(.command), .modifierUp(.command)])
    }

    @Test func ultimoGatilhoPorTipo() {
        let config = ShortcutConfig(
            modifiers: [.l1: []],
            layers: [
                nil: [.cross: Self.enter, .circle: .systemShortcut(.spaceLeft), .square: .text("a", pressEnter: false), .ps: .openPalette],
                .l1: [.cross: .text("b", pressEnter: true)],
            ]
        )
        var mapper = ShortcutMapper(config: config)
        _ = mapper.press(.cross)
        #expect(mapper.lastTrigger == ShortcutMapper.Trigger(button: .cross, layer: nil, type: .chord))
        _ = mapper.press(.circle)
        #expect(mapper.lastTrigger == ShortcutMapper.Trigger(button: .circle, layer: nil, type: .systemShortcut))
        _ = mapper.press(.square)
        #expect(mapper.lastTrigger == ShortcutMapper.Trigger(button: .square, layer: nil, type: .text))
        _ = mapper.press(.ps)
        #expect(mapper.lastTrigger == ShortcutMapper.Trigger(button: .ps, layer: nil, type: .openPalette))
        _ = mapper.press(.triangle)
        #expect(mapper.lastTrigger == nil)
        _ = mapper.press(.l1)
        #expect(mapper.lastTrigger == nil)
        _ = mapper.release(.cross)
        _ = mapper.press(.cross)
        #expect(mapper.lastTrigger == ShortcutMapper.Trigger(button: .cross, layer: .l1, type: .text))
        _ = mapper.press(.r1)
        #expect(mapper.lastTrigger == nil)
    }

    /// Invariantes de `data-delta.md` §4 sobre sequências arbitrárias da configuração padrão.
    @Test func invariantesEmSequenciasAleatorias() {
        var generator = SystemRandomNumberGenerator()
        for _ in 0..<200 {
            var mapper = ShortcutMapper()
            var modifierCount: [KeyModifier: Int] = [:]
            var down: [ButtonID: ShortcutAction] = [:]
            for _ in 0..<30 {
                let button = ButtonID.allCases.randomElement(using: &generator)!
                let pressing = !mapper.held.contains(button)
                let actions = pressing ? mapper.press(button) : mapper.release(button)
                for action in actions {
                    switch action {
                    case .modifierDown(let key): modifierCount[key, default: 0] += 1
                    case .modifierUp(let key): modifierCount[key, default: 0] -= 1
                    case .keyDown(let chord, _): down[button] = .keyUp(chord)
                    case .systemDown(let shortcut): down[button] = .systemUp(shortcut)
                    case .keyUp, .systemUp: #expect(down.removeValue(forKey: button) == action)
                    default: break
                    }
                }
                if ShortcutConfig.pointerButtons.contains(button) { #expect(actions.isEmpty) }
                if ShortcutDefaults.config.isModifier(button) {
                    #expect(actions.allSatisfy { if case .modifierDown = $0 { true } else if case .modifierUp = $0 { true } else { false } })
                }
            }
            for action in mapper.releaseAll() {
                if case .modifierUp(let key) = action { modifierCount[key, default: 0] -= 1 }
            }
            #expect(modifierCount.values.allSatisfy { $0 == 0 })
        }
    }
}
