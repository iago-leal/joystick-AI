# Requirements: Prova de conceito de entrada do controle e apontamento

> Identificador: `001-poc-entrada-ponteiro`
> Data: `2026-09-14`
> Pasta da extração reversa: `_reversa_sdd/`
> Confidência: 🟢 CONFIRMADO, 🟡 INFERIDO ou PLANEJADO, 🔴 LACUNA / DÚVIDA

> **Nota de confidência:** o projeto é greenfield. Todas as fontes em `_reversa_sdd/` nasceram do `/reversa-new` com selo 🟡 PLANEJADO e nada foi ainda implementado ou observado; por isso os itens herdados das specs mantêm 🟡. Recebem 🟢 apenas as decisões confirmadas pelo usuário na sessão de esclarecimentos (seção 9), que são decisões e não fatos observados. A PoC existe justamente para converter as premissas 🟡 em fatos.

## 1. Resumo executivo

A primeira feature do joystick-AI é uma prova de conceito (PoC) que lê o controle DualSense no macOS com outro aplicativo em primeiro plano e o converte em mouse: o touchpad e o analógico esquerdo movem o cursor, o analógico direito rola e os botões clicam e arrastam. Destina-se ao programador de sofá, que é também quem avalia o resultado. O objetivo é validar, antes de investir no restante do MVP (produto mínimo viável), as duas premissas críticas mais baratas de testar: a precisão do apontamento e o acesso ao hardware com injeção de eventos. A feature termina com um relatório de validação que decide se o MVP segue como especificado.

## 2. Contexto a partir do legado

Não há sistema legado: `architecture.md`, `domain.md`, `inventory.md` e `code-analysis.md` não existem, tampouco adendos em `_reversa_sdd/addenda/` ou `.reversa/principles.md`. O contexto vem dos artefatos do `/reversa-new`. O recorte foi escolhido pelo usuário em 2026-09-14: `controller-input` e `pointer-control`, sem `app-shell`, com as permissões concedidas manualmente em Ajustes do Sistema.

| Fonte | Trecho relevante | Confidência |
|-------|------------------|-------------|
| `_reversa_sdd/ideation.md#Premissas a validar` | Premissas 1 (precisão do apontamento) e 2 (acesso ao hardware e injeção de eventos), classificadas como críticas pelo usuário. | 🟡 |
| `_reversa_sdd/prd.md#8. Riscos` | Os dois riscos de impacto alto têm como mitigação uma prova de conceito de apontamento antes do restante e a validação cedo da leitura do controle e da injeção. | 🟡 |
| `_reversa_sdd/prd.md#4. Escopo (in)` | Conexão do DualSense no macOS e controle como mouse (mover, clicar, arrastar, rolar). | 🟡 |
| `_reversa_sdd/personas.md#Observação de design` | O apontamento é secundário, voltado a revisão e navegação; o fluxo principal com agentes se apoia em botões e voz. | 🟡 |
| `_reversa_sdd/sdd/controller-input.md#6.1 Requisitos Principais` | RF-01 a RF-09 e os casos EC-01, EC-02, EC-03, EC-05 e EC-06 da leitura do controle. | 🟡 |
| `_reversa_sdd/sdd/controller-input.md#13. Plano de Rollout` | Entrega como PoC isolada, que registra eventos em log, antes de conectar os demais componentes. | 🟡 |
| `_reversa_sdd/sdd/pointer-control.md#6.1 Requisitos Principais` | RF-01 a RF-09 e RF-12 do apontamento; RF-10 e RF-11 dependem de componentes fora desta feature. | 🟡 |
| `_reversa_sdd/sdd/pointer-control.md#13. Plano de Rollout` | Entrega junto com `controller-input`, com teste de acerto em alvos de 16 × 16 pt antes dos demais componentes. | 🟡 |
| `_reversa_sdd/sdd/action-mapping.md#8. Design e Interface` | Mapeamento padrão: R2 e clique do touchpad fazem clique esquerdo, R1 faz clique direito, L1 é o modificador. | 🟡 |
| `_reversa_sdd/sdd/action-mapping.md#13. Plano de Rollout` | `action-mapping` só é entregue após a PoC de `controller-input` e `pointer-control`. | 🟡 |
| `_reversa_sdd/sdd/app-shell.md#11. Edge Cases e Tratamento de Erros` | EC-01: recompilar com assinatura diferente invalida as permissões concedidas. | 🟡 |
| `_reversa_sdd/sdd/app-shell.md#14. Open Questions` | OQ-01 (necessidade de Input Monitoring), OQ-02 (macOS 13 como mínimo) e OQ-03 (certificado de desenvolvimento). | 🟡 |

## 3. Personas e cenários de uso

| Persona | Objetivo | Cenário-chave |
|---------|----------|---------------|
| Programador de sofá (`_reversa_sdd/personas.md#Persona 1: Programador de sofá`) | Mover o cursor, clicar e rolar sem mouse ao revisar código e artefatos. | Do sofá, à noite, com o Mac ligado ou não à TV, leva o cursor até uma aba do VS Code com o analógico esquerdo, ajusta a posição no touchpad e clica com R2, várias vezes por sessão. |
| Programador de sofá, no papel de avaliador da PoC | Decidir com dados se as premissas 1 e 2 se sustentam. | Executa o protocolo de validação à mesa e no sofá, a cada rodada de calibração e ao fim da feature, ajustando os parâmetros no arquivo entre as rodadas, e registra os resultados no relatório. |
| Componentes futuros (`action-mapping`, `voice-dictation`, `app-shell`) | Reaproveitar a leitura do controle validada aqui. | Consomem as entradas normalizadas do controle nas features seguintes, sem refazer a leitura. |

## 4. Regras de negócio novas ou alteradas

1. **RN-01:** Existe no máximo um **controle ativo**, isto é, o controle cujas entradas produzem efeito: o primeiro DualSense conectado. Outros DualSense aguardam a desconexão do ativo; controles de outros modelos são ignorados. 🟡
   - Origem: `_reversa_sdd/sdd/controller-input.md#6.1 Requisitos Principais` (RF-08), `#11. Edge Cases e Tratamento de Erros` (EC-03)
   - Tipo: nova
