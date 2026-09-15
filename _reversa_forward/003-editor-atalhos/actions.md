# Actions: Editor de atalhos e comandos

> Identificador: `003-editor-atalhos`
> Data: `2026-09-14`
> Roadmap: `_reversa_forward/003-editor-atalhos/roadmap.md`

## Resumo

| Métrica | Valor |
|---------|-------|
| Total de ações | 76 |
| Paralelizáveis (`[//]`) | 42 |
| Maior cadeia de dependência | 14 (T003 → T023 → T024 → T025 → T030 → T031 → T053 → T056 → T062 → T066 → T067 → T069 → T073 → T075) |

## Convenções desta decomposição

### Portões manuais

Passagens que dependem de ato humano não recebem ID `T`; aparecem como `PM-n` na coluna de dependências. O `/reversa-coding` deve parar ao alcançar um portão e só seguir quando o usuário confirmar o resultado.

| Portão | Ato do usuário | Requer | Referência | Libera |
|--------|----------------|--------|------------|--------|
| PM-0 | Liberar a escrita fora das pastas do Reversa em `.reversa/reversa-config.json`. **Já cumprido:** `allowLegacyEdits: true` com `allowedPaths` vazio (liberação irrestrita), a reler na ativação do `/reversa-coding`. | - | `CLAUDE.md`, roadmap §2 | Todas as ações `T` |
| PM-1a | Compilar e instalar (`scripts/build-app.sh`); executar P-01 (ativação e devolução do foco), P-02 (captura de teclado), P-03 (ditado nos campos) e P-05 (legibilidade a 3 m) com o editor mínimo. | T001 a T014, T076 | D-19, D-22, D-23, `onboarding.md` §1 | T015, T016 |
| PM-1b | Executar P-04 (observação do arquivo por VS Code, `vim`, `echo >`, `mv` e *link* simbólico) com a recarga real já ligada. | T060 | D-16, `onboarding.md` §1 | T061 |
| PM-2 | Roteiro completo do `onboarding.md` §2 (29 passos), com resultados anotados nas notas de execução. | Todas as ações `T` | roadmap §10, `onboarding.md` §2 | Critério de pronto |

A maior cadeia conta apenas ações `T`.

### Ajustes de ordem em relação ao roadmap §8

1. **Parada obrigatória no PM-1a.** O roadmap manda falhar cedo: se P-01 falhar sem alternativa aceitável, volta-se ao `/reversa-clarify`. Por isso o `/reversa-coding` executa a Fase 1 (T001 a T014 e T076) e para no PM-1a antes de iniciar a Fase 2, embora as ações de modelo, validação e mapeador não dependam formalmente do portão.
2. **P-04 separada no PM-1b.** O roadmap previa P-04 com o `ConfigWatcher` "registrando eventos em `debug`", mas o contrato `interfaces/diagnostic-log.md` não define evento para isso, e criar um só para a sonda alteraria o contrato. A sonda passa a rodar depois de T060, quando a recarga externa já produz `shortcuts.loaded`, `shortcuts.invalid` e `shortcuts.unchanged` com `trigger: external`, que são a evidência pedida. O risco é baixo: uma falha altera apenas `ConfigWatcher.swift` (T061), e o editor não depende da observação para salvar (roadmap §9). O PM-1b pode ser executado a qualquer momento depois de T060, sem bloquear o editor.
3. **Gravação através de *link* simbólico.** O roadmap §9 atribui a P-04 a verificação de D-17, mas antes do editor não há caminho de gravação. A verificação passa ao PM-2; T075 acrescenta o passo ao `onboarding.md`.

### Correspondência com as fases do roadmap

| Fase do roadmap | Ações |
|-----------------|-------|
| 0, sondas | T001 a T014, T076, PM-1a, T015, T016; PM-1b e T061 (ajuste 2) |
| 1, núcleo | T017 a T048 |
| 2, integração sem editor | T049 a T060 |
| 3, editor | T062 a T073 |
| Portão manual | PM-2, com T074 e T075 como preparação |

Algumas ações de `JoystickCore` necessárias ao editor mínimo (T001 a T006, T012) foram antecipadas para a Fase 1 desta decomposição.

### Arquivos compartilhados e blocos de compilação

Ações que tocam o mesmo arquivo são sequenciais: `ShortcutMapper.swift` (T002, T035, T036, T037), `CommandPalette.swift` (T004, T012), `PaletteActions.swift` (T012, T051), `PalettePanel.swift` (T013, T052), `LogEventCatalog.swift` (T005, T006), `ShortcutConfigValidation.swift` (T023, T024, T025), `ConfigDocument.swift` (T030, T031), `ShortcutActions.swift` (T035, T036, T049, T050), `EditorDraft.swift` (T043 a T046), `ConfigStore.swift` (T055, T056), `EditorViewModel.swift` (T062, T063), `EditorWindowController.swift` (T009, T071, T072), `EditorMetrics.swift` (T007, T015), `KeyCaptureField.swift` (T008, T016), `StatusMenu.swift` (T011, T058), `ConfigWatcher.swift` (T054, T061), `AppDelegate.swift` (T004, T014, T059, T060, T073), `onboarding.md` (T076, T075), e os testes `ShortcutConfigValidationTests` (T026, T027), `ShortcutMapperTests` (T038, T039), `ShortcutDefaultsTests` (T018, T040), `EditorDraftTests` (T047, T048), `CommandPaletteTests` e `LogEventCatalogTests` (T004 e, depois, T019 e T020).

O pacote deve compilar (`swift build`) ao fim de cada ação, e quem altera uma assinatura corrige os pontos de chamada na mesma ação. `./scripts/test.sh` deve passar ao fim de cada ação de teste, com duas exceções em bloco: entre T012 e T019, o teste de volta circular da paleta falha até ser reescrito; entre T036 e T040, o alvo de testes só volta a compilar e passar com T038 e T040 concluídas.

### Acréscimos da decomposição

Detalhes que o roadmap deixa implícitos e que a decomposição fixa, para que as ações sejam atômicas:

- **Validação em duas camadas (D-05, D-20).** `ShortcutConfigValidation.validate(document)` aplica as regras semânticas sobre o tipo já decodificado; `decode(root:)` cuida da estrutura JSON e chama `validate`. É o que permite a `EditorDraft` reutilizar a validação sem serializar o rascunho.
- **Codificação inversa (D-07).** `ConfigDocument` ganha a codificação de `ShortcutsDocument` para as seções JSON, necessária à fusão e verificada por ida e volta.
- **Resolução compartilhada (D-09, D-21).** `ShortcutConfig.resolvedAction(for:in:)` devolve a ação e se ela é herdada; o mapeador e o editor usam a mesma regra.
- **Resumo de ação (D-21, RF-08).** `ActionSummary` em `JoystickCore` produz os textos da figura ("mesa à esquerda", "Enter (herdado)", "clique esquerdo, fixo") com teste, em vez de formatá-los nas *views*.
- **Gatilho resolvido para o log (D-14).** `ShortcutMapper.lastTrigger` informa botão, camada e tipo; ver a inconsistência 3 abaixo.
- **Identificação sem tecla presa (D-24).** Ligar o modo de identificação solta antes as teclas mantidas pelos atalhos, pois os botões soltos durante o modo não chegam ao mapeador.
- **Amostras para o PM-2.** Arquivos de exemplo em `scripts/config-samples/`, como os da feature 001.

### Inconsistências encontradas ao decompor

Nenhuma bloqueia a execução; todas foram resolvidas pela opção indicada, mas convém revisá-las no `/reversa-audit`.

1. **Assinatura da fusão.** D-07 escreve `merge(existing:shortcuts:palette:)`; `data-delta.md` §2, `merge(existing:document:)`. Adotada a do `data-delta.md`.
2. **`ShortcutIssue`.** D-05 define `{ path, rule }`; `data-delta.md` acrescenta `line: Int?`; as regras `syntax` e `unreadable` só aparecem no contrato de log. Adotado `{ path, rule, line? }`, com `syntax` e `unreadable` no enumerado.
3. **Origem de `shortcut.triggered`.** `data-delta.md` §3 (🟡) faz `keyDown` carregar botão e camada, o que não cobre os tipos `systemShortcut`, `text` e `openPalette`, também registrados. Adotado `ShortcutMapper.lastTrigger`, sem mudar `keyDown`.
4. **`editor.activation_failed`.** Consta do contrato de log (🟡), mas não da lista de D-27. Adotado o contrato.
5. **Sonda P-04 sem evento.** Tratada no ajuste de ordem 2.
6. **`lastConfirmed` ao confirmar "Editar atalhos".** Nem D-13 nem o `data-delta.md` dizem se a entrada fixa passa a ser a última confirmada. Adotado que não passa: a próxima abertura volta ao último comando digitado.

