# Actions: Paleta de comandos pelo controle

> Identificador: `002-paleta-comandos`
> Data: `2026-09-14`
> Roadmap: `_reversa_forward/002-paleta-comandos/roadmap.md`

## Resumo

| Métrica | Valor |
|---------|-------|
| Total de ações | 22 |
| Paralelizáveis (`[//]`) | 12 |
| Maior cadeia de dependência | 9 (T002 → T008 → T009 → T015 → T016 → T017 → T019 → T020 → PM-1 → T021) |

## Convenções desta decomposição

### Portões manuais

Passagens que dependem de ato humano não recebem ID `T`; aparecem como `PM-n` na coluna de dependências. O `/reversa-coding` deve parar ao alcançar um portão e só seguir quando o usuário confirmar o resultado.

| Portão | Ato do usuário | Requer | Referência | Libera |
|--------|----------------|--------|------------|--------|
| PM-0 | Liberar a escrita fora das pastas do Reversa em `.reversa/reversa-config.json`. **Já cumprido:** `allowLegacyEdits: true` com `allowedPaths` vazio (liberação irrestrita), a reler na ativação do `/reversa-coding`. | - | `CLAUDE.md`, roadmap §2 | T001 a T020, T022 |
| PM-1 | Compilar e instalar; executar as sondas P-01 (intervalo do Enter com `--palette-enter-delay-ms` 0, 50 e 150, no Terminal e no VS Code) e P-02 (painel sobre tela cheia e outra mesa, sem roubar o foco); informar o menor intervalo que funcionou. | T001 a T020, T022 | D-06, D-08, `onboarding.md` §1 | T021 |
| PM-2 | Roteiro completo do `onboarding.md` §2 (18 passos), no Terminal e no terminal integrado do VS Code, com resultados anotados nas notas de execução. | Todas as ações `T` | roadmap §10, `onboarding.md` §2 | Critério de pronto |

A maior cadeia conta apenas ações `T`; o portão atravessado aparece na sequência para indicar onde ela para.

### Ajuste de ordem em relação ao roadmap §8

O roadmap previa as sondas P-01 e P-02 antes do código, com um utilitário descartável. A decomposição as move para o PM-1, executadas com o próprio app, por dois motivos: um utilitário à parte exigiria conceder Acessibilidade também ao Terminal, e o argumento `--palette-enter-delay-ms` (T003) já permite testar os três intervalos sem recompilar. O risco de deixar a sonda para depois é baixo: um resultado ruim muda só o valor padrão de D-06 (T021), não a arquitetura. Se nenhum intervalo até 500 ms funcionar, a regra do roadmap continua valendo: parar e voltar ao `/reversa-clarify`. T022 adapta o `onboarding.md` §1 a esse ajuste.

### Correspondência com as fases do roadmap

| Fase do roadmap | Ações |
|-----------------|-------|
| 0, sondas | PM-1 (ajuste acima), T021, T022 |
| 1, núcleo | T001 a T012 |
| 2, integração | T013 a T020 |
| Portão manual | PM-2 |

### Arquivos compartilhados

`Sources/JoystickCore/Palette/CommandPalette.swift` recebe T002, T008 e T009; `Tests/JoystickCoreTests/CommandPaletteTests.swift` recebe T005 e T010; `Sources/JoystickAIPoC/Palette/PaletteActions.swift` recebe T015, T016 e T021; `Sources/JoystickAIPoC/App/AppDelegate.swift` recebe T019 e T020. Essas ações são sequenciais. O pacote deve compilar e `./scripts/test.sh` deve passar ao fim de cada ação.

