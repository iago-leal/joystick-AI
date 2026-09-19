# Impacto no legado: Controle Ipega ao lado do DualSense

> Identificador: `007-controle-ipega`
> Data: `2026-09-19`
> Âncora: legado (`_reversa_sdd/architecture.md` + `_reversa_sdd/domain.md`, extração de 2026-09-15, com os adendos das features 001 a 006), com as specs SDD de `_reversa_sdd/sdd/` como complemento.
> Política de edição no momento da execução: `allowLegacyEdits: true`, `allowedPaths` vazio (liberação irrestrita do projeto), relida na ativação do `/reversa-coding`.
> Execução: parcial; 32 de 33 ações fechadas numa rodada. Parada no portão manual PM-1, que libera T033. Suíte: 280 → 306 testes, todos verdes (302 na rodada, +4 com a revisão de D-03 no PM-1); `swift build -c release` sem avisos novos; app instalado e assinado com a identidade estável.

O app deixa de aceitar só o `GCDualSenseGamepad` e passa a conhecer um modelo de controle, `ControllerModel` (`dualSense`, `ipega`), no núcleo. O Ipega é reconhecido pela categoria "Switch Pro Controller" somada à presença no IORegistry do par (0x057E, 0x2009). A leitura escolhe a tabela de botões pelo modelo: a do Ipega repete a do DualSense por posição, troca o clique do touchpad pelo Share e não liga touchpad; o Home vem do relatório HID `0x30`. O Share ganha o identificador `share`, no fim de `ButtonID`, e herda tudo o que os botões livres têm. O documento padrão não muda. A figura do editor recebe o modelo ativo e, com o Ipega, mostra o Share e marca o touchpad como ausente.

## Arquivos afetados

