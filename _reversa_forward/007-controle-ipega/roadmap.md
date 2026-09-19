# Roadmap: Controle Ipega ao lado do DualSense

> Identificador: `007-controle-ipega`
> Data: `2026-09-19`
> Requirements: `_reversa_forward/007-controle-ipega/requirements.md`
> Confidência: 🟢 CONFIRMADO, 🟡 INFERIDO, 🔴 LACUNA

> **Nota de confidência:** recebem 🟢 as decisões apoiadas no código inspecionado em 2026-09-19 (`ControllerReader.swift`, `ButtonReader.swift`, `AxisTouchReader.swift`, `ControllerDiagnostics.swift`, `TransportResolver.swift`, `ExtendedReportActivator.swift`, `ActiveControllerRegistry.swift`, `InputEvent.swift`, `ButtonLabels.swift`, `ShortcutConfig.swift`, `ShortcutDefaults.swift`, `ActionSummary.swift`, `FigureState.swift`, `LogAnalysis.swift`, `ButtonsCommand.swift`, `InputRouter.swift`, `figure.js`, `index.html`), nas duas sondas no hardware desta data ou na extração em `_reversa_sdd/`. Recebem 🟡 as que dependem de comportamento do sistema ainda não observado (gesto do Home, conexão sem fio) ou de ajuste visual na figura. Não há 🔴: o `requirements.md` não tem `[DÚVIDA]` pendente.

## 1. Resumo da abordagem

O app deixa de aceitar só o `GCDualSenseGamepad` e passa a conhecer um **modelo de controle** (`ControllerModel`, no núcleo), com dois valores: `dualSense` e `ipega`. O Ipega é reconhecido pela categoria "Switch Pro Controller" que o sistema lhe atribui, somada à presença no IORegistry de um dispositivo com o fabricante 0x057E e o produto 0x2009. A leitura do controle passa a escolher a tabela de botões pelo modelo: a do Ipega reproduz a do DualSense por posição, troca o clique do touchpad pelo Share e não liga touchpad. O Home do Ipega, que o sistema não entrega à interface de controles, é lido do relatório bruto (0x30, byte 4, bit 0x10) pelo mesmo leitor HID que já lê o PS.

O Share ganha um identificador próprio, `share`, acrescentado no fim de `ButtonID`. Como não está entre os botões de apontamento, ele herda de graça tudo o que os botões livres têm: ação em qualquer camada, papel de modificador, validação, gravação e identificação no editor. A configuração continua única para os dois controles. A figura do editor recebe o modelo ativo: com o Ipega, mostra o Share e marca o touchpad como ausente; com o DualSense ou sem controle, fica como antes. O mapeamento padrão, o documento padrão gravado por "Restaurar padrão" e o comportamento do DualSense não mudam.

## 2. Princípios aplicados

Não existe `.reversa/principles.md`, então não há princípio a respeitar nem conflito a registrar. As restrições equivalentes vêm da extração e das features anteriores:

| Restrição | Como a feature se relaciona | Status |
|-----------|------------------------------|--------|
| Núcleo funcional com casca imperativa; `JoystickCore` só importa `Foundation` (`architecture.md` §2 e §3) | `ControllerModel`, a classificação, a leitura do bit do Home, o `share` e a figura por modelo ficam no núcleo, testados; o app só consulta o sistema e aplica (D-01, D-04, D-08) | respeita |
| Um controle ativo por vez, com fila e soltura sintética (001 RN-01, RN-04; RN-EC-01, RN-EC-07) | `ActiveControllerRegistry` fica igual na lógica; só perde a premissa de que todo aceito é DualSense (D-05) | respeita |
| Sem permissão nova, sem rede (`permissions.md` §2) | O leitor HID já abre dispositivos para o PS; passa a abrir também o Ipega, sob a mesma permissão de Input Monitoring (D-04) | respeita |
| Valores de eixo e textos fora do log (001 RN-12; 003 RN-14) | Só o modelo e o motivo de recusa entram no log (D-07) | respeita |
| Configurações existentes válidas sem migração (003) | `share` é chave nova e opcional; o documento padrão não muda (D-02) | respeita |
| Regra de escrita do Reversa (`CLAUDE.md`) | `.reversa/reversa-config.json` está com `allowLegacyEdits: true` e `allowedPaths` vazio, liberação irrestrita. O `/reversa-coding` deve avisar uma vez por sessão | observação |