## Fase 1, Preparação

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T001 | Criar `KeyRepeat` com `delay` de 400 ms e `interval` de 50 ms, como `DispatchTimeInterval` ou em milissegundos com conversão, documentado com `action-mapping` RF-10 (D-07) | - | `[//]` | `Sources/JoystickCore/Shortcuts/KeyRepeat.swift` | 🟢 | `[X]` |
| T002 | Criar `PaletteItem { text, pressEnter }` (`Equatable`, `Sendable`), `CommandPalette.items` com os 17 itens na ordem de `requirements.md` §4, `PaletteDirection` (`up`, `down`) e `PaletteCloseReason` (`circle`, `ps`, `disconnected`, `injection_suspended`, `idle`, com `rawValue` do log) | - | `[//]` | `Sources/JoystickCore/Palette/CommandPalette.swift` | 🟢 | `[X]` |
| T003 | Acrescentar a `LaunchArguments` o campo `paletteEnterDelayMs: Int?`, o caso `--palette-enter-delay-ms` com faixa de 0 a 500 e `LaunchArgumentError.invalidPaletteEnterDelay(String)` com a mensagem de `interfaces/launch-arguments.md` §2 | - | `[//]` | `Sources/JoystickCore/App/LaunchArguments.swift` | 🟢 | `[X]` |
| T004 | Acrescentar a `LogEventCatalog` os eventos `paletteOpened(selection:)`, `paletteConfirmed(index:enter:)`, `paletteClosed(reason:)`, `paletteBlocked()` e `paletteInvalidArgs(message:)`, com nomes, níveis e campos de `interfaces/diagnostic-log.md` §2 e `launch-arguments.md` §2, sem texto de item (D-14) | T002 | - | `Sources/JoystickCore/Log/LogEventCatalog.swift` | 🟢 | `[X]` |

## Fase 2, Testes

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T005 | Criar `CommandPaletteTests` para a lista: 17 itens na ordem definida, primeiro `CONTINUAR` e último `/resume`, todos com uma linha e de 1 a 1.000 caracteres, `pressEnter` falso exatamente nos três itens terminados em espaço (RN-05, RF-05) | T002 | `[//]` | `Tests/JoystickCoreTests/CommandPaletteTests.swift` | 🟢 | `[X]` |
| T006 | Acrescentar a `LaunchArgumentsTests` os casos de `--palette-enter-delay-ms`: 0, 120 e 500 aceitos; -1, 501, `abc` e ausência de valor rejeitados com o erro correspondente e campo `nil` | T003 | `[//]` | `Tests/JoystickCoreTests/LaunchArgumentsTests.swift` | 🟢 | `[X]` |
| T007 | Acrescentar os eventos `palette.*` a `sampleEvents` de `LogEventCatalogTests` e um teste de que nenhum deles contém campo com texto de item (chaves `text`, `label` ou valor igual a algum `PaletteItem.text`) | T004 | `[//]` | `Tests/JoystickCoreTests/LogEventCatalogTests.swift` | 🟢 | `[X]` |

## Fase 3, Núcleo

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T008 | Criar `PaletteMachine` (`Sendable`) com `isOpen`, `selection`, `lastConfirmed`, `repeating`, `PaletteSnapshot` e `PaletteEffect`; implementar `open()` (seleção em `lastConfirmed ?? 0`), `press` e `release` de ↑ e ↓ com seleção circular e efeitos `startRepeat`/`stopRepeat`, e `repeatTick()`, conforme `data-delta.md` §4 (D-01) | T002 | - | `Sources/JoystickCore/Palette/CommandPalette.swift` | 🟢 | `[X]` |
| T009 | Completar `PaletteMachine`: `press(.cross)` fecha com `confirm(index 1-based, item)` e grava `lastConfirmed`; `press(.circle)` e `press(.ps)` fecham com `closed`; `close(reason)` externo; `stopRepeat` antes de fechar com repetição ativa; demais botões e qualquer entrada com a paleta fechada sem efeito | T008 | - | `Sources/JoystickCore/Palette/CommandPalette.swift` | 🟢 | `[X]` |
| T010 | Acrescentar a `CommandPaletteTests` as transições da máquina: abertura na primeira e na última confirmada; ↑ no primeiro vai ao 17.º e ↓ no último ao primeiro; `repeatTick` só com repetição ativa; confirmação, fechamento por ○, PS e motivos externos; outros botões ignorados; invariante `0 ≤ selection < 17`; nenhum efeito com a paleta fechada | T005, T009 | - | `Tests/JoystickCoreTests/CommandPaletteTests.swift` | 🟢 | `[X]` |
| T011 | Acrescentar `ShortcutAction.openPalette` e fazer `ShortcutMapper.press(.ps)` devolver `[.openPalette]` na camada base, sem registrar acorde; atualizar o comentário do tipo (D-02) | - | `[//]` | `Sources/JoystickCore/Shortcuts/ShortcutMapper.swift` | 🟢 | `[X]` |
| T012 | Atualizar `ShortcutMapperTests`: retirar `.ps` de `botoesDoPonteiroNaoGeramTeclas`; testar PS sozinho, com L1 e com L2 segurados devolvendo `[.openPalette]`, com Options segurado devolvendo `[]`, e soltura de PS sem ações (RN-01) | T011 | - | `Tests/JoystickCoreTests/ShortcutMapperTests.swift` | 🟢 | `[X]` |

