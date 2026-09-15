# Configuração (config), Design Técnico

> Gerado pelo Redator em 2026-09-15 · Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA

## Interface

### Núcleo

| Símbolo | Assinatura | Observação |
|---------|-----------|------------|
| `ConfigLoader.defaultURL` | `URL` | `~/.config/joystick-ai/config.json` |
| `ConfigLoader.maxBytes` | `1 << 20` | — |
| `ConfigLoader.load(from:fileManager:)` | `→ ConfigLoadResult` | Ausência, diretório, tamanho, leitura |
| `ConfigLoader.parse(data:)` | `→ ConfigLoadResult` | JSON, `pointer`, atalhos e paleta |
| `ConfigLoader.line(fromDescription:)`, `line(atOffset:in:)` | `→ Int?` / `Int` | Linha do erro de sintaxe |
| `ConfigLoadResult` | `settings`, `status` (`defaults`/`loaded`/`invalidJSON`), `reason`, `issues: [ConfigIssue]`, `shortcuts`, `shortcutsSource`, `shortcutsReason`, `shortcutIssues`, `data` | — |
| `ConfigIssue` | `valueRejected(field, rejected, min, max, defaultValue)`, `invalidJSON(line, message)`, `unreadable(message)` | Seção `pointer` e arquivo |
| `PointerSettingsValidation.validate(_:)` | `JSONValue → (PointerSettings, [ConfigIssue])` | — |
| `ShortcutConfigValidation.decode(root:)` | `→ Result<ShortcutsDocument, ShortcutIssues>` | Forma + semântica |
| `ShortcutConfigValidation.validate(_:)` | `ShortcutsDocument → [ShortcutIssue]` | Usado também pelo rascunho do editor |
| `ShortcutConfigValidation.textRule`, `labelRule`, `isMultiline`, `path(layer:)`, `sortedLayers` | — | Auxiliares públicos |
| `ShortcutsDocument` | `shortcuts`, `palette`; `maxTextLength 1000`, `maxLabelLength 80`, `paletteItemLimit 1...50` | — |
| `ShortcutIssue` | `path`, `rule`, `line?`; `logPath` | 17 regras |
| `ConfigLineLocator.line(of:in:)`, `nearestLine(of:in:)` | `(String, Data) → Int?` | Varredura léxica |
| `ConfigDocument.encode(_:)`, `merge(existing:document:)` | `→ Data` | Serialização |
| `ActionSummary.text(for:layer:in:)`, `text(for:)`, `truncated(_:limit:)` | `→ String` | Resumo da figura (24 caracteres) |

### App (main thread)

| Símbolo | Observação |
|---------|------------|
| `ConfigState { current, status (valid / invalid(issue)), lastBytes, source }` | — |
| `ConfigStore(url:log:)` | `start(with:)`, `reload(trigger:)`, `save(_:confirmBackup:)`, `restoreDefaults(confirmBackup:)`, `addObserver`, `onApply`, `state` |
| `ConfigStore.SaveOutcome` | `saved`, `needsBackupConfirmation(line)`, `failed(message)` |
| `ConfigWatcher(url:onChange:)` | `start()`, `stop()`; `reloadDelay 150 ms` |
| `ConfigWriter(url:fileManager:)` | `write(_:confirmBackup:) → Outcome` (`written(bytes, created, backup)`, `needsBackupConfirmation(line)`, `failed(message)`); `resolveLinks`; `backupSuffix ".bak"`; `maxLinkDepth 16` |

## Fluxo Principal

### Leitura (`ConfigLoader.swift:50-112`)

```
load(url):
  não existe          → defaults, reason file_missing, shortcutsReason fileMissing
  é diretório         → unreadable
  atributo size > 1 MiB → unreadable
  Data(contentsOf) falha ou > 1 MiB → unreadable
  senão parse(data)

parse(data):
  JSONDecoder falha   → invalidJSON(line, message) + ShortcutIssue(syntax, line)
  raiz não objeto     → invalidJSON(nil, "a raiz do arquivo não é um objeto JSON") + ShortcutIssue(wrongType, linha 1)
  pointer objeto      → PointerSettingsValidation → status loaded
  senão               → defaults, reason section_missing
  decode(root):
    sucesso → shortcuts = documento; source = file se alguma seção existe, senão defaults + sectionMissing
    falha   → shortcutIssues = problemas com linha = nearestLine(path)
```

Linha de sintaxe: procura "line N" na descrição do erro do Foundation; senão, conta LFs até `NSJSONSerializationErrorIndex`. 🟢

