import Testing
@testable import JoystickCore

extension Box where Value == VirtualControllerMachine {
    func button(_ b: VirtualButton, down: Bool, nowNs: UInt64 = 0) -> [InputEvent] {
        value.button(b, down: down, nowNs: nowNs)
    }
    func stick(_ s: VirtualStick, x: Double, y: Double, nowNs: UInt64 = 0) -> [InputEvent] {
        value.stick(s, sample: StickSample(x: x, y: y), nowNs: nowNs)
    }
    func pad(finger: Int, phase: TouchPhase, x: Double = 0, y: Double = 0, nowNs: UInt64 = 0) -> [InputEvent] {
        value.pad(PadSample(finger: finger, phase: phase, x: x, y: y), nowNs: nowNs)
    }
    func apply(mode: CenterMode, nowNs: UInt64 = 0) -> [InputEvent] { value.apply(mode: mode, nowNs: nowNs) }
    func releaseAll(nowNs: UInt64 = 0) -> [InputEvent] { value.releaseAll(nowNs: nowNs) }
}

/// Máquina do controle virtual do iPhone (`010-joystick-virtual-iphone` D-03, D-05 a D-08).
@Suite struct VirtualControllerMachineTests {
    static func machine() -> VirtualControllerMachine { VirtualControllerMachine(mode: .pointer) }

    // MARK: - Botões (T003)

    @Test func botaoViraEntradaDoControleCorrespondente() {
        let m = Box(Self.machine())
        let down = m.button(.cross, down: true, nowNs: 7)
        #expect(down.count == 1)
        #expect(down.first?.kind == .buttonDown)
        #expect(down.first?.element == .button(.cross))
        #expect(down.first?.timestamp == 7)
        #expect(down.first?.synthetic == false)
        let up = m.button(.cross, down: false, nowNs: 9)
        #expect(up.map(\.kind) == [.buttonUp])
        #expect(up.first?.element == .button(.cross))
    }

    @Test func todoBotaoTemCorrespondenteNoControleFisico() {
        let ids = Set(VirtualButton.allCases.map(\.buttonID))
        #expect(ids.count == VirtualButton.allCases.count, "correspondência precisa ser injetora")
        #expect(!ids.contains(.share), "share é só do Ipega (007 D-02)")
        #expect(ids == Set(ButtonID.allCases).subtracting([.share]))
    }

    @Test func pressionarDeNovoNaoTemEfeito() {
        let m = Box(Self.machine())
        #expect(m.button(.square, down: true).count == 1)
        #expect(m.button(.square, down: true).isEmpty)
        #expect(m.value.pressed == [.square])
        #expect(m.value.buttonCount == 1)
    }

    @Test func soltarBotaoNaoPressionadoNaoTemEfeito() {
        let m = Box(Self.machine())
        #expect(m.button(.triangle, down: false).isEmpty)
        #expect(m.value.pressed.isEmpty)
        #expect(m.value.buttonCount == 0)
    }

    @Test func contagensSomamSoOQueTemEfeito() {
        let m = Box(Self.machine())
        _ = m.button(.cross, down: true)
        _ = m.button(.cross, down: true)   // ignorado
        _ = m.button(.r1, down: true)      // clique esquerdo
        _ = m.button(.r2, down: true)      // clique direito
        _ = m.button(.touchpadClick, down: true)  // clique esquerdo
        _ = m.button(.l1, down: true)      // não é clique
        _ = m.button(.circle, down: false) // ignorado
        #expect(m.value.buttonCount == 5)
        #expect(m.value.clickCount == 3)
    }

    // MARK: - Analógicos (T004)

    @Test func amostraDoAnalogicoViraEixoComYParaCima() {
        let m = Box(Self.machine())
        let left = m.stick(.left, x: 0.5, y: 0.25, nowNs: 3)
        #expect(left.count == 1)
        #expect(left.first?.kind == .axis)
        #expect(left.first?.element == .leftStick)
        #expect(left.first?.x == 0.5)
        #expect(left.first?.y == 0.25, "o Y positivo para cima chega como veio da página")
        #expect(left.first?.timestamp == 3)
        let right = m.stick(.right, x: -0.125, y: -0.75)
        #expect(right.first?.element == .rightStick)
        #expect(right.first?.x == -0.125)
        #expect(right.first?.y == -0.75)
    }

