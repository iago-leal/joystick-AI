# Requirements: Controle DualShock 4 ao lado do DualSense e do Ipega

> Identificador: `012-controle-dualshock-4`
> Data: `2026-09-22`
> Pasta da extração reversa: `_reversa_sdd/`
> Confidência: 🟢 CONFIRMADO, 🟡 INFERIDO, 🔴 LACUNA / DÚVIDA

## 1. Resumo executivo

A feature permite que o programador de sofá use, ao lado do DualSense e do Ipega, um controle que se apresenta ao sistema como DualShock 4: o controle do PlayStation 4 da Sony ou um clone que o emula, como o GameSir G8+ no modo PlayStation. Hoje o app conhece só dois modelos, e o controle novo, embora casado por Bluetooth e visto pelo sistema com perfil completo, é recusado e registrado no log como modelo não aceito. O DualShock 4 tem os mesmos 18 botões do DualSense nas mesmas posições, inclusive o touchpad com clique, e por isso deve se comportar como o DualSense: mover o ponteiro, clicar, rolar, disparar atalhos e a paleta, e mostrar a carga nas interfaces.

## 2. Contexto a partir do legado

| Fonte | Trecho relevante | Confidência |
|-------|------------------|-------------|
| Pedido do usuário, 2026-09-22 | "Conectei um novo controle. Verifique a compatibilidade com o app." e, após a verificação, "Abra a feature 012." | 🟢 |
| Sonda no sistema, 2026-09-22 | O controle novo aparece por Bluetooth como "DUALSHOCK 4 Wireless Controller", fabricante 0x054C e produto 0x05C4 (DualShock 4 de primeira geração). A interface de controles do sistema lhe dá o perfil DualShock, com 34 elementos: quatro botões frontais, ombros, gatilhos, cliques dos analógicos, PS, Share, Options, direcional e touchpad com dois dedos e clique. O sistema informa a bateria (55 %, descarregando). Um segundo dispositivo, "GameSir-G8+" (0x3537, 0x1108), casado por Bluetooth Low Energy com endereço quase idêntico, declara-se digitalizador e não chega à interface de controles | 🟢 |
| Log `~/Library/Logs/joystick-ai/poc-20260921-193627.jsonl`, 2026-09-22 13:24 | `controller.ignored` com nome "DUALSHOCK 4 Wireless Controller", categoria "DualShock 4" e motivo `unsupported_model`, uma única vez, com o app em execução | 🟢 |
| `_reversa_sdd/addenda/007-controle-ipega.md#Resumo da entrega` | O app conhece um modelo de controle com dois valores, DualSense e Ipega; a classificação usa o perfil da interface de controles e o par fabricante/produto do registro de dispositivos; os botões correspondem pela posição física; a configuração é única; a figura do editor muda conforme o ativo | 🟢 |
| `_reversa_sdd/domain.md#3.1 Controle e entrada (001)` | 001 RN-01, lida pelo adendo 007: um ativo, o primeiro controle aceito; outros modelos ignorados. 001 RN-04: nenhuma desconexão deixa entrada presa. 001 RN-05 e RN-06: touchpad relativo, só o primeiro dedo, somado ao analógico esquerdo | 🟢 |
| `_reversa_sdd/entrada-do-controle/requirements.md#Regras de Negócio` | RN-EC-03 (alterada pela 007): modelo não reconhecido é ignorado com `unsupported_model`. RN-EC-11: fase do toque inferida pela transição de e para a origem quando o sistema não a informa. RN-EC-12 e RN-EC-13: PS lido no relatório bruto e, por Bluetooth, leitura de um relatório de recurso para tirar o DualSense do modo simplificado. RN-EC-14: tipo de conexão pelo transporte do registro de dispositivos. RN-EC-16: mapeamento físico dos 18 botões. RN-EC-17: PS entregue ao ativo | 🟢 |
| `_reversa_sdd/domain.md#4. Regras implícitas (só no código)` | RI-08: o sistema retém o PS antes da interface de controles, e o app o lê do relatório bruto. RI-10: no DualSense a fase do toque é inferida, porque o dicionário de touchpads vem vazio | 🟢 |
| `_reversa_sdd/atalhos/requirements.md#Regras de Negócio` | RN-AT-01: R1, R2 e clique do touchpad são cliques fixos, nunca atalho nem modificador. RN-AT-19: mapeamento padrão sem arquivo de configuração | 🟢 |
| `_reversa_sdd/editor/requirements.md#Regras de Negócio` | RN-ED-14 (alterada pela 007): a figura mostra os botões nas posições físicas e conhece o controle ativo; com o DualSense ou sem controle, a figura é a original | 🟢 |
| `_reversa_forward/011-bateria-e-cursor-no-menu/requirements.md#5. Requisitos Funcionais` | RF-01 a RF-09: o editor e a paleta mostram a carga do controle ativo, com estado de carregamento quando o sistema o informa, frase própria sem controle ou sem carga, atualização periódica e reação imediata a conexão, desconexão e promoção. O adendo dessa feature ainda não foi gerado | 🟡 |
| `_reversa_sdd/architecture.md#5. Modelo de dados em arquivo` | O log tem `model` em `controller.connected` e `reason` em `controller.ignored`; `logSchema` segue 1; o identificador do controle só existe no log | 🟢 |
| `_reversa_sdd/sdd/controller-input.md#4. Non-Goals (Fora do Escopo)` | NG-01: suporte a controles que não sejam DualSense (Xbox, DualShock 4, Switch Pro) fora do MVP. A 007 já abriu essa exclusão para o Ipega; esta feature a abre para o DualShock 4 | 🟢 |

