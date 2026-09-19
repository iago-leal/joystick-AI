# Data delta: Controle Ipega ao lado do DualSense

> Identificador: `007-controle-ipega`
> Data: `2026-09-19`
> Base: `_reversa_sdd/architecture.md#5. Modelo de dados em arquivo`, `_reversa_sdd/data-dictionary.md` e o código de `InputEvent.swift`, `ShortcutConfigValidation.swift`, `ShortcutDefaults.swift`, `FigureState.swift` e `LogEventCatalog.swift` em 2026-09-19
> Confidência: 🟢 salvo indicação

## 1. Persistência

| Arquivo | Antes | Depois |
|---------|-------|--------|
| `~/.config/joystick-ai/config.json` | Chaves de botão: os 18 `rawValue` de `ButtonID` | Mais `share`, aceito em `shortcuts.layers.<camada>` como gatilho, como nome de camada quando for modificador, e em `shortcuts.modifiers`. `shortcuts.version` segue 1 |
| `~/Library/Logs/joystick-ai/poc-*.jsonl` | `logSchema` 1 | Idêntico, com o campo aditivo `model` em `controller.connected` e o valor `unsupported_model` em `controller.ignored` (ver `interfaces/diagnostic-log.md`) |

Exemplo de configuração com o Share como gatilho e como modificador:

```json
"shortcuts": {
  "version": 1,
  "modifiers": { "share": ["command"] },
  "layers": {
    "base": { "circle": { "type": "text", "text": "CONTINUAR", "pressEnter": true } },
    "share": { "cross": { "type": "systemShortcut", "name": "missionControl" } }
  }
}
```

**Compatibilidade:** arquivos existentes são lidos sem mudança. O documento padrão ("Restaurar padrão" e ausência de arquivo) é idêntico ao anterior, porque `share` fica fora do laço que grava "nenhuma" na camada Options (D-02). Um arquivo com `share` é recusado por versões anteriores à feature com `wrongType` no caminho do botão; não há migração.

## 2. Núcleo

| Item | Antes | Depois |
|------|-------|--------|
| `ButtonID` | 18 casos, `dpadRight` por último | 19 casos, `share` por último; `displayName` `"Share"` |
| `ShortcutConfig.pointerButtons` | R1, R2, `touchpadClick` | Igual |
| `ShortcutDefaults.config` | — | Igual; `share` sem ação em todas as camadas |
| `ControllerModel` | — | Novo: `dualSense`, `ipega`; pares (fabricante, produtos): (0x054C, {0x0CE6, 0x0DF2}) e (0x057E, {0x2009}); `classify(productCategory:isDualSenseProfile:hidDevices:)` |
| `ControllerInfo` | `id`, `name`, `connection`, `connectedAt`, `atStartup` | Mais `model: ControllerModel` |
| `ActiveControllerRegistry.connect` | `(key:info:isDualSense:)` | `(key:info:accepted:)`; lógica igual |
| `SwitchProReport` | — | Novo: `homeButton(reportID:bytes:) -> Bool?`, relatório `0x30` com ≥ 13 bytes, bit `0x10` do byte 4 |
| `FigureState` | `layer`, `buttons` (18) | Mais `controller` (`"dualSense"` ou `"ipega"`); `buttons` com 19 itens; com `ipega`, resumo do `touchpadClick` = `"ausente neste controle"` |
| `ButtonCoverage` | Esperado: `ButtonID.allCases` | Esperado por modelo: DualSense sem `share`; Ipega sem `touchpadClick`; DualSense quando o log não traz `model` |

## 3. Tabela de correspondência do Ipega

| Elemento da interface de controles | Botão físico do Ipega | `ButtonID` |
|-----------------------------------|-----------------------|------------|
| `buttonA` | baixo (A) | `cross` |
| `buttonB` | direita (B) | `circle` |
| `buttonX` | esquerda (X) | `square` |
| `buttonY` | cima (Y) | `triangle` |
| `leftShoulder`, `rightShoulder` | L, R | `l1`, `r1` |
| `leftTrigger`, `rightTrigger` | ZL, ZR (digitais) | `l2`, `r2` |
| `leftThumbstickButton`, `rightThumbstickButton` | cliques dos analógicos | `l3`, `r3` |
| `buttonOptions` | Select (−) | `create` |
| `buttonMenu` | Start (+) | `options` |
| `buttonHome` e HID `0x30` byte 4 bit `0x10` | Home | `ps` |
| `physicalInputProfile.buttons[GCInputButtonShare]` | Share (captura) | `share` |
| `dpad.up/down/left/right` | direcional | `dpadUp/Down/Left/Right` |
| — | Android, iOS, Turbo, Clear | não chegam ao Mac |

## 4. Migrações

n/a.
