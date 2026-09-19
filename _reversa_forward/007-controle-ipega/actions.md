# Actions: Controle Ipega ao lado do DualSense

> Identificador: `007-controle-ipega`
> Data: `2026-09-19`
> Roadmap: `_reversa_forward/007-controle-ipega/roadmap.md`

## Resumo

| Métrica | Valor |
|---------|-------|
| Total de ações | 33 |
| Paralelizáveis (`[//]`) | 24 |
| Maior cadeia de dependência | 9 (T001 → T002 → T003 → T004 → T021 → T025 → T027 → T031 → T032), seguida do PM-1 e de T033 |

## Convenções desta decomposição

### Portões manuais

Passagens que dependem de ato humano não recebem ID `T`; aparecem como `PM-n` na coluna de dependências. O `/reversa-coding` deve parar ao alcançar um portão e só seguir quando o usuário confirmar o resultado.

| Portão | Ato do usuário | Requer | Referência | Libera |
|--------|----------------|--------|------------|--------|
| PM-1 | Com o app da feature instalado e só o Ipega conectado por cabo, executar o roteiro do `onboarding.md` §2 (19 passos) e relatar os resultados, inclusive P-01, P-02 (ou sua dispensa) e o ajuste visual do Share. | T032 | D-09, D-12, `onboarding.md` §2 | T033 e o critério de pronto |

Não há PM-0: as sondas de 2026-09-19 já responderam o que decidia o desenho (roadmap D-12). A maior cadeia conta apenas ações `T`.

### Ordem das fases

Os testes da Fase 2 dependem dos tipos criados na Fase 3; o `/reversa-coding` executa pela coluna de dependências, e não pela ordem das tabelas. `ControllerInfo` ganha `model` com valor padrão `.dualSense` no inicializador (T003), para que os testes existentes que constroem `ControllerInfo` sigam compilando sem mudança.

### Correspondência com o roadmap

| Decisões do roadmap | Ações |
|---------------------|-------|
| D-01 (`ControllerModel` e classificação) | T002, T011, T025 |
| D-02 (`ButtonID.share`, padrão idêntico) | T004, T007, T014, T015, T017 |
| D-03 (leitura por modelo) | T021, T022, T023, T025 |
| D-04 (Home pelo HID) | T006, T012, T024 |
| D-05 (`ControllerInfo.model`, `connect(accepted:)`) | T003, T005, T013 |
| D-06 (transporte por modelo) | T020 |
| D-07 (log) | T009, T018, T025 |
| D-08 (figura por modelo) | T008, T016, T026, T027, T028, T029 |
| D-09 (posição do Share) | T028; ajuste no PM-1 e em T033 |
| D-10 (cobertura por modelo) | T010, T019, T030 |
| D-11 (testes) | T011 a T019, T029, T031 |
| D-12 (portão manual) | T032, PM-1, T033 |

## Fase 1, Preparação

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T001 | Registrar nas notas de execução o número de testes verdes de `./scripts/test.sh` antes de qualquer mudança (esperado 280) e o estado de `.reversa/reversa-config.json` lido na ativação do `/reversa-coding` | - | - | `_reversa_forward/007-controle-ipega/actions.md` | 🟢 | `[X]` |

