# Delta de dados: Prova de conceito de entrada do controle e apontamento

> Identificador: `001-poc-entrada-ponteiro`
> Data: `2026-09-14`
> Roadmap: `_reversa_forward/001-poc-entrada-ponteiro/roadmap.md`
> Base de comparação: `_reversa_sdd/sdd/controller-input.md#9. Modelo de Dados`, `_reversa_sdd/sdd/pointer-control.md#9. Modelo de Dados`, `_reversa_sdd/sdd/action-mapping.md#9. Modelo de Dados`, `_reversa_sdd/sdd/app-shell.md#9. Modelo de Dados`
> Confidência: 🟢 CONFIRMADO, 🟡 INFERIDO, 🔴 LACUNA

Não há banco de dados nem modelo extraído de código; o "modelo existente" são as entidades planejadas nas specs. Este documento registra o que a PoC adota delas, o que omite, o que acrescenta e o que persiste.

## 1. Entidades em memória

### 1.1 `InputEvent` (de `controller-input` §9)

| Campo | Situação na PoC | Observação | Confidência |
|-------|-----------------|------------|-------------|
| `kind` | mantido | `controllerError` só gera linha de log; não há consumidor (`app-shell` fora). | 🟡 |
| `element` | mantido | Um dos 18 identificadores, `leftStick`, `rightStick`, `l2`, `r2`, `touch0` ou `touch1`. | 🟡 |
| `value` | mantido | Gatilhos, de 0,0 a 1,0. | 🟡 |
| `x`, `y` | mantidos | Analógicos e toque, já com zona morta aplicada aos analógicos. | 🟡 |
| `touchIndex` | mantido | 0 ou 1. | 🟡 |
| `touchPhase` | **novo** | `began`, `moved`, `ended`; necessário para RN-05 (descartar o primeiro evento do toque). Origem conforme D-05. | 🔴 |
| `synthetic` | **novo** | `true` nos `buttonUp` gerados por RN-04 antes da desconexão; permite verificar no log a ordem exigida por RF-10. | 🟡 |
| `timestamp` | mantido, renomeado no log para `t_arrival` | Nanossegundos de `CLOCK_UPTIME_RAW`. | 🟡 |
| `frameworkTimestamp` | **novo**, opcional | `lastEventTimestamp` do perfil físico, apenas informativo. | 🟡 |

### 1.2 `ControllerInfo` (de `controller-input` §9)

| Campo | Situação na PoC | Observação | Confidência |
|-------|-----------------|------------|-------------|
| `id` | mantido | UUID gerado a cada conexão. | 🟡 |
| `name` | mantido | `vendorName` do `GCController`. | 🟡 |
| `connection` | mantido | `usb`, `bluetooth` ou `unknown`, pela correlação de D-07. | 🟡 |
| `batteryLevel` | **omitido** | RF-10 da spec é Won't nesta feature. | 🟢 |
| `connectedAt` | **novo** | `t_arrival` da conexão; ordena a fila de RN-01. | 🟡 |
| `atStartup` | **novo** | `true` quando o controle veio da enumeração inicial ou de notificação nos primeiros 2 s do processo (D-25); evidência de RF-03 no log. | 🟡 |

### 1.3 `ActiveControllerRegistry` (novo)

| Campo | Tipo | Descrição | Confidência |
|-------|------|-----------|-------------|
| `queue` | `[ControllerInfo]` | DualSense conectados, em ordem de conexão. | 🟡 |
| `active` | `ControllerInfo?` | Primeiro da fila; derivado, não armazenado em separado. | 🟡 |
| `pressed` | `Set<ButtonID>` | Botões do ativo atualmente pressionados; base de RN-04 e de RN-08 ("sem outro botão"). | 🟡 |

Transições: `connect(dualSense)` enfileira, e uma segunda conexão do mesmo controle (mesma identidade de objeto, D-25) é ignorada; `connect(outroModelo)` gera `controller.ignored`; `disconnect(ativo)` emite `buttonUp` sintético para cada item de `pressed`, depois `controllerDisconnected`, e promove o seguinte; `disconnect(naoAtivo)` apenas remove da fila.

### 1.4 `PointerState` (novo)