**Constatação.** O DualShock 4 é o único dos modelos aceitos ou pedidos até aqui cuja disposição física coincide inteiramente com a do DualSense: 18 entradas nas mesmas posições, touchpad com clique incluído. A única diferença de nome está no botão à esquerda do touchpad, chamado Share no DualShock 4 e Create no DualSense; é o mesmo botão, e não o botão de captura do Ipega. O sistema já entrega o perfil completo, a bateria e o tipo de conexão, de modo que a feature consiste em aceitar a identidade e estender a ela as regras que hoje valem para o DualSense. 🟢

O usuário confirmou em 2026-09-22 que o controle novo é um GameSir G8+ no modo PlayStation, sem touchpad físico, e não um DualShock 4 da Sony; a sonda já o indicava pelos dois endereços Bluetooth quase idênticos, pelo fabricante GameSir do segundo dispositivo e pelo produto 0x05C4, a primeira geração que os clones costumam emular. O app não tem como distinguir os dois: a identidade que chega é a mesma. A diferença prática está no touchpad, que o GameSir G8+ não tem fisicamente, embora o perfil declare os elementos. Por consequência, o portão manual desta feature exercita só o clone, por Bluetooth, e o comportamento próprio do DualShock 4 da Sony (touchpad físico, cabo) fica verificado por teste automatizado. 🟢

## 3. Personas e cenários de uso

| Persona | Objetivo | Cenário-chave |
|---------|----------|---------------|
| Programador de sofá (`_reversa_sdd/personas.md#Persona 1: Programador de sofá`) | Usar o controle novo no lugar do DualSense, sem reaprender nada | Casa o controle por Bluetooth, move o ponteiro pelo analógico, clica com R1, abre a paleta com PS e envia "CONTINUAR" com o mesmo atalho que usaria no DualSense |
| Programador de sofá | Alternar entre os três controles conforme carga e cômodo | Com o DualSense descarregado, pega o controle novo; o app o adota sem reiniciar e mostra a carga dele no editor e na paleta |

O uso é alternado: um controle de cada vez na mão, com os outros eventualmente conectados. 🟡

## 4. Regras de negócio novas ou alteradas