## 3. Decisões técnicas

| ID | Decisão | Justificativa | Alternativas descartadas | Confidência |
|----|---------|----------------|--------------------------|-------------|
| D-01 | Novo `enum ControllerModel: String { case dualSense, ipega }` em `Sources/JoystickCore/Input/ControllerModel.swift`, com a função pura `classify(productCategory:isDualSenseProfile:hidDevices:) -> ControllerModel?`. `ipega` quando a categoria é `"Switch Pro Controller"` e `hidDevices` (pares fabricante/produto lidos do IORegistry) contém (0x057E, 0x2009); `dualSense` quando o perfil é `GCDualSenseGamepad`; `nil` nos demais casos. O modelo guarda seus pares (fabricante, produtos) para o `TransportResolver` e o leitor HID. | RN-01 com a resposta 1a do esclarecimento. A interface de controles do sistema não expõe fabricante nem produto; a correlação pelo IORegistry é a mesma técnica de `TransportResolver` e dispensa permissão. A sonda confirmou categoria e identificação. | Aceitar qualquer `extendedGamepad` (resposta 1c, descartada); aceitar pela categoria sem IORegistry (resposta 1b, descartada); filtrar pelo número de série `Shanwan…` (não documentado, pode variar por lote e firmware) | 🟢 |
| D-02 | `ButtonID` ganha `case share` **no fim** da enumeração, depois de `dpadRight`, com `displayName` `"Share"`. `ShortcutConfig.pointerButtons` não muda. `ShortcutDefaults.optionsLayer` exclui `share` do laço que grava `"nenhuma"`, para que o documento padrão fique idêntico ao anterior. | RN-05, RN-08, RN-13. No fim, a ordem de `ButtonID` (camadas do editor, soltura sintética, tabela de `ShortcutDefaultsTests`) não muda para os 18 existentes. Fora dos botões de apontamento, o Share recebe ação, vira modificador e é validado sem código novo em `ShortcutConfigValidation`, `EditorDraft` e `ActionPanel`, que já usam `ButtonID(rawValue:)`. | Reaproveitar `touchpadClick` para o Share (tornaria o Share clique fixo, contra RN-05); identificador `capture` (o nome no editor é "Share", RN-13); inserir `share` ao lado de `touchpadClick` (reordena camadas e solturas) | 🟢 |
| D-03 | A leitura passa a ser por modelo. `ControllerReader.connect` classifica (D-01); aceito, entrega a `ButtonReader`, `AxisTouchReader` e `ControllerDiagnostics` o `GCExtendedGamepad` e o modelo. `ButtonReader.digitalButtons` ganha a tabela do Ipega: `buttonA`→`cross`, `buttonB`→`circle`, `buttonX`→`square`, `buttonY`→`triangle`, ombros e gatilhos como no DualSense, `buttonMenu`→`options`, `buttonOptions`→`create`, `buttonHome`→`ps`, `physicalInputProfile.buttons[GCInputButtonShare]`→`share`, direcional igual. `AxisTouchReader` liga os analógicos em qualquer modelo e o touchpad só no DualSense. `ControllerDiagnostics` pede a supressão de gestos no `buttonHome` dos dois. | RN-03 e RN-06. A segunda sonda mostrou que baixo, direita, esquerda e cima chegam como A, B, X e Y, mesma tabela do DualSense (RN-EC-16); Select e Start chegam como `buttonOptions` e `buttonMenu`. ZL e ZR digitais passam por `TriggerTracker` (limiar 0,5) sem mudança. | Classe de leitor separada para o Ipega (duplicaria a entrega, a deduplicação e o log); inverter A/B como na convenção Nintendo (a sonda mostrou que não há inversão) | 🟢 |
| D-04 | O Home do Ipega é lido do relatório bruto. Novo `SwitchProReport.homeButton(reportID:bytes:) -> Bool?` no núcleo: relatório `0x30` com pelo menos 13 bytes, bit `0x10` do byte 4 (com o identificador no byte 0); outros relatórios, `nil`. `ExtendedReportActivator` passa a casar também (0x057E, 0x2009), escolhe o intérprete pelo fabricante do dispositivo que enviou o relatório e mantém o estado do Home por dispositivo; o pedido do relatório de recurso `0x05` continua só para o DualSense sem fio. A entrega segue por `onHomeButton` ao controle ativo, como o PS. | RN-04; RN-EC-12 e RN-EC-17 valem igual. A sonda mostrou o bit do Home no relatório 0x30 e nenhum evento do Home pela interface de controles. O registro já deduplica o botão se as duas vias o entregarem (RN-EC-06). | Leitor HID próprio para o Ipega (segundo `IOHIDManager` sem ganho); ler todos os botões do Ipega pelo HID (a interface de controles já entrega 17 de 18, com normalização pronta) | 🟢 |
| D-05 | `ControllerInfo` ganha `model: ControllerModel`. `ActiveControllerRegistry.connect(key:info:isDualSense:)` passa a `connect(key:info:accepted:)`, e o caso `.ignored` passa a significar "modelo não aceito". A fila, a promoção e as solturas sintéticas não mudam. | RN-02 e RN-09: a regra do ativo vale para qualquer modelo aceito; a soltura sintética já percorre o conjunto de pressionados, que passa a poder conter `share`. | Uma fila por modelo (contra RN-02); prioridade fixa do DualSense sobre o Ipega (fora do pedido) | 🟢 |
| D-06 | `TransportResolver.resolve(for: ControllerModel)` procura no IORegistry os pares do modelo em vez da constante Sony; o DualSense segue com 0x054C e os produtos 0x0CE6 e 0x0DF2. | RN-11: tipo de conexão também para o Ipega; a regra de exclusão (candidatos de transportes diferentes resultam em `unknown`) continua. | Tipo `unknown` fixo para o Ipega (o log perderia o cabo/sem fio sem motivo) | 🟢 |
| D-07 | Log: `controller.connected` ganha o campo `model` (`"dualSense"` ou `"ipega"`); `controller.ignored` passa a usar `reason: "unsupported_model"` no lugar de `"not_dualsense"`. `logSchema` segue 1: o campo é aditivo e nenhum consumidor interno lê o motivo. | RN-11 e RF-12. `LogAnalysis` lê só `controller.connected` e `controller.disconnected`, sem o motivo. | Evento novo por modelo (duplica o de conexão); manter `not_dualsense` (o nome ficaria falso) | 🟢 |
| D-08 | O editor conhece o modelo ativo. `ControllerReader` publica, na main thread, o modelo do ativo a cada conexão, desconexão e promoção (`onActiveModelChange`); `AppDelegate` o liga a `EditorViewModel.activeModel`. `FigureState` ganha `controller: String` (`"dualSense"` ou `"ipega"`, e `"dualSense"` sem controle) e passa a ter 19 itens, com `share`. Com o Ipega, o resumo do `touchpadClick` passa a `"ausente neste controle"`. A página aplica `data-controller` à raiz: com `dualSense`, o grupo e o balão do Share ficam ocultos; com `ipega`, o touchpad recebe a classe visual de ausente e o Share aparece. | RN-12, RN-13, RF-10, RF-11. A decisão fica no núcleo e testável; a página só aplica o que recebe, como em `004-figura-controle-web` D-07. A ação do Share continua gravada com o DualSense ativo, porque a configuração é única (RN-07). | Figura própria do Ipega (resposta 3b, descartada); decidir a visibilidade na página a partir do nome do controle (lógica fora do núcleo) | 🟢 |
| D-09 | Posição do Share na figura: desenho sobre a silhueta, à esquerda da área do touchpad e abaixo de Create; balão na faixa livre mais próxima, escolhida no ajuste visual do portão manual, sem cruzar linhas-guia de outros botões. | A figura tem 18 balões numa área de 830 × 620 px; o encaixe do 19º só se valida vendo-a. | Mover balões existentes (mexe no leiaute aprovado na 004) | 🟡 (PM-1) |
| D-10 | `LogAnalysis.buttonCoverage` e `poc-tools buttons` passam a esperar o conjunto do modelo do último `controller.connected` do log: o DualSense sem `share`, o Ipega sem `touchpadClick`, e o DualSense quando o campo `model` falta (logs anteriores). O total continua "de 18". | RF-02: a conferência de 18 de 18 também para o Ipega; logs antigos continuam legíveis. | Conferir os 19 identificadores (nenhum controle tem os 19) | 🟢 |
| D-11 | Testes em `Tests/JoystickCoreTests/`: novo `ControllerModelTests` (classificação, pares, `nil` para outro Switch Pro); novo `SwitchProReportTests` (bit do Home, relatório curto, outro identificador); `ActiveControllerRegistryTests` com fila mista e soltura sintética de `share`; `ShortcutDefaultsTests` confirma o documento padrão idêntico e `share` sem ação; `ShortcutConfigValidationTests` aceita `share` como gatilho e como modificador; `FigureStateTests` com 19 itens, `controller` e o resumo do touchpad ausente; `FigureStateTests` e `ButtonLabels` com o rótulo "Share"; `ActionSummaryTests` para o Share; `LogEventCatalogTests` com `model` e `unsupported_model`; `LogAnalysisTests` com a cobertura por modelo. | Cobre RF-02, RF-04, RF-06 a RF-12 sem hardware. A leitura pela interface de controles e o HID ficam no portão manual (TD-01: o app não tem alvo de teste). | Testes do app (não há alvo) | 🟢 |
| D-12 | Um portão manual, **PM-1**, depois do código: os cenários do `requirements.md` §7 com o Ipega por cabo, mais as sondas P-01 (Home sem gesto do sistema), P-02 (Ipega sem fio, informativa) e o ajuste visual de D-09. Não há PM-0: as sondas de 2026-09-19 já responderam o que decidia o desenho. | O que resta observar depende do código novo. | Portão prévio sem código (as perguntas que ele responderia já têm resposta) | 🟢 |