| Arquivo afetado | Componente | Tipo | Severidade | Justificativa |
|-----------------|------------|------|------------|---------------|
| `Sources/JoystickCore/Input/ControllerModel.swift` | Núcleo, pipeline de entrada (`code-analysis.md` §0.2) | componente-novo | MEDIUM | `ControllerModel` com os pares de cada modelo, `matches`, `buttons` (18 por modelo) e `classify(productCategory:isDualSenseProfile:hidDevices:)`. Decide quem é aceito (RN-EC-03). |
| `Sources/JoystickCore/Input/InputEvent.swift` | Núcleo, `ButtonID` e `ControllerInfo` (`data-dictionary.md`) | regra-alterada | HIGH | `ButtonID` passa de 18 para 19 casos, com `share` no fim; `ControllerInfo` ganha `model` (padrão `.dualSense`). Todo consumidor de `ButtonID.allCases` passa a ver 19 itens: camadas do editor, figura, soltura sintética, cobertura. A ordem dos 18 anteriores é fixada por teste. |
| `Sources/JoystickCore/Config/ButtonLabels.swift` | `editor` (RN-ED-14) | regra-alterada | LOW | Rótulo "Share". |
| `Sources/JoystickCore/Input/ActiveControllerRegistry.swift` | `controller-input` (RN-EC-01, RN-EC-03) | regra-alterada | MEDIUM | `connect(key:info:isDualSense:)` vira `connect(key:info:accepted:)`; `.ignored` significa "modelo não aceito". Lógica da fila e da soltura intacta. |
| `Sources/JoystickCore/Input/SwitchProReport.swift` | Núcleo, leitura HID (RI-08) | componente-novo | MEDIUM | Bit `0x10` do byte 4 no relatório `0x30` com ≥ 13 bytes; analógicos nos bytes 6 a 11 (12 bits por eixo, −1…1, y para cima), acrescentados na revisão de D-03 no PM-1; demais relatórios, `nil`. |
| `Sources/JoystickCore/Config/ShortcutDefaults.swift` | `shortcuts` (RN-AT-19, 003 RN-11) | regra-alterada | LOW | `share` fora do laço que grava "nenhuma" em Options, para o documento padrão ficar idêntico. Efeito colateral registrado nas notas de execução: em Options, o Share herda a ação da base. |
| `Sources/JoystickCore/Config/FigureState.swift` | `editor`, ponte da figura (`addenda/004-figura-controle-web.md`) | delta-de-contrato-externo | MEDIUM | Campo `controller`, 19 itens, resumo "ausente neste controle" no touchpad com o Ipega. Contrato da ponte emendado em `interfaces/figure-bridge.md`. |
| `Sources/JoystickCore/Log/LogEventCatalog.swift` | `diagnostics-log` (`architecture.md` §5) | delta-de-contrato-externo | LOW | `controller.connected` ganha `model`. O motivo `unsupported_model` é passado pelo app. `logSchema` segue 1. |
| `Sources/JoystickCore/Analysis/LogAnalysis.swift` | `targets-analysis` / `poc-tools` | regra-alterada | LOW | `ButtonCoverage` ganha `model` e `expected`; a contagem considera só os 18 botões do modelo do último `controller.connected` (DualSense sem o campo). |
| `Sources/poc-tools/ButtonsCommand.swift`, `Sources/poc-tools/main.swift` | `poc-tools` | regra-alterada | LOW | `buttons` imprime o modelo e a tabela do conjunto esperado; "Total: N de 18". |
| `Sources/JoystickAIPoC/Controller/TransportResolver.swift` | `controller-input` (RN-EC-14, I-02) | regra-alterada | MEDIUM | `resolve(for:)` por modelo; `presentDevices()` expõe os pares do IORegistry para a classificação; constantes Sony removidas (vêm do modelo). |
| `Sources/JoystickAIPoC/Controller/ExtendedReportActivator.swift` | `controller-input` (RN-EC-12, RN-EC-13, RN-EC-17, I-02) | regra-alterada | HIGH | Casa também (0x057E, 0x2009); estado do PS/Home por dispositivo emissor, limpo na remoção; intérprete escolhido pelo par do emissor; `0x05` só para o DualSense sem fio; `onIpegaSticks` repassa só as mudanças dos analógicos do Ipega. `onHomeButton` passa o modelo do emissor, e o `ControllerReader` só entrega se o ativo for do mesmo modelo (refinamento de RN-EC-17). |
| `Sources/JoystickAIPoC/Controller/ButtonReader.swift` | `controller-input` (RN-EC-16) | regra-alterada | HIGH | Recebe `GCExtendedGamepad`, perfil e modelo; o 14º item é `touchpadClick` no DualSense e `share` (`GCInputButtonShare`) no Ipega; o resto da tabela é comum. |
| `Sources/JoystickAIPoC/Controller/AxisTouchReader.swift` | `controller-input` (RN-EC-08, RN-EC-10, RN-EC-11) | regra-alterada | MEDIUM | Touchpad, `controller.touch_source` e analógicos pela interface de controles só no DualSense. `deliverStick` (normalização e deduplicação) passa a ser comum às duas vias. Revisão de D-03 no PM-1: o driver do sistema zera os eixos do Ipega, e os analógicos dele vêm do HID. |
| `Sources/JoystickAIPoC/Controller/ControllerDiagnostics.swift` | `controller-input` | regra-alterada | LOW | Recebe `GCExtendedGamepad`; mensagem de supressão cita o Home do Ipega. |
| `Sources/JoystickAIPoC/Controller/ControllerReader.swift` | `controller-input` (RN-EC-01, RN-EC-03, 001 RN-01) | regra-alterada | HIGH | Classifica pelo modelo; recusa com `reason: unsupported_model`; `ControllerInfo` com `model` e transporte por modelo; `onActiveModelChange` na main thread após conexão do ativo, desconexão do ativo e promoção; analógicos do HID entregues só ao Ipega ativo. |
| `Sources/JoystickAIPoC/Editor/EditorViewModel.swift`, `Sources/JoystickAIPoC/App/AppDelegate.swift` | `editor`, `app-shell` | regra-nova | LOW | `activeModel` publicado e ligado ao leitor; a ponte da figura reenvia o estado pela assinatura existente de `objectWillChange`. |
| `Resources/ControllerFigure/index.html`, `figure.js`, `figure.css` | `editor`, página da figura | regra-alterada | MEDIUM | Grupo e balão `share`; raiz com `data-controller`; balão compacto (largura por posição); CSS oculta o Share com o DualSense e marca o touchpad como ausente com o Ipega. Posição do Share provisória (D-09 🟡, PM-1). |
| `Tests/JoystickCoreTests/ControllerModelTests.swift`, `SwitchProReportTests.swift` | testes | regra-nova | LOW | Suítes novas: 7 e 7 testes. |
| `Tests/JoystickCoreTests/ActiveControllerRegistryTests.swift` | testes | regra-alterada | LOW | Chamadas passam a `accepted:`; +3 testes (recusa, fila mista, soltura com `share`). 12 testes. |
| `Tests/JoystickCoreTests/ShortcutDefaultsTests.swift` | testes | regra-nova | LOW | +2 (`padraoSemShare`, `ordemDosBotoesAnterioresPreservada`). 4 testes. |
| `Tests/JoystickCoreTests/ShortcutConfigValidationTests.swift`, `ActionSummaryTests.swift` | testes | regra-nova | LOW | +1 cada (`shareComoGatilhoEModificador`, `share`). 22 e 8 testes. |
| `Tests/JoystickCoreTests/FigureStateTests.swift` | testes | regra-alterada | LOW | 19 itens, chave `controller`, rótulo "Share" (teste renomeado para `rotulosDos19Botoes`), +1 (`controleAtivo`). |
| `Tests/JoystickCoreTests/LogEventCatalogTests.swift`, `LogAnalysisTests.swift`, `FigureAssetsTests.swift` | testes | regra-alterada | LOW | `model` e `unsupported_model` em `sampleEvents` (+1); cobertura por modelo (+2); 19 grupos e balões (+1). |
| `~/.config/joystick-ai/config.json` (formato) | `config` (`architecture.md` §5) | delta-de-dados | LOW | Chave `share` aceita em camadas e em `modifiers`; `version` segue 1. Versões anteriores recusariam o arquivo com `share`. |
| `~/Library/Logs/joystick-ai/poc-*.jsonl` (formato) | `diagnostics-log` | delta-de-dados | LOW | Campo `model` em `controller.connected`; `reason: unsupported_model` em `controller.ignored`; `button: share` em `input.button`. |
| Integrações I-01 (`GameController`) e I-02 (IOKit HID) | integrações externas (`architecture.md` §4) | delta-de-contrato-externo | MEDIUM | I-01 aceita `GCExtendedGamepad` da categoria Switch Pro; I-02 casa e lê o Ipega. Contrato em `interfaces/controle-ipega.md`. Sem permissão nova. |

