# Interface: log de diagnóstico (delta do DualShock 4)

> Feature: `012-controle-dualshock-4`
> Tipo: arquivo, escrita (JSON Lines)
> Contrato base: `_reversa_forward/001-poc-entrada-ponteiro/interfaces/diagnostic-log.md`, com os deltas de `002`, `003`, `004`, `007-controle-ipega` e `011-bateria-e-cursor-no-menu`
> Origem: `requirements.md` RN-08, RF-13, RNF de observabilidade e de privacidade; `roadmap.md` D-07
> Confidência: 🟢

## 1. O que muda

Localização, formato, *flush*, ordem e tratamento de erros seguem o contrato base. `logSchema` continua `1`: nenhum campo novo, nenhum evento novo; entra um valor a mais num campo existente.

## 2. Eventos alterados

| Evento | Antes | Depois | Requisito |
|--------|-------|--------|-----------|
| `controller.connected` | `model: "dualSense" \| "ipega"` | Mais `"dualShock4"`; `connection` vale `bluetooth` ou `usb` pelo transporte do IORegistry, e `charge` e `chargeState` seguem a regra da 011 (omitidos quando indisponíveis) | RN-08, RF-13 |
| `controller.ignored` | `name`, `productCategory`, `reason: "unsupported_model"` | Sem mudança de forma; deixa de ocorrer para o DualShock 4 e continua ocorrendo, uma vez por conexão, para outras identidades (o GameSir em outro modo, um controle Xbox) | RN-01 |
| `controller.extended_report` | Só para o DualSense por Bluetooth | Também para o DualShock 4 por Bluetooth, com `transport: bluetooth` e `result` (D-05) | RN-04 |
| `controller.touch_source` | Só para o DualSense | Também para o DualShock 4, com a fonte escolhida (D-03) | RN-04 |
| `input.button` | 19 valores de `button` | Sem mudança; com o DualShock 4, só os 18 do DualSense ocorrem (`share` nunca) | RN-03 |

Linha observada antes da feature, no log de 2026-09-22 (o controle recusado):

```json
{"ts_ns":46110074703416,"wall":"2026-09-22T13:24:13.352-03:00","level":"info","event":"controller.ignored","name":"DUALSHOCK 4 Wireless Controller","productCategory":"DualShock 4","reason":"unsupported_model"}
```

Linha esperada depois da feature (campos após `event` em ordem alfabética, como grava `LogEvent`):

```json
{"ts_ns":…,"wall":"…","level":"info","event":"controller.connected","atStartup":true,"charge":55,"chargeState":"discharging","connection":"bluetooth","id":"…","model":"dualShock4","name":"DUALSHOCK 4 Wireless Controller","t_arrival":…}
```

## 3. Consumidores

- `LogAnalysis.buttonCoverage` e `poc-tools buttons`: com `model: "dualShock4"`, esperam os 18 identificadores sem `share`; o texto de ajuda da ferramenta passa a citar os três modelos (D-07). Sem `model`, DualSense, como na 007.
- `LogAnalysis.cycles` e `poc-tools latency`: sem mudança.
- `LogEventCatalogTests.sampleEvents`: passa a incluir `controllerConnected` com `model: .dualShock4` e carga, para o teste de chaves proibidas cobri-lo.

## 4. Privacidade

Nenhum valor de eixo, posição de toque, texto ou acorde entra no log. O endereço Bluetooth e o número de série do controle não são registrados. O canal Bluetooth Low Energy do GameSir não produz linha alguma.