1. **RN-01:** O app aceita um terceiro modelo de controle, o DualShock 4, identificado pelo perfil DualShock da interface de controles do sistema e pelo par fabricante 0x054C com produto 0x05C4 (primeira geração) ou 0x09CC (segunda geração) no registro de dispositivos. Vale tanto para o controle da Sony quanto para clones que se apresentem com essa identidade, como o GameSir G8+ no modo PlayStation. Controles de outros modelos, e o GameSir em outro modo, continuam ignorados e registrados uma vez no log. 🟢
   - Origem no legado: `_reversa_sdd/domain.md#3.1 Controle e entrada (001)` (001 RN-01); `_reversa_sdd/entrada-do-controle/requirements.md#Regras de Negócio` (RN-EC-03); `_reversa_sdd/addenda/007-controle-ipega.md#Resumo da entrega`
   - Tipo: alterada
2. **RN-02:** A regra do controle ativo vale para os três modelos sem distinção: o primeiro controle aceito a se conectar é o ativo, e os demais aguardam em fila, na ordem de chegada, sem produzir eventos; desconectado o ativo, o próximo assume, seja de que modelo for. 🟢
   - Origem no legado: `_reversa_sdd/entrada-do-controle/requirements.md#Regras de Negócio` (RN-EC-01, RN-EC-02, RN-EC-07)
   - Tipo: alterada (a fila passa a misturar três modelos)
3. **RN-03:** Os 18 botões do DualShock 4 são os do DualSense, pela posição física: ✕, ○, □ e △; L1 e R1; L2 e R2, contados como pressionados a partir de metade do curso; L3 e R3; o direcional; Options; o Share do DualShock 4, que ocupa a posição do Create, age como Create; PS; e o clique do touchpad. O identificador de botão de captura criado para o Ipega não é usado pelo DualShock 4. 🟢
   - Origem no legado: `_reversa_sdd/entrada-do-controle/requirements.md#Regras de Negócio` (RN-EC-09, RN-EC-16); `_reversa_forward/007-controle-ipega/requirements.md#4. Regras de negócio novas ou alteradas` (RN-03, RN-05)
   - Tipo: alterada (o mapeamento passa a cobrir o DualShock 4)
4. **RN-04:** O touchpad do DualShock 4 obedece às regras do touchpad do DualSense: deslocamento relativo, só o primeiro dedo conta, pousar o dedo não move, o deslocamento soma-se ao do analógico esquerdo, e o clique do touchpad é clique esquerdo fixo. Por Bluetooth, o app faz o que for preciso para que o toque chegue, como já faz com o DualSense. Se o aparelho físico não tiver touchpad, como no GameSir G8+, os elementos existem, nunca disparam e não produzem erro nem aviso. Como o aparelho disponível é o clone, o caminho do toque num DualShock 4 da Sony é verificado por teste automatizado, e o portão manual confirma só a ausência de erro no clone. 🟡
   - Origem no legado: `_reversa_sdd/domain.md#3.1 Controle e entrada (001)` (001 RN-05, RN-06); `_reversa_sdd/entrada-do-controle/requirements.md#Regras de Negócio` (RN-EC-11, RN-EC-13); `_reversa_sdd/atalhos/requirements.md#Regras de Negócio` (RN-AT-01); esclarecimento de 2026-09-22 (Q1)
   - Tipo: alterada (a regra passa a cobrir o DualShock 4)
5. **RN-05:** O PS do DualShock 4 obedece às regras do PS: só mudanças de estado são entregues, sem repetição quando chegar por mais de uma via, sempre ao controle ativo e só quando o emissor for do mesmo modelo do ativo. Sem arquivo de configuração, o PS abre a paleta. 🟡
   - Origem no legado: `_reversa_sdd/entrada-do-controle/requirements.md#Regras de Negócio` (RN-EC-06, RN-EC-12, RN-EC-17); `_reversa_sdd/domain.md#4. Regras implícitas (só no código)` (RI-08); `_reversa_forward/007-controle-ipega/requirements.md#4. Regras de negócio novas ou alteradas` (RN-04)
   - Tipo: alterada
