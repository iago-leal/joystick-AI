# Tela de alvos e análise (targets-analysis), Design Técnico

> Gerado pelo Redator em 2026-09-15 · Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA

## Interface

### Núcleo

| Símbolo | Assinatura | Observação |
|---------|-----------|------------|
| `TargetRun` | `Codable`; `attemptsPerRun 20`, `targetSize 16`, `marginPt 40`; `init(startedAt:environment:complete:abortReason:seed:screen:settings:scrollUnit:attempts:ignoredPhysicalClicks:)` | `summary` calculado no `init` |
| `TargetRun.summarize(_:)` | `[TargetAttempt] → TargetSummary` | — |
| `TargetRun.timestamp(_:)` | `Date → String` | `ISO8601DateFormatter [.withInternetDateTime]`, fuso local |
| `TargetRun.fileName(startedAt:environment:exists:)` | `→ String` | Sufixo em colisão |
| `SeededGenerator(seed:)` | `RandomNumberGenerator` | SplitMix64 |
| `TargetLayout.positions(seed:widthPt:heightPt:count:size:margin:)` | `→ [RectPt]` | — |
| `LatencyStats.summarize(_:)` | `[UInt64] → LatencySummary?` | `count`, `p50Ms`, `p95Ms`, `maxMs`, `passes(thresholdMs:)` |
| `LogAnalysis.read(contents:)` | `→ LogReadResult { records, malformedLines }` | — |
| `LogAnalysis.buttonCoverage(_:)`, `cycles(_:)`, `latencySamples(_:)` | Registros → resumo | — |
| `RunsReport.markdown(runs:environment:)` | `→ String` | `outlierThresholdMs 60000` |

### App (main thread)

| Símbolo | Observação |
|---------|------------|
| `TargetSession(log:writer:context:screen:environment:seed:settings:scrollUnit:)` | `start()`, `abort(_:)`, `isActive`, `screen`, `onFinish`; `summaryDuration 3 s` |
| `TargetAbortMonitor(session:context:router:displayMonitor:gate:)` | `start()`, `stop()` |
| `TargetRunWriter(log:directory:)` | `write(_:startedAt:) → URL?`; `defaultDirectory` |
| `TargetWindow(screen:)`, `TargetView` | `target`, `counter`, `summary`, `rect(of:)` |
| `ScreenCatalog` | `listings()`, `emit(log:)`, `descriptor(for:)`, `displayID(of:)` |

### CLI (`poc-tools`)

| Comando | Entrada | Saída |
|---------|---------|-------|
| `buttons <log>` | Log com `--debug` | Tabela `Botão / down / up` + total |
| `runs [--env] [--dir]` | Diretório `target-runs` | Tabela do bloco (b) |
| `latency <log>` | Log com `--debug` | Tabela `Medida / Amostras / p50 / p95 / Máximo / Aprovada` |
| `cycles <log>` | Log | Tabela `Medida / Valor` |
| `help [cmd]`, `-h`, `--help` | — | Uso |

## Fluxo Principal

### Abertura (`AppDelegate.swift:137-139,146-190`)

```
se arguments.targets: openTargets
  para cada erro que não é da paleta: invalidScreen → pula; outro → targets.invalid_args
  env ausente → retorna
  sem telas → targets.invalid_args "nenhuma tela ativa"; retorna
  index ← --screen; invalidScreen ou index > telas → targets.screen_fallback; index ← 1
  seed ← --seed ?? aleatório(0…UInt32.max)
  session, abortMonitor; paleta.blocked ← true (fila input)
  onFinish: paleta.blocked ← false; abortMonitor.stop(); libera referências
  abortMonitor.start(); session.start()
```

### Sessão (`TargetSession.swift`)