## 4. Premissas

Nenhuma premissa vem de `[DÚVIDA]`. As abaixo vêm de inferência e são conferidas no PM-1.

| Premissa | Origem (`requirements.md` seção) | Risco se errada |
|----------|----------------------------------|-----------------|
| Um Switch Pro Controller original da Nintendo usa a mesma identificação (0x057E / 0x2009) e seria aceito como `ipega` | §4 RN-01; §9, resposta 1a | Baixo: o usuário não tem esse controle; se tiver, ele funciona pela mesma correspondência. A regra "outro Switch Pro com identificação diferente é ignorado" continua valendo |
| Pressionar o Home do Ipega não abre gesto do sistema (P-01) | §10, risco residual | O Home abriria algo além da paleta; mitigação por D-03 (supressão pedida) e registro no PM-1 |
| Sem fio, o Ipega usa o mesmo relatório 0x30 (P-02) | §6, compatibilidade | Sem fio, o Home pode não chegar; os demais 17 botões seguem pela interface de controles. Informativo: o uso relatado é por cabo |

## 5. Delta arquitetural

| Componente | Arquivo de origem no legado | Tipo de mudança | Resumo |
|------------|------------------------------|-----------------|--------|
| `controller-input` | `_reversa_sdd/code-analysis.md#2. controller-input`; `_reversa_sdd/entrada-do-controle/requirements.md#Regras de Negócio` (RN-EC-01, RN-EC-03, RN-EC-12, RN-EC-14, RN-EC-16) | regra-alterada | Aceita dois modelos (D-01, D-05); tabela do Ipega (D-03); Home pelo HID (D-04); transporte por modelo (D-06) |
| Núcleo (`ButtonID`, `ControllerInfo`, `ControllerModel`, `SwitchProReport`) | `_reversa_sdd/code-analysis.md#0.2 Pipeline de entrada` | regra-alterada, componente-novo | `share`; modelo no `ControllerInfo`; classificação e leitura do bit do Home (D-01, D-02, D-04) |
| `shortcuts` e `config` | `_reversa_sdd/atalhos/requirements.md#Regras de Negócio` (RN-AT-19) | regra-alterada | O Share é gatilho e modificador válido; o padrão não muda (D-02) |
| `editor` (figura) | `_reversa_sdd/editor/requirements.md#Regras de Negócio` (RN-ED-14); `_reversa_sdd/addenda/004-figura-controle-web.md` | contrato-alterado | `FigureState` com `controller` e 19 itens; página com o Share e o touchpad ausente (D-08, D-09) |
| `diagnostics-log` e `poc-tools` | `_reversa_sdd/architecture.md#5. Modelo de dados em arquivo` | contrato-alterado | `model` em `controller.connected`; `unsupported_model`; cobertura por modelo (D-07, D-10) |
| Integrações externas | `_reversa_sdd/architecture.md#4. Integrações externas` (I-01, I-02) | contrato-alterado | I-01 aceita o Ipega; I-02 casa também 0x057E / 0x2009; ver `interfaces/controle-ipega.md` |

