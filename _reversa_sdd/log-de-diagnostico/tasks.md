# Log de diagnóstico (diagnostics-log), Tarefas de Implementação

> Gerado pelo Redator em 2026-09-15 · Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA

## Pré-requisitos

- [ ] Nenhum; é a primeira unit a construir, junto com os tipos de valor que o catálogo referencia

## Tarefas

- [ ] T-01, Implementar `JSONValue` (serialização determinística, acesso, `Codable`, literais)
  - Origem no legado: `Sources/JoystickCore/Support/JSONValue.swift`
  - Critério de pronto: `SupportTests`; `double(2)` → `2.0`; `NaN` → `null`; controles escapados
  - Confiança: 🟢

- [ ] T-02, Implementar `MonotonicClock`
  - Origem no legado: `Sources/JoystickCore/Support/MonotonicClock.swift`
  - Critério de pronto: valores crescentes em nanossegundos
  - Confiança: 🟢

- [ ] T-03, Implementar `LogLevel`, `LogEvent` e `LogLineFormatter`
  - Origem no legado: `Sources/JoystickCore/Log/LogEvent.swift`
  - Critério de pronto: cabeçalho fixo, campos ordenados, reservados ignorados
  - Confiança: 🟢

- [ ] T-04, Implementar `LogEventCatalog` com os 50 eventos e níveis de RN-LG-14
  - Origem no legado: `Sources/JoystickCore/Log/LogEventCatalog.swift`
  - Critério de pronto: `LogEventCatalogTests` (8); nenhuma fábrica recebe coordenada, eixo, tecla ou texto
  - Confiança: 🟢

- [ ] T-05, Implementar `DiagnosticLog` (arquivo por sessão, fila, *buffer*, descarga, suspensão de `debug`)
  - Origem no legado: `Sources/JoystickAIPoC/Log/DiagnosticLog.swift`
  - Critério de pronto: arquivo criado com sufixo em colisão; `debug` filtrado; `flushSync` grava tudo
  - Confiança: 🟢

- [ ] T-06, Registrar `session.start` como primeiro evento e `app.terminating` + `flushSync` no encerramento
  - Origem no legado: `Sources/JoystickAIPoC/App/AppDelegate.swift:39-46`, `Lifecycle.swift:33-41`
  - Critério de pronto: primeira e última linhas do arquivo em ⌘Q e SIGTERM
  - Confiança: 🟢

## Tarefas de Teste

- [ ] TT-01, `SupportTests` (5) e `LogEventCatalogTests` (8)
- [ ] TT-02, Validar que todas as linhas de um log real são JSON (`poc-tools` lê sem erro)
- [ ] TT-03, Sessão com `--debug` e movimento contínuo: tamanho do arquivo e ausência de atraso na entrada
- [ ] TT-04, Busca nos logs por coordenadas, nomes de tecla e textos da paleta: nenhuma ocorrência

## Ordem Sugerida

1. T-01 e T-02.
2. T-03 e T-04.
3. T-05 e T-06.

## Lacunas Pendentes (🔴)

Nenhuma. A falta de rotação de arquivos está confirmada (🟢) e é candidata a decisão de produto.