## Diff conceitual por componente

**`controller-input`.** Antes, "aceito" e "DualSense" eram sinônimos: o perfil `GCDualSenseGamepad` decidia a entrada, a tabela de botões e o touchpad. Agora a decisão passa por `ControllerModel.classify`, e o modelo acompanha o controle em `ControllerInfo`. A fila, a promoção, a deduplicação e a soltura sintética não mudam; só perdem a premissa de modelo único. O leitor HID, que antes guardava um único estado do PS para todos os DualSense, passa a guardar um estado por dispositivo e a informar o modelo do emissor; o PS ou o Home de um controle de outro modelo que o ativo deixa de ser entregue. Com dois controles do mesmo modelo, vale a exceção aceita de RN-EC-17.

**Núcleo.** `ButtonID` cresce no fim, o que preserva a ordem de camadas, solturas e tabelas. `share` não entra em `pointerButtons`, e por isso a validação, o rascunho do editor e o painel de ação o tratam como botão livre sem código novo. `ShortcutDefaults` o exclui da camada Options para o documento padrão continuar byte a byte igual.

**`editor`.** A figura deixa de ser só do DualSense no contrato: o estado leva o controle ativo, e a página decide visibilidade e marcação por `data-controller`. A figura desenhada continua a do DualSense (resposta 3a do esclarecimento). O 19º balão não coube em faixa livre; ficou compacto, no vão inferior entre L3 e PS, com a linha-guia cruzando as de L3 e →. Ajuste pendente no PM-1.

