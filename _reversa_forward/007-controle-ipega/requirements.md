# Requirements: Controle Ipega ao lado do DualSense

> Identificador: `007-controle-ipega`
> Data: `2026-09-19`
> Pasta da extração reversa: `_reversa_sdd/`
> Confidência: 🟢 CONFIRMADO, 🟡 INFERIDO, 🔴 LACUNA / DÚVIDA

## 1. Resumo executivo

A feature permite que o programador de sofá use o controle Ipega do mesmo modo que usa o DualSense: mover o ponteiro, clicar, rolar e disparar atalhos e a paleta. Hoje o app aceita apenas o DualSense e ignora qualquer outro modelo, de modo que o Ipega, embora reconhecido pelo sistema operacional, não produz efeito algum. Os botões do Ipega correspondem aos do DualSense pela posição física. O botão de captura, que o DualSense não tem, torna-se um botão de atalho livre. Sem touchpad, o Ipega move o ponteiro apenas pelo analógico.

## 2. Contexto a partir do legado

| Fonte | Trecho relevante | Confidência |
|-------|------------------|-------------|
| Pedido do usuário, 2026-09-19 | "Estou com outro joystick conectado ao macOS. Chama-se Ipega e ele tem controles similares ao do PlayStation 5, mas possui alguns botões a mais. Gostaria de configurá-lo também." | 🟢 |
| `_reversa_sdd/domain.md#3.1 Controle e entrada (001)` | 001 RN-01: no máximo um controle ativo, o primeiro DualSense conectado; outros modelos são ignorados | 🟢 |
| `_reversa_sdd/entrada-do-controle/requirements.md#Regras de Negócio` | RN-EC-01 e RN-EC-02: o primeiro controle é o ativo, e os demais aguardam em fila sem produzir eventos; RN-EC-03: controle que não é DualSense é ignorado e registrado uma vez com o motivo `not_dualsense` | 🟢 |
| `_reversa_sdd/entrada-do-controle/requirements.md#Regras de Negócio` | RN-EC-16: mapeamento físico dos 18 botões do DualSense, inclusive Options e Create; RN-EC-12 e RN-EC-17: o PS é lido no relatório bruto do dispositivo e atribuído ao controle ativo | 🟢 |
| `_reversa_sdd/entrada-do-controle/requirements.md#Regras de Negócio` | RN-EC-07: na desconexão do ativo, cada botão pressionado recebe soltura sintética, e o próximo da fila assume; RN-EC-14: tipo de conexão resolvido só para o DualSense | 🟢 |
| `_reversa_sdd/atalhos/requirements.md#Regras de Negócio` | RN-AT-01: R1, R2 e clique do touchpad são cliques fixos, nunca atalho nem modificador; RN-AT-19: mapeamento padrão sem arquivo de configuração | 🟢 |
| `_reversa_sdd/editor/requirements.md#Regras de Negócio` | RN-ED-06: o editor recusa ação em R1, R2 e no clique do touchpad; RN-ED-14: a figura mostra os 18 botões nas posições físicas | 🟢 |
| `_reversa_sdd/addenda/004-figura-controle-web.md#Resumo da entrega` | A figura do editor é uma representação plana do DualSense, desenhada numa página web local embutida na aba Atalhos | 🟢 |
| `_reversa_sdd/domain.md#3.1 Controle e entrada (001)` | 001 RN-04: nenhuma desconexão deixa entrada presa; 001 RN-05 e RN-06: o touchpad move o ponteiro somado ao analógico esquerdo | 🟢 |
| Sondas no hardware, 2026-09-19 | O Ipega se apresenta como clone de Switch Pro Controller (USB, fabricante 0x057E, produto 0x2009), sem touchpad. Dezessete botões chegam pela interface de controles do sistema, e o Home só pelo relatório bruto do dispositivo (byte 4, bit 0x10). Os botões frontais baixo, direita, esquerda e cima chegam como A, B, X e Y, os mesmos nomes do DualSense. ZL e ZR são digitais. Os botões Android, iOS, Turbo e Clear não chegam ao Mac | 🟢 |

