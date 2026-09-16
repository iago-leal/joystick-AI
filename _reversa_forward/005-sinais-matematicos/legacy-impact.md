# Impacto no legado: Atalhos de zoom montados pelo controle

> Identificador: `005-sinais-matematicos`
> Data: `2026-09-16`
> Âncora: legado (`_reversa_sdd/architecture.md` + `_reversa_sdd/domain.md`, extração de 2026-09-15, com os adendos das features 001 a 004), com as specs SDD de `_reversa_sdd/sdd/` como complemento.
> Política de edição no momento da execução: `allowLegacyEdits: true`, `allowedPaths` vazio (liberação irrestrita do projeto), relida na ativação do `/reversa-coding`.
> Execução: completa; 11 de 11 ações fechadas em duas rodadas (T001 a T010 na 1; T011 na 2, após o portão manual PM-1 aprovado, com a sonda P-01 aprovada pelo relato do usuário).

A feature ensina o catálogo de teclas a oferecer sinais compostos, isto é, sinais que correspondem a uma tecla do catálogo com um modificador implícito. Há um só, `+`, igual à tecla `equal` com ⇧. A exibição de acordes passa a mostrar esse par como `+`, e a grade do editor de acorde passa a oferecer `+` logo após `-`. O arquivo de configuração, a validação, a captura pelo teclado, a injeção e o log não mudam de código.

## Arquivos afetados

| Arquivo afetado | Componente | Tipo | Severidade | Justificativa |
|-----------------|------------|------|------------|---------------|
| `Sources/JoystickCore/Shortcuts/ShortcutMapper.swift` | `shortcuts` (architecture.md §3, camada Core; `atalhos/design.md`, `KeyChord`) | regra-nova | LOW | Constante `KeyChord.equal = 24` (`0x18`), ao lado das demais teclas nomeadas. Nenhum uso existente muda. |
| `Sources/JoystickCore/Shortcuts/KeyCatalog.swift` | `shortcuts` (architecture.md §3; `atalhos/design.md`, `KeyCatalog`; `code-analysis.md` §5.3) | regra-alterada | MEDIUM | Tipos novos `ComposedKey` e `KeyChoice`, lista `composedKeys` (só `plus`), `choices(in:)` e a busca interna `composedKey(matching:)`. `display(_:)` é o ponto único de exibição de acordes e passa a mostrar `equal` com ⇧ como `+` (⇧⌘= → "⌘+"), o que alcança o cabeçalho do editor de acorde, `ActionSummary`, `FigureState` e a figura web. `entries`, `byName` e `byKeyCode` seguem com 73 teclas; a entrada `equal` passou a citar `KeyChord.equal` em vez do literal, com o mesmo valor. |
| `Sources/JoystickAIPoC/Editor/ChordEditor.swift` | `editor` (`editor/design.md` §Interface, `ChordEditor`; RN-ED-17) | regra-alterada | MEDIUM | A grade percorre `KeyCatalog.choices(in:)`: rótulo, aplicação e destaque vêm do núcleo. Muda a montagem de acordes com `equal` e ⇧: acionar `+` liga ⇧; acionar uma tecla a partir de um acorde exibido com `+` retira ⇧ (⌘+ seguido de `=` dá ⌘=, seguido de `Z` dá ⌘Z). Acordes sem sinal composto, como ⇧⌘Z, montam-se como antes. `TVButtonStyle`, `FlowLayout` e o grupo inicial por `onAppear` inalterados. Sem teste automatizado (TD-01); coberto pelo PM-1, passos 1 a 4. |
| `Tests/JoystickCoreTests/KeyCatalogTests.swift` | testes | regra-nova | LOW | Três testes novos: `exibicaoDoSinalDeSoma`, `escolhasDaGrade` e `aplicacaoESelecaoDasEscolhas` (as cinco linhas de `data-delta.md` §3). A suíte passa de 6 para 9 testes. |
| `Tests/JoystickCoreTests/ActionSummaryTests.swift` | testes | regra-nova | LOW | Teste `acordesDeZoom`: ⌘+ em L1 + ↑ resume "⌘+", ⌘- em L1 + ↓ resume "⌘-". |
| `Tests/JoystickCoreTests/LogEventCatalogTests.swift` | testes | regra-alterada | LOW | `eventosDeAtalhosSemTextoTeclaNemAcorde` inclui nome e rótulo de cada sinal composto no conjunto de segredos. |

Resultado da verificação (T010): `swift build -c release` verde; `./scripts/test.sh` com 274 testes em 31 suítes, todos verdes (270 antes da feature).

## Diff conceitual por componente

**Atalhos, catálogo de teclas.** Antes, a grade e a exibição conheciam só as 73 entradas, e ⇧⌘= aparecia como "⇧⌘=". Agora o catálogo distingue duas listas: as entradas, que continuam sendo o único vocabulário do arquivo, da validação e da captura, e os sinais compostos, que existem apenas para a escolha na grade e para a exibição. Um sinal composto casa todo acorde com a sua tecla e o seu modificador implícito; `display` retira esse modificador e mostra o sinal. Como `symbols(_:)` não muda, os demais modificadores seguem na ordem ⌃⌥⇧⌘: ⌥⇧⌘= aparece como "⌥⌘+".