2. **RN-02:** **Zona morta** é o limite abaixo do qual a leitura de um analógico conta como repouso: valores absolutos menores que 0,12 valem 0,0. 🟡
   - Origem: `_reversa_sdd/sdd/controller-input.md#6.1 Requisitos Principais` (RF-05), EC-02
   - Tipo: nova
3. **RN-03:** L2 e R2 contam como botão pressionado a partir de 0,5 do curso e como solto abaixo desse valor. 🟡
   - Origem: `_reversa_sdd/sdd/controller-input.md#6.1 Requisitos Principais` (RF-06)
   - Tipo: nova
4. **RN-04:** Nenhuma desconexão deixa entrada presa: antes de dar o controle por desconectado, o sistema trata como solto todo botão ainda pressionado e solta todo botão de mouse que ele próprio pressionou. 🟡
   - Origem: `_reversa_sdd/sdd/controller-input.md#11. Edge Cases e Tratamento de Erros` (EC-01), `_reversa_sdd/sdd/pointer-control.md#11. Edge Cases e Tratamento de Erros` (EC-02)
   - Tipo: nova
5. **RN-05:** O touchpad move o cursor de forma relativa ao deslocamento do dedo, como o trackpad de um notebook: pousar o dedo não move o cursor, e só o primeiro dedo em contato conta. 🟡
   - Origem: `_reversa_sdd/sdd/pointer-control.md#6.1 Requisitos Principais` (RF-01, RF-02), EC-03, `#15. Decisões Tomadas`
   - Tipo: nova
6. **RN-06:** Touchpad e analógico esquerdo atuam ao mesmo tempo, e seus deslocamentos se somam. 🟡
   - Origem: `_reversa_sdd/sdd/pointer-control.md#8. Design e Interface`, EC-04
   - Tipo: nova
7. **RN-07:** A velocidade do cursor pelo analógico esquerdo é proporcional à inclinação elevada ao expoente 2,0, até 1.500 pt/s (pontos de tela por segundo) na inclinação total. Esses valores e os de RN-02, RN-08 e RN-09 são padrões, ajustáveis pelo arquivo de parâmetros de RF-26. 🟡
   - Origem: `_reversa_sdd/sdd/pointer-control.md#6.1 Requisitos Principais` (RF-03), `#9. Modelo de Dados`
   - Tipo: nova
8. **RN-08:** Com L1 pressionado sem outro botão, as velocidades do analógico e do touchpad caem para 30%. L1 fica reservado como modificador do futuro `action-mapping`. 🟡
   - Origem: `_reversa_sdd/sdd/pointer-control.md#6.1 Requisitos Principais` (RF-09), `#15. Decisões Tomadas`
   - Tipo: nova
9. **RN-09:** Dois cliques esquerdos formam duplo clique quando ocorrem em até 400 ms e a no máximo 4 pt de distância. 🟡
   - Origem: `_reversa_sdd/sdd/pointer-control.md#6.1 Requisitos Principais` (RF-08)
   - Tipo: nova
10. **RN-10:** O cursor permanece dentro da união das telas conectadas, inclusive quando uma delas é desconectada. 🟡
    - Origem: `_reversa_sdd/sdd/pointer-control.md#6.1 Requisitos Principais` (RF-12), EC-05
    - Tipo: nova
11. **RN-11:** Nesta feature o mapeamento é fixo: analógico esquerdo move o cursor, analógico direito rola, R2 e clique do touchpad fazem clique esquerdo, R1 faz clique direito e L1 ativa a precisão. O mapeamento configurável chega com `action-mapping`. 🟡
    - Origem: `_reversa_sdd/sdd/action-mapping.md#8. Design e Interface`, `_reversa_sdd/sdd/pointer-control.md#6.1 Requisitos Principais` (RF-05, RF-06)
    - Tipo: nova
12. **RN-12:** O sistema não abre conexões de rede e não lê teclado nem mouse físicos. As entradas do controle só são gravadas no log de diagnóstico (RF-11) e nos resultados da tela de alvos (RF-27), ambos locais; nenhum dos dois contém coordenadas do cursor, posições do toque ou valores de eixo, e nada sai da máquina. 🟢
    - Origem: `_reversa_sdd/sdd/controller-input.md#12. Segurança e Privacidade`, `_reversa_sdd/sdd/pointer-control.md#12. Segurança e Privacidade`, `_reversa_sdd/sdd/app-shell.md#12. Segurança e Privacidade`; esclarecimento 7
    - Tipo: nova

## 5. Requisitos Funcionais