    @Test func valoresForaDoIntervaloSaoLimitados() {
        let m = Box(Self.machine())
        let out = m.stick(.left, x: 3.0, y: -2.5)
        #expect(out.first?.x == 1.0)
        #expect(out.first?.y == -1.0)
        #expect(m.value.sticks[.left] == StickSample(x: 1.0, y: -1.0))
    }

    @Test func amostraIgualNaoGeraEvento() {
        let m = Box(Self.machine())
        #expect(m.stick(.left, x: 0.4, y: 0.4).count == 1)
        #expect(m.stick(.left, x: 0.4, y: 0.4).isEmpty)
        // O limite também vale para a comparação: 2,0 e 1,0 são a mesma amostra depois de limitados.
        #expect(m.stick(.left, x: 2.0, y: 0.4).count == 1)
        #expect(m.stick(.left, x: 3.0, y: 0.4).isEmpty)
    }

    @Test func repousoGeraUmUnicoEvento() {
        let m = Box(Self.machine())
        _ = m.stick(.left, x: 0.8, y: 0.0)
        #expect(m.stick(.left, x: 0.0, y: 0.0).count == 1)
        #expect(m.stick(.left, x: 0.0, y: 0.0).isEmpty)
        #expect(m.value.sticks[.left] == .centered)
    }

    @Test func analogicosSaoIndependentes() {
        let m = Box(Self.machine())
        _ = m.stick(.left, x: 0.5, y: 0.5)
        #expect(m.stick(.right, x: 0.5, y: 0.5).count == 1, "a amostra de um analógico não silencia o outro")
    }

    // MARK: - Área de apontamento (T005)

    @Test func dedoViraToqueComFaseEIndice() {
        let m = Box(Self.machine())
        let began = m.pad(finger: 1, phase: .began, x: 0.2, y: -0.4, nowNs: 11)
        #expect(began.count == 1)
        #expect(began.first?.kind == .touch)
        #expect(began.first?.element == .touch(1))
        #expect(began.first?.touchIndex == 1)
        #expect(began.first?.touchPhase == .began)
        #expect(began.first?.x == 0.2)
        #expect(began.first?.y == -0.4)
        #expect(began.first?.timestamp == 11)
        #expect(m.pad(finger: 1, phase: .moved, x: 0.3, y: -0.4).first?.touchPhase == .moved)
        #expect(m.pad(finger: 1, phase: .ended, x: 0.3, y: -0.4).first?.touchPhase == .ended)
        #expect(m.value.fingers.isEmpty)
    }

    @Test func coordenadaDoDedoEhLimitada() {
        let m = Box(Self.machine())
        let out = m.pad(finger: 0, phase: .began, x: -4.0, y: 2.0)
        #expect(out.first?.x == -1.0)
        #expect(out.first?.y == 1.0)
    }

    @Test func faseOrfaEhDescartada() {
        let m = Box(Self.machine())
        #expect(m.pad(finger: 0, phase: .moved).isEmpty)
        #expect(m.pad(finger: 0, phase: .ended).isEmpty)
        _ = m.pad(finger: 0, phase: .began)
        _ = m.pad(finger: 0, phase: .ended)
        #expect(m.pad(finger: 0, phase: .moved).isEmpty, "o dedo levantado não move mais")
    }

    @Test func dedoRepetidoNaoReabre() {
        let m = Box(Self.machine())
        #expect(m.pad(finger: 2, phase: .began).count == 1)
        #expect(m.pad(finger: 2, phase: .began).isEmpty)
        #expect(m.value.fingers == [2])
    }

    @Test func noMaximoQuatroDedosSimultaneos() {
        let m = Box(Self.machine())
        for finger in 0..<PadSample.maxFingers {
            #expect(m.pad(finger: finger, phase: .began).count == 1)
        }
        #expect(m.value.fingers.count == 4)
        #expect(m.pad(finger: 4, phase: .began).isEmpty, "o quinto dedo não entra")
        #expect(m.pad(finger: 4, phase: .moved).isEmpty)
        _ = m.pad(finger: 0, phase: .ended)
        #expect(m.pad(finger: 4, phase: .began).count == 1, "com uma vaga aberta, entra")
    }

