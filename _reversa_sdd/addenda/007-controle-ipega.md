# Adendo: Controle Ipega ao lado do DualSense

> Identificador: `007-controle-ipega`
> Data: 2026-09-19
> Cenário: legado

## Vigência

Vigente desde 2026-09-19.

## Resumo da entrega

A feature permite usar o controle Ipega, no modo Switch, do mesmo modo que o DualSense: mover o ponteiro, clicar, rolar e disparar atalhos e a paleta. O app deixa de aceitar só o `GCDualSenseGamepad` e passa a conhecer um modelo de controle, `ControllerModel` (`dualSense`, `ipega`). O Ipega é reconhecido pela categoria "Switch Pro Controller" com o par 0x057E/0x2009 no IORegistry. Os botões correspondem aos do DualSense pela posição física. O Share do Ipega ganha o identificador `share`, no fim de `ButtonID`, e é livre para ação e para papel de modificador. O Home e os dois analógicos do Ipega vêm do relatório HID `0x30`: o sistema não entrega o Home à interface de controles, e o driver zera os eixos desse clone, o que foi constatado no PM-1 e levou à revisão da decisão D-03. A configuração é única para os dois controles, e o documento padrão não muda. A figura do editor mostra o Share e marca o touchpad como ausente quando o Ipega é o ativo.

Sincronização parcial: 32 de 33 ações de `actions.md` estão fechadas, e a T033 aguarda o portão manual PM-1. A revisão de D-03 veio depois, como correção registrada no `progress.jsonl`. `swift build -c release` e `./scripts/test.sh` passam, com 306 testes em 33 suítes (280 antes da feature). O PM-1 já confirmou: reconhecimento do Ipega por USB, fila mista com promoção, soltura sintética na desconexão, botões, R2 como clique direito, modificadores L1 e Options, cursor e rolagem pelos analógicos, e L1 desacelerando o cursor. Pendentes: o restante do roteiro, o sentido do eixo Y, P-01 (Home sem gesto do sistema), P-02 (sem fio) e a posição do balão do Share. Uma nova execução do `/reversa-sync` depois do PM-1 complementa este adendo.

## Impacto por artefato da extração

