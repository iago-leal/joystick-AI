# Investigation: Atalhos de zoom montados pelo controle

> Identificador: `005-sinais-matematicos`
> Data: `2026-09-16`
> Roadmap: `_reversa_forward/005-sinais-matematicos/roadmap.md`

## 1. Pergunta de fundo

Como permitir que o programador de sofá escolha `+` e `-` na grade de montagem de acordes e veja "⌘+" e "⌘-" no editor e na figura, sem mudar o arquivo de configuração, a validação, a injeção nem o log, e de modo que o acorde montado amplie e reduza o zoom como o teclado físico?

## 2. Estado de partida, observado no código em 2026-09-16

- `KeyCatalog` (`Sources/JoystickCore/Shortcuts/KeyCatalog.swift`) tem 73 `KeyEntry` em seis grupos. O grupo de pontuação começa com `minus` (`0x1B`, "-") e `equal` (`0x18`, "="); não há `+`. `byName` e `byKeyCode` são montados com `Dictionary(uniqueKeysWithValues:)`, o que exige nomes e códigos únicos.
- `KeyCatalog.display(_:)` concatena `symbols(modifiers)`, na ordem ⌃⌥⇧⌘, com o rótulo da tecla. Hoje ⇧⌘= aparece como "⇧⌘=".
- Quem usa `display`: `ChordEditor` (cabeçalho e aviso de ⌘Tab e ⌘Espaço) e `ActionSummary.text(for:)`, que alimenta `FigureState` e, por ele, a figura web da feature 004.
- `ChordEditor` (`Sources/JoystickAIPoC/Editor/ChordEditor.swift`) monta a grade com `ForEach(KeyCatalog.entries(in: group), id: \.name)`; cada botão faz `onChange(KeyChord(entry.keyCode, chord.modifiers))` e fica destacado se `entry.keyCode == chord.keyCode`. Os quatro modificadores são alternadores independentes.
- `KeyCaptureField` aceita qualquer `keyDown` cuja tecla esteja no catálogo e grava os modificadores do evento: ⌘+ no teclado físico (US Internacional) já resulta em `KeyChord(0x18, [.command, .shift])`.
- `ConfigDocument.encode` grava o nome da tecla (`equal`) e a lista de modificadores; `ShortcutConfigValidation` aceita só nomes do catálogo. Um ⇧⌘= já é válido e gravável.
- `KeyboardInjector` pressiona ⌘ e ⇧ com `flagsChanged` e posta a tecla `0x18` com as `flags` dos modificadores mantidos, como o teclado físico.
- `LogEventCatalogTests.eventosDeAtalhosSemTextoTeclaNemAcorde` monta o conjunto de segredos com nome e rótulo de cada `KeyEntry`.
- Testes: 270, todos verdes após a feature 004 (`_reversa_sdd/addenda/004-figura-controle-web.md#Atualização 2026-09-16`).

Conclusão: o legado já monta, grava e injeta ⌘+ como ⇧⌘=. A lacuna é só de escolha e de exibição.

## 3. Alternativas avaliadas

### 3.1 Como representar o `+`

| Alternativa | Prós | Contras | Veredito |
|-------------|------|---------|----------|
| Escolha composta fora do catálogo: `+` = `equal` + ⇧ | Arquivo, validação, captura e injeção intactos; testável no núcleo | Um tipo novo e uma lista paralela no catálogo | **Escolhida** (D-01, D-03) |
| `KeyEntry("plus", 0x18, "+")` no catálogo | Grade sem mudança de código | Código duplicado derruba `byKeyCode`; nome novo no arquivo; ⇧ não seria implícito | Descartada |
| Tecla `+` do teclado numérico (`kVK_ANSI_KeypadPlus`, `0x45`) | Sem ⇧; aceita pelo VS Code | O usuário não a escolheu; alguns aplicativos tratam o teclado numérico de outra forma; tecla nova no arquivo | Descartada |
| Atalho de sistema "Zoom" | Um clique | Não é atalho do macOS lido de `AppleSymbolicHotKeys`; confundiria o conceito de atalho de sistema | Descartada |

### 3.2 Onde aplicar a exibição "⌘+"

| Alternativa | Prós | Contras | Veredito |
|-------------|------|---------|----------|
| Em `KeyCatalog.display` | Ponto único: painel, figura, captura e arquivo lido ficam coerentes | Muda um teste de exibição existente só por acréscimo | **Escolhida** (D-02) |
| Só na grade | Mudança local | Figura e resumo continuariam "⇧⌘=", contra RF-03 | Descartada |

### 3.3 Efeito de acionar `=` a partir de "⌘+"

| Alternativa | Prós | Contras | Veredito |
|-------------|------|---------|----------|
| Retirar ⇧ quando o acorde atual casa uma composta | `=` sempre produz efeito visível; `+` e `=` nunca ficam destacados juntos | Regra adicional, restrita às compostas | **Escolhida** (D-03) |
| Manter os modificadores, como hoje | Nenhuma regra nova | Acionar `=` não mudaria nada na tela | Descartada |

## 4. Compatibilidade com aplicativos e layouts

- **VS Code** (verificado em 2026-09-16 no pacote instalado, `workbench.desktop.main.js`): `workbench.action.zoomIn` tem `primary: 2134` e `secondary: [3158, 2157]`. Na codificação de teclas do VS Code, `2048` é ⌘ e `1024` é ⇧; `86` é `Equal` e `109` é `NumpadAdd`. Logo, as associações são ⌘=, ⇧⌘= e ⌘ com o `+` numérico. O ⇧⌘= injetado deve ampliar o zoom. 🟢 para a associação, 🟡 para a injeção até a P-01.
- **iTerm** (instalado): "Make Text Bigger" usa ⌘+ como equivalente de menu; a correspondência com ⇧⌘= injetado não foi observada. 🟡 (P-01)
- **Layouts:** US Internacional (layout ativo do usuário) e ABNT2 têm `=` e `+` na tecla `0x18`, e `-` na `0x1B`. Em layouts como o alemão, `0x18` produz outro caractere; a feature não os cobre, em linha com o escopo definido.

## 5. Sondas

| ID | Pergunta | Como responder | Decisão afetada |
|----|----------|----------------|-----------------|
| P-01 | O ⇧⌘= e o ⌘- injetados pelo app ampliam e reduzem o zoom no VS Code e no iTerm? | PM-1, passos 5 e 6 do `onboarding.md` | D-07; emenda para o terminal se falhar |

## 6. Padrões aplicáveis

- Núcleo funcional com casca imperativa (`_reversa_sdd/architecture.md#2. Estilo arquitetural`): regra de composição e exibição como funções puras sobre `KeyChord`.
- Catálogo fechado com nomes estáveis (003 D-03): as compostas são derivadas do catálogo, não o ampliam.
- Portão manual no hardware para o que depende de terceiros (`_reversa_sdd/domain.md#2. Glossário`, "Portão manual" e "Sonda").
