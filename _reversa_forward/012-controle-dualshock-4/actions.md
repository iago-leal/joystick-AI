# Actions: Controle DualShock 4 ao lado do DualSense e do Ipega

> Identificador: `012-controle-dualshock-4`
> Data: `2026-09-22`
> Roadmap: `_reversa_forward/012-controle-dualshock-4/roadmap.md`

## Resumo

| Métrica | Valor |
|---------|-------|
| Total de ações | 26 |
| Paralelizáveis (`[//]`) | 20 |
| Maior cadeia de dependência | 7 (T003 → T004 → T012 → T016 → T021 → T022 → T023), precedida do PM-0 e atravessada pelo PM-1 |

## Convenções desta decomposição

### Portões manuais

Passagens que dependem de ato humano não recebem ID `T`; aparecem como `PM-n` na coluna de dependências. O `/reversa-coding` deve parar ao alcançar um portão e só seguir quando o usuário confirmar o resultado.

| Portão | Ato do usuário | Requer | Referência | Libera |
|--------|----------------|--------|------------|--------|
| PM-0 | Com o app fechado e o GameSir G8+ no modo PlayStation conectado por Bluetooth, rodar `swift sondas/probe-ds4.swift` e executar as sondas P-01, P-02 e P-03 do `onboarding.md` §1, relatando os valores observados. | T002 | D-11, `onboarding.md` §1 | T003 |
| PM-1 | Com o app da feature instalado e só o GameSir G8+ conectado no início, executar o roteiro do `onboarding.md` §3 (14 passos) e relatar os resultados. | T022 | D-11, `onboarding.md` §3 | T023 e o critério de pronto |

### Duas metades, como na 011

As decisões D-02, D-04 e D-05 dependem das sondas; as demais, não. Por isso o núcleo se divide: `ControllerModel`, a classificação, a figura, o log e a ferramenta de botões (D-01, D-06 a D-08) começam logo depois da linha de base, em paralelo ao PM-0; a tabela de botões, o touchpad, o intérprete do PS e a ativação por Bluetooth (D-02 a D-05) esperam a T004. O `/reversa-coding` executa pela coluna de dependências, e não pela ordem das tabelas.

### Fidelidade ao rito

Nenhuma ação de código do leitor HID ou da tabela de botões é iniciada antes de a T004 confirmar ou revisar as decisões. Se a T004 mandar parar (PS ausente nas duas vias), o `/reversa-coding` devolve a decisão ao usuário e não segue.

### Correspondência com o roadmap

| Decisões do roadmap | Ações |
|---------------------|-------|
| D-01 (`dualShock4`, `SystemProfile`, classificação) | T005, T011, T013 |
| D-02 (tabela de botões) | T004, T014 |
| D-03 (analógicos e touchpad por modelo Sony) | T015 |
| D-04 (`DualShock4Report`) | T004, T006, T012, T016 |
| D-05 (recurso `0x05` também para o DualShock 4) | T004, T016 |
| D-06 (registro, transporte, nome padrão) | T007, T013 |
| D-07 (log e ferramenta de botões) | T008, T009, T020 |
| D-08 (figura) | T010, T017, T018, T019 |
| D-09 (carga sem código novo) | T007, T008 |
| D-10 (testes) | T005 a T010, T019, T021 |
| D-11 (portões) | T002, T003, PM-0, T022, PM-1, T023 |

## Fase 1, Preparação

