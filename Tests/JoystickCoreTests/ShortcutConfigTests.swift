import Foundation
import Testing
@testable import JoystickCore

@Suite struct ShortcutConfigTests {
    static let enter = TriggerAction.chord(KeyChord(KeyChord.returnKey), repeats: false)
    static let undo = TriggerAction.chord(KeyChord(0x06, [.command]), repeats: false)

    static let config = ShortcutConfig(
        modifiers: [.l1: [], .l3: [.control]],
        layers: [
            nil: [.cross: enter, .circle: .systemShortcut(.missionControl)],
            .l1: [.cross: .text("CONTINUAR", pressEnter: true), .circle: TriggerAction.none],
            .l3: [:],
        ]
    )

    @Test func acaoPropriaNaCamada() {
        let resolution = Self.config.resolvedAction(for: .cross, in: .l1)
        #expect(resolution == ShortcutConfig.Resolution(action: .text("CONTINUAR", pressEnter: true), inherited: false))
        #expect(Self.config.resolvedAction(for: .cross, in: nil) == ShortcutConfig.Resolution(action: Self.enter, inherited: false))
    }

    @Test func acaoHerdadaDaBase() {
        #expect(Self.config.resolvedAction(for: .cross, in: .l3) == ShortcutConfig.Resolution(action: Self.enter, inherited: true))
        #expect(Self.config.resolvedAction(for: .circle, in: .l3)
            == ShortcutConfig.Resolution(action: .systemShortcut(.missionControl), inherited: true))
    }

    /// RN-02: "nenhuma" própria conta como ação e bloqueia a herança.
    @Test func nenhumaPropriaBloqueiaHeranca() {
        #expect(Self.config.resolvedAction(for: .circle, in: .l1) == ShortcutConfig.Resolution(action: .none, inherited: false))
    }

    @Test func botaoAusenteNaBase() {
        #expect(Self.config.resolvedAction(for: .square, in: nil) == ShortcutConfig.Resolution(action: .none, inherited: false))
        #expect(Self.config.resolvedAction(for: .square, in: .l1) == ShortcutConfig.Resolution(action: .none, inherited: true))
    }

    @Test func camadaSemEntradaNoDicionarioHerda() {
        let config = ShortcutConfig(modifiers: [.l2: []], layers: [nil: [.triangle: Self.undo]])
        #expect(config.resolvedAction(for: .triangle, in: .l2) == ShortcutConfig.Resolution(action: Self.undo, inherited: true))
        #expect(config.isModifier(.l2))
        #expect(!config.isModifier(.triangle))
    }

    @Test func tipoDaAcao() {
        #expect(Self.enter.type == .chord)
        #expect(TriggerAction.systemShortcut(.spaceLeft).type == .systemShortcut)
        #expect(TriggerAction.text("x", pressEnter: false).type == .text)
        #expect(TriggerAction.openPalette.type == .openPalette)
        #expect(TriggerAction.none.type == nil)
    }

    @Test func atalhoDeSistemaIdaEVoltaPeloNome() {
        let names = SystemShortcut.allCases.map(\.name)
        #expect(Set(names) == ["spaceLeft", "spaceRight", "missionControl", "applicationWindows", "nextWindow"])
        for shortcut in SystemShortcut.allCases {
            #expect(SystemShortcut(name: shortcut.name) == shortcut)
            #expect(!shortcut.displayName.isEmpty)
        }
        #expect(SystemShortcut(name: "MissionControl") == nil)
        #expect(SystemShortcut.spaceLeft.displayName == "mesa à esquerda")
    }
}