1. `start`: `startedAt`; `positions = TargetLayout.positions(seed, frame.width, frame.height)`; `TargetWindow`; monitor local `[.leftMouseDown, .keyDown]`; `NSApp.activate(ignoringOtherApps: true)`; `makeKeyAndOrderFront`; `targets.started`; `showNextTarget`.
2. `handle(event)`: inativa → segue; `keyDown` Esc (53) → `abort(.user)`, consome; `leftMouseDown` na janela: sem marca → `ignoredPhysicalClicks += 1`, consome; com marca → `recordAttempt`, consome; outros → segue.
3. `recordAttempt`: `elapsedMs = (agora − targetShownNs) / 1e6` (divisão inteira); `hit = rect(alvo).contains(convert(locationInWindow))`; `l1Held = input.sync { registry.pressed.contains(.l1) }`; acrescenta; `showNextTarget`.
4. `showNextTarget`: 20 tentativas → `finish(complete: true)`; senão contador, alvo e `targetShownNs`.
5. `finish`: inativa; remove monitor; monta `TargetRun` com `ScreenCatalog.descriptor`; completa → oculta o alvo, mostra o resumo, grava e fecha após 3 s; interrompida → grava e fecha.
6. `close`: `orderOut`; solta a janela; `onFinish`.

### Interrupções (`TargetAbortMonitor.swift`)

`start`: na fila `input`, `router.onButtonDown = { ○ → main: session.abort(.user) }` (o roteador só chama com pressionar não sintético); `displayMonitor.onChange` → se a tela (por `NSScreenNumber`) sumiu, `abort(.screenRemoved)`; `gate.onSuspended` → `abort(.injectionSuspended)`. `stop` desfaz os três. 🟢

### Layout (`TargetRun.swift:151-179`)

`state += 0x9E3779B97F4A7C15; z = (z ⊕ z>>30)·0xBF58476D1CE4E5B9; z = (z ⊕ z>>27)·0x94D049BB133111EB; z ⊕ z>>31`. Para cada alvo, `x = Int.random(in: 40...max(40, W−56))`, depois `y` análogo. 🟢

### Gravação (`TargetRunWriter.swift`)

`JSONEncoder [.prettyPrinted, .withoutEscapingSlashes]` → cria diretório → `fileName` → `write(.withoutOverwriting)` → `targets.finished`. Falha de codificação → `write_failed` com `payload` vazio; falha de escrita → `write_failed` com JSON compacto. 🟢

### Análise (`LogAnalysis.swift`, `LatencyStats.swift`, `RunsReport.swift`)

- `read`: `enumerateLines`; ignora brancas; `JSONValue` objeto → registro; senão malformada.
- `buttonCoverage`: `input.button`, `synthetic ≠ true`, `phase down|up`.
- `cycles`: conta `session.start`; `controller.connected` abre `id`; `controller.disconnected` do mesmo `id` fecha e conta.
- `latencySamples`: RN-TA-23.
- `LatencyStats.summarize`: ordena; `percentile(p) = sorted[max(1, ⌈p·n⌉) − 1] / 1e6`.
- `RunsReport.markdown`: RN-TA-24; parâmetros alterados comparando `jsonValue` de cada campo com `PointerSettings()`; números inteiros sem casas; porcentagens arredondadas.

### CLI (`main.swift`, `ToolInput.swift`)

Sem subcomando → uso em `stderr`, 64. `-h`/`--help` no resto de um subcomando conhecido → ajuda, 0. `help` sem tópico → uso, 0; tópico desconhecido → 64. `readLog`: exatamente 1 argumento (senão 64); inexistente ou ilegível → 66; malformadas → aviso. `runs`: `--env`/`--dir` com valor; outro argumento → 64; `--env` inválido → 64; diretório ilegível → 66. 🟢

## Fluxos Alternativos