<!-- As sondas de D-11 abrem a feature e travam só a metade que depende delas; a outra metade corre em paralelo. -->

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T001 | Registrar nas notas de execução o número de testes verdes antes de qualquer mudança (esperado 449 em 45 suítes, conforme a 011, com o `SDKROOT` do SDK 26.5 e o `-plugin-path` descritos na T001 da 011) e o estado de `.reversa/reversa-config.json` lido na ativação do `/reversa-coding` | - | `[//]` | `_reversa_forward/012-controle-dualshock-4/actions.md` | 🟢 | `[X]` |
| T002 | Escrever o programa de sonda `sondas/probe-ds4.swift`, descartável e fora do app: liga `shouldMonitorBackgroundEvents`, enumera `GCController.controllers()`, imprime a classe do perfil, a categoria, os elementos e o dicionário `touchpads`, imprime o nome do elemento a cada mudança de botão e lê `battery`; abre um `IOHIDManager` casando 0x054C com 0x05C4 e 0x09CC, imprime identificador e tamanho de cada relatório de entrada e, quando um byte muda, o índice e o valor; ao receber uma tecla no terminal, lê o recurso `0x05` e imprime o resultado. Sem escrita no dispositivo além desse pedido (D-11) | - | `[//]` | `_reversa_forward/012-controle-dualshock-4/sondas/probe-ds4.swift` | 🟢 | `[X]` |
| T003 | Registrar nas notas de execução, no `onboarding.md` §1 e no `investigation.md` §3 os resultados de P-01, P-02 e P-03 apurados no PM-0: classe do perfil, elemento do Share, PS pela interface de controles ou não, dicionário `touchpads`, formato dos relatórios em repouso, índice e bit do PS em cada formato, resultado do pedido `0x05` e formato depois dele, nível e estado da bateria, transporte | PM-0 | - | `_reversa_forward/012-controle-dualshock-4/onboarding.md` | 🟡 | `[X]` |
| T004 | Confirmar ou revisar D-02 (elemento do Share), D-04 (índices do PS) e D-05 (ativação por Bluetooth) no `roadmap.md` à luz da T003, com linha no histórico §11; se a P-02 não mostrar bit do PS **e** a P-01 mostrar que o PS não chega pela interface de controles, parar e devolver ao usuário a decisão sobre o PS no clone | T003 | - | `_reversa_forward/012-controle-dualshock-4/roadmap.md` | 🟡 | `[X]` |

## Fase 2, Testes

<!-- Tudo o que o núcleo alcança nasce aqui; a leitura pela interface de controles e o HID ficam nas sondas e no PM-1 (TD-01). -->

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T005 | Em `ControllerModelTests`, adaptar os sete casos existentes a `classify(productCategory:profile:hidDevices:)` e acrescentar: perfil `dualShock` com (0x054C, 0x05C4) e com (0x054C, 0x09CC) → `dualShock4`; perfil `dualShock` sem par → `nil`; (0x054C, 0x0BA0) → `nil`; perfil `extended` com par Sony → `nil`; perfil `dualSense` continua `dualSense` sem par; `dualShock4.buttons` com 18 itens sem `share`; `rawValue` `"dualShock4"`; `matches` para os dois produtos (D-01, D-10) | T011 | `[//]` | `Tests/JoystickCoreTests/ControllerModelTests.swift` | 🟢 | `[X]` |
| T006 | Criar `DualShock4ReportTests`: `0x01` com 10 e com 64 bytes, bit do PS ligado e desligado no índice fixado pela T004 (7 esperado); `0x11` com 78 bytes no índice fixado (9 esperado); outros bits do mesmo byte não afetam; `0x11` com menos de 12 bytes, `0x01` com menos de 10 e identificador desconhecido devolvem `nil` (D-04, D-10) | T012 | `[//]` | `Tests/JoystickCoreTests/DualShock4ReportTests.swift` | 🟡 | `[X]` |
| T007 | Em `ActiveControllerRegistryTests`, cobrir a fila com três modelos (DualSense, Ipega, DualShock 4, nessa ordem) com promoção em cadeia até o DualShock 4 e `active?.model == .dualShock4`; soltura sintética de `ps` e `touchpadClick` pressionados num DualShock 4 ativo, em ordem de `ButtonID`, com o conjunto vazio para o promovido (D-06, D-09, RN-02, RN-07) | T011 | `[//]` | `Tests/JoystickCoreTests/ActiveControllerRegistryTests.swift` | 🟢 | `[X]` |
| T008 | Em `LogEventCatalogTests`, acrescentar `controllerConnected` para um `ControllerInfo` com `model: .dualShock4`, `connection: .bluetooth` e carga conhecida: `model` grava `"dualShock4"`, `charge` e `chargeState` presentes; incluir o evento em `sampleEvents` para o teste de chaves proibidas (D-07, D-09) | T011 | `[//]` | `Tests/JoystickCoreTests/LogEventCatalogTests.swift` | 🟢 | `[X]` |
| T009 | Em `LogAnalysisTests`, cobrir `buttonCoverage` com o último `controller.connected` em `model: "dualShock4"`: `expected` são os 18 sem `share`, `share` observado não conta, e um log com `model` ausente segue `dualSense` (D-07) | T011 | `[//]` | `Tests/JoystickCoreTests/LogAnalysisTests.swift` | 🟢 | `[X]` |
| T010 | Em `FigureStateTests`, cobrir `model: .dualShock4`: `controller == "dualShock4"`, 19 itens, `touchpadClick` com `kind: .fixed` e resumo normal (não `absentSummary`), `create` com rótulo "Create" (D-08, RN-10) | T011 | `[//]` | `Tests/JoystickCoreTests/FigureStateTests.swift` | 🟢 | `[X]` |

