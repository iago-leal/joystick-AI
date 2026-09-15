# Interface: argumentos de abertura (delta da paleta)

> Feature: `002-paleta-comandos`
> Tipo: linha de comando (`open ~/Applications/JoystickAIPoC.app --args ...`)
> Contrato base: argumentos de `LaunchArguments` definidos na feature 001 (`--targets`, `--env`, `--screen`, `--seed`, `--debug`, `--scroll-unit`)
> Origem: `roadmap.md` D-06, sonda P-01
> Confidência: 🟡

## 1. Argumento novo

| Argumento | Valor | Padrão | Efeito |
|-----------|-------|--------|--------|
| `--palette-enter-delay-ms` | inteiro de 0 a 500 | definido pela sonda P-01 e registrado em `actions.md` | Intervalo entre o último caractere digitado por um item da paleta e o Enter, para itens com Enter ao final. |

Só afeta a paleta. A ação de texto de L1+✕ (`CONTINUAR`) mantém o Enter imediato do protótipo (RF-07).

## 2. Erros

| Entrada | Tratamento |
|---------|------------|
| Sem valor (`--palette-enter-delay-ms` no fim) | `LaunchArgumentError.missingValue`; vale o padrão. |
| Não inteiro, negativo ou acima de 500 | Novo `LaunchArgumentError.invalidPaletteEnterDelay(String)`, com a mensagem `--palette-enter-delay-ms inválido: "<valor>"; use um inteiro de 0 a 500`; vale o padrão. |

Os erros vão ao log como `palette.invalid_args { message }`, nível `warn`, emitido uma vez ao iniciar. O app segue normalmente.

## 3. Exemplo

```sh
open ~/Applications/JoystickAIPoC.app --args --debug --palette-enter-delay-ms 120
```