| ID | Requisito | Prioridade | Critério de aceite | Confidência |
|----|-----------|------------|--------------------|-------------|
| RF-01 | O sistema deve reconhecer a conexão de um DualSense por USB (Universal Serial Bus) e por Bluetooth, identificando nome, tipo de conexão e identificador da conexão. (controller-input RF-01) | Must | Conectar o controle por cabo e, depois, por Bluetooth registra uma conexão em cada caso, com o tipo correto, em até 2 s após o macOS reconhecê-lo. | 🟡 |
| RF-02 | O sistema deve reconhecer a desconexão do controle ativo por desligamento, remoção do cabo ou perda do Bluetooth. (controller-input RF-02) | Must | Desligar o controle segurando o botão PS registra a desconexão em até 2 s. | 🟡 |
| RF-03 | O sistema deve adotar como ativo, ao iniciar, um DualSense que já esteja conectado. (controller-input, Fluxo Alternativo A) | Must | Iniciar a PoC com o controle já ligado registra a conexão sem que o usuário desligue e religue o controle. | 🟡 |
| RF-04 | O sistema deve receber as entradas do controle com outro aplicativo em primeiro plano. (controller-input RF-03) | Must | Com o Terminal em primeiro plano, pressionar e soltar ✕ registra o pressionar e o soltar de `cross`. | 🟡 |
| RF-05 | O sistema deve reconhecer o pressionar e o soltar dos 18 identificadores: `cross`, `circle`, `square`, `triangle`, `l1`, `r1`, `l2`, `r2`, `l3`, `r3`, `options`, `create`, `ps`, `touchpadClick`, `dpadUp`, `dpadDown`, `dpadLeft`, `dpadRight`. (controller-input RF-04) | Must | Um teste manual guiado registra os dois eventos para cada um dos 18 identificadores. | 🟡 |
| RF-06 | O sistema deve ler os eixos X e Y de cada analógico normalizados de -1,0 a 1,0, aplicando RN-02. (controller-input RF-05, EC-02) | Must | Com o analógico em repouso, mesmo com desvio físico de 0,08, o cursor não se move; com inclinação total, o cursor atinge a velocidade máxima de RF-13. A leitura normalizada, inclusive o valor 0,0 em repouso e 1,0 no curso máximo, é verificada por testes automatizados da normalização, já que o log não registra valores de eixo (RN-12; esclarecimento 6). | 🟡 |
| RF-07 | O sistema deve ler L2 e R2 de 0,0 a 1,0, aplicando RN-03. (controller-input RF-06) | Must | Pressionar R2 até a metade registra `r2` pressionado; soltar abaixo de 0,5 registra `r2` solto. | 🟡 |
| RF-08 | O sistema deve ler a posição normalizada, de -1,0 a 1,0 nos dois eixos, e o estado de toque de até dois dedos no touchpad. (controller-input RF-07) | Must | Pousar um dedo registra no log o início do toque daquele dedo e retirá-lo registra o fim, sem posições; deslizá-lo da esquerda para a direita move o cursor para a direita (RF-12). A posição normalizada é verificada por testes automatizados, já que o log não registra posições do toque (RN-12; esclarecimento 6). | 🟡 |
| RF-09 | O sistema deve aplicar RN-01, inclusive em reconexões rápidas. (controller-input RF-08, EC-03, EC-05) | Must | Com dois DualSense ligados, só o primeiro move o cursor e, desconectado este, o segundo assume; uma queda de Bluetooth de menos de 1 s registra desconexão e nova conexão, nessa ordem, sem dois controles ativos. | 🟡 |
| RF-10 | O sistema deve aplicar RN-04 em toda desconexão. (controller-input EC-01, pointer-control EC-02) | Must | Desligar o controle durante um arraste com R2 segurado deixa o botão esquerdo do mouse solto: mover o mouse físico em seguida não estende a seleção. | 🟡 |
| RF-11 | O sistema deve manter um log de diagnóstico com conexões, desconexões e erros e, com a depuração ligada, com cada pressionar e soltar de botão, sempre com carimbo de tempo monotônico na chegada da entrada e na entrega do movimento ao sistema, sem coordenadas do cursor. (controller-input RNF-01, §12, §13; pointer-control §12) | Must | O log de uma sessão de 60 s permite calcular o percentil 95 (p95) das duas latências e não contém coordenadas do cursor. | 🟡 |
| RF-12 | O sistema deve mover o cursor pelo touchpad conforme RN-05. (pointer-control RF-01, RF-02, EC-03) | Must | Deslizar o dedo para a direita move o cursor para a direita; pousar o dedo em qualquer ponto não altera a posição; deslizar um segundo dedo não move o cursor. | 🟡 |
| RF-13 | O sistema deve mover o cursor continuamente com o analógico esquerdo conforme RN-07. (pointer-control RF-03, G-02) | Must | Inclinação de 30% move o cursor a menos de 10% da velocidade máxima; inclinação total atravessa 1.920 pt de largura em até 1,5 s. | 🟡 |
| RF-14 | O sistema deve rolar o conteúdo sob o cursor com o analógico direito, nos eixos vertical e horizontal, com velocidade proporcional à inclinação. (pointer-control RF-04, G-03) | Must | Inclinar para baixo rola para baixo o arquivo aberto no VS Code e inclinar para a direita rola na horizontal; um arquivo de 1.000 linhas é percorrido do início ao fim em até 10 s. | 🟡 |
| RF-15 | O sistema deve fazer clique esquerdo com R2 e com o clique do touchpad, pressionando o botão esquerdo do mouse ao pressionar e soltando-o ao soltar, na posição do cursor. (pointer-control RF-05, RN-11) | Must | Pressionar e soltar R2 sobre uma aba do VS Code a seleciona; o clique do touchpad produz o mesmo efeito. | 🟡 |
| RF-16 | O sistema deve fazer clique direito com R1. (pointer-control RF-06, RN-11) | Must | Pressionar R1 sobre um arquivo no explorador do VS Code abre o menu de contexto. | 🟡 |
| RF-17 | O sistema deve permitir arrastar: com o clique esquerdo mantido, movimentos do touchpad ou do analógico esquerdo arrastam. (pointer-control RF-07) | Must | Segurar R2 e mover o analógico seleciona um trecho de texto no editor; segurar R2 e deslizar no touchpad produz o mesmo efeito. | 🟡 |
| RF-18 | O sistema deve reconhecer duplo clique conforme RN-09. (pointer-control RF-08) | Must | Dois cliques de R2 com intervalo inferior a 400 ms sobre uma palavra no editor a selecionam. | 🟡 |
| RF-19 | O sistema deve aplicar a precisão de RN-08. (pointer-control RF-09) | Should | Com L1 segurado, a mesma inclinação do analógico desloca o cursor a 30% da distância obtida sem L1, com tolerância de 5%. | 🟡 |
| RF-20 | O sistema deve somar os deslocamentos do touchpad e do analógico esquerdo conforme RN-06. (pointer-control EC-04) | Must | Com o analógico inclinado para a direita, deslizar o dedo para a direita acelera o cursor e deslizá-lo para a esquerda o desacelera. | 🟡 |
| RF-21 | O sistema deve manter o cursor dentro da união das telas conectadas conforme RN-10. (pointer-control RF-12, EC-05) | Must | Com Mac e TV lado a lado, o cursor passa de uma tela à outra e para na borda externa; desligar a TV com o cursor sobre ela reposiciona o cursor na tela restante. | 🟡 |
| RF-22 | O sistema deve, sem a permissão de Acessibilidade ou quando ela for revogada durante o uso, deixar de injetar eventos, registrar no log a orientação para concedê-la e seguir em execução. (pointer-control EC-01) | Must | Remover a PoC da lista de Acessibilidade com ela aberta interrompe o movimento do cursor, gera no log a orientação de concessão e o processo continua em execução. | 🟡 |
| RF-23 | O sistema deve, ao ser encerrado por meio normal do macOS, soltar todo botão de mouse que tenha pressionado. (app-shell RF-09, parcial; pointer-control EC-06) | Must | Encerrar a PoC com R2 segurado não deixa o botão esquerdo do mouse preso. | 🟡 |
| RF-24 | O sistema deve pedir ao macOS, enquanto estiver em execução, que o botão PS não acione gestos do sistema, e registrar no log, em nível informativo, o pedido e a instrução de verificação visual; como o macOS não informa se acatou o pedido, o sistema segue funcionando em qualquer caso. (controller-input RF-09, EC-06; esclarecimento 10) | Should | O log de cada sessão contém o registro do pedido de supressão; no teste manual, pressionar PS não abre o Launchpad nem a sobreposição de jogos, ou, se abrir, o avaliador anota o fato no bloco (f) do relatório e as demais funções seguem operando. | 🟢 |
| RF-25 | O sistema deve ser acompanhado de um relatório de validação, gravado na pasta da feature, que registre: (a) elementos do controle lidos em segundo plano, com alvo de 18 de 18; (b) taxa de acerto em alvos de 16 × 16 pt em 20 tentativas na tela de alvos (RF-27), com alvo de pelo menos 90%, apurada em separado à mesa (monitor a cerca de 60 cm) e no sofá (TV a cerca de 2 m), com a resolução e a escala de cada tela, uma linha por rodada de calibração com os parâmetros vigentes e a medição com e sem L1; (c) confirmação no uso real, no sofá, com 20 alvos pequenos do VS Code (por exemplo, fechar aba, ícones da barra de atividades, setas do explorador, margem de breakpoint), anotados como acerto ou erro no primeiro clique; (d) p95 do processamento da entrada, com alvo de até 5 ms, e da entrada ao movimento do cursor, com alvo de até 20 ms; (e) método de assinatura adotado e se as permissões sobreviveram a uma recompilação; (f) respostas às questões abertas herdadas listadas na seção 10; (g) veredito de cada premissa: sustentada, sustentada com ajustes ou refutada, sendo o da premissa 1 baseado nos resultados do sofá. (controller-input §3, §13, §14; pointer-control §3, §13, §14; ideation, premissas 1 e 2; esclarecimentos 2, 3 e 5) | Must | O relatório existe na pasta da feature, contém os sete blocos com valores medidos, e não estimados, e cada veredito cita as medições que o sustentam. | 🟢 |
| RF-26 | O sistema deve ler, ao iniciar, os parâmetros do ponteiro da seção `pointer` de `~/.config/joystick-ai/config.json`, com os mesmos nomes e padrões de `PointerSettings` (`_reversa_sdd/sdd/pointer-control.md#9. Modelo de Dados`), ignorando as demais seções. Arquivo ausente ou campo ausente assume o padrão, sem criar o arquivo; JSON (JavaScript Object Notation) inválido faz a PoC operar com os padrões e registrar no log o erro com o número da linha; valor de tipo errado ou fora da faixa permitida é substituído pelo padrão com aviso no log. As faixas são: `touchpadSensitivity` de 0,1 a 5,0; `stickMaxSpeed` de 150 a 7.500 pt/s; `stickExponent` de 0,5 a 4,0; `deadzone` de 0,0 a 0,5; `scrollSpeed` de 1 a 1.000 linhas/s; `precisionFactor` de 0,05 a 1,0; `doubleClickIntervalMs` de 100 a 2.000 ms. A mudança vale ao reabrir a PoC, sem recompilar. (pointer-control RF-10, RNF-04; esclarecimentos 1 e 8) | Must | Mudar `stickMaxSpeed` de 1500 para 1800, salvar e reabrir a PoC altera a velocidade do cursor sem recompilar; com o arquivo ausente, a PoC opera com os padrões e o arquivo continua inexistente. | 🟢 |
| RF-27 | O sistema deve oferecer uma tela de alvos, aberta sem recompilar, que apresenta em sequência 20 alvos de 16 × 16 pt em posições sorteadas na tela escolhida e registra, para cada alvo, se o primeiro clique acertou, o tempo até o clique e se L1 estava pressionado. Ao fim, grava um resultado com taxa de acerto, tempo médio, parâmetros vigentes, rótulo do ambiente (mesa ou sofá) informado ao abrir, resolução e escala da tela. Uma sequência interrompida é gravada como incompleta e fica fora do cálculo. (pointer-control G-01, §13; esclarecimentos 2 e 5) | Must | Completar as 20 tentativas grava um resultado com 20 registros e todos os campos listados; interromper na décima tentativa grava um resultado marcado como incompleto. | 🟢 |

