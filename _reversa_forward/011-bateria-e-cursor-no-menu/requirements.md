# Requirements: Carga do controle no editor e na paleta, e cursor preservado após o menu da barra

> Identificador: `011-bateria-e-cursor-no-menu`
> Data: `2026-09-20`
> Pasta da extração reversa: `_reversa_sdd/`
> Confidência: 🟢 CONFIRMADO, 🟡 INFERIDO, 🔴 LACUNA / DÚVIDA

## 1. Resumo executivo

A feature entrega duas coisas ao usuário que dirige a sessão de sofá pelo controle. A primeira é informativa: o editor de atalhos e a paleta de comandos passam a mostrar quanta carga resta no controle ativo, hoje um dado que o app nunca exibiu em nenhuma interface, de modo que a queda de energia sempre chega sem aviso. A segunda é corretiva: abrir o menu do app na barra de menus deixa de derrubar a condução pelo controle, defeito que hoje obriga o usuário a levantar-se para o trackpad e clicar fisicamente antes de voltar a clicar pelo joystick, o que anula a premissa central do produto, a de passar a sessão inteira longe do teclado.

## 2. Contexto a partir do legado

| Fonte | Trecho relevante | Confidência |
|-------|------------------|-------------|
| `_reversa_sdd/sdd/controller-input.md#RF-10` | "O sistema deve expor o nível de bateria e o estado de carga do controle ativo, quando disponíveis", classificado como `Could` na spec greenfield e nunca implementado; o tipo previsto trazia `batteryLevel` de 0,0 a 1,0 | 🟡 |
| `_reversa_sdd/sdd/app-shell.md#RF-05` | O menu deveria mostrar controle com nome, conexão e bateria quando disponível; o menu entregue mostra apenas "Editar atalhos", o teclado remoto e "Sair" | 🟡 |
| `_reversa_sdd/domain.md#3.1` (001 RN-01, 001 RN-04) | Há no máximo um controle ativo, o primeiro aceito; os demais esperam em fila e não produzem efeito; nenhuma desconexão deixa entrada presa | 🟢 |
| `_reversa_sdd/addenda/007-controle-ipega.md#Impacto` | O app conhece `ControllerModel` (`dualSense`, `ipega`) e já publica o modelo do controle ativo para o editor, que o usa na figura e marca o touchpad como ausente no Ipega | 🟢 |
| `_reversa_sdd/addenda/010-joystick-virtual-iphone.md#Resumo` | O controle virtual do iPhone não se registra como controle ativo, não entra na fila e não emite conexão; ele só soma botões à união de pressionados | 🟢 |
| `_reversa_sdd/editor/requirements.md#Interface` (RN-ED-13) | Escala de TV do editor: corpo 32 pt, título 40 pt, alvo mínimo de 60 pt, janela mínima 1.400 × 800 pt, legível a cerca de 3 m | 🟢 |
| `_reversa_sdd/domain.md#3.2` (002 RN-02, 002 RN-03) | A paleta nunca toma o foco e digita no aplicativo em foco; aberta, ↑ e ↓ navegam, ✕ confirma, ○ e PS fecham, enquanto ponteiro e cliques seguem funcionando | 🟢 |
| `_reversa_sdd/domain.md#3.3` (003 RN-12) | A paleta tem de 1 a 50 itens, com texto de 1 a 1.000 caracteres em uma linha e rótulo de até 80 | 🟢 |
| `_reversa_sdd/code-analysis.md#6. palette` | O painel é não ativador, nunca chave nem principal, transparente ao mouse, e sua legibilidade a 3 m vem de fonte monoespaçada de 26 pt com linha de 40 pt e largura mínima de 520 pt | 🟢 |
| `_reversa_sdd/domain.md#4` (RI-20) | A paleta fecha sozinha após 60 s sem entrada do controle | 🟢 |
| `_reversa_sdd/code-analysis.md#1. app-shell` | O ícone da barra de menus é um `NSStatusItem` com menu próprio, que troca de símbolo quando a configuração fica inválida; o app roda como acessório, sem ícone no Dock | 🟢 |
| `_reversa_sdd/code-analysis.md#4. injection` | Todo evento sai marcado com `0x4A4F5953` e é postado no ponto de entrada do sistema; a posição acompanhada vale enquanto a leitura do sistema for uma das 32 últimas postadas e houver menos de 100 ms desde a última emissão, senão o mouse físico retoma o controle | 🟢 |
| `_reversa_sdd/domain.md#4` (RI-04) | Suspender a injeção solta tudo o que estava mantido antes de desligar o injetor e guarda as solturas para repeti-las na retomada; o app já sabe desfazer estado preso | 🟢 |
| `_reversa_sdd/domain.md#4` (RI-23, RI-24) | O editor já enfrentou recusa de ativação pelo sistema quando o pedido partia do controle, resolvido por janela flutuante com clique sintético na barra de título; ao fechar, o foco volta ao aplicativo anterior | 🟢 |
| `_reversa_sdd/architecture.md#7` (TD-01) | Nenhum teste automatizado cobre o alvo do aplicativo; só o núcleo puro é testável sem hardware | 🟢 |
| `_reversa_sdd/architecture.md#7` (TD-07) | O log não tem rotação nem limpeza, e eventos de nível `info` não têm teto | 🟢 |

