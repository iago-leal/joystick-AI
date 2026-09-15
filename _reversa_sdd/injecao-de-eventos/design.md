# Injeção de eventos (injection), Design Técnico

> Gerado pelo Redator em 2026-09-15 · Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA

## Interface

Todas as chamadas ocorrem na fila `input`. 🟢

### `EventInjector`

| Símbolo | Assinatura | Retorno | Observação |
|---------|-----------|---------|------------|
| `sourceMark` | `static let Int64 = 0x4A4F_5953` | — | "JOYS"; lido pelo editor e pela tela de alvos |
| `eventSource` | `CGEventSource?` | — | `.hidSystemState`, compartilhado com os outros injetores |
| `enabled` | `var Bool = false` | — | Alterado só pelo `InjectionGate` |
| `screens` | `var ScreenUnion` | — | Alterado pelo `DisplayMonitor` |
| `currentLocation()` | `()` | `ScreenPoint` | RN-IN-03 |
| `move(by:kind:origin:tArrival:)` | `(PointDelta, MoveKind, PostSource?, UInt64?)` | `Void` | RN-IN-04 |
| `post(_:tArrival:)` | `(MouseAction, UInt64)` | `Void` | Origem `button` |
| `activationClick(at:)` | `(CGPoint)` | `Void` | RN-IN-15 |
| `deliver(_:)` | `(CGEvent)` | `Void` | Marca e posta, sem log |
| `deliver(_:kind:button:origin:clickState:tArrival:)` | — | `Void` | Marca, posta e registra se houver origem e `tArrival` |

`PostedKind` ∈ {`move`, `drag`, `scroll`, `down`, `up`}; `PostSource` ∈ {`touch`, `stick_onset`, `button`} (`LogEventCatalog`).

### `KeyboardInjector`

| Símbolo | Assinatura | Observação |
|---------|-----------|------------|
| `modifierDown(_:)` / `modifierUp(_:)` | `(KeyModifier)` | Contagem de referência |
| `chordDown(_:)` / `chordUp(_:)` | `(KeyChord)` | RN-IN-09 |
| `chordRepeat(_:)` | `(KeyChord)` | `keyDown` com autorepeat |
| `forceUp(_:)` / `forceModifierUp(_:)` | `(KeyChord)` / `(KeyModifier)` | RN-IN-13 |
| `type(_:pressEnter:)` | `(String, Bool)` | RN-IN-12 |

### `ScrollInjector`

| Símbolo | Assinatura | Observação |
|---------|-----------|------------|
| `unit` | `ScrollUnit` | Definido na abertura por `--scroll-unit` |
| `scroll(vertical:horizontal:origin:tArrival:)` | `(Int32, Int32, PostSource?, UInt64?)` | RN-IN-14 |

## Fluxo Principal

### Posição de partida (`EventInjector.swift:38-62`)

```
currentLocation():
  actual ← CGEvent(source: nil).location          // (0,0) se nil
  se trackedPosition ≠ nil e agora − lastPostNs < 100 ms e recentPositions contém actual:
      devolve trackedPosition
  trackedPosition ← nil; recentPositions ← [actual]; devolve actual

track(p):
  trackedPosition ← p; recentPositions.append(p) (mantém as 32 últimas); lastPostNs ← agora
```

### Movimento (`:65-87`)

1. Se desligado, retorna.
2. `from = currentLocation()`; `to = from + delta`; se há telas, `to = screens.clamp(to)`.
3. Tipo e botão: `move` → `mouseMoved`/esquerdo (sem botão no log); `leftDrag` → `leftMouseDragged`/esquerdo; `rightDrag` → `rightMouseDragged`/direito.
4. `CGEvent(mouseEventSource:mouseType:mouseCursorPosition: to, mouseButton:)`; `mouseEventDeltaX = round(to.x − from.x)`, `mouseEventDeltaY = round(to.y − from.y)`.
5. `track(to)`; `deliver(kind: move|drag, button, origin, clickState: nil, tArrival)`.

### Clique (`:89-108`)

1. Se desligado, retorna.
2. `.down(b, s)` → `leftMouseDown`/`rightMouseDown`, `kind down`; `.up(b, s)` → `leftMouseUp`/`rightMouseUp`, `kind up`.
3. Posição = `currentLocation()`; `mouseEventClickState = s`; `deliver(origin: .button, clickState: s)`.

### Teclado (`KeyboardInjector.swift`)

