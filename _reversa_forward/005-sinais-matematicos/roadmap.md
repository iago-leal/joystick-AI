# Roadmap: Atalhos de zoom montados pelo controle

> Identificador: `005-sinais-matematicos`
> Data: `2026-09-16`
> Requirements: `_reversa_forward/005-sinais-matematicos/requirements.md`
> Confidência: 🟢 CONFIRMADO, 🟡 INFERIDO, 🔴 LACUNA

> **Nota de confidência:** recebem 🟢 as decisões apoiadas no código inspecionado em 2026-09-16 (`KeyCatalog.swift`, `ChordEditor.swift`, `KeyCaptureField.swift`, `ActionSummary.swift`, `ConfigDocument.swift`, `KeyCatalogTests.swift`, `LogEventCatalogTests.swift`), na extração em `_reversa_sdd/` ou na decisão do usuário registrada no `requirements.md` §9. Recebem 🟡 as que dependem da reação de aplicativos de terceiros ao acorde injetado; a sonda P-01 as confirma. Não há 🔴: o `requirements.md` não tem `[DÚVIDA]` pendente.

## 1. Resumo da abordagem

O delta cabe em dois arquivos de produção. No núcleo, `KeyCatalog` passa a conhecer **escolhas compostas**: um sinal exibido na grade que corresponde a uma tecla do catálogo mais um modificador implícito. Há uma só, `+`, igual à tecla `equal` com ⇧. As escolhas compostas ficam fora de `KeyCatalog.entries`, de modo que os 73 nomes aceitos no arquivo, a busca por código de tecla, a validação, a codificação e o log continuam intactos. `KeyCatalog.display` passa a mostrar `equal` com ⇧ como `+`, o que atualiza de uma vez o cabeçalho do editor de acorde, o resumo de `ActionSummary`, o `FigureState` enviado à figura e os acordes gravados pelo teclado ou lidos do arquivo. No app, `ChordEditor` percorre a lista de escolhas do grupo, com o `+` logo depois do `-`, e aplica cada escolha pelo núcleo. A injeção, o arquivo de configuração e o esquema do log não mudam. Uma sonda no hardware (P-01) confirma que o ⌘⇧= e o ⌘- injetados ampliam e reduzem o zoom no VS Code e no terminal.

## 2. Princípios aplicados

Não existe `.reversa/principles.md`; não há princípio a respeitar nem conflito a registrar. As restrições equivalentes vêm da extração e das features anteriores:

| Restrição | Como a feature se relaciona | Status |
|-----------|------------------------------|--------|
| Núcleo funcional com casca imperativa; `JoystickCore` só importa `Foundation` (`architecture.md` §2 e §3) | A regra de composição, a exibição e a aplicação da escolha ficam no núcleo, testadas; o app só desenha a grade (D-01, D-03) | respeita |
| Catálogo fixo nome ↔ tecla virtual, com nomes e códigos únicos (003 D-03; `KeyCatalogTests.nomesETeclasVirtuaisUnicos`) | O `+` não vira entrada do catálogo; reaproveita `equal` e não cria nome no arquivo (D-01) | respeita |
| Configuração em JSON sem migração de esquema (`architecture.md` §5; ADR-011) | O arquivo continua gravando `"key": "equal"` com `"modifiers": ["command", "shift"]` (D-05) | respeita |
| Log sem teclas nem acordes (003 RN-14; `LogEventCatalogTests`) | Nenhum evento novo; o teste de segredos passa a incluir os rótulos compostos (D-06) | respeita |
| Escala de TV do PM-1a: 32 pt, 60 pt (`EditorMetrics`; ADR-014) | O `+` usa o mesmo `TVButtonStyle` das demais teclas da grade (D-04) | respeita |
| Regra de escrita do Reversa (`CLAUDE.md`) | `.reversa/reversa-config.json` está com `allowLegacyEdits: true` e `allowedPaths` vazio, liberação irrestrita. O `/reversa-coding` deve avisar uma vez por sessão | observação |

## 3. Decisões técnicas