## 6. Requisitos Não Funcionais

| Tipo | Requisito | Evidência ou justificativa | Confidência |
|------|-----------|----------------------------|-------------|
| Desempenho | p95 de até 5 ms entre a chegada da entrada do controle e sua entrega normalizada. | `_reversa_sdd/sdd/controller-input.md#7. Requisitos Não-Funcionais` (RNF-01) | 🟡 |
| Desempenho | p95 de até 20 ms entre a entrada do controle e o movimento correspondente do cursor. | `_reversa_sdd/sdd/pointer-control.md#7. Requisitos Não-Funcionais` (RNF-01) | 🟡 |
| Suavidade | Cursor atualizado 120 vezes por segundo enquanto o analógico esquerdo estiver fora da zona morta, sem atualizações periódicas com o analógico em repouso. | `_reversa_sdd/sdd/pointer-control.md#7. Requisitos Não-Funcionais` (RNF-02) | 🟡 |
| Consumo | Processo com até 2% de um núcleo com o controle parado e até 5% em movimento contínuo, medidos por 60 s. | `controller-input` RNF-02 fixa 2% para a leitura e `pointer-control` RNF-03 fixa 1% parado e 5% em movimento; como a PoC é um processo único, adota-se 2% para o conjunto parado. | 🟡 |
| Robustez | Zero travamentos em 100 ciclos de conectar e desconectar o controle. | `_reversa_sdd/sdd/controller-input.md#7. Requisitos Não-Funcionais` (RNF-04) | 🟡 |
| Compatibilidade | macOS 13 ou superior. | `controller-input` RNF-03 e `app-shell` OQ-02; piso provisório, de impacto baixo. | 🟡 |
| Segurança | Operar só com as permissões concedidas pelo usuário em Ajustes do Sistema, sem contorná-las. | `_reversa_sdd/sdd/app-shell.md#12. Segurança e Privacidade` | 🟡 |
| Privacidade | Cumprir RN-12. | `controller-input` §12, `pointer-control` §12, `app-shell` §12 | 🟡 |
| Observabilidade | Log de diagnóstico conforme RF-11, suficiente para medir as latências do relatório. | `_reversa_sdd/sdd/controller-input.md#13. Plano de Rollout` | 🟡 |
| Acessibilidade | Sensibilidade do touchpad e velocidade do analógico ajustáveis entre 0,1× e 5× do padrão, pelo arquivo de parâmetros de RF-26. | `_reversa_sdd/sdd/pointer-control.md#7. Requisitos Não-Funcionais` (RNF-04); esclarecimento 1 | 🟢 |
| Empacotamento | A PoC é um app macOS empacotado que roda como agente: sem ícone no Dock e sem janela além da tela de alvos, com log em `~/Library/Logs/joystick-ai/` e com as permissões concedidas em nome do próprio app, nunca do terminal que o inicia. | Validar a premissa 2 nas condições do produto final e evitar estender a outros programas do terminal a capacidade de injetar eventos; esclarecimento 4; `_reversa_sdd/sdd/app-shell.md#6.1 Requisitos Principais` (RF-01, RF-12) | 🟢 |
| Operação | As permissões concedidas sobrevivem às recompilações. A estabilidade da assinatura é verificada antes de qualquer rodada de calibração: primeiro com o certificado de desenvolvimento da conta Apple gratuita; se as permissões se perderem numa recompilação, com um certificado autoassinado de uso local. A verificação inicial cobre a Acessibilidade; se o teste de leitura em segundo plano concluir que Input Monitoring é necessário, a mesma verificação se repete para ele antes de qualquer teste de apontamento. | `_reversa_sdd/sdd/app-shell.md#7. Requisitos Não-Funcionais` (RNF-05), EC-01, OQ-03; esclarecimentos 3 e 9 | 🟢 |