## 3. Personas e cenários de uso

| Persona | Objetivo | Cenário-chave |
|---------|----------|---------------|
| Programador de sofá (persona principal do `prd.md`) | Acompanhar agentes na TV a cerca de 3 m sem tocar no teclado | Abre a paleta pelo controle, vê de relance que restam 38% de carga e decide ligar o cabo antes de começar a sessão longa |
| Programador de sofá | Usar o menu do app sem perder a condução | Abre o menu na barra de menus pelo controle para ligar o teclado remoto, fecha o menu e continua apontando e clicando pelo controle |
| Usuário em bancada, com o controle por cabo | Distinguir carga baixa de controle carregando | Vê que o controle está em 12%, destacado, e carregando, e segue trabalhando sem procurar o cabo |

## 4. Regras de negócio novas ou alteradas

1. **RN-01:** O editor de atalhos e a paleta de comandos exibem a carga do controle ativo como porcentagem inteira de 0 a 100. 🟢
   - Origem no legado: `_reversa_sdd/sdd/controller-input.md#RF-10`, requisito `Could` jamais implementado
   - Tipo: nova
2. **RN-02:** A carga exibida é sempre a do controle ativo definido por `_reversa_sdd/domain.md#3.1` (001 RN-01). Controles em fila não têm carga exibida, e a promoção de um controle da fila a ativo troca o valor mostrado. 🟢
   - Origem no legado: `_reversa_sdd/domain.md#3.1` (001 RN-01, 001 RN-04)
   - Tipo: nova
3. **RN-03:** Sem controle ativo, as duas interfaces dizem em texto que não há controle conectado, e não mostram número nem zero. 🟢
   - Tipo: nova
4. **RN-04:** Quando o controle ativo existe mas o sistema não informa a carga dele, as duas interfaces dizem em texto que a carga é indisponível para aquele controle, e não mostram número nem estimativa. O Ipega, reconhecido pela categoria de controle do Switch, é o caso concreto de risco. 🟡
   - Origem no legado: `_reversa_sdd/addenda/007-controle-ipega.md#Impacto`
   - Tipo: nova
5. **RN-05:** O controle virtual do iPhone não altera nada do que se exibe: ele não é controle ativo, não entra na fila e não tem carga a exibir. Com o iPhone em uso e nenhum controle físico conectado, vale a RN-03. 🟢
   - Origem no legado: `_reversa_sdd/addenda/010-joystick-virtual-iphone.md#Resumo`
   - Tipo: nova
6. **RN-06:** O estado de carregamento é exibido junto da porcentagem quando o sistema o informar, e omitido quando não informar; a ausência dessa indicação nunca impede a exibição do número. 🟡
   - Origem no legado: `_reversa_sdd/sdd/app-shell.md#RF-05`
   - Tipo: nova
7. **RN-07:** Carga igual ou inferior a 15% é exibida com destaque visual nas duas interfaces. O destaque é apenas visual: nenhum som, nenhuma janela modal e nenhuma mudança no que o controle faz. 🟢
   - Origem no legado: nenhuma; limite decidido pelo usuário na clarificação de 2026-09-20
   - Tipo: nova
