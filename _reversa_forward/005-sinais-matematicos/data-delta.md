# Data delta: Atalhos de zoom montados pelo controle

> Identificador: `005-sinais-matematicos`
> Data: `2026-09-16`
> Base: `_reversa_sdd/architecture.md#5. Modelo de dados em arquivo`, `_reversa_sdd/data-dictionary.md` e o código de `KeyCatalog.swift` e `ConfigDocument.swift` em 2026-09-16
> Confidência: 🟢 salvo indicação

## 1. Persistência

Nada muda em disco.

| Arquivo | Antes | Depois |
|---------|-------|--------|
| `~/.config/joystick-ai/config.json` | acorde com `key` do catálogo de 73 nomes e `modifiers` | idêntico; ⌘+ é gravado como `{"type": "chord", "key": "equal", "modifiers": ["command", "shift"]}`, igual ao ⇧⌘= montado antes da feature |
| `~/Library/Logs/joystick-ai/poc-*.jsonl` | `logSchema` 1 | idêntico; nenhum evento nem campo novo |

Exemplo de ação, antes e depois:

```json
"layers": {
  "l1": {
    "dpadUp":   { "type": "chord", "key": "equal", "modifiers": ["command", "shift"] },
    "dpadDown": { "type": "chord", "key": "minus", "modifiers": ["command"] }
  }
}
```

## 2. Catálogo de teclas (`KeyCatalog`)

| Item | Antes | Depois |
|------|-------|--------|
| `KeyCatalog.entries` | 73 `KeyEntry` | 73 `KeyEntry`, sem mudança de nome, código, rótulo nem grupo |
| `KeyCatalog.composedKeys` | inexistente | `[ComposedKey(name: "plus", display: "+", keyCode: 0x18, modifier: .shift, group: .punctuation, after: "minus")]` |
| `KeyCatalog.choices(in:)` | inexistente | `entries(in:)` convertidas em `.key`, com cada `.composed` inserida após a entrada `after`; pontuação: `-`, `+`, `=`, `[`, … |
| `KeyCatalog.display(_:)` | `symbols(modifiers) + entry.display` | igual, exceto quando o acorde casa uma composta: `symbols(modifiers − [modifier]) + composed.display` |
| `KeyChord.equal` | inexistente | `0x18` |

## 3. Tipos novos em `JoystickCore`

```
ComposedKey: Equatable, Sendable                 // Sources/JoystickCore/Shortcuts/KeyCatalog.swift (D-01)
  name: String                                   // "plus": identificador da escolha na grade; nunca gravado no arquivo
  display: String                                // "+"
  keyCode: UInt16                                // tecla do catálogo usada no acorde (0x18, equal)
  modifier: KeyModifier                          // modificador implícito (.shift)
  group: KeyGroup                                // grupo da grade (.punctuation)
  after: String                                  // nome da entrada que a precede na grade ("minus")
  func matches(_ chord: KeyChord) -> Bool        // chord.keyCode == keyCode && chord.modifiers.contains(modifier)

KeyChoice: Equatable, Sendable                   // (D-03)
  case key(KeyEntry)
  case composed(ComposedKey)
  var id: String                                 // entry.name ou composed.name
  var display: String
  func isSelected(in chord: KeyChord) -> Bool    // .composed: matches; .key: mesma tecla e nenhuma composta casa
  func applied(to chord: KeyChord) -> KeyChord   // .composed: tecla + modificadores ∪ {modifier}
                                                 // .key: tecla + modificadores, menos o modificador de composta que casava
```

Regras de `applied` e `isSelected`, com o acorde atual à esquerda:

| Acorde atual | Escolha | Resultado | Exibição | `+` marcado | `=` marcado |
|--------------|---------|-----------|----------|-------------|-------------|
| ⌘Z | `+` | ⇧⌘= | ⌘+ | sim | não |
| ⌥⌘Z | `+` | ⌥⇧⌘= | ⌥⌘+ | sim | não |
| ⇧⌘= | `=` | ⌘= | ⌘= | não | sim |
| ⇧⌘= | `-` | ⌘- | ⌘- | não | não |
| ⇧⌘Z | `=` | ⇧⌘= | ⌘+ | sim | não |

A última linha é consequência direta de D-03: ⇧⌘Z não casa composta, então ⇧ é mantido, e ⇧ com `=` é, por definição, `+`.

## 4. Campos removidos e migrações

Nenhum campo removido. Nenhuma migração: arquivos anteriores com ⇧⌘= são lidos sem mudança e exibidos como "⌘+".