`pointer`, `palette`, `injection` e `targets-analysis` não mudam de código: recebem os mesmos `ButtonID` pela correspondência.

## 6. Delta no modelo de dados

- Resumo das mudanças: o arquivo de configuração passa a aceitar a chave `share` em camadas e em `modifiers`; o documento padrão não muda. O log ganha o campo `model` em `controller.connected` e o valor `unsupported_model` em `controller.ignored`. No núcleo: `ButtonID.share`, `ControllerModel`, `ControllerInfo.model`, `FigureState.controller` e o 19º item da figura.
- Detalhe completo em: `_reversa_forward/007-controle-ipega/data-delta.md`

## 7. Delta de contratos externos

| Contrato | Tipo | Arquivo de detalhe |
|----------|------|--------------------|
| Controle Ipega (interface de controles do sistema e relatório HID) | dispositivo | `_reversa_forward/007-controle-ipega/interfaces/controle-ipega.md` |
| Ponte da figura | JSON em memória | `_reversa_forward/007-controle-ipega/interfaces/figure-bridge.md` (emenda ao contrato da 004) |
| Log de diagnóstico | arquivo | `_reversa_forward/007-controle-ipega/interfaces/diagnostic-log.md` (emenda ao contrato da 004) |
| Arquivo de configuração | arquivo | chave nova `share`; o contrato de `_reversa_forward/003-editor-atalhos/interfaces/config-file.md` segue vigente, com o acréscimo de `data-delta.md` §1 |