## Fase 3, Núcleo

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T011 | Em `ControllerModel`: acrescentar `case dualShock4` (`vendorID` 0x054C, `productIDs` {0x05C4, 0x09CC}; 0x0BA0 fora, com comentário apontando a premissa do roadmap §4); criar `enum SystemProfile { dualSense, dualShock, extended }`; trocar a assinatura de `classify` para `(productCategory:profile:hidDevices:)`, com `dualShock4` quando `profile == .dualShock` e `hidDevices` contém um par do modelo, `dualSense` quando `profile == .dualSense`, Ipega como hoje; `buttons` do `dualShock4` = os 18 sem `share`; atualizar o comentário de cabeçalho (D-01) | T001 | `[//]` | `Sources/JoystickCore/Input/ControllerModel.swift` | 🟢 | `[X]` |
| T012 | Criar `DualShock4Report.homeButton(reportID:bytes:) -> Bool?` no núcleo, só `Foundation`: `0x01` com ≥ 10 bytes e `0x11` com ≥ 12 bytes, bit 0 nos índices fixados pela T004 (7 e 9 esperados); outros, `nil`; comentário de cabeçalho com a disposição do bloco comum e a referência à sonda (D-04) | T004 | `[//]` | `Sources/JoystickCore/Input/DualShock4Report.swift` | 🟡 | `[X]` |
| T013 | Em `ControllerReader.connect`: derivar `SystemProfile` de `gamepad is GCDualSenseGamepad` e `gamepad is GCDualShockGamepad`; passar `TransportResolver.presentDevices()` sempre que o perfil não for `dualSense`; trocar o nome padrão por um `switch` com "DualSense", "Pro Controller" e "DualShock 4"; atualizar os comentários de RN-01 (D-01, D-06) | T011 | `[//]` | `Sources/JoystickAIPoC/Controller/ControllerReader.swift` | 🟢 | `[X]` |
| T014 | Em `ButtonReader.digitalButtons`: caso `.dualShock4` com `(.touchpadClick, (pad as? GCDualShockGamepad)?.touchpadButton)`, mantendo `buttonOptions → create` e `buttonMenu → options` (ou o elemento que a T004 fixar para o Share); atualizar o comentário de cabeçalho com a correspondência do DualShock 4 (D-02) | T004, T011 | `[//]` | `Sources/JoystickAIPoC/Controller/ButtonReader.swift` | 🟡 | `[X]` |
| T015 | Em `AxisTouchReader.attach`: substituir o `guard` por `GCDualSenseGamepad` por um `switch` no modelo que devolve as superfícies do touchpad (`touchpadPrimary`, `touchpadSecondary`) de `GCDualSenseGamepad` ou de `GCDualShockGamepad` e `nil` para o Ipega; ligar os analógicos pela interface de controles para `dualSense` e `dualShock4`; manter a escolha `touchState`/`zeroTransition` e o evento `controller.touch_source`; atualizar o comentário de cabeçalho (D-03) | T004, T011 | `[//]` | `Sources/JoystickAIPoC/Controller/AxisTouchReader.swift` | 🟢 | `[X]` |
| T016 | Em `ExtendedReportActivator`: caso `.dualShock4` no `switch` de `handleReport`, chamando `DualShock4Report.homeButton`; em `activate`, estender o pedido do recurso `0x05` por Bluetooth a `dualShock4` conforme a T004 (mantido, ou removido se a sonda mostrar que não muda o modo); atualizar o comentário de cabeçalho. O casamento por `ControllerModel.allCases` já cobre os pares novos e não muda (D-04, D-05) | T004, T012 | `[//]` | `Sources/JoystickAIPoC/Controller/ExtendedReportActivator.swift` | 🟡 | `[X]` |