8. **RN-08:** Na paleta, a carga é parte fixa do painel, e não um item da lista. Portanto ela não conta para o limite de 1 a 50 itens, não é alcançada pela navegação com ↑ e ↓, não é confirmável por ✕, não desloca a entrada fixa "Editar atalhos" e não muda o índice do último confirmado. 🟢
   - Origem no legado: `_reversa_sdd/domain.md#3.2` (002 RN-03) e `#3.3` (003 RN-12)
   - Tipo: nova
9. **RN-09:** Exibir a carga não pode fazer o painel da paleta tomar o foco, nem alterar o fechamento automático por 60 s de inatividade, que continua contando apenas entrada do controle. 🟢
   - Origem no legado: `_reversa_sdd/domain.md#3.2` (002 RN-02) e `#4` (RI-20)
   - Tipo: nova
10. **RN-10:** Com o editor ou a paleta abertos, o valor exibido se atualiza sozinho em no máximo 60 s, e de imediato na conexão, na desconexão e na promoção do controle ativo. Fechados os dois, nenhuma leitura de carga acontece. 🟡
    - Tipo: nova
11. **RN-11:** A leitura da carga não entra no caminho de tempo real: nenhuma consulta ocorre na fila de entrada nem acrescenta trabalho ao temporizador de 120 Hz. 🟢
    - Origem no legado: `_reversa_sdd/architecture.md#2` e ADR-006
    - Tipo: nova
12. **RN-12:** O log registra a carga apenas na conexão do controle e nas mudanças de faixa de carga, nunca a cada leitura, para não inflar o arquivo, que não tem rotação. A porcentagem não é dado sensível e não viola o catálogo fechado de eventos. 🟢
    - Origem no legado: `_reversa_sdd/domain.md#3.1` (001 RN-12) e `_reversa_sdd/architecture.md#7` (TD-07)
    - Tipo: nova
13. **RN-13:** Abrir e fechar o menu do app na barra de menus não pode deixar a condução pelo controle inoperante. O sintoma observado em campo é a parada simultânea do movimento do cursor e do efeito do clique. Fechado o menu, as duas coisas voltam a funcionar sem nenhuma ação no mouse ou no trackpad físico. 🟢
    - Origem no legado: defeito relatado pelo usuário em 2026-09-20 e detalhado na clarificação do mesmo dia; nenhuma regra do legado o prevê
    - Tipo: nova
14. **RN-14:** O defeito é específico do menu deste app: abrir pelo controle os menus de outros itens da barra do macOS não o reproduz. A correção fica, portanto, no que o app controla, e não depende de contornar comportamento geral do sistema. 🟢
    - Origem no legado: evidência de campo do usuário, clarificação de 2026-09-20
    - Tipo: nova
15. **RN-15:** Nenhum botão de mouse fica pressionado depois do ciclo de abrir e fechar o menu. Se o ciclo deixar um botão pendente, o app o solta, do mesmo modo que já solta o que estava mantido ao suspender a injeção. 🟢
    - Origem no legado: `_reversa_sdd/domain.md#4` (RI-04) e `#3.1` (001 RN-04)
    - Tipo: nova
16. **RN-16:** A recuperação descrita em RN-13 e RN-15 vale para qualquer origem da abertura do menu, seja ela um clique vindo do controle ou um clique do mouse físico enquanto o controle está em uso. 🟡
    - Tipo: nova
17. **RN-17:** A correção não pode reintroduzir a recusa de ativação do editor já resolvida, nem alterar o retorno do foco ao aplicativo anterior quando o editor fecha. 🟢
    - Origem no legado: `_reversa_sdd/domain.md#4` (RI-23, RI-24)
    - Tipo: alterada

## 5. Requisitos Funcionais