| Campo | Tipo | Descrição | Confidência |
|-------|------|-----------|-------------|
| `leftStick`, `rightStick` | `(x: Double, y: Double)` | Última leitura normalizada. | 🟡 |
| `primaryTouch` | `(x, y, fase)?` | Último ponto do primeiro dedo; `nil` sem toque. | 🔴 |
| `pendingTouchDelta` | `(dx, dy)` em pt | Acumulado entre ticks (RN-06). | 🟡 |
| `subpixelRemainder` | `(dx, dy)` em pt | Resto fracionário não emitido. | 🟡 |
| `heldMouseButtons` | `Set<left \| right>` | Botões de mouse pressionados pela PoC; esvaziado em RN-04, RF-23 e perda de permissão. | 🟡 |
| `leftHolders` | `Set<r2 \| touchpadClick>` | Quais botões do controle mantêm o clique esquerdo; o `mouseUp` só sai quando o conjunto esvazia. | 🟡 |
| `lastLeftClick` | `(t_ns, ponto)?` | Base de RN-09; o ponto fica só em memória, nunca no log. | 🟡 |
| `pendingScrollRemainder` | `(dx, dy)` em px ou linhas | Fração de rolagem não emitida (D-13). | 🟡 |
| `timerRunning` | `Bool` | Temporizador de 120 Hz ativo, ligado por qualquer dos dois analógicos fora da zona morta (D-11). | 🟡 |
| `injectionEnabled` | `Bool` | Espelha `CGPreflightPostEventAccess()` (D-15). | 🟡 |

### 1.5 `ScreenUnion` (novo)

| Campo | Tipo | Descrição | Confidência |
|-------|------|-----------|-------------|
| `rects` | `[CGRect]` em coordenadas globais de display (origem superior esquerda) | Um por display ativo. | 🟡 |
| `clamp(p)` | função | Devolve `p` se contido em algum retângulo; senão, o ponto mais próximo do retângulo mais próximo. | 🟡 |

### 1.6 `ConfigLoadResult` (novo)

| Campo | Tipo | Descrição | Confidência |
|-------|------|-----------|-------------|
| `settings` | `PointerSettings` | Valores efetivos após padrões e validação. | 🟡 |
| `status` | `defaults \| loaded \| invalidJSON` | Espelha, em escala menor, `AppState.configStatus` de `app-shell` §9. | 🟡 |
| `issues` | `[ConfigIssue]` | `{campo, valorRejeitado, faixa}` ou `{linha?, mensagem}`. | 🟡 |

## 2. `PointerSettings` (de `pointer-control` §9), somente leitura

A PoC lê os mesmos nomes e padrões, sem acrescentar nem remover campos. Todas as faixas estão fixadas em RF-26: as de `touchpadSensitivity` e `stickMaxSpeed` desde o esclarecimento 1 e as demais desde o esclarecimento 8, que adotou as faixas técnicas antes propostas nesta etapa. A spec `pointer-control` §9 ainda não as contém e deve recebê-las pelo `/reversa-sync`.

| Campo | Padrão | Faixa aceita | Origem da faixa | Confidência |
|-------|--------|--------------|-----------------|-------------|
| `touchpadSensitivity` | 1,0 | 0,1 a 5,0 | RF-26, esclarecimento 1 | 🟢 |
| `stickMaxSpeed` | 1500 | 150 a 7500 | RF-26, esclarecimento 1 | 🟢 |
| `stickExponent` | 2,0 | 0,5 a 4,0 | RF-26, esclarecimento 8 (abaixo de 0,5 a curva vira degrau; acima de 4,0 inclinações médias ficam inertes) | 🟢 |
| `deadzone` | 0,12 | 0,0 a 0,5 | RF-26, esclarecimento 8 (acima de 0,5 metade do curso fica morta) | 🟢 |
| `scrollSpeed` | 40 | 1 a 1000 | RF-26, esclarecimento 8 (RF-14 requer cerca de 100) | 🟢 |
| `invertScrollY` | false | booleano | tipo | 🟢 |
| `precisionFactor` | 0,3 | 0,05 a 1,0 | RF-26, esclarecimento 8 (zero congelaria o cursor) | 🟢 |
| `doubleClickIntervalMs` | 400 | 100 a 2000 | RF-26, esclarecimento 8 | 🟢 |

Regras de leitura: campo ausente ou `null` usa o padrão sem aviso; tipo errado ou valor fora da faixa usa o padrão com aviso `config.value_rejected`; JSON inválido usa todos os padrões com erro `config.invalid_json`. Seções diferentes de `pointer` são ignoradas sem validação. Contrato completo em `interfaces/config-pointer.md`.