**Atalhos, escolha na grade.** `KeyChoice` concentra duas regras puras. Escolher um sinal composto aplica a sua tecla e acrescenta o modificador implícito aos já ligados. Escolher uma tecla aplica a tecla e mantém os modificadores, exceto o do sinal composto que casava o acorde atual. O destaque segue a mesma lógica, de modo que `+` e `=` nunca ficam marcados juntos. `choices(in:)` intercala cada sinal logo após a entrada indicada em `after`: na pontuação, `-`, `+`, `=`, `[`, …; nos demais grupos, a lista é idêntica às entradas.

**Editor, painel de acorde.** O `ChordEditor` deixa de calcular tecla e destaque e passa a delegá-los ao núcleo. A aparência dos botões e a quebra de linha não mudam; a pontuação ganha um botão.

**Figura e resumo.** Nenhum código muda em `ActionSummary`, `FigureState`, `FigureBridge` nem em `Resources/ControllerFigure/`; o novo texto chega pela exibição do catálogo.

**Arquivo, validação, captura, injeção e log.** Sem mudança de código. Um ⌘+ montado é gravado como `{"type": "chord", "key": "equal", "modifiers": ["command", "shift"]}`, igual ao ⇧⌘= montado antes, e injetado com ⇧ e ⌘ mantidos sobre a tecla `0x18`, como o teclado físico. O nome `plus` nunca chega ao arquivo nem ao log.

## Preservadas

Regras 🟢 do `domain.md` e da extração que continuam intactas, com a evidência conferida nesta rodada:

- **RN-AT-18** (73 teclas com nome estável, posições físicas; tecla fora do catálogo não pode ser gravada): `entries` segue com 73 itens e sem `plus` (`KeyCatalogTests.exibicaoDoSinalDeSoma`); `nomesETeclasVirtuaisUnicos` e `idaEVoltaEntreNomeETecla` verdes.
- **003 D-03** (tabela fixa nome ↔ tecla virtual, com nomes e códigos únicos): `byName` e `byKeyCode` continuam montados só sobre `entries`.
- **RN-CF-14** (regras de conteúdo, entre elas `unknownKey`): `ShortcutConfigValidation` e `ConfigDocument` não foram tocados; nenhum nome novo é aceito nem gravado.
- **ADR-011** e **architecture.md §5** (configuração em JSON, sem migração de esquema): o formato gravado não muda; arquivos anteriores com ⇧⌘= são lidos como antes.
- **003 RN-06** (seis tipos de ação; acorde com repetição opcional): `TriggerAction` e `KeyRepeat` inalterados.
- **003 RN-14** (log sem textos, rótulos nem acordes): nenhum evento novo; o teste de segredos passa a cobrir `plus` e `+`.
- **003 RN-15** (gravação de acorde só com o campo ativo e a janela em foco): `KeyCaptureField` inalterado; ⌘+ no teclado físico continua gravando `KeyChord(0x18, [.command, .shift])`, agora exibido como "⌘+".
- **RN-IN-09** (acorde injetado com os modificadores em ordem ⌃⌥⇧⌘ antes da tecla): `KeyboardInjector` e `ShortcutActions` inalterados.
- **RF-ED-05** (montar ⌘⇧T só com o ponteiro): `T` não casa sinal composto, portanto ⇧ é mantido e o acorde é montado e exibido como antes ("⇧⌘T").
- **RN-ED-13** e **ADR-014** (escala de TV, 32 pt e 60 pt): o botão `+` usa o mesmo `TVButtonStyle`.
- **architecture.md §3** (`JoystickCore` só importa `Foundation`): os tipos novos ficam em `KeyCatalog.swift`, sem `import` novo.
- **Emenda E002 da feature 004** (grupos do editor de acorde em `FlowLayout`): mantida.

## Modificadas

Regras 🟢 alteradas ou cuja descrição na extração deixa de ser completa; cada uma gera um item no `regression-watch.md`:

- **`_reversa_sdd/editor/requirements.md`, RN-ED-14** ("acorde por símbolos"): a regra continua, com a exceção de que `equal` com ⇧ aparece como `+` sem o ⇧ (⇧⌘= → "⌘+"), no painel, no resumo e na figura.
- **`_reversa_sdd/editor/requirements.md`, RN-ED-17**, e **`_reversa_sdd/editor/design.md` §Interface, `ChordEditor`** ("grade de teclas"): a grade passa a ser de escolhas, com `+` logo após `-` na pontuação; o destaque e a aplicação vêm de `KeyChoice`, e escolher uma tecla a partir de um acorde exibido com `+` retira ⇧.
- **`_reversa_sdd/atalhos/design.md`, `KeyCatalog`** (`entries`, `entry(named:)`, `entry(keyCode:)`, `entries(in:)`, `display(chord)`, `symbols(modifiers)`): a interface ganha `composedKeys` e `choices(in:)`, e surgem os tipos `ComposedKey` e `KeyChoice`.
- **`_reversa_sdd/atalhos/design.md`, `KeyChord`**, e **`_reversa_sdd/data-dictionary.md` §3.2** (lista de constantes): entra `equal` 24.
- **`_reversa_sdd/code-analysis.md` §5.3 Catálogos** (`KeyCatalog` com 73 teclas em 6 grupos): continua verdadeiro, mas incompleto sem os sinais compostos fora da tabela.
- **`_reversa_sdd/traceability/code-spec-matrix.md`** e **`_reversa_sdd/atalhos/tasks.md`, TT-01** (`KeyCatalogTests` com 6 testes): a suíte passa a ter 9.