- **○ pelo controle:** além de abortar, ○ segue aos atalhos e posta Esc (padrão); o Esc injetado chega ao monitor e a segunda interrupção é ignorada por `isActive`. 🟡
- **Clique do R2 (direito):** não é `leftMouseDown`; segue normalmente e não conta. 🟢
- **App inativo:** o monitor local só recebe eventos entregues ao app; a ativação no início da sessão pode ser recusada como no editor (sonda P-01), e cliques poderiam não chegar. 🟡
- **Tela removida durante o resumo de 3 s:** `abort` é ignorado (sessão já inativa); a gravação ocorre ao fim do intervalo. 🟢

## Dependências

- `ponteiro`: `PointerSettings`, `ScrollUnit`, `DisplayMonitor.onChange`, `InputRouter.onButtonDown`. 🟢
- `entrada-do-controle`: `InputContext.registry.pressed`, `ButtonID`. 🟢
- `injecao-de-eventos`: `EventInjector.sourceMark`. 🟢
- `aplicativo`: `LaunchArguments`, `InjectionGate.onSuspended`, bootstrap. 🟢
- `paleta`: `PaletteActions.blocked`. 🟢
- `log-de-diagnostico`: `targets.*`, `JSONValue`, `MonotonicClock`, formato do log lido pela CLI. 🟢
- AppKit (janela, monitor local), Foundation. 🟢

## Decisões de Design Identificadas

| Decisão | Evidência | Confiança |
|---------|-----------|-----------|
| Tela de alvos embutida no app, aberta por argumentos (001 D-20) | `AppDelegate.swift:145` | 🟢 |
| Semente reproduzível (001 RF-27) | `TargetRun.swift:151` | 🟢 |
| Distinção de cliques pela marca do injetor (ADR-005) | `TargetSession.swift:72-77` | 🟢 |
| Ponto do clique não persistido (001 RN-12) | `TargetSession.swift:89` | 🟢 |
| CLI separada lendo o log JSONL (001 D-19, RF-25) | `Sources/poc-tools/main.swift:3` | 🟢 |
| Percentil pela posição mais próxima | `LatencyStats.swift:14` | 🟢 |
| Latência medida até o `CGEvent.post` (R-12) | `LatencyCommand.swift:14` | 🟢 |
| Paleta bloqueada na tela de alvos (002 D-13) | `AppDelegate.swift:177` | 🟢 |

## Estado Interno

`TargetSession`: `window`, `monitor`, `positions`, `attempts`, `ignoredPhysicalClicks`, `targetShownNs`, `startedAt`, `isActive`. `TargetAbortMonitor`: `screenID`. Máquina de estados: `state-machines.md` §10. 🟢

## Observabilidade

`targets.screens`, `targets.started`, `targets.finished`, `targets.invalid_args`, `targets.screen_fallback`, `targets.write_failed`. A CLI escreve avisos em `stderr` e tabelas em `stdout`. 🟢

## Riscos e Lacunas

- 🟢 L-03: nenhuma sequência gravada (`target-runs` vazio) e medições do PM-3 pendentes; a unit está implementada, sem evidência de uso, e as medições continuam planejadas.
- 🟡 `Int.random(in:using:)` depende do algoritmo da biblioteca padrão; outra versão do Swift pode mudar as posições da mesma semente.
- 🟢 `runs` ordena `startedAt` como texto; sequências com fusos diferentes podem sair fora de ordem (`RunsReport.swift:10`; [Revisor]).
- 🟢 `timeToClickMs` trunca em vez de arredondar, enquanto `meanTimeMs` arredonda (`TargetSession.swift:88`, `TargetRun.swift:115`; [Revisor]).
- 🟢 Erros de `--seed` ou `--scroll-unit` sem `--targets` não são registrados; `--scroll-unit` inválido mantém `pixel` em silêncio (`AppDelegate.swift:136-150`, `LaunchArguments.swift:42`, `:102-108`; [Revisor]).
- 🟢 A mesma sessão só registra cliques esquerdos; a precisão do clique direito (R2) não é medida (`TargetSession.swift:51`, `:72`; [Revisor]).
