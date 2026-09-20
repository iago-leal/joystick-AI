# Delta de dados: carga do controle e ciclo do menu

> Feature: `011-bateria-e-cursor-no-menu`
> Base: `_reversa_sdd/data-dictionary.md`, `_reversa_sdd/architecture.md#5. Modelo de dados em arquivo`
> Confidência: 🟢 salvo indicação

## 1. Arquivo de configuração

`~/.config/joystick-ai/config.json` não muda: nenhuma chave nova, nenhuma removida, `version` continua 1 nas seções `shortcuts` e `palette`, e a seção `pointer` fica intacta. 🟢

A feature não introduz nada configurável pelo usuário. O limite de carga baixa é constante do código, fixada em 15% por decisão da clarificação de 2026-09-20 (RN-07), e o período de consulta é constante de 60 s (RN-10). Nenhum dos dois entra no arquivo, porque valores configuráveis exigiriam validação conjunta, gravação por fusão e faixa de valores aceitos, custo desproporcional para dois números que o usuário não pediu para ajustar. 🟢

## 2. Tipos novos no núcleo

Em `Sources/JoystickCore/`, sem dependência além de `Foundation`, conforme D-03.

| Tipo | Forma | Papel |
|------|-------|-------|
| `ControllerChargeState` | enumeração `unknown`, `discharging`, `charging`, `full` | Espelho puro dos quatro estados que a interface de controles do sistema reporta, sem importar o framework |
| `ControllerCharge` | estrutura com `level: Double` de 0,0 a 1,0 e `state: ControllerChargeState` | Leitura crua de um controle, antes de qualquer decisão de exibição |
| `ChargeDisplay` | enumeração com os casos `noController`, `unavailable` e `known(percent: Int, charging: Bool, low: Bool)` | Resultado da decisão de exibição; é o que editor e paleta consomem, e nenhum dos dois volta a raciocinar sobre nível ou estado |

A função que produz `ChargeDisplay` recebe `ControllerCharge?` e devolve, nesta ordem de precedência:

1. `noController` quando não há controle ativo, ou seja, quando a leitura é ausente por falta de controle;
2. `unavailable` quando há controle ativo mas a carga não existe, **ou** quando o estado é `unknown`, nunca por causa do valor do nível (D-02);
3. `known`, com `percent` sendo o nível multiplicado por 100 e arredondado para inteiro, limitado à faixa de 0 a 100; `charging` verdadeiro nos estados `charging` e `full`; `low` verdadeiro quando `percent` for igual ou inferior a 15.

Nenhum desses tipos é persistido: vivem na sessão e morrem com ela. 🟢

### Tabela de verdade da decisão

| Entrada | `percent` | `charging` | `low` | Caso |
|---------|-----------|------------|-------|------|
| sem controle ativo | — | — | — | `noController` |
| controle sem propriedade de carga | — | — | — | `unavailable` |
| nível 0,0, estado `unknown` | — | — | — | `unavailable` (o caso que D-02 existe para impedir) |
| nível 0,0, estado `discharging` | 0 | não | sim | `known` |
| nível 0,15, estado `discharging` | 15 | não | sim | `known` |
| nível 0,151, estado `discharging` | 15 | não | sim | `known` (arredondamento antes da comparação) |
| nível 0,16, estado `discharging` | 16 | não | não | `known` |
| nível 0,38, estado `charging` | 38 | sim | não | `known` |
| nível 1,0, estado `full` | 100 | sim | não | `known` |

O arredondamento acontece **antes** da comparação com o limite, de modo que a faixa baixa é definida sobre o número que o usuário lê, e não sobre a fração interna. Sem essa ordem, 0,154 apareceria como 15% sem destaque, e o usuário veria dois controles no mesmo número com marcações diferentes. 🟢

## 3. Estado compartilhado do aplicativo

| Estrutura | Situação atual | Depois da feature |
|-----------|----------------|-------------------|
| Canal de publicação do controle ativo | Leva apenas o modelo do controle ativo, ou ausência, à main thread, desde a `007-controle-ipega` | Leva modelo e `ControllerCharge?` juntos, num único envio por mudança (D-05) |
| Modelo do editor | Guarda o modelo do controle ativo | Guarda também o último `ChargeDisplay` publicado |
| Painel da paleta | Guarda itens e seleção | Guarda também o último `ChargeDisplay`, usado só no desenho do rodapé |
| Consultor periódico | Não existe | Novo, na main thread; guarda apenas o instante da última leitura e se há interface aberta |

Nada disso atravessa filas: a carga nasce na main thread, é decidida por função pura e é desenhada na main thread. A fila de entrada não a vê em ponto algum, o que é o conteúdo de RN-11. 🟢

## 4. Log de diagnóstico

`logSchema` continua 1. O catálogo permanece fechado e sem conteúdo sensível (001 RN-12, 003 RN-14). O detalhe campo a campo está em `interfaces/diagnostic-log.md`.

| Evento | Mudança | Campos |
|--------|---------|--------|
| `controller.connected` | Campo novo | Acrescenta `charge`, a porcentagem inteira de 0 a 100, ou a ausência do campo quando a carga for indisponível. Os campos existentes `id`, `name`, `connection`, `atStartup`, `model` e `t_arrival` permanecem |
| `controller.charge` | Evento novo | `id` do controle, `charge` com a porcentagem inteira e `state` com um de `unknown`, `discharging`, `charging`, `full`. Emitido apenas quando a faixa de dez em dez muda, nunca a cada leitura (D-09) |
| `menu.cycle` | Evento novo | `released`, número de botões de mouse soltos pela reconciliação, `resynced`, booleano indicando se a posição acompanhada foi ressincronizada, e `timerRestarted`, booleano. Registrado uma vez por fechamento do menu |

O evento `menu.cycle` é o que dá substância ao RF-13: ele permite dizer, lendo o log de uma sessão com o defeito reproduzido, se a reconciliação teve o que reconciliar. Com os três campos em zero e falso, a reconciliação não encontrou estado retido, e a causa do defeito é outra. 🟡

Nenhum dos três eventos carrega coordenada, texto, rótulo ou acorde. A porcentagem de carga não identifica pessoa nem revela conteúdo, e por isso não fere o catálogo fechado. 🟢

## 5. Migração

Não há. Nenhum arquivo persistido muda de forma, nenhuma versão de esquema sobe e nenhum dado antigo precisa ser reescrito. Um log de sessão anterior continua legível pelas ferramentas de análise, que ignoram campos e eventos desconhecidos por desenho. 🟢
