# Interface: log de diagnóstico

> Feature: `010-joystick-virtual-iphone`
> Tipo: arquivo JSONL por sessão, em `~/Library/Logs/joystick-ai/`
> Base: `_reversa_sdd/data-dictionary.md#9. Log de diagnóstico (JSONL)`; deltas anteriores em `_reversa_forward/009-sugestao-de-palavras/interfaces/diagnostic-log.md`
> Confidência: 🟢

## 1. Esquema

`logSchema` continua 1. O catálogo de eventos permanece fechado, e nenhum evento novo carrega conteúdo: não há coordenada, deslocamento, nome de tecla, rótulo, texto, código de pareamento nem endereço do aparelho.

## 2. Evento alterado

### `remote.disconnected`

| Campo | Tipo | Origem |
|-------|------|--------|
| `reason` | texto | Feature 008 |
| `keys` | inteiro | Teclas pressionadas na sessão, feature 008 |
| `suggestions` | inteiro | Sugestões aceitas na sessão, feature 009 |
| `buttons` | inteiro | **Novo.** Botões do controle virtual pressionados na sessão |
| `clicks` | inteiro | **Novo.** Cliques de mouse originados do controle virtual na sessão |

Os dois campos novos são contagens acumuladas pela máquina do controle virtual e zeradas a cada sessão. Sessões sem uso do controle registram zero, e não a ausência do campo.

## 3. Evento novo

### `remote.mode`

| Campo | Tipo | Valores |
|-------|------|---------|
| `mode` | texto | `pointer`, `compact`, `full` |

Registrado no nível `info`, a cada troca confirmada do bloco central, inclusive a primeira, logo após o início da sessão. Serve para responder, ao ler um log de campo, em que estado o usuário passou a sessão, sem revelar o que ele fez em cada estado.

## 4. O que continua fora do log

- Nome do botão tocado, posição dos analógicos e coordenadas do dedo na área de apontamento.
- Qualquer texto transcrito pelo ditado, que sequer passa pelo aplicativo.
- Toda a matéria já proibida pelas features anteriores: teclas, rótulos, código de pareamento e endereço do aparelho.

## 5. Verificação

A suíte `LogEventCatalogTests` continua conferindo que nenhuma fábrica de evento aceita chave proibida; as fábricas alteradas e a nova entram nessa conferência, como ocorreu com `suggestions` na feature 009.
