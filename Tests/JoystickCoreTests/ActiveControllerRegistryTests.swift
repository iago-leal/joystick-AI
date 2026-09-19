import Foundation
import Testing
@testable import JoystickCore

@Suite struct ActiveControllerRegistryTests {
    func info(_ name: String, at t: UInt64 = 0, model: ControllerModel = .dualSense) -> ControllerInfo {
        ControllerInfo(id: UUID(), name: name, connection: .bluetooth, connectedAt: t, atStartup: false, model: model)
    }

    @Test func primeiroDualSenseEhOAtivo() {
        var registry = ActiveControllerRegistry<Int>()
        let first = info("DualSense")
        #expect(registry.connect(key: 1, info: first, accepted: true) == .active)
        #expect(registry.active == first)
    }

    @Test func segundoFicaNaFilaComPosicao() {
        var registry = ActiveControllerRegistry<Int>()
        _ = registry.connect(key: 1, info: info("A"), accepted: true)
        let second = info("B")
        #expect(registry.connect(key: 2, info: second, accepted: true) == .queued(position: 1))
        #expect(registry.queue.count == 2)
        #expect(registry.active?.name == "A")
    }

    @Test func outroModeloEhIgnorado() {
        var registry = ActiveControllerRegistry<Int>()
        #expect(registry.connect(key: 1, info: info("Xbox"), accepted: false) == .ignored)
        #expect(registry.active == nil)
        #expect(registry.queue.isEmpty)
    }

    @Test func segundaConexaoDoMesmoControleEhDescartada() {
        var registry = ActiveControllerRegistry<Int>()
        _ = registry.connect(key: 7, info: info("A"), accepted: true)
        #expect(registry.connect(key: 7, info: info("A de novo"), accepted: true) == .duplicate)
        #expect(registry.queue.count == 1)
        #expect(registry.active?.name == "A")
    }

    @Test func desconexaoDoAtivoSoltaBotoesEPromoveOSeguinte() {
        var registry = ActiveControllerRegistry<Int>()
        _ = registry.connect(key: 1, info: info("A"), accepted: true)
        _ = registry.connect(key: 2, info: info("B"), accepted: true)
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
        _ = registry.connect(key: 1, info: info("A"), accepted: true)
        _ = registry.connect(key: 2, info: info("B"), accepted: true)
        let accepted = registry.press(.cross, from: 2)
        #expect(!accepted)
        #expect(registry.pressed.isEmpty)
    }

    @Test func desconexaoDeNaoAtivoApenasRemove() {
        var registry = ActiveControllerRegistry<Int>()
        _ = registry.connect(key: 1, info: info("A"), accepted: true)
        _ = registry.connect(key: 2, info: info("B"), accepted: true)
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
        _ = registry.connect(key: 1, info: info("A"), accepted: true)
        _ = registry.press(.r2, from: 1)
        let drop = registry.disconnect(key: 1)
        #expect(drop.syntheticReleases == [.r2])
        #expect(registry.active == nil)

        #expect(registry.connect(key: 3, info: info("A reconectado"), accepted: true) == .active)
        #expect(registry.queue.count == 1)
        #expect(registry.pressed.isEmpty)
    }

    @Test func desconexaoDesconhecidaNaoAlteraNada() {
        var registry = ActiveControllerRegistry<Int>()
        _ = registry.connect(key: 1, info: info("A"), accepted: true)
        let outcome = registry.disconnect(key: 9)
        #expect(outcome.removed == nil)
        #expect(registry.active?.name == "A")
    }

    // MARK: `007-controle-ipega` D-05, RN-09

    @Test func modeloNaoAceitoEhIgnorado() {
        var registry = ActiveControllerRegistry<Int>()
        #expect(registry.connect(key: 1, info: info("Pro Controller", model: .ipega), accepted: false) == .ignored)
        #expect(registry.queue.isEmpty)
    }

    @Test func filaMistaComPromocao() {
        var registry = ActiveControllerRegistry<Int>()
        #expect(registry.connect(key: 1, info: info("DualSense"), accepted: true) == .active)
        #expect(registry.connect(key: 2, info: info("Pro Controller", model: .ipega), accepted: true) == .queued(position: 1))
        #expect(registry.active?.model == .dualSense)

        let outcome = registry.disconnect(key: 1)
        #expect(outcome.promoted?.model == .ipega)
        #expect(registry.active?.model == .ipega)
        #expect(registry.isActive(2))
    }

    @Test func solturaSinteticaIncluiShareEmOrdem() {
        var registry = ActiveControllerRegistry<Int>()
        _ = registry.connect(key: 1, info: info("Pro Controller", model: .ipega), accepted: true)
        for button in [ButtonID.share, .r2, .cross, .dpadRight] {
            _ = registry.press(button, from: 1)
        }
        let outcome = registry.disconnect(key: 1)
        #expect(outcome.syntheticReleases == [.cross, .r2, .dpadRight, .share])
        #expect(registry.pressed.isEmpty)
    }
}
