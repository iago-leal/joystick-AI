# Regression watch: Controle Ipega ao lado do DualSense

> Identificador: `007-controle-ipega`
> Âncora: legado (`_reversa_sdd/architecture.md`, `_reversa_sdd/domain.md`, extração de 2026-09-15). Os itens do watch principal nascem da seção "Modificadas" do `legacy-impact.md`; só regras originalmente 🟢 entram nele. Os requisitos 🟡 do `requirements.md` e as decisões 🟡 do roadmap, que dependem do PM-1, ficam em "Observações", sem peso de regressão.

## Watch principal

| ID | Origem (arquivo, seção) | Regra esperada após mudança | Tipo de verificação | Sinal de violação |
|----|--------------------------|------------------------------|---------------------|-------------------|
| W001 | `_reversa_sdd/domain.md` §3.1, 001 RN-01; `entrada-do-controle/requirements.md`, RN-EC-01; `domain.md` §2, "Controle ativo" e "Controle em fila" | Há no máximo um controle ativo, o primeiro controle aceito (DualSense ou Ipega); os demais aceitos formam uma fila mista, com promoção na desconexão do ativo. | redação | Re-extração descrevendo o ativo como "o primeiro DualSense", ou `ActiveControllerRegistryTests.filaMistaComPromocao` ausente ou vermelho. |
| W002 | `entrada-do-controle/requirements.md`, RN-EC-03 | Controle sem modelo reconhecido por `ControllerModel.classify` (perfil DualSense, ou categoria "Switch Pro Controller" com o par 0x057E/0x2009 no IORegistry) é ignorado uma vez com `reason: unsupported_model`. | redação | Motivo `not_dualsense` de volta no código ou na spec; Switch Pro sem o par aceito (`ControllerModelTests.switchProSemOParEhRecusado` vermelho). |
| W003 | `entrada-do-controle/requirements.md`, RN-EC-03 | O motivo antigo `not_dualsense` não existe mais no código de produção. | ausência | `grep -r not_dualsense Sources/` com resultado. |
| W004 | `entrada-do-controle/requirements.md`, RN-EC-12; `domain.md` §4, RI-08 | O Home do Ipega é lido do relatório HID `0x30` com ≥ 13 bytes, bit `0x10` do byte 4, com estado por dispositivo emissor; o PS do DualSense segue as três formas anteriores. | presença | `SwitchProReport` ausente, `SwitchProReportTests` vermelho, ou `ExtendedReportActivator` sem casamento de (0x057E, 0x2009). |
| W005 | `entrada-do-controle/requirements.md`, RN-EC-14 | O tipo de conexão é resolvido pela exclusão entre os dispositivos do IORegistry do modelo do controle (`TransportResolver.resolve(for:)`). | redação | Constantes Sony fixas de volta em `TransportResolver`, ou o Ipega registrado sempre como `unknown` por cabo. |
| W006 | `entrada-do-controle/requirements.md`, RN-EC-16 e RF-EC-05 | A tabela de botões é por modelo: comum às duas, exceto o 14º item, `touchpadButton` → `touchpadClick` no DualSense e `GCInputButtonShare` → `share` no Ipega. Cada modelo tem 18 botões. | redação | Re-extração com uma tabela única, `ControllerModel.buttons` com contagem diferente de 18, ou `poc-tools buttons` sem o modelo no cabeçalho. |
| W007 | `entrada-do-controle/requirements.md`, RN-EC-17 | O PS ou o Home lido pelo HID só é entregue ao ativo quando o emissor é do mesmo modelo; entre dois controles do mesmo modelo, vale a exceção aceita anterior. | presença | `ControllerReader` entregando o Home sem comparar `active?.model`, ou o Home do Ipega em fila abrindo a paleta com o DualSense ativo. |
| W008 | `_reversa_sdd/data-dictionary.md`, `ButtonID`; `code-analysis.md` §0.2 | `ButtonID` tem 19 casos; os 18 primeiros na ordem anterior e `share` por último. | redação | `ShortcutDefaultsTests.ordemDosBotoesAnterioresPreservada` vermelho, ou `share` fora da última posição. |
| W009 | `atalhos/requirements.md`, RN-AT-19; `domain.md` §3.3, 003 RN-11 | O documento padrão não contém `share` em nenhuma camada nem em `modifiers`; em Options, o Share herda "nenhuma" da base. | ausência | `ShortcutDefaultsTests.padraoSemShare` vermelho, ou `share` gravado por "Restaurar padrão". |
| W010 | `editor/requirements.md`, RN-ED-14; `addenda/004-figura-controle-web.md` | O estado da figura tem 19 itens e o campo `controller`; com `ipega`, o touchpad segue `fixed` e resume "ausente neste controle"; a página oculta o Share com `dualSense`. | redação | `FigureStateTests.controleAtivo` ou `FigureAssetsTests.dezenoveBotoesEControleAtivo` vermelhos, ou figura com o Share visível com o DualSense ativo. |
| W011 | `_reversa_sdd/architecture.md` §5, log de diagnóstico | `controller.connected` traz `model`; `logSchema` segue 1; `LogAnalysis.buttonCoverage` usa o modelo do último `controller.connected`, DualSense sem o campo. | presença | `LogEventCatalogTests.modeloNaConexaoEMotivoDeRecusa` ou `LogAnalysisTests.logSemModeloEsperaODualSense` vermelhos. |
| W012 | `_reversa_sdd/traceability/code-spec-matrix.md` | Contagens: `ControllerModelTests` 7, `SwitchProReportTests` 7, `ActiveControllerRegistryTests` 12, `ShortcutDefaultsTests` 4, `ShortcutConfigValidationTests` 22, `ActionSummaryTests` 8; total de 306 testes em 33 suítes. | redação | Matriz com as contagens anteriores sem feature que as reduza, ou algum dos testes nomeados no `legacy-impact.md` removido. |
| W013 | `entrada-do-controle/requirements.md`, RN-EC-08 e RN-EC-10; revisão de D-03 no PM-1 | Os analógicos do Ipega vêm do relatório HID `0x30` (bytes 6 a 11), com a mesma zona morta e deduplicação do DualSense; a interface de controles não é ligada para eles. | presença | Cursor e rolagem parados com o Ipega ativo, ou `SwitchProReportTests.analogicosNosExtremos` vermelho. |

