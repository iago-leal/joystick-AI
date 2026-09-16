# Regression watch: Atalhos de zoom montados pelo controle

> Identificador: `005-sinais-matematicos`
> Âncora: legado (`_reversa_sdd/architecture.md`, `_reversa_sdd/domain.md`, extração de 2026-09-15). Os itens do watch principal nascem da seção "Modificadas" do `legacy-impact.md`; só regras originalmente 🟢 entram nele. As regras 🟡 do `requirements.md` e a decisão 🟡 do roadmap, que dependem da sonda P-01, ficam em "Observações", sem peso de regressão.

## Watch principal

| ID | Origem (arquivo, seção) | Regra esperada após mudança | Tipo de verificação | Sinal de violação |
|----|--------------------------|------------------------------|---------------------|-------------------|
| W001 | `_reversa_sdd/editor/requirements.md`, RN-ED-14 ("acorde por símbolos") | O resumo de acorde usa símbolos na ordem ⌃⌥⇧⌘, exceto quando o acorde casa um sinal composto: `equal` com ⇧ aparece como `+`, sem o ⇧ (⇧⌘= → "⌘+", ⌥⇧⌘= → "⌥⌘+"), no painel, no resumo e na figura. | redação | Re-extração descrevendo ⇧⌘= como "⇧⌘=", ou `KeyCatalogTests.exibicaoDoSinalDeSoma` e `ActionSummaryTests.acordesDeZoom` ausentes ou vermelhos. |
| W002 | `_reversa_sdd/editor/requirements.md`, RN-ED-17; `_reversa_sdd/editor/design.md` §Interface, `ChordEditor` | A grade do editor de acorde percorre `KeyCatalog.choices(in:)`; na pontuação a ordem começa por `-`, `+`, `=`; rótulo, aplicação e destaque vêm de `KeyChoice`; escolher uma tecla a partir de um acorde que casa um sinal composto retira o modificador implícito. | redação | `ChordEditor` voltando a `KeyCatalog.entries(in:)`, grade sem `+`, ou `+` e `=` destacados ao mesmo tempo. |
| W003 | `_reversa_sdd/atalhos/design.md`, tabela de tipos, `KeyCatalog` | A interface de `KeyCatalog` inclui `composedKeys` (um item: `plus`, `+`, tecla 24, `.shift`, `.punctuation`, depois de `minus`) e `choices(in:)`, e o módulo tem os tipos `ComposedKey` e `KeyChoice`, todos em `KeyCatalog.swift`. | presença | Tipos ou membros ausentes, movidos para o alvo do app, ou `composedKeys` com item diferente sem feature que o justifique. |
| W004 | `_reversa_sdd/code-analysis.md` §5.3 Catálogos; `_reversa_sdd/atalhos/requirements.md`, RN-AT-18 | O catálogo gravável segue com 73 teclas e nomes únicos; os sinais compostos ficam fora de `entries`, `byName` e `byKeyCode`, de modo que `entry(named: "plus")` é `nil` e `plus` nunca é aceito nem gravado no arquivo. | ausência | `plus` (ou outro sinal) em `entries`, `entries.count` diferente de 73, ou `"key": "plus"` aceito pela validação. |
| W005 | `_reversa_sdd/atalhos/design.md`, `KeyChord`; `_reversa_sdd/data-dictionary.md` §3.2 | As constantes de `KeyChord` incluem `equal` 24, e a entrada `equal` do catálogo a usa. | redação | Lista de constantes na extração sem `equal`, ou entrada `equal` com código diferente de 24. |
| W006 | `_reversa_sdd/traceability/code-spec-matrix.md` (`KeyCatalogTests.swift`); `_reversa_sdd/atalhos/tasks.md`, TT-01 | `KeyCatalogTests` tem 9 testes, entre eles `exibicaoDoSinalDeSoma`, `escolhasDaGrade` e `aplicacaoESelecaoDasEscolhas`. | redação | Matriz ou tarefa citando 6 testes, ou algum dos três testes removido. |

## Observações

Regras 🟡 do `requirements.md` e decisão 🟡 do `roadmap.md`, implementadas nesta rodada; sem peso de regressão até o PM-1 e uma re-extração as confirmarem como 🟢.

| ID | Origem (arquivo, seção) | Regra esperada | Tipo de verificação | Sinal de violação |
|----|--------------------------|----------------|---------------------|-------------------|
| O001 | `requirements.md` RN-01; `roadmap.md` D-01 | `+` é a tecla `equal` (`0x18`) com ⇧, como no teclado físico nos layouts US Internacional e ABNT2. | presença | Sinal composto apontando outra tecla, como a `+` do teclado numérico, sem decisão registrada. |
| O002 | `requirements.md` RN-02; `roadmap.md` D-03 | Escolher `+` liga ⇧ e preserva os demais modificadores; desligar ⇧ depois deixa "⌘=". | presença | `+` apagando ⌘ ou ⌥; ⇧ desligado sem trocar a exibição para `=`. |
| O003 | `requirements.md` RN-03 | A exibição com `+` vale também para acordes gravados pelo teclado e lidos do arquivo (PM-1, passos 8 e 9). | presença | Acorde gravado ou lido aparecendo como "⇧⌘=". |
| O004 | `requirements.md` RN-05; `roadmap.md` D-05 | O ⌘+ salvo é gravado como `{"type": "chord", "key": "equal", "modifiers": ["command", "shift"]}` (PM-1, passo 7). | ausência | `plus` presente em `config.json`. |
| O005 | `requirements.md` RF-04; `roadmap.md` D-07, sonda P-01 | L1 + ↑ com ⌘+ e L1 + ↓ com ⌘- ampliam e reduzem o zoom no VS Code e no iTerm (PM-1, passos 5 e 6). | presença | Zoom sem resposta num dos dois aplicativos; no iTerm, aciona a emenda prevista no roadmap §9. |

Desfecho do PM-1 (2026-09-16): O004 confirmada no arquivo gravado (`equal` com ⇧⌘ e `minus` com ⌘, na camada Options, sem `plus`); O005 aprovada pelo relato do usuário ("Sim, funciona"), sem detalhe por aplicativo, com dois acionamentos de cada atalho no log; O001 e O002 exercitadas nos passos 1 a 4, também aprovados pelo relato; O003 sem verificação em hardware, porque os passos 8 e 9 não foram relatados, e coberta só pelos testes automatizados. Nenhuma emenda foi acionada.

## Histórico de re-extrações

## Arquivadas
