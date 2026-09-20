import Testing
@testable import JoystickCore

/// União dos botões das duas origens de entrada (`010-joystick-virtual-iphone` D-04).
@Suite struct CombinedPressedTests {
    @Test func uniaoDevolveOsBotoesDasDuasOrigens() {
        let combined = CombinedPressed(controller: [.l1, .cross], virtual: [.r2])
        #expect(combined.all == [.l1, .cross, .r2])
        #expect(combined.contains(.l1))
        #expect(combined.contains(.r2))
        #expect(!combined.contains(.square))
        #expect(!combined.isEmpty)
    }

    @Test func uniaoVaziaQuandoNenhumaOrigemMantemNada() {
        let combined = CombinedPressed()
        #expect(combined.all.isEmpty)
        #expect(combined.isEmpty)
        #expect(!combined.contains(.cross))
    }

    @Test func solturaDeUmaOrigemNaoRemoveOsDaOutra() {
        var combined = CombinedPressed(controller: [.l1], virtual: [.cross, .r1])
        combined.virtual.remove(.cross)
        #expect(combined.all == [.l1, .r1])
        combined.controller.removeAll()
        #expect(combined.all == [.r1], "o controle desconectado não solta o que o iPhone mantém")
    }

    @Test func mesmoBotaoNasDuasOrigensSoSaiQuandoAsDuasSoltam() {
        var combined = CombinedPressed(controller: [.l1], virtual: [.l1])
        #expect(combined.all == [.l1])
        combined.controller.remove(.l1)
        #expect(combined.contains(.l1), "o iPhone ainda o mantém")
        combined.virtual.remove(.l1)
        #expect(!combined.contains(.l1))
        #expect(combined.isEmpty)
    }

    @Test func precisaoDeL1ValeComQualquerDasOrigens() {
        // RN-08: precisão só com L1 e nenhum outro botão, venha ele de onde vier.
        #expect(PointerMotionEngine.precisionActive(pressed: CombinedPressed(virtual: [.l1]).all))
        #expect(PointerMotionEngine.precisionActive(pressed: CombinedPressed(controller: [.l1], virtual: [.l1]).all))
        #expect(!PointerMotionEngine.precisionActive(pressed: CombinedPressed(controller: [.l1], virtual: [.cross]).all))
        #expect(!PointerMotionEngine.precisionActive(pressed: CombinedPressed(virtual: [.l1, .r1]).all))
    }
}