## Fase 1, Preparação

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T001 | Criar `KeyCatalog` com `KeyEntry { name, keyCode, display, group }` e `KeyGroup` (`letters`, `digits`, `punctuation`, `editing`, `navigation`, `function`), cobrindo letras, dígitos, pontuação por nome, Return, Tab, Space, Delete, Forward Delete, Esc, setas, Home, End, Page Up, Page Down e F1 a F12, com busca por nome e por tecla virtual (D-03) | - | `[//]` | `Sources/JoystickCore/Shortcuts/KeyCatalog.swift` | 🟢 | `[X]` |
| T002 | Acrescentar a `SystemShortcut` o `name` estável (`spaceLeft`, `spaceRight`, `missionControl`, `applicationWindows`, `nextWindow`), `init?(name:)` e o rótulo de exibição em português ("mesa à esquerda" etc.) (D-03, RF-08) | - | `[//]` | `Sources/JoystickCore/Shortcuts/ShortcutMapper.swift` | 🟢 | `[X]` |
| T003 | Criar `TriggerAction` (`chord(KeyChord, repeats)`, `systemShortcut`, `text(String, pressEnter)`, `openPalette`, `none`), `ShortcutConfig { modifiers, layers }` com `pointerButtons` (R1, R2, clique do touchpad) e `resolvedAction(for:in:)` que devolve ação e herança, `ShortcutsDocument { shortcuts, palette }` e `ShortcutIssue { path, rule, line? }` com o enumerado de regras de `data-delta.md` §2 mais `syntax` e `unreadable`, todos `Equatable` e `Sendable` (D-02) | - | `[//]` | `Sources/JoystickCore/Config/ShortcutConfig.swift` | 🟢 | `[X]` |
| T004 | Acrescentar `label` (padrão vazio) e `displayText` a `PaletteItem`, `PaletteCloseReason.configChanged` com `rawValue` `config_changed`, e renomear `CommandPalette` para `PaletteDefaults`, corrigindo os usos em `AppDelegate`, `CommandPaletteTests` e `LogEventCatalogTests` (D-04, `data-delta.md` §3) | - | `[//]` | `Sources/JoystickCore/Palette/CommandPalette.swift` | 🟢 | `[X]` |
| T005 | Acrescentar a `LogEventCatalog` os eventos `shortcuts.loaded`, `shortcuts.unchanged` (`debug`), `shortcuts.invalid`, `shortcuts.file_removed`, `shortcuts.saved`, `shortcuts.save_failed`, `shortcuts.restored` e `shortcut.triggered`, com os enumerados de `trigger`, `source`, `reason` e `type` e os níveis e campos de `interfaces/diagnostic-log.md` §2, sem texto, rótulo, tecla nem acorde (D-14, D-27) | T003 | - | `Sources/JoystickCore/Log/LogEventCatalog.swift` | 🟢 | `[X]` |
| T006 | Acrescentar a `LogEventCatalog` os eventos `editor.opened { source }`, `editor.closed { outcome }`, `editor.conflict { choice }`, `editor.identify { on }` e `editor.activation_failed`, com os enumerados `menu`, `palette`, `alert`; `clean`, `saved`, `discarded`; `reload`, `keep`, `pending` (D-27) | T005 | - | `Sources/JoystickCore/Log/LogEventCatalog.swift` | 🟢 | `[X]` |
| T007 | Criar `EditorMetrics` com texto base de 24 pt, títulos de 30 pt, alvo mínimo de 44 pt, tamanho mínimo de janela de 1.100 × 720 pt, e os estilos SwiftUI de botão, alternador e campo de texto que respeitam essas medidas (D-19) | - | `[//]` | `Sources/JoystickAIPoC/Editor/EditorMetrics.swift` | 🟡 | `[X]` |
| T008 | Criar `KeyCaptureField` (`NSViewRepresentable`) que, só enquanto ativo e com a janela em foco, instala `NSEvent.addLocalMonitorForEvents` para `keyDown` e `flagsChanged`, descarta eventos com `eventSourceUserData` igual a `EventInjector.sourceMark`, consome o evento, encerra ao primeiro acorde com tecla do `KeyCatalog` entregando `KeyChord` e remove o monitor ao desativar ou sumir (D-22 a, RN-15) | T001 | `[//]` | `Sources/JoystickAIPoC/Editor/KeyCaptureField.swift` | 🔴 | `[X]` |
| T009 | Criar `EditorWindowController`: `NSWindow` redimensionável e fechável com `NSHostingView` e rolagem interna; `show(source:)` guarda `frontmostApplication`, cria ou reutiliza a janela, chama `NSApp.activate(ignoringOtherApps: true)` e `makeKeyAndOrderFront`, registra `editor.opened` e, se a janela não estiver em foco logo depois, `editor.activation_failed`; ao fechar, reativa o aplicativo guardado se ainda em execução e registra `editor.closed { clean }` (D-19, D-23) | T006, T007 | - | `Sources/JoystickAIPoC/Editor/EditorWindowController.swift` | 🔴 | `[X]` |
| T010 | Criar `EditorProbeView`, provisória para o PM-1a: texto de exemplo nas métricas de TV, um `TextField` e um `KeyCaptureField` que exibe o acorde capturado pelos rótulos do `KeyCatalog` (roadmap §8, Fase 0) | T007, T008 | `[//]` | `Sources/JoystickAIPoC/Editor/EditorProbeView.swift` | 🔴 | `[X]` |
| T011 | Criar `StatusMenu` com `NSStatusItem`, símbolo `gamecontroller` como imagem modelo e os itens "Editar atalhos" (fechamento `onEditShortcuts`) e "Sair" (`NSApp.terminate`) (D-18, RF-06) | - | `[//]` | `Sources/JoystickAIPoC/App/StatusMenu.swift` | 🟢 | `[X]` |
| T012 | Acrescentar a `PaletteMachine` a entrada fixa "Editar atalhos" no índice `items.count`, com seleção circular sobre `items.count + 1` posições e confirmação que produz o novo efeito `PaletteEffect.openEditor` sem `confirm` nem alteração de `lastConfirmed`; em `PaletteActions`, tratar `openEditor` chamando `onOpenEditor` na main thread (D-13, RF-07) | T004 | - | `Sources/JoystickCore/Palette/CommandPalette.swift` | 🟢 | `[X]` |
| T013 | Em `PaletteView`, desenhar `displayText` (com o sufixo " …" da 002 quando não houver rótulo), a entrada fixa "Editar atalhos" separada por uma linha e textos longos truncados pela largura disponível da tela em `fit` (D-13) | T004, T012 | `[//]` | `Sources/JoystickAIPoC/Palette/PalettePanel.swift` | 🟢 | `[X]` |
| T014 | No `AppDelegate`, criar `StatusMenu` e `EditorWindowController` com `EditorProbeView`; ligar "Editar atalhos" do menu a `show(source: .menu)` e `paletteActions.onOpenEditor` a `show(source: .palette)` (roadmap §8, Fase 0) | T009, T010, T011, T012, T013 | - | `Sources/JoystickAIPoC/App/AppDelegate.swift` | 🔴 | `[X]` |
| T015 | Registrar nas notas de execução os resultados de P-01, P-02, P-03 e P-05 e ajustar as constantes de `EditorMetrics` conforme a legibilidade e a precisão de clique observadas a 3 m | PM-1a | `[//]` | `Sources/JoystickAIPoC/Editor/EditorMetrics.swift` | 🟡 | ``[X]` |
| T016 | Declarar em `KeyCaptureField` a lista de acordes que P-02 mostrou serem consumidos pelo sistema antes do app (por exemplo Command+Tab e Command+Space), para o editor indicar que exigem a montagem (D-22) | PM-1a | `[//]` | `Sources/JoystickAIPoC/Editor/KeyCaptureField.swift` | 🔴 | `[X]` |
| T076 | Adaptar o `onboarding.md` §1 à separação dos portões: PM-1a com P-01, P-02, P-03 e P-05 e registro de quatro resultados; P-04 remetida ao PM-1b, depois de T060, com a releitura verificada pelos eventos `shortcuts.*` de `trigger: external` (acrescentada na revisão pós-auditoria, A005) | - | `[//]` | `_reversa_forward/003-editor-atalhos/onboarding.md` | 🟢 | `[X]` |

## Fase 2, Testes

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T017 | Criar `KeyCatalogTests`: nomes e teclas virtuais únicos, ida e volta nome ↔ tecla, rótulo não vazio, presença de cada grupo e das teclas listadas em D-03 | T001 | `[//]` | `Tests/JoystickCoreTests/KeyCatalogTests.swift` | 🟢 | `[X]` |
| T018 | Criar `ShortcutDefaultsTests` com a tabela de equivalência registrada do `switch` atual: os 18 botões na base e com L1, L2 e Options segurados isoladamente, pressionar e soltar, por uma fábrica `makeMapper()` e uma normalização `normalized(_:)` ainda identidade; deve passar antes de T036 (D-04) | - | `[//]` | `Tests/JoystickCoreTests/ShortcutDefaultsTests.swift` | 🟢 | `[X]` |
| T019 | Atualizar `CommandPaletteTests`: lista por `PaletteDefaults` com rótulo vazio, `displayText`, entrada fixa na 18.ª posição, ↑ no primeiro item levando à entrada fixa, confirmação da entrada produzindo `openEditor` sem `confirm` e sem mudar `lastConfirmed`, e `rawValue` de `configChanged` | T004, T012 | `[//]` | `Tests/JoystickCoreTests/CommandPaletteTests.swift` | 🟢 | `[X]` |
| T020 | Acrescentar os eventos `shortcuts.*`, `shortcut.triggered` e `editor.*` a `sampleEvents` de `LogEventCatalogTests`, com teste de que nenhum contém texto, rótulo, nome de tecla ou acorde, e de `palette.closed` com `config_changed` (RN-14) | T004, T005, T006 | `[//]` | `Tests/JoystickCoreTests/LogEventCatalogTests.swift` | 🟢 | `[X]` |
| T021 | Criar `ShortcutConfigTests`: `resolvedAction(for:in:)` com ação própria, herdada, "nenhuma" própria bloqueando a herança e botão ausente na base; `SystemShortcut` com ida e volta de `name` | T002, T003 | `[//]` | `Tests/JoystickCoreTests/ShortcutConfigTests.swift` | 🟢 | `[X]` |

## Fase 3, Núcleo

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T022 | Criar `ShortcutDefaults.config` com a tabela de RN-11: modificadores L1 e L2 sem teclas e Options com Command; camadas base, L1, L2 e Options, esta com "nenhuma" explícita nos botões fora de → e ← (D-04) | T003 | `[//]` | `Sources/JoystickCore/Config/ShortcutDefaults.swift` | 🟢 | `[X]` |
| T023 | Criar `ShortcutConfigValidation.validate(_ document:) -> [ShortcutIssue]` com as regras semânticas de D-05: modificador fora de R1, R2 e clique do touchpad; camada só de modificador; modificador e botão de apontamento fora de toda camada; texto de uma linha com 1 a 1.000 caracteres; rótulo com até 80; paleta com 1 a 50 itens; caminhos no formato `shortcuts.layers.l2.dpadLeft` e `palette.items[3].text` | T003 | `[//]` | `Sources/JoystickCore/Config/ShortcutConfigValidation.swift` | 🟢 | `[X]` |
| T024 | Implementar a decodificação da seção `shortcuts` a partir de `JSONValue`: `version` 1, `modifiers`, `layers` com `base` ou botão, ações `chord`, `systemShortcut`, `text`, `openPalette` e `none` com campos e padrões de `interfaces/config-file.md` §2.1, e as regras `unsupportedVersion`, `unknownKey`, `unknownModifier`, `unknownSystemShortcut`, `unknownActionType` e `wrongType` (D-05) | T001, T002, T023 | - | `Sources/JoystickCore/Config/ShortcutConfigValidation.swift` | 🟢 | `[X]` |
| T025 | Implementar `decode(root:) -> Result<ShortcutsDocument, [ShortcutIssue]>`: decodificação da seção `palette` (§2.2), seção ausente substituída pelo padrão, `validate` sobre o documento montado e recusa conjunta das duas seções diante de qualquer erro (D-05, RN-08) | T004, T022, T024 | - | `Sources/JoystickCore/Config/ShortcutConfigValidation.swift` | 🟢 | `[X]` |
| T026 | Criar `ShortcutConfigValidationTests` para `shortcuts`: um caso por regra de T023 e T024, formato do caminho e ausência do valor recusado na mensagem | T024 | - | `Tests/JoystickCoreTests/ShortcutConfigValidationTests.swift` | 🟢 | `[X]` |
| T027 | Acrescentar a `ShortcutConfigValidationTests` os casos de `palette` (0, 1, 50 e 51 itens, texto e rótulo nos limites, quebra de linha), seções ausentes, só uma seção presente, erro numa seção recusando as duas (RN-08) e `validate(ShortcutDefaults)` sem problemas | T025, T026 | - | `Tests/JoystickCoreTests/ShortcutConfigValidationTests.swift` | 🟢 | `[X]` |
| T028 | Criar `ConfigLineLocator.line(of path:, in data:) -> Int?`: varredura léxica que acompanha objetos, listas e cadeias com escape e devolve a linha de início do valor do caminho (D-06) | - | `[//]` | `Sources/JoystickCore/Config/ConfigLineLocator.swift` | 🟡 | `[X]` |
| T029 | Criar `ConfigLineLocatorTests`: caminhos aninhados e com índice, chaves e chaves de fechamento dentro de cadeias, aspas escapadas, mesma chave em objetos diferentes, caminho inexistente devolvendo `nil` e quebras de linha CRLF | T028 | `[//]` | `Tests/JoystickCoreTests/ConfigLineLocatorTests.swift` | 🟡 | `[X]` |
| T030 | Criar em `ConfigDocument` a codificação de `ShortcutsDocument` para as seções `shortcuts` e `palette` como `JSONValue`, inversa de T025 (D-07) | T025 | `[//]` | `Sources/JoystickCore/Config/ConfigDocument.swift` | 🟢 | `[X]` |
| T031 | Implementar `ConfigDocument.merge(existing: JSONValue?, document:) -> Data`: substitui só `shortcuts` e `palette` na raiz existente, cria o objeto quando ausente ou não objeto e serializa com `[.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]` (D-07, RN-10) | T030 | - | `Sources/JoystickCore/Config/ConfigDocument.swift` | 🟢 | `[X]` |
| T032 | Criar `ConfigDocumentTests`: ida e volta `decode(encode(doc)) == doc` para o padrão e um documento com camada nova; fusão preservando `pointer` e chaves desconhecidas por valor; criação do objeto; mesmos *bytes* em duas gravações | T031 | - | `Tests/JoystickCoreTests/ConfigDocumentTests.swift` | 🟢 | `[X]` |
| T033 | Alterar `ConfigLoader` para decodificar a raiz uma vez e entregá-la a `PointerSettingsValidation` e a `ShortcutConfigValidation`; acrescentar a `ConfigLoadResult` `shortcuts`, `shortcutsSource` e `shortcutIssues` com linha por `ConfigLineLocator` (ou de `describe` no erro de sintaxe), com `ShortcutIssue` de `rule: unreadable` para arquivo ilegível, acima de 1 MiB ou diretório no lugar do arquivo, e expor os *bytes* lidos, sem mudar `pointer` nem os eventos `config.*` (D-06, D-08) | T025, T028 | `[//]` | `Sources/JoystickCore/Config/ConfigLoader.swift` | 🟢 | `[X]` |
| T034 | Acrescentar a `ConfigLoaderTests`: arquivo ausente e só `pointer` com padrões e `reason`; `shortcuts` inválido mantendo `pointer` lido, padrões e linha do problema; erro de sintaxe com `rule: syntax` e linha; arquivo acima de 1 MiB e diretório com `rule: unreadable`; casos atuais de `pointer` inalterados | T033 | - | `Tests/JoystickCoreTests/ConfigLoaderTests.swift` | 🟢 | `[X]` |
| T035 | Acrescentar `ShortcutAction.systemDown(SystemShortcut)` e `systemUp(SystemShortcut)`; em `ShortcutActions`, ler `AppleSymbolicHotKeys` por `CFPreferencesCopyAppValue` no pressionar, pressionar o acorde obtido e guardá-lo por atalho para o soltar; `releaseAll()` devolve cada `systemUp` convertido em `keyUp` do acorde efetivamente pressionado, para que `repeatReleases` o repita na retomada da injeção (D-11, RN-07, adendo 001 `pointer-control` EC-01) | T002 | `[//]` | `Sources/JoystickAIPoC/Pointer/ShortcutActions.swift` | 🟡 | `[X]` |
| T036 | Reescrever `ShortcutMapper` sobre `ShortcutConfig` (`init(config:)` com padrão `ShortcutDefaults.config`): `modifierOrder`, camada do modificador mais antigo, ação por `resolvedAction` decidida no pressionar e guardada até o soltar, `modifierDown`/`modifierUp` das teclas mantidas, `[]` para botões de apontamento, `releaseAll` zerando estado, conforme `data-delta.md` §4; remover `switch`, `systemChords` e `commandHeldByOptions` e ajustar a criação em `ShortcutActions` (D-09, D-10, RN-01, RN-03) | T018, T022, T035 | - | `Sources/JoystickCore/Shortcuts/ShortcutMapper.swift` | 🟢 | `[X]` |
| T037 | Acrescentar a `ShortcutMapper` o `lastTrigger { button, layer, type }` do último pressionar com ação diferente de "nenhuma", zerado quando o pressionar não produz ação (D-14) | T036 | - | `Sources/JoystickCore/Shortcuts/ShortcutMapper.swift` | 🟡 | `[X]` |
| T038 | Adaptar `ShortcutMapperTests` à configuração padrão: casos atuais com `systemDown`/`systemUp` no lugar dos acordes de sistema, botões de apontamento sem ação, PS nas camadas e `releaseAll`, inclusive com atalho de sistema segurado devolvendo `systemUp`; retirar o teste de `systemChords` | T036 | - | `Tests/JoystickCoreTests/ShortcutMapperTests.swift` | 🟢 | `[X]` |
| T039 | Acrescentar a `ShortcutMapperTests` configurações próprias: herança, "nenhuma" própria, L3 como modificador mantendo Control, RN-01 com o modificador solto antes, RN-03 nas duas ordens de L1 e L2, e `lastTrigger` por tipo | T037, T038 | - | `Tests/JoystickCoreTests/ShortcutMapperTests.swift` | 🟢 | `[X]` |
| T040 | Trocar em `ShortcutDefaultsTests` a fábrica para `ShortcutMapper(config: ShortcutDefaults.config)` e a normalização para converter `systemDown`/`systemUp` no acorde padrão; a tabela registrada em T018 não muda (D-04) | T018, T036 | `[//]` | `Tests/JoystickCoreTests/ShortcutDefaultsTests.swift` | 🟢 | `[X]` |
| T041 | Criar `ActionSummary.text(for button:, layer:, in config:)` com o resumo exibido na figura: acorde pelos rótulos do `KeyCatalog`, atalho de sistema pelo rótulo de T002, rótulo ou texto truncado, "abrir paleta", "nenhuma", sufixo "(herdado)", "modificador" e "clique esquerdo, fixo" ou "clique direito, fixo" (D-21, RF-08) | T001, T002, T003 | `[//]` | `Sources/JoystickCore/Config/ActionSummary.swift` | 🟡 | `[X]` |
| T042 | Criar `ActionSummaryTests` com o critério de RF-08 na camada L2 do padrão: ← "mesa à esquerda", ✕ "Enter (herdado)", R1 "clique esquerdo, fixo" | T041 | - | `Tests/JoystickCoreTests/ActionSummaryTests.swift` | 🟡 | `[X]` |
| T043 | Criar `EditorDraft` com `base`, `document`, `isDirty`, `issues` obtidos de `validate` e convertidos do caminho para `EditorTarget` (`trigger`, `modifier`, `paletteItem`), `warnings` com `noPaletteTrigger`, e os tipos `EditorIssue`, `EditorWarning` e `EditorOperationError` (D-20) | T023 | `[//]` | `Sources/JoystickCore/Config/EditorDraft.swift` | 🟢 | `[X]` |
| T044 | Implementar as operações de atalho de `EditorDraft`: atribuir ação a um gatilho, voltar a herdar, marcar modificador com teclas mantidas, alterar essas teclas, desmarcar removendo a camada e as ações próprias, e recusar botões de apontamento com `pointerButton` (D-20, RF-09, RF-11) | T043 | - | `Sources/JoystickCore/Config/EditorDraft.swift` | 🟢 | `[X]` |
| T045 | Implementar as operações de paleta de `EditorDraft`: incluir em posição, remover (recusando o último), mover para cima e para baixo, e editar rótulo, texto e Enter, recusando quebra de linha e excesso de caracteres com o motivo (D-20, RF-14, RN-12) | T044 | - | `Sources/JoystickCore/Config/EditorDraft.swift` | 🟢 | `[X]` |
| T046 | Implementar em `EditorDraft` `restoreDefaults()` e `rebase(to:keepChanges:)`, que troca a base pela vigente nova e descarta ou mantém o rascunho (D-20, D-25, D-26) | T022, T045 | - | `Sources/JoystickCore/Config/EditorDraft.swift` | 🟢 | `[X]` |
| T047 | Criar `EditorDraftTests` para atalhos: atribuir e herdar, marcar e desmarcar modificador, ✕ marcado como modificador com Enter na base gerando problema em `trigger(base, cross)` (RF-12), recusa de R1, `isDirty` voltando a falso ao desfazer e aviso `noPaletteTrigger` | T044 | `[//]` | `Tests/JoystickCoreTests/EditorDraftTests.swift` | 🟢 | `[X]` |
| T048 | Acrescentar a `EditorDraftTests` a paleta (limites, reordenação, edições), `restoreDefaults` e `rebase` com e sem manter o rascunho | T046, T047 | - | `Tests/JoystickCoreTests/EditorDraftTests.swift` | 🟢 | `[X]` |

## Fase 4, Integração

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T049 | Criar `ShortcutActions.apply(_ config:)` na fila `input`: interrompe a repetição, executa `releaseAll()` e recria o mapeador com a configuração nova, de modo que botões segurados na troca sejam ignorados até soltos (D-12, RN-09) | T036 | `[//]` | `Sources/JoystickAIPoC/Pointer/ShortcutActions.swift` | 🟢 | `[X]` |
| T050 | Registrar `shortcut.triggered` em `ShortcutActions` a partir de `mapper.lastTrigger`, a cada pressionar que execute ação (D-14, RN-14) | T005, T037, T049 | - | `Sources/JoystickAIPoC/Pointer/ShortcutActions.swift` | 🟡 | `[X]` |
| T051 | Criar `PaletteActions.apply(items:)` na fila `input`: fecha a paleta aberta com `config_changed`, recria a máquina com os itens novos e `lastConfirmed` nulo e publica os itens na main thread por `onItems`; atualizar o comentário de `defaultEnterDelayMs`, que volta a valer para itens com Enter (D-12) | T012 | `[//]` | `Sources/JoystickAIPoC/Palette/PaletteActions.swift` | 🟢 | `[X]` |
| T052 | Acrescentar `PalettePanel.update(items:)` na main thread, que troca a lista de `PaletteView` e recalcula o tamanho na próxima abertura (D-12) | T013 | `[//]` | `Sources/JoystickAIPoC/Palette/PalettePanel.swift` | 🟢 | `[X]` |
| T053 | Criar `ConfigWriter`: resolve *link* simbólico, lê a raiz atual, sinaliza erro de sintaxe para confirmação, copia para `config.json.bak` quando confirmado, funde por `ConfigDocument.merge`, cria o diretório e grava com `Data.write(options: .atomic)` no destino; devolve *bytes*, `created` e `backup`, ou mensagem com caminho e erro do sistema (D-17) | T031 | `[//]` | `Sources/JoystickAIPoC/Config/ConfigWriter.swift` | 🟡 | `[X]` |
| T054 | Criar `ConfigWatcher` com `DispatchSource.makeFileSystemObjectSource` (`.write`, `.rename`, `.delete`) no diretório do arquivo e no do destino do *link*, ancestral existente mais próximo quando o diretório falta, troca para o filho quando ele surge, e releitura agendada 150 ms após o último evento, entregue na main thread (D-16) | - | `[//]` | `Sources/JoystickAIPoC/Config/ConfigWatcher.swift` | 🔴 | `[X]` |
| T055 | Criar `ConfigStore` na main thread com `ConfigState` (`current`, `status`, `lastBytes`, `source`): `start(with:)` a partir do resultado do `ConfigLoader`; `reload(trigger:)` que compara *bytes* (`shortcuts.unchanged`), aplica leitura válida (`shortcuts.loaded`), mantém a vigente na inválida, isto é, com `shortcutIssues` não vazio, inclusive `unreadable` (`shortcuts.invalid`), e no arquivo removido (`shortcuts.file_removed`); `onApply` para a fila `input` e observadores de estado que recebem o `trigger` da aplicação (D-15, D-16, RN-08) | T005, T033 | `[//]` | `Sources/JoystickAIPoC/Config/ConfigStore.swift` | 🟢 | `[X]` |
| T056 | Acrescentar a `ConfigStore` `save(_ document:, confirmBackup:)` por `ConfigWriter`, guardando os *bytes* gravados, aplicando com `trigger: editor` e registrando `shortcuts.saved` ou `shortcuts.save_failed` sem alterar a vigente, e `restoreDefaults()` que grava os padrões com `trigger: restore` e `shortcuts.restored` (D-17, D-26) | T053, T055 | - | `Sources/JoystickAIPoC/Config/ConfigStore.swift` | 🟡 | `[X]` |
| T057 | Acrescentar a `InputRouter` o modo de identificação: `setIdentifying(_:)` na fila `input`, que ao ligar fecha a paleta e solta as teclas dos atalhos; com ele ligado, todo botão segue para `ButtonActions` e os demais, fora R1, R2 e clique do touchpad, vão só a `onIdentify` pela main thread (D-24, RN-16) | - | `[//]` | `Sources/JoystickAIPoC/Pointer/InputRouter.swift` | 🟢 | `[X]` |
| T058 | Acrescentar a `StatusMenu` `update(status:)`: com configuração inválida, símbolo `exclamationmark.triangle` e, no topo, "Configuração inválida: linha N" com `onOpenFromAlert` e separador; com leitura válida, volta ao estado normal (D-18, RF-20) | T011 | `[//]` | `Sources/JoystickAIPoC/App/StatusMenu.swift` | 🟢 | `[X]` |
| T059 | No `AppDelegate`, trocar a leitura direta por `ConfigStore` iniciado antes do controle, registrar `shortcuts.loaded { startup }`, criar `ShortcutActions` e `PaletteActions` com a vigente e ligar `onApply` a `paletteActions.apply` e depois `shortcutActions.apply` na fila `input`, com `onItems` para `palettePanel.update` (D-12, D-15) | T014, T049, T051, T052, T055 | - | `Sources/JoystickAIPoC/App/AppDelegate.swift` | 🟢 | `[X]` |
| T060 | No `AppDelegate`, iniciar `ConfigWatcher` chamando `store.reload(trigger: .external)`, registrar `StatusMenu` como observador do estado e ligar o item de alerta a `show(source: .alert)` (D-16, D-18, RF-03, RF-20) | T054, T058, T059 | - | `Sources/JoystickAIPoC/App/AppDelegate.swift` | 🔴 | `[X]` |
| T061 | Registrar nas notas de execução o resultado de P-04 e ajustar `ConfigWatcher` (eventos observados, atraso de releitura, tratamento do *link*) conforme o observado | PM-1b | - | `Sources/JoystickAIPoC/Config/ConfigWatcher.swift` | 🔴 | `[X]` |
| T062 | Criar `EditorViewModel` (`ObservableObject`, main thread) com `draft`, `selectedLayer`, `selectedButton`, `identifying`, mensagem de operação recusada, erro de gravação e confirmação de *backup* pendente; estado inicial lido do `ConfigStore` a cada abertura, com `conflict = externalInvalid(line)` se a configuração já estiver inválida; intenções que chamam as operações de `EditorDraft`; `save()` e `restoreDefaults()` por `ConfigStore`, que, bem-sucedidos, rebaseiam o rascunho na vigente gravada; e `discard()` (D-20, D-26, RF-04, RF-13) | T046, T056 | - | `Sources/JoystickAIPoC/Editor/EditorViewModel.swift` | 🟢 | `[X]` |
| T063 | Acrescentar a `EditorViewModel` a reação à vigente nova vinda de `trigger: external` (as de `editor` e `restore` já foram tratadas em T062 e não abrem conflito): sem rascunho sujo, adota; com rascunho sujo, `conflict = externalChange` e escolhas Recarregar e Manter por `rebase`; leitura inválida em `externalInvalid(line)` sem tocar no rascunho; registrar `editor.conflict` (D-25, RF-18) | T062 | - | `Sources/JoystickAIPoC/Editor/EditorViewModel.swift` | 🟢 | `[X]` |
| T064 | Criar `ControllerFigureView`: formas SwiftUI nas posições físicas (gatilhos e *bumpers* no topo, direcional à esquerda, botões de ação à direita, touchpad, Create, Options e PS ao centro, analógicos embaixo), cada botão clicável com o `ActionSummary`, destaque de seleção e de problema, herdados esmaecidos e fixos sem edição (D-21, RF-08, RF-17) | T015, T041 | `[//]` | `Sources/JoystickAIPoC/Editor/ControllerFigureView.swift` | 🟡 | `[X]` |
| T065 | Criar `ChordEditor` com "Gravar pelo teclado" (`KeyCaptureField`) e "Montar" (grade de teclas por grupo do `KeyCatalog` e alternadores de Command, Option, Control e Shift), mais o aviso dos acordes consumidos pelo sistema de T016 (D-22, RF-10) | T015, T016 | `[//]` | `Sources/JoystickAIPoC/Editor/ChordEditor.swift` | 🔴 | `[X]` |
| T066 | Criar `ActionPanel` do botão selecionado: tipo de ação (acorde, atalho de sistema, texto com Enter, abrir paleta, nenhuma, herdar fora da base), detalhe de cada tipo com `ChordEditor`, alternador "Este botão é modificador" com as quatro teclas, confirmação ao desmarcar e estado "fixo" para botões de apontamento (D-21, RF-09, RF-11) | T062, T065 | - | `Sources/JoystickAIPoC/Editor/ActionPanel.swift` | 🟡 | `[X]` |
| T067 | Criar `ShortcutsTab` com seletor de camada (base e uma por modificador), `ControllerFigureView` e `ActionPanel` lado a lado (D-21) | T064, T066 | - | `Sources/JoystickAIPoC/Editor/ShortcutsTab.swift` | 🟡 | `[X]` |
| T068 | Criar `PaletteTab`: lista com campos de rótulo e texto, alternador de Enter, incluir, remover, "Mover para cima", "Mover para baixo", arrastar por `onMove` e mensagem dos limites recusados (D-21, RF-14) | T015, T062 | `[//]` | `Sources/JoystickAIPoC/Editor/PaletteTab.swift` | 🟡 | `[X]` |
| T069 | Criar `EditorRootView` com as abas Atalhos e Paleta, alternador do modo de identificação, `EditorBanners` e rodapé com Salvar (desabilitado com `issues`), Descartar e Restaurar padrão com confirmação (D-19, D-26, RF-12, RF-15) | T063, T067, T068, T070 | - | `Sources/JoystickAIPoC/Editor/EditorRootView.swift` | 🟡 | `[X]` |
| T070 | Criar `EditorBanners`: faixa de conflito com Recarregar e Manter, erro de leitura com linha, erro de gravação com caminho, confirmação de *backup* do arquivo com erro de sintaxe e aviso `noPaletteTrigger` (D-17, D-20, D-25) | T015, T063 | `[//]` | `Sources/JoystickAIPoC/Editor/EditorBanners.swift` | 🟡 | `[X]` |
| T071 | Em `EditorWindowController`, interceptar o fechamento com rascunho sujo e abrir o diálogo Salvar, Descartar e Cancelar, registrando `editor.closed` com `saved`, `discarded` ou `clean` (D-23, RF-13) | T009, T062 | `[//]` | `Sources/JoystickAIPoC/Editor/EditorWindowController.swift` | 🔴 | `[X]` |
| T072 | Em `EditorWindowController`, desligar o modo de identificação ao fechar a janela e ao perder o foco, por um fechamento `onIdentifyOff` (D-24) | T071 | - | `Sources/JoystickAIPoC/Editor/EditorWindowController.swift` | 🟢 | `[X]` |
| T073 | No `AppDelegate`, criar `EditorViewModel` com o `ConfigStore`, trocar `EditorProbeView` por `EditorRootView` e apagar o arquivo provisório, ligar `router.onIdentify` à seleção do botão e `identifying` a `router.setIdentifying` na fila `input`, com `editor.identify` (D-23, D-24) | T057, T060, T069, T072 | - | `Sources/JoystickAIPoC/App/AppDelegate.swift` | 🔴 | `[X]` |

## Fase 5, Polimento

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T074 | Criar amostras para o PM-2: L3 como modificador com L3+○ em Mission Control, R1 numa camada, vírgula faltando na linha 12 e paleta com `/reversa-docs` no topo, todas com a seção `pointer` de `stick-1800.json` | T025 | `[//]` | `scripts/config-samples/` | 🟢 | `[X]` |
| T075 | Adaptar o `onboarding.md` §2 e §3: verificação da gravação através de *link* simbólico e passo de revogar e devolver a Acessibilidade com L2+← segurado no PM-2, limitação de P-03 se o ditado falhar, ajustes de P-04 decorrentes de T061, uso das amostras de T074, e conferência de nomes de arquivos, eventos e textos da interface contra o código | T061, T073, T074, T076 | - | `_reversa_forward/003-editor-atalhos/onboarding.md` | 🟢 | `[X]` |

## Notas de execução

### Rodada 1, 2026-09-14

- **Política de escrita:** relida na ativação; `allowLegacyEdits: true` com `allowedPaths` vazio, liberação irrestrita.
- **Concluídas:** T001 a T014, T019 e T076, 16 de 76 ações. `./scripts/test.sh` verde com 163 testes (eram 157); compilação de depuração e de release sem avisos.
- **T019 antecipada:** T012 quebra a volta circular e a faixa de seleção de `CommandPaletteTests`, como previsto no bloco T012 → T019; a ação foi executada nesta rodada para não encerrá-la com a suíte vermelha. Inclui um teste de lista configurada com a entrada fixa (D-28).
- **T001, exibição de acordes:** `KeyCatalog.display(_:)` monta o acorde com ⌃ ⌥ ⇧ ⌘ antes do rótulo da tecla; usado pelo editor mínimo e disponível para `ActionSummary` (T041).
- **T003, herança:** `resolvedAction(for:in:)` marca `inherited` sempre que a camada pedida é de modificador e o botão está ausente nela, mesmo com a base também ausente (resultado "nenhuma (herdado)").
- **T008, eventos injetados:** com a gravação ativa, teclas com a marca do app são consumidas, e não repassadas, para que o Enter do controle não acione um botão do editor; `flagsChanged` também é consumido enquanto a gravação espera a tecla.
- **T009, ativação:** no macOS 14 ou superior, a abertura usa `NSApp.activate()` e o fechamento usa `NSApp.yieldActivation(to:)` seguido de `activate()` no aplicativo guardado; no macOS 13, as formas com `ignoringOtherApps`. `editor.activation_failed` é registrado se, 500 ms após o pedido, o app não estiver ativo com a janela em foco.
- **T012, entrada fixa:** confirmar "Editar atalhos" fecha a paleta, emite `openEditor` e não altera `lastConfirmed` (inconsistência 6).
- **Parada no PM-1a:** a instalação (`JOYSTICK_SIGN_IDENTITY="JoystickAI Local Signing" ./scripts/build-app.sh`) fica com o usuário, porque encerra a instância aberta; em seguida, as sondas P-01, P-02, P-03 e P-05 do `onboarding.md` §1.

### Rodada 2, 2026-09-15: PM-1a, primeira execução

Sondas executadas pelo usuário na sessão de log `poc-20260914-230802.jsonl`, com o app instalado em 2026-09-14 às 23:07.

- **P-01, reprovada pela paleta:** a janela abriu atrás do aplicativo em uso nas seis aberturas pela paleta, todas com `editor.activation_failed`. Pelo ícone da barra de menus, quatro de cinco aberturas ativaram a janela; a exceção foi um segundo clique com a janela já aberta. O cursor pisca no campo mesmo com a janela atrás, porque ela é a principal do app, mas o app não fica ativo. Causa: no macOS 14 ou superior, `NSApp.activate()` é recusado sem interação recente com o app, e o botão do controle lido por `GameController` não conta como interação. A devolução do foco ao fechar não foi informada.
- **P-01, ajuste:** `EditorWindowController` espera 150 ms (`fallbackDelay`); se o app não estiver ativo com a janela em foco, chama `orderFrontRegardless()` e posta, pelo `EventInjector.activationClick(at:)`, um clique no centro da barra de título, com a marca do app e a volta do cursor à posição anterior. `editor.activation_failed` passa a significar falha também do clique, conferida 500 ms depois dele; nenhum evento novo foi criado, e a ausência desse evento em aberturas `source: palette` comprova o ajuste. Se o reteste falhar, adota-se a alternativa de D-23 (paleta levando o ponteiro ao ícone).
- **P-02, aprovada em parte:** Command+Shift+Z e Command+Q foram gravados, e Command+Q não encerrou o app (mesmo processo antes e depois). Command+Tab abriu a troca de aplicativos e Command+Space abriu o Raycast antes de chegarem ao campo. Não informados: ✕ do controle com a gravação ativa e digitação no Terminal com o campo inativo.
- **T016:** `KeyCaptureField.consumedBeforeApp` declara Command+Tab e Command+Space; `KeyChord.space` foi acrescentado ao lado das demais teclas nomeadas.
- **P-03, reprovada:** dez toques em R3 entre 09:20 e 09:22 e nenhum texto no campo. Não se sabe se a interface de ditado do Raycast apareceu nem para onde foi o texto; como a janela estava sujeita à falha de P-01, a sonda será repetida depois do ajuste. Se falhar de novo, a limitação vai ao `onboarding.md` (T075), sem bloquear o editor.
- **P-05, reprovada:** texto de 24 pt e alvos de 44 pt pequenos a 3 m; contador e erros de clique não informados. `EditorMetrics` passa a texto de 32 pt, títulos de 40 pt, alvo mínimo de 60 pt, janela mínima de 1.400 × 800 pt, espaçamento de 20 pt e margem de 40 pt, acima dos mínimos do RNF de legibilidade; D-19 previa 1.100 × 720 pt. A janela ainda cabe na tela embutida de 900 pt. `EditorProbeView` passa a mostrar os valores das constantes e a quebrar o texto na largura da janela.
- **Estado:** T016 concluída; T015 com os resultados registrados e o primeiro ajuste feito, mantida aberta até o reteste. `./scripts/test.sh` verde com 163 testes; compilação de release sem avisos. O PM-1a segue pendente: reinstalar e repetir P-01, P-03 e P-05.

### Rodada 3, 2026-09-15: PM-1a, reteste

Sessão de log `poc-20260915-093447.jsonl`, com os ajustes da rodada 2 instalados.

- **P-01, inconclusiva:** a primeira abertura pela paleta, com a janela fechada, ainda registrou `editor.activation_failed`; a lista de janelas mostrou o editor atrás do iTerm2 e do VS Code, e o VS Code passou a ser o app em foco, sinal de que o clique de ativação acertou a janela de cima. As duas aberturas seguintes pela paleta, com a janela já aberta, trouxeram-na à frente sem falha, e o usuário relatou que ela passou a vir para a frente. Falta repetir a abertura com a janela fechada; se falhar, adota-se D-23.
- **P-03, causa encontrada:** o usuário constatou que o campo do editor aceita digitação, mas não colagem, e o ditado do Raycast insere o texto colando. O app `.accessory` não tinha menu principal, e sem o menu Editar ⌘V, ⌘C, ⌘X, ⌘A, ⌘Z e ⇧⌘Z não chegam ao campo. `EditMenu.install()`, chamado no `AppDelegate`, instala um menu principal só com "Editar", sem "Sair", para ⌘Q não encerrar o app. A gravação de acorde segue antes dos equivalentes de menu, pelo monitor local.
- **P-05, aprovada:** texto de 32 pt e alvos de 60 pt funcionaram bem a 3 m.
- **Redimensionamento:** depois de redimensionar a janela, nenhum botão respondia. `EditorWindowController` passa a usar rolagem só vertical, e `EditorProbeView` ocupa a largura da janela, em vez de ter largura fixa centralizada. A causa não foi confirmada; o reteste decide.
- **Estado:** `./scripts/test.sh` verde com 163 testes; build de release sem avisos; app reinstalado (sessão `poc-20260915-095548.jsonl`). O PM-1a segue pendente de P-01 com a janela fechada, P-03 e redimensionamento.

### Rodada 4, 2026-09-15: PM-1a, segundo reteste e emenda E002

Sessão de log `poc-20260915-095548.jsonl`.

- **P-01, reprovada:** quatro aberturas pela paleta com a janela fechada, as quatro com `editor.activation_failed`. Conforme o combinado com o usuário, adota-se a alternativa de D-23 (`investigation.md` §3.3) pela emenda E002, sem nova tentativa de ativação direta. O clique de ativação da rodada 2 foi removido: acertava a janela de outro aplicativo e o ativava.
- **E002:** `StatusMenu.arm(_:)` tira o menu do ícone, guarda a ação de abrir o editor e devolve o ponto do ícone na barra de menus da tela do cursor, calculado pela distância à borda direita, igual em cada tela; o clique no ícone armado executa a ação e restaura o menu, que também volta após `armedTimeout` (10 s). `EventInjector.moveCursor(to:)` leva o ponteiro ao ponto. Sem evento novo: `editor.opened` segue com `source: palette`.
- **P-03, aprovada:** com o menu Editar, colar funciona no campo e o ditado do Raycast insere o texto.
- **Redimensionamento, aprovado:** os botões respondem depois de redimensionar a janela.
- **Estado:** `./scripts/test.sh` verde com 163 testes; build de release sem avisos. Falta o reteste de E002 (P-01 pelo ícone armado, com devolução do foco ao fechar, RF-19) e os itens de P-02 ainda não informados (✕ do controle durante a gravação e digitação no Terminal).

### Rodada 5, 2026-09-15: reteste da E002 e emenda E003

Sessão de log `poc-20260915-100331.jsonl`.

- **E002, reprovada:** o ponteiro chegou ao ícone, mas o R1 no ícone armado abriu o editor atrás do terminal (`editor.opened { palette }` seguido de `editor.activation_failed`), e o mesmo ocorreu numa abertura pelo menu. O macOS 26 não trata o clique sintético do controle como interação que autoriza `NSApp.activate()`. As aberturas pelo menu aprovadas na rodada 2 provavelmente usaram o trackpad.
- **P-02, aprovada:** ✕ do controle com a gravação ativa não é gravado, e digitar no Terminal com a gravação desligada não altera o editor.
- **E003:** a E002 foi desfeita no código (`StatusMenu` restaurado, `moveCursor(to:)` removido) e a paleta volta a chamar `show(source: .palette)`. `EditorWindowController.show` põe a janela no nível `.floating` quando o app não está ativo, chama `orderFrontRegardless()` e, 150 ms depois, sem foco, clica no centro da barra de título por `EventInjector.activationClick(at:)`, que devolve o cursor à posição anterior; `editor.activation_failed` é conferido 500 ms após o clique. A janela volta a `.normal` em `didBecomeActiveNotification` e ao fechar.
- **Estado:** `./scripts/test.sh` verde com 163 testes; build de release sem avisos. Falta o reteste de P-01 pela E003, inclusive a devolução do foco ao fechar (RF-19).

### Rodada 6, 2026-09-15: PM-1a aprovado

Sessão de log `poc-20260915-101042.jsonl`.

- **P-01, aprovada pela E003:** quatro aberturas pela paleta com a janela fechada, todas sem `editor.activation_failed`; o usuário confirmou o editor acima do Terminal, com foco e colagem sem clique manual, e o foco devolvido ao Terminal ao fechar (RF-19).
- **Resultado do portão:** P-01 (E003), P-02, P-03 (com `EditMenu`) e P-05 (métricas de 32 pt e 60 pt) aprovadas. T015 e T016 concluídas. P-04 segue para o PM-1b, depois de T060.
- **Próximo passo:** Fase 2, a partir de T017.

### Rodada 7, 2026-09-15: Fases 2 e 3 até o PM-1b

- **Política de escrita:** `allowLegacyEdits: true` com `allowedPaths` vazio, liberação irrestrita.
- **Concluídas:** T017, T018 e T020 a T060, T062 a T074; somadas às rodadas anteriores, 74 de 76 ações. Abertas: T061, que depende de P-04 no PM-1b, e T075, que depende de T061. `./scripts/test.sh` verde com 251 testes (eram 163); compilação de depuração e de release sem avisos.
- **T021 a T025, decodificação:** `Result` exige erro que conforme `Error`, daí o tipo `ShortcutIssues`. A camada sem ações equivale à ausente e não é armazenada. Tecla fora do catálogo é recusada na validação (`unknownKey`), não só na decodificação, para que o rascunho também a acuse. Com uma seção estruturalmente inválida, a validação semântica ainda roda na outra, e a recusa conjunta de RN-08 lista os problemas das duas.
- **T028, linha do problema:** `nearestLine(of:in:)` recua ao ancestral existente quando o caminho do problema aponta para chave ausente, como `palette.items` vazio.
- **T035 a T037, mapeador:** `ShortcutAction` ganha `systemDown` e `systemUp`, e `ShortcutActions` resolve o acorde pelas preferências no pressionar e guarda o acorde pressionado para soltá-lo igual. `lastTrigger` é lido antes de executar a ação e registrado depois, em `shortcut.triggered`.
- **T041, rótulos:** o rótulo de `return` no `KeyCatalog` passa a "Enter", como no restante da interface.
- **T043 a T046, rascunho:** `EditorTarget.palette` localiza os problemas da lista inteira (vazia ou longa demais). Marcar um botão como modificador remove as ações "nenhuma" explícitas dele nas camadas; sem isso, o padrão tornaria L3 modificador inválido por `modifierHasAction`, e a amostra de T074 não seria gravável pelo editor.
- **T054, observação:** além dos diretórios, o descritor do próprio arquivo de destino é observado, porque gravação no lugar (`echo >`) não gera evento no diretório; `.attrib` ficou fora da máscara, para que a própria leitura não provoque releitura. A verificação em hardware é P-04.
- **T056:** a restauração registra `shortcuts.restored` no lugar de `shortcuts.saved`, e não os dois.
- **T057:** motivo novo `palette.closed { reason: identify }`, documentado em `interfaces/diagnostic-log.md` §3.
- **T066:** um modificador que ainda tem ação própria na camada (arquivo editado à mão) mostra "Remover a ação de X nesta camada", única saída do painel para o problema de RF-12.
- **T068:** a reordenação por arrastar usa `onDrag` e `onDrop` sobre as linhas, e não `List` com `onMove`, porque a janela já rola num `ScrollView` e uma `List` aninhada perde a altura; "Mover para cima" e "Mover para baixo" seguem como caminho pelo controle.
- **T071 e T072:** o diálogo de fechamento é uma folha `NSAlert` presa à janela; se Salvar falhar (problemas, cópia de segurança pendente ou erro de gravação), a janela continua aberta com a faixa correspondente. A identificação é desligada ao abrir a folha, ao perder o foco e ao fechar.
- **T073:** `EditorProbeView.swift` ficou sem uso e não foi apagado, porque apagar arquivo pré-existente depende de confirmação do usuário.
- **T074:** amostras geradas pelo próprio `ConfigDocument.merge` a partir do padrão e conferidas pelo `ConfigLoader`: `l3-modifier.json` e `palette-reversa-docs.json` válidas; `r1-in-layer.json` recusada com `pointerButtonNotAllowed` na linha 159; `invalid-line12.json` com erro de sintaxe na linha 12, que invalida o arquivo inteiro, inclusive `pointer`, que volta ao padrão de 1500.
- **Parada no PM-1b:** reinstalar o app e executar P-04 (`onboarding.md` §1); o resultado alimenta T061 e, depois, T075 e o PM-2. Os cenários do editor já podem ser observados, mas o registro formal fica no PM-2.

### Rodada 8, 2026-09-15: PM-1b, P-04

App reinstalado e aberto com `--debug` (sessão `poc-20260915-111003.jsonl`). A pedido do usuário, a sonda foi executada pelo assistente, por *script*, sobre `~/.config/joystick-ai/config.json`, com cópia prévia do arquivo e restauração depois de cada gravação; ao fim, o arquivo voltou idêntico à cópia. As gravações alternaram o arquivo original (só `pointer`, 17 itens padrão) e o mesmo arquivo com a paleta de `palette-reversa-docs.json` (18 itens), com 2,5 s entre elas.

| Gravação | Evento com `trigger: external` | Atraso |
|----------|--------------------------------|--------|
| No lugar, com truncamento, como editor que grava sem renomear; ida e volta | `shortcuts.loaded` com 18 e depois 17 itens | 159 ms |
| `vim` 9.2 com `-u NONE -N` (`backupcopy=auto`, `writebackup`); ida e volta | `shortcuts.loaded` com 18 e depois 17 itens | até 221 ms |
| `echo '{}' >` e restauração | `shortcuts.loaded` (padrão, `section_missing`) duas vezes, uma por mudança de *bytes* | 160 ms |
| `mv` de arquivo de outro diretório por cima; ida e volta | `shortcuts.loaded` com 18 e depois 17 itens | 162 ms |
| Erro de sintaxe na linha 2, no lugar, e restauração | `shortcuts.invalid { line: 2, rule: syntax }`, depois `shortcuts.loaded` | 158 ms |
| Troca do arquivo por *link* simbólico para cópia idêntica em outro diretório | `shortcuts.unchanged` | 161 ms |
| Destino do *link* gravado no lugar, por `mv` e por `vim` | `shortcuts.loaded` a cada gravação | até 280 ms |
| Volta a arquivo comum com o mesmo conteúdo | `shortcuts.unchanged` | 161 ms |

- **Resultado, aprovada:** cada gravação produziu exatamente um evento, sem repetição nem laço de releitura, sempre abaixo de 1 s (RF-03); o atraso é o de 150 ms da releitura mais o tempo de gravação. A observação sobreviveu à troca de *inode* por `mv`, à troca por *link* e à volta a arquivo comum, e o conteúdo inválido manteve a vigente com a linha certa (RF-04).
- **Primeira tentativa com `vim`:** o comando do *script* apagava a primeira linha, e o app registrou `shortcuts.invalid { line: 1 }` para um arquivo de fato inválido; corrigido o comando, os passos foram repetidos com o resultado da tabela.
- **Limites da execução:** não houve gravação pela interface do VS Code, só a gravação no lugar que a imita, nem `vim` com o `vimrc` do usuário; o alerta no ícone da barra de menus não foi observado na tela, só no log. Esses pontos ficam para o PM-2 (passos 5 e 7).
- **T061:** nenhum ajuste no `ConfigWatcher`; eventos observados, atraso de 150 ms e tratamento do *link* mantidos.
- **T075:** `onboarding.md` §1 ganhou os resultados dos dois portões; §2 passou a usar as amostras de T074, com a regra de que uma seção presente substitui o padrão por inteiro, e ganhou a gravação através de *link* simbólico (passo 10) e a revogação da Acessibilidade com L2+← segurado (passo 31), o que renumera os passos a partir do 10. O passo 3 passou a desmarcar L3 antes de marcá-lo, porque a amostra do passo 2 já traz L3 modificador; o passo 26 cobre a gravação pela interface do VS Code e o `vim` com `vimrc`, fora da P-04. Textos da interface, eventos, regras e linhas conferidos contra o código. P-03 não gerou limitação; §3 registra a dependência do menu Editar para colar e ditar.
- **Estado:** 76 de 76 ações concluídas; falta o PM-2, executado pelo usuário conforme `onboarding.md` §2.

### Rodada 9, 2026-09-15: PM-2, parte por *script*

A pedido do usuário, o assistente executou por *script* a parte dos passos que depende só de arquivo e log (sessões `poc-20260915-113108.jsonl` e `poc-20260915-113137.jsonl`), com a configuração guardada em `config.pre-003.json` e restaurada ao fim, idêntica à cópia. Gravações no lugar, a 2,5 s umas das outras. Nada que exija controle, editor ou observação da tela foi verificado.

| Passo | Parte executada | Resultado |
|-------|-----------------|-----------|
| 1 | App encerrado, arquivo movido, app aberto; `mv` desfeito | `shortcuts.loaded { startup, defaults, file_missing }`; arquivo continuou ausente 6 s depois da abertura; desfazer o `mv` gerou `shortcuts.loaded { external }`. ✕, L1+✕, L2+← e PS não verificados |
| 2 | `l3-modifier.json` e △ trocado por Command+Z | `shortcuts.loaded { external, file }` com L3 entre os modificadores, nas duas gravações. Gravação pela interface do VS Code e efeito de △ não verificados |
| 5 | `r1-in-layer.json` | `shortcuts.invalid { rule: pointerButtonNotAllowed, path: shortcuts.layers.l1.r1, line: 159 }`. Alerta no ícone, item do menu e R1 clicando não verificados |
| 6 | `l3-modifier.json` e ○ trocado por Tab | `shortcuts.loaded { external, file }` nas duas gravações. Repetição de □ e efeito de ○ não verificados |
| 7 | `invalid-line12.json` e correção | `shortcuts.invalid { rule: syntax, line: 12 }`; a correção gerou `shortcuts.loaded`. ○ mantido em Tab e alerta não verificados |
| 28 | Busca nos três logs do dia a partir das 11:10 | Nenhuma ocorrência de `CONTINUAR` nem de `reversa-docs`; nenhum nome de tecla, acorde ou atalho de sistema nos eventos `shortcuts.*`, `shortcut.*` e `editor.*`. A parte com `shortcuts.saved` e `shortcut.triggered` depende do editor e do controle |

- **Reabertura:** o app foi reaberto com `--debug` depois da restauração, porque `pointer` só é lido ao abrir; o log confirma `scrollSpeed` 100 do arquivo do usuário, contra 40 do padrão na sessão sem arquivo.
### Rodada 10, 2026-09-15: PM-2 guiado, parte 1

O usuário operou o controle e observou a tela; o assistente preparou os arquivos, inclusive por vigias que gravaram o arquivo 2 s depois de □ pressionado e da paleta aberta, e conferiu o log (sessão `poc-20260915-114349.jsonl`, aberta sem arquivo).

- **Passo 1, aprovado:** sem arquivo, ✕ deu Enter, L1+✕ digitou `CONTINUAR` com Enter, L2+← trocou de mesa e PS abriu a paleta com 17 itens e "Editar atalhos".
- **Passo 2, aprovado:** com `l3-modifier.json` e △ em Command+Z, △ desfez no editor de texto.
- **Passo 4, aprovado:** L1 antes de L2 com ✕ digitou `CONTINUAR`; L2 antes de L1 deu só Enter.
- **Passo 5, aprovado:** com `r1-in-layer.json`, alerta no ícone, "Configuração inválida: linha 159" no menu, faixa do editor com a linha 159, R1 clicando e L1+✕ ainda com `CONTINUAR`.
- **Passo 6, aprovado:** □ pressionado às 11:50:11.6, arquivo gravado às 11:50:13.7 e `shortcuts.loaded` às 11:50:13.9 com □ ainda segurado; o apagamento parou, nenhuma tecla ficou presa e ○ passou a Tab.
- **Passo 7, aprovado:** com `invalid-line12.json`, ○ seguiu em Tab, alerta e "Configuração inválida: linha 12" no menu; com arquivo válido, o alerta sumiu e ○ voltou a Esc.
- **Passo 30, aprovado:** paleta aberta às 11:53:20.3, arquivo gravado às 11:53:22.5, `palette.closed { reason: config_changed }`; ao reabrir, `/reversa-docs` no topo.
- **Passos 12, 13, 25, 27 e abertura pelo ícone (11, primeira parte), aprovados:** editor aberto pela paleta acima do Terminal, ponteiro de volta ao lugar e nada digitado; figura com □ à esquerda do grupo de ação e L1 acima de L2; camada L2 com "mesa à esquerda", "Enter (herdado)" e "clique esquerdo, fixo"; fechar devolveu o foco ao Terminal; "Editar atalhos" no ícone abriu o editor à frente.
- **Passo 3, em parte:** L3 marcado, L3+○ em Mission Control salvo (`shortcuts.saved`, `shortcuts.loaded { editor }`) e o usuário marcou B2 como feito. A gravação com L3 desmarcado não apareceu no log; o fluxo de desmarcar com confirmação e salvar será repetido.
- **Passo 18, aprovado:** L3 com Control mantido, gravado no arquivo (`modifiers.l3: ["control"]`); L3+← trocou de mesa.
- **Passo 19, aprovado:** ✕ marcado como modificador desabilitou "Salvar" com destaque e mensagem; o mesmo ocorreu com R3, marcado por engano, com "1 problema impede salvar" e o botão "Remover a ação de R3 nesta camada".
- **Achado:** marcar um botão como modificador remove as ações "nenhuma" dele nas camadas (decisão de T045), mas desmarcá-lo não as devolve. No arquivo salvo, `layers.options.r3` sumiu, e Options+R3 passou a herdar ⌘M. Correção proposta depois do PM-2: `unsetModifier` restaurar as "nenhuma" da base do rascunho, ou `setModifier` deixar de removê-las até a gravação.
- **Passo 3, concluído:** desmarcar L3 com confirmação e salvar gravou o arquivo sem `modifiers.l3` nem `layers.l3`; L3+○ passou a Esc. Aprovado com a parte anterior.
- **Passos 14 a 17, aprovados:** ⌘Z gravado pelo teclado em L1+○ e salvo, desfazendo; com a gravação ativa, ✕ do controle não foi gravado e ⇧⌘Z foi; ⌘Tab montado sem teclado em L1+↓, salvo e executado; digitação no Terminal com a gravação desligada não alterou o editor, e o log não tem nomes de tecla nem acordes.
- **Observação:** ao escolher "Acorde" para L1+↓, o editor partiu da ação herdada (↓ com repetição) e manteve `repeat: true` no ⌘Tab gravado. Segurar L1+↓ repete Command+Tab. Não viola requisito, mas convém partir de `repeat: false` quando a ação de origem é herdada ou de outro botão.
- **Passo 24, aprovado:** com "Identificar pelo controle", △ e ✕ selecionaram o cartão sem Tab nem Enter, R1 clicou normalmente e trocar para o Terminal desligou o modo; log com `editor.identify` ligado e desligado.
- **Passo 20, aprovado:** fechar com ✕ em "nenhuma" abriu a folha; Cancelar manteve a janela e a alteração; Descartar fechou com `editor.closed { outcome: discarded }`, e a reabertura mostrou Enter.
- **Passo 23, aprovado:** Cancelar não mudou nada; "Restaurar e gravar" registrou `shortcuts.restored` e `shortcuts.loaded { trigger: restore }`, e L1+○ e L1+↓ voltaram a herdados; `pointer` preservado no arquivo.
- **Passo 21, aprovado:** `/reversa-docs` incluído no topo com Enter e salvo; a paleta abriu com ele no topo e "Editar atalhos" no fim, e a confirmação digitou o comando com Enter; a seção `palette` gravada é igual à de `palette-reversa-docs.json`.
- **Passo 28, aprovado:** depois de confirmar `/reversa-docs` e acionar L1+✕, o log tem `shortcuts.saved`, `palette.confirmed` e `shortcut.triggered { button: cross, layer: l1, type: text }`, e `grep -c -e CONTINUAR -e reversa-docs` dá 0.
- **Passo 22, aprovado:** com paleta de 1 item gravada por fora, a lixeira mostrou "A paleta precisa de ao menos um item."; colar texto de duas linhas mostrou "O texto deve ter uma única linha."; com 50 itens, "Incluir no fim" mostrou "A paleta aceita no máximo 50 itens.".
- **Passo 26, aprovado:** com rascunho sujo, a gravação pela interface do VS Code abriu a faixa de conflito (`editor.conflict { pending }`); "Recarregar do arquivo" adotou o arquivo (`reload`) e "Manter minhas alterações" preservou o rascunho (`keep`), sem sobrescrever nada. Cada gravação do VS Code gerou um `shortcuts.loaded { external }`. O usuário não tem `~/.vimrc`, então o `vim` com configuração própria equivale ao já testado na P-04.
- **Passo 8, aprovado:** partindo do arquivo só com `pointer`, salvar pelo editor gravou `shortcuts` e `palette` e manteve `pointer` com `scrollSpeed` 100.
- **Passo 9, aprovado:** com a pasta sem escrita, a faixa mostrou "Não foi possível gravar." com o caminho e "Permission denied" (`shortcuts.save_failed`); o rascunho ficou; devolvida a permissão, salvar gravou.
- **Passo 10, aprovado:** com `config.json` como *link* para cópia em outro diretório, salvar gravou no destino, o *link* continuou *link*, `pointer` ficou intacto e a observação registrou só `shortcuts.unchanged { external }`. Ao fim, o *link* foi trocado por arquivo comum idêntico a `config.pre-003.json`.
- **Passo 11, aprovado:** "Sair" com □ segurado encerrou o app (`app.terminating { reason: quit }`) sem apagamento contínuo depois.
- **Passo 31, aprovado com ressalva:** revogar a Acessibilidade gerou `pointer.injection_suspended` e, ao devolver, `pointer.injection_resumed`; ← no teclado físico moveu o cursor sem trocar de mesa, logo Control não ficou preso. O log mostra, porém, L2 solto às 13:06:02.7 e a suspensão detectada às 13:06:04.0: a soltura das teclas no instante da suspensão não chegou a ser exercitada. Como a verificação é por consulta a cada 2 s, o caso só se repete com o botão segurado até a retomada.
- **Passo 29, aprovado:** o usuário julgou o texto legível e os alvos fáceis de acertar durante os testes.
- **Resultado do PM-2:** aprovado, com a ressalva do passo 31. App reaberto com `--debug` e configuração original.
- **Achados para correção:** (1) desmarcar um modificador não devolve as ações "nenhuma" removidas ao marcá-lo, e Options+R3 passou a herdar ⌘M depois de marcar e desmarcar R3; (2) trocar a ação herdada de um botão com repetição para "Acorde" preserva `repeat: true`, e L1+↓ em ⌘Tab passou a repetir.

### Rodada 11, 2026-09-15: correção dos achados do PM-2

- **E004:** `EditorDraft` guarda, por modificador marcado, as camadas de onde a marcação tirou a "nenhuma" explícita e a devolve ao desmarcar, desde que a camada ainda seja a base ou de um modificador e o botão não tenha ganho outra ação; a memória só sobrevive a `rebase` e `restoreDefaults` para botões que continuam modificadores. Marcar e desmarcar R3 ou L3 no padrão deixa o rascunho limpo. A regra RN-04 e a validação não mudaram.
- **E005:** em `ActionPanel`, escolher "Acorde" sobre ação vigente que já é acorde (herdada) aproveita o acorde sem repetição.
- **`EditorProbeView.swift`:** apagado com confirmação do usuário.
- **Estado:** `./scripts/test.sh` verde com 253 testes (dois novos em `EditorDraftTests`); compilação de depuração e de release sem avisos; app reinstalado e aberto com `--debug`. E005 fica sem teste automatizado, por estar na camada SwiftUI; a verificação é repetir o passo 16 do PM-2 e conferir "Repetir enquanto segurado" desligado.

## Histórico de alterações

| Data | Alteração | Autor |
|------|-----------|-------|
| 2026-09-14 | Versão inicial gerada por `/reversa-to-do` | reversa |
| 2026-09-14 | Revisão pós-auditoria (`audit/cross-check.md`): A001 em T035 e T038; A002 em T033, T034 e T055; A003 e A004 em T055, T062 e T063; A005 com a nova T076 e T075 reescrita. IDs existentes mantidos | reversa |
| 2026-09-14 | Rodada 1 do `/reversa-coding`: T001 a T014, T019 e T076 concluídas; parada no PM-1a | reversa |
| 2026-09-15 | Rodada 2: resultados da primeira execução do PM-1a, ajuste de ativação do editor, métricas de TV maiores e T016 concluída; PM-1a pendente de reteste | reversa |
| 2026-09-15 | Rodada 3: reteste do PM-1a, P-05 aprovada, menu Editar para colagem e ditado, rolagem só vertical | reversa |
| 2026-09-15 | Rodada 4: P-01 reprovada, emenda E002 (editor aberto pela paleta por meio do ícone armado), P-03 e redimensionamento aprovados | reversa |
| 2026-09-15 | Rodada 5: E002 reprovada e revogada, P-02 aprovada, emenda E003 (janela flutuante com clique de ativação) | reversa |
| 2026-09-15 | Rodada 6: PM-1a aprovado; T015 concluída | reversa |
| 2026-09-15 | Rodada 7: T017, T018, T020 a T060 e T062 a T074 concluídas (74 de 76); parada no PM-1b | reversa |
| 2026-09-15 | Rodada 8: P-04 aprovada no PM-1b; T061 e T075 concluídas (76 de 76); PM-2 pendente | reversa |
| 2026-09-15 | Rodadas 9 e 10: PM-2 executado com o usuário, aprovado com ressalva no passo 31 e dois achados do editor | reversa |
| 2026-09-15 | Rodada 11: emendas E004 e E005 corrigem os achados do PM-2; `EditorProbeView.swift` apagado | reversa |

## Emendas

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| E002 | Revogada pela E003. A paleta arma o ícone da barra de menus e leva o ponteiro até ele; o clique no ícone abre o editor em primeiro plano, e o clique de ativação automático é removido | PM-1a | - | `Sources/JoystickAIPoC/App/StatusMenu.swift` | 🟡 | `[X]` |
| E003 | Editor aberto no nível flutuante com clique de ativação na barra de título; volta ao nível normal ao ativar ou fechar; desfaz a E002 | E002 | - | `Sources/JoystickAIPoC/Editor/EditorWindowController.swift` | 🟡 | `[X]` |
| E004 | Desmarcar modificador devolve a "nenhuma" que a marcação tirou das camadas (achado do PM-2) | PM-2 | - | `Sources/JoystickCore/Config/EditorDraft.swift` | 🟢 | `[X]` |
| E005 | Acorde aproveitado da ação herdada começa sem repetição (achado do PM-2) | PM-2 | `[//]` | `Sources/JoystickAIPoC/Editor/ActionPanel.swift` | 🟡 | `[X]` |