## 7. Critérios de Aceitação

```gherkin
# Cobre: RF-01
Cenário: Conexão por cabo e por Bluetooth
  Dado a PoC em execução e nenhum controle conectado
  Quando o usuário conecta o DualSense por USB e, depois de desconectá-lo, o liga por Bluetooth
  Então o log registra duas conexões, uma do tipo USB e outra do tipo Bluetooth, cada uma em até 2 s

# Cobre: RF-02
Cenário: Desligamento do controle
  Dado um DualSense ativo
  Quando o usuário desliga o controle segurando o botão PS
  Então o log registra a desconexão em até 2 s e não resta controle ativo

# Cobre: RF-03
Cenário: Controle ligado antes da PoC
  Dado um DualSense já conectado ao Mac
  Quando o usuário inicia a PoC
  Então o controle passa a ser o ativo sem ser desligado e religado

# Cobre: RF-04, RF-05
Cenário: Todos os botões com outro aplicativo em foco
  Dado um DualSense ativo e o Terminal em primeiro plano
  Quando o usuário pressiona e solta, um a um, os 18 botões do roteiro guiado
  Então o log registra o pressionar e o soltar de cada um dos 18 identificadores

# Cobre: RF-06
Cenário: Analógico em repouso e no curso máximo
  Dado um DualSense ativo
  Quando o usuário leva o analógico esquerdo ao curso máximo e depois o solta
  Então o cursor atinge a velocidade máxima configurada durante a inclinação total e, em repouso, não se move

# Cobre: RF-06
Cenário: Analógico com desvio físico em repouso
  Dado um analógico que, parado, reporta 0,08
  Quando nenhum dedo toca o analógico
  Então o sistema trata a leitura como 0,0 e o cursor não se move

# Cobre: RF-07
Cenário: Gatilho tratado como botão
  Dado um DualSense ativo
  Quando o usuário pressiona R2 até a metade do curso e depois o solta
  Então o log registra `r2` pressionado ao atingir 0,5 e `r2` solto abaixo de 0,5

# Cobre: RF-08, RF-12
Cenário: Segundo dedo no touchpad
  Dado um dedo deslizando no touchpad e movendo o cursor
  Quando o usuário pousa e desliza um segundo dedo
  Então o log registra os dois toques e o cursor continua seguindo apenas o primeiro dedo

# Cobre: RF-09
Cenário: Dois DualSense conectados
  Dado dois DualSense ligados, o primeiro conectado antes do segundo
  Quando o usuário move o analógico de cada um e depois desliga o primeiro
  Então só o primeiro move o cursor enquanto conectado e, após desligá-lo, o segundo passa a mover o cursor

# Cobre: RF-09
Cenário: Controle de outro modelo
  Dado um DualSense ativo
  Quando o usuário conecta um controle de outro modelo
  Então o outro controle é ignorado, o log registra a ocorrência e o controle ativo não muda

# Cobre: RF-09
Cenário: Queda breve do Bluetooth
  Dado um DualSense ativo por Bluetooth
  Quando a conexão cai e volta em menos de 1 s
  Então o log registra a desconexão e a nova conexão, nessa ordem, e há um único controle ativo

# Cobre: RF-10, RF-17
Cenário: Controle desliga no meio de um arraste
  Dado o usuário segurando R2 e arrastando para selecionar texto
  Quando o controle perde a conexão
  Então o botão esquerdo do mouse é solto antes do registro da desconexão e mover o mouse físico não estende a seleção

# Cobre: RF-11
Cenário: Log de diagnóstico mensurável e sem coordenadas
  Dado a depuração ligada e uma sessão de 60 s de uso
  Quando o avaliador analisa o log
  Então consegue calcular o p95 das duas latências e não encontra coordenadas do cursor

# Cobre: RF-12
Cenário: Pousar o dedo não move o cursor
  Dado o cursor parado no centro da tela
  Quando o usuário pousa o dedo num canto do touchpad sem deslizá-lo
  Então o cursor permanece na mesma posição

# Cobre: RF-13
Cenário: Atravessar a tela com o analógico
  Dado uma tela de 1.920 pt de largura e o cursor na borda esquerda
  Quando o usuário inclina totalmente o analógico esquerdo para a direita
  Então o cursor chega à borda direita em até 1,5 s

# Cobre: RF-14
Cenário: Rolar um arquivo longo
  Dado um arquivo de 1.000 linhas aberto no VS Code, com o cursor sobre o editor
  Quando o usuário inclina totalmente o analógico direito para baixo
  Então o editor chega ao fim do arquivo em até 10 s

# Cobre: RF-15, RF-16, RF-18
Cenário: Clique esquerdo, clique direito e duplo clique
  Dado o cursor sobre uma aba, depois sobre um arquivo do explorador e depois sobre uma palavra no editor do VS Code
  Quando o usuário clica com R2 na aba, pressiona R1 no arquivo e dá dois cliques rápidos de R2 na palavra
  Então a aba é selecionada, o menu de contexto do arquivo abre e a palavra fica selecionada

# Cobre: RF-15
Cenário: Clique pelo touchpad
  Dado o cursor sobre uma aba do VS Code
  Quando o usuário pressiona e solta o clique do touchpad
  Então a aba é selecionada

# Cobre: RF-17
Cenário: Arrastar para selecionar texto
  Dado o cursor no início de um trecho de texto no editor
  Quando o usuário segura R2, move o analógico esquerdo até o fim do trecho e solta R2
  Então o trecho fica selecionado

# Cobre: RF-19
Cenário: Precisão com L1
  Dado uma inclinação fixa do analógico esquerdo que desloca o cursor por uma distância D em 1 s
  Quando o usuário repete a mesma inclinação por 1 s segurando L1
  Então o cursor se desloca entre 25% e 35% de D

# Cobre: RF-20
Cenário: Touchpad e analógico ao mesmo tempo
  Dado o analógico esquerdo inclinado para a direita, movendo o cursor
  Quando o usuário desliza o dedo no touchpad para a direita e depois para a esquerda
  Então o cursor acelera no primeiro movimento e desacelera no segundo

# Cobre: RF-21
Cenário: Duas telas e desligamento da TV
  Dado o Mac e a TV configurados lado a lado, com o cursor sobre a TV
  Quando o usuário leva o cursor à borda externa da TV e, em seguida, desliga a TV
  Então o cursor para na borda externa e, com a TV desligada, reaparece na tela do Mac

# Cobre: RF-22
Cenário: Permissão de Acessibilidade revogada durante o uso
  Dado a PoC movendo o cursor com a permissão de Acessibilidade concedida
  Quando o usuário remove a PoC da lista de Acessibilidade em Ajustes do Sistema
  Então o cursor deixa de responder ao controle, o log orienta a concessão e o processo continua em execução

# Cobre: RF-23
Cenário: Encerrar a PoC com o clique mantido
  Dado o usuário segurando R2 sobre o editor
  Quando a PoC é encerrada por meio normal do macOS
  Então o botão esquerdo do mouse fica solto

# Cobre: RF-24
Cenário: Pedido de supressão registrado
  Dado um DualSense conectado
  Quando a PoC inicia
  Então o log registra, em nível informativo, o pedido de supressão de gestos e a instrução de verificação visual

# Cobre: RF-24
Cenário: Botão PS com a PoC em execução
  Dado a PoC em execução numa versão do macOS que acata o pedido de supressão
  Quando o usuário pressiona PS
  Então nem o Launchpad nem a sobreposição de jogos abrem

# Cobre: RF-24
Cenário: Botão PS numa versão que ignora a supressão
  Dado a PoC em execução numa versão do macOS que ignora o pedido de supressão
  Quando o usuário pressiona PS e o Launchpad ou a sobreposição de jogos abre
  Então as demais funções seguem operando e o avaliador anota o fato no bloco (f) do relatório

# Cobre: RF-25
Cenário: Relatório de validação completo
  Dado o protocolo de validação executado à mesa e no sofá, e a confirmação no VS Code feita no sofá
  Quando o avaliador fecha a feature
  Então a pasta da feature contém o relatório com os sete blocos medidos, os resultados de mesa e sofá em separado e um veredito fundamentado para cada premissa

# Cobre: RF-25
Cenário: Diagnóstico por ambiente
  Dado taxa de acerto de 95% à mesa e de 70% no sofá com os mesmos parâmetros
  Quando o avaliador redige o veredito da premissa 1
  Então o veredito se baseia no resultado do sofá e o relatório aponta a distância ou a escala da tela como causa provável, com a resolução e a escala registradas

# Cobre: RF-26
Cenário: Ajuste de parâmetro sem recompilar
  Dado a PoC em execução com `stickMaxSpeed` igual a 1500 no arquivo
  Quando o avaliador muda o valor para 1800, salva o arquivo e reabre a PoC
  Então a inclinação total do analógico passa a mover o cursor a 1.800 pt/s, sem recompilação

# Cobre: RF-26
Cenário: Arquivo de parâmetros ausente
  Dado que `~/.config/joystick-ai/config.json` não existe
  Quando a PoC inicia
  Então opera com os padrões de `PointerSettings` e o arquivo continua inexistente

# Cobre: RF-26
Cenário: Arquivo de parâmetros inválido ou fora da faixa
  Dado um arquivo com vírgula faltando na linha 4, ou com `touchpadSensitivity` igual a 9,0
  Quando a PoC inicia
  Então opera com os padrões para os valores afetados e o log registra o erro com a linha, ou o valor rejeitado e a faixa permitida

# Cobre: RF-27
Cenário: Sequência completa na tela de alvos
  Dado a tela de alvos aberta com o rótulo "sofá" na TV
  Quando o avaliador tenta clicar nos 20 alvos de 16 × 16 pt
  Então é gravado um resultado com 20 registros, taxa de acerto, tempo médio, parâmetros vigentes, rótulo, resolução e escala

# Cobre: RF-27
Cenário: Sequência interrompida
  Dado a tela de alvos aberta
  Quando o avaliador encerra a sequência na décima tentativa
  Então o resultado é gravado como incompleto e não entra no cálculo do relatório

# Cobre: RNF de operação
Cenário: Acessibilidade sobrevive a uma recompilação
  Dado a PoC assinada pelo método escolhido e com Acessibilidade concedida
  Quando o app é recompilado e reaberto
  Então o log registra a permissão de injeção ativa sem nova concessão em Ajustes do Sistema

# Cobre: RNF de operação
Cenário: Input Monitoring sobrevive a uma recompilação, se necessário
  Dado que o teste de leitura em segundo plano concluiu que Input Monitoring é necessário e a permissão foi concedida
  Quando o app é recompilado e reaberto, antes de qualquer teste de apontamento
  Então as entradas do controle continuam chegando com outro aplicativo em primeiro plano, sem nova concessão

# Cobre: RF-25
Cenário: Premissa refutada
  Dado uma taxa de acerto em alvos de 16 × 16 pt inferior a 90% após a calibração
  Quando o avaliador redige o relatório
  Então a premissa 1 recebe veredito "refutada" ou "sustentada com ajustes", com as medições e o ajuste proposto
```

