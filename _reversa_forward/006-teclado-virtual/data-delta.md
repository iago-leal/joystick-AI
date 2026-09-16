# Data delta: Teclado virtual chamado pelo controle

> Identificador: `006-teclado-virtual`
> Data: `2026-09-16`
> Base: `_reversa_sdd/architecture.md#5. Modelo de dados em arquivo`, `_reversa_sdd/data-dictionary.md` e o código de `ShortcutMapper.swift`, `ShortcutConfigValidation.swift` e `ConfigDocument.swift` em 2026-09-16
> Confidência: 🟢 salvo indicação

## 1. Persistência

| Arquivo | Antes | Depois |
|---------|-------|--------|
| `~/.config/joystick-ai/config.json` | `systemShortcut.name` em `nextWindow`, `missionControl`, `applicationWindows`, `spaceLeft`, `spaceRight` | os cinco nomes mais `accessibilityShortcut`; nenhum campo, tipo ou versão novos; `shortcuts.version` segue 1 |
| `~/Library/Logs/joystick-ai/poc-*.jsonl` | `logSchema` 1 | idêntico; nenhum evento nem campo novo |

Exemplo de ação com o atalho novo, num botão escolhido pelo usuário:

```json
"layers": {
  "base": {
    "l3": { "type": "systemShortcut", "name": "accessibilityShortcut" }
  }
}
```

**Compatibilidade:** arquivos existentes são lidos sem mudança. Um arquivo com `accessibilityShortcut` é recusado por versões anteriores à feature, com `unknownSystemShortcut` em `shortcuts.layers.<camada>.<botão>.name`; não há migração nem convivência de versões a tratar.

## 2. Atalhos de sistema (`SystemShortcut`)

| Item | Antes | Depois |
|------|-------|--------|
| Casos | 5 (IDs 27, 32, 33, 79, 81) | 6, com `accessibilityShortcut = 162` |
| `name` | 5 nomes | acrescenta `"accessibilityShortcut"` |
| `displayName` | 5 rótulos | acrescenta `"atalho de acessibilidade"` |
| `defaultChord` | 5 acordes | acrescenta `KeyChord(KeyChord.f5, [.option, .command])` (⌥⌘F5) |
| `chords(fromSymbolicHotKeys:)` | percorre `allCases` | sem mudança de código; passa a ler também a entrada `"162"` |

Leitura esperada da entrada 162 observada nesta máquina:

| `parameters` | Tecla virtual | Máscara | Acorde |
|--------------|---------------|---------|--------|
| `(65535, 96, 1572864)` | `0x60` (F5) | `0x180000` = ⌘ `0x100000` + ⌥ `0x80000` | ⌥⌘F5 |

## 3. Constantes e propriedades de `KeyChord`

| Item | Antes | Depois |
|------|-------|--------|
| `KeyChord.f5` | inexistente | `96` (`0x60`), igual à entrada `f5` de `KeyCatalog` |
| `KeyChord.isFunctionKey` | inexistente | **só com D-03:** `true` para os 12 códigos de F1 a F12 (`0x7A`, `0x78`, `0x63`, `0x76`, `0x60`, `0x61`, `0x62`, `0x64`, `0x65`, `0x6D`, `0x67`, `0x6F`) |

## 4. Injeção (só com D-03)

| Tecla | `flags` antes | `flags` depois |
|-------|---------------|----------------|
| Setas (123 a 126) | modificadores + `maskNumericPad` + `maskSecondaryFn` | sem mudança |
| F1 a F12 | modificadores | modificadores + `maskSecondaryFn` |
| Demais | modificadores | sem mudança |

## 5. Catálogo de eventos do log

Sem mudança. O acionamento produz `shortcut.triggered { button, layer, type: "systemShortcut" }`, sem o nome do atalho, como os cinco atalhos de sistema existentes.

## 6. Migrações

n/a.
