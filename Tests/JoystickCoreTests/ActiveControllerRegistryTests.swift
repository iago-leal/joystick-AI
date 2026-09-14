import Foundation
import Testing
@testable import JoystickCore

@Suite struct ActiveControllerRegistryTests {
    func info(_ name: String, at t: UInt64 = 0) -> ControllerInfo {
        ControllerInfo(id: UUID(), name: name, connection: .bluetooth, connectedAt: t, atStartup: false)
    }

    @Test func primeiroDualSenseEhOAtivo() {
        var registry = ActiveControllerRegistry<Int>()
        let first = info("DualSense")
        #expect(registry.connect(key: 1, info: first, isDualSense: true) == .active)
        #expect(registry.active == first)
    }

    @Test func segundoFicaNaFilaComPosicao() {
        var registry = ActiveControllerRegistry<Int>()
        _ = registry.connect(key: 1, info: info("A"), isDualSense: true)
        let second = info("B")
        #expect(registry.connect(key: 2, info: second, isDualSense: true) == .queued(position: 1))
        #expect(registry.queue.count == 2)
        #expect(registry.active?.name == "A")
    }

    @Test func outroModeloEhIgnorado() {
        var registry = ActiveControllerRegistry<Int>()
        #expect(registry.connect(key: 1, info: info("Xbox"), isDualSense: false) == .ignored)
        #expect(registry.active == nil)
        #expect(registry.queue.isEmpty)
    }

    @Test func segundaConexaoDoMesmoControleEhDescartada() {
        var registry = ActiveControllerRegistry<Int>()
        _ = registry.connect(key: 7, info: info("A"), isDualSense: true)
        #expect(registry.connect(key: 7, info: info("A de novo"), isDualSense: true) == .duplicate)
        #expect(registry.queue.count == 1)
        #expect(registry.active?.name == "A")
    }

    @Test func desconexaoDoAtivoSoltaBotoesEPromoveOSeguinte() {
        var registry = ActiveControllerRegistry<Int>()
        _ = registry.connect(key: 1, info: info("A"), isDualSense: true)
        _ = registry.connect(key: 2, info: info("B"), isDualSense: true)
        let pressedR2 = registry.press(.r2, from: 1)
        let pressedL1 = registry.press(.l1, from: 1)
        #expect(pressedR2 && pressedL1)

        let outcome = registry.disconnect(key: 1)
        #expect(outcome.wasActive)
        #expect(outcome.removed?.name == "A")
        #expect(outcome.syntheticReleases == [.l1, .r2])
        #expect(outcome.promoted?.name == "B")
        #expect(registry.pressed.isEmpty)
        #expect(registry.active?.name == "B")
    }

    @Test func botoesDoControleNaoAtivoSaoIgnorados() {
        var registry = ActiveControllerRegistry<Int>()
        _ = registry.connect(key: 1, info: info("A"), isDualSense: true)
        _ = registry.connect(key: 2, info: info("B"), isDualSense: true)
        let accepted = registry.press(.cross, from: 2)
        #expect(!accepted)
        #expect(registry.pressed.isEmpty)
    }

    @Test func desconexaoDeNaoAtivoApenasRemove() {
        var registry = ActiveControllerRegistry<Int>()
        _ = registry.connect(key: 1, info: info("A"), isDualSense: true)
        _ = registry.connect(key: 2, info: info("B"), isDualSense: true)
        _ = registry.press(.cross, from: 1)

        let outcome = registry.disconnect(key: 2)
        #expect(!outcome.wasActive)
        #expect(outcome.syntheticReleases.isEmpty)
        #expect(outcome.promoted == nil)
        #expect(registry.pressed == [.cross])
        #expect(registry.active?.name == "A")
    }

    @Test func quedaEReconexaoRapidasMantemUmUnicoAtivo() {
        var registry = ActiveControllerRegistry<Int>()
        _ = registry.connect(key: 1, info: info("A"), isDualSense: true)
        _ = registry.press(.r2, from: 1)
        let drop = registry.disconnect(key: 1)
        #expect(drop.syntheticReleases == [.r2])
        #expect(registry.active == nil)

        #expect(registry.connect(key: 3, info: info("A reconectado"), isDualSense: true) == .active)
        #expect(registry.queue.count == 1)
        #expect(registry.pressed.isEmpty)
    }

    @Test func desconexaoDesconhecidaNaoAlteraNada() {
        var registry = ActiveControllerRegistry<Int>()
        _ = registry.connect(key: 1, info: info("A"), isDualSense: true)
        let outcome = registry.disconnect(key: 9)
        #expect(outcome.removed == nil)
        #expect(registry.active?.name == "A")
    }
}