## Fase 4, Integração

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T017 | Em `figure.js`, acrescentar `dualShock4: true` à tabela `CONTROLLERS` e atualizar o comentário que a descreve (D-08) | T001 | `[//]` | `Resources/ControllerFigure/figure.js` | 🟢 | `[X]` |
| T018 | Em `figure.css`, transformar a regra `.figure[data-controller="dualSense"] [data-button="share"]` numa lista de seletores que inclua `[data-controller="dualShock4"]`, para o grupo e para o balão do Share, com comentário (D-08) | T001 | `[//]` | `Resources/ControllerFigure/figure.css` | 🟢 | `[X]` |
| T019 | Em `FigureAssetsTests`, conferir que `figure.js` cita `dualShock4` em `CONTROLLERS` e que `figure.css` tem o seletor `[data-controller="dualShock4"] [data-button="share"]` (D-08, D-10) | T017, T018 | `[//]` | `Tests/JoystickCoreTests/FigureAssetsTests.swift` | 🟢 | `[X]` |
| T020 | Em `ButtonsCommand` e no texto de ajuda de `main.swift` do `poc-tools`, citar os três modelos (DualSense e DualShock 4 sem `share`, Ipega sem `touchpadClick`); nenhuma lógica muda, porque `ControllerModel.buttons` já decide (D-07) | T011 | `[//]` | `Sources/poc-tools/ButtonsCommand.swift` | 🟢 | `[X]` |
| T021 | Compilar com `swift build -c release` sem avisos no código novo e rodar `./scripts/test.sh` (com o `SDKROOT` e o `-plugin-path` da T001) até ficar verde; registrar nas notas de execução o total de testes e suítes depois da feature (D-10) | T005, T006, T007, T008, T009, T010, T013, T014, T015, T016, T019, T020 | - | `scripts/test.sh` | 🟢 | `[X]` |
| T022 | Instalar o app com `JOYSTICK_SIGN_IDENTITY="JoystickAI Local Signing" ./scripts/build-app.sh` e conferir com `./scripts/check-signature.sh` que a identidade e a folha são as de sempre, para as permissões seguirem válidas; abrir com `--debug`; conferir no `onboarding.md` §3 se algum nome ou passo mudou com a implementação e ajustar (D-11) | T021 | - | `scripts/build-app.sh` | 🟢 | `[X]` |
| T023 | Registrar nas notas de execução o resultado dos 14 passos do PM-1, inclusive a cobertura de botões observada (18 ou 17 de 18, conforme o GameSir tenha ou não tecla para o clique do touchpad) e a contagem de eventos de toque e de erro; se algum passo reprovar, registrar a correção como emenda com ID `E-nn` na seção "Emendas", executá-la e repetir o passo (D-11) | PM-1 | - | `_reversa_forward/012-controle-dualshock-4/actions.md` | 🟡 | `[ ]` |