## 8. Prioridade MoSCoW

| Item | MoSCoW | Justificativa |
|------|--------|---------------|
| RF-01 a RF-11 | Must | Leitura confiável do controle em segundo plano é a premissa 2 e a base de todos os componentes futuros. |
| RF-12 a RF-18, RF-20, RF-21 | Must | Mover, rolar, clicar e arrastar compõem a premissa 1 e o escopo "controle como mouse" do PRD. |
| RF-22, RF-23 | Must | Sem eles, uma falha deixa botão de mouse preso ou o processo travado, o que inviabiliza a avaliação. |
| RF-25 | Must | O relatório é o produto da PoC: sem ele, a decisão sobre o MVP volta a ser palpite. |
| RF-26 | Must | Sem ele, cada rodada de calibração exige recompilar, o que torna a calibração lenta demais para ser feita. |
| RF-27 | Must | É o instrumento que torna a taxa de acerto reprodutível e comparável entre rodadas e ambientes. |
| RNF de empacotamento e de operação | Must | Sem app empacotado e assinatura estável, a premissa 2 não é validada nas condições do produto e a calibração perde as permissões a cada build. |
| RF-19 | Should | Melhora a precisão, mas o teste de acerto pode ser feito sem ela; a medição com e sem L1 é informativa. |
| RF-24 | Should | Evita o Launchpad abrindo por acidente; depende de o macOS permitir. |
| RNF de desempenho | Must (medição) | Os valores entram no relatório; não atingir o alvo não bloqueia a entrega, mas pesa no veredito. |
| RNF de acessibilidade (faixa de 0,1× a 5×) | Should | Motivação declarada, não público prioritário do MVP; sai quase sem custo da validação de faixa de RF-26. |
| Nível de bateria (controller-input RF-10) | Won't | Só teria onde aparecer no menu do `app-shell`, fora desta feature. |
| Vibração e barra de luz (controller-input RF-11) | Won't | Consumidas por `action-mapping` e `voice-dictation`, fora desta feature. |
| Recarga automática de parâmetros ao salvar (pointer-control RF-10) | Won't | A PoC lê o arquivo só ao iniciar (RF-26); vigiar o arquivo e tratar erro sem perder a configuração anterior pertence a `action-mapping` (RF-03, RF-04). |
| Criação do arquivo de configuração com conteúdo padrão (action-mapping RF-02) | Won't | A PoC só lê o arquivo; criá-lo com os mapeamentos padrão é responsabilidade de `action-mapping`. |
| Modo de condução (pointer-control RF-11, app-shell RF-06) | Won't | Durante a PoC, o mouse físico continua disponível e encerrar o processo libera o cursor. |
| Janela de permissões e barra de menus (`app-shell`) | Won't | Recorte do usuário: permissões concedidas manualmente. |
| Mapeamento configurável e atalhos de fluxo (`action-mapping`) | Won't | Entregue após a PoC, conforme o rollout da spec. |
| Ditado (`voice-dictation`) | Won't | Depende do teste manual de microfone, independente desta feature. |
| Leitura do botão de mudo por acesso de baixo nível (controller-input NG-04) | Won't | A PoC apenas responde se o botão é exposto (OQ-01). |

