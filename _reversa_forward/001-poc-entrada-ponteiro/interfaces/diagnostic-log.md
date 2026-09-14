# Interface: log de diagnóstico

> Feature: `001-poc-entrada-ponteiro`
> Tipo: arquivo, escrita (JSON Lines)
> Produtor: `JoystickAIPoC`
> Consumidores: `poc-tools` (`buttons`, `latency`, `cycles`); o avaliador, por leitura direta
> Origem: `requirements.md` RF-11, RN-12, RNF de observabilidade e de empacotamento; `_reversa_sdd/sdd/controller-input.md#12. Segurança e Privacidade`; `_reversa_sdd/sdd/app-shell.md#6.1 Requisitos Principais` (RF-12)
> Confidência: 🟡

## 1. Localização e ciclo de vida

- Diretório: `~/Library/Logs/joystick-ai/`, criado se ausente.
- Arquivo: `poc-<AAAAMMDD-HHMMSS>.jsonl`, hora local de início da sessão; um arquivo por execução.
- Sem rotação: sessões da PoC são curtas. Um arquivo acima de 50 MiB deixa de receber eventos de nível `debug` e registra `log.debug_suspended` uma vez.
- O Console do macOS abre o diretório diretamente.

## 2. Formato do registro

Cada linha é um objeto JSON independente, terminado por `\n`:

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| `ts_ns` | inteiro | sim | `clock_gettime_nsec_np(CLOCK_UPTIME_RAW)` no momento da escrita lógica do evento. |
| `wall` | string | sim | Hora local ISO 8601 com milissegundos, apenas para leitura humana. |
| `level` | string | sim | `debug`, `info`, `warn`, `error`. |
| `event` | string | sim | Nome do evento (seção 3). |
| demais | variável | por evento | Ver seção 3. |

## 3. Eventos

Eventos `debug` só aparecem com `--debug`. Os eventos registram quais entradas ocorreram e quando; nenhum contém coordenadas do cursor, deltas de movimento, posições do toque ou valores de eixo (RN-12, esclarecimento 7).

| Evento | Nível | Campos | Requisito |
|--------|-------|--------|-----------|
| `session.start` | info | `logSchema: 1`, `appVersion`, `macOS`, `pid`, `debug`, `args`, `signing: {identifier, teamOrCertName, designatedRequirement}` | RF-25 e |
| `permissions.status` | info | `postEvent: bool`, `listenEvent: bool`, `trigger: startup \| poll` (só na mudança) | RF-22, P-04 |
| `permissions.guidance` | warn | `message` com o caminho em Ajustes do Sistema | RF-22 |
| `config.loaded` / `config.value_rejected` / `config.invalid_json` / `config.unreadable` | info/warn/error | ver `config-pointer.md#3` | RF-26 |
| `displays.changed` | info | `count` | RF-21 |
| `cursor.reclamped` | info | sem campos | RF-21 |
| `controller.connected` | info | `id`, `name`, `connection`, `atStartup`, `t_arrival` | RF-01, RF-03, D-25 |
| `controller.ignored` | info | `name`, `productCategory`, `reason` | RF-09 |
| `controller.queued` | info | `id`, `position` | RF-09 |
| `controller.disconnected` | info | `id`, `t_arrival` | RF-02 |
| `controller.elements` | debug | `names: [string]`, `touchpads: [string]` | P-01, P-03 |
| `controller.touch_source` | info | `id`, `source: touchState \| zero_transition` | P-01, D-05 |
| `controller.gesture_suppression` | info | `elements: ["buttonHome"]`, `message` com o pedido feito e a instrução de verificação visual; emitido em toda conexão, qualquer que seja a resposta do macOS | RF-24, D-23 |
| `controller.error` | error | `message` | `controller-input` §8 |
| `input.button` | debug | `button`, `phase: down \| up`, `synthetic`, `t_arrival`, `t_delivered`, `t_framework?` | RF-05, RF-10, RF-11 |
| `input.touch` | debug | `finger: 0 \| 1`, `phase: began \| ended`, `t_arrival`, `t_delivered` | RF-08 |
| `touch.raw_transition` | debug | `finger`, `toZero: bool` | P-02 |
| `pointer.posted` | debug | `kind: move \| drag \| scroll \| down \| up`, `button?`, `source: touch \| stick_onset \| button`, `clickState?`, `t_arrival`, `t_posted` | RF-11, D-19 |
| `pointer.injection_suspended` / `pointer.injection_resumed` | warn/info | `heldButtons` | RF-22, R-08 |
| `targets.screens` | info | `screens: [{index, name, widthPt, heightPt, backingScale}]`; emitido a cada início da PoC, com ou sem `--targets`, e novamente em `displays.changed` | RF-27, D-20 |
| `targets.started` / `targets.finished` | info | `env`, `seed`, `complete`, `abortReason?`, `file` | RF-27 |
| `targets.invalid_args` / `targets.screen_fallback` / `targets.write_failed` | warn/warn/error | `message`; em `write_failed`, também `payload` com o JSON do resultado | RF-27 |
| `app.terminating` | info | `reason: quit \| sigterm \| sigint \| sighup`, `releasedButtons` | RF-23 |
| `log.debug_suspended` | warn | `sizeBytes` | limite da seção 1 |

Movimentos dos ticks de 120 Hz posteriores ao início não geram `pointer.posted`, pois não têm entrada única de origem (D-19) e multiplicariam o volume do log.

## 4. Cálculos derivados (`poc-tools`)

| Comando | Entrada | Saída |
|---------|---------|-------|
| `poc-tools latency <log>` | `input.*` e `pointer.posted` | contagem, p50, p95 e máximo de `t_delivered − t_arrival` e de `t_posted − t_arrival`, em ms, com indicação de aprovação contra 5 ms e 20 ms |
| `poc-tools buttons <log>` | `input.button` não sintéticos | tabela dos 18 identificadores com `down` e `up` observados; total "N de 18" |
| `poc-tools cycles <log>` | `session.start`, `controller.connected`, `controller.disconnected` | ciclos completos, conexões sem desconexão correspondente, número de sessões no arquivo (mais de uma indica reinício) |

## 5. Erros

- Falha ao criar o diretório ou abrir o arquivo: a PoC segue sem log de arquivo e escreve um único aviso no Unified Logging (subsistema `dev.iagoleal.joystick-ai.poc`), já que não há outro canal visível.
- Falha de escrita no meio da sessão: descartam-se os eventos pendentes e tenta-se de novo no próximo *flush*.

## 6. Idempotência, ordem e desempenho

- A ordem das linhas segue a ordem de envio à fila `log`, que é serial; `ts_ns` é monotônico dentro da sessão.
- Os carimbos `t_*` são tomados na fila `input` antes do envio, de modo que o custo de escrita não entra na latência medida.
- *Flush* a cada 250 ms ou 256 KiB, e sempre em `app.terminating`.

## 7. Timeouts

Não se aplica: escrita local assíncrona.