- `modifierDown(m)`: `count[m] += 1`; se ficou 1, `postModifier(m, down: true)`.
- `modifierUp(m)`: se `count[m]` ausente ou 0, retorna; decrementa; se era 1, `postModifier(m, down: false)`.
- `postModifier`: se ligado, `CGEvent(keyboardEventSource:virtualKey: código(m), keyDown:)`, `type = .flagsChanged`, `flags = heldFlags` (após a alteração da contagem), `deliver`.
- `postKey(chord, down, autorepeat)`: se ligado, evento com `chord.keyCode`; `flags = heldFlags ∪ (seta ? [numericPad, secondaryFn] : [])`; autorepeat → campo `keyboardEventAutorepeat = 1`; `deliver`.
- `chordDown`: `modifierDown` de cada modificador ordenado (⌃⌥⇧⌘), `postKey(down)`. `chordUp`: `postKey(up)`, `modifierUp` em ordem inversa.
- `forceUp`: `postKey(up)`; `forceModifierUp` em ordem inversa, que só posta se a contagem é zero.
- `type`: se desligado, retorna; para cada unidade de `text.utf16`, `down` e `up` com `virtualKey 0`, `keyboardSetUnicodeString(1, &unidade)`, `flags = []`, `deliver`; se `pressEnter`, `chordDown` e `chordUp` de `KeyChord(36)`.

Mapa de flags: ⌘ `maskCommand`, ⇧ `maskShift`, ⌥ `maskAlternate`, ⌃ `maskControl`.

### Rolagem (`ScrollInjector.swift:15-22`)

Se desligado ou `(0, 0)`, retorna; `CGEvent(scrollWheelEvent2Source:units: pixel|line, wheelCount: 2, wheel1: vertical, wheel2: horizontal, wheel3: 0)`; `deliver(kind: .scroll, origin, tArrival)`.

## Fluxos Alternativos

- **Clique de ativação** (`EventInjector.swift:115-131`): se desligado, retorna; `from = currentLocation()`; posta `leftMouseDown` e `leftMouseUp` (`clickState 1`) em `point` sem registro; posta `mouseMoved` em `from`; `track(point)` e `track(from)`. 🟢
- **Falha na criação do `CGEvent`:** a operação retorna em silêncio; no clique de ativação, um `down` pode sair sem `up` se o segundo evento falhar. 🟡

## Dependências

- CoreGraphics (`CGEvent`, `CGEventSource`). 🟢
- `ponteiro`: `ScreenUnion`, `MouseAction`, `MoveKind`, `PointDelta`, `ScrollUnit`. 🟢
- `atalhos`: `KeyChord`, `KeyModifier`. 🟢
- `log-de-diagnostico`: `LogEventCatalog.pointerPosted`, `MonotonicClock`. 🟢

## Decisões de Design Identificadas

| Decisão | Evidência no código | Confiança |
|---------|---------------------|-----------|
| `.cghidEventTap` com `.hidSystemState` e marca própria (ADR-005) | `EventInjector.swift:10,28,134-142` | 🟢 |
| Posição acompanhada por causa da leitura atrasada do sistema (achado da Fase 2) | `EventInjector.swift:31-37` | 🟢 |
| Contagem de modificadores num injetor único compartilhado (002 D-05) | `KeyboardInjector.swift:10-11` | 🟢 |
| Texto por `unicodeString` e não por códigos de tecla | `KeyboardInjector.swift:78-94` | 🟢 |
| Máscaras de seta para Mission Control | `KeyboardInjector.swift:110-111` | 🟢 |

## Estado Interno

| Onde | Campos |
|------|--------|
| `EventInjector` | `enabled`, `screens`, `trackedPosition: ScreenPoint?`, `recentPositions: [ScreenPoint]` (≤ 32), `lastPostNs: UInt64` |
| `KeyboardInjector` | `modifierCounts: [KeyModifier: Int]` |
| `ScrollInjector` | `unit` (imutável) |

## Observabilidade

`pointer.posted { kind, source, button?, clickState?, t_arrival, t_posted }` em debug, só com origem. Nenhum registro de teclado ou texto. 🟢

## Riscos e Lacunas

- 🟡 Caracteres fora do BMP saem como duas metades de par substituto, cada uma num par de eventos.
- 🟡 Com a injeção desligada, `modifierDown` incrementa a contagem sem postar; após a retomada, a tecla seguinte pode sair sem o modificador que o botão ainda segura.
- 🟡 O texto sai com `flags` vazias, mas um modificador mantido por `flagsChanged` anterior pode continuar ativo no estado do sistema e alterar o efeito do caractere.