6. **RN-06:** O DualShock 4 usa a mesma configuração de atalhos do DualSense e do Ipega, pela correspondência de RN-03, e o mesmo mapeamento padrão. Não há configuração própria por modelo, e um arquivo gravado antes da feature continua válido sem migração. O comportamento do DualSense e do Ipega não muda. 🟢
   - Origem no legado: `_reversa_sdd/architecture.md#5. Modelo de dados em arquivo`; `_reversa_sdd/atalhos/requirements.md#Regras de Negócio` (RN-AT-19); `_reversa_forward/007-controle-ipega/requirements.md#4. Regras de negócio novas ou alteradas` (RN-07, RN-08)
   - Tipo: alterada
7. **RN-07:** Nenhuma desconexão do DualShock 4 deixa entrada presa: botões pressionados, inclusive PS e clique do touchpad, recebem soltura sintética, e o próximo controle da fila assume com o conjunto de pressionados vazio. 🟢
   - Origem no legado: `_reversa_sdd/domain.md#3.1 Controle e entrada (001)` (001 RN-04); `_reversa_sdd/entrada-do-controle/requirements.md#Regras de Negócio` (RN-EC-07)
   - Tipo: alterada (a regra passa a cobrir o DualShock 4)
8. **RN-08:** O log identifica o DualShock 4 com valor próprio de modelo ao registrar conexão e desconexão, resolve o tipo de conexão (cabo ou sem fio) pela identidade da Sony, e a ferramenta de conferência de botões lista os 18 do modelo. Valores de eixo e posições de toque continuam fora do log, e o esquema do log não muda. O valor `usb` é verificado só por teste automatizado, porque o portão manual desta feature cobre apenas o Bluetooth. 🟢
   - Origem no legado: `_reversa_sdd/entrada-do-controle/requirements.md#Regras de Negócio` (RN-EC-14, RN-EC-15); esclarecimento de 2026-09-22 (Q2); `_reversa_sdd/architecture.md#5. Modelo de dados em arquivo`; `_reversa_forward/007-controle-ipega/requirements.md#4. Regras de negócio novas ou alteradas` (RN-11)
   - Tipo: alterada
9. **RN-09:** O editor e a paleta mostram a carga do DualShock 4 como mostram a do DualSense: porcentagem inteira, estado de carregamento quando o sistema o informa, destaque no limite já decidido, frase de indisponibilidade quando o sistema não informa, e reação imediata à conexão, desconexão e promoção. A regra apoia-se no código da feature 011, já commitado, e é verificada por teste automatizado; a conferência visual da carga não entra no portão manual desta feature, por preferência do usuário pelo mínimo de testes manuais. 🟡
   - Origem no legado: `_reversa_forward/011-bateria-e-cursor-no-menu/requirements.md#5. Requisitos Funcionais` (RF-01 a RF-09); esclarecimento de 2026-09-22 (Q4)
   - Tipo: alterada (a regra passa a cobrir o DualShock 4)
10. **RN-10:** Com o DualShock 4 ativo, a aba Atalhos mostra a figura do DualSense sem alteração, com os nomes do DualSense (Create, e não Share, para o botão à esquerda do touchpad), e o modo de identificação seleciona na figura o botão correspondente ao pressionado. O usuário confirmou a escolha em 2026-09-22. 🟢
    - Origem no legado: `_reversa_sdd/editor/requirements.md#Regras de Negócio` (RN-ED-14); `_reversa_forward/007-controle-ipega/requirements.md#4. Regras de negócio novas ou alteradas` (RN-12, RN-13); esclarecimento de 2026-09-22 (Q5)
    - Tipo: alterada
11. **RN-11:** Ficam fora do app o canal Bluetooth Low Energy próprio do GameSir, qualquer outro dispositivo que o clone exponha, os botões traseiros e de firmware do clone, e a vibração, a luz e os sensores de movimento do DualShock 4. O app não os abre, não os lê e não os mostra. 🟢
    - Origem no legado: `_reversa_forward/007-controle-ipega/requirements.md#4. Regras de negócio novas ou alteradas` (RN-10); `_reversa_sdd/sdd/controller-input.md#4. Non-Goals (Fora do Escopo)` (NG-03)
    - Tipo: nova