## Fase 4, Integração

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T013 | Em `ShortcutActions`, trocar as constantes locais de repetição por `KeyRepeat` e tratar `.openPalette` chamando `releaseAll()` e depois o fechamento `onOpenPalette` (definido pela integração), tudo na fila `input` (D-04, D-07) | T001, T011 | - | `Sources/JoystickAIPoC/Pointer/ShortcutActions.swift` | 🟢 | `[X]` |
| T014 | Criar `PalettePanel: NSPanel` (D-08) e `PaletteView: NSView` (D-09): painel sem borda, não ativador, sem `key`, ignorando mouse, `.statusBar`, `collectionBehavior` de D-08; `show(snapshot:)` posiciona no centro da `visibleFrame` da tela do cursor (D-10) e `hide()`; lista com texto de 26 pt monoespaçado, linha de 40 pt, faixa de destaque e marcador "▶", rolando para manter a seleção visível quando a tela não comportar as 17 linhas; só main thread | T002 | `[//]` | `Sources/JoystickAIPoC/Palette/PalettePanel.swift` | 🟡 | `[X]` |
| T015 | Criar `PaletteActions` na fila `input`: guarda `PaletteMachine`, expõe `isOpen`, `open()`, `handle(_ event:)` e `close(_ reason:)`; executa os efeitos: `render` publica `PaletteSnapshot` ao painel por `DispatchQueue.main.async` (D-11); `startRepeat`/`stopRepeat` com `DispatchSourceTimer` e `KeyRepeat`; `confirm` registra `palette.confirmed`, chama `keyboard.type(text, pressEnter: false)` e agenda Return após `enterDelayMs` se o item tiver Enter (D-06); `closed` registra `palette.closed`; `open` registra `palette.opened` | T001, T004, T009, T014 | - | `Sources/JoystickAIPoC/Palette/PaletteActions.swift` | 🟡 | `[X]` |
| T016 | Completar `PaletteActions`: `noteActivity()` grava `lastInputNs`; temporizador de 1 s ativo só com a paleta aberta fecha com `.idle` após 60 s sem atividade; propriedade `blocked` que, verdadeira, faz `open()` registrar `palette.blocked` sem abrir (D-12, D-13) | T015 | - | `Sources/JoystickAIPoC/Palette/PaletteActions.swift` | 🟢 | `[X]` |
| T017 | Em `InputRouter`, receber `PaletteActions`; em botões, enviar sempre a `ButtonActions` e, com a paleta aberta, a `PaletteActions` em vez de `ShortcutActions`; chamar `noteActivity()` em botões, eixos e toque; em `controllerDisconnected`, fechar a paleta com `.disconnected` antes de repassar aos demais (D-03, D-12) | T016 | `[//]` | `Sources/JoystickAIPoC/Pointer/InputRouter.swift` | 🟢 | `[X]` |
| T018 | Em `InjectionGate`, receber `PaletteActions` e, na suspensão, fechar a paleta com `.injectionSuspended` antes de soltar teclas e botões, na fila `input` (D-12) | T015 | `[//]` | `Sources/JoystickAIPoC/App/InjectionGate.swift` | 🟢 | `[X]` |
| T019 | No `AppDelegate`, criar um único `KeyboardInjector` e passá-lo a `ShortcutActions` e `PaletteActions` (D-05); criar `PalettePanel` oculto no início; criar `PaletteActions` com `enterDelayMs = arguments.paletteEnterDelayMs ?? PaletteActions.defaultEnterDelayMs` e registrar `palette.invalid_args` para o erro de T003; ligar `shortcutActions.onOpenPalette` a `paletteActions.open()`; passar a paleta a `InputRouter` e `InjectionGate` | T003, T013, T017, T018 | - | `Sources/JoystickAIPoC/App/AppDelegate.swift` | 🟢 | `[X]` |
| T020 | Em `AppDelegate.openTargets`, pôr `paletteActions.blocked = true` na fila `input` ao iniciar a sessão da tela de alvos e voltar a `false` em `session.onFinish` (D-13) | T019 | - | `Sources/JoystickAIPoC/App/AppDelegate.swift` | 🟢 | `[X]` |