    // MARK: - Troca de estado e solturas (T006)

    @Test func sairDoApontamentoSoltaBotoesEZeraAnalogicosEDedos() {
        let m = Box(Self.machine())
        _ = m.button(.cross, down: true)
        _ = m.button(.r1, down: true)
        _ = m.stick(.left, x: 0.6, y: 0.0)
        _ = m.pad(finger: 0, phase: .began)
        let events = m.apply(mode: .compact, nowNs: 42)
        #expect(events.filter { $0.kind == .buttonUp }.count == 2)
        #expect(events.allSatisfy { $0.timestamp == 42 })
        #expect(events.contains { $0.kind == .axis && $0.element == .leftStick && $0.x == 0 && $0.y == 0 })
        #expect(events.contains { $0.kind == .touch && $0.touchPhase == .ended && $0.touchIndex == 0 })
        #expect(m.value.pressed.isEmpty)
        #expect(m.value.fingers.isEmpty)
        #expect(m.value.sticks[.left] == .centered)
        #expect(m.value.mode == .compact)
    }

    @Test func trocaEntreTecladosNaoSoltaNadaDoControle() {
        let m = Box(Self.machine())
        _ = m.apply(mode: .compact)
        _ = m.button(.cross, down: true)
        let events = m.apply(mode: .full)
        #expect(events.isEmpty, "a soltura das teclas é da máquina do teclado (D-08)")
        #expect(m.value.pressed == [.cross], "botão mantido atravessa a troca entre os dois teclados")
        #expect(m.value.mode == .full)
    }

    @Test func estadoRepetidoNaoSoltaNada() {
        let m = Box(Self.machine())
        _ = m.button(.cross, down: true)
        #expect(m.apply(mode: .pointer).isEmpty)
        #expect(m.value.pressed == [.cross])
    }

    @Test func solturaGeralDevolveBotoesSinteticosEmOrdemEstavel() {
        let m = Box(Self.machine())
        _ = m.button(.touchpadClick, down: true)
        _ = m.button(.cross, down: true)
        _ = m.button(.l1, down: true)
        _ = m.stick(.right, x: 0.0, y: 0.9)
        _ = m.pad(finger: 1, phase: .began)
        let events = m.releaseAll(nowNs: 99)
        let released = events.filter { $0.kind == .buttonUp }.compactMap { event -> ButtonID? in
            guard case .button(let id)? = event.element else { return nil }
            return id
        }
        #expect(released == [.cross, .l1, .touchpadClick], "mesma ordem das solturas do controle (RN-04)")
        #expect(events.filter { $0.kind == .buttonUp }.allSatisfy { $0.synthetic })
        #expect(events.contains { $0.kind == .axis && $0.element == .rightStick && $0.x == 0 && $0.y == 0 })
        #expect(events.contains { $0.kind == .touch && $0.touchPhase == .ended && $0.touchIndex == 1 })
        #expect(events.allSatisfy { $0.timestamp == 99 })
        #expect(m.value.pressed.isEmpty)
        #expect(m.value.sticks[.right] == .centered)
        #expect(m.value.fingers.isEmpty)
    }

    @Test func solturaGeralComNadaMantidoNaoEmiteNada() {
        let m = Box(Self.machine())
        #expect(m.releaseAll().isEmpty)
        _ = m.button(.cross, down: true)
        _ = m.button(.cross, down: false)
        #expect(m.releaseAll().isEmpty)
    }

    @Test func solturaGeralNaoZeraAsContagensDaSessao() {
        let m = Box(Self.machine())
        _ = m.button(.r1, down: true)
        _ = m.releaseAll()
        #expect(m.value.buttonCount == 1)
        #expect(m.value.clickCount == 1)
        #expect(m.button(.r1, down: true).count == 1, "depois da soltura, o mesmo botão pressiona de novo")
        #expect(m.value.buttonCount == 2)
    }
}
