# Actions: Atalhos de zoom montados pelo controle

> Identificador: `005-sinais-matematicos`
> Data: `2026-09-16`
> Roadmap: `_reversa_forward/005-sinais-matematicos/roadmap.md`

## Resumo

| Métrica | Valor |
|---------|-------|
| Total de ações | 11 |
| Paralelizáveis (`[//]`) | 4 |
| Maior cadeia de dependência | 8 (T001 → T002 → T003 → T004 → T005 → T006 → T010 → T011) |

## Convenções desta decomposição

### Portões manuais

Passagens que dependem de ato humano não recebem ID `T`; aparecem como `PM-n` na coluna de dependências. O `/reversa-coding` deve parar ao alcançar um portão e só seguir quando o usuário confirmar o resultado.

| Portão | Ato do usuário | Requer | Referência | Libera |
|--------|----------------|--------|------------|--------|
| PM-0 | Liberar a escrita fora das pastas do Reversa em `.reversa/reversa-config.json`. **Já cumprido:** `allowLegacyEdits: true` com `allowedPaths` vazio (liberação irrestrita), a reler na ativação do `/reversa-coding`. | - | `CLAUDE.md`, roadmap §2 | Todas as ações `T` |
| PM-1 | Compilar e instalar (`scripts/build-app.sh`) e executar o roteiro do `onboarding.md` §2 (11 passos) na TV a 3 m, com a sonda P-01 no VS Code e no iTerm, anotando os resultados nas notas de execução. | T001 a T010 | D-07, `onboarding.md` §2 | T011 e o critério de pronto |

A maior cadeia conta apenas ações `T`.

### Correspondência com o roadmap

| Decisões do roadmap | Ações |
|---------------------|-------|
| D-01 (escolha composta fora do catálogo) | T001, T002 |
| D-02 (exibição "⌘+") | T004 |
| D-03 (`KeyChoice`, `applied`, `isSelected`, `choices(in:)`) | T003 |
| D-04 (grade do `ChordEditor`) | T009 |
| D-05 (nada muda em arquivo, validação, captura e injeção) | nenhuma ação; conferido por T010 e PM-1, passos 7 a 9 |
| D-06 (testes) | T005, T006, T007, T008 |
| D-07 (portão e sonda P-01) | PM-1, T011 |

### Arquivos compartilhados e blocos de compilação

Ações que tocam o mesmo arquivo são sequenciais: `KeyCatalog.swift` (T002, T003, T004) e `KeyCatalogTests.swift` (T005, T006). O pacote deve compilar (`swift build`) ao fim de cada ação, e `./scripts/test.sh` deve passar ao fim de cada ação de teste.

### Fase 2 sem ações próprias

O projeto escreve os testes junto do núcleo, depois da API que exercitam, para que cada ação termine compilando. Por isso os testes de D-06 estão na Fase 3, logo após as ações que cobrem.

### Acréscimos da decomposição

- **Comentários de cabeçalho.** Como nas features anteriores, os tipos novos abrem com um comentário de documentação que cita `005-sinais-matematicos` e a decisão que implementam.
- **Reserva condicional.** Se a P-01 falhar no iTerm, o `/reversa-coding` registra o resultado nas notas e sugere `/reversa-add` para a emenda prevista no roadmap §9; nenhuma ação `T` é reservada para isso.

## Fase 1, Preparação

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T001 | Acrescentar a `KeyChord` a constante `public static let equal: UInt16 = 0x18`, junto das demais teclas nomeadas (D-01) | - | - | `Sources/JoystickCore/Shortcuts/ShortcutMapper.swift` | 🟢 | `[X]` |

## Fase 2, Testes

Sem ações nesta fase; ver "Fase 2 sem ações próprias".