## 9. Esclarecimentos

### Sessão 2026-09-14

- **Q:** Como os parâmetros do ponteiro (sensibilidade do touchpad, velocidade máxima, expoente, velocidade de rolagem, fator de precisão) serão ajustados durante a calibração?
  **R:** Arquivo mínimo com a seção `pointer`, no formato do futuro `~/.config/joystick-ai/config.json`, lido ao iniciar a PoC; a mudança vale ao reabrir, sem recompilar. Integrado em RF-26, RN-07, no RNF de acessibilidade e na seção 8.
- **Q:** Como será medida a taxa de acerto em alvos de 16 × 16 pt?
  **R:** Tela de alvos própria da PoC para calibrar e comparar rodadas, com confirmação final em alvos reais do VS Code. Integrado em RF-25 e RF-27.
- **Q:** Há conta Apple com certificado de desenvolvimento para assinar a PoC de forma estável?
  **R:** Verificar como primeira ação do plano: testar o certificado da conta Apple gratuita e, se as permissões não sobreviverem a uma recompilação, usar certificado autoassinado de uso local. Integrado no RNF de operação e em RF-25. Orientação ao `/reversa-plan`: essa verificação precede qualquer rodada de calibração.
- **Q:** Em que formato a PoC é executada?
  **R:** App macOS empacotado, rodando como agente, sem ícone no Dock e sem janela além da tela de alvos, com permissões em nome do próprio app. Integrado no RNF de empacotamento.
