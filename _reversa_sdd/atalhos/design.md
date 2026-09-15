# Atalhos (shortcuts), Design Técnico

> Gerado pelo Redator em 2026-09-15 · Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA

## Interface

### Tipos do núcleo

| Tipo | Definição | Arquivo |
|------|-----------|---------|
| `KeyModifier` | `control`, `option`, `shift`, `command`; `Comparable` pela ordem de declaração (⌃⌥⇧⌘) | `ShortcutMapper.swift:4-10` |
| `KeyChord` | `keyCode: UInt16`, `modifiers: Set<KeyModifier>`; constantes Return 36, Tab 48, Space 49, grave 50, Delete 51, Esc 53, M 46, setas 123 a 126; `isArrow` | `ShortcutMapper.swift:13-35` |
| `SystemShortcut` | `nextWindow` 27, `missionControl` 32, `applicationWindows` 33, `spaceLeft` 79, `spaceRight` 81; `name`, `displayName`, `defaultChord`, `chords(fromSymbolicHotKeys:)` | `ShortcutMapper.swift:38-104` |
| `ShortcutAction` | `keyDown(chord, repeats)`, `keyUp(chord)`, `text(text, pressEnter)`, `modifierDown/Up(m)`, `openPalette`, `systemDown/Up(s)` | `ShortcutMapper.swift:106-119` |
| `TriggerAction` | `chord(chord, repeats)`, `systemShortcut(s)`, `text(text, pressEnter)`, `openPalette`, `none`; `type` | `ShortcutConfig.swift:9-28` |
| `ShortcutConfig` | `pointerButtons = {r1, r2, touchpadClick}`; `modifiers: [ButtonID: Set<KeyModifier>]`; `layers: [ButtonID?: [ButtonID: TriggerAction]]` (`nil` = base); `resolvedAction(for:in:) → Resolution { action, inherited }` | `ShortcutConfig.swift:31-66` |
| `KeyCatalog` | `entries`, `entry(named:)`, `entry(keyCode:)`, `entries(in:)`, `display(chord)`, `symbols(modifiers)` | `KeyCatalog.swift` |
| `KeyRepeat` | `delayMs = 400`, `intervalMs = 50` | `KeyRepeat.swift` |

### `ShortcutMapper` (valor, `Sendable`)

| Membro | Assinatura | Observação |
|--------|-----------|------------|
| `config` | `let ShortcutConfig` | Imutável; troca = novo mapeador |
| `held` | `Set<ButtonID>` | Botões pressionados vistos pelo mapeador |
| `modifierOrder` | `[ButtonID]` | Do mais antigo ao mais recente |
| `resolved` | `[ButtonID: HeldAction]` | `chord` ou `system` guardado até o soltar |
| `lastTrigger` | `Trigger? { button, layer, type }` | Zerado a cada pressionar |
| `currentLayer` | `ButtonID?` | `modifierOrder.first` |
| `press(_:)` / `release(_:)` / `releaseAll()` | `mutating → [ShortcutAction]` | — |

### `ShortcutActions` (classe, fila `input`)

| Membro | Observação |
|--------|------------|
| `init(context:keyboard:config:)` | Recebe o `KeyboardInjector` único |
| `handle(_ event: InputEvent)` | `buttonDown`, `buttonUp`, `controllerDisconnected` |
| `apply(_ config:)` | Para a repetição, solta tudo, recria o mapeador |
| `releaseAll() -> [ShortcutAction]` | Solta e devolve as solturas para repetição |
| `repeatReleases(_:)` | `forceUp` / `forceModifierUp` |
| `onOpenPalette` | Chamado na fila `input` depois das solturas |
| `static currentChord(for:)` | `CFPreferencesCopyAppValue("AppleSymbolicHotKeys", "com.apple.symbolichotkeys")` |

## Fluxo Principal

### `press(button)` (`ShortcutMapper.swift:163-193`)

```
lastTrigger ← nil
se button já está em held: devolve []
held ∪= {button}
se button ∈ pointerButtons: devolve []
se config.modifiers[button] = keys:
    modifierOrder.append(button); devolve [modifierDown(k) para k em keys ordenado]
layer ← modifierOrder.first
action ← config.resolvedAction(button, layer).action
    // própria na camada → herdada da base → none
chord(c, r)          → resolved[button] = chord(c); [keyDown(c, r)]
systemShortcut(s)    → resolved[button] = system(s); [systemDown(s)]
text(t, e)           → [text(t, e)]
openPalette          → [openPalette]
none                 → []
se action ≠ none: lastTrigger ← (button, layer, type)
```

### `release(button)` (`:195-202`)

Se não estava em `held`, `[]`. Se é modificador na ordem: remove da ordem e devolve `modifierUp` de cada tecla em ordem ⌃⌥⇧⌘. Senão, devolve o `keyUp`/`systemUp` da ação guardada, se houver.

### `releaseAll()` (`:206-216`)

`resolved` ordenado por `ButtonID` → `keyUp`/`systemUp`; depois, para cada modificador em `modifierOrder`, `modifierUp` das teclas; zera `held`, `modifierOrder`, `resolved`, `lastTrigger`.

### Execução (`ShortcutActions.swift:25-110`)