## Fase 2, Testes

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T011 | Criar `ControllerModelTests`: DualSense pelo perfil; Ipega pela categoria "Switch Pro Controller" com (0x057E, 0x2009) presente; `nil` para Switch Pro sem o par, para o par sem a categoria e para outra categoria; pares de cada modelo (D-01) | T002 | `[//]` | `Tests/JoystickCoreTests/ControllerModelTests.swift` | 🟢 | `[X]` |
| T012 | Criar `SwitchProReportTests`: `0x30` de 64 bytes com o bit `0x10` do byte 4 ligado e desligado; outros bits do byte 4 não afetam; relatório com menos de 13 bytes e identificador diferente de `0x30` devolvem `nil` (D-04) | T006 | `[//]` | `Tests/JoystickCoreTests/SwitchProReportTests.swift` | 🟢 | `[X]` |
| T013 | Em `ActiveControllerRegistryTests`, cobrir `connect(key:info:accepted:)`: `accepted: false` devolve `.ignored`; fila mista DualSense e Ipega com promoção; soltura sintética que inclui `share` em ordem de `ButtonID` (D-05, RN-09) | T004, T005 | `[//]` | `Tests/JoystickCoreTests/ActiveControllerRegistryTests.swift` | 🟢 | `[X]` |
| T014 | Em `ShortcutDefaultsTests`, fixar que o documento padrão não contém `share` em nenhuma camada, que `share` resolve "nenhuma" na base e em Options, e que a ordem dos 18 primeiros casos de `ButtonID` não mudou (D-02, RN-08) | T007 | `[//]` | `Tests/JoystickCoreTests/ShortcutDefaultsTests.swift` | 🟢 | `[X]` |
| T015 | Em `ShortcutConfigValidationTests`, aceitar `share` como gatilho na base, como modificador em `modifiers` e como nome de camada, sem `pointerButtonNotAllowed` (D-02, RN-05) | T004 | `[//]` | `Tests/JoystickCoreTests/ShortcutConfigValidationTests.swift` | 🟢 | `[X]` |
| T016 | Em `FigureStateTests`, trocar as expectativas de 18 para 19 itens com `share` por último; acrescentar "Share" à tabela de rótulos; `controller` `"dualSense"` por padrão e `"ipega"` com o modelo; com `ipega`, `touchpadClick` segue `fixed` e resume "ausente neste controle" (D-08, RN-13) | T008 | `[//]` | `Tests/JoystickCoreTests/FigureStateTests.swift` | 🟢 | `[X]` |
| T017 | Em `ActionSummaryTests`, cobrir o Share sem ação ("nenhuma"), com texto e como modificador ⌘ (RN-05) | T004 | `[//]` | `Tests/JoystickCoreTests/ActionSummaryTests.swift` | 🟢 | `[X]` |
| T018 | Em `LogEventCatalogTests`, esperar `model` em `controller.connected` para os dois modelos e incluir `controllerIgnored` com `reason: unsupported_model` em `sampleEvents` (D-07) | T009 | `[//]` | `Tests/JoystickCoreTests/LogEventCatalogTests.swift` | 🟢 | `[X]` |
| T019 | Em `LogAnalysisTests`, cobrir a cobertura por modelo: log com `model: ipega` espera `share` e não `touchpadClick`; log sem `model` espera o conjunto do DualSense; total sobre 18 nos dois (D-10) | T010 | `[//]` | `Tests/JoystickCoreTests/LogAnalysisTests.swift` | 🟢 | `[X]` |

## Fase 3, Núcleo

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T002 | Criar `ControllerModel` (`dualSense`, `ipega`, `String` e `Codable`), com os pares (fabricante, produtos) de cada modelo e `classify(productCategory:isDualSenseProfile:hidDevices:) -> ControllerModel?` conforme `data-delta.md` §2 (D-01) | T001 | `[//]` | `Sources/JoystickCore/Input/ControllerModel.swift` | 🟢 | `[X]` |
| T003 | Acrescentar `model: ControllerModel` a `ControllerInfo`, com valor padrão `.dualSense` no inicializador público (D-05) | T002 | - | `Sources/JoystickCore/Input/InputEvent.swift` | 🟢 | `[X]` |
| T004 | Acrescentar `case share` no fim de `ButtonID`, atualizar o comentário do tipo (19 identificadores, `share` só no Ipega) e dar a `share` o `displayName` `"Share"` em `ButtonLabels` (D-02, RN-13) | T003 | - | `Sources/JoystickCore/Input/InputEvent.swift` | 🟢 | `[X]` |
| T005 | Trocar `connect(key:info:isDualSense:)` por `connect(key:info:accepted:)` em `ActiveControllerRegistry` e o comentário de `.ignored` para "modelo não aceito", sem mudar a lógica (D-05) | T001 | `[//]` | `Sources/JoystickCore/Input/ActiveControllerRegistry.swift` | 🟢 | `[X]` |
| T006 | Criar `SwitchProReport.homeButton(reportID:bytes:) -> Bool?`: relatório `0x30` com ≥ 13 bytes, bit `0x10` do byte 4; demais casos `nil`; comentário com a referência às sondas de 2026-09-19 (D-04) | T001 | `[//]` | `Sources/JoystickCore/Input/SwitchProReport.swift` | 🟢 | `[X]` |
| T007 | Em `ShortcutDefaults.optionsLayer`, excluir `share` do laço que grava "nenhuma", para o documento padrão ficar idêntico ao anterior (D-02) | T004 | `[//]` | `Sources/JoystickCore/Config/ShortcutDefaults.swift` | 🟢 | `[X]` |
| T008 | Em `FigureState`, acrescentar `controller: String`, receber `model: ControllerModel?` no inicializador derivado (nulo vira `"dualSense"`), atualizar o comentário para 19 itens e, com `ipega`, resumir `touchpadClick` como "ausente neste controle" (D-08) | T002, T004 | `[//]` | `Sources/JoystickCore/Config/FigureState.swift` | 🟢 | `[X]` |
| T009 | Em `LogEventCatalog.controllerConnected`, gravar `model` a partir de `info.model` (D-07) | T003 | `[//]` | `Sources/JoystickCore/Log/LogEventCatalog.swift` | 🟢 | `[X]` |
| T010 | Em `LogAnalysis.buttonCoverage`, calcular o conjunto esperado pelo `model` do último `controller.connected` (DualSense sem `share`, Ipega sem `touchpadClick`, DualSense sem o campo) e expô-lo em `ButtonCoverage` junto da contagem (D-10) | T004, T009 | `[//]` | `Sources/JoystickCore/Analysis/LogAnalysis.swift` | 🟢 | `[X]` |