| ID | Requisito | Prioridade | Critério de aceite | Confidência |
|----|-----------|------------|--------------------|-------------|
| RF-01 | Mostrar no editor de atalhos a carga do controle ativo em porcentagem inteira | Must | Com o controle conectado e carga conhecida, a janela do editor mostra a porcentagem sem que o usuário precise rolar a tela | 🟡 |
| RF-02 | Mostrar na paleta de comandos a carga do controle ativo em porcentagem inteira | Must | Com a paleta aberta pelo controle, a porcentagem aparece no painel sem o usuário navegar até ela | 🟢 |
| RF-03 | Apresentar a carga em tamanho legível a 3 m nas duas interfaces | Must | No editor, o texto acompanha o corpo de 32 pt de RN-ED-13; na paleta, acompanha a escala do painel, de 26 pt em linha de 40 pt; a leitura a 3 m é confirmada no portão manual | 🟢 |
| RF-04 | Indicar o estado de carregamento quando o sistema o informar | Should | Com o controle no cabo, a interface distingue "38%" de "38%, carregando"; sem a informação, mostra só a porcentagem | 🟡 |
| RF-05 | Destacar visualmente a carga igual ou inferior a 15% | Should | Em 15% o valor aparece destacado nas duas interfaces; em 16% aparece sem destaque; nenhum som e nenhuma janela modal são usados | 🟢 |
| RF-06 | Dizer em texto que não há controle conectado | Must | Sem controle, a área da carga traz a frase correspondente nas duas interfaces, e nenhum número aparece | 🟢 |
| RF-07 | Dizer em texto que a carga é indisponível para o controle ativo | Must | Com um controle que não informa carga, a área traz a frase correspondente, e nenhum número aparece | 🟡 |
| RF-08 | Atualizar sozinho o valor enquanto uma das interfaces estiver aberta | Must | Com o editor ou a paleta abertos, uma queda real de carga aparece em até 60 s, sem fechar e reabrir | 🟡 |
| RF-09 | Refletir de imediato conexão, desconexão e promoção do controle ativo | Must | Desligar o controle ativo com o editor aberto troca a exibição para a frase de RF-06 ou para a carga do próximo da fila, sem espera perceptível | 🟢 |
| RF-10 | Preservar o comportamento da paleta com a carga à vista | Must | Navegação com ↑ e ↓, confirmação por ✕, fechamento por ○ e PS, ausência de foco e fechamento por 60 s de inatividade seguem idênticos, e a contagem de itens não muda | 🟢 |
| RF-11 | Preservar a condução pelo controle após o ciclo do menu da barra | Must | Abrir o menu, fechá-lo e, na sequência, mover o cursor e clicar pelo controle, sem tocar no mouse físico | 🟢 |
| RF-12 | Não deixar botão de mouse pendente após o ciclo do menu | Must | Depois do ciclo, um arraste não começa sozinho e o primeiro clique pelo controle é registrado como clique simples | 🟢 |
| RF-13 | Registrar no log evidência suficiente para diagnosticar o ciclo do menu | Should | O log de uma sessão com o defeito reproduzido permite dizer em que ponto a condução parou, sem instrumentação extra | 🟡 |
| RF-14 | Manter o comportamento atual do editor quanto a ativação e devolução de foco | Must | Após a correção, nenhuma sessão registra falha de ativação do editor, e fechar o editor devolve o foco ao aplicativo anterior | 🟢 |

## 6. Requisitos Não Funcionais

| Tipo | Requisito | Evidência ou justificativa | Confidência |
|------|-----------|----------------------------|-------------|
| Desempenho | A leitura da carga não ocorre na fila de entrada nem no temporizador de 120 Hz, e não altera a latência de processamento já medida em 0,110 ms no p95 | `_reversa_sdd/architecture.md#6`, ADR-006 | 🟢 |
| Desempenho | A correção do ciclo do menu não acrescenta consulta síncrona ao caminho de movimento do cursor | `_reversa_sdd/architecture.md#2` | 🟡 |
| Privacidade | Nenhum dado novo sensível: a carga não identifica pessoa, e o catálogo fechado de eventos do log continua sem coordenadas, textos e acordes | `_reversa_sdd/domain.md#3.1` (001 RN-12), suíte do catálogo de eventos | 🟢 |
| Observabilidade | Todo evento novo entra no catálogo fechado com teste próprio, e a carga registrada respeita RN-12 | `_reversa_sdd/architecture.md#6` | 🟢 |
| Testabilidade | A lógica de decisão da exibição, ou seja, formatação da porcentagem, faixa de carga baixa e escolha entre valor e frase de indisponibilidade, precisa ser verificável sem hardware | `_reversa_sdd/architecture.md#7` (TD-01): o alvo do aplicativo não tem teste automatizado | 🟢 |
| Verificação | Portão manual no hardware cobrindo o ciclo do menu com DualSense e com Ipega, e cobrindo a coexistência com o controle virtual do iPhone | Prática estabelecida nos portões PM de 001 a 010 | 🟢 |
| Compatibilidade | A feature não muda o formato do arquivo de configuração nem a versão do esquema do log | `_reversa_sdd/architecture.md#5` | 🟢 |

