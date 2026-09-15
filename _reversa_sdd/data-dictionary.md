# Dicionário de dados — joystick-AI

> Gerado pelo Arqueólogo em 2026-09-15 · Nível: completo
> Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA
> Não há banco de dados. Os dados persistidos são três formatos de arquivo (seções 7, 9 e 10); os demais são estruturas em memória.

## Índice

1. [Entrada do controle](#1-entrada-do-controle)
2. [Ponteiro](#2-ponteiro)
3. [Atalhos](#3-atalhos)
4. [Paleta](#4-paleta)
5. [Configuração em memória](#5-configuração-em-memória)
6. [Editor](#6-editor)
7. [Arquivo `config.json`](#7-arquivo-configjson)
8. [Argumentos de abertura](#8-argumentos-de-abertura)
9. [Log de diagnóstico (JSONL)](#9-log-de-diagnóstico-jsonl)
10. [Resultado da tela de alvos](#10-resultado-da-tela-de-alvos)
11. [Análise](#11-análise)
12. [Constantes de domínio](#12-constantes-de-domínio)

---

## 1. Entrada do controle

### 1.1 `ButtonID` (enum, `String`, ordenável) 🟢

`JoystickCore/Input/InputEvent.swift:4`. A ordem de declaração define a comparação e a ordem estável das solturas.

| Valor | Elemento físico | Elemento `GCDualSenseGamepad` |
|-------|-----------------|-------------------------------|
| `cross` | ✕ | `buttonA` |
| `circle` | ○ | `buttonB` |
| `square` | □ | `buttonX` |
| `triangle` | △ | `buttonY` |
| `l1`, `r1` | ombros | `leftShoulder`, `rightShoulder` |
| `l2`, `r2` | gatilhos (≥ 0,5) | `leftTrigger`, `rightTrigger` |
| `l3`, `r3` | clique dos analógicos | `leftThumbstickButton`, `rightThumbstickButton` |
| `options` | Options | `buttonMenu` 🟢 confirmado no hardware (P-05) |
| `create` | Create | `buttonOptions` 🟢 confirmado no hardware (P-05) |
| `ps` | PS | `buttonHome` e relatório HID bruto |
| `touchpadClick` | clique do touchpad | `touchpadButton` |
| `dpadUp`, `dpadDown`, `dpadLeft`, `dpadRight` | direcional | `dpad.up/down/left/right` |

### 1.2 Enums auxiliares 🟢

| Tipo | Valores | Local |
|------|---------|-------|
| `ButtonPhase` | `down`, `up` | `InputEvent.swift:15` |
| `TouchPhase` | `began`, `moved`, `ended` | `InputEvent.swift:20` |
| `ConnectionType` | `usb`, `bluetooth`, `unknown` | `InputEvent.swift:24` |
| `ConnectionSource` | `enumeration`, `notification` | `StartupAdoption.swift:4` |
| `InputElement` | `button(ButtonID)`, `leftStick`, `rightStick`, `touch(Int)` | `InputEvent.swift:48` |
| `InputEventKind` | `controllerConnected`, `controllerDisconnected`, `buttonDown`, `buttonUp`, `axis`, `touch`, `controllerError` | `InputEvent.swift:55` |

### 1.3 `ControllerInfo` (struct) 🟢

`InputEvent.swift:29`.

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|:-:|-----------|
| `id` | `UUID` | ✔ | Gerado a cada conexão; identifica o controle no log |
| `name` | `String` | ✔ | `vendorName`, ou "DualSense" |
| `connection` | `ConnectionType` | ✔ | Pelo IORegistry, por exclusão |
| `connectedAt` | `UInt64` (ns) | ✔ | `t_arrival` da conexão; ordena a fila |
| `atStartup` | `Bool` | ✔ | Enumeração inicial ou chegada em menos de 2 s do início |

### 1.4 `InputEvent` (struct) 🟢

`InputEvent.swift:63`. Entregue sempre na fila `input`.

| Campo | Tipo | Padrão | Descrição |
|-------|------|--------|-----------|
| `kind` | `InputEventKind` | — | Tipo |
| `element` | `InputElement?` | `nil` | Origem |
| `value` | `Double?` | `nil` | Gatilhos, de 0 a 1 |
| `x`, `y` | `Double?` | `nil` | Analógico com zona morta ou toque em [-1, 1]; **nunca** vão ao log |
| `touchIndex` | `Int?` | `nil` | 0 ou 1 |
| `touchPhase` | `TouchPhase?` | `nil` | Fase do toque |
| `synthetic` | `Bool` | `false` | `buttonUp` gerado na desconexão (RN-04) |
| `timestamp` | `UInt64` | — | `t_arrival` em ns de `CLOCK_UPTIME_RAW` |
| `frameworkTimestamp` | `Double?` | `nil` | `lastEventTimestamp` do perfil, informativo |

### 1.5 `ActiveControllerRegistry<Key>` (struct genérica) 🟢

`ActiveControllerRegistry.swift:7`. No app, `Key = ObjectIdentifier`.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `entries` | `[(Key, ControllerInfo)]` (privado) | Fila por ordem de chegada; o primeiro é o ativo |
| `pressed` | `Set<ButtonID>` | Botões pressionados do ativo |
| `ConnectOutcome` | `active`, `queued(position)`, `duplicate`, `ignored` | Resultado da conexão |
| `DisconnectOutcome` | `removed`, `wasActive`, `syntheticReleases`, `promoted` | Resultado da desconexão |

### 1.6 `InputContext` (classe, app) 🟢

`JoystickAIPoC/Controller/InputSink.swift:25`. Estado compartilhado da fila `input`: `queue`, `log`, `registry`, `settings: PointerSettings`, `sink: InputSink`.

---

## 2. Ponteiro

### 2.1 `PointerSettings` (struct, `Codable`) 🟢

`JoystickCore/Pointer/PointerSettings.swift:4`. Seção `pointer` do arquivo, lida só no início.

| Campo | Tipo | Padrão | Faixa aceita | Uso |
|-------|------|--------|--------------|-----|
| `touchpadSensitivity` | `Double` | 1,0 | 0,1 – 5,0 | Multiplica 400 pt por unidade normalizada |
| `stickMaxSpeed` | `Double` | 1500 | 150 – 7500 | pt/s com o analógico no máximo |
| `stickExponent` | `Double` | 2,0 | 0,5 – 4,0 | Curva `m^e` |
| `deadzone` | `Double` | 0,12 | 0,0 – 0,5 | Zona morta por eixo |
| `scrollSpeed` | `Double` | 40 | 1 – 1000 | Linhas/s (×20 em pixel) |
| `invertScrollY` | `Bool` | `false` | — | Inverte a rolagem vertical |
| `precisionFactor` | `Double` | 0,3 | 0,05 – 1,0 | Fator com só L1 pressionado |
| `doubleClickIntervalMs` | `Int` | 400 | 100 – 2000, inteiro | Janela do duplo clique |

Valor ausente ou `null` mantém o padrão sem aviso; fora da faixa, de tipo errado ou fracionário em campo inteiro é recusado com `config.value_rejected` (`PointerSettingsValidation.swift:16-49`).

### 2.2 Geometria 🟢

| Tipo | Campos | Descrição | Local |
|------|--------|-----------|-------|
| `ScreenPoint` | `x`, `y: Double` | Coordenadas globais, origem superior esquerda, pt | `Geometry.swift:4` |
| `ScreenRect` | `x`, `y`, `width`, `height: Double` | Retângulo global; `maxX`/`maxY` exclusivos | `Geometry.swift:15` |
| `ScreenUnion` | `rects: [ScreenRect]` | União das telas ativas; `contains`, `clamp` | `ScreenUnion.swift:4` |
| `PointDelta` | `dx`, `dy: Double` | Deslocamento; soma e escala | `StickKinematics.swift:4` |

### 2.3 Estado do movimento 🟢

| Tipo | Campos | Local |
|------|--------|-------|
| `PointerState` | `leftStick`, `rightStick` (x, y), `pendingTouchDelta`, `subpixel: SubpixelAccumulator`, `timerRunning` | `PointerMotionEngine.swift:5` |
| `MotionOutput` | `move: PointDelta?`, `timer: TimerCommand` (`none`/`start`/`stop`), `stickOnset`, `scrollOnset` | `PointerMotionEngine.swift:19` |
| `SubpixelAccumulator` | `remainder: PointDelta` | `StickKinematics.swift:45` |
| `TouchpadTracker` | `contacts: Set<Int>`, `primary: Int?`, `baseline: (x, y)?` (privados) | `TouchpadTracker.swift:6` |
| `ZeroTransitionPhaseInference` | `touching: Bool` | `TouchpadTracker.swift:61` |
| `ScrollMapper` | `unit: ScrollUnit`, `settings`, `remainder: (vertical, horizontal)` | `ScrollMapper.swift:11` |

### 2.4 Cliques 🟢

| Tipo | Valores / campos | Local |
|------|------------------|-------|
| `MouseButton` | `left`, `right` | `ClickStateMachine.swift:3` |
| `MouseAction` | `down(MouseButton, clickState)`, `up(MouseButton, clickState)` | `ClickStateMachine.swift:9` |
| `MoveKind` | `move`, `leftDrag`, `rightDrag` | `ClickStateMachine.swift:14` |
| `ScrollUnit` | `pixel`, `line` | `ScrollMapper.swift:3` |
| `ClickStateMachine` | `settings`, `heldMouseButtons: Set<MouseButton>`, `leftHolders: Set<ButtonID>`, `lastLeftClick: (timeNs, point, clickState)?` (só em memória) | `ClickStateMachine.swift:20` |

---

## 3. Atalhos

### 3.1 `KeyModifier` (enum, ordenável) 🟢

`ShortcutMapper.swift:4`. Ordem do macOS: `control` (⌃, kVK 59), `option` (⌥, 58), `shift` (⇧, 56), `command` (⌘, 55).

### 3.2 `KeyChord` (struct, `Hashable`) 🟢

`ShortcutMapper.swift:13`.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `keyCode` | `UInt16` | Tecla virtual `kVK_*` (posição física) |
| `modifiers` | `Set<KeyModifier>` | Modificadores do acorde |

Constantes: `returnKey` 36, `tab` 48, `space` 49, `grave` 50, `delete` 51, `escape` 53, `m` 46, setas 123–126; `isArrow` para 123…126.

### 3.3 `KeyEntry` e `KeyGroup` 🟢

`KeyCatalog.swift:4-23`. `KeyEntry(name, keyCode, display, group)`; `KeyGroup` ∈ {`letters`, `digits`, `punctuation`, `editing`, `navigation`, `function`}. Catálogo fixo de 73 teclas:

| Grupo | Nomes gravados no arquivo |
|-------|---------------------------|
| `letters` | `a` … `z` |
| `digits` | `0` … `9` |
| `punctuation` | `minus`, `equal`, `leftBracket`, `rightBracket`, `backslash`, `semicolon`, `quote`, `comma`, `period`, `slash`, `grave` |
| `editing` | `return`, `tab`, `space`, `delete`, `forwardDelete`, `escape` |
| `navigation` | `upArrow`, `downArrow`, `leftArrow`, `rightArrow`, `home`, `end`, `pageUp`, `pageDown` |
| `function` | `f1` … `f12` |

### 3.4 `SystemShortcut` (enum, `Int`) 🟢

`ShortcutMapper.swift:38`. O valor bruto é a chave em `AppleSymbolicHotKeys`.

| Caso | Id | Nome no arquivo | Rótulo | Acorde padrão |
|------|----|-----------------|--------|---------------|
| `nextWindow` | 27 | `nextWindow` | próxima janela | ⌘\` |
| `missionControl` | 32 | `missionControl` | Mission Control | ⌃↑ |
| `applicationWindows` | 33 | `applicationWindows` | janelas do aplicativo | ⌃↓ |
| `spaceLeft` | 79 | `spaceLeft` | mesa à esquerda | ⌃← |
| `spaceRight` | 81 | `spaceRight` | mesa à direita | ⌃→ |

### 3.5 `TriggerAction` e `TriggerActionType` 🟢

`ShortcutConfig.swift:4-28`.

| Caso | Dados | `type` no log | Restrições |
|------|-------|---------------|------------|
| `chord` | `KeyChord`, `repeats: Bool` | `chord` | Tecla do catálogo |
| `systemShortcut` | `SystemShortcut` | `systemShortcut` | — |
| `text` | `String`, `pressEnter: Bool` | `text` | 1 a 1.000 caracteres, uma linha |
| `openPalette` | — | `openPalette` | — |
| `none` | — | (nenhum) | Proibida em botão modificador |

"Herdar" não é caso: é a ausência do botão numa camada de modificador.

### 3.6 `ShortcutAction` (saída do mapeador) 🟢

`ShortcutMapper.swift:106`: `keyDown(KeyChord, repeats)`, `keyUp(KeyChord)`, `text(String, pressEnter)`, `modifierDown(KeyModifier)`, `modifierUp(KeyModifier)`, `openPalette`, `systemDown(SystemShortcut)`, `systemUp(SystemShortcut)`.

### 3.7 `ShortcutMapper` (struct) 🟢

`ShortcutMapper.swift:127`.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `config` | `ShortcutConfig` | Mapeamento vigente |
| `held` | `Set<ButtonID>` | Botões segurados |
| `modifierOrder` | `[ButtonID]` | Modificadores segurados, do mais antigo ao mais recente |
| `resolved` | `[ButtonID: HeldAction]` | `chord` ou `system` mantido por botão |
| `lastTrigger` | `Trigger?` | `button`, `layer` (`nil` = base), `type` |

---

## 4. Paleta

### 4.1 `PaletteItem` (struct) 🟢

`CommandPalette.swift:5`.

| Campo | Tipo | Obrigatório | Restrição | Descrição |
|-------|------|:-:|-----------|-----------|
| `text` | `String` | ✔ | 1 a 1.000 caracteres, uma linha | Digitado no aplicativo em foco |
| `pressEnter` | `Bool` | ✔ (no arquivo, opcional = `false`) | — | Envia Enter ao final |
| `label` | `String` | — (padrão `""`) | até 80 caracteres, uma linha | Exibido no lugar do texto |

`displayText` = `label` se não vazio, senão `text`.

### 4.2 Estado e efeitos 🟢

| Tipo | Valores / campos | Local |
|------|------------------|-------|
| `PaletteDirection` | `up`, `down` | `CommandPalette.swift:20` |
| `PaletteCloseReason` | `circle`, `ps`, `disconnected`, `idle`, `injection_suspended`, `config_changed`, `identify` | `CommandPalette.swift:25` |
| `PaletteSnapshot` | `isOpen: Bool`, `selection: Int` (0-based) | `CommandPalette.swift:60` |
| `PaletteEffect` | `render(snapshot)`, `startRepeat(direção)`, `stopRepeat`, `confirm(index 1-based, item)`, `closed(motivo)`, `openEditor` | `CommandPalette.swift:71` |
| `PaletteMachine` | `items` (≥ 1), `isOpen`, `selection`, `lastConfirmed: Int?`, `repeating: PaletteDirection?`; entrada fixa "Editar atalhos" no índice `items.count` | `CommandPalette.swift:86` |

---

## 5. Configuração em memória

### 5.1 `ShortcutConfig` (struct) 🟢

`ShortcutConfig.swift:31`.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `modifiers` | `[ButtonID: Set<KeyModifier>]` | Botão modificador → teclas mantidas (conjunto pode ser vazio) |
| `layers` | `[ButtonID?: [ButtonID: TriggerAction]]` | Chave `nil` = base; demais = camada do modificador |
| `pointerButtons` (estático) | `Set<ButtonID>` | `r1`, `r2`, `touchpadClick` |

`Resolution(action, inherited)` resulta de `resolvedAction(for:in:)`.

### 5.2 `ShortcutsDocument` (struct) 🟢

`ShortcutConfig.swift:69`: `shortcuts: ShortcutConfig` e `palette: [PaletteItem]`, validados e aplicados juntos. Limites: `maxTextLength` 1.000, `maxLabelLength` 80, `paletteItemLimit` 1…50.

### 5.3 `ShortcutIssue` (struct) 🟢

`ShortcutConfig.swift:84`.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `path` | `String` | Ex.: `shortcuts.layers.l2.dpadLeft`, `palette.items[3].text`; vazio para o arquivo inteiro |
| `rule` | `Rule` | Ver abaixo |
| `line` | `Int?` | Linha no arquivo, quando conhecida |

`Rule`: `unsupportedVersion`, `pointerButtonNotAllowed`, `layerWithoutModifier`, `modifierHasAction`, `unknownKey`, `unknownModifier`, `unknownSystemShortcut`, `unknownActionType`, `textEmpty`, `textTooLong`, `multiline`, `labelTooLong`, `paletteEmpty`, `paletteTooLong`, `wrongType`, `syntax`, `unreadable`.

### 5.4 `ConfigIssue` (enum) 🟢

`PointerSettingsValidation.swift:3`: `valueRejected(field, rejected, min, max, defaultValue)`, `invalidJSON(line, message)`, `unreadable(message)`.

### 5.5 `ConfigLoadResult` (struct) 🟢

`ConfigLoader.swift:7`.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `settings` | `PointerSettings` | Validados ou padrão |
| `status` | `ConfigStatus` (`defaults`, `loaded`, `invalidJSON`) | Resultado de `pointer` |
| `reason` | `String?` | `file_missing` ou `section_missing` |
| `issues` | `[ConfigIssue]` | Problemas de `pointer` e do arquivo |
| `shortcuts` | `ShortcutsDocument` | Lidos ou padrões |
| `shortcutsSource` | `ShortcutsSource` (`defaults`, `file`) | Origem |
| `shortcutsReason` | `ShortcutsDefaultReason?` (`file_missing`, `section_missing`) | Motivo dos padrões |
| `shortcutIssues` | `[ShortcutIssue]` | Vazio numa leitura aceita |
| `data` | `Data?` | Bytes lidos, para comparar releituras |

### 5.6 `ConfigState` (struct, app) 🟢

`JoystickAIPoC/Config/ConfigStore.swift:5`: `current: ShortcutsDocument`, `status` (`valid` ou `invalid(ShortcutIssue)`), `lastBytes: Data?`, `source: ShortcutsSource`. Gatilhos de mudança: `ShortcutsTrigger` ∈ {`startup`, `external`, `editor`, `restore`}.

---

## 6. Editor

| Tipo | Valores / campos | Local | Confiança |
|------|------------------|-------|-----------|
| `EditorTarget` | `trigger(layer, button)`, `modifier(button)`, `paletteItem(index)`, `palette` | `EditorDraft.swift:4` | 🟢 |
| `EditorIssue` | `target`, `rule` | `EditorDraft.swift:12` | 🟢 |
| `EditorWarning` | `noPaletteTrigger` | `EditorDraft.swift:23` | 🟢 |
| `EditorOperationError` | `lastPaletteItem`, `paletteFull`, `multiline`, `textTooLong`, `labelTooLong`, `pointerButton` | `EditorDraft.swift:29` | 🟢 |
| `EditorDraft` | `base`, `document`, `removedNones: [ButtonID: [ButtonID?]]` | `EditorDraft.swift:46` | 🟢 |
| `EditorViewModel` | `draft`, `tab` (`shortcuts`/`palette`), `selectedLayer`, `selectedButton` (padrão ✕), `identifying`, `operationError`, `saveError`, `pendingBackup(line, restore)`, `conflict` (`externalChange`/`externalInvalid`) | `EditorViewModel.swift:9` | 🟢 |
| `EditorOpenSource` | `menu`, `palette`, `alert` | `LogEventCatalog.swift:12` | 🟢 |
| `EditorCloseOutcome` | `clean`, `saved`, `discarded` | `LogEventCatalog.swift:13` | 🟢 |
| `EditorConflictChoice` | `reload`, `keep`, `pending` | `LogEventCatalog.swift:14` | 🟢 |

---

## 7. Arquivo `config.json`

**Caminho:** `~/.config/joystick-ai/config.json` (link simbólico seguido até 16 níveis). **Limite:** 1 MiB. **Cópia de segurança:** `config.json.bak`, ao gravar sobre arquivo com erro de sintaxe. **Criação:** só pelo editor ou por "Restaurar padrão". 🟢

```jsonc
{
  "pointer": {                          // opcional; lido só no início
    "touchpadSensitivity": 1.0,         // ver §2.1
    "stickMaxSpeed": 1500,
    "stickExponent": 2.0,
    "deadzone": 0.12,
    "scrollSpeed": 40,
    "invertScrollY": false,
    "precisionFactor": 0.3,
    "doubleClickIntervalMs": 400
  },
  "shortcuts": {                        // opcional; ausente = padrão; observado em tempo real
    "version": 1,                       // obrigatório, igual a 1
    "modifiers": {                      // opcional
      "<ButtonID>": ["command", "shift"]   // conjunto, sem repetição; pode ser []
    },
    "layers": {                         // opcional
      "base": {                         // ou "<ButtonID modificador>"
        "<ButtonID>": { "type": "chord", "key": "<KeyEntry.name>", "modifiers": ["command"], "repeat": true },
        "<ButtonID>": { "type": "systemShortcut", "name": "<SystemShortcut.name>" },
        "<ButtonID>": { "type": "text", "text": "…", "pressEnter": false },
        "<ButtonID>": { "type": "openPalette" },
        "<ButtonID>": { "type": "none" }
      }
    }
  },
  "palette": {                          // opcional; ausente = padrão
    "version": 1,
    "items": [                          // 1 a 50
      { "label": "", "text": "/reversa", "pressEnter": false }
    ]
  }
  // demais chaves da raiz são preservadas na gravação
}
```

| Caminho | Tipo | Obrigatório | Padrão | Regra |
|---------|------|:-:|--------|-------|
| `shortcuts.version` | inteiro | ✔ | — | `unsupportedVersion` se ausente ou ≠ 1 |
| `shortcuts.modifiers.<b>` | lista de `KeyModifier` | — | `[]` | `wrongType`, `unknownModifier`, `pointerButtonNotAllowed` |
| `shortcuts.layers.<camada>` | objeto | — | ausente = herda | `layerWithoutModifier`, `wrongType` |
| `….<b>.type` | cadeia | ✔ | — | `unknownActionType` |
| `….<b>.key` | cadeia | ✔ em `chord` | — | `unknownKey` |
| `….<b>.modifiers` | lista | — | `[]` | `unknownModifier`, `wrongType` |
| `….<b>.repeat` | booleano | — | `false` | `wrongType` |
| `….<b>.name` | cadeia | ✔ em `systemShortcut` | — | `unknownSystemShortcut` |
| `….<b>.text` | cadeia | ✔ em `text` | — | `textEmpty`, `multiline`, `textTooLong` |
| `….<b>.pressEnter` | booleano | — | `false` | `wrongType` |
| `palette.version` | inteiro | ✔ | — | `unsupportedVersion` |
| `palette.items` | lista | ✔ | — | `wrongType`, `paletteEmpty`, `paletteTooLong` |
| `palette.items[i].text` | cadeia | ✔ | — | `textEmpty`, `multiline`, `textTooLong` |
| `palette.items[i].label` | cadeia | — | `""` | `multiline`, `labelTooLong` |
| `palette.items[i].pressEnter` | booleano | — | `false` | `wrongType` |

**Gravação:** chaves em ordem alfabética, indentação do `JSONEncoder.prettyPrinted`, barras sem escape, quebra de linha final; omite `modifiers` vazio (dentro de acordes), `repeat` falso e camadas vazias; sempre escreve `modifiers` e `layers` da seção, e `label` e `pressEnter` dos itens (`ConfigDocument.swift`). 🟢

**Amostras em `scripts/config-samples/`:** `invalid-line4.json`, `invalid-line12.json` (erro de sintaxe), `out-of-range.json` (`pointer` recusado), `stick-1800.json`, `l3-modifier.json`, `r1-in-layer.json` (`pointerButtonNotAllowed`), `palette-reversa-docs.json`. 🟡 (propósito inferido pelo nome)

---

## 8. Argumentos de abertura

`LaunchArguments` (`JoystickCore/App/LaunchArguments.swift:36`), passados por `open --args`. 🟢

| Argumento | Campo | Tipo | Padrão | Validação | Erro |
|-----------|-------|------|--------|-----------|------|
| `--targets` | `targets` | `Bool` | `false` | — | `missingEnv` sem `--env` |
| `--env <v>` | `env` | `TargetEnvironment?` | `nil` | `mesa` ou `sofa`, sem acento | `invalidEnv` |
| `--screen <n>` | `screen` | `Int` | 1 | inteiro ≥ 1 | `invalidScreen` (cai na tela 1) |
| `--seed <n>` | `seed` | `UInt64?` | aleatória de 32 bits | inteiro sem sinal | `invalidSeed` |
| `--debug` | `debug` | `Bool` | `false` | — | — |
| `--scroll-unit <v>` | `scrollUnit` | `ScrollUnit` | `pixel` | `pixel` ou `line` | `invalidScrollUnit` |
| `--palette-enter-delay-ms <n>` | `paletteEnterDelayMs` | `Int?` | `nil` (0 ms) | 0 a 500 | `invalidPaletteEnterDelay` |
| qualquer flag sem valor | — | — | — | — | `missingValue(flag)` |

Erros com `concernsPalette` vão a `palette.invalid_args`; os demais, a `targets.invalid_args`, e só quando a tela de alvos é pedida.

---

## 9. Log de diagnóstico (JSONL)

**Caminho:** `~/Library/Logs/joystick-ai/poc-AAAAMMDD-HHMMSS[-n].jsonl`. **Esquema:** `logSchema = 1`, em `session.start`. 🟢

### 9.1 Campos comuns

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `ts_ns` | inteiro | `CLOCK_UPTIME_RAW` em ns, no instante lógico do evento |
| `wall` | cadeia | `yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX` |
| `level` | `debug` \| `info` \| `warn` \| `error` | `debug` só com `--debug` |
| `event` | cadeia | Nome do evento |

### 9.2 Catálogo (50 eventos) 🟢

| Evento | Nível | Campos específicos |
|--------|-------|--------------------|
| `session.start` | info | `logSchema`, `appVersion`, `macOS`, `pid`, `debug`, `args[]`, `signing{identifier, teamOrCertName, designatedRequirement}` |
| `permissions.status` | info | `postEvent`, `listenEvent`, `trigger` (`startup`/`poll`) |
| `permissions.guidance` | warn | `message` |
| `config.invalid_json` | error | `message`, `line?` |
| `config.unreadable` | error | `message` |
| `config.loaded` | info | `status`, `settings{…}`, `reason?` |
| `config.value_rejected` | warn | `field`, `rejected`, `min`, `max`, `default` |
| `displays.changed` | info | `count` |
| `cursor.reclamped` | info | — |
| `controller.connected` | info | `id`, `name`, `connection`, `atStartup`, `t_arrival` |
| `controller.ignored` | info | `name`, `productCategory`, `reason` |
| `controller.queued` | info | `id`, `position` |
| `controller.disconnected` | info | `id`, `t_arrival` |
| `controller.elements` | debug | `names[]`, `touchpads[]` |
| `controller.touch_source` | info | `id`, `source` (`touchState`/`zero_transition`) |
| `controller.gesture_suppression` | info | `elements[]`, `message` |
| `controller.extended_report` | info | `transport`, `result` (`ok` ou `0x…`) |
| `controller.error` | error | `message` |
| `input.button` | debug | `button`, `phase`, `synthetic`, `t_arrival`, `t_delivered`, `t_framework?` |
| `input.touch` | debug | `finger`, `phase` (`began`/`ended`), `t_arrival`, `t_delivered` |
| `touch.raw_transition` | debug | `finger`, `toZero` |
| `pointer.posted` | debug | `kind` (`move`/`drag`/`scroll`/`down`/`up`), `source` (`touch`/`stick_onset`/`button`), `button?`, `clickState?`, `t_arrival`, `t_posted` |
| `pointer.injection_suspended` | warn | `heldButtons[]` |
| `pointer.injection_resumed` | info | `heldButtons[]` |
| `targets.screens` | info | `screens[{index, name, widthPt, heightPt, backingScale}]` |
| `targets.started` | info | `env`, `seed` |
| `targets.finished` | info | `env`, `seed`, `complete`, `abortReason?`, `file` |
| `targets.invalid_args` | warn | `message` |
| `targets.screen_fallback` | warn | `message` |
| `targets.write_failed` | error | `message`, `payload` |
| `app.terminating` | info | `reason` (`quit`/`sigterm`/`sigint`/`sighup`), `releasedButtons[]` |
| `palette.opened` | info | `selection` (1-based) |
| `palette.confirmed` | info | `index` (1-based), `enter` |
| `palette.closed` | info | `reason` |
| `palette.blocked` | info | `reason` = `targets` |
| `palette.invalid_args` | warn | `message` |
| `shortcuts.loaded` | info | `trigger`, `source`, `reason?`, `modifiers[]`, `items` |
| `shortcuts.unchanged` | debug | `trigger` |
| `shortcuts.invalid` | error | `trigger`, `rule`, `path?`, `line?` |
| `shortcuts.file_removed` | info | — |
| `shortcuts.saved` | info | `created`, `backup` |
| `shortcuts.save_failed` | error | `message` (caminho e erro do sistema) |
| `shortcuts.restored` | info | — |
| `shortcut.triggered` | info | `button`, `layer` (`base` ou botão), `type` |
| `editor.opened` | info | `source` |
| `editor.closed` | info | `outcome` |
| `editor.conflict` | warn | `choice` |
| `editor.identify` | info | `on` |
| `editor.activation_failed` | warn | — |
| `log.debug_suspended` | warn | `sizeBytes` |

**Dados nunca registrados (RN-12, RN-14):** coordenadas do cursor, deltas, posições do toque, valores de eixo, pontos de clique, textos da paleta ou de ações, rótulos, nomes de teclas e acordes. 🟢

### 9.3 `JSONValue` 🟢

`JSONValue.swift:4`: `null`, `bool`, `int(Int64)`, `uint(UInt64)`, `double`, `string`, `array`, `object`. Acessores `doubleValue`, `intValue`, `stringValue`, `boolValue` e `subscript(key)`.

---

## 10. Resultado da tela de alvos

**Caminho:** `~/Library/Application Support/joystick-ai/target-runs/AAAAMMDD-HHMMSS-<env>[-n].json`, JSON `prettyPrinted`, nunca sobrescrito. 🟢

### 10.1 `TargetRun` (`schemaVersion` 1)

`TargetRun.swift:73`.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `schemaVersion` | `Int` | 1 |
| `startedAt` | `String` | ISO 8601 local com fuso |
| `environment` | `TargetEnvironment` | `mesa` ou `sofa` |
| `complete` | `Bool` | 20 tentativas feitas |
| `abortReason` | `AbortReason?` | `user`, `screen_removed`, `injection_suspended`; `nil` se completa |
| `seed` | `UInt64` | Semente do SplitMix64 |
| `screen` | `ScreenDescriptor` | `name`, `widthPx`, `heightPx`, `widthPt`, `heightPt`, `backingScale` |
| `targetSizePt` | `Int` | 16 |
| `settings` | `PointerSettings` | Vigentes na sessão |
| `scrollUnit` | `ScrollUnit` | Da abertura |
| `attempts` | `[TargetAttempt]` | Ver abaixo |
| `summary` | `TargetSummary` | Calculado na criação |
| `ignoredPhysicalClicks` | `Int` | Cliques do mouse físico descartados |

### 10.2 Subestruturas

| Tipo | Campos |
|------|--------|
| `TargetAttempt` | `index` (1-based), `targetRectPt: RectPt`, `hit`, `timeToClickMs`, `l1Held` |
| `RectPt` | `x`, `y`, `w`, `h` (inteiros, pt, relativos à tela) |
| `TargetSummary` | `hits`, `total`, `hitRate`, `meanTimeMs`, `hitRateWithL1?`, `hitRateWithoutL1?` |
| `ScreenListing` (log) | `index`, `name`, `widthPt`, `heightPt`, `backingScale` |

---

## 11. Análise

| Tipo | Campos | Local |
|------|--------|-------|
| `LogReadResult` | `records: [[String: JSONValue]]`, `malformedLines` | `LogAnalysis.swift:3` |
| `ButtonObservation` / `ButtonCoverage` | `down`, `up` / `observed`, `covered` | `LogAnalysis.swift:8-22` |
| `CycleSummary` | `completeCycles`, `unmatchedConnections`, `sessions` | `LogAnalysis.swift:24` |
| `LatencySummary` | `count`, `p50Ms`, `p95Ms`, `maxMs`; `passes(thresholdMs)` = p95 ≤ meta | `LatencyStats.swift:3` |

---

## 12. Constantes de domínio

| Constante | Valor | Local |
|-----------|-------|-------|
| Limiar do gatilho | 0,5 | `Normalization.swift:5` |
| Janela de adoção no início | 2 s | `StartupAdoption.swift:10` |
| Tick do movimento | 1/120 s | `PointerMotionEngine.swift:40` |
| Tick máximo aceito | 50 ms | `MotionLoop.swift:19` |
| Pontos por unidade do touchpad | 400 | `TouchpadTracker.swift:8` |
| Distância do duplo clique | 4 pt | `ClickStateMachine.swift:21` |
| Pixels por linha de rolagem | 20 | `ScrollMapper.swift:12` |
| Repetição de tecla | 400 ms, depois 50 ms | `KeyRepeat.swift:7-8` |
| Marca dos eventos injetados | `0x4A4F5953` ("JOYS") | `EventInjector.swift:10` |
| Ressincronia da posição | 100 ms, 32 posições | `EventInjector.swift:16-17` |
| Consulta de permissões | 2 s | `PermissionMonitor.swift:12` |
| Agregação de reconfiguração de telas | 200 ms | `DisplayMonitor.swift:47` |
| Agregação de releitura da configuração | 150 ms | `ConfigWatcher.swift:10` |
| Tamanho máximo do arquivo | 1 MiB | `ConfigLoader.swift:44` |
| Inatividade da paleta | 60 s, consulta a cada 1 s | `PaletteActions.swift:11-12` |
| Atraso padrão do Enter da paleta | 0 ms (faixa 0–500) | `PaletteActions.swift:10`, `LaunchArguments.swift:50` |
| Flush do log | 250 ms ou 256 KiB | `DiagnosticLog.swift:8-9` |
| Suspensão de `debug` | 50 MiB | `DiagnosticLog.swift:10` |
| Atraso do clique de ativação do editor | 150 ms, verificação após 500 ms | `EditorWindowController.swift:20-22` |
| Tela de alvos | 20 alvos, 16 pt, margem 40 pt, resumo 3 s, discrepante > 60 s | `TargetRun.swift:74-76`, `TargetSession.swift:6`, `RunsReport.swift:5` |
| Metas de latência | processamento 5 ms, entrada ao movimento 20 ms (p95) | `LatencyCommand.swift:6-7` |
| IDs USB | Sony `0x054C`; DualSense `0x0CE6`, Edge `0x0DF2` | `TransportResolver.swift:11-13` |
| Relatório de calibração | `0x05` | `ExtendedReportActivator.swift:12` |
| Bundle | `dev.iagoleal.joystick-ai.poc`, versão 0.1.0 | `Resources/Info.plist` |
