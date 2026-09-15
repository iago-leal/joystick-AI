# Interface: log de diagnóstico (delta da paleta)

> Feature: `002-paleta-comandos`
> Tipo: arquivo, escrita (JSON Lines)
> Contrato base: `_reversa_forward/001-poc-entrada-ponteiro/interfaces/diagnostic-log.md`
> Origem: `requirements.md` RN-07, RF-09, RNF de observabilidade e de privacidade; `roadmap.md` D-13, D-14
> Confidência: 🟢

## 1. O que muda

Localização, formato do registro, *flush*, ordem e tratamento de erros seguem o contrato base sem alteração. `logSchema` continua `1`, porque só entram eventos novos e nenhum campo existente muda. Os consumidores do `poc-tools` ignoram eventos desconhecidos.

## 2. Eventos novos

Todos em nível `info`, emitidos na fila `input`. Índices contam a partir de 1, na ordem da lista fixa (`requirements.md` §4).

| Evento | Campos | Quando | Requisito |
|--------|--------|--------|-----------|
| `palette.opened` | `selection: int` | A paleta passou de fechada a aberta. | RF-01, RF-08 |
| `palette.confirmed` | `index: int`, `enter: bool` | ✕ confirmou um item; emitido antes da digitação. | RF-04 |
| `palette.closed` | `reason: circle \| ps \| disconnected \| injection_suspended \| idle` | A paleta fechou sem confirmação. | RF-03, RF-09 |
| `palette.blocked` | `reason: targets` | PS foi pressionado com a tela de alvos aberta e a paleta não abriu. | D-13 |

## 3. Privacidade

- Nenhum evento contém o texto, o rótulo nem o comprimento do item, nem as teclas injetadas na digitação (RN-07).
- `enter` só indica se houve Enter ao final; combinado com `index`, identifica o item da lista fixa, o que é aceito, pois a lista é pública no código e não contém texto do usuário.
- A digitação continua sem gerar `input.button` nem `pointer.posted`, como no protótipo.

## 4. Latência derivável

Com `--debug`, a abertura pode ser medida por `palette.opened.ts_ns − input.button(ps, down).ts_ns`. O valor inclui o envio à fila `log`, mas não o desenho na tela, e serve só como indicador; a verificação do limite de 150 ms é visual no PM-1.

## 5. Exemplo

```json
{"ts_ns":912345678901,"wall":"2026-09-15T21:04:10.112-03:00","level":"info","event":"palette.opened","selection":1}
{"ts_ns":913901234567,"wall":"2026-09-15T21:04:11.668-03:00","level":"info","event":"palette.confirmed","enter":true,"index":2}
{"ts_ns":990001234567,"wall":"2026-09-15T21:05:27.768-03:00","level":"info","event":"palette.closed","reason":"circle"}
```
