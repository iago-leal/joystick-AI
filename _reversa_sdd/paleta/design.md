# Paleta de comandos (palette), Design Técnico

> Gerado pelo Redator em 2026-09-15 · Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA

## Interface

### Núcleo (`CommandPalette.swift`)

| Tipo | Definição |
|------|-----------|
| `PaletteItem` | `text`, `pressEnter`, `label` (vazio exibe o texto); `displayText` |
| `PaletteDirection` | `up`, `down` |
| `PaletteCloseReason` | `circle`, `ps`, `disconnected`, `idle`, `injection_suspended`, `config_changed`, `identify` |
| `PaletteSnapshot` | `isOpen`, `selection` (base 0) |
| `PaletteEffect` | `render(snapshot)`, `startRepeat(direction)`, `stopRepeat`, `confirm(index base 1, item)`, `closed(reason)`, `openEditor` |
| `PaletteMachine` | `items` (não vazio, `precondition`), `isOpen`, `selection`, `lastConfirmed`, `repeating`; `editorEntryIndex = items.count`; `entryCount = items.count + 1`; `open()`, `press(_:)`, `release(_:)`, `repeatTick()`, `close(_:)` |

### App

| Membro | Observação |
|--------|------------|
| `PaletteActions.init(context:keyboard:enterDelayMs:items:)` | Fila `input` |
| `blocked` | Verdadeiro durante a tela de alvos (`AppDelegate.swift:178-181`) |
| `onRender`, `onOpenEditor`, `onItems` | Chamados na main |
| `open()`, `apply(items:)`, `handle(_:)`, `close(_:)`, `noteActivity()`, `isOpen` | — |
| `defaultEnterDelayMs = 0`, `idleTimeoutNs = 60 s`, `idleCheckInterval = 1 s` | Constantes |
| `PalettePanel(items:)`, `show(_ snapshot)`, `update(items:)` | Main thread |
| `PaletteView` | `fontSize 26`, `rowHeight 40`, `padding 16`, `markerWidth 40`, `minWidth 520`, fundo branco 0,1 com alfa 0,96, destaque `systemBlue`, separador branco 0,45 |

## Fluxo Principal

### Máquina (`CommandPalette.swift:86-178`)

```
open():      se aberta → []; isOpen ← true; selection ← lastConfirmed ?? 0; [render]
press(b):    se fechada → []
  ↑/↓   → step(dir); repeating ← dir; [render, startRepeat(dir)]
  ✕     → se selection = editorEntryIndex: finish() + [openEditor]
          senão lastConfirmed ← selection; finish() + [confirm(selection+1, item)]
  ○     → finish() + [closed(circle)]
  PS    → finish() + [closed(ps)]
  outro → []
release(b):  se fechada ou sem repetição → []; se b é o direcional repetido: repeating ← nil; [stopRepeat]
repeatTick(): se aberta e repetindo: step; [render]
close(r):    se aberta: finish() + [closed(r)]
step(dir):   selection ← (selection ± 1 + entryCount) mod entryCount
finish():    [stopRepeat se repetindo]; isOpen ← false; [render]
```

### Execução (`PaletteActions.swift`)

1. `open()`: se `blocked`, registra `palette.blocked` e retorna. Efeitos da máquina; vazios, retorna. Registra `palette.opened { selection base 1 }`, marca `lastInputNs`, liga o temporizador de inatividade e executa.
2. `handle`: só eventos de botão; `buttonDown` → `press`; `buttonUp` → `release`.
3. `perform`:
   - `render` → se fechou, desliga a inatividade; `onRender(snapshot)` na main → `PalettePanel.show`.
   - `startRepeat` → temporizador na fila `input` (400 ms, 50 ms, folga 5 ms) chamando `repeatTick`.
   - `stopRepeat` → cancela.
   - `confirm` → `palette.confirmed { index, enter }`; `type(item)`.
   - `closed` → `palette.closed { reason }`.
   - `openEditor` → `onOpenEditor` na main → `EditorWindowController.show(source: .palette)`.
4. `type(item)`: `keyboard.type(text, pressEnter: false)`; se `pressEnter`, com atraso 0 posta Return (acorde 36) imediatamente, senão agenda na fila `input` após `enterDelayMs`.
5. Inatividade: a cada 1 s (folga 100 ms), se aberta e `agora − lastInputNs ≥ 60 s`, `close(.idle)`.
6. `apply(items:)`: `close(.configChanged)`; nova `PaletteMachine(items:)`; `onItems` na main → `PalettePanel.update`.

### Roteamento (`InputRouter.swift:48-66`)

Botões: primeiro `ButtonActions`; depois `palette.noteActivity()`; aberta → `palette.handle`, fechada → `shortcuts.handle`. Eixos e toque: `noteActivity` e movimento. Desconexão: `palette.close(.disconnected)` antes dos demais. 🟢

### Painel (`PalettePanel.swift`)