## Fase 3, Núcleo

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T002 | Criar `public struct ComposedKey: Equatable, Sendable` com `name`, `display`, `keyCode`, `modifier`, `group`, `after` e `matches(_ chord:) -> Bool`, e `KeyCatalog.composedKeys` com o único item `plus` (`+`, `KeyChord.equal`, `.shift`, `.punctuation`, depois de `minus`), fora de `entries`, `byName` e `byKeyCode` (D-01, `data-delta.md` §2 e §3) | T001 | - | `Sources/JoystickCore/Shortcuts/KeyCatalog.swift` | 🟢 | `[X]` |
| T003 | Criar `public enum KeyChoice: Equatable, Sendable` (`key(KeyEntry)`, `composed(ComposedKey)`) com `id`, `display`, `isSelected(in:)` e `applied(to:)` conforme a tabela de `data-delta.md` §3, e `KeyCatalog.choices(in group:) -> [KeyChoice]`, que insere cada composta logo após a entrada nomeada em `after` (D-03) | T002 | - | `Sources/JoystickCore/Shortcuts/KeyCatalog.swift` | 🟢 | `[X]` |
| T004 | Alterar `KeyCatalog.display(_:)` para, quando alguma composta casar o acorde, devolver `symbols(modifiers − [composta.modifier]) + composta.display`; nos demais casos, manter a regra atual (D-02) | T003 | - | `Sources/JoystickCore/Shortcuts/KeyCatalog.swift` | 🟢 | `[X]` |
| T005 | Em `KeyCatalogTests`, testar a exibição: ⇧⌘= → "⌘+", ⌥⇧⌘= → "⌥⌘+", ⌘= → "⌘=", ⌘- → "⌘-", ⇧= → "+"; e afirmar que `entries.count` segue 73 e que `entry(named: "plus")` é `nil` (D-06, RF-03, RF-06) | T004 | `[//]` | `Tests/JoystickCoreTests/KeyCatalogTests.swift` | 🟢 | `[X]` |
| T006 | Em `KeyCatalogTests`, testar `choices(in: .punctuation)` começando por `-`, `+`, `=`; nenhuma composta nos outros grupos; e `applied` e `isSelected` nas cinco linhas da tabela de `data-delta.md` §3 (D-06, RF-01, RF-02) | T005 | - | `Tests/JoystickCoreTests/KeyCatalogTests.swift` | 🟢 | `[X]` |
| T007 | Em `ActionSummaryTests`, testar que a ação `.chord(KeyChord(KeyChord.equal, [.command, .shift]), repeats: false)` resume "⌘+" e que ⌘- resume "⌘-" (D-06, RF-03) | T004 | `[//]` | `Tests/JoystickCoreTests/ActionSummaryTests.swift` | 🟢 | `[X]` |
| T008 | Em `LogEventCatalogTests.eventosDeAtalhosSemTextoTeclaNemAcorde`, incluir no conjunto de segredos o `name` e o `display` de cada item de `KeyCatalog.composedKeys` (D-06, RN-06) | T002 | `[//]` | `Tests/JoystickCoreTests/LogEventCatalogTests.swift` | 🟢 | `[X]` |

## Fase 4, Integração

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T009 | Em `ChordEditor`, trocar a grade de `ForEach(KeyCatalog.entries(in: group), id: \.name)` por `ForEach(KeyCatalog.choices(in: group), id: \.id)`, com rótulo `choice.display`, ação `onChange(choice.applied(to: chord))` e destaque `choice.isSelected(in: chord)`, mantendo `TVButtonStyle` e `FlowLayout`; atualizar o comentário de cabeçalho citando `005-sinais-matematicos` D-04 (RF-01, RF-02, RF-05) | T003, T004 | `[//]` | `Sources/JoystickAIPoC/Editor/ChordEditor.swift` | 🟢 | `[X]` |

## Fase 5, Polimento

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T010 | Rodar `swift build -c release` e `./scripts/test.sh`, confirmar ambos verdes e registrar nas notas de execução a contagem de testes (270 antes da feature) e a lista de arquivos alterados, que deve se limitar aos alvos de T001 a T009 (D-05) | T006, T007, T008, T009 | - | `_reversa_forward/005-sinais-matematicos/actions.md` | 🟢 | `[X]` |
| T011 | Atualizar `onboarding.md` com os textos e a ordem da grade do código entregue e com o resultado de cada passo do PM-1, destacando a sonda P-01 no VS Code e no iTerm (D-07) | T010, PM-1 | - | `_reversa_forward/005-sinais-matematicos/onboarding.md` | 🟡 | `[X]` |