### Decodificação de atalhos (`ShortcutConfigValidation.swift:116-271`)

1. `shortcuts` presente → `SectionDecoder.shortcuts`; ausente → `ShortcutDefaults.config`. Idem `palette` → `PaletteDefaults.items`.
2. `shortcuts`: objeto; `version`; `modifiers` (objeto de listas de nomes de modificador, sem repetição); `layers` (`base` ou nome de botão → objeto de gatilhos → ação). Chaves percorridas em ordem alfabética.
3. Ação: `type` textual; `chord` (`key` do catálogo, `modifiers?`, `repeat?`), `systemShortcut` (`name`), `text` (`text`, `pressEnter?`), `openPalette`, `none`.
4. `palette`: objeto; `version`; `items` lista; cada item objeto com `text`, `label?` (padrão vazio), `pressEnter?`.
5. Seções decodificadas passam por `validate` (semântica); a recusa soma problemas de forma e de semântica das duas.

### Semântica (`:16-81`)

Para cada modificador que é botão de apontamento: `pointerButtonNotAllowed`. Para cada camada (base primeiro, depois modificadores por `ButtonID`): camada de não modificador → `layerWithoutModifier`; cada gatilho: de apontamento → `pointerButtonNotAllowed`, modificador → `modifierHasAction`; texto → `textRule`; acorde fora do catálogo → `unknownKey`. Paleta: vazia → `paletteEmpty` (e para); mais de 50 → `paletteTooLong`; cada item → `textRule` e `labelRule`.

### Localização de linha (`ConfigLineLocator.swift`)

Converte `a.b[3].c` em componentes; o `Scanner` percorre bytes pulando espaços, cadeias (com escapes e sem quebra de linha) e valores aninhados, contando LF e CR isolado; `nearestLine` remove o último componente até encontrar. 🟢

### Estado (`ConfigStore.swift`)

- `start(with:)`: `lastBytes = data`; com problema → `invalid(primeiro)` e `shortcuts.invalid` por problema (`startup`); sem problema → vigente e fonte do resultado, `shortcuts.loaded`.
- `reload(trigger:)`: `load`; `fileMissing` → mantém (log `file_removed` se `lastBytes` existia e zera; senão `unchanged`); `data == lastBytes` → `unchanged`; senão `lastBytes = data`; problema → `invalid`, log, `notify`; aceite → `apply`.
- `write`: `ConfigWriter.write`; `written` → `lastBytes = bytes`, log `saved` ou `restored`, `apply(source: file)`; `needsBackupConfirmation` → devolve; `failed` → log `save_failed`, devolve.
- `apply`: vigente, `valid`, fonte, `shortcuts.loaded`, `onApply(document)`, `notify`.

`onApply` no bootstrap (`AppDelegate.swift:80-84`): `inputQueue.async { paletteActions.apply(items:); shortcutActions.apply(config) }`. Observadores: barra de menus (`AppDelegate.swift:103-104`) e editor. 🟢

### Observação (`ConfigWatcher.swift`)

`watchedPaths` = {ancestral existente do diretório do arquivo, ancestral existente do diretório do destino, destino se existir}. `refreshSources` cancela observações que saíram, reabre sempre a do destino (descritor inválido após troca atômica) e abre as novas com `open(path, O_EVTONLY)` e `DispatchSource.makeFileSystemObjectSource([.write, .extend, .rename, .delete], queue: .main)`. `handleEvent` → `refreshSources`, cancela a releitura pendente e agenda outra em 150 ms, que reabre as observações e chama `onChange` → `configStore.reload(trigger: .external)`. 🟢

### Gravação (`ConfigWriter.swift:24-61`)

1. `destination = resolveLinks(url)`.
2. Se existe: lê (falha → `failed`); `ConfigLoader.parse(data).shortcutIssues.first`: `syntax` ou `wrongType` sem caminho → sem confirmação, `needsBackupConfirmation(line)`; com confirmação, grava `data` em `<destino>.bak` (atômico; falha → `failed`) e `backup = true`. Outros casos → `existing = JSONValue` decodificado.
3. `bytes = ConfigDocument.merge(existing, document)`.
4. `createDirectory(withIntermediateDirectories)`; `bytes.write(.atomic)`; falha → `failed`.
5. `written(bytes, created: !existia, backup)`.

### Codificação (`ConfigDocument.swift`)