| ID | Decisão | Justificativa | Alternativas descartadas | Confidência |
|----|---------|----------------|--------------------------|-------------|
| D-01 | Em `Sources/JoystickCore/Shortcuts/KeyCatalog.swift`, novo tipo `ComposedKey { name, display, keyCode, modifier, group, after }` e lista `KeyCatalog.composedKeys` com um só item: `plus`, `+`, `KeyChord.equal` (`0x18`), `.shift`, `.punctuation`, depois de `minus`. `KeyChord` ganha a constante `equal`. As escolhas compostas **não** entram em `entries`, `byName` nem `byKeyCode`. | `byKeyCode` é montado com `Dictionary(uniqueKeysWithValues:)`: uma entrada nova com `0x18` derrubaria o processo na carga. Fora de `entries`, `entry(named:)`, `ShortcutConfigValidation`, `ConfigDocument.encode` e `KeyCaptureField` continuam sem mudança (RN-05). | Entrada `plus` no catálogo com o mesmo código (quebra a unicidade e cria nome novo no arquivo); tecla `+` do teclado numérico `0x45` (descartada pelo usuário no clarify); composição só no app (sem teste, contra o RNF de testabilidade). | 🟢 |
| D-02 | `KeyCatalog.display(_:)` passa a exibir, antes da regra geral, todo acorde que casa uma escolha composta (`keyCode == equal` e `modifiers` contém ⇧) como `symbols(modifiers − [.shift]) + "+"`: ⇧⌘= vira "⌘+", ⌥⇧⌘= vira "⌥⌘+". `symbols(_:)` não muda. | A função é o ponto único de exibição de acordes: `ChordEditor` (cabeçalho), `ActionSummary.text(for:)`, e por ele `FigureState` e a figura web, e ainda o resultado da gravação pelo teclado (RN-03, RF-03, RF-07). | Guardar o sinal no `KeyChord` (mudaria o modelo e o arquivo); tratar só na grade (a figura e o resumo continuariam "⇧⌘="). | 🟢 |
| D-03 | Novo `enum KeyChoice { case key(KeyEntry), composed(ComposedKey) }` com `display`, `id` (o `name`), `isSelected(in chord:)` e `applied(to chord:) -> KeyChord`, e `KeyCatalog.choices(in group:) -> [KeyChoice]`, que intercala cada composta logo após a entrada indicada em `after`. Regras: `.composed` devolve a tecla da composta com os modificadores do acorde **mais** o implícito (RN-02); `.key` devolve a tecla com os modificadores do acorde, **retirando ⇧ se o acorde atual casa uma composta** (acionar `=` a partir de "⌘+" dá "⌘="). Seleção: `+` marcado com `equal` e ⇧; `=` marcado com `equal` sem ⇧. | Sem a retirada, acionar `=` a partir de "⌘+" não teria efeito visível, e os dois botões ficariam indistintos. A regra fica testável no núcleo. | Manter o comportamento atual de `.key` (o `=` pareceria não responder); desligar ⇧ ao escolher qualquer tecla (quebraria acordes como ⇧⌘Z montados hoje). | 🟢 |
| D-04 | `Sources/JoystickAIPoC/Editor/ChordEditor.swift`: a grade percorre `KeyCatalog.choices(in: group)` com `id: \.id`, rótulo `choice.display`, ação `onChange(choice.applied(to: chord))` e destaque `choice.isSelected(in: chord)`, no mesmo `TVButtonStyle` e `FlowLayout`. O `onAppear`, que escolhe o grupo pela tecla do acorde, continua valendo (`equal` está em pontuação). | Mudança mínima na casca; escala de TV herdada (RF-01, RF-05). | Botão "+" avulso fora da grade (quebra a regra de grupos de 003 D-19 e RF-01). | 🟢 |
| D-05 | Nada muda em `ConfigDocument`, `ShortcutConfigValidation`, `KeyCaptureField`, `ShortcutMapper`, `ShortcutActions` e `KeyboardInjector`. O ⌘+ é gravado como `{"type": "chord", "key": "equal", "modifiers": ["command", "shift"]}` e injetado como `flagsChanged` de ⌘ e ⇧ seguido de `keyDown` da tecla `0x18`, como o teclado físico. | É o que o legado já faz com o ⌘⇧= montado hoje (RN-01, RN-05, RF-06). | Nome `plus` no arquivo (exigiria mudar validação e deixaria arquivos novos ilegíveis para versões anteriores). | 🟢 |
| D-06 | Testes em `Tests/JoystickCoreTests/KeyCatalogTests.swift`: exibição (`⇧⌘=` → "⌘+", `⌥⇧⌘=` → "⌥⌘+", `⌘=` → "⌘=", `⌘-` → "⌘-"); `choices(in: .punctuation)` com `+` logo após `-` e sem composta nos outros grupos; `applied` e `isSelected` nos quatro casos de D-03; `entries.count` segue 73. `ActionSummaryTests`: acorde ⇧⌘= resume "⌘+". `LogEventCatalogTests.eventosDeAtalhosSemTextoTeclaNemAcorde`: o conjunto de segredos inclui `composedKeys` (nome e rótulo). | Cobre RF-01, RF-02, RF-03 e RF-06 sem hardware; TD-01 deixa a grade sem teste, coberta pelo PM-1. | Teste de interface do app (não há alvo de teste do app, TD-01). | 🟢 |
| D-07 | Portão manual PM-1 com a sonda P-01: acordes montados pelo ponteiro, salvos e usados em L1 + ↑ e L1 + ↓ no VS Code e no iTerm; e conferência do arquivo, da figura, da gravação pelo teclado e do log (roteiro em `onboarding.md`). | RF-04 depende da interpretação do acorde por aplicativos de terceiros. No VS Code, as associações padrão de `workbench.action.zoomIn` incluem ⌘= e ⇧⌘= (ver `investigation.md` §2); o terminal não foi verificado. | Encerrar sem hardware (RF-04 ficaria sem evidência). | 🟡 (P-01) |

