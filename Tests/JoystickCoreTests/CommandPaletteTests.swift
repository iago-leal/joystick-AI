import Testing
@testable import JoystickCore

@Suite struct CommandPaletteTests {
    // MARK: Lista padrão (002 RF-05, RN-05; 003 RN-11, RN-12)

    @Test func listaComDezesseteItensNaOrdem() {
        let texts = PaletteDefaults.items.map(\.text)
        #expect(texts == [
            "CONTINUAR", "/reversa-forward", "/reversa-requirements ", "/reversa-clarify", "/reversa-plan",
            "/reversa-to-do", "/reversa-coding", "/reversa-add ", "/reversa-audit", "/reversa-quality",
            "/reversa-sync", "/reversa-resume", "/reversa-debugger ", "/reversa", "/clear", "/compact", "/resume",
        ])
    }

    @Test func itensDeUmaLinhaEDentroDoLimite() {
        for item in PaletteDefaults.items {
            #expect(!item.text.isEmpty && item.text.count <= 1_000, "\(item.text)")
            let hasNewline = item.text.contains { $0.isNewline }
            #expect(!hasNewline, "\(item.text)")
        }
    }

    /// Emenda E001: a paleta só coloca o texto na linha; o envio é um ✕ seguinte.
    @Test func nenhumItemEnviaEnter() {
        for item in PaletteDefaults.items {
            #expect(!item.pressEnter, "\(item.text)")
        }
        #expect(PaletteDefaults.items.filter { $0.text.hasSuffix(" ") }.count == 3)
    }

    @Test func itensPadraoSemRotulo() {
        for item in PaletteDefaults.items {
            #expect(item.label.isEmpty, "\(item.text)")
            #expect(item.displayText == item.text)
        }
    }

    @Test func rotuloExibidoNoLugarDoTexto() {
        #expect(PaletteItem("/reversa-docs", pressEnter: true, label: "Documentação").displayText == "Documentação")
        #expect(PaletteItem("/reversa-docs", pressEnter: true).displayText == "/reversa-docs")
    }

    @Test func motivoDeConfiguracaoNova() {
        #expect(PaletteCloseReason.configChanged.rawValue == "config_changed")
    }

    // MARK: Máquina de estados (002 data-delta.md §4; 003 D-13)

    static let count = PaletteDefaults.items.count
    /// Itens mais a entrada fixa "Editar atalhos".
    static let entries = count + 1

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
        // ↑ no primeiro item leva à entrada fixa, a última posição.
        #expect(machine.press(.dpadUp) == [.render(PaletteSnapshot(isOpen: true, selection: Self.count)), .startRepeat(.up)])
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
            for _ in 0..<(Self.entries * 2) { _ = machine.repeatTick() }
            _ = machine.release(button)
            #expect((0..<Self.entries).contains(machine.selection))
        }
    }

    // MARK: Entrada fixa "Editar atalhos" (003 RF-07, RN-12)

    @Test func entradaFixaDepoisDosItens() {
        let machine = PaletteMachine()
        #expect(machine.editorEntryIndex == Self.count)
        #expect(machine.entryCount == Self.entries)
        #expect(PaletteMachine.editorEntryTitle == "Editar atalhos")
    }

    @Test func confirmarEntradaFixaAbreOEditorSemDigitar() {
        var machine = opened()
        _ = machine.press(.dpadDown)
        _ = machine.release(.dpadDown)
        _ = machine.press(.cross)
        #expect(machine.lastConfirmed == 1)

        _ = machine.open()
        _ = machine.press(.dpadUp)
        _ = machine.release(.dpadUp)
        _ = machine.press(.dpadUp)
        _ = machine.release(.dpadUp)
        #expect(machine.selection == Self.count)
        let effects = machine.press(.cross)
        #expect(effects == [.render(PaletteSnapshot(isOpen: false, selection: Self.count)), .openEditor])
        #expect(!effects.contains { if case .confirm = $0 { true } else { false } })
        // A entrada fixa não passa a ser a última confirmada.
        #expect(machine.lastConfirmed == 1)
        #expect(machine.open() == [.render(PaletteSnapshot(isOpen: true, selection: 1))])
    }

    @Test func listaConfiguradaComEntradaFixa() {
        let items = [PaletteItem("/reversa-docs", pressEnter: true), PaletteItem("CONTINUAR", pressEnter: false)]
        var machine = PaletteMachine(items: items)
        _ = machine.open()
        _ = machine.press(.dpadDown)
        _ = machine.release(.dpadDown)
        _ = machine.press(.dpadDown)
        _ = machine.release(.dpadDown)
        #expect(machine.selection == 2)
        _ = machine.press(.dpadDown)
        #expect(machine.selection == 0)
        _ = machine.release(.dpadDown)
        #expect(machine.press(.cross).last == .confirm(index: 1, item: items[0]))
    }
}
