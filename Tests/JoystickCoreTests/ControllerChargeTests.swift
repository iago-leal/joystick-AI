import Testing
@testable import JoystickCore

/// Decisão de exibição da carga do controle ativo (`011-bateria-e-cursor-no-menu` D-02, D-03, RN-01 a RN-07).
///
/// A tabela de verdade que estes testes percorrem está em `data-delta.md` §2. O ponto sensível é a precedência:
/// a indisponibilidade nasce do estado reportado, nunca do valor do nível, porque o cabeçalho do sistema entrega
/// nível padrão 0 e estado padrão desconhecido para o controle que não conta quanta carga tem.
@Suite struct ControllerChargeTests {
    @Test func semControleAtivoNaoMostraNumero() {
        #expect(ChargeDisplay.decide(hasActiveController: false, charge: nil) == .noController)
    }

    /// O controle virtual do iPhone não é controle ativo (RN-05): com ele em uso e nenhum físico, vale RN-03.
    @Test func semControleAtivoIgnoraLeituraResidual() {
        let residual = ControllerCharge(level: 0.38, state: .discharging)
        #expect(ChargeDisplay.decide(hasActiveController: false, charge: residual) == .noController)
    }

    @Test func controleSemPropriedadeDeCargaEhIndisponivel() {
        #expect(ChargeDisplay.decide(hasActiveController: true, charge: nil) == .unavailable)
    }

    /// O caso que D-02 existe para impedir: nível 0 com estado desconhecido não pode virar "0%" na tela.
    @Test func estadoDesconhecidoEhIndisponivelSejaQualForONivel() {
        for level in [0.0, 0.5, 1.0] {
            #expect(ChargeDisplay.decide(hasActiveController: true, charge: ControllerCharge(level: level, state: .unknown)) == .unavailable)
        }
    }

    @Test func nivelZeroComEstadoConhecidoNaoEhIndisponivel() {
        let display = ChargeDisplay.decide(hasActiveController: true, charge: ControllerCharge(level: 0.0, state: .discharging))
        #expect(display != .unavailable)
        #expect(display != .noController)
    }

    // MARK: porcentagem e carregamento

    @Test func porcentagemEhONivelVezesCemArredondado() {
        let casos: [(Double, Int)] = [(0.0, 0), (0.15, 15), (0.151, 15), (0.16, 16), (0.38, 38), (0.384, 38), (0.385, 39), (1.0, 100)]
        for (level, percent) in casos {
            #expect(ChargeDisplay.decide(hasActiveController: true, charge: ControllerCharge(level: level, state: .discharging))
                    == .known(percent: percent, charging: false, low: percent <= 15))
        }
    }

    /// O cabeçalho do sistema documenta a faixa de 0,0 a 1,0, mas nada impede um valor fora dela; o que o usuário
    /// lê continua sendo uma porcentagem.
    @Test func porcentagemFicaEntreZeroECem() {
        #expect(ChargeDisplay.decide(hasActiveController: true, charge: ControllerCharge(level: -0.5, state: .discharging))
                == .known(percent: 0, charging: false, low: true))
        #expect(ChargeDisplay.decide(hasActiveController: true, charge: ControllerCharge(level: 2.0, state: .charging))
                == .known(percent: 100, charging: true, low: false))
    }

    @Test func carregandoValeNosDoisEstadosDeCabo() {
        #expect(ChargeDisplay.decide(hasActiveController: true, charge: ControllerCharge(level: 0.38, state: .charging))
                == .known(percent: 38, charging: true, low: false))
        #expect(ChargeDisplay.decide(hasActiveController: true, charge: ControllerCharge(level: 1.0, state: .full))
                == .known(percent: 100, charging: true, low: false))
    }

    @Test func descarregandoNaoTrazMarcaDeCarregamento() {
        #expect(ChargeDisplay.decide(hasActiveController: true, charge: ControllerCharge(level: 0.38, state: .discharging))
                == .known(percent: 38, charging: false, low: false))
    }

    // MARK: faixa baixa

    /// O arredondamento acontece **antes** da comparação com o limite: a faixa baixa é definida sobre o número que
    /// o usuário lê, e não sobre a fração interna. Sem essa ordem, 0,154 apareceria como 15% sem destaque, e dois
    /// controles no mesmo número teriam marcações diferentes.
    @Test func faixaBaixaVaiAteQuinzePorCentoInclusive() {
        for level in [0.0, 0.05, 0.15, 0.151, 0.154] {
            let display = ChargeDisplay.decide(hasActiveController: true, charge: ControllerCharge(level: level, state: .discharging))
            #expect(display.isLow, "nível \(level) deveria estar na faixa baixa")
        }
    }

    @Test func acimaDeQuinzePorCentoNaoRecebeDestaque() {
        for level in [0.155, 0.16, 0.38, 1.0] {
            let display = ChargeDisplay.decide(hasActiveController: true, charge: ControllerCharge(level: level, state: .discharging))
            #expect(!display.isLow, "nível \(level) não deveria estar na faixa baixa")
        }
    }

    /// 0,155 arredonda para 16 e sai da faixa; 0,154 arredonda para 15 e fica. A fronteira é do número lido.
    @Test func fronteiraDaFaixaBaixaEhDoNumeroLido() {
        #expect(ChargeDisplay.decide(hasActiveController: true, charge: ControllerCharge(level: 0.154, state: .discharging))
                == .known(percent: 15, charging: false, low: true))
        #expect(ChargeDisplay.decide(hasActiveController: true, charge: ControllerCharge(level: 0.155, state: .discharging))
                == .known(percent: 16, charging: false, low: false))
    }

    @Test func cargaBaixaNoCaboContinuaBaixaEComMarcaDeCarregamento() {
        #expect(ChargeDisplay.decide(hasActiveController: true, charge: ControllerCharge(level: 0.12, state: .charging))
                == .known(percent: 12, charging: true, low: true))
    }

    @Test func semControleEIndisponivelNaoTemFaixaBaixa() {
        #expect(!ChargeDisplay.noController.isLow)
        #expect(!ChargeDisplay.unavailable.isLow)
    }
}
