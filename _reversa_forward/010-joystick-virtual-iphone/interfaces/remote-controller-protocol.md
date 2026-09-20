# Interface: mensagens do controle virtual

> Feature: `010-joystick-virtual-iphone`
> Tipo: WebSocket sobre TLS, porta 47811, caminho `/ws`
> Base: `_reversa_forward/008-iphone-teclado-remoto/interfaces/remote-keyboard-protocol.md`, que continua valendo na íntegra
> Origem: `requirements.md` RN-01 a RN-10, RF-01 a RF-11; `roadmap.md` D-01, D-05 a D-08, D-15
> Confidência: 🟢 salvo indicação

## 1. O que não muda

Portas, política de origem local, identidade, pareamento por código, token de sessão, recusa de segundo aparelho, vigia de um segundo, fechamento por dez segundos de silêncio, limite de 1 KiB por quadro e encerramento após cinco mensagens inválidas seguidas continuam exatamente como a feature 008 os definiu. As mensagens de teclado (`down`, `up`, `prefs`, `pick`, `ping`, `release`, `bye`) e as de servidor (`welcome`, `reject`, `layout`, `modifiers`, `status`, `caps`, `suggest`) seguem sem alteração. 🟢

## 2. Mensagens novas do cliente

Todas em texto JSON, um objeto por quadro, com o campo `t`, e só aceitas depois de `hello` aceito.

| `t` | Campos | Quando | Efeito no Mac |
|-----|--------|--------|---------------|
| `btn` | `b`: nome do botão; `d`: `1` ao pressionar, `0` ao soltar | `touchstart` e `touchend` num botão do controle | Entrada de botão equivalente à do controle físico, entregue ao roteador na fila `input` |
| `stick` | `s`: `l` ou `r`; `x` e `y`: números de −1,0 a 1,0, com Y positivo para cima | A cada quadro em que a posição do dedo no analógico mudou, no máximo sessenta vezes por segundo, e uma vez ao voltar ao repouso | Amostra de analógico, com zona morta e curva aplicadas no Mac |
| `pad` | `f`: dedo, de 0 a 3; `p`: `b`, `m` ou `e`; `x` e `y`: normalizados de −1,0 a 1,0 | Toque na área de apontamento, do pousar ao levantar | Deslocamento relativo do cursor, pelo mesmo caminho do touchpad do controle |
| `mode` | `m`: `pointer`, `compact` ou `full` | Troca do estado do bloco central, e uma vez logo após `welcome` | Solta o que o estado anterior mantinha e confirma com `mode` |

Nomes aceitos em `b`: `cross`, `circle`, `square`, `triangle`, `dpadUp`, `dpadDown`, `dpadLeft`, `dpadRight`, `l1`, `r1`, `l2`, `r2`, `l3`, `r3`, `options`, `create`, `ps`, `touchpadClick`. Qualquer outro nome é mensagem inválida. 🟢

## 3. Mensagem nova do servidor

| `t` | Campos | Quando |
|-----|--------|--------|
| `mode` | `m`: `pointer`, `compact` ou `full` | Após aplicar a troca pedida pelo cliente, já com o estado anterior solto |

## 4. Validação

| Situação | Tratamento |
|----------|------------|
| `b` fora da lista, `s` diferente de `l` e `r`, `p` fora de `b`, `m`, `e`, `m` fora dos três estados | Mensagem inválida; conta para o limite de cinco seguidas |
| `d` diferente de 0 e 1, `f` fora de 0 a 3, `x` ou `y` ausentes ou não numéricos | Mensagem inválida |
| `x` ou `y` numéricos além de −1,0 a 1,0 | Limitados ao intervalo, sem contar como inválidos, pelo mesmo critério de `Normalization.touchPosition` |
| `btn` repetido para botão já pressionado, ou `d: 0` de botão solto | Ignorado, sem efeito e sem contar como inválido |
| `pad` com `p: m` ou `p: e` sem `b` anterior para o mesmo dedo | Ignorado |
| Mais de duzentas e quarenta mensagens de entrada por segundo | As excedentes são descartadas em silêncio, sem encerrar a sessão |
| `btn`, `stick` ou `pad` com o bloco central em estado que não os produz | Aceitos e aplicados: a página é a única fonte de verdade sobre o que está na tela, e recusar criaria estado preso 🟡 |

## 5. Soltura e fim de sessão

Todos os caminhos de soltura da feature 008 passam a cobrir também o controle virtual, sem exceção: `release` ao ocultar a página, `bye` ao sair, vigia de um segundo sem mensagem com algo mantido, fechamento por silêncio, substituição da conexão pelo token, desligamento do recurso no Mac e encerramento do aplicativo. Em qualquer deles, os botões do iPhone são soltos, os analógicos voltam ao repouso, os dedos da área de apontamento são descartados e o movimento para. 🟢

A troca de estado do bloco central é um caso à parte, mais estreito: solta o que o estado abandonado mantinha, e só isso. Sair do teclado solta teclas e modificadores; sair do apontamento solta botões e cliques. 🟢

## 6. Cadência e ordem

As mensagens chegam na ordem de envio, garantida pelo canal, e são aplicadas na fila `input`, o que preserva a ordem entre as duas origens de entrada (008 RN-14). O Mac não reordena por carimbo de tempo, e nenhuma mensagem de entrada carrega relógio da página, exceto o `ts` já existente das teclas. 🟢

## 7. Privacidade

Nome de botão, posição de analógico, coordenada de dedo e estado do bloco central não vão ao log, salvo as contagens e o estado descritos em `diagnostic-log.md`. A página não guarda nada além das preferências em `localStorage` descritas no `data-delta.md`. 🟢