**Constatação.** O Ipega entrega 18 entradas, o mesmo número do DualSense, e 17 delas têm equivalente direto por posição. A diferença está em um único par: o Ipega tem o botão de captura (Share) e não tem o touchpad nem o clique dele. Por decisão do usuário, o Share não herda o papel de clique do touchpad. Os quatro botões que o usuário considera extras (Android, iOS, Turbo, Clear) são de firmware: trocam o modo do controle ou configuram o disparo repetido, e o app não os enxerga. 🟢

## 3. Personas e cenários de uso

| Persona | Objetivo | Cenário-chave |
|---------|----------|---------------|
| Programador de sofá (`_reversa_sdd/personas.md#Persona 1: Programador de sofá`) | Usar o Ipega quando o DualSense estiver descarregado ou em outro cômodo | Conecta o Ipega por cabo, move o ponteiro pelo analógico, confirma um menu com R1 e envia "CONTINUAR" com o mesmo atalho que usaria no DualSense |
| Programador de sofá | Ganhar um botão de atalho a mais | Atribui ao Share, pelo editor, um atalho que no DualSense exigiria uma camada de modificador |

O uso é alternado: um controle de cada vez na mão, com o outro eventualmente conectado. 🟡

## 4. Regras de negócio novas ou alteradas

1. **RN-01:** O app aceita dois modelos de controle: o DualSense e o Ipega no modo em que se apresenta como Switch Pro Controller, identificado pelo fabricante 0x057E e pelo produto 0x2009 com que se apresenta. Controles de outros modelos, inclusive outros controles do tipo Switch Pro com identificação diferente, e o Ipega em outro modo continuam ignorados e registrados uma vez no log. 🟢
   - Origem no legado: `_reversa_sdd/domain.md#3.1 Controle e entrada (001)` (001 RN-01); `_reversa_sdd/entrada-do-controle/requirements.md#Regras de Negócio` (RN-EC-03)
   - Tipo: alterada
2. **RN-02:** A regra do controle ativo vale para os dois modelos sem distinção: o primeiro controle aceito a se conectar é o ativo, e os demais aguardam em fila, na ordem de chegada, sem produzir eventos. 🟢
   - Origem no legado: `_reversa_sdd/entrada-do-controle/requirements.md#Regras de Negócio` (RN-EC-01, RN-EC-02, RN-EC-07)
   - Tipo: alterada (a fila passa a misturar modelos)
3. **RN-03:** Os botões do Ipega correspondem aos do DualSense pela posição física: baixo (A) age como ✕, direita (B) como ○, esquerda (X) como □, cima (Y) como △; L e R como L1 e R1; ZL e ZR como L2 e R2; os cliques dos analógicos como L3 e R3; o direcional como o direcional; Select (−) como Create; Start (+) como Options; Home como PS. 🟢
   - Origem no legado: `_reversa_sdd/entrada-do-controle/requirements.md#Regras de Negócio` (RN-EC-16)
   - Tipo: alterada (o mapeamento passa a cobrir o Ipega)
4. **RN-04:** O Home do Ipega obedece às mesmas regras do PS: só mudanças de estado são entregues, sem repetição quando chegar por mais de uma via, e sempre ao controle ativo. 🟢
   - Origem no legado: `_reversa_sdd/entrada-do-controle/requirements.md#Regras de Negócio` (RN-EC-06, RN-EC-12, RN-EC-17)
   - Tipo: alterada
5. **RN-05:** O Share do Ipega é um botão de atalho livre, identificado como botão próprio, e não como o clique do touchpad. Pode receber qualquer ação e ser modificador, como os demais botões livres; nunca produz clique. 🟢
   - Origem no legado: `_reversa_sdd/atalhos/requirements.md#Regras de Negócio` (RN-AT-01)
   - Tipo: nova
