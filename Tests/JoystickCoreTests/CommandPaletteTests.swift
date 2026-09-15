import Testing
@testable import JoystickCore

@Suite struct CommandPaletteTests {
    // MARK: Lista fixa (RF-05, RN-05)

    @Test func listaComDezesseteItensNaOrdem() {
        let texts = CommandPalette.items.map(\.text)
        #expect(texts == [
            "CONTINUAR", "/reversa-forward", "/reversa-requirements ", "/reversa-clarify", "/reversa-plan",
            "/reversa-to-do", "/reversa-coding", "/reversa-add ", "/reversa-audit", "/reversa-quality",
            "/reversa-sync", "/reversa-resume", "/reversa-debugger ", "/reversa", "/clear", "/compact", "/resume",
        ])
    }

    @Test func itensDeUmaLinhaEDentroDoLimite() {
        for item in CommandPalette.items {
            #expect(!item.text.isEmpty && item.text.count <= 1_000, "\(item.text)")
            let hasNewline = item.text.contains { $0.isNewline }
            #expect(!hasNewline, "\(item.text)")
        }
    }

    /// Emenda E001: a paleta só coloca o texto na linha; o envio é um ✕ seguinte.
    @Test func nenhumItemEnviaEnter() {
        for item in CommandPalette.items {
            #expect(!item.pressEnter, "\(item.text)")
        }
        #expect(CommandPalette.items.filter { $0.text.hasSuffix(" ") }.count == 3)
    }

    // MARK: Máquina de estados (data-delta.md §4)

    static let count = CommandPalette.items.count

    func opened() -> PaletteMachine {
        var machine = PaletteMachine()
        _ = machine.open()
        return machine
    }

    @Test func aberturaNoPrimeiroItem() {
        var machine = PaletteMachine()
        #expect(machine.open() == [.render(PaletteSnapshot(isOpen: true, selection: 0))])
        #expect(machine.open().isEmpty)
    }

    @Test func aberturaNoUltimoConfirmado() {
        var machine = opened()
        for _ in 0..<4 { _ = machine.press(.dpadDown) }
        _ = machine.press(.cross)
        #expect(machine.lastConfirmed == 4)
        #expect(machine.open() == [.render(PaletteSnapshot(isOpen: true, selection: 4))])
    }

    @Test func navegacaoCircular() {
        var machine = opened()
        #expect(machine.press(.dpadUp) == [.render(PaletteSnapshot(isOpen: true, selection: Self.count - 1)), .startRepeat(.up)])
        _ = machine.release(.dpadUp)
        #expect(machine.press(.dpadDown) == [.render(PaletteSnapshot(isOpen: true, selection: 0)), .startRepeat(.down)])
    }

    @Test func repeticaoSoComDirecaoAtiva() {
        var machine = opened()
        #expect(machine.repeatTick().isEmpty)
        _ = machine.press(.dpadDown)
        #expect(machine.repeatTick() == [.render(PaletteSnapshot(isOpen: true, selection: 2))])
        #expect(machine.release(.dpadUp).isEmpty)
        #expect(machine.release(.dpadDown) == [.stopRepeat])
        #expect(machine.repeatTick().isEmpty)
        #expect(machine.selection == 2)
    }

    @Test func dezIntervalosDeRepeticaoAvancamDez() {
        var machine = opened()
        _ = machine.press(.dpadDown)
        for _ in 0..<10 { _ = machine.repeatTick() }
        #expect(machine.selection == 11)
    }

    @Test func confirmacaoFechaEEntregaOItem() {
        var machine = opened()
        _ = machine.press(.dpadDown)
        #expect(machine.press(.cross) == [
            .stopRepeat,
            .render(PaletteSnapshot(isOpen: false, selection: 1)),
            .confirm(index: 2, item: PaletteItem("/reversa-forward", pressEnter: false)),
        ])
        #expect(!machine.isOpen)
        #expect(machine.repeating == nil)
    }

    @Test func fechamentoPorCirculoEPorPS() {
        var machine = opened()
        #expect(machine.press(.circle) == [.render(PaletteSnapshot(isOpen: false, selection: 0)), .closed(.circle)])
        _ = machine.open()
        #expect(machine.press(.ps) == [.render(PaletteSnapshot(isOpen: false, selection: 0)), .closed(.ps)])
        #expect(machine.lastConfirmed == nil)
    }

    @Test func fechamentoExterno() {
        for reason in [PaletteCloseReason.disconnected, .injectionSuspended, .idle] {
            var machine = opened()
            #expect(machine.close(reason) == [.render(PaletteSnapshot(isOpen: false, selection: 0)), .closed(reason)])
            #expect(machine.close(reason).isEmpty)
        }
    }

    @Test func outrosBotoesIgnorados() {
        var machine = opened()
        for button in ButtonID.allCases where ![.dpadUp, .dpadDown, .cross, .circle, .ps].contains(button) {
            #expect(machine.press(button).isEmpty, "\(button)")
            #expect(machine.release(button).isEmpty, "\(button)")
        }
        #expect(machine.isOpen)
        #expect(machine.selection == 0)
    }

    @Test func fechadaNaoProduzEfeito() {
        var machine = PaletteMachine()
        for button in ButtonID.allCases {
            #expect(machine.press(button).isEmpty)
            #expect(machine.release(button).isEmpty)
        }
        #expect(machine.repeatTick().isEmpty)
        #expect(machine.close(.idle).isEmpty)
    }

    @Test func selecaoSempreDentroDaLista() {
        var machine = opened()
        let presses: [ButtonID] = [.dpadUp, .dpadUp, .dpadDown, .dpadUp, .dpadDown, .dpadDown, .dpadDown]
        for button in presses {
            _ = machine.press(button)
            for _ in 0..<(Self.count * 2) { _ = machine.repeatTick() }
            _ = machine.release(button)
            #expect((0..<Self.count).contains(machine.selection))
        }
    }
}
