# Log de diagnóstico (diagnostics-log), Design Técnico

> Gerado pelo Redator em 2026-09-15 · Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA

## Interface

### Núcleo

| Símbolo | Assinatura | Observação |
|---------|-----------|------------|
| `LogLevel` | `debug`, `info`, `warn`, `error`; `Comparable` | — |
| `LogEvent` | `init(_ name:, level:, fields: [String: JSONValue] = [:])` | Valor |
| `LogLineFormatter.line(_:tsNs:wall:)` | `→ String` | Linha com `\n` |
| `LogEventCatalog` | 50 fábricas estáticas + `config(_ result) → [LogEvent]` | Único ponto de criação de eventos |
| Enums de campo | `PermissionTrigger`, `TouchSource`, `TouchBoundary`, `PostedKind`, `PostSource`, `TerminationReason`, `ShortcutsTrigger`, `ShortcutsSource`, `ShortcutsDefaultReason`, `EditorOpenSource`, `EditorCloseOutcome`, `EditorConflictChoice` | Valores textuais do log |
| `ScreenListing` | `index`, `name`, `widthPt`, `heightPt`, `backingScale` | `targets.screens` |
| `JSONValue` | `null`, `bool`, `int(Int64)`, `uint(UInt64)`, `double`, `string`, `array`, `object`; `jsonString()`, `doubleValue`, `intValue`, `stringValue`, `boolValue`, `subscript(key)`; `Codable`; literais | Log e leitura da configuração |
| `MonotonicClock.nowNs()` | `→ UInt64` | `CLOCK_UPTIME_RAW` |

### App

| Símbolo | Observação |
|---------|------------|
| `DiagnosticLog(debug:directory:now:)` | Abre o arquivo e liga o temporizador de descarga |
| `subsystem`, `flushInterval 250 ms`, `flushThresholdBytes 256 KiB`, `debugLimitBytes 50 MiB` | Constantes |
| `debugEnabled`, `fileURL` | Leitura |
| `defaultDirectory` | `~/Library/Logs/joystick-ai` |
| `log(_:)` | Chamável de qualquer fila |
| `flushSync()` | Descarga síncrona |

## Fluxo Principal

### Abertura (`DiagnosticLog.swift:28-36,63-85`)

1. Cria o diretório com intermediários.
2. `stem = "poc-" + yyyyMMdd-HHmmss(now)`; tenta `stem.jsonl`, depois `stem-2.jsonl`, `stem-3.jsonl`… até não existir.
3. `createFile`; `FileHandle(forWritingTo:)`; guarda `fileURL`.
4. Falha → `Logger.error` com o diretório e o erro; `handle` fica nulo.
5. Temporizador na fila `log` a cada 250 ms chama `flushLocked`.

### Registro (`:44-54`)

```
log(event):
  se level = debug e !debugEnabled: retorna        // na fila de quem chama
  tsNs ← MonotonicClock.nowNs(); date ← Date()
  fila log async:
    se level = debug e debugSuspended: retorna
    linha ← LogLineFormatter.line(event, tsNs, wall(date))
    append(linha)                                  // sem handle, descarta
    se buffer ≥ 256 KiB: flushLocked()
```

### Descarga (`:93-107`)

`flushLocked`: sem `handle` ou *buffer* vazio, retorna; `write(contentsOf:)`; sucesso soma `bytesWritten`; falha ignora; esvazia o *buffer*; se `!debugSuspended` e `bytesWritten > 50 MiB`, liga a suspensão e põe `log.debug_suspended` no *buffer* (escrito na descarga seguinte). 🟢

### Formatação (`LogEvent.swift:33-47`, `JSONValue.swift:21-75`)

`{"ts_ns":N,"wall":"…","level":"…","event":"…"` + `,"campo":valor` por chave ordenada, exceto as reservadas, + `}\n`. Valores por `JSONValue.write` (RN-LG-04). 🟢

### Decodificação de `JSONValue` (`JSONValue.swift:112-134`)

Tenta, em ordem, `null`, `Bool`, `Int64`, `UInt64`, `Double`, `String`, lista e objeto; nenhum → `dataCorrupted`. Números inteiros viram `int` (ou `uint` acima de `Int64.max`); fracionários, `double`. 🟢

### Pontos de emissão