## Notas de execução

### Rodada de 2026-09-16 (`/reversa-coding`)

- **Política de edição:** `allowLegacyEdits: true` com `allowedPaths` vazio, liberação irrestrita (PM-0 cumprido).
- **T001:** a constante foi escrita em decimal, `public static let equal: UInt16 = 24` (igual a `0x18`), e posta antes de `returnKey`, porque as demais constantes de `KeyChord` são decimais e ordenadas pelo código.
- **T002:** além do pedido, a entrada `equal` de `KeyCatalog.punctuation` passou a usar `KeyChord.equal` em vez do literal `0x18`, como já faz `grave`. Nome, código, rótulo e grupo não mudam.
- **T003:** a busca da composta que casa um acorde ficou em `KeyCatalog.composedKey(matching:)`, de visibilidade interna ao módulo, usada por `KeyChoice` e por `display`.
- **T005 e T006:** testes `exibicaoDoSinalDeSoma`, `escolhasDaGrade` e `aplicacaoESelecaoDasEscolhas`. O último percorre as cinco linhas de `data-delta.md` §3 conferindo resultado, exibição e destaque de `+` e `=`, e ainda confirma que `-` fica destacado em ⌘- e `Z` em ⇧⌘Z.
- **T007:** teste `acordesDeZoom` em `ActionSummaryTests`, com ⌘+ em L1 + ↑ e ⌘- em L1 + ↓.
- **T010:** `swift build -c release` verde; `./scripts/test.sh` com **274 testes em 31 suítes, todos verdes** (270 antes da feature, mais 4). Arquivos de projeto alterados, todos alvos de T001 a T009: `Sources/JoystickCore/Shortcuts/ShortcutMapper.swift`, `Sources/JoystickCore/Shortcuts/KeyCatalog.swift`, `Sources/JoystickAIPoC/Editor/ChordEditor.swift`, `Tests/JoystickCoreTests/KeyCatalogTests.swift`, `Tests/JoystickCoreTests/ActionSummaryTests.swift`, `Tests/JoystickCoreTests/LogEventCatalogTests.swift`. Nada mudou em `ConfigDocument`, `ShortcutConfigValidation`, `KeyCaptureField`, `ShortcutActions` nem `KeyboardInjector` (D-05).
- **Grade entregue:** o grupo "Pontuação" começa por `-`, `+`, `=`, na ordem prevista em `onboarding.md` §2, passo 1; nenhum texto do roteiro precisou de ajuste.
- **Parada no PM-1:** T011 aguarda a compilação, a instalação e o roteiro de 11 passos na TV, com a sonda P-01 no VS Code e no iTerm.

### Rodada 2 de 2026-09-16 (PM-1 e T011)

- **Instalação:** `build-app.sh` com "JoystickAI Local Signing"; assinatura e permissões preservadas; configuração guardada em `config.pre-005.json`.
- **PM-1:** aprovado. O usuário montou ⌘+ e ⌘- na camada Options e relatou "Sim, funciona". O arquivo grava `equal` com ⇧⌘ e `minus` com ⌘, sem `plus`, e o log não tem acorde. Os passos 8 e 9 não foram relatados, e o 11 não foi executado para preservar os atalhos. Detalhe em `onboarding.md` §3.
- **Sonda P-01:** aprovada pelo relato do usuário, sem detalhe por aplicativo; nenhuma emenda para o terminal.
- **T011:** `onboarding.md` recebeu a seção 3 com o resultado de cada passo.

## Histórico de alterações

| Data | Alteração | Autor |
|------|-----------|-------|
| 2026-09-16 | Versão inicial gerada por `/reversa-to-do` | reversa |
| 2026-09-16 | T001 a T010 executadas por `/reversa-coding`; T011 aguarda o PM-1 | reversa |
| 2026-09-16 | PM-1 aprovado e T011 executada; todas as ações fechadas | reversa |