6. **RN-06:** Com o Ipega ativo, o ponteiro move-se apenas pelo analógico esquerdo, com a mesma velocidade, zona morta e precisão por L1 do DualSense; o clique esquerdo sai só do R1 e o direito do R2; a rolagem segue pelo analógico direito. 🟢
   - Origem no legado: `_reversa_sdd/domain.md#3.1 Controle e entrada (001)` (001 RN-02, RN-06, RN-08, RN-11)
   - Tipo: alterada (sem touchpad, a soma de deslocamentos se reduz ao analógico)
7. **RN-07:** O Ipega usa a mesma configuração de atalhos do DualSense, aplicada pela correspondência de RN-03: um atalho em L1 + ✕ vale também para L + A, e uma edição feita com qualquer dos dois controles ativo vale para ambos. O Share entra nessa configuração como botão a mais, que o DualSense nunca aciona. Não há configuração própria do Ipega nem sobreposição por modelo. 🟢
   - Origem no legado: `_reversa_sdd/architecture.md#5. Modelo de dados em arquivo`
   - Tipo: alterada (a configuração passa a conhecer o Share)
8. **RN-08:** O mapeamento padrão do DualSense não muda. No Ipega, o padrão é o do DualSense pela correspondência de RN-03, e o Share não tem ação até o usuário atribuí-la. 🟡
   - Origem no legado: `_reversa_sdd/atalhos/requirements.md#Regras de Negócio` (RN-AT-19)
   - Tipo: nova (preserva a regra do legado)
9. **RN-09:** Nenhuma desconexão do Ipega deixa entrada presa: botões pressionados, inclusive Share e Home, recebem soltura sintética, e o próximo controle da fila assume. 🟢
   - Origem no legado: `_reversa_sdd/domain.md#3.1 Controle e entrada (001)` (001 RN-04); `_reversa_sdd/entrada-do-controle/requirements.md#Regras de Negócio` (RN-EC-07)
   - Tipo: alterada (a regra passa a cobrir o Ipega)
10. **RN-10:** Os botões de firmware do Ipega (Android, iOS, Turbo e Clear) ficam fora do app: não aparecem no editor nem na figura, e o app não tenta detectá-los. 🟢
    - Origem no legado: nenhuma (sonda no hardware de 2026-09-19)
    - Tipo: nova
11. **RN-11:** O log identifica o modelo do controle ao registrar conexão, desconexão e controles ignorados, e resolve o tipo de conexão (cabo ou sem fio) também para o Ipega. Valores de eixo continuam fora do log. 🟡
    - Origem no legado: `_reversa_sdd/entrada-do-controle/requirements.md#Regras de Negócio` (RN-EC-03, RN-EC-14, RN-EC-15)
    - Tipo: alterada
12. **RN-12:** Com o Ipega ativo, a aba Atalhos mostra a figura do DualSense com um botão Share acrescentado e o touchpad marcado como ausente. O Share tem os mesmos estados visuais e o mesmo resumo de ação dos demais botões livres. O modo de identificação seleciona na figura o botão correspondente ao pressionado no Ipega, inclusive o Share. Com o DualSense ativo, a figura continua como antes da feature, e a ação atribuída ao Share continua gravada. 🟡
    - Origem no legado: `_reversa_sdd/editor/requirements.md#Regras de Negócio` (RN-ED-14); `_reversa_sdd/addenda/004-figura-controle-web.md#Resumo da entrega`
    - Tipo: alterada
13. **RN-13:** O editor, a figura e os resumos de ação usam os nomes dos botões do DualSense (✕, ○, □, △, L1, Options, PS e os demais), qualquer que seja o controle ativo. O Share, sem equivalente no DualSense, tem nome próprio. 🟢
    - Origem no legado: `_reversa_sdd/editor/requirements.md#Regras de Negócio` (RN-ED-14)
    - Tipo: nova

## 5. Requisitos Funcionais