| Origem | Eventos |
|--------|---------|
| `AppDelegate` | `session.start`, `config.*`, `palette.invalid_args`, `targets.invalid_args`, `targets.screen_fallback`, `editor.identify` |
| `PermissionMonitor` | `permissions.status`, `permissions.guidance` |
| `InjectionGate` | `pointer.injection_suspended`, `pointer.injection_resumed` |
| `ControllerReader` | `controller.connected`, `controller.disconnected`, `controller.ignored`, `controller.queued`, `input.button` |
| `ButtonReader` | `input.button`, `controller.error` |
| `AxisTouchReader` | `controller.touch_source`, `input.touch`, `touch.raw_transition` |
| `ControllerDiagnostics` | `controller.elements`, `controller.gesture_suppression` |
| `ExtendedReportActivator` | `controller.extended_report`, `controller.error` |
| `InputSink` | `controller.error` |
| `EventInjector` | `pointer.posted` |
| `DisplayMonitor` | `displays.changed`, `cursor.reclamped` |
| `ScreenCatalog` | `targets.screens` |
| `ShortcutActions` | `shortcut.triggered` |
| `PaletteActions` | `palette.opened`, `palette.confirmed`, `palette.closed`, `palette.blocked` |
| `ConfigStore` | `shortcuts.*` |
| `EditorWindowController`, `EditorViewModel` | `editor.opened`, `editor.closed`, `editor.activation_failed`, `editor.conflict` |
| `TargetSession`, `TargetRunWriter` | `targets.started`; `targets.finished`, `targets.write_failed` |
| `Lifecycle` | `app.terminating` + `flushSync()` (`Lifecycle.swift:33-41`) |
| `DiagnosticLog` | `log.debug_suspended` |

🟢

## Fluxos Alternativos

- **Sem permissão de escrita em `~/Library/Logs`:** app funcional, nenhum arquivo; só a mensagem no `os.Logger`. 🟢
- **Disco cheio no meio da sessão:** as linhas do *buffer* com falha se perdem, sem evento de erro. 🟢
- **Encerramento abrupto (SIGKILL, falha):** até 250 ms ou 256 KiB de linhas não descarregadas se perdem. 🟡

## Dependências

- Foundation (`FileManager`, `FileHandle`, `DateFormatter`), Dispatch, `os.Logger`, Darwin (`clock_gettime_nsec_np`). 🟢
- Tipos de outras units referenciados pelo catálogo: `ButtonID`, `ButtonPhase`, `ControllerInfo`, `ConnectionType`, `MouseButton`, `TargetEnvironment`, `AbortReason`, `ConfigLoadResult`, `PaletteCloseReason`, `ShortcutIssue.Rule`, `TriggerActionType`. 🟢
- Consumidores do formato: `tela-de-alvos-e-analise` (`LogAnalysis`, `poc-tools`). 🟢

## Decisões de Design Identificadas

| Decisão | Evidência | Confiança |
|---------|-----------|-----------|
| JSON Lines local com carimbos monotônicos (001 D-18, ADR-008) | `DiagnosticLog.swift:5`, `MonotonicClock.swift:3` | 🟢 |
| Catálogo tipado como única fonte de eventos (001 RN-12) | `LogEventCatalog.swift:33-35` | 🟢 |
| Formatação própria em vez de `JSONEncoder`, para ordem fixa do cabeçalho | `LogEvent.swift:32-47` | 🟢 |
| `ts_ns` tomado na chamada, não na escrita | `DiagnosticLog.swift:43` | 🟢 |
| Limite de 50 MiB só para `debug` | `DiagnosticLog.swift:10` | 🟢 |

## Estado Interno

`handle`, `buffer`, `bytesWritten`, `debugSuspended`, `timer`, `fileURL`, `wallFormatter`, todos acessados na fila `log` (exceto `debugEnabled`, imutável). Máquina de estados do nível `debug`: `state-machines.md` §11. 🟢

## Observabilidade

A própria unit; o único evento sobre si é `log.debug_suspended`. Falhas de abertura vão ao `os.Logger`. 🟢

## Riscos e Lacunas

- 🟢 Sem rotação ou retenção: `~/Library/Logs/joystick-ai` cresce indefinidamente (RN-LG-13; [Revisor]).
- 🟡 Falhas de escrita são silenciosas e perdem eventos sem aviso.
- 🟡 `log.debug_suspended` só é escrito na descarga seguinte à que ultrapassou o limite; o arquivo pode passar alguns KiB de 50 MiB.
- 🟡 Exceções ao princípio de privacidade: `config.value_rejected` registra o valor recusado de `pointer`, `session.start` registra os argumentos, `targets.write_failed` inclui o conteúdo da rodada; nenhum deles contém teclas ou textos digitados.
- 🟡 `wall` usa o fuso local e o calendário gregoriano implícito do `en_US_POSIX`; comparar sessões de fusos diferentes exige `ts_ns` ou conversão.