## 8. Plano de migração

n/a. Arquivos de configuração existentes continuam válidos e nenhum é reescrito. Um arquivo que use `share` é recusado por versões anteriores à feature (`wrongType` no caminho do botão); como a instalação é única e local, não há convivência de versões a tratar. Logs anteriores continuam legíveis por `poc-tools` (D-10).

## 9. Riscos e mitigações

| Risco | Impacto | Probabilidade | Mitigação |
|-------|---------|---------------|-----------|
| O Home do Ipega aciona um gesto do sistema além da paleta | médio | baixo | Supressão pedida em `buttonHome` (D-03); P-01 no PM-1; se persistir, registrar e decidir com o usuário |
| O usuário troca o Ipega de modo (Android ou iOS) sem querer | baixo | médio | O controle passa a ser ignorado e registrado (RN-01); o `onboarding.md` explica como voltar ao modo Switch |
| Sem fio, o relatório difere e o Home não chega | baixo | médio | P-02 informativa; os outros 17 botões seguem pela interface de controles |
| O 19º balão não cabe sem cruzar linhas-guia | baixo | médio | Ajuste visual no PM-1 (D-09) |
| `GCInputButtonShare` ausente do perfil em alguma versão do sistema | médio | baixo | Elemento ausente é registrado como `controller.error` e os demais botões seguem (comportamento atual de `ButtonReader`); conferido no PM-1 |
| Reordenação acidental de `ButtonID` muda a ordem de camadas e solturas | médio | baixo | `share` no fim (D-02) e teste que fixa a ordem dos 18 existentes |

## 10. Critério de pronto

- [ ] Todas as ações do `actions.md` marcadas `[X]`
- [ ] `cross-check.md` (se executado) sem CRITICAL nem HIGH
- [ ] `regression-watch.md` gerado
- [ ] `swift build -c release` e `./scripts/test.sh` verdes, com os testes de D-11 (280 antes da feature, conferir na primeira rodada)
- [ ] PM-1 aprovado: cenários do §7 com o Ipega por cabo, P-01 registrada, P-02 registrada ou dispensada, figura ajustada
- [ ] DualSense conferido no PM-1 sem regressão (atalhos, paleta, touchpad, figura)
- [ ] Re-extração reversa executada e sem regressão vermelha (recomendado, não obrigatório)

## 11. Histórico de alterações

| Data | Alteração | Autor |
|------|-----------|-------|
| 2026-09-19 | Versão inicial gerada por `/reversa-plan` | reversa |