## 7. Critérios de Aceitação

```gherkin
Cenário: carga visível no editor
  Dado um controle conectado e reconhecido como ativo, com carga conhecida de 38%
  Quando o usuário abre o editor de atalhos
  Então a janela mostra "38%" no corpo de 32 pt da escala de TV

Cenário: carga visível na paleta
  Dado um controle conectado e reconhecido como ativo, com carga conhecida de 38%
  Quando o usuário abre a paleta pelo controle
  Então o painel mostra "38%" na escala de leitura a 3 m
  E o usuário não precisa navegar com ↑ nem ↓ para vê-lo

Cenário negativo: a carga não vira item da paleta
  Dado a paleta aberta com 17 itens e a entrada fixa "Editar atalhos"
  Quando o usuário percorre a lista inteira com ↓ até dar a volta
  Então a seleção passa apenas pelos 17 itens e pela entrada fixa
  E a carga nunca fica selecionada nem é confirmada por ✕

Cenário negativo: a carga não muda o comportamento do painel
  Dado a paleta aberta com a carga à vista
  Quando o usuário deixa de tocar no controle por 60 s
  Então a paleta fecha sozinha como antes
  E em nenhum momento o painel tomou o foco do aplicativo em uso

Cenário: carga acompanha a troca do controle ativo
  Dado dois controles conectados, o ativo em 38% e o da fila em 71%
  Quando o usuário desliga o controle ativo com o editor aberto
  Então a janela passa a mostrar a carga do controle promovido, sem fechar e reabrir

Cenário: atualização sem reabrir a janela
  Dado o editor aberto mostrando 38%
  Quando a carga real do controle cai para 37%
  Então a janela passa a mostrar o valor novo em até 60 s

Cenário negativo: nenhum controle conectado
  Dado que nenhum controle físico está conectado
  Quando o usuário abre o editor de atalhos
  Então a janela informa em texto que não há controle conectado
  E nenhuma porcentagem aparece, nem mesmo zero

Cenário negativo: controle sem informação de carga
  Dado um controle ativo cujo sistema não informa o nível de carga
  Quando o usuário abre o editor de atalhos
  Então a janela informa em texto que a carga é indisponível para esse controle
  E nenhuma porcentagem estimada aparece

Cenário negativo: só o controle virtual do iPhone em uso
  Dado que o iPhone está pareado como controle virtual e nenhum controle físico está conectado
  Quando o usuário abre o editor de atalhos
  Então a janela informa em texto que não há controle conectado

Cenário: carregamento distinguido da descarga
  Dado um controle ativo em 38% e ligado ao cabo, com o sistema informando o estado de carga
  Quando o usuário abre o editor de atalhos
  Então a janela distingue o controle que carrega do controle que descarrega

Cenário negativo: estado de carga não informado
  Dado um controle ativo em 38% cujo sistema não informa se ele carrega
  Quando o usuário abre o editor de atalhos
  Então a janela mostra a porcentagem sem nenhuma indicação de carregamento

Cenário: carga baixa destacada
  Dado um controle ativo com 15% de carga
  Quando o usuário abre o editor ou a paleta
  Então o valor aparece com destaque visual
  E nenhum som é emitido e nenhuma janela modal é aberta

Cenário negativo: carga acima do limite não recebe destaque
  Dado um controle ativo com 16% de carga
  Quando o usuário abre o editor ou a paleta
  Então o valor aparece sem destaque

Cenário: menu da barra não derruba a condução
  Dado o usuário conduzindo o cursor pelo controle físico
  Quando ele abre o menu do app na barra de menus e em seguida o fecha
  Então mover o cursor pelo controle volta a funcionar
  E o clique seguinte pelo controle produz efeito no aplicativo em foco
  E nada precisa ser clicado no mouse ou no trackpad físico

Cenário negativo: nenhum botão preso depois do menu
  Dado o usuário conduzindo o cursor pelo controle físico
  Quando ele abre e fecha o menu do app na barra de menus
  Então nenhum arraste começa sozinho
  E o primeiro clique seguinte pelo controle é registrado como clique simples

Cenário: menu aberto pelo mouse físico durante o uso do controle
  Dado o usuário conduzindo o cursor pelo controle físico
  Quando o menu do app é aberto por um clique do trackpad e fechado em seguida
  Então a condução pelo controle continua funcionando sem intervenção adicional

Cenário: rastro do ciclo do menu no log
  Dado uma sessão em que o defeito do menu foi reproduzido
  Quando o usuário ou o assistente lê o log dessa sessão
  Então é possível dizer em que ponto do ciclo a condução pelo controle parou
  E nenhuma instrumentação adicional precisou ser ligada

Cenário: editor continua ativando e devolvendo o foco
  Dado a correção do ciclo do menu aplicada
  Quando o usuário abre o editor de atalhos pelo controle e depois o fecha
  Então a janela do editor recebe o foco sem registrar falha de ativação
  E o foco volta ao aplicativo que estava à frente
```

