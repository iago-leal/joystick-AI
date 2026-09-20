# Delta de dados: controle virtual no iPhone

> Feature: `010-joystick-virtual-iphone`
> Base: `_reversa_sdd/data-dictionary.md`, `_reversa_sdd/architecture.md#5. Modelo de dados em arquivo`
> Confidência: 🟢 salvo indicação

## 1. Arquivo de configuração

`~/.config/joystick-ai/config.json` não muda: nenhuma chave nova, nenhuma removida, `version` continua 1 nas seções `shortcuts` e `palette`. 🟢

O efeito da feature sobre a configuração é de alcance, não de forma. A seção `pointer` passa a reger também o apontamento vindo do iPhone: `deadzone`, `stickMaxSpeed`, `stickExponent`, `precisionFactor`, `scrollSpeed`, `invertScrollY` e `touchpadSensitivity` valem para os analógicos e para a área de apontamento da página, pelos mesmos componentes que já os aplicam ao controle físico. Segue valendo a limitação conhecida de que `pointer` só é lido na abertura do aplicativo (003 RN-10, TD-08). 🟢

A seção `shortcuts` também não muda de forma, e seu conteúdo passa a ser exercido pelas duas origens: os mesmos gatilhos, modificadores e camadas respondem ao toque na página. 🟢

## 2. Tipos novos no núcleo

Todos em `Sources/JoystickCore/Remote/`, sem dependência além de `Foundation`.

| Tipo | Forma | Papel |
|------|-------|-------|
| `VirtualButton` | enumeração com correspondência para `ButtonID` | Conjunto dos botões que a página pode enviar: as quatro faces, as quatro direções do direcional, os quatro gatilhos, os dois cliques de analógico, Options, Create, PS e o clique do painel. `share` fica de fora, por ser do controle da feature 007 |
| `VirtualStick` | enumeração `left`, `right` | Qual analógico a amostra descreve |
| `StickSample` | `x`, `y` em −1,0 a 1,0, com Y positivo para cima | Posição bruta do analógico, antes da zona morta |
| `PadSample` | `finger`, `phase` (`began`, `moved`, `ended`), `x`, `y` normalizados | Dedo na área de apontamento, no mesmo formato que o touchpad do controle entrega |
| `VirtualControllerMachine` | estrutura com `pressed: Set<VirtualButton>`, `sticks`, `fingers`, `buttonCount`, `clickCount` | Converte mensagem em `InputEvent`, garante idempotência por botão, produz as solturas sintéticas e conta a sessão |

Nenhum desses tipos é persistido: vivem na sessão remota e morrem com ela. 🟢

## 3. Estado compartilhado do aplicativo

| Estrutura | Situação atual | Depois da feature |
|-----------|----------------|-------------------|
| `ActiveControllerRegistry.pressed` | Conjunto único, alimentado só pelo controle ativo | Inalterado em forma e em regra; continua descrevendo apenas o hardware |
| `InputContext` | Expõe `registry` | Expõe também o conjunto de botões do controle virtual e a união dos dois, que passa a ser o que `MotionLoop`, `ButtonActions` e `TargetSession` consultam |

A união é lida na fila `input`, como todo o resto do pipeline, e não introduz trava nem estado compartilhado entre filas. 🟢

## 4. Log de diagnóstico

`logSchema` continua 1. O catálogo permanece fechado e sem conteúdo (001 RN-12, 003 RN-14).

| Evento | Mudança | Campos |
|--------|---------|--------|
| `remote.disconnected` | Campos novos | Acrescenta `buttons`, número de botões do controle virtual pressionados na sessão, e `clicks`, número de cliques de mouse originados deles. Os campos existentes `reason`, `keys` e `suggestions` permanecem |
| `remote.mode` | Evento novo | `mode` com um de `pointer`, `compact` ou `full`, registrado a cada troca do bloco central. Sem coordenada, sem tecla, sem rótulo |

Movimento do cursor não gera evento novo: `pointer.posted` já registra o que interessa, com origem e sem coordenadas (`_reversa_sdd/code-analysis.md#4. `injection``). Detalhe campo a campo em `interfaces/diagnostic-log.md`. 🟢

## 5. Preferências guardadas no navegador do iPhone

A chave `remoteKeyboardPrefs` do `localStorage`, criada pela feature 009 com `lang` e `visible`, ganha dois campos:

| Campo | Valores | Padrão |
|-------|---------|--------|
| `center` | `pointer`, `compact`, `full` | `compact` |
| `sensitivity` | número de 0,5 a 2,0, multiplicador aplicado sobre os valores do Mac | 1,0 |

A leitura e a gravação seguem dentro de `try`, e uma chave ausente ou inválida volta ao padrão, como já ocorre com os campos da 009. Nada disso chega ao Mac por outro caminho que não as mensagens do canal. 🟢

## 6. Migração

Não há migração. Configuração e log seguem legíveis pelas versões anteriores, o campo novo do `localStorage` é opcional e uma página antiga, sem as mensagens do controle, continua funcionando como teclado. Um aplicativo novo com uma página velha em cache também funciona: sem `btn`, `stick` e `pad`, o controle virtual simplesmente não existe naquela sessão. 🟢