1. `buttonDown`: `actions = mapper.press(b)`; `trigger = mapper.lastTrigger` (lido antes, pois abrir a paleta zera o mapeador); `perform(actions)`; se `trigger`, registra `shortcut.triggered`.
2. `buttonUp`: `perform(mapper.release(b))`.
3. `controllerDisconnected`: `releaseAll()`.
4. `perform`:
   - `keyDown(c, r)` → `keyboard.chordDown(c)`; se `r`, `startRepeat(c)`.
   - `keyUp(c)` → se `c == repeatingChord`, `stopRepeat()`; `keyboard.chordUp(c)`.
   - `text(t, e)` → `keyboard.type(t, pressEnter: e)` (Enter imediato, sem o atraso da paleta).
   - `modifierDown/Up(m)` → `keyboard.modifierDown/Up(m)`.
   - `openPalette` → `releaseAll()`; `onOpenPalette?()` (liga a `paletteActions.open()`, `AppDelegate.swift:77`).
   - `systemDown(s)` → `chord = currentChord(s)`; `systemChordsDown[s] = chord`; `chordDown(chord)`.
   - `systemUp(s)` → se houver acorde guardado, remove e `chordUp`.
5. `startRepeat(c)`: para a repetição anterior; `DispatchSourceTimer` na fila `input`, prazo 400 ms, intervalo 50 ms, folga 5 ms; cada disparo `keyboard.chordRepeat(c)`.

### Leitura das preferências (`ShortcutMapper.swift:84-103`)

Para cada atalho: parte do padrão; exige `hotKeys[String(id)]` com `enabled` verdadeiro, `value.parameters` com ao menos 3 números e `parameters[1]` que caiba em `UInt16`; converte a máscara `parameters[2]` pelos bits de RN-AT-11.

## Fluxos Alternativos

- **Ruptura:** `InputRouter.setIdentifying(true)` (`InputRouter.swift:33-34`), `Lifecycle.cleanUp` (`Lifecycle.swift:37`), `InjectionGate` na revogação (`InjectionGate.swift:51`), `apply` e `openPalette` chamam `releaseAll()`. 🟢
- **Retomada da injeção:** `repeatReleases(pendingKeyReleases)` repete `keyUp` como `forceUp` e `modifierUp` como `forceModifierUp`; os demais casos são ignorados (`ShortcutActions.swift:72-81`). 🟢
- **Paleta aberta:** o roteador envia `buttonDown`/`buttonUp` à paleta; o soltar de um botão pressionado antes da abertura não chega ao mapeador, que já foi zerado por `openPalette`. 🟢
- **Configuração trocada com botão segurado:** o mapeador novo não o tem em `held`; o soltar é ignorado e o próximo pressionar funciona. 🟢

## Dependências

- `entrada-do-controle`: `ButtonID`, `InputEvent`, `InputContext`. 🟢
- `injecao-de-eventos`: `KeyboardInjector`. 🟢
- `configuracao`: `ShortcutConfigValidation` (regras `pointerButtonNotAllowed`, `modifierHasAction`, `layerWithoutModifier`, `unknownKey`) e entrega da configuração aplicada. 🟢
- `paleta`: `PaletteActions.open()`. 🟢
- `log-de-diagnostico`: `LogEventCatalog.shortcutTriggered`. 🟢
- CoreFoundation Preferences (`CFPreferencesCopyAppValue`). 🟢

## Decisões de Design Identificadas

| Decisão | Evidência | Confiança |
|---------|-----------|-----------|
| Camadas com herança só da base e precedência do modificador mais antigo (003 RN-02, RN-03) | `ShortcutMapper.swift:121-126,161` | 🟢 |
| Ação decidida no pressionar (003 RN-01) | `resolved` | 🟢 |
| Atalho de sistema lido no uso, via cache do `cfprefsd` (003 D-11, RN-07) | `ShortcutActions.swift:112-117` | 🟢 |
| Tabela fixa nome ↔ tecla virtual (003 D-03) | `KeyCatalog.swift:25` | 🟢 |
| Padrões equivalentes ao protótipo 001, verificados por teste | `ShortcutDefaults.swift:3-4`, `ShortcutDefaultsTests` | 🟢 |
| Um único `KeyboardInjector` compartilhado com a paleta (002 D-05) | `AppDelegate` | 🟢 |
| Repetição compartilhada com a paleta (002 D-07) | `KeyRepeat.swift:5` | 🟢 |

## Estado Interno

| Onde | Campos |
|------|--------|
| `ShortcutMapper` | `held`, `modifierOrder`, `resolved`, `lastTrigger` |
| `ShortcutActions` | `mapper`, `repeatTimer`, `repeatingChord`, `systemChordsDown: [SystemShortcut: KeyChord]`, `onOpenPalette` |

Máquina de estados do botão no mapeador: `state-machines.md` §4. 🟢

## Observabilidade

`shortcut.triggered { button, layer, type }` em `info`. Carga e recusa de configuração ficam na unit `configuracao` (`shortcuts.loaded`, `shortcuts.rejected`). 🟢

## Riscos e Lacunas

- 🟢 L-01 fechada: o ditado é o atalho R3 → ⌘M do Raycast, por decisão do usuário (RN-AT-21); o atalho do transcritor precisa estar configurado no Raycast, fora do app.
- 🟢 DV-06: atalho de sistema desativado nas preferências posta o acorde padrão; comportamento aceito pelo usuário (RN-AT-22).
- 🟡 Dois botões com o mesmo acorde repetido: soltar um interrompe a repetição do outro, que continua pressionado.
- 🟡 Pressionar um segundo acorde com repetição encerra a repetição do primeiro, mesmo com o primeiro ainda segurado.
- 🟡 O cache do `cfprefsd` pode devolver o acorde antigo logo após uma mudança nas preferências.
- 🟡 Acorde lido das preferências não passa pelo catálogo: tecla fora da tabela é postada normalmente.
