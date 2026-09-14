import Foundation
import Testing
@testable import JoystickCore

@Suite struct ClickStateMachineTests {
    let origin = ScreenPoint(x: 100, y: 100)
    func ms(_ value: UInt64) -> UInt64 { value * 1_000_000 }

    @Test func r1ETouchpadCompartilhamOBotaoEsquerdo() {
        var machine = ClickStateMachine(settings: PointerSettings())
        #expect(machine.press(.r1, at: origin, timeNs: ms(0)) == .down(.left, clickState: 1))
        #expect(machine.press(.touchpadClick, at: origin, timeNs: ms(10)) == nil)
        #expect(machine.release(.r1, at: origin, timeNs: ms(20)) == nil)
        #expect(machine.release(.touchpadClick, at: origin, timeNs: ms(30)) == .up(.left, clickState: 1))
        #expect(machine.heldMouseButtons.isEmpty)
    }

    @Test func r2NoBotaoDireito() {
        var machine = ClickStateMachine(settings: PointerSettings())
        #expect(machine.press(.r2, at: origin, timeNs: 0) == .down(.right, clickState: 1))
        #expect(machine.release(.r2, at: origin, timeNs: 1) == .up(.right, clickState: 1))
    }

    @Test func outrosBotoesNaoClicam() {
        var machine = ClickStateMachine(settings: PointerSettings())
        #expect(machine.press(.l1, at: origin, timeNs: 0) == nil)
        #expect(machine.press(.cross, at: origin, timeNs: 0) == nil)
    }

    @Test func duploCliqueDentroDoIntervaloEDaDistancia() {
        var machine = ClickStateMachine(settings: PointerSettings())
        _ = machine.press(.r1, at: origin, timeNs: ms(0))
        _ = machine.release(.r1, at: origin, timeNs: ms(80))
        let near = ScreenPoint(x: 103, y: 102)
        #expect(machine.press(.r1, at: near, timeNs: ms(300)) == .down(.left, clickState: 2))
        #expect(machine.release(.r1, at: near, timeNs: ms(350)) == .up(.left, clickState: 2))
    }

    @Test func foraDoIntervaloEhCliqueSimples() {
        var machine = ClickStateMachine(settings: PointerSettings())
        _ = machine.press(.r1, at: origin, timeNs: ms(0))
        _ = machine.release(.r1, at: origin, timeNs: ms(50))
        #expect(machine.press(.r1, at: origin, timeNs: ms(401)) == .down(.left, clickState: 1))
    }

    @Test func foraDaDistanciaEhCliqueSimples() {
        var machine = ClickStateMachine(settings: PointerSettings())
        _ = machine.press(.r1, at: origin, timeNs: ms(0))
        _ = machine.release(.r1, at: origin, timeNs: ms(50))
        #expect(machine.press(.r1, at: ScreenPoint(x: 105, y: 100), timeNs: ms(100)) == .down(.left, clickState: 1))
    }

    @Test func intervaloConfiguravel() {
        var settings = PointerSettings()
        settings.doubleClickIntervalMs = 600
        var machine = ClickStateMachine(settings: settings)
        _ = machine.press(.r1, at: origin, timeNs: ms(0))
        _ = machine.release(.r1, at: origin, timeNs: ms(50))
        #expect(machine.press(.r1, at: origin, timeNs: ms(550)) == .down(.left, clickState: 2))
    }

    @Test func escolhaEntreMovimentoEArraste() {
        var machine = ClickStateMachine(settings: PointerSettings())
        #expect(machine.moveKind == .move)
        _ = machine.press(.r2, at: origin, timeNs: 0)
        #expect(machine.moveKind == .rightDrag)
        _ = machine.press(.r1, at: origin, timeNs: 0)
        #expect(machine.moveKind == .leftDrag)
        _ = machine.release(.r1, at: origin, timeNs: 1)
        _ = machine.release(.r2, at: origin, timeNs: 1)
        #expect(machine.moveKind == .move)
    }

    @Test func releaseAllDevolveOsMouseUpPendentes() {
        var machine = ClickStateMachine(settings: PointerSettings())
        _ = machine.press(.r1, at: origin, timeNs: 0)
        _ = machine.press(.touchpadClick, at: origin, timeNs: 0)
        _ = machine.press(.r2, at: origin, timeNs: 0)
        let ups = machine.releaseAll()
        #expect(ups == [.up(.left, clickState: 1), .up(.right, clickState: 1)])
        #expect(machine.heldMouseButtons.isEmpty)
        #expect(machine.leftHolders.isEmpty)
        #expect(machine.releaseAll().isEmpty)
        #expect(machine.release(.r1, at: origin, timeNs: 1) == nil)
    }
}