`shortcuts = { version: 1, modifiers: {botão: [modificadores ordenados]}, layers: {base|botão: {botão: ação}} }` (só camadas não vazias); acorde `{type, key, modifiers?, repeat?}` (tecla fora do catálogo viraria `keyCodeN`, mas é recusada antes); `palette = { version: 1, items: [{label, text, pressEnter}] }`. `merge` substitui as duas chaves na raiz existente (ou cria), `JSONEncoder [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]` + `\n`. 🟢

## Fluxos Alternativos

- **Arquivo removido e recriado:** a remoção mantém a vigente e zera `lastBytes`; a recriação é lida como alteração nova. 🟢
- **Diretório `~/.config/joystick-ai` inexistente:** observa-se o ancestral existente; ao surgir o diretório, a observação passa a ele. 🟢
- **Leitura ilegível na releitura:** `data` nula, `lastBytes` zerado, estado inválido com `unreadable`. 🟢
- **Gravação com `.bak`:** a raiz nova contém só `shortcuts` e `palette`; `pointer` e demais chaves ficam apenas no `.bak`. 🟢

## Dependências

- `atalhos`: `ShortcutConfig`, `TriggerAction`, `KeyCatalog`, `SystemShortcut`, `ShortcutDefaults`. 🟢
- `paleta`: `PaletteItem`, `PaletteDefaults`. 🟢
- `ponteiro`: `PointerSettings` (campos, faixas, `jsonValue`). 🟢
- `log-de-diagnostico`: `JSONValue`, eventos `config.*` e `shortcuts.*`, `ShortcutsTrigger`, `ShortcutsSource`, `ShortcutsDefaultReason`. 🟢
- Foundation (`FileManager`, `JSONDecoder/Encoder`), Dispatch (`DispatchSourceFileSystemObject`), Darwin (`open`, `O_EVTONLY`). 🟢

## Decisões de Design Identificadas

| Decisão | Evidência | Confiança |
|---------|-----------|-----------|
| Arquivo JSON único em camadas (ADR-011) | `ConfigLoader.swift:39` | 🟢 |
| Validação conjunta que recusa as duas seções (003 D-05, RN-08) | `ShortcutConfigValidation.swift:115` | 🟢 |
| Linha por varredura léxica só na falha (003 D-06) | `ConfigLineLocator.swift:3-6` | 🟢 |
| Fusão e troca atômica com `.bak` (003 D-07, D-17, ADR-012) | `ConfigDocument.swift:67`, `ConfigWriter.swift:4-7` | 🟢 |
| Raiz decodificada uma vez para as três seções (003 D-08) | `ConfigLoader.swift:41-42` | 🟢 |
| `ConfigStore` na main como dono da vigente (003 D-15) | `ConfigStore.swift:20` | 🟢 |
| Observação por diretório e arquivo, com *bytes* para ignorar a própria gravação (003 D-16) | `ConfigWatcher.swift:3-8`, `ConfigStore.swift:15` | 🟢 |
| Remoção do arquivo mantém a vigente; arquivo nunca criado sem o editor (003 RN-10) | `ConfigStore.swift:71-80`, `AppDelegate.swift:48` | 🟢 |
| Problemas sem valores (003 RN-14) | `ShortcutConfig.swift:83` | 🟢 |

## Estado Interno

`ConfigState` (vigente, status, `lastBytes`, fonte), observadores e `onApply` no `ConfigStore`; `sources: [String: DispatchSourceFileSystemObject]` e `pendingReload` no `ConfigWatcher`. Máquina de estados: `state-machines.md` §8. 🟢

## Observabilidade

`config.loaded`, `config.value_rejected`, `config.invalid_json`, `config.unreadable` (ao iniciar); `shortcuts.loaded`, `shortcuts.invalid`, `shortcuts.unchanged` (`debug`), `shortcuts.file_removed`, `shortcuts.saved`, `shortcuts.save_failed`, `shortcuts.restored`. 🟢

## Riscos e Lacunas

- 🟢 DV-05, defeito confirmado pelo usuário: a gravação confia no chamador; se o rascunho mudar entre a verificação e "Copiar e gravar", um documento inválido pode ser gravado e aplicado. Correção em `tasks.md` T-11.
- 🟢 O `.bak` é sobrescrito a cada gravação com arquivo corrompido; apenas a última cópia sobrevive (`ConfigWriter.swift:41-43`; [Revisor]).
- 🟡 `config.value_rejected` registra o valor recusado de `pointer` (números e booleanos), diferentemente das seções de atalhos, que nunca registram valores.
- 🟡 Alterar `pointer` com o app aberto não tem efeito nem aviso até reiniciar.
- 🟡 Entre a leitura para fusão e a troca atômica, uma edição externa simultânea é perdida (sem trava de arquivo).
