# Log de diagnóstico (diagnostics-log)

> Unit do módulo `diagnostics-log` · Gerado pelo Redator em 2026-09-15 · Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA

## Visão Geral

Registro local em JSON Lines, um arquivo por sessão, com carimbos monotônicos para medir latência e 50 eventos tipados que nunca carregam coordenadas, deltas, valores de eixo, teclas ou textos digitados. É a fonte das análises de `poc-tools` e das validações das features. Inclui os tipos de apoio `JSONValue` e `MonotonicClock`. 🟢

## Responsabilidades

- Criar um arquivo novo por sessão em `~/Library/Logs/joystick-ai`. 🟢
- Formatar cada evento como uma linha JSON determinística. 🟢
- Escrever fora das filas `main` e `input`, com *buffer* e descarga periódica. 🟢
- Filtrar eventos `debug` conforme `--debug` e suspendê-los acima de 50 MiB. 🟢
- Descarregar de forma síncrona no encerramento. 🟢
- Oferecer um catálogo único de fábricas de eventos, sem campos sensíveis. 🟢
- Fornecer o relógio monotônico de todos os carimbos `t_*`. 🟢

## Regras de Negócio

- RN-LG-01: Arquivo `~/Library/Logs/joystick-ai/poc-AAAAMMDD-HHmmss.jsonl` (hora local do início); se já existir, sufixos `-2`, `-3`… O diretório é criado se faltar. 🟢
- RN-LG-02: Sem conseguir criar o diretório ou o arquivo, o app segue sem log e registra o erro no `os.Logger` (subsistema `dev.iagoleal.joystick-ai.poc`, categoria `log`). 🟢
- RN-LG-03: Cada linha começa por `ts_ns` (monotônico, tomado na chamada), `wall` (`yyyy-MM-dd'T'HH:mm:ss.SSS±HH:MM`, `en_US_POSIX`), `level` e `event`, seguidos dos demais campos em ordem alfabética; campos com esses quatro nomes são ignorados; termina em `\n`. 🟢
- RN-LG-04: Serialização compacta: objetos com chaves ordenadas; `double` inteiro com `.0`; `double` não finito vira `null`; aspas, barra invertida, `\n`, `\r`, `\t` escapados e demais controles como `\u00XX`; outros caracteres Unicode sem escape. 🟢
- RN-LG-05: Níveis ordenados `debug < info < warn < error`. Sem `--debug`, eventos `debug` são descartados na chamada. 🟢
- RN-LG-06: Com `--debug`, quando os *bytes* escritos passam de 50 MiB, grava-se `log.debug_suspended { sizeBytes }` (`warn`) e os eventos `debug` seguintes são descartados; os demais continuam. 🟢
- RN-LG-07: Escrita na fila serial `log` (`utility`): *buffer* descarregado a cada 250 ms ou ao atingir 256 KiB. 🟢
- RN-LG-08: Falha de escrita descarta o *buffer* pendente e tenta de novo na próxima descarga. 🟢
- RN-LG-09: No encerramento, `flushSync` descarrega de forma síncrona depois de `app.terminating`. 🟢
- RN-LG-10: Nenhuma fábrica aceita coordenadas do cursor, deltas, posições do toque ou valores de eixo; eventos de paleta usam índices a partir de 1 e nunca o texto; eventos de atalhos usam caminho, linha, regra e contagens, nunca texto, rótulo, nome de tecla ou acorde. 🟢
- RN-LG-11: Carimbos `t_*` (`t_arrival`, `t_delivered`, `t_posted`) e `ts_ns` vêm de `clock_gettime_nsec_np(CLOCK_UPTIME_RAW)`, em nanossegundos, e não avançam durante o repouso do Mac. 🟢
- RN-LG-12: `session.start` é o primeiro evento, com `logSchema: 1`, `appVersion`, `macOS`, `pid`, `debug`, `args` e `signing`. 🟢
- RN-LG-13: Não há rotação nem limpeza de arquivos antigos. 🟢 (nenhum `removeItem` nem `contentsOfDirectory` em `Log/`; [Revisor])
- RN-LG-14: Catálogo de 50 eventos por nível:

| Nível | Eventos |
|-------|---------|
| `debug` (6) | `controller.elements`, `input.button`, `input.touch`, `touch.raw_transition`, `pointer.posted`, `shortcuts.unchanged` |
| `info` (29) | `session.start`, `permissions.status`, `config.loaded`, `displays.changed`, `cursor.reclamped`, `controller.connected`, `controller.ignored`, `controller.queued`, `controller.disconnected`, `controller.touch_source`, `controller.gesture_suppression`, `controller.extended_report`, `pointer.injection_resumed`, `targets.screens`, `targets.started`, `targets.finished`, `app.terminating`, `palette.opened`, `palette.confirmed`, `palette.closed`, `palette.blocked`, `shortcuts.loaded`, `shortcuts.file_removed`, `shortcuts.saved`, `shortcuts.restored`, `shortcut.triggered`, `editor.opened`, `editor.closed`, `editor.identify` |
| `warn` (9) | `permissions.guidance`, `config.value_rejected`, `pointer.injection_suspended`, `targets.invalid_args`, `targets.screen_fallback`, `palette.invalid_args`, `editor.conflict`, `editor.activation_failed`, `log.debug_suspended` |
| `error` (6) | `config.invalid_json`, `config.unreadable`, `controller.error`, `targets.write_failed`, `shortcuts.invalid`, `shortcuts.save_failed` |