## Fase 4, Integração

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T020 | Trocar `TransportResolver.resolve()` por `resolve(for: ControllerModel)` e expor a leitura dos pares (fabricante, produto) presentes no IORegistry para a classificação; remover as constantes Sony, que passam a vir do modelo (D-06, D-01) | T002 | `[//]` | `Sources/JoystickAIPoC/Controller/TransportResolver.swift` | 🟢 | `[X]` |
| T021 | Em `ButtonReader`, receber `GCExtendedGamepad`, o perfil físico e o modelo; manter a tabela do DualSense e acrescentar a do Ipega de `data-delta.md` §3, com o Share por `physicalInputProfile.buttons[GCInputButtonShare]`; atualizar o comentário dos 18 botões (D-03) | T004 | `[//]` | `Sources/JoystickAIPoC/Controller/ButtonReader.swift` | 🟢 | `[X]` |
| T022 | Em `AxisTouchReader`, receber `GCExtendedGamepad` e o modelo; ligar os analógicos em qualquer modelo e o touchpad (e `controller.touch_source`) só no DualSense, por conversão para `GCDualSenseGamepad` (D-03, RN-06) | T002 | `[//]` | `Sources/JoystickAIPoC/Controller/AxisTouchReader.swift` | 🟢 | `[X]` |
| T023 | Em `ControllerDiagnostics`, receber `GCExtendedGamepad`; manter a lista de elementos e o pedido de supressão de gestos em `buttonHome` para os dois modelos (D-03) | T001 | `[//]` | `Sources/JoystickAIPoC/Controller/ControllerDiagnostics.swift` | 🟢 | `[X]` |
| T024 | Em `ExtendedReportActivator`, casar também (0x057E, 0x2009); no relatório, escolher `DualSenseReport` ou `SwitchProReport` pelo fabricante do dispositivo emissor e guardar o estado do Home por dispositivo; manter o pedido `0x05` só para o DualSense sem fio; atualizar o comentário do tipo (D-04) | T006, T020 | `[//]` | `Sources/JoystickAIPoC/Controller/ExtendedReportActivator.swift` | 🟢 | `[X]` |
| T025 | Em `ControllerReader.connect`, classificar o controle (categoria, perfil, pares do IORegistry); recusado, registrar `controller.ignored` com `reason: unsupported_model`; aceito, criar `ControllerInfo` com `model` e `TransportResolver.resolve(for:)`, chamar `connect(accepted: true)` e passar gamepad e modelo aos leitores; publicar `onActiveModelChange` na main thread após conexão, desconexão e promoção (D-01, D-03, D-05, D-07, D-08) | T003, T005, T020, T021, T022, T023 | - | `Sources/JoystickAIPoC/Controller/ControllerReader.swift` | 🟢 | `[X]` |
| T026 | Em `EditorViewModel`, acrescentar `@Published var activeModel: ControllerModel?` e passá-lo a `FigureState` em `figureState` (D-08) | T008 | `[//]` | `Sources/JoystickAIPoC/Editor/EditorViewModel.swift` | 🟢 | `[X]` |
| T027 | Em `AppDelegate`, ligar `controllerReader.onActiveModelChange` a `editorModel.activeModel` (D-08) | T025, T026 | - | `Sources/JoystickAIPoC/App/AppDelegate.swift` | 🟢 | `[X]` |
| T028 | Na página da figura, acrescentar o grupo e o balão `share` (`index.html`), `positions.share` e a gravação de `data-controller` em `render` (`figure.js`), e as regras de ocultar o Share com `dualSense` e marcar o touchpad como ausente com `ipega` (`figure.css`), conforme `interfaces/figure-bridge.md` §4 (D-08, D-09) | T008 | `[//]` | `Resources/ControllerFigure/figure.js` | 🟡 | `[X]` |
| T029 | Em `FigureAssetsTests`, conferir que os 19 identificadores de `ButtonID` têm grupo e balão na página e que `figure.js` conhece `share` e `data-controller`, mantendo a proibição de `innerHTML` e afins (D-11) | T028 | - | `Tests/JoystickCoreTests/FigureAssetsTests.swift` | 🟢 | `[X]` |
| T030 | Em `poc-tools buttons`, listar o conjunto esperado do modelo do log (T010), com o modelo no cabeçalho e "Total: N de 18"; atualizar o texto de uso (D-10) | T010 | `[//]` | `Sources/poc-tools/ButtonsCommand.swift` | 🟢 | `[X]` |