- Criação: `NSPanel` `[.borderless, .nonactivatingPanel]`, `level .statusBar`, `collectionBehavior [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]`, `ignoresMouseEvents`, `hidesOnDeactivate false`, sem opacidade, com sombra, sem animação; `canBecomeKey` e `canBecomeMain` falsos.
- `show(snapshot)`: fechada → `orderOut`; aberta e invisível → `place()`; `selection`; `orderFrontRegardless()`.
- `place()`: tela que contém `NSEvent.mouseLocation` (ou `NSScreen.main`); `fit(maxHeight: visível − 48, maxWidth: visível − 48)`; centraliza na área visível.
- `fit`: `visibleRows = max(1, min(entradas, ⌊(altura − 32) / 40⌋))`; largura = `min(max(520, 40 + maior texto + 48), max(520, maxWidth))`; altura = `linhas · 40 + 32`.
- `draw`: fundo arredondado (raio 14); separador antes de "Editar atalhos"; seleção com retângulo azul (raio 8), marcador ▶ e peso *semibold*; texto truncado no fim.

## Fluxos Alternativos

- **Paleta aberta pelo editor ou pela tela de alvos:** não existe; a paleta só abre por ação de atalho. 🟢
- **Injeção suspensa:** `InjectionGate` fecha com `injection_suspended` (`InjectionGate.swift:49`). 🟢
- **Modo de identificação:** `InputRouter.setIdentifying(true)` fecha com `identify`. 🟢
- **Item confirmado com a injeção desligada:** o log registra `palette.confirmed`, mas `KeyboardInjector` descarta o texto. 🟡

## Dependências

- `atalhos`: ação `openPalette`, `KeyRepeat`, soltura prévia das teclas. 🟢
- `injecao-de-eventos`: `KeyboardInjector.type`, `chordDown/Up`. 🟢
- `configuracao`: lista validada (1 a 50 itens, texto de 1 a 1.000 caracteres em uma linha, rótulo até 80) e `onApply`. 🟢
- `editor`: `EditorWindowController.show(source: .palette)`. 🟢
- `aplicativo`: `LaunchArguments.paletteEnterDelayMs` (0 a 500). 🟢
- `log-de-diagnostico`: `palette.opened`, `palette.confirmed`, `palette.closed`, `palette.blocked`, `palette.invalid_args`. 🟢
- AppKit (`NSPanel`, `NSView`). 🟢

## Decisões de Design Identificadas

| Decisão | Evidência | Confiança |
|---------|-----------|-----------|
| Máquina pura com efeitos (002 D-01) | `CommandPalette.swift:82-86` | 🟢 |
| Abrir solta as teclas mantidas (002 D-02, D-04) | `ShortcutActions.swift:98-100` | 🟢 |
| Painel não ativador e transparente ao mouse (002 D-08, ADR-010) | `PalettePanel.swift:4-27` | 🟢 |
| Legibilidade a 3 m (002 D-09) | `PalettePanel.swift:61-72` | 🟢 |
| Posição pela tela do cursor, só na abertura (002 D-10) | `PalettePanel.swift:49-58` | 🟢 |
| Estado na fila `input`, cópias à main (002 D-11) | `PaletteActions.swift:6` | 🟢 |
| Bloqueio na tela de alvos (002 D-13) | `AppDelegate.swift:177-181` | 🟢 |
| Nenhum item padrão envia Enter (emenda E001) | `CommandPalette.swift:34-36` | 🟢 |
| Entrada fixa fora da contagem de 1 a 50 (003 D-13) | `CommandPalette.swift:84-85` | 🟢 |

## Estado Interno

| Onde | Campos |
|------|--------|
| `PaletteMachine` | `isOpen`, `selection`, `lastConfirmed`, `repeating` |
| `PaletteActions` | `machine`, `repeatTimer`, `idleTimer`, `lastInputNs`, `blocked`, `enterDelayMs` |
| `PaletteView` | `items`, `selection`, `visibleRows`, `firstVisible` |

Máquina de estados: `state-machines.md` §3. 🟢

## Observabilidade

`palette.opened { selection }`, `palette.confirmed { index, enter }`, `palette.closed { reason }`, `palette.blocked { reason: targets }`, `palette.invalid_args { message }`. Nenhum texto de item. 🟢

## Riscos e Lacunas

- 🟡 DV-07: confirmação e abertura do editor fecham sem `palette.closed`; análises que contam fechamentos precisam somar `palette.confirmed` e `editor.opened { source: palette }`.
- 🟡 O Enter agendado com atraso é postado mesmo que o foco mude ou a injeção seja revogada no intervalo (neste caso é descartado).
- 🟡 Com a paleta aberta, um botão pressionado antes da abertura e solto depois não chega aos atalhos; isso é seguro porque a abertura já soltou tudo.
- 🟡 O painel não se reposiciona se a tela mudar com a paleta aberta.