**`diagnostics-log` e `poc-tools`.** O log ganha um campo aditivo e troca um valor de motivo sem consumidor interno; `logSchema` segue 1. A conferência de botões passa a ser por modelo, e logs antigos continuam legíveis como DualSense.

## Preservadas

Regras 🟢 do `_reversa_sdd/domain.md` e das specs por unidade que seguem intactas no comportamento com o DualSense:

- 001 RN-02, RN-03, RN-05, RN-06, RN-08, RN-09, RN-10, RN-11, RN-12: zona morta, limiar dos gatilhos, touchpad relativo e soma com o analógico, precisão com L1, duplo clique, cursor na união das telas, mapeamento fixo do ponteiro, sem rede.
- 001 RN-04: nenhuma desconexão deixa entrada presa (a soltura sintética passa a poder incluir `share`, pela mesma regra).
- 002 RN-01 a RN-07 e E001: paleta.
- 003 RN-01 a RN-16: atalhos, configuração e editor. RN-11 (padrão reproduz o protótipo) segue válida: o documento padrão não muda.
- RI-01 a RI-07, RI-09 a RI-29.
- RN-EC-02, RN-EC-04 a RN-EC-11, RN-EC-13, RN-EC-15 (`entrada-do-controle/requirements.md`).
- RN-AT-19 (`atalhos/requirements.md`).

## Modificadas

| Regra (origem) | Antes | Depois | Tipo |
|----------------|-------|--------|------|
| 001 RN-01 (`domain.md` §3.1); RN-EC-01 | Um ativo, o primeiro DualSense; outros modelos ignorados | Um ativo, o primeiro controle aceito (DualSense ou Ipega); fila mista | regra-alterada |
| RN-EC-03 | Não `GCDualSenseGamepad` é ignorado com `reason: not_dualsense` | Sem modelo reconhecido por `ControllerModel.classify` é ignorado com `reason: unsupported_model` | regra-alterada |
| RN-EC-12; RI-08 | PS lido do relatório HID do DualSense | Também o Home do Ipega, pelo relatório `0x30` (byte 4, bit `0x10`); estado por dispositivo | regra-alterada |
| RN-EC-14 | Transporte pela exclusão entre os DualSense do IORegistry | Pela exclusão entre os dispositivos do modelo do controle | regra-alterada |
| RN-EC-08, RN-EC-10 | Analógicos pela interface de controles | No DualSense, igual; no Ipega, pelo relatório HID `0x30`, com a mesma zona morta e deduplicação | regra-alterada |
| RN-EC-16; RF-EC-05 | 18 botões do DualSense com `touchpadButton` → `touchpadClick` | Tabela por modelo; no Ipega, `GCInputButtonShare` → `share` no lugar do touchpad | regra-alterada |
| RN-EC-17 | PS pelo HID ao ativo, venha de qual DualSense vier | PS ou Home ao ativo só se o emissor for do mesmo modelo; entre dois do mesmo modelo, como antes | regra-alterada |
| RN-ED-14 (`editor/requirements.md`) | A figura mostra os 18 botões | 19 itens no estado; o Share aparece só com o Ipega ativo, e o touchpad fica marcado como ausente | regra-alterada |
| Glossário "Controle ativo" e "Controle em fila" (`domain.md` §2) | "O único DualSense…" | "O único controle aceito…" | regra-alterada |
