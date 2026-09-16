# Adendo: Atalhos de zoom montados pelo controle

> Identificador: `005-sinais-matematicos`
> Data: 2026-09-16
> Cenário: legado

## Vigência

Vigente desde 2026-09-16.

## Resumo da entrega

A feature permite montar pelo controle, no editor de atalhos, os acordes de aumentar e diminuir o zoom, ⌘+ e ⌘-, escolhendo diretamente os sinais `+` e `-`. Antes, o `-` já estava na grade, mas o `+` só podia ser montado como ⇧⌘=, e o editor o exibia assim. Agora o catálogo de teclas conhece o sinal composto `+`, que é a tecla `equal` com ⇧: a grade da pontuação começa por `-`, `+`, `=`, e todo acorde com `equal` e ⇧ aparece como `+` no painel, no resumo e na figura. O formato do arquivo de configuração, a validação, a captura pelo teclado, a injeção e o log não mudam; um ⌘+ continua gravado como `equal` com ⇧⌘.

Sincronização completa: as 11 ações de `actions.md` estão fechadas (T001 a T010 na primeira rodada; T011 após o portão manual PM-1). `swift build -c release` e `./scripts/test.sh` estão verdes, com 274 testes (270 antes da feature). O PM-1 foi aprovado pelo relato do usuário, com os atalhos gravados na camada Options e a sonda P-01 (zoom no VS Code e no iTerm) aprovada sem detalhe por aplicativo; os passos 8 e 9 do roteiro não foram relatados.

## Impacto por artefato da extração

| Artefato | Seção | Tipo de impacto | Delta |
|----------|-------|-----------------|-------|
| `_reversa_sdd/architecture.md` | `#3. Camadas e dependências` | regra-alterada | O componente `shortcuts` do `JoystickCore` ganha, em `KeyCatalog.swift`, os tipos de valor `ComposedKey` e `KeyChoice`, a lista `KeyCatalog.composedKeys` (só `plus`) e `KeyCatalog.choices(in:)`; o núcleo continua importando só `Foundation`, e o `editor` do app passa a delegar ao núcleo a aplicação e o destaque das escolhas da grade. |
| `_reversa_sdd/architecture.md` | `#5. Modelo de dados em arquivo` | regra-alterada | Sem delta de dados: o ⌘+ é gravado como `{"type": "chord", "key": "equal", "modifiers": ["command", "shift"]}`, e o nome `plus` nunca chega ao arquivo; arquivos anteriores com ⇧⌘= são lidos sem migração e exibidos como "⌘+". |
| `_reversa_sdd/domain.md` | `#2. Glossário` | regra-nova | Termo novo, "sinal composto": sinal da grade de montagem que corresponde a uma tecla do catálogo com um modificador implícito (`+` = `equal` + ⇧); não é tecla do catálogo nem nome gravável, e o "Acorde" continua sendo tecla do `KeyCatalog` com modificadores. |
| `_reversa_sdd/domain.md` | `#3.3 Atalhos, configuração e editor (003)` | regra-alterada | A exibição de acordes por símbolos ganha uma exceção: acorde com `equal` e ⇧ aparece como `+` sem o ⇧ (⇧⌘= → "⌘+"); 003 RN-06, RN-14 e RN-15 continuam intactas, e o teste de segredos do log passa a incluir `plus` e `+`. |
| `_reversa_sdd/editor/requirements.md` | `#Regras de Negócio` (RN-ED-14 e RN-ED-17) | regra-alterada | RN-ED-14 deve ser lida com a exceção do sinal `+`; em RN-ED-17, a grade do catálogo passa a ser de escolhas, com `+` logo após `-`, e escolher uma tecla a partir de um acorde exibido com `+` retira o ⇧ (⌘+ seguido de `=` dá ⌘=). RF-ED-05 (⇧⌘T só com o ponteiro) segue válido. |
| `_reversa_sdd/editor/design.md` | `#Interface` (`ChordEditor`) | regra-alterada | A "grade de teclas" percorre `KeyCatalog.choices(in:)`, com rótulo `choice.display`, aplicação `choice.applied(to:)` e destaque `choice.isSelected(in:)`, no mesmo `TVButtonStyle` e `FlowLayout`. |
| `_reversa_sdd/atalhos/requirements.md` | `#Regras de Negócio` (RN-AT-18) | regra-alterada | O catálogo gravável segue com 73 teclas; os sinais compostos ficam fora de `entries`, `byName` e `byKeyCode`, e `entry(named: "plus")` é `nil`. |
| `_reversa_sdd/atalhos/design.md` | `#Interface` (`Tipos do núcleo`) | regra-alterada | `KeyChord` ganha a constante `equal` 24, usada pela entrada `equal` do catálogo; `KeyCatalog` ganha `composedKeys` e `choices(in:)`, e `display(chord)` retira o modificador implícito e mostra o sinal quando um sinal composto casa o acorde. |
| `_reversa_sdd/data-dictionary.md` | `#3.2 KeyChord` | regra-alterada | A lista de constantes inclui `equal` 24. |
| `_reversa_sdd/code-analysis.md` | `#5.3 Catálogos` | regra-alterada | Ao lado das 73 teclas, o catálogo tem os sinais compostos (`ComposedKey`), usados só na grade e na exibição. |
| `_reversa_sdd/traceability/code-spec-matrix.md` | `#Testes` | regra-alterada | `KeyCatalogTests.swift` passa de 6 para 9 testes (`exibicaoDoSinalDeSoma`, `escolhasDaGrade`, `aplicacaoESelecaoDasEscolhas`); `ActionSummaryTests.swift` ganha `acordesDeZoom`. O total do projeto passa a 274. |

## Regras sob vigilância

W001 a W006 no watch principal e O001 a O005 em "Observações", em [`_reversa_forward/005-sinais-matematicos/regression-watch.md`](../../_reversa_forward/005-sinais-matematicos/regression-watch.md). O desfecho do PM-1 para as observações está registrado no próprio arquivo.

## Fontes

- `_reversa_forward/005-sinais-matematicos/legacy-impact.md`
- `_reversa_forward/005-sinais-matematicos/regression-watch.md`
- `_reversa_forward/005-sinais-matematicos/requirements.md`
- `_reversa_forward/005-sinais-matematicos/progress.jsonl`
- `_reversa_forward/005-sinais-matematicos/actions.md` (notas das rodadas 1 e 2)
- `_reversa_forward/005-sinais-matematicos/data-delta.md`
- `_reversa_forward/005-sinais-matematicos/onboarding.md` (resultado do PM-1)