| ID | Requisito | Prioridade | Critério de aceite | Confidência |
|----|-----------|------------|--------------------|-------------|
| RF-01 | Aceitar o Ipega como controle ativo (RN-01, RN-02) | Must | Com só o Ipega conectado, o analógico esquerdo move o cursor e R1 clica | 🟢 |
| RF-02 | Entregar as 18 entradas do Ipega pela correspondência de posição (RN-03) | Must | A ferramenta de conferência de botões registra 18 de 18 entradas do Ipega, cada uma com o nome esperado por RN-03 e o Share com identidade própria | 🟢 |
| RF-03 | Tratar o Home do Ipega como o PS (RN-04) | Must | Sem arquivo de configuração, o Home abre a paleta, e um único toque produz uma única abertura | 🟢 |
| RF-04 | Oferecer o Share como botão de atalho livre (RN-05) | Must | Atribuir ao Share, pelo editor, o envio de "CONTINUAR" faz o Share digitá-lo; marcar o Share como modificador cria a camada dele; em nenhum caso o Share clica | 🟢 |
| RF-05 | Mover, clicar e rolar com o Ipega sem touchpad (RN-06) | Must | O analógico esquerdo move o cursor, L1 reduz a velocidade, R1 e R2 fazem os cliques esquerdo e direito, e o analógico direito rola | 🟢 |
| RF-06 | Alternar entre os dois controles conectados (RN-02) | Must | Com o DualSense conectado primeiro e o Ipega depois, só o DualSense age; desligado o DualSense, o Ipega assume sem reiniciar o app | 🟢 |
| RF-07 | Não deixar entrada presa ao desconectar o Ipega (RN-09) | Must | Desconectar o Ipega com Share, Home ou R1 pressionado não deixa tecla, modificador nem botão do mouse pressionado | 🟢 |
| RF-08 | Aplicar ao Ipega a configuração de atalhos do DualSense (RN-07, RN-08) | Must | L1 + ✕ no DualSense e L + A no Ipega produzem a mesma ação; uma ação atribuída com o Ipega ativo vale também no DualSense | 🟢 |
| RF-09 | Manter inalterados o comportamento e a configuração do DualSense (RN-08) | Must | Um arquivo de configuração anterior à feature continua válido sem migração, e o DualSense produz as mesmas ações de antes | 🟢 |
| RF-10 | Identificar no editor os botões pressionados no Ipega (RN-12) | Must | No modo de identificação, pressionar cada um dos 18 botões do Ipega seleciona na figura o botão correspondente | 🟡 |
| RF-11 | Exibir o Share na figura e o touchpad como ausente com o Ipega ativo (RN-12, RN-13) | Should | Com o Ipega ativo, a figura do DualSense mostra o Share selecionável e o touchpad marcado como ausente, e todos os botões aparecem com os nomes do DualSense; com o DualSense ativo, a figura é a de antes da feature | 🟡 |
| RF-12 | Registrar no log o modelo e o tipo de conexão do Ipega (RN-11) | Should | O evento de conexão do Ipega traz o modelo e o tipo de conexão; um controle de outro modelo aparece como ignorado, uma única vez | 🟡 |

## 6. Requisitos Não Funcionais

| Tipo | Requisito | Evidência ou justificativa | Confidência |
|------|-----------|----------------------------|-------------|
| Desempenho | A latência entre pressionar um botão do Ipega e o efeito no sistema não excede a medida para o DualSense na feature 001 | `_reversa_sdd/entrada-do-controle/requirements.md#Requisitos Não Funcionais` | 🟡 |
| Compatibilidade | Configurações existentes continuam válidas sem migração, e o mapeamento padrão do DualSense não muda | `_reversa_sdd/architecture.md#5. Modelo de dados em arquivo`; RN-08 | 🟢 |
| Compatibilidade | Funcionar no macOS em uso pelo usuário (26) sem quebrar o mínimo declarado do app (13) | `_reversa_sdd/inventory.md#1. Visão geral` | 🟡 |
| Segurança | Nenhuma permissão nova além das já exigidas pela leitura do PS no relatório bruto do dispositivo; nenhuma rede | `_reversa_sdd/permissions.md#2. Matriz de permissões do sistema operacional` | 🟡 |
| Privacidade | Valores de eixo e textos de atalho continuam fora do log | `_reversa_sdd/domain.md#3.1 Controle e entrada (001)` (001 RN-12) | 🟢 |
| Testabilidade | Correspondência de botões, regras de configuração e fila de controles verificáveis por testes automatizados; leitura do Home, figura e alternância entre controles verificadas por portão manual no hardware | `_reversa_sdd/architecture.md#6. Qualidade e verificação` | 🟢 |
| Observabilidade | O log distingue os eventos do DualSense e do Ipega pelo modelo registrado na conexão | RN-11 | 🟡 |