## 4. Premissas

Nenhuma premissa vem de `[DÚVIDA]`: o `requirements.md` não tem marcador pendente. A única escolha feita sem resposta explícita do usuário, o envio do `+` pelo teclado principal, está registrada no `requirements.md` §9 e é sustentada por D-01 e D-07.

| Premissa | Origem (`requirements.md` seção) | Risco se errada |
|----------|----------------------------------|-----------------|
| O terminal usado aceita ⌘⇧= como ⌘+ | §9, última pergunta; RF-04 | Zoom no terminal não responde; emenda troca por ⌘= ou tecla do teclado numérico só para esse uso, sem mudar D-01 a D-06 |

## 5. Delta arquitetural

| Componente | Arquivo de origem no legado | Tipo de mudança | Resumo |
|------------|------------------------------|-----------------|--------|
| `shortcuts` (catálogo de teclas) | `_reversa_sdd/architecture.md#3. Camadas e dependências`; `_reversa_sdd/code-analysis.md#5.3 Catálogos` | regra-alterada | `KeyCatalog` ganha escolhas compostas (`ComposedKey`, `KeyChoice`, `choices(in:)`) e a exibição de `equal` com ⇧ como `+`; os 73 nomes do arquivo não mudam |
| `editor` (montagem de acorde) | `_reversa_sdd/code-analysis.md#8.3 Interface`; `_reversa_sdd/editor/requirements.md#Regras de Negócio` (RN-ED-17) | regra-alterada | A grade de `ChordEditor` usa `choices(in:)`, com `+` ao lado de `-` e seleção distinta para `+` e `=` |

A figura (`FigureState`, `FigureBridge`, `Resources/ControllerFigure/`) não muda de código: recebe o novo resumo por `ActionSummary`.

## 6. Delta no modelo de dados

- Resumo das mudanças: nada muda em disco nem no esquema. Surgem dois tipos de valor em memória no núcleo (`ComposedKey`, `KeyChoice`) e a constante `KeyChord.equal`.
- Detalhe completo em: `_reversa_forward/005-sinais-matematicos/data-delta.md`

## 7. Delta de contratos externos

n/a. O arquivo `~/.config/joystick-ai/config.json` e o log `poc-*.jsonl` mantêm os contratos das features 003 e 004; por isso não há diretório `interfaces/`.

| Contrato | Tipo | Arquivo de detalhe |
|----------|------|--------------------|
| Arquivo de configuração | arquivo | sem mudança; `_reversa_forward/003-editor-atalhos/interfaces/config-file.md` segue vigente |
| Log de diagnóstico | arquivo | sem mudança; `_reversa_forward/004-figura-controle-web/interfaces/diagnostic-log.md` segue vigente |

## 8. Plano de migração

n/a. Arquivos gravados antes da feature com ⇧⌘= são lidos como antes e apenas exibidos como "⌘+" (RF-06).

## 9. Riscos e mitigações

| Risco | Impacto | Probabilidade | Mitigação |
|-------|---------|---------------|-----------|
| O terminal não trata o ⌘⇧= injetado como ⌘+ | médio | baixo | P-01 no iTerm; se falhar, emenda com ⌘= para o terminal, sem mudar o núcleo |
| Layout em que a tecla `0x18` não produz `=` e `+` (por exemplo, alemão) mostra "+" para um acorde que não é ⌘+ | baixo | baixo | Fora do escopo: o usuário usa US Internacional, e ABNT2 tem `=` e `+` na mesma tecla; registrado em `investigation.md` §4 |
| Acionar `=` a partir de "⌘+" retirar ⇧ surpreender quem queria ⇧⌘= literal | baixo | baixo | ⇧⌘= e ⌘+ são o mesmo acorde; a exibição única evita ambiguidade (D-02, D-03) |
| Rótulo "⌘+" confundir-se com o separador " + Enter" do resumo de texto | baixo | baixo | O resumo de texto vem entre aspas; o de acorde, não (`ActionSummary`) |

## 10. Critério de pronto

- [ ] Todas as ações do `actions.md` marcadas `[X]`
- [ ] `cross-check.md` (se executado) sem CRITICAL nem HIGH
- [ ] `regression-watch.md` gerado
- [ ] `swift build -c release` e `./scripts/test.sh` verdes, com os testes de D-06
- [ ] PM-1 aprovado, com a sonda P-01 registrada em `onboarding.md`
- [ ] Re-extração reversa executada e sem regressão vermelha (recomendado, não obrigatório)

## 11. Histórico de alterações

| Data | Alteração | Autor |
|------|-----------|-------|
| 2026-09-16 | Versão inicial gerada por `/reversa-plan` | reversa |