## Fase 5, Polimento

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T024 | Atualizar os comentários que ainda dizem "os dois modelos" ou citam só DualSense e Ipega em `ControllerDiagnostics.swift`, `TransportResolver.swift` e `ChargePoller.swift`, sem mudança de lógica; a mensagem de supressão de gestos continua a mesma | T014, T015 | - | `Sources/JoystickAIPoC/Controller/ControllerDiagnostics.swift` | 🟢 | `[X]` |
| T025 | Escrever `legacy-impact.md` a partir do rascunho do `roadmap.md` §5 e do diff real: arquivos tocados, regras da extração alteradas (RN-EC-03, RN-EC-11, RN-EC-13, RN-EC-16, RN-ED-14, RN-AT-19 inalterada), contratos emendados e o que não mudou | T021 | `[//]` | `_reversa_forward/012-controle-dualshock-4/legacy-impact.md` | 🟢 | `[ ]` |
| T026 | Escrever `regression-watch.md`: regras sob vigilância (DualSense e Ipega inalterados, fila mista, soltura sintética, PS deduplicado, touchpad mudo no clone, canal Bluetooth Low Energy silencioso, TD-03 com dois DualShock 4) e observações a conferir no PM-1 e na re-extração | T021 | `[//]` | `_reversa_forward/012-controle-dualshock-4/regression-watch.md` | 🟢 | `[ ]` |

## Notas de execução

<!--
Reservado para /reversa-coding registrar avisos ou observações que surgiram durante a execução.
Não use isso para corrigir ações, edits manuais ficam fora desse arquivo, vão direto no código.
-->

- **T001 (2026-09-22):** `.reversa/reversa-config.json` lido na ativação: `allowLegacyEdits: true`, `allowedPaths` vazio, isto é, liberação irrestrita do projeto. Linha de base: **449 testes em 45 suítes**, todos verdes, exatamente o número que o roadmap §10 previa depois da 011. Medidos com `SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk` e `-Xswiftc -plugin-path -Xswiftc /Library/Developer/CommandLineTools/usr/lib/swift/host/plugins/testing`, o mesmo arranjo da T001 das features 008 a 011.

- **T002 (2026-09-22):** sonda escrita em `sondas/probe-ds4.swift` e verificada só com `swiftc -typecheck` (não há controle ligado nesta sessão). Duas escolhas de desenho que vão além do enunciado, para as sondas responderem sem ambiguidade: a cada botão pressionado o programa imprime, entre colchetes, a **propriedade do `GCExtendedGamepad` que aponta para o mesmo objeto** (`buttonOptions`, `buttonMenu`, `buttonHome`, `touchpadButton`), o que fixa D-02 por identidade e não por nome de elemento; e o leitor HID **aprende por 3 s os bits que mudam em repouso** (contador nos bits 2 a 7 do byte do PS, analógicos) e só imprime o que muda fora desse ruído, senão o contador do relatório afogaria o bit do PS. Achado do SDK relevante para a T015: no `GCDualShockGamepad`, `touchpadPrimary` e `touchpadSecondary` são **opcionais** (`GCControllerDirectionPad?`), ao contrário do `GCDualSenseGamepad`; a sonda imprime se existem no aparelho, e a T015 precisa desembrulhá-las.

- **PM-0, T003 e T004 (2026-09-22, 14:22 a 14:26):** a sonda correu pelo próprio `/reversa-coding`, a pedido do usuário, com o usuário ao controle e a saída lida em tempo real; log íntegro em `sondas/probe-ds4-2026-09-22.log`. Os valores estão na tabela "Resultados do PM-0" do `onboarding.md` §1 e no `investigation.md` §3.5. Em resumo: perfil `GCDualShockGamepad`; Share por `buttonOptions`, Options por `buttonMenu`, clique do touchpad por `touchpadButton` (o GameSir tem a tecla); **PS retido pelo sistema** (nada em `buttonHome`); relatório `0x11` de 78 bytes desde a conexão, **PS no bit 0 do byte 9**, contador nos bits 3 a 7; recurso `0x05` `ok` com 41 bytes e formato inalterado; bateria 45 % descarregando; transporte Bluetooth. **D-02, D-04 e D-05 confirmadas** (linha no `roadmap.md` §11): o byte 7 do `0x01` continua da literatura, porque o relatório simplificado nunca apareceu por Bluetooth e não há cabo. Uma premissa do roadmap §4 caiu: o clique do touchpad do GameSir vem com um **toque fixo** em (127, 173) na superfície primária; o rastreador do app já descarta as amostras de eixo dividido desse toque, o cursor não se move, e o passo 13 do PM-1 passou a esperar um par de `input.touch` por clique em vez de zero. Sem isso, o passo reprovaria por um efeito inofensivo.