## Fase 5, Polimento

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T021 | Fixar `PaletteActions.defaultEnterDelayMs` no menor intervalo aprovado no PM-1 e registrar nas notas de execução os resultados de P-01 e P-02 | PM-1 | `[//]` | `Sources/JoystickAIPoC/Palette/PaletteActions.swift` | 🔴 | `[ ]` |
| T022 | Adaptar o `onboarding.md` §1 ao ajuste de ordem: P-01 com o app aberto por `--palette-enter-delay-ms` 0, 50 e 150 e P-02 com o painel real, sem utilitário descartável; conferir que nomes de arquivos, argumentos e eventos citados no §2 batem com o código | T020 | `[//]` | `_reversa_forward/002-paleta-comandos/onboarding.md` | 🟢 | `[X]` |

## Notas de execução

### Rodada 1, 2026-09-14

- **Política de escrita:** relida na ativação; `allowLegacyEdits: true` com `allowedPaths` vazio, liberação irrestrita.
- **Concluídas:** T001 a T020 e T022, 21 de 22 ações. `./scripts/test.sh` verde com 157 testes (eram 140) e compilação de release sem avisos. Resta T021, que depende do PM-1.
- **Parada no PM-1:** o app instalado estava aberto com `--debug` durante a rodada; a instalação (`scripts/build-app.sh`) ficou para o usuário, porque encerra a instância aberta.
- **T013 antecipada para a Fase 2:** o alvo `JoystickAIPoC` só voltava a compilar com o `switch` de `ShortcutActions` tratando `.openPalette`, e `scripts/test.sh` compila o pacote inteiro.
- **T003, erro fora de `targets.invalid_args`:** `LaunchArgumentError.concernsPalette` separa os erros da paleta, registrados ao iniciar como `palette.invalid_args`; `openTargets` os ignora.
- **T014, sufixo " …":** itens sem Enter ao final aparecem com " …" no lugar do espaço final, para indicar que esperam complemento; o texto digitado não muda.
- **T015, Enter imediato:** com `enterDelayMs` 0, o Return é postado na mesma passada da fila `input`, igual ao `CONTINUAR` de L1+✕; acima de 0, por `asyncAfter` na fila `input`.
- **Nomenclatura dos portões:** o roadmap §8 chama de "PM-1" o roteiro completo; nesta decomposição, PM-1 são as sondas e PM-2 o roteiro. O `onboarding.md` segue a decomposição.
- **Limitação aceita (D-04):** um modificador pressionado com a paleta aberta e ainda segurado após o fechamento não ativa a camada até ser pressionado de novo.

## Histórico de alterações

| Data | Alteração | Autor |
|------|-----------|-------|
| 2026-09-14 | Versão inicial gerada por `/reversa-to-do` | reversa |
| 2026-09-14 | Rodada 1 do `/reversa-coding`: T001 a T020 e T022 concluídas; parada no PM-1 | reversa |