## 8. Prioridade MoSCoW

| Item | MoSCoW | Justificativa |
|------|--------|---------------|
| RF-11, RF-12 | Must | O defeito quebra a premissa do produto, a de conduzir a sessão inteira sem teclado e sem trackpad |
| RF-01, RF-02, RF-03 | Must | A carga pedida precisa estar nas duas interfaces que o usuário alcança sem sair do controle, e em tamanho que se leia a 3 m |
| RF-06, RF-07 | Must | Sem as frases de ausência, a informação fica ambígua e pode ser lida como zero |
| RF-08, RF-09 | Must | Valor congelado na abertura é pior que nenhum valor, porque induz decisão errada sobre ligar o cabo |
| RF-10 | Must | A paleta é o caminho mais usado do controle; qualquer regressão de navegação ou de foco custa mais que a informação acrescentada |
| RF-14 | Must | Regressão de ativação do editor já custou uma emenda e 14 falhas registradas em log; não pode voltar |
| RF-04 | Should | Distinguir descarga de carregamento evita a procura desnecessária pelo cabo, mas depende do que o sistema informa |
| RF-05 | Should | O limite de 15% já está decidido, e o destaque é o que transforma o número em aviso; ainda assim, a feature entrega valor sem ele |
| RF-13 | Should | O diagnóstico do defeito vale além desta feature, mas a correção não depende do registro |
| RNF de testabilidade | Should | O alvo do aplicativo não tem teste automatizado; manter a decisão no núcleo puro é a única via de verificação sem hardware |

## 9. Esclarecimentos

### Sessão 2026-09-20

- **Q:** Depois de clicar no ícone do app na barra de menus, o que exatamente deixa de responder ao controle?
  **R:** O cursor para de se mover **e** o clique deixa de produzir efeito. Integrado em RN-13 e no cenário "menu da barra não derruba a condução".
- **Q:** O estado se recupera sozinho, sem tocar no trackpad?
  **R:** Não observado por tempo suficiente para afirmar. A dúvida permanece em Lacunas e deve ser respondida por observação dirigida antes do plano de correção.
- **Q:** O mesmo defeito aparece ao abrir, pelo controle, outros menus da barra do macOS?
  **R:** Não; ocorre só com o ícone deste app. Integrado em RN-14, que restringe a correção ao que o app controla.
- **Q:** Onde a carga do controle deve aparecer?
  **R:** No editor de atalhos, como pedido, e também na paleta de comandos. Integrado em RN-01, RN-08, RN-09, RF-02 e RF-10.
- **Q:** O destaque de carga baixa entra nesta feature?
  **R:** Sim, com destaque a partir de 15%. Integrado em RN-07 e RF-05, que passou de `Could` a `Should`.

## 10. Lacunas

- 🔴 [DÚVIDA] Depois do ciclo do menu, o estado se recupera sozinho? A observação de campo não durou o bastante para dizer se a condução volta após alguns segundos parado, se volta ao trocar o aplicativo em foco, ou se de fato só volta com um clique físico. A resposta separa estado preso dentro do app de espera por um evento que nunca chega, e decide se a correção precisa de um mecanismo de recuperação ativa ou apenas de deixar de reter o que retém.

## 11. Histórico de alterações

| Data | Alteração | Autor |
|------|-----------|-------|
| 2026-09-20 | Versão inicial gerada por `/reversa-requirements` | reversa |
| 2026-09-20 | Cinco respostas integradas por `/reversa-clarify`: sintoma do defeito, escopo restrito ao menu do app, carga também na paleta e limite de 15% para carga baixa | reversa |