🟢

## Requisitos Funcionais

| ID | Requisito | Prioridade | Critério de Aceite |
|----|-----------|-----------|-------------------|
| RF-LG-01 | Um arquivo JSONL por sessão | Must | Duas aberturas no mesmo segundo geram `poc-…jsonl` e `poc-…-2.jsonl` |
| RF-LG-02 | Linha determinística com cabeçalho fixo | Must | Toda linha é JSON válido e começa por `{"ts_ns":` |
| RF-LG-03 | Filtro e suspensão de `debug` | Must | Sem `--debug` não há `input.button`; acima de 50 MiB surge `log.debug_suspended` |
| RF-LG-04 | Escrita sem bloquear entrada | Must | O registro ocorre na fila `log` |
| RF-LG-05 | Descarga no encerramento | Must | `app.terminating` está no arquivo após ⌘Q, SIGTERM, SIGINT ou SIGHUP |
| RF-LG-06 | Catálogo sem dados sensíveis | Must | Nenhum evento contém coordenada, eixo, tecla ou texto |
| RF-LG-07 | Carimbos monotônicos para latência | Must | `poc-tools latency` calcula `t_posted − t_arrival` |

## Requisitos Não Funcionais

| Tipo | Requisito inferido | Evidência no código | Confiança |
|------|--------------------|---------------------|-----------|
| Performance | Formatação e escrita fora das filas críticas | `DiagnosticLog.swift:15,44-54` | 🟢 |
| Privacidade | Catálogo fechado sem campos sensíveis | `LogEventCatalog.swift:33-35` | 🟢 |
| Armazenamento | Limite de 50 MiB só para `debug` | `DiagnosticLog.swift:10,102-106` | 🟢 |
| Reprodutibilidade | Chaves ordenadas e números estáveis | `JSONValue.swift:14-55` | 🟢 |
| Durabilidade | Até 250 ms de eventos podem se perder numa queda abrupta | `DiagnosticLog.swift:8` | 🟡 |

## Critérios de Aceitação

```gherkin
Dado o app iniciado sem --debug às 14:03:05 de 15/09/2026
Quando o log é aberto
Então existe ~/Library/Logs/joystick-ai/poc-20260915-140305.jsonl
E a primeira linha é session.start com logSchema 1 e debug false

Dado LogEvent("palette.confirmed", info, {index: 3, enter: false})
Quando é formatado com ts_ns 42 e wall "2026-09-15T14:03:05.123-03:00"
Então a linha é {"ts_ns":42,"wall":"2026-09-15T14:03:05.123-03:00","level":"info","event":"palette.confirmed","enter":false,"index":3}

Dado o app sem --debug
Quando input.button é registrado
Então nada é escrito

Dado --debug e 50 MiB já escritos
Quando a próxima descarga ocorre
Então log.debug_suspended é escrito e input.button seguintes são descartados
E palette.opened continua sendo escrito

Dado JSONValue.double(2)
Quando é serializado
Então o texto é "2.0"
```

## Prioridade (MoSCoW)

| Requisito | MoSCoW | Justificativa |
|-----------|--------|---------------|
| Arquivo por sessão, formato, fila | Must | Base das validações da PoC |
| Catálogo sem dados sensíveis | Must | Privacidade do que é digitado |
| Suspensão de `debug` | Must | Evita encher o disco |
| Rotação de arquivos | Won't (nesta versão) | Volume atual pequeno (43 arquivos, 5,8 MB) |

## Rastreabilidade de Código

| Arquivo | Função / Classe | Cobertura |
|---------|-----------------|-----------|
| `Sources/JoystickCore/Log/LogEvent.swift` | `LogLevel`, `LogEvent`, `LogLineFormatter` | 🟢 |
| `Sources/JoystickCore/Log/LogEventCatalog.swift` | Enums de campo, `ScreenListing`, `LogEventCatalog` | 🟢 |
| `Sources/JoystickCore/Support/JSONValue.swift` | `JSONValue` | 🟢 |
| `Sources/JoystickCore/Support/MonotonicClock.swift` | `MonotonicClock` | 🟢 |
| `Sources/JoystickAIPoC/Log/DiagnosticLog.swift` | `DiagnosticLog` | 🟢 |
