# Interface: log de diagnóstico (delta do controle Ipega)

> Feature: `007-controle-ipega`
> Tipo: arquivo, escrita (JSON Lines)
> Contrato base: `_reversa_forward/001-poc-entrada-ponteiro/interfaces/diagnostic-log.md`, com os deltas de `002-paleta-comandos`, `003-editor-atalhos` e `004-figura-controle-web`
> Origem: `requirements.md` RN-11, RF-12, RNF de observabilidade e de privacidade; `roadmap.md` D-07, D-10
> Confidência: 🟢 salvo indicação

## 1. O que muda

Localização, formato, *flush*, ordem e tratamento de erros seguem o contrato base. `logSchema` continua `1`: entra um campo aditivo e muda um valor sem consumidor interno.

## 2. Eventos alterados

| Evento | Antes | Depois | Requisito |
|--------|-------|--------|-----------|
| `controller.connected` | `id`, `name`, `connection`, `atStartup`, `t_arrival` | Mais `model: "dualSense" \| "ipega"` | RN-11, RF-12 |
| `controller.ignored` | `reason: "not_dualsense"` | `reason: "unsupported_model"`; `name` e `productCategory` iguais | RN-01, RN-11 |
| `input.button` | `button` em 18 valores | Mais `button: "share"` | RN-05 |

Linha observada antes da feature, no log de 2026-09-19 (o Ipega recusado):

```json
{"ts_ns":15458394427625,"wall":"2026-09-19T11:04:29.570-03:00","level":"info","event":"controller.ignored","name":"Pro Controller","productCategory":"Switch Pro Controller","reason":"not_dualsense"}
```

Linha esperada depois da feature (campos após `event` em ordem alfabética, como grava `LogEvent`):

```json
{"ts_ns":…,"wall":"…","level":"info","event":"controller.connected","atStartup":true,"connection":"usb","id":"…","model":"ipega","name":"Pro Controller","t_arrival":…}
```

## 3. Consumidores

- `LogAnalysis.buttonCoverage` e `poc-tools buttons`: esperam o conjunto do modelo do último `controller.connected`; sem `model`, DualSense (D-10).
- `LogAnalysis.cycles`: sem mudança.
- `LogEventCatalogTests.sampleEvents`: passa a incluir `controllerConnected` com `model` e `controllerIgnored` com `unsupported_model`, para o teste de chaves proibidas cobri-los.

## 4. Privacidade

Nenhum valor de eixo, posição, texto ou acorde entra nos campos novos. O número de série do Ipega não é registrado.