## 5. Requisitos Funcionais

| ID | Requisito | Prioridade | Critério de aceite | Confidência |
|----|-----------|------------|--------------------|-------------|
| RF-01 | Aceitar o DualShock 4 como controle ativo (RN-01, RN-02) | Must | Com só o DualShock 4 conectado por Bluetooth, o analógico esquerdo move o cursor e R1 clica; o log registra a conexão com o modelo, e nenhum `controller.ignored` aparece para ele | 🟢 |
| RF-02 | Entregar as 18 entradas pela correspondência de posição (RN-03) | Must | A ferramenta de conferência de botões registra 18 de 18 entradas, e o Share do DualShock 4 chega como Create | 🟢 |
| RF-03 | Tratar o PS do DualShock 4 como o PS (RN-05) | Must | Sem arquivo de configuração, um toque no PS abre a paleta uma única vez, e o sistema não abre nenhuma tela própria | 🟡 |
| RF-04 | Mover e clicar pelo touchpad (RN-04) | Must | Por teste automatizado: com a identidade do DualShock 4, arrastar o dedo move o cursor e o clique do touchpad faz clique esquerdo; no portão manual, com o GameSir G8+, nada acontece e nenhum erro é registrado | 🟡 |
| RF-05 | Mover, clicar e rolar pelos analógicos e ombros (RN-03) | Must | O analógico esquerdo move o cursor, L1 reduz a velocidade, R1 e R2 fazem os cliques esquerdo e direito, e o analógico direito rola | 🟢 |
| RF-06 | Alternar entre os controles conectados (RN-02) | Must | Com o DualSense conectado primeiro e o DualShock 4 depois, só o DualSense age; desligado o DualSense, o DualShock 4 assume sem reiniciar o app; o mesmo vale com o Ipega em qualquer ordem | 🟢 |
| RF-07 | Não deixar entrada presa ao desconectar (RN-07) | Must | Desligar o DualShock 4 com R1, PS ou um modificador pressionado não deixa tecla, modificador nem botão do mouse pressionado | 🟢 |
| RF-08 | Aplicar ao DualShock 4 a configuração compartilhada (RN-06) | Must | L1 + ✕ produz a mesma ação nos três controles; uma ação atribuída com o DualShock 4 ativo vale nos outros dois | 🟢 |
| RF-09 | Manter inalterados o DualSense e o Ipega (RN-06) | Must | Um arquivo de configuração anterior à feature continua válido sem migração, e os dois controles produzem as mesmas ações de antes | 🟢 |
| RF-10 | Identificar no editor os botões pressionados (RN-10) | Must | No modo de identificação, pressionar cada um dos 18 botões do DualShock 4 seleciona na figura o botão correspondente | 🟡 |
| RF-11 | Manter a figura do DualSense com o DualShock 4 ativo (RN-10) | Should | Com o DualShock 4 ativo, a figura é idêntica à do DualSense, com o touchpad presente e sem o botão de captura do Ipega | 🟢 |
| RF-12 | Mostrar a carga do DualShock 4 nas duas interfaces (RN-09) | Should | Por teste automatizado: com o DualShock 4 ativo, o editor e a paleta mostram a porcentagem informada pelo sistema, e a troca de controle ativo atualiza o valor; fora do portão manual | 🟡 |
| RF-13 | Registrar no log o modelo e o tipo de conexão (RN-08) | Should | O evento de conexão traz o valor próprio do modelo e `bluetooth` ou `usb`; `usb` é conferido só por teste automatizado; um controle de outro modelo continua a aparecer como ignorado, uma única vez | 🟢 |
| RF-14 | Ignorar os dispositivos anexos do clone (RN-11) | Must | Com o GameSir G8+ casado, o canal Bluetooth Low Energy dele não gera evento, erro nem entrada de log além do que já havia | 🟢 |

