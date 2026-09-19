# Interface: log de diagnóstico (delta do teclado remoto)

> Feature: `008-iphone-teclado-remoto`
> Tipo: arquivo, escrita (JSON Lines)
> Contrato base: `_reversa_forward/001-poc-entrada-ponteiro/interfaces/diagnostic-log.md`, com os deltas de 002 a 004 e `_reversa_forward/007-controle-ipega/interfaces/diagnostic-log.md`
> Origem: `requirements.md` RN-13, RF-13; `roadmap.md` D-18
> Confidência: 🟢 salvo indicação

## 1. O que muda

Localização, formato, *flush*, ordem e tratamento de erros seguem o contrato base. `logSchema` continua `1`: só entram eventos novos.

## 2. Eventos novos

| Evento | Nível | Campos | Quando |
|--------|-------|--------|--------|
| `remote.enabled` | info | `port`, `channelPort` | Listeners prontos |
| `remote.disabled` | info | `reason`: `menu`, `quit`, `listener_failed` | Recurso desligado |
| `remote.connected` | info | `resumed`: booleano (token) | `welcome` enviado |
| `remote.rejected` | warn | `reason`: `not_local`, `bad_origin`, `bad_code`, `bad_token`, `busy`, `code_rotated`, `no_identity`, `host_mismatch`, `expired` | Conexão ou ligação recusada |
| `remote.watchdog` | warn | `held`: número de teclas e modificadores soltos | Vigia de D-11 disparado |
| `remote.disconnected` | info | `reason`: `bye`, `closed`, `timeout`, `invalid_messages`, `replaced`, `disabled`; `keys`: teclas pressionadas na sessão | Fim da sessão |

## 3. Proibições

Nenhum evento `remote.*` leva código de tecla, rótulo, código de pareamento, token, endereço ou nome do aparelho, carimbo `ts` da página nem contagem por tecla. `LogEventCatalogTests.sampleEvents` passa a incluir as seis fábricas, para o teste de chaves proibidas cobri-las.

## 4. Consumidores

`LogAnalysis` e `poc-tools` ignoram os eventos novos. A sonda P-05 mede a latência por um modo de depuração que grava `ts` e a chegada num arquivo à parte, apagado ao fim da sonda, sem passar pelo log. 🟡