## Fase 5, Polimento

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T031 | Rodar `swift build -c release` e `./scripts/test.sh`; registrar nas notas de execução o total de testes, o número anterior (T001) e os avisos de compilação novos, se houver | T011, T012, T013, T014, T015, T016, T017, T018, T019, T024, T027, T029, T030 | - | `_reversa_forward/007-controle-ipega/actions.md` | 🟢 | `[X]` |
| T032 | Instalar o app com `JOYSTICK_SIGN_IDENTITY="JoystickAI Local Signing" ./scripts/build-app.sh`, conferir a assinatura com `./scripts/check-signature.sh` e parar no PM-1 | T031 | - | `scripts/build-app.sh` | 🟢 | `[X]` |
| T033 | Registrar no `onboarding.md` §3 (novo) o resultado do PM-1 por passo, P-01 e P-02; se o passo 7 reprovar o balão do Share, ajustar `positions.share` e o grupo no `index.html` e repetir o passo | PM-1 | - | `_reversa_forward/007-controle-ipega/onboarding.md` | 🟡 | `[ ]` |

## Notas de execução

- **T001 (2026-09-19):** `./scripts/test.sh` antes de qualquer mudança: 280 testes em 31 suítes, todos verdes (confere com o esperado). `.reversa/reversa-config.json` lido na ativação: `{"version": 1, "allowLegacyEdits": true, "allowedPaths": []}`, liberação irrestrita, avisada ao usuário.
- **T014 (2026-09-19):** o resumo do Share na camada Options do padrão é "nenhuma (herdado)", e não "nenhuma": fora do laço de Options (D-02), o Share não tem entrada própria ali e herda a ação da base, ao contrário dos demais botões livres, que têm "nenhuma" explícito. Com o padrão, o efeito é o mesmo (nada acontece); se o usuário der ação ao Share na base, ela também valerá com Options segurado. Consequência direta de manter o documento padrão idêntico; o teste fixa o comportamento.
- **T024/T025 (2026-09-19):** refinamento dentro do escopo de RN-01: o leitor HID informa o modelo do emissor, e o PS ou o Home só é entregue se o controle ativo for do mesmo modelo. Evita que o Home do Ipega na fila acione a paleta com o DualSense ativo. Com dois controles do mesmo modelo, vale a limitação anterior (entrega ao ativo).
- **T028 (2026-09-19):** não há faixa livre de 190 × 64 px para o 19º balão sem cruzar linhas-guia existentes (conferido contra as 18 linhas-guia). Posição provisória: desenho em (316, 246), à esquerda do touchpad e abaixo de Create; balão compacto de 104 px em (208, 552), no vão inferior entre L3 e PS. A linha-guia do Share cruza as de L3 e →, perto da origem desta. Ajuste no PM-1, passo 7 (D-09 🟡).
- **T031 (2026-09-19):** `swift build -c release` sem avisos novos. `./scripts/test.sh`: 302 testes em 33 suítes, todos verdes (antes: 280 em 31; +22 testes, +2 suítes). O único aviso é o preexistente do `ld` sobre `Testing.framework` das Command Line Tools (macOS 14 contra alvo 13), alheio à feature.
- **T032 (2026-09-19):** `build-app.sh` com "JoystickAI Local Signing" encerrou a instância aberta e instalou em `~/Applications/JoystickAIPoC.app`. `check-signature.sh`: identifier `dev.iagoleal.joystick-ai.poc`, authority "JoystickAI Local Signing", requisito designado com `certificate leaf = H"bd5fe5690ad38f5f4aa4395aaf28299c53c53839"`. Parada no PM-1.
- **Revisão de D-03 no PM-1 (2026-09-19):** com o Ipega ativo, os botões chegavam, mas cursor e rolagem não. Sonda de 90 s com as duas vias ao mesmo tempo: a interface de controles registrou 0 mudanças nos analógicos (valor sempre 0,00), enquanto o relatório HID `0x30` mostrou o curso completo nos quatro eixos (0 a 4080; repouso em 2048/2032). O driver do sistema zera os eixos deste clone. Correção autorizada pelo usuário: `SwitchProReport.sticks` lê os bytes 6 a 11 (12 bits por eixo, y positivo para cima); `ExtendedReportActivator` envia só as mudanças por `onIpegaSticks`; `ControllerReader` as entrega ao Ipega ativo por `AxisTouchReader.deliverStick` (mesma normalização e deduplicação do DualSense); para o Ipega, os analógicos da interface de controles deixam de ser ligados. +4 testes em `SwitchProReportTests`; suíte com 306 testes, verdes. Sentido do eixo Y a confirmar no PM-1.

## Histórico de alterações

| Data | Alteração | Autor |
|------|-----------|-------|
| 2026-09-19 | Versão inicial gerada por `/reversa-to-do` | reversa |