## 6. Requisitos Não Funcionais

| Tipo | Requisito | Evidência ou justificativa | Confidência |
|------|-----------|----------------------------|-------------|
| Desempenho | A latência entre pressionar um botão do DualShock 4 e o efeito no sistema não excede a medida para o DualSense na feature 001; a leitura do PS e do toque não entra no caminho do ponteiro | `_reversa_sdd/entrada-do-controle/requirements.md#Requisitos Não Funcionais` | 🟡 |
| Compatibilidade | Configurações existentes continuam válidas sem migração; o mapeamento padrão e o esquema do log não mudam | `_reversa_sdd/architecture.md#5. Modelo de dados em arquivo`; RN-06, RN-08 | 🟢 |
| Compatibilidade | Funcionar no macOS em uso pelo usuário (26) sem quebrar o mínimo declarado do app (13) | `_reversa_sdd/inventory.md#1. Visão geral` | 🟡 |
| Segurança | Nenhuma permissão nova além das já exigidas pela leitura do PS no relatório bruto; nenhuma rede | `_reversa_sdd/permissions.md#2. Matriz de permissões do sistema operacional` | 🟡 |
| Privacidade | Valores de eixo, posições de toque e textos de atalho continuam fora do log; o endereço Bluetooth do controle não entra no log | `_reversa_sdd/domain.md#3.1 Controle e entrada (001)` (001 RN-12); RN-EC-15 | 🟢 |
| Robustez | A identidade de clone não altera o comportamento: elementos declarados e nunca acionados, como o touchpad do GameSir, não geram erro, aviso nem repetição no log | RN-04, RN-11 | 🟡 |
| Testabilidade | Classificação, correspondência de botões, fila com três modelos, regras de configuração, caminho do toque, tipo de conexão `usb` e carga nas interfaces verificáveis por testes automatizados; o portão manual limita-se ao mínimo, com o GameSir G8+ por Bluetooth: PS, ponteiro, cliques, atalhos, ausência de erro do touchpad e alternância de controle ativo | `_reversa_sdd/architecture.md#6. Qualidade e verificação`; esclarecimentos de 2026-09-22 (Q1, Q2, Q4) | 🟢 |
| Observabilidade | O log distingue os três modelos pelo valor registrado na conexão, e a ferramenta de conferência de botões cobre o DualShock 4 | RN-08 | 🟢 |

## 7. Critérios de Aceitação