- **Metade dependente das sondas, T006, T012, T014 a T016, T024 (2026-09-22):** escrita logo depois da T004, sem desvio das decisões confirmadas. Os casos provisórios de `ButtonReader` e `ExtendedReportActivator` foram substituídos pelos definitivos. Em `AxisTouchReader`, as superfícies do touchpad passaram a vir de um `touchSurfaces(of:model:)` por modelo, porque no SDK as do `GCDualShockGamepad` são opcionais; se faltarem, o modelo fica sem analógicos e sem touchpad, o mesmo que o `guard` antigo fazia com um perfil que não fosse `GCDualSenseGamepad`. `ChargePoller.swift` não citava modelo algum e ficou intocado (T024 previa "se tanto").

- **T021 (2026-09-22):** `swift build -c release` sem nenhum aviso do código. Testes: **465 em 46 suítes**, todos verdes, contra 449 em 45 da linha de base: +16 testes e +1 suíte (`DualShock4ReportTests`, 5 casos, inclusive a amostra real do relatório em repouso colhida na P-02).

- **T022 (2026-09-22):** aplicativo instalado em `~/Applications/JoystickAIPoC.app`; assinatura conferida: identificador `dev.iagoleal.joystick-ai.poc`, autoridade `JoystickAI Local Signing`, folha `bd5fe569…`, a mesma de sempre, de modo que as permissões seguem válidas. O `build-app.sh` precisou do `SDKROOT` do SDK 26.5, como na 011. Aberto com `--debug` às 14:32 com o GameSir já conectado: `controller.extended_report` `ok` por Bluetooth, `controller.connected` com `model: "dualShock4"`, `connection: "bluetooth"`, `atStartup: true`, carga 45 % descarregando, `controller.touch_source` `zero_transition`, nenhum `controller.ignored` nem `controller.error`. O `onboarding.md` §3 já tinha sido ajustado na T003 (passos 3 e 13); nenhum nome ou rótulo mudou com a implementação.

- **Metade sem sonda, T005, T007 a T011, T013, T017 a T020 (2026-09-22):** executada antes do PM-0, como o roadmap §1 e a convenção "Duas metades" autorizam. `swift build -c release` sem aviso do código; **460 testes em 45 suítes**, todos verdes, contra 449 da linha de base: +11 casos (`ControllerModelTests` +4, `ActiveControllerRegistryTests` +2, `LogEventCatalogTests` +1, `LogAnalysisTests` +2, `FigureStateTests` +1, `FigureAssetsTests` +1). Um desvio, registrado aqui: o caso novo da enumeração quebra a exaustividade dos `switch` de `ButtonReader.digitalButtons` e `ExtendedReportActivator.handleReport`, cujas ações (T014, T016) esperam o PM-0. Para o pacote compilar e os testes correrem, os dois receberam um **caso provisório** comentado como tal (`(.touchpadClick, nil)` e `nil`), que a T014 e a T016 substituem. O app **não** deve ser instalado neste estado, e a T022 só vem depois da T021, que depende das duas. Em `ControllerModel.classify`, o `switch` por `SystemProfile` só consulta a categoria e o par do Ipega no perfil `extended`; com o perfil `dualShock` sem par, o resultado é `nil`, o mesmo que o código anterior daria, porque a categoria "DualShock 4" nunca casa com a do Ipega.

## Histórico de alterações

| Data | Alteração | Autor |
|------|-----------|-------|
| 2026-09-22 | Versão inicial gerada por `/reversa-to-do` | reversa |
| 2026-09-22 | `/reversa-coding`, rodada 1: T001, T002, T005, T007 a T011, T013, T017 a T020 concluídas; parada no PM-0 | reversa |
| 2026-09-22 | `/reversa-coding`, rodada 2: PM-0 executado; T003, T004, T006, T012, T014 a T016, T021, T022, T024 concluídas; parada no PM-1 | reversa |
