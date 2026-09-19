# Interface: canal do teclado remoto (delta das sugestões)

> Feature: `009-sugestao-de-palavras`
> Tipo: WebSocket sobre TLS (porta 47811), delta sobre `_reversa_forward/008-iphone-teclado-remoto/interfaces/remote-keyboard-protocol.md`
> Origem: `requirements.md` RN-01 a RN-14; `roadmap.md` D-05, D-08, D-10 a D-12
> Confidência: 🟢 salvo indicação

## 1. O que muda

A página HTTP (porta 47810), o aperto de mão, o pareamento, os tempos e as mensagens da 008 não mudam. A versão do `hello` segue `1`. Entram duas mensagens do cliente e uma do servidor. Uma página antiga, que nunca envia `prefs`, não recebe `suggest`.

## 2. Mensagens novas do cliente

| `t` | Campos | Quando | Efeito no Mac |
|-----|--------|--------|---------------|
| `prefs` | `lang`: `pt` ou `en`; `visible`: booleano | Logo após `welcome` e a cada troca do seletor ou do botão de ocultar | Guarda idioma e visibilidade na sessão; com `visible: false`, deixa de consultar o motor e envia `suggest` vazio; com `visible: true`, consulta de imediato |
| `pick` | `rev`: inteiro; `i`: 0, 1 ou 2 | Toque numa sugestão ativa | Se `rev` for a revisão atual, a injeção estiver ligada e nenhum modificador do iPhone estiver mantido ou preso, digita o sufixo da palavra `i` seguido de espaço (D-05); senão, ignora |

`prefs` com campo ausente ou de tipo errado e `pick` com `i` fora de 0 a 2 contam como mensagem inválida, pela regra de cinco seguidas da 008. `pick` com `rev` velha, com a injeção desligada ou com modificador ativo é ignorado sem contar como inválido, porque decorre de corrida normal entre toque e rede.

## 3. Mensagem nova do servidor

| `t` | Campos | Quando |
|-----|--------|--------|
| `suggest` | `rev`: inteiro; `mode`: `complete` ou `next`; `words`: até 3 textos | A cada resposta do motor ainda válida para a revisão atual, e com `words` vazio sempre que a faixa deve esvaziar: descarte (RN-03), entrada segura (RN-06), palavra com cara de código (RN-13), fronteira sem previsão (RN-12) ou faixa oculta |

Cada palavra tem de 1 a 48 caracteres, só letras, sem espaço final; o espaço é acrescentado pelo Mac ao aceitar. No modo `complete`, toda palavra começa exatamente pela palavra em composição (D-04).

## 4. Comportamento da página

- A faixa desenha as palavras por `textContent`, na ordem recebida.
- Ao enviar `down` de uma tecla que não seja modificador nem Caps Lock, a página esmaece a faixa e ignora toques nela até a próxima `suggest` (D-10).
- Com ⌘, ⇧, ⌥ ou ⌃ mantido ou preso (mensagem `modifiers`), a faixa fica inativa.
- Com estado diferente de "Conectado", o texto do estado ocupa o lugar das sugestões.
- O toque numa sugestão não envia `down` nem `up` e não conta como tecla da sessão.

## 5. Ordem e tempos

- A tecla é injetada antes de o contexto ser atualizado; a consulta ao motor nunca atrasa a tecla (RN-09).
- Há no máximo uma consulta em curso; chegando outra, a pendente é substituída pela mais nova.
- Meta: `suggest` na página em até 150 ms após o `down` que mudou o contexto, no percentil 95.

## 6. Privacidade

`words`, `rev` e o índice escolhido não vão ao log (RN-08). O contexto recente nunca sai do Mac: a página só recebe as palavras sugeridas.
