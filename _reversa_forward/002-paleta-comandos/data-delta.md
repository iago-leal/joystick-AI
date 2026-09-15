# Data delta: Paleta de comandos pelo controle

> Identificador: `002-paleta-comandos`
> Data: `2026-09-14`
> Base: `_reversa_sdd/sdd/action-mapping.md#9. Modelo de Dados` e o código entregue pela feature 001
> Confidência: 🟢 salvo indicação

## 1. Persistência

Nenhuma. O arquivo `~/.config/joystick-ai/config.json` não muda e continua lido só na seção `pointer`. Nada é gravado em disco além das linhas novas do log (`interfaces/diagnostic-log.md`).

## 2. Tipos novos em `JoystickCore`

```
PaletteItem {                        // Sources/JoystickCore/Palette/CommandPalette.swift
  text: String                       // uma linha; 1 a 1.000 caracteres (RN-05)
  pressEnter: Bool                   // falso nos itens que terminam com espaço
}

CommandPalette.items: [PaletteItem]  // 17 itens fixos, na ordem de requirements.md §4

PaletteCloseReason: Enum             // circle | ps | disconnected | injection_suspended | idle
PaletteDirection: Enum               // up | down

PaletteMachine {                     // estado em memória, só na fila input
  isOpen: Bool                       // inicial: false
  selection: Int                     // índice 0-based; válido só com isOpen
  lastConfirmed: Int?                // inicial: nil; perdido ao encerrar o app (RF-08)
  repeating: PaletteDirection?       // direção em repetição, se houver
}

PaletteEffect: Enum
  render(PaletteSnapshot)
  startRepeat(PaletteDirection)
  stopRepeat
  confirm(index: Int, item: PaletteItem)
  closed(PaletteCloseReason)

PaletteSnapshot {                    // cópia imutável enviada à main thread (D-11)
  isOpen: Bool
  selection: Int
}

KeyRepeat {                          // Sources/JoystickCore/Shortcuts/KeyRepeat.swift (D-07)
  delay = 400 ms
  interval = 50 ms
}
```

## 3. Tipos alterados

| Tipo | Antes | Depois |
|------|-------|--------|
| `ShortcutAction` | `keyDown`, `keyUp`, `text`, `modifierDown`, `modifierUp` | Acrescenta `openPalette`. |
| `ShortcutMapper.press(_:)` | `.ps` devolve `[]` em todas as camadas | `.ps` devolve `[.openPalette]` na camada base e, por repasse, com L1 ou L2 segurados; com Options, `[]`. |
| `LaunchArguments` | sem campo da paleta | `paletteEnterDelayMs: Int?` (`nil` usa o padrão); `LaunchArgumentError.invalidPaletteEnterDelay(String)`. |
| `LogEventCatalog` | sem eventos da paleta | `paletteOpened`, `paletteConfirmed`, `paletteClosed`, `paletteBlocked`, `paletteInvalidArgs`. |

## 4. Transições da `PaletteMachine`

| Estado | Entrada | Novo estado | Efeitos |
|--------|---------|-------------|---------|
| fechada | `open()` | aberta, `selection = lastConfirmed ?? 0` | `render` |
| aberta | `press(.dpadUp)` / `press(.dpadDown)` | seleção −1 / +1, circular em 17 | `render`, `startRepeat(direção)` |
| aberta | `repeatTick()` com `repeating` | seleção na direção, circular | `render` |
| aberta | `release(.dpadUp)` / `release(.dpadDown)` da direção em repetição | `repeating = nil` | `stopRepeat` |
| aberta | `press(.cross)` | fechada, `lastConfirmed = selection` | `stopRepeat` se houver, `render`, `confirm(selection + 1, item)` |
| aberta | `press(.circle)` / `press(.ps)` | fechada | `stopRepeat` se houver, `render`, `closed(.circle)` / `closed(.ps)` |
| aberta | `close(motivo)` externo | fechada | `stopRepeat` se houver, `render`, `closed(motivo)` |
| aberta | `press` ou `release` de outro botão | inalterado | nenhum |
| fechada | qualquer entrada exceto `open()` | inalterado | nenhum |

Invariantes verificados em teste: `0 ≤ selection < 17` com a paleta aberta; `confirm` e `closed` são mutuamente exclusivos por fechamento; nenhum efeito é produzido com a paleta fechada.

## 5. Reflexo esperado na extração (para o `/reversa-sync`)

- `action-mapping` §9, `Action.type`: acrescentar o tipo conceitual `openPalette`.
- `action-mapping` §9: nova entidade `PaletteItem { text, pressEnter }`, fixa nesta entrega e editável na feature seguinte (`backlog-editor.md`).
- 🟡 Nenhuma migração prevista quando a paleta passar a ser configurável: a lista fixa vira o valor padrão da futura seção de paleta do arquivo.