| Artefato | Seção | Tipo de impacto | Delta |
|----------|-------|-----------------|-------|
| `_reversa_sdd/architecture.md` | `#3. Camadas e dependências` | componente-novo | O `JoystickCore` ganha `ControllerModel` (classificação, pares HID, 18 botões por modelo) e `SwitchProReport` (Home e analógicos do relatório `0x30`); continua importando só `Foundation`. |
| `_reversa_sdd/architecture.md` | `#3. Camadas e dependências` | regra-alterada | O componente `controller-input` do app lê por modelo: tabela de botões com `share` no lugar de `touchpadClick` no Ipega, touchpad e analógicos pela interface de controles só no DualSense, e o leitor HID com estado por dispositivo emissor, entregando PS, Home e analógicos do Ipega ao ativo do mesmo modelo. |
| `_reversa_sdd/architecture.md` | `#4. Integrações externas` | delta-de-contrato-externo | I-01 (`GameController`) passa a aceitar o `GCExtendedGamepad` da categoria Switch Pro; I-02 (IOKit HID) casa também 0x057E/0x2009 e lê o Home e os analógicos. Não há permissão nova. Contrato em `_reversa_forward/007-controle-ipega/interfaces/controle-ipega.md`. |
| `_reversa_sdd/architecture.md` | `#5. Modelo de dados em arquivo` | delta-de-dados | A configuração aceita a chave `share` em camadas e em `modifiers` (`version` segue 1). O log ganha `model` em `controller.connected`, `reason: unsupported_model` em `controller.ignored` e `button: share` em `input.button`; `logSchema` segue 1. |
| `_reversa_sdd/architecture.md` | `#5. Modelo de dados em arquivo` | delta-de-contrato-externo | A ponte da figura envia `controller` e 19 itens; a página aplica `data-controller` à raiz. Emenda em `_reversa_forward/007-controle-ipega/interfaces/figure-bridge.md`. |
| `_reversa_sdd/domain.md` | `#2. Glossário` | regra-alterada | "Controle ativo" e "Controle em fila" passam a designar qualquer controle aceito (DualSense ou Ipega), e não só o DualSense. |
| `_reversa_sdd/domain.md` | `#3.1 Controle e entrada (001)` | regra-alterada | 001 RN-01 deve ser lida como "um ativo, o primeiro controle aceito"; outros modelos continuam ignorados. 001 RN-04 vale também para `share`. As demais RN de 001 seguem intactas. |
| `_reversa_sdd/domain.md` | `#4. Regras implícitas (só no código)` | regra-alterada | RI-08 se estende: o Home do Ipega e os analógicos dele também são lidos do relatório HID bruto, e o sistema zera os eixos desse clone. |
| `_reversa_sdd/entrada-do-controle/requirements.md` | `#Regras de Negócio` (RN-EC-01, RN-EC-03, RN-EC-08, RN-EC-10, RN-EC-12, RN-EC-14, RN-EC-16, RN-EC-17) | regra-alterada | Aceitação por `ControllerModel.classify` com `unsupported_model`; transporte e tabela de botões por modelo; analógicos do Ipega pelo HID, com a mesma zona morta e deduplicação; Home do Ipega pelo HID; PS e Home entregues ao ativo só quando o emissor é do mesmo modelo. |
| `_reversa_sdd/editor/requirements.md` | `#Interface` (RN-ED-14) | regra-alterada | O estado da figura tem 19 itens e o controle ativo. Com o Ipega, o Share aparece e o touchpad fica marcado como "ausente neste controle"; com o DualSense ou sem controle, a figura é a de antes. A posição do Share é provisória até o PM-1. |
| `_reversa_sdd/atalhos/requirements.md` | `#Regras de Negócio` (RN-AT-19) | regra-alterada | O mapeamento padrão é idêntico ao anterior e não tem `share`. Em Options, o Share herda "nenhuma" da base, em vez de tê-lo explícito como os demais botões livres. |
| `_reversa_sdd/data-dictionary.md` | `#1.1 ButtonID`; `#1.3 ControllerInfo`; `#1.5 ActiveControllerRegistry<Key>` | regra-alterada | `ButtonID` tem 19 casos, com `share` por último e rótulo "Share"; `ControllerInfo` ganha `model` (padrão `.dualSense`); `connect(key:info:isDualSense:)` passa a ser `connect(key:info:accepted:)`. |
| `_reversa_sdd/code-analysis.md` | `#2. controller-input` | regra-alterada | `ControllerReader.connect` classifica pelo modelo, registra `unsupported_model` e publica `onActiveModelChange` para o editor. `TransportResolver.resolve(for:)` e `presentDevices()` substituem as constantes Sony. |
| `_reversa_sdd/traceability/code-spec-matrix.md` | `#Testes` | regra-alterada | Suítes novas `ControllerModelTests` (7) e `SwitchProReportTests` (7). `ActiveControllerRegistryTests` passa a 12, `ShortcutDefaultsTests` a 4, `ShortcutConfigValidationTests` a 22 e `ActionSummaryTests` a 8. O total do projeto passa a 306 testes em 33 suítes. |

## Regras sob vigilância

W001 a W013 no watch principal e O001 a O007 em "Observações", em [`_reversa_forward/007-controle-ipega/regression-watch.md`](../../_reversa_forward/007-controle-ipega/regression-watch.md). A O007 registra a rolagem com L1 travada no iTerm, defeito anterior à feature, a tratar à parte.

## Fontes

- `_reversa_forward/007-controle-ipega/legacy-impact.md`
- `_reversa_forward/007-controle-ipega/regression-watch.md`
- `_reversa_forward/007-controle-ipega/requirements.md`
- `_reversa_forward/007-controle-ipega/progress.jsonl`
- `_reversa_forward/007-controle-ipega/actions.md` (notas de execução e revisão de D-03 no PM-1)
- `_reversa_forward/007-controle-ipega/data-delta.md`
- `_reversa_forward/007-controle-ipega/interfaces/controle-ipega.md`
- `_reversa_forward/007-controle-ipega/interfaces/figure-bridge.md`
- `_reversa_forward/007-controle-ipega/interfaces/diagnostic-log.md`
