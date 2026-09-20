# Interface: log de diagnóstico

> Feature: `011-bateria-e-cursor-no-menu`
> Tipo: arquivo JSONL por sessão, em `~/Library/Logs/joystick-ai/`
> Base: `_reversa_sdd/data-dictionary.md#9. Log de diagnóstico (JSONL)`; deltas anteriores em `_reversa_forward/010-joystick-virtual-iphone/interfaces/diagnostic-log.md`
> Confidência: 🟢 salvo indicação

## 1. Esquema

`logSchema` continua 1. O catálogo de eventos permanece fechado, e nenhum evento desta feature carrega conteúdo: não há coordenada, deslocamento, nome de tecla, rótulo nem texto. A porcentagem de carga é grandeza física do acessório, não identifica pessoa e não revela o que o usuário digitou ou apontou.

## 2. Evento alterado

### `controller.connected`

| Campo | Tipo | Origem |
|-------|------|--------|
| `id` | texto (UUID) | Feature 001 |
| `name` | texto | Feature 001 |
| `connection` | texto (`usb`, `bluetooth`, `unknown`) | Feature 001 |
| `atStartup` | booleano | Feature 001 |
| `model` | texto (`dualSense`, `ipega`) | Feature 007 |
| `t_arrival` | inteiro sem sinal (ns) | Feature 001 |
| `charge` | inteiro de 0 a 100 | **Novo.** Porcentagem de carga no instante da conexão |
| `chargeState` | texto (`unknown`, `discharging`, `charging`, `full`) | **Novo.** Estado reportado no instante da conexão |

Os dois campos novos são **omitidos** quando a carga é indisponível, e não gravados como zero ou como texto vazio. Essa escolha é deliberada: gravar zero tornaria indistinguíveis o controle descarregado e o controle que não conta, exatamente a confusão que D-02 existe para evitar na tela, e que seria igualmente nociva na análise posterior. 🟢

Nível `info`, como o evento já era.

## 3. Eventos novos

### `controller.charge`

| Campo | Tipo | Valores |
|-------|------|---------|
| `id` | texto (UUID) | Identificador da conexão do controle, o mesmo de `controller.connected` |
| `charge` | inteiro | 0 a 100 |
| `state` | texto | `unknown`, `discharging`, `charging`, `full` |

**Quando é emitido:** apenas quando a faixa de dez em dez muda, ou seja, quando o número das dezenas da porcentagem difere do último registrado para aquela conexão; e também quando o estado muda entre descarregando e carregando. Nunca a cada leitura. 🟢

**Por que assim:** o log não tem rotação nem limpeza (TD-07), e a consulta ocorre a cada 60 s enquanto uma interface estiver aberta. Registrar toda leitura acrescentaria uma linha por minuto de editor aberto, sem ganho: a curva de descarga de um controle não precisa de resolução de um minuto para ser útil no diagnóstico.

**Cardinalidade esperada:** no máximo dez registros por conexão numa descarga completa, mais as trocas de estado.

Nível `info`.

### `menu.cycle`

> **Reescrito pela emenda E-01.** A forma original, com `released`, `resynced` e `timerRestarted`, supunha estado
> retido no fim do ciclo. As sondas P-01, P-04 e P-05 falsificaram a hipótese: não há estado retido; o sistema toma
> os analógicos enquanto o menu rastreia e deixa os botões passarem. O evento passou a registrar o que interessa
> depois da correção, que é se o controle conseguiu navegar o menu.

| Campo | Tipo | Valores |
|-------|------|---------|
| `keys` | inteiro | Quantas teclas de navegação foram enviadas ao menu no ciclo, traduzidas de direcional, ✕, ○ e PS |
| `durationMs` | inteiro | Quanto tempo o menu ficou aberto, em milissegundos |

**Quando é emitido:** uma vez por fechamento do menu do ícone da barra. Não há evento correspondente de abertura:
a abertura não produz decisão, e registrá-la dobraria o volume sem informação nova. 🟢

**Como se lê:** `keys` em zero com `durationMs` alto significa que o menu ficou aberto sem o controle navegá-lo,
seja porque o usuário usou o trackpad, seja porque a tradução de E-03 parou de funcionar. `keys` acompanhando os
apertos significa que a navegação por botão está de pé. Os três ciclos medidos na sonda P-06 registraram `keys=14`,
`keys=6` e `keys=0`, este último o ciclo fechado pelo trackpad.

Nível `info`. Em sessões sem uso do menu, o evento simplesmente não aparece.

## 4. Compatibilidade

Ferramentas de análise existentes (`poc-tools`) ignoram eventos e campos desconhecidos por desenho, portanto logs antigos continuam legíveis e logs novos não quebram a análise de latência, de ciclos nem de rodadas de alvos. Nenhuma das três fábricas novas ou alteradas aceita parâmetro que possa carregar conteúdo do usuário, o que mantém válida a suíte que verifica a ausência de chaves proibidas no catálogo. 🟢
