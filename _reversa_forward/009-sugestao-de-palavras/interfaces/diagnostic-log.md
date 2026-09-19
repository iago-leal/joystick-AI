# Interface: log de diagnóstico (delta das sugestões)

> Feature: `009-sugestao-de-palavras`
> Tipo: arquivo, escrita (JSON Lines)
> Contrato base: `_reversa_forward/008-iphone-teclado-remoto/interfaces/diagnostic-log.md`
> Origem: `requirements.md` RN-08, RF-09; `roadmap.md` D-13
> Confidência: 🟢

## 1. O que muda

Localização, formato, *flush*, ordem e tratamento de erros seguem o contrato base. `logSchema` continua `1`: entra só um campo aditivo.

## 2. Evento alterado

| Evento | Nível | Campos | Quando |
|--------|-------|--------|--------|
| `remote.disconnected` | info | `reason` e `keys`, como na 008; **`suggestions`**: sugestões aceitas na sessão | Fim da sessão |

## 3. Proibições

Nenhum evento leva palavra digitada, contexto recente, sugestão, sugestão escolhida, revisão, índice, idioma nem visibilidade da faixa. `LogEventCatalogTests.sampleEvents` passa a usar a fábrica com `suggestions`, e o teste de chaves proibidas continua cobrindo os eventos `remote.*`.

## 4. Consumidores

`LogAnalysis` e `poc-tools` ignoram o campo novo. As sondas P-01 e P-02 usam um modo de depuração que grava em arquivo à parte, apagado ao fim da sonda, sem passar pelo log.