```gherkin
Cenário: Usar o DualShock 4 sozinho
  Dado só o DualShock 4 casado por Bluetooth e o app em execução
  Quando o usuário move o analógico esquerdo e pressiona R1
  Então o cursor se move e um clique esquerdo é feito sob ele

Cenário: Adoção na abertura
  Dado o DualShock 4 já casado antes de o app abrir
  Quando o app inicia
  Então o log registra a conexão com o modelo do DualShock 4 e a adoção no início
  E nenhum registro de modelo ignorado aparece para ele

Cenário: Correspondência por posição
  Dado o DualShock 4 ativo e nenhum arquivo de configuração
  Quando o usuário segura L1 e pressiona ✕
  Então "CONTINUAR" é digitado, como no DualSense e no Ipega

Cenário: Share age como Create
  Dado o editor no modo de identificação e o DualShock 4 ativo
  Quando o usuário pressiona o Share do DualShock 4
  Então o botão Create é selecionado na figura

Cenário: PS abre a paleta
  Dado o DualShock 4 ativo e nenhum arquivo de configuração
  Quando o usuário pressiona PS uma vez
  Então a paleta é aberta uma única vez
  E nenhuma tela do sistema é aberta

Cenário: Touchpad num controle com touchpad físico
  Dado um DualShock 4 com touchpad físico, ativo, por Bluetooth
  Quando o usuário pousa o dedo, arrasta e pressiona o touchpad
  Então o cursor se move só durante o arraste
  E o pressionar faz clique esquerdo

Cenário: Touchpad num clone sem touchpad
  Dado o GameSir G8+ no modo PlayStation, ativo
  Quando o usuário usa o controle por dez minutos sem tocar em nada que não exista
  Então nenhum evento de toque é registrado
  E nenhum erro ou aviso sobre o touchpad aparece no log

Cenário: Três controles conectados
  Dado o DualSense conectado primeiro, o Ipega depois e o DualShock 4 por último
  Quando o usuário move o analógico do DualShock 4
  Então o cursor não se move
  E, desligados o DualSense e o Ipega, o analógico do DualShock 4 passa a mover o cursor

Cenário: Desconexão com botão pressionado
  Dado o DualShock 4 ativo e Options marcado como modificador ⌘
  Quando o usuário segura Options e desliga o controle
  Então ⌘ não fica pressionado no sistema

Cenário: Carga nas interfaces
  Dado o DualShock 4 ativo com carga informada pelo sistema
  Quando o usuário abre o editor e depois a paleta
  Então as duas mostram a porcentagem do DualShock 4
  E, trocado o controle ativo, o valor acompanha o novo ativo

Cenário: Configuração compartilhada
  Dado o DualShock 4 ativo
  Quando o usuário atribui pelo editor um atalho a L1 + ○ e salva
  E passa a usar o DualSense
  Então L1 + ○ produz o mesmo atalho

Cenário: DualSense e Ipega inalterados
  Dado um arquivo de configuração gravado antes da feature
  Quando o usuário usa o DualSense ou o Ipega
  Então cada botão produz a mesma ação de antes

Cenário: GameSir em outro modo
  Dado o GameSir G8+ trocado para o modo Xbox ou Switch
  Quando o controle se reconecta com outra identidade
  Então o app o ignora e registra no log uma única vez o modelo ignorado

Cenário: Controle de outro modelo
  Dado um controle Xbox conectado
  Quando ele se conecta
  Então o app o ignora e registra no log uma única vez o modelo ignorado
  E o DualShock 4 ativo continua a agir

Cenário: Canal anexo do clone
  Dado o GameSir G8+ casado, com o canal Bluetooth Low Energy dele presente
  Quando o app inicia e roda por uma sessão inteira
  Então o canal anexo não gera evento, erro nem registro de modelo ignorado
```

Os cenários "Touchpad num controle com touchpad físico" e "Carga nas interfaces" são verificados só por teste automatizado, porque o aparelho disponível é o GameSir G8+ e o usuário pediu o mínimo de testes manuais; os demais compõem o portão manual, todos por Bluetooth. 🟢

## 8. Prioridade MoSCoW

| Item | MoSCoW | Justificativa |
|------|--------|---------------|
| RF-01 | Must | É o pedido: usar o controle novo |
| RF-02 | Must | Sem as 18 entradas, o controle fica incompleto |
| RF-03 | Must | O PS abre a paleta, entrada principal dos comandos |
| RF-04 | Must | O touchpad é parte do modelo aceito; num clone sem touchpad, o requisito se reduz a não falhar |
| RF-05 | Must | O ponteiro é função básica do app |
| RF-06 | Must | Os três controles podem estar conectados ao mesmo tempo |
| RF-07 | Must | Regra de segurança do legado (001 RN-04) |
| RF-08 | Must | Sem mapeamento, o controle não dispara atalhos |
| RF-09 | Must | O DualSense e o Ipega são os controles em uso; regressão neles custa mais que a feature |
| RF-10 | Must | O editor é o único meio de configuração sem teclado |
| RF-14 | Must | Um dispositivo anexo que gere ruído ou erro no log contamina o diagnóstico das demais features |
| RF-11 | Should | Conforto visual; a identificação por RF-10 já permite configurar |
| RF-12 | Should | A carga é entrega da 011 e vale para qualquer controle aceito; o app já recebe o valor do sistema |
| RF-13 | Should | Diagnóstico; não afeta o uso |
| RNF de desempenho | Should | O caminho de tempo real não muda; a medida confirma |
| GameSir nos modos Xbox e Switch | Won't | Outra identidade de dispositivo; fora do pedido (RN-01) |
| Portão manual por cabo | Won't | Só o Bluetooth está disponível; `usb` fica por teste automatizado (RN-08) |
| Touchpad físico e carga no portão manual | Won't | O aparelho disponível não tem touchpad, e o usuário pediu o mínimo de testes manuais (RN-04, RN-09) |
| Canal Bluetooth Low Energy do GameSir e botões traseiros do clone | Won't | Não chegam à interface de controles; sem função no app (RN-11) |
| Vibração, luz e sensores de movimento | Won't | O app não usa esses recursos em nenhum modelo (RN-11) |
| Configuração de atalhos própria do DualShock 4 | Won't | Decisão do usuário na 007, estendida (RN-06) |
| Figura própria do DualShock 4 e nome "Share" no editor | Won't | A figura do DualSense já representa o controle (RN-10) |
| Distinguir clone de controle da Sony | Won't | A identidade que chega é a mesma; não há como, nem motivo, para distinguir (RN-01) |