## 7. Critérios de Aceitação

```gherkin
Cenário: Usar o Ipega sozinho
  Dado só o Ipega conectado e o app em execução
  Quando o usuário move o analógico esquerdo e pressiona R
  Então o cursor se move e um clique esquerdo é feito sob ele

Cenário: Correspondência por posição
  Dado o Ipega ativo e nenhum arquivo de configuração
  Quando o usuário segura L e pressiona o botão frontal de baixo (A)
  Então "CONTINUAR" é digitado, como com L1 + ✕ no DualSense

Cenário: Home abre a paleta
  Dado o Ipega ativo e nenhum arquivo de configuração
  Quando o usuário pressiona Home uma vez
  Então a paleta é aberta uma única vez

Cenário: Share como atalho livre
  Dado o Ipega ativo
  Quando o usuário atribui ao Share, pelo editor, o envio de um texto e salva
  E pressiona Share
  Então o texto é digitado no aplicativo em foco
  E nenhum clique é feito

Cenário: Share sem ação por padrão
  Dado o Ipega ativo e nenhum arquivo de configuração
  Quando o usuário pressiona Share
  Então nada acontece

Cenário: Share recusa papel de clique
  Dado o editor aberto com o Ipega ativo
  Quando o usuário seleciona o Share
  Então o editor oferece os tipos de ação dos botões livres
  E não o apresenta como clique fixo

Cenário: Dois controles conectados
  Dado o DualSense conectado primeiro e o Ipega depois
  Quando o usuário move o analógico do Ipega
  Então o cursor não se move
  E, desligado o DualSense, o analógico do Ipega passa a mover o cursor

Cenário: Desconexão com botão pressionado
  Dado o Ipega ativo e Share marcado como modificador ⌘
  Quando o usuário segura Share e desconecta o cabo
  Então ⌘ não fica pressionado no sistema

Cenário: Ipega em outro modo
  Dado o Ipega trocado para outro modo pelo botão Android ou iOS
  Quando o controle se reconecta com outra identidade
  Então o app o ignora e registra no log uma única vez o modelo ignorado

Cenário: DualSense inalterado
  Dado um arquivo de configuração gravado antes da feature
  Quando o usuário usa o DualSense
  Então cada botão produz a mesma ação de antes

Cenário: Identificação no editor
  Dado o editor no modo de identificação e o Ipega ativo
  Quando o usuário pressiona Select
  Então o botão Create é selecionado na figura

Cenário: Configuração compartilhada
  Dado o Ipega ativo
  Quando o usuário atribui pelo editor um atalho a L + A e salva
  E passa a usar o DualSense
  Então L1 + ✕ produz o mesmo atalho

Cenário: Figura com o Ipega ativo
  Dado o editor aberto com o Ipega ativo
  Quando o usuário observa a aba Atalhos
  Então a figura mostra o Share e o touchpad marcado como ausente
  E os botões aparecem com os nomes do DualSense

Cenário: Outro controle do tipo Switch Pro
  Dado um controle Switch Pro com identificação diferente da do Ipega
  Quando ele se conecta
  Então o app o ignora e registra no log uma única vez o modelo ignorado

Cenário: Botões de firmware
  Dado o Ipega ativo
  Quando o usuário pressiona Turbo ou Clear
  Então o app não produz efeito nem registra evento
```

## 8. Prioridade MoSCoW

