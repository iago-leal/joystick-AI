# Data delta: Figura do controle em página web embutida

> Identificador: `004-figura-controle-web`
> Data: `2026-09-15`
> Base: `_reversa_sdd/architecture.md#5. Modelo de dados em arquivo`, `_reversa_sdd/data-dictionary.md` e o código de `ControllerFigureView.swift` e `EditorViewModel.swift` em 2026-09-15
> Confidência: 🟢 salvo indicação

## 1. Persistência

Nada muda em disco.

| Arquivo | Antes | Depois |
|---------|-------|--------|
| `~/.config/joystick-ai/config.json` | seções `pointer`, `shortcuts`, `palette` | idêntico; a feature não lê nem grava nada novo (RN-10) |
| `~/Library/Logs/joystick-ai/poc-*.jsonl` | `logSchema` 1, catálogo de 50 eventos | `logSchema` 1; um evento novo, `editor.figure_unavailable` (ver `interfaces/diagnostic-log.md`) |
| `~/Library/WebKit/dev.iagoleal.joystick-ai.poc/` | inexistente | continua inexistente: o `WKWebView` usa `WKWebsiteDataStore.nonPersistent()` (RN-09, D-06); a sonda P-03 confere |
| Rodadas da tela de alvos | sem mudança | sem mudança |

## 2. Tipos novos em `JoystickCore`

```
FigureState: Codable, Equatable, Sendable        // Sources/JoystickCore/Config/FigureState.swift (D-12)
  layer: String                                  // "base" ou ButtonID.rawValue do modificador ("l1", "options")
  buttons: [FigureButton]                        // 18 itens, sempre na ordem de ButtonID.allCases

FigureButton: Codable, Equatable, Sendable
  id: String                                     // ButtonID.rawValue ("cross", "dpadLeft", "touchpadClick")
  label: String                                  // ButtonID.displayName ("✕", "←", "Touchpad")
  summary: String                                // ActionSummary.text(for:layer:in:), inclusive " (herdado)"
  kind: Kind                                     // fixed | modifier | own | inherited
  problem: Bool                                  // EditorViewModel.hasIssue(button, in: layer)
  selected: Bool                                 // button == selectedButton

FigureButton.Kind: String, Codable
  fixed        // ShortcutConfig.pointerButtons: r1, r2, touchpadClick
  modifier     // config.isModifier(button)
  inherited    // !fixed && !modifier && resolvedAction(for:in:).inherited
  own          // demais

FigureFailure: String                            // Sources/JoystickAIPoC/Editor/FigureBridge.swift (D-10)
  resourceMissing | loadFailed | processTerminated
```

Regras de derivação, iguais às de `ControllerFigureView.chip` (`ControllerFigureView.swift:38-44`):

| Campo | Regra | Origem |
|-------|-------|--------|
| `kind = fixed` | `ShortcutConfig.pointerButtons.contains(button)` | `ControllerFigureView.swift:41` |
| `kind = modifier` | `config.isModifier(button)`, avaliado depois de `fixed` | `ControllerFigureView.swift:41` |
| `kind = inherited` | nem fixo nem modificador, e `config.resolvedAction(for: button, in: layer).inherited` | `ControllerFigureView.swift:42` |
| `summary` | `ActionSummary.text(for: button, layer: layer, in: config)` | `ControllerFigureView.swift:52`; `ActionSummary.swift:8-21` |
| `problem` | existe `EditorIssue` com alvo `.trigger(layer: layer, button: button)` ou `.modifier(button)` | `EditorViewModel.swift:85-93` |
| `selected` | `button == selected` | `ControllerFigureView.swift:43` |
| `layer` | `layer?.rawValue ?? "base"`, como em `shortcut.triggered` | `LogEventCatalog.swift` (`shortcutTriggered`) |

O construtor recebe `issues: [EditorIssue]` (de `EditorDraft.issues`) em vez do `EditorViewModel`, para o núcleo não conhecer o modelo do app.

`ButtonID.displayName` passa a viver em `Sources/JoystickCore/Config/ButtonLabels.swift` (D-13), com os mesmos 18 textos de `EditorLabels.swift:4-27`.

## 3. Exemplo de `FigureState` codificado

Camada L2 da configuração padrão, com ✕ selecionado e sem problemas (dois botões mostrados):

```json
{
  "layer": "l2",
  "buttons": [
    { "id": "cross", "label": "✕", "summary": "Return (herdado)", "kind": "inherited", "problem": false, "selected": true },
    { "id": "dpadLeft", "label": "←", "summary": "mesa à esquerda", "kind": "own", "problem": false, "selected": false }
  ]
}
```

Chaves em ordem alfabética ao codificar (`JSONEncoder` com `.sortedKeys`), para o teste de instantâneo ser estável. O dicionário produzido por `JSONSerialization` a partir desse `Data` é o que `callAsyncJavaScript` recebe (D-07).

## 4. Testes previstos (`Tests/JoystickCoreTests/FigureStateTests.swift`)

| Teste | Afirma |
|-------|--------|
| ordem e contagem | 18 botões, `ids` iguais a `ButtonID.allCases.map(\.rawValue)` |
| padrão na base | `cross.summary == "Return"`, `ps.summary == "abrir paleta"`, `r1.summary == "clique esquerdo, fixo"`, `r1.kind == .fixed`, `l1.kind == .modifier` |
| camada L2 | `dpadLeft.summary == "mesa à esquerda"` e `kind == .own`; um botão sem ação própria em L2 com `kind == .inherited` e sufixo " (herdado)" |
| problema | texto vazio em ✕ produz `cross.problem == true`; problema de modificador marca o botão em qualquer camada |
| seleção | exatamente um `selected` quando `selected != nil`; nenhum quando `nil` |
| sem modificadores | configuração sem modificadores não produz `inherited` nem `modifier` |
| texto do usuário | `.text("<b>x</b>", pressEnter: false)` produz `summary == "“<b>x</b>”"` sem alteração (a proteção é da página, D-07, mas o núcleo não deve escapar nem truncar diferente) |
| codificação | instantâneo das chaves `buttons, id, kind, label, layer, problem, selected, summary`; `Kind` codifica como string |
| rótulos | `ButtonID.displayName` continua a produzir os 18 textos da tabela anterior |

## 5. Bundle do app

| Caminho no `.app` | Antes | Depois |
|-------------------|-------|--------|
| `Contents/MacOS/JoystickAIPoC` | binário | binário |
| `Contents/Info.plist` | copiado de `Resources/Info.plist` | igual |
| `Contents/Resources/ControllerFigure/index.html` | — | novo (D-01) |
| `Contents/Resources/ControllerFigure/figure.css` | — | novo |
| `Contents/Resources/ControllerFigure/figure.js` | — | novo |
| `Contents/_CodeSignature/CodeResources` | sela binário e `Info.plist` | sela também os três recursos (D-02) |

Fora do `.app`, o repositório ganha `Resources/ControllerFigure/` ao lado de `Resources/Info.plist`.

## 6. Migrações

Nenhuma. Não há esquema, versão nem índice a alterar.