## 9. Esclarecimentos

### Sessão 2026-09-22

- **Q:** Que aparelho físico é o controle novo: GameSir G8+ no modo PlayStation ou DualShock 4 da Sony?
  **R:** GameSir G8+ no modo PlayStation, sem touchpad físico.
- **Q:** Que transportes o portão manual deve cobrir?
  **R:** Só Bluetooth; o tipo `usb` fica verificado apenas por teste automatizado.
- **Q:** Que identidades da Sony o app deve aceitar como DualShock 4: só 0x05C4, também 0x09CC, ou ainda o adaptador 0x0BA0?
  **R:** Não sei. A RN-01 permanece como está (0x05C4 e 0x09CC); a inclusão do adaptador fica a cargo do plano.
- **Q:** Como o plano deve tratar a dependência da RF-12 em relação ao código da feature 011, commitado mas pausado?
  **R:** Não sei; quero o mínimo possível de testes manuais. Aplicado como: o código da 011 é a base, e a RF-12 é verificada por teste automatizado, fora do portão manual.
- **Q:** Com o DualShock 4 ativo, a aba Atalhos mantém a figura e os nomes do DualSense, com "Create" no botão à esquerda do touchpad?
  **R:** Sim, figura e nomes do DualSense sem alteração.

## 10. Lacunas

- 🟡 A decidir no plano: além de 0x05C4 e 0x09CC, aceitar o adaptador USB sem fio oficial da Sony (0x0BA0) como DualShock 4. O usuário não soube responder; a inclusão custa uma constante e um caso de teste, e o plano decide.
- 🟡 Risco a resolver no plano: o sistema pode reter o PS do DualShock 4 antes da interface de controles, como faz com o DualSense (RI-08), e a leitura do relatório bruto tem disposição diferente da do DualSense; por Bluetooth, o toque pode exigir uma ativação diferente da usada no DualSense (RN-EC-13). Uma sonda como as da 007 decide.
- 🟡 Risco a resolver no plano: num clone, a ativação do toque e a leitura do relatório bruto podem não ser implementadas como na Sony; a sonda deve conferir com o aparelho real.

## Pendências de Qualidade

- Q-018 (nome de produto): o documento cita DualShock 4, DualSense, Ipega, GameSir G8+ e macOS. As citações foram mantidas porque os modelos de controle são o próprio objeto da feature, e não escolha de implementação.

## 11. Histórico de alterações

| Data | Alteração | Autor |
|------|-----------|-------|
| 2026-09-22 | Versão inicial gerada por `/reversa-requirements` | reversa |
| 2026-09-22 | Sessão de esclarecimentos: aparelho confirmado como GameSir G8+, portão manual só por Bluetooth e reduzido ao mínimo, figura do DualSense confirmada; identidades adicionais adiadas ao plano | reversa-clarify |