- **Q:** Em que ambiente o protocolo de validação deve ser executado?
  **R:** À mesa e no sofá, com resultados separados e registro de resolução e escala; o veredito da premissa 1 se baseia no sofá. Integrado em RF-25, RF-27 e na seção 3.

Perguntas 6 a 10, levantadas pelo `/reversa-audit` (`audit/cross-check.md`, achados A001, A005 a A008):

- **Q:** O log não pode conter valores de eixo nem posições do toque. Como comprovar RF-06 (analógico chega a 1,0 no curso máximo) e RF-08 (X do toque crescente)?
  **R:** Pelo efeito observável: RF-06 pela velocidade máxima de RF-13 e pelo cursor parado em repouso; RF-08 pelo início e fim do toque no log e pelo cursor seguindo o dedo. Os valores normalizados são verificados por testes automatizados. Integrado nos critérios de RF-06 e RF-08 e no cenário "Analógico em repouso e no curso máximo".
- **Q:** RN-12 diz que as entradas do controle não são gravadas, mas RF-11 exige gravar botões com a depuração ligada e a tela de alvos grava o estado de L1. Qual regra prevalece?
  **R:** As entradas só ficam no log de diagnóstico e nos resultados da tela de alvos, ambos locais, sem coordenadas do cursor, posições do toque nem valores de eixo, e nada sai da máquina. Integrado em RN-12.
- **Q:** RF-26 só fixa faixas para `touchpadSensitivity` e `stickMaxSpeed`. E os demais campos numéricos?
  **R:** Adotar as faixas propostas no `data-delta.md`: `stickExponent` de 0,5 a 4,0; `deadzone` de 0,0 a 0,5; `scrollSpeed` de 1 a 1.000; `precisionFactor` de 0,05 a 1,0; `doubleClickIntervalMs` de 100 a 2.000. Integrado em RF-26.
- **Q:** O cenário de recompilação cita Acessibilidade e Input Monitoring, mas a verificação inicial não concede Input Monitoring. O que deve ser verificado?
  **R:** Só a Acessibilidade na verificação inicial; se o teste de leitura em segundo plano concluir que Input Monitoring é necessário, repetir a verificação para ele antes de qualquer teste de apontamento. Integrado no RNF de operação e nos dois cenários de recompilação.
- **Q:** O macOS não informa se aceitou suprimir os gestos do botão PS. Como fica RF-24?
  **R:** Registrar sempre o pedido de supressão, em nível informativo, com a instrução de verificação visual; o aceite passa a ser o teste manual do PS, anotado no bloco (f). Integrado em RF-24 e nos três cenários de RF-24.

## 10. Lacunas

- 🟡 **Questões abertas herdadas que a própria PoC responde**, sem bloquear o plano: `controller-input` OQ-01 (botão de mudo exposto?), `controller-input` OQ-03 e `app-shell` OQ-01 (Input Monitoring é necessário para receber entradas em segundo plano?), `app-shell` OQ-03 (certificado disponível, agora verificado como primeira ação), `pointer-control` OQ-01 (padrões adequados a uma TV a 2 m; resposta preliminar, obtida no ambiente sofá e a confirmar na primeira semana de uso) e `pointer-control` OQ-02 (rolagem em pixels ou em linhas).
- 🟡 **Versão mínima do macOS.** O piso de macOS 13 é provisório (`controller-input` OQ-02, `app-shell` OQ-02); impacto baixo, já que a máquina de uso tem versão mais recente.
- 🟡 **Inconsistência entre specs.** A velocidade de rolagem padrão de 40 linhas por segundo (`_reversa_sdd/sdd/pointer-control.md#9. Modelo de Dados`) não atinge a meta G-03, que exige cerca de 100 linhas por segundo para percorrer 1.000 linhas em 10 s. Esta feature adota G-03 como critério (RF-14) e trata o padrão como ponto de partida da calibração; o valor final deve voltar à spec pelo `/reversa-sync`.
- 🟡 **Teste de alternativa existente.** O PRD recomenda testar um mapeador de controle acionando o atalho do Raycast "antes de investir além da prova de conceito" (`_reversa_sdd/prd.md#8. Riscos`). Está fora desta feature, mas convém realizá-lo antes de abrir a próxima.

## 11. Histórico de alterações

| Data | Alteração | Autor |
|------|-----------|-------|
| 2026-09-14 | Versão inicial gerada por `/reversa-requirements`, com recorte controller-input + pointer-control escolhido pelo usuário | reversa |
| 2026-09-14 | Sessão de esclarecimentos: três dúvidas resolvidas e duas lacunas fechadas (formato de execução e ambiente de teste); acrescentados RF-26, RF-27 e o RNF de empacotamento; RF-25 ampliado para sete blocos | reversa |
| 2026-09-14 | Segunda rodada de esclarecimentos, a partir do `/reversa-audit`: RN-12 redefinida; critérios de RF-06 e RF-08 reescritos por efeito observável; faixas de todos os campos numéricos em RF-26; RF-24 com registro incondicional do pedido; RNF de operação e cenário de recompilação separados por permissão | reversa |

## Pendências de Qualidade

- **Q-018 (produto comercial no documento), exceção assumida.** DualSense, macOS, VS Code, Terminal e Raycast aparecem porque são o domínio do problema e os ambientes de teste definidos no PRD, não escolhas de solução. Frameworks e APIs de implementação foram deliberadamente omitidos e ficam para o `/reversa-plan`.
- **Q-017 (o quê, não o como), exceção assumida.** O formato de app agente, o arquivo JSON com a seção `pointer` e o método de assinatura descrevem como a PoC é construída, mas entraram como restrições decididas pelo usuário na sessão de esclarecimentos, e não como escolha do redator.
- **Q-011 e Q-019, não aplicáveis.** Não existem `_reversa_sdd/domain.md` nem `.reversa/principles.md`; as regras citam as specs SDD como origem.