| Item | MoSCoW | Justificativa |
|------|--------|---------------|
| RF-01 | Must | É o pedido: usar o Ipega |
| RF-02 | Must | Sem as 18 entradas, o controle fica incompleto |
| RF-03 | Must | O PS abre a paleta, entrada principal dos comandos |
| RF-04 | Must | Decisão do usuário sobre o Share |
| RF-05 | Must | O ponteiro é função básica do app |
| RF-06 | Must | Os dois controles podem estar conectados ao mesmo tempo |
| RF-07 | Must | Regra de segurança do legado (001 RN-04) |
| RF-08 | Must | Sem mapeamento, o Ipega não dispara atalhos |
| RF-09 | Must | O DualSense é o controle principal do usuário |
| RF-10 | Must | O editor é o único meio de configuração sem teclado |
| RF-11 | Should | Conforto visual; a identificação por RF-10 já permite configurar |
| RF-12 | Should | Diagnóstico; não afeta o uso |
| Botões Android, iOS, Turbo e Clear | Won't | Não chegam ao Mac (RN-10) |
| Ipega nos modos Android ou iOS | Won't | Outra identidade de dispositivo; fora do pedido (RN-01) |
| Share como clique esquerdo | Won't | Decisão do usuário (RN-05) |
| Outros controles do tipo Switch Pro e gamepads genéricos | Won't | Decisão do usuário (RN-01) |
| Configuração de atalhos própria do Ipega | Won't | Decisão do usuário (RN-07) |
| Figura própria do Ipega e nomes impressos no Ipega | Won't | Decisão do usuário (RN-12, RN-13) |
| Vibração, luzes e sensores de movimento do Ipega | Won't | O app não usa esses recursos nem no DualSense |

## 9. Esclarecimentos

Decisões tomadas antes do requisito, na sessão de 2026-09-19:

- Correspondência dos botões frontais pela posição, e não pelo rótulo impresso (RN-03).
- Select age como Create e Start como Options (RN-03).
- Share é botão de atalho livre, e o clique esquerdo fica só no R1 (RN-05, RN-06).

### Sessão 2026-09-19

- **Q:** Quais controles o app deve aceitar, além do DualSense?
  **R:** (a) Só o Ipega no modo Switch Pro, identificado pelo fabricante e pelo produto com que se apresenta (0x057E / 0x2009). Integrado em RN-01.
- **Q:** Como o Ipega recebe os atalhos?
  **R:** (a) Usa a mesma configuração do DualSense, com o Share como botão a mais, sem ação até ser atribuída. Integrado em RN-07 e RF-08.
- **Q:** Qual figura a aba Atalhos mostra quando o Ipega está ativo?
  **R:** (a) A figura do DualSense, com um botão Share acrescentado e o touchpad marcado como ausente. Integrado em RN-12 e RF-11.
- **Q:** Que nomes de botão o editor e os resumos usam quando o Ipega está ativo?
  **R:** (a) Os nomes do DualSense, e o Share com nome próprio. Integrado em RN-13 e RF-11.

## 10. Lacunas

- n/a: nenhuma dúvida pendente.
- 🟡 Inferência a confirmar no plano, sem decisão pendente: com o DualSense ativo, o Share não aparece na figura (RN-12), de modo que a ação dele só pode ser editada pelo editor com o Ipega ativo ou pelo arquivo de configuração.
- 🟡 Risco residual: o Home do Ipega pode acionar algum gesto do sistema, como o PS acionava o Launchpad no DualSense; a sonda de 2026-09-19 não observou efeito, e o portão manual deve conferir.

## Pendências de Qualidade

- Q-018 (nome de produto): o documento cita DualSense, Ipega, Switch Pro Controller e macOS. As citações foram mantidas porque os modelos de controle são o próprio objeto da feature, e não escolha de implementação.

## 11. Histórico de alterações

| Data | Alteração | Autor |
|------|-----------|-------|
| 2026-09-19 | Versão inicial gerada por `/reversa-requirements` | reversa |
| 2026-09-19 | Sessão do `/reversa-clarify`: escopo, configuração compartilhada, figura e nomes resolvidos (RN-01, RN-07, RN-12, RN-13) | reversa |