## Observações

Requisitos 🟡 do `requirements.md` e decisões 🟡 do `roadmap.md`, conferidos no PM-1; sem peso de regressão até uma re-extração os confirmar como 🟢.

| ID | Origem (arquivo, seção) | Regra esperada | Tipo de verificação | Sinal de violação |
|----|--------------------------|----------------|---------------------|-------------------|
| O001 | `requirements.md` RF-10, RN-12 | No modo de identificação, cada um dos 18 botões do Ipega seleciona na figura o botão correspondente, inclusive o Share. | presença | Botão do Ipega sem seleção, ou selecionando outro. |
| O002 | `requirements.md` RF-11, RN-12, RN-13; `roadmap.md` D-08 | Com o Ipega ativo, a figura mostra o Share selecionável e o touchpad marcado como ausente; com o DualSense, fica como antes. | presença | Figura sem trocar ao alternar os controles. |
| O003 | `roadmap.md` D-09 | O balão do Share encaixa na figura sem cruzar linhas-guia de outros botões. | presença | Posição provisória atual (balão compacto em 208, 552) reprovada no passo 7 do PM-1. |
| O004 | `requirements.md` RF-12, RN-11 | O log registra o modelo e o tipo de conexão do Ipega; outro modelo aparece como ignorado uma vez. | presença | `controller.connected` do Ipega sem `model: ipega` ou com `connection: unknown` por cabo. |
| O005 | `roadmap.md` §4, premissa P-01 | Pressionar o Home do Ipega não abre gesto do sistema além da paleta. | presença | Launchpad ou sobreposição de jogos ao pressionar o Home. |
| O006 | `roadmap.md` §4, premissa P-02 | Sem fio, o Ipega usa o mesmo relatório `0x30`, e o Home chega. | presença | Informativa; o uso relatado é por cabo. |
| O007 | PM-1, 2026-09-19 | Com L1, a rolagem desacelera nos navegadores; no iTerm, trava, com o DualSense e com o Ipega (passos de 1 a 5 px descartados pelo terminal). Anterior à feature; defeito a registrar à parte. | presença | — |

## Histórico de re-extrações

## Arquivadas