**Divergência a sincronizar:** o padrão `scrollSpeed` = 40 não atinge a meta G-03 de `pointer-control`; a PoC mantém o padrão da spec e a calibração define o valor que deve voltar a ela.

## 3. Entidades persistidas novas

Nenhuma delas existe nas specs; ambas são locais, sem rede e sem dados pessoais além dos que o próprio usuário produz. São os dois únicos lugares em que RN-12, na redação do esclarecimento 7, admite gravar entradas do controle.

### 3.1 Registro do log de diagnóstico

- Local: `~/Library/Logs/joystick-ai/poc-<AAAAMMDD-HHMMSS>.jsonl`, um arquivo por sessão.
- Estrutura: um objeto JSON por linha, com `ts_ns`, `wall`, `level`, `event` e campos específicos do evento.
- Permitido: quais entradas ocorreram (botão e fase, início e fim de toque, via do estado de toque) e seus carimbos de tempo.
- Proibido: coordenadas do cursor, deltas de movimento, posições do toque, valores de eixo. Para responder a P-02 sem registrar posições, a Fase 1 registra apenas as transições do toque bruto (`touch.raw_transition`, com o dedo e se o valor foi a (0, 0) ou saiu dele). Por isso, os valores normalizados de RF-06 e RF-08 são verificados por testes, e não pelo log (esclarecimento 6).
- Contrato: `interfaces/diagnostic-log.md`.

### 3.2 Resultado de sequência da tela de alvos (`TargetRun`)

- Local: `~/Library/Application Support/joystick-ai/target-runs/<AAAAMMDD-HHMMSS>-<env>.json`.
- Entidades:

```
TargetRun {
  schemaVersion: Int              // 1
  startedAt: String               // ISO 8601
  environment: Enum               // mesa | sofa (sem acento; ambientes "mesa" e "sofá" do requirements)
  complete: Bool
  abortReason: Enum?              // user | screen_removed | injection_suspended; só quando complete = false
  seed: UInt64
  screen: { name, widthPx, heightPx, widthPt, heightPt, backingScale }
  targetSizePt: Int               // 16
  settings: PointerSettings       // valores efetivos
  scrollUnit: Enum                // pixel | line
  attempts: [TargetAttempt]
  summary: { hits, total, hitRate, meanTimeMs, hitRateWithL1?, hitRateWithoutL1? }
  ignoredPhysicalClicks: Int
}

TargetAttempt {
  index: Int                      // 1 a 20
  targetRectPt: { x, y, w, h }    // posição do alvo na tela, não do cursor
  hit: Bool
  timeToClickMs: Int
  l1Held: Bool
}
```

- Contrato: `interfaces/target-run-result.md`.

### 3.3 Relatório de validação

`_reversa_forward/001-poc-entrada-ponteiro/validation-report.md`, em Markdown, criado como esqueleto e preenchido à mão (D-24). Não é lido por código.

## 4. Campos e entidades das specs que ficam de fora

| Item | Spec | Motivo |
|------|------|--------|
| `ControllerInfo.batteryLevel` | `controller-input` §9 | RF-10 da spec é Won't. |
| `Config.version`, `modifier`, `longPressMs`, `dictation`, `mappings` | `action-mapping` §9 | Mapeamento fixo (RN-11); a PoC lê só `pointer`. |
| `AppState` completo | `app-shell` §9 | Sem menu; reduz-se a `ConfigLoadResult` e `injectionEnabled`. |
| `PersistedState` (`state.json`) | `app-shell` §9 | Sem modo de condução nem "abrir ao iniciar sessão". Também não se guarda se o pedido de Acessibilidade já foi feito: D-15 o repete por processo. |

## 5. Migrações necessárias

Nenhuma. O arquivo `config.json` só é lido; os formatos persistidos novos têm `schemaVersion` (resultado) ou evento `session.start` com `logSchema` (log) para permitir evolução sem migração.

## 6. Histórico de alterações

| Data | Alteração | Autor |
|------|-----------|-------|
| 2026-09-14 | Versão inicial gerada por `/reversa-plan` | reversa |
| 2026-09-14 | Revisão após esclarecimentos 6 a 10: faixas de §2 confirmadas; `ControllerInfo.atStartup` (D-25); `PointerState.pendingScrollRemainder` e temporizador compartilhado (D-11); §3 alinhada à nova RN-12; rótulo `sofa` declarado | reversa |
