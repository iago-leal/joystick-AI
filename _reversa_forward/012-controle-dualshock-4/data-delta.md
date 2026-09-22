# Data delta: Controle DualShock 4 ao lado do DualSense e do Ipega

> Identificador: `012-controle-dualshock-4`
> Data: `2026-09-22`
> Base: `_reversa_sdd/architecture.md#5. Modelo de dados em arquivo`, `_reversa_sdd/data-dictionary.md`, `_reversa_sdd/addenda/007-controle-ipega.md` e o código de `ControllerModel.swift`, `DualSenseReport.swift`, `SwitchProReport.swift`, `InputEvent.swift`, `FigureState.swift`, `LogAnalysis.swift` e `LogEventCatalog.swift` em 2026-09-22
> Confidência: 🟢 salvo indicação

## 1. Persistência

| Arquivo | Antes | Depois |
|---------|-------|--------|
| `~/.config/joystick-ai/config.json` | 19 chaves de botão (`ButtonID`), `shortcuts.version` 1 | **Idêntico.** O DualShock 4 usa os 18 identificadores do DualSense; nenhuma chave, seção ou versão nova |
| `~/Library/Logs/joystick-ai/poc-*.jsonl` | `logSchema` 1; `model` em `controller.connected` com `dualSense` ou `ipega` | Idêntico, com o valor novo `dualShock4` em `model` (ver `interfaces/diagnostic-log.md`) |
| `~/.config/joystick-ai/target-runs/*.json` | — | Sem mudança |

**Compatibilidade:** arquivos existentes são lidos sem mudança e nenhum é reescrito. O documento padrão ("Restaurar padrão" e ausência de arquivo) é idêntico ao anterior. Não há migração.

## 2. Núcleo

| Item | Antes | Depois |
|------|-------|--------|
| `ControllerModel` | `dualSense`, `ipega`; pares (0x054C, {0x0CE6, 0x0DF2}) e (0x057E, {0x2009}) | Mais `dualShock4`, com o par (0x054C, {0x05C4, 0x09CC}); `rawValue` `"dualShock4"`. O adaptador 0x0BA0 fica fora (D-01) |
| `ControllerModel.SystemProfile` | — | Novo: `dualSense`, `dualShock`, `extended`; substitui o booleano `isDualSenseProfile` |
| `ControllerModel.classify` | `(productCategory:isDualSenseProfile:hidDevices:)` | `(productCategory:profile:hidDevices:)`; `dualShock4` quando `profile == .dualShock` e `hidDevices` contém um par do modelo; os outros casos como antes |
| `ControllerModel.buttons` | DualSense sem `share`; Ipega sem `touchpadClick` | Mais `dualShock4` sem `share` (os mesmos 18 do DualSense) |
| `DualShock4Report` | — | Novo: `homeButton(reportID:bytes:) -> Bool?`; relatório `0x01` com ≥ 10 bytes, bit 0 do byte 7; relatório `0x11` com ≥ 12 bytes, bit 0 do byte 9; outros, `nil` 🟡 (índices confirmados na P-02) |
| `ControllerInfo.model` | `dualSense` ou `ipega` | Mais `dualShock4`; padrão do inicializador continua `.dualSense` |
| `FigureState.controller` | `"dualSense"` ou `"ipega"` | Mais `"dualShock4"`; com esse valor o `touchpadClick` tem resumo normal (o `absentSummary` continua só do Ipega) |
| `ButtonCoverage.model` / `expected` | Por modelo do último `controller.connected` | Mais `dualShock4` → 18 sem `share` |
| `ButtonID`, `ShortcutConfig`, `ShortcutDefaults`, `ChargeDisplay`, `ControllerCharge`, `ActiveControllerRegistry` | — | Sem mudança |

## 3. Tabela de correspondência do DualShock 4

| Elemento da interface de controles | Botão físico do DualShock 4 | `ButtonID` | Nome na figura |
|-----------------------------------|-----------------------------|------------|----------------|
| `buttonA` | ✕ | `cross` | ✕ |
| `buttonB` | ○ | `circle` | ○ |
| `buttonX` | □ | `square` | □ |
| `buttonY` | △ | `triangle` | △ |
| `leftShoulder`, `rightShoulder` | L1, R1 | `l1`, `r1` | L1, R1 |
| `leftTrigger`, `rightTrigger` (analógicos, limiar 0,5) | L2, R2 | `l2`, `r2` | L2, R2 |
| `leftThumbstickButton`, `rightThumbstickButton` | L3, R3 | `l3`, `r3` | L3, R3 |
| `buttonOptions` 🟡 (P-01) | Share | `create` | Create |
| `buttonMenu` | Options | `options` | Options |
| `buttonHome` e HID (`DualShock4Report`) | PS | `ps` | PS |
| `GCDualShockGamepad.touchpadButton` | clique do touchpad | `touchpadClick` | Touchpad |
| `dpad.up/down/left/right` | direcional | `dpadUp/Down/Left/Right` | direcional |
| `GCDualShockGamepad.touchpadPrimary`, `touchpadSecondary` | touchpad (dois dedos) | `.touch(0)`, `.touch(1)` | — |
| `leftThumbstick`, `rightThumbstick` | analógicos | `.leftStick`, `.rightStick` | — |
| — | botões traseiros e de firmware do GameSir; vibração, luz, sensores | não chegam ou não são lidos (RN-11) | — |

O identificador `share` (botão de captura do Ipega) não é usado pelo DualShock 4.

## 4. Relatórios HID lidos pelo app

| Modelo | Relatório | Tamanho mínimo | Campo lido | Índice |
|--------|-----------|----------------|------------|--------|
| DualSense | `0x01` | 64 | PS | byte 10, bit 0 |
| DualSense | `0x31` | 12 | PS | byte 11, bit 0 |
| DualSense | `0x01` | 10 (exato) | PS | byte 7, bit 0 |
| Ipega | `0x30` | 13 | Home; analógicos | byte 4, bit `0x10`; bytes 6 a 11 |
| **DualShock 4** | `0x01` | 10 | PS | byte 7, bit 0 🟡 |
| **DualShock 4** | `0x11` | 12 | PS | byte 9, bit 0 🟡 |

Nenhum outro campo do relatório do DualShock 4 é examinado: eixos, toque, bateria e sensores continuam fora do leitor HID (RN-11; a carga vem da interface de controles, D-09).

## 5. Migrações

n/a.
