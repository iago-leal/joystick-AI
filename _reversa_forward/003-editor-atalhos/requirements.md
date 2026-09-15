# Requirements: Editor de atalhos e comandos

> Identificador: `003-editor-atalhos`
> Data: `2026-09-14`
> Pasta da extração reversa: `_reversa_sdd/`
> Confidência: 🟢 CONFIRMADO, 🟡 INFERIDO ou PLANEJADO, 🔴 LACUNA / DÚVIDA

> **Nota de confidência:** as specs em `_reversa_sdd/sdd/` nasceram do `/reversa-new` com selo 🟡 PLANEJADO. Recebem 🟢 os fatos entregues pelas features 001 e 002, registrados nos adendos vigentes, e as decisões do usuário tomadas na sessão de esclarecimentos da feature 002 e preservadas em [`backlog-editor.md`](../002-paleta-comandos/backlog-editor.md). As regras que esse backlog apenas propunha, sem confirmação do usuário, entram aqui como 🟡.

## 1. Resumo executivo

A feature entrega uma interface gráfica para o programador de sofá personalizar o que cada botão do DualSense faz e quais comandos a paleta oferece, sem editar código nem arquivo à mão. Hoje os atalhos e os 17 itens da paleta estão fixos no código, e a única seção lida do arquivo de configuração é a do ponteiro. Com a entrega, atalhos e paleta passam a viver no arquivo de configuração, editável pela nova janela ou por qualquer editor de texto, com aplicação imediata e sem reiniciar o app. O editor é aberto por um ícone na barra de menus ou por um item fixo no fim da paleta.

## 2. Contexto a partir do legado

Não existem `architecture.md`, `domain.md`, `inventory.md`, `code-analysis.md` nem `.reversa/principles.md`. O contexto vem das specs do `/reversa-new`, dos adendos vigentes das features 001 e 002, que corrigem a leitura das specs para o que foi entregue, e do backlog preservado pela feature 002. A leitura do código confirmou os fatos marcados com 🟢.

| Fonte | Trecho relevante | Confidência |
|-------|------------------|-------------|
| `_reversa_sdd/addenda/001-poc-entrada-ponteiro.md#Impacto por artefato da extração` | O protótipo de atalhos tem mapeamento fixo no código: setas, Enter, Esc, Backspace, Tab, L1+✕ `CONTINUAR`, L1+△ Shift+Tab, Create para Mission Control, L2 como camada de mesas e janelas, Options segurando Command e R3 com Command+M. | 🟢 |
| `_reversa_sdd/addenda/001-poc-entrada-ponteiro.md#Impacto por artefato da extração` | O app lê só a seção `pointer` de `~/.config/joystick-ai/config.json`, uma vez ao iniciar, e nunca cria o arquivo; os atalhos de sistema vêm das preferências do macOS, e não do arquivo. | 🟢 |
| `_reversa_sdd/addenda/001-poc-entrada-ponteiro.md#Impacto por artefato da extração` | R1 e o clique do touchpad fazem o clique esquerdo, R2 o direito, e L1 reduz a velocidade do cursor. O log não registra coordenadas nem teclas. | 🟢 |
| `_reversa_sdd/addenda/002-paleta-comandos.md#Impacto por artefato da extração` | PS abre a paleta na camada base e com L1 ou L2 segurados, e não faz nada com Options; a lista tem 17 itens fixos e nenhum envia Enter (emenda E001); o log da paleta registra índice ou motivo, nunca o texto. | 🟢 |
| `_reversa_sdd/addenda/002-paleta-comandos.md#Resumo da entrega` | O editor visual de atalhos, a configuração persistida e a paleta editável ficaram para a feature seguinte, a partir de `backlog-editor.md`. | 🟢 |
| `_reversa_forward/002-paleta-comandos/backlog-editor.md#Decisões já tomadas para esta futura feature` | Tipos de ação decididos (resposta 2a), pontos de entrada do editor (resposta 4c) e paleta editável com 1 a 50 itens. | 🟢 |
| `_reversa_forward/002-paleta-comandos/backlog-editor.md#Regras de negócio propostas` | Nove regras propostas para camadas, modificadores, validação, gravação e privacidade, sem confirmação do usuário. | 🟡 |
| `_reversa_sdd/sdd/action-mapping.md#6.1 Requisitos Principais` | RF-03 (recarga em até 1 s), RF-04 (arquivo inválido mantém a configuração anterior e informa a linha), RF-10 (repetição após 400 ms, a cada 50 ms) e RF-14 (modificador sem ação própria). | 🟡 |
| `_reversa_sdd/sdd/action-mapping.md#4. Non-Goals (Fora do Escopo)` | NG-01 (tela gráfica fora do escopo), que esta feature revoga, e NG-04 (sem execução de scripts), que permanece. | 🟡 |
| `_reversa_sdd/sdd/action-mapping.md#11. Edge Cases e Tratamento de Erros` | EC-01 (JSON inválido), EC-04 (combinação decidida no pressionar), EC-05 (sem tecla presa), EC-07 (falha de gravação) e EC-08 (arquivo removido com o app aberto). | 🟡 |
| `_reversa_sdd/sdd/action-mapping.md#15. Decisões Tomadas (Decision Log)` | L1 como único modificador e arquivo em `~/.config/joystick-ai/`; a primeira decisão é revogada, a segunda mantida. | 🟡 |
| `_reversa_sdd/sdd/app-shell.md#4. Non-Goals (Fora do Escopo)` | NG-03 (tela de mapeamentos fora do escopo), que esta feature revoga. | 🟡 |
| `_reversa_sdd/sdd/app-shell.md#6.1 Requisitos Principais` | RF-01 (app de barra de menus sem Dock), RF-08 (itens de configuração no menu) e RF-12 (log local). | 🟡 |
| `_reversa_sdd/personas.md#Persona 1: Programador de sofá` | Uso no sofá, com o Mac ligado ou não à TV, sem teclado nem mouse. | 🟡 |

## 3. Personas e cenários de uso

| Persona | Objetivo | Cenário-chave |
|---------|----------|---------------|
| Programador de sofá (`_reversa_sdd/personas.md#Persona 1: Programador de sofá`) | Incluir na paleta um comando que usa com frequência. | Pressiona PS, desce até "Editar atalhos", confirma com ✕, inclui `/reversa-docs` no topo da lista e salva; na abertura seguinte, a paleta traz o comando no topo. Algumas vezes por mês. |
| Programador de sofá | Trocar a ação de um botão. | No editor, liga o modo de identificação, pressiona △ no controle para selecioná-lo, atribui Command+Z e salva; △ passa a desfazer em até 1 s. |
| Programador de sofá | Criar uma camada nova de atalhos. | Marca L3 como modificador; a camada L3 aparece, e ele atribui a L3+○ o atalho de sistema Mission Control. |
| Programador de sofá, no papel de configurador | Versionar a configuração em dotfiles. | Edita o arquivo num editor de texto e salva; a alteração vale em até 1 s, e um erro de sintaxe mantém os atalhos vigentes e aparece no editor e no log com a linha. |

## 4. Regras de negócio novas ou alteradas

Termos usados nesta seção e nas seguintes:

- **Editor de atalhos:** janela do app em que o usuário vê e altera o mapeamento dos botões e a lista da paleta.
- **Botão modificador:** botão que, enquanto segurado, troca o conjunto de ações dos demais botões. No protótipo, L1, L2 e Options.
- **Camada:** conjunto de ações ativo num momento. A camada base vale sem modificador segurado; cada botão modificador define a sua.
- **Gatilho:** par formado por um botão e uma camada; é a unidade que recebe uma ação.
- **Acorde:** tecla do teclado acompanhada de zero ou mais teclas modificadoras (Command, Option, Control, Shift).
- **Configuração vigente:** mapeamento e paleta em uso pelo app num dado momento.
- **Modo de identificação:** estado do editor em que pressionar um botão do controle o seleciona na tela em vez de executar sua ação.

1. **RN-01:** Cada gatilho tem no máximo uma ação, decidida no instante em que o botão é pressionado e mantida até ele ser solto, mesmo que o modificador seja solto antes. 🟡
   - Origem no legado: `_reversa_sdd/sdd/action-mapping.md#11. Edge Cases e Tratamento de Erros` (EC-04)
   - Tipo: nova
2. **RN-02:** Numa camada de modificador, cada gatilho herda a ação da camada base, salvo quando recebe ação própria; "nenhuma" conta como ação própria. Qualquer botão pode ser modificador, exceto os de apontamento fixo de RN-05. 🟡
   - Origem no legado: `_reversa_sdd/sdd/action-mapping.md#15. Decisões Tomadas (Decision Log)` (L1 como único modificador)
   - Tipo: alterada
3. **RN-03:** Com mais de um modificador segurado, vale a camada do que está segurado há mais tempo, com herança só da camada base. O protótipo usa ordem fixa (Options, depois L2, depois L1, depois base) com herança em cascata, e a regra muda o resultado em combinações raras: segurar L2, depois L1, e pressionar ✕ passa a enviar Enter, e não mais `CONTINUAR`. 🟢
   - Origem no legado: `_reversa_sdd/addenda/001-poc-entrada-ponteiro.md#Impacto por artefato da extração`
   - Tipo: alterada
4. **RN-04:** Um botão modificador não recebe ação em nenhuma camada. Pode manter pressionadas zero ou mais teclas modificadoras do teclado enquanto segurado, como Options mantém Command. 🟡
   - Origem no legado: `_reversa_sdd/sdd/action-mapping.md#6.1 Requisitos Principais` (RF-14)
   - Tipo: nova
5. **RN-05:** R1 e o clique do touchpad fazem o clique esquerdo e R2 o direito, em qualquer camada; esses três botões não recebem atalho nem podem ser modificadores. L1 reduz a velocidade do cursor mesmo quando é modificador. 🟢
   - Origem no legado: `_reversa_sdd/addenda/001-poc-entrada-ponteiro.md#Impacto por artefato da extração`
   - Tipo: nova
6. **RN-06:** Um gatilho aceita seis tipos de ação: acorde, com repetição opcional após 400 ms e a cada 50 ms enquanto segurado; atalho de sistema; texto, com Enter opcional ao final; abrir a paleta; nenhuma; e, só fora da camada base, herdar da camada base. Abrir aplicativo, toque curto, toque longo e alternar o modo de condução não entram. 🟢
   - Origem no legado: `_reversa_sdd/sdd/action-mapping.md#9. Modelo de Dados` (tipos `openApp` e `toggleMode` e gatilhos `tap` e `longPress`)
   - Tipo: alterada
7. **RN-07:** Os atalhos de sistema oferecidos são os cinco já usados pelo protótipo: mesa à esquerda, mesa à direita, Mission Control, janelas do aplicativo e próxima janela. A configuração guarda o nome do atalho, e o acorde é lido das preferências do macOS no momento do uso, de modo que uma alteração feita pelo usuário nos Ajustes do Sistema é respeitada. 🟢
   - Origem no legado: `_reversa_sdd/addenda/001-poc-entrada-ponteiro.md#Impacto por artefato da extração`
   - Tipo: nova
8. **RN-08:** Uma configuração inválida nunca substitui a vigente. Mapeamento e paleta são validados em conjunto: um erro em qualquer dos dois mantém ambos. Na leitura ao iniciar, sem configuração vigente, valem o mapeamento e a paleta padrão. 🟡
   - Origem no legado: `_reversa_sdd/sdd/action-mapping.md#6.1 Requisitos Principais` (RF-04), `_reversa_sdd/sdd/action-mapping.md#11. Edge Cases e Tratamento de Erros` (EC-01)
   - Tipo: nova
9. **RN-09:** Aplicar uma configuração, seja por gravação no editor, seja por alteração externa, solta antes as teclas e as teclas modificadoras mantidas pelo controle e interrompe a repetição em curso. 🟡
   - Origem no legado: `_reversa_sdd/sdd/action-mapping.md#11. Edge Cases e Tratamento de Erros` (EC-05)
   - Tipo: nova
10. **RN-10:** O arquivo de configuração só é criado quando o usuário salva no editor. Ao gravar, o app preserva o conteúdo das seções que não gerencia, como `pointer`. A seção `pointer` continua lida só ao iniciar. Remover o arquivo com o app aberto mantém a configuração vigente até o próximo início. 🟡
    - Origem no legado: `_reversa_sdd/sdd/action-mapping.md#6.1 Requisitos Principais` (RF-02), `_reversa_sdd/sdd/action-mapping.md#11. Edge Cases e Tratamento de Erros` (EC-08), `_reversa_sdd/addenda/001-poc-entrada-ponteiro.md#Impacto por artefato da extração`
    - Tipo: alterada
11. **RN-11:** O mapeamento padrão reproduz o protótipo em uso, com PS abrindo a paleta (tabela abaixo); a paleta padrão é a lista de 17 itens entregue pela feature 002, sem Enter em nenhum item. Sem arquivo, o comportamento do app é idêntico ao anterior à entrega, ressalvada a regra RN-03. 🟢
    - Origem no legado: `_reversa_sdd/addenda/002-paleta-comandos.md#Resumo da entrega`
    - Tipo: nova
12. **RN-12:** A paleta tem de 1 a 50 itens. Cada item tem texto de uma única linha, com 1 a 1.000 caracteres, rótulo opcional exibido no lugar do texto (vazio exibe o próprio texto) e uma opção de Enter ao final, disponível em todos os itens e desmarcada nos 17 itens padrão. O item "Editar atalhos" é fixo, sempre o último, não editável e fora da contagem de 1 a 50. 🟢
    - Origem no legado: `_reversa_sdd/addenda/002-paleta-comandos.md#Impacto por artefato da extração` (emenda E001)
    - Tipo: alterada
13. **RN-13:** Ações de texto, do mapeamento ou da paleta, apenas digitam; nenhuma ação executa programa ou comando de shell. Os limites de RN-12 para o texto valem também para a ação de texto de um gatilho. 🟡
    - Origem no legado: `_reversa_sdd/sdd/action-mapping.md#4. Non-Goals (Fora do Escopo)` (NG-04)
    - Tipo: nova
14. **RN-14:** O log registra o gatilho executado, a abertura do editor com a origem (barra de menus ou paleta) e os eventos de configuração (carga, recarga, erro de validação com linha, gravação e restauração do padrão), nunca os textos, os acordes gravados nem as teclas injetadas. 🟢
    - Origem no legado: `_reversa_sdd/sdd/action-mapping.md#12. Segurança e Privacidade`, `_reversa_sdd/addenda/002-paleta-comandos.md#Impacto por artefato da extração`
    - Tipo: nova
15. **RN-15:** A gravação de acorde só captura teclas enquanto o campo de gravação está ativo e a janela do editor está em foco, e descarta as teclas injetadas pelo próprio app. Nenhuma tecla é capturada fora dessas condições. 🟡
    - Origem no legado: `_reversa_sdd/sdd/app-shell.md#12. Segurança e Privacidade`
    - Tipo: nova
16. **RN-16:** Com o editor aberto, o controle mantém a configuração vigente, inclusive atalhos, ponteiro e paleta, para que o próprio editor possa ser operado pelo controle. No modo de identificação, os botões que não são de apontamento fixo selecionam o botão na tela e não executam ação; os de apontamento continuam clicando. 🟡
    - Tipo: nova

### Mapeamento padrão

Reproduz o protótipo registrado no adendo da feature 001, somado a PS da feature 002. Nas camadas L1 e L2, os botões ausentes da tabela herdam a ação da camada base. 🟢

| Camada | Botão | Ação |
|--------|-------|------|
| base | ↑ ↓ ← → | acordes das setas, com repetição |
| base | ✕ / ○ / △ | acordes Enter / Esc / Tab |
| base | □ | acorde Backspace, com repetição |
| base | Create | atalho de sistema Mission Control |
| base | R3 | acorde Command+M (ditado do Raycast configurado pelo usuário) |
| base | PS | abrir a paleta |
| base | L3 | nenhuma |
| base | L1, L2, Options | modificadores |
| base | R1, clique do touchpad / R2 | clique esquerdo / clique direito, fixos |
| L1 | ✕ | texto `CONTINUAR` com Enter |
| L1 | △ | acorde Shift+Tab |
| L2 | ← / → | atalhos de sistema mesa à esquerda / mesa à direita |
| L2 | ↓ / ↑ | atalhos de sistema janelas do aplicativo / Mission Control |
| L2 | △ | atalho de sistema próxima janela |
| Options (mantém Command) | → / ← | acordes Command+Tab / Command+Shift+Tab |
| Options (mantém Command) | demais botões | nenhuma |

## 5. Requisitos Funcionais

| ID | Requisito | Prioridade | Critério de aceite | Confidência |
|----|-----------|------------|--------------------|-------------|
| RF-01 | O sistema deve carregar mapeamento e paleta do arquivo de configuração ao iniciar e, sem arquivo ou sem essas seções, usar o padrão de RN-11. | Must | Sem arquivo, ✕ envia Enter, L1+✕ digita `CONTINUAR` com Enter, L2+← troca de mesa e PS abre a paleta de 17 itens; com △ associado a Command+Z no arquivo, △ desfaz. | 🟢 |
| RF-02 | O sistema deve executar, a cada botão pressionado, a ação do gatilho resolvido conforme RN-01 a RN-05. | Must | Com L3 marcado como modificador e L3+○ associado a Mission Control, segurar L3 e pressionar ○ abre o Mission Control; soltar L3 antes de ○ mantém a ação até ○ ser solto. | 🟡 |
| RF-03 | O sistema deve aplicar, em até 1 s e sem reiniciar, uma alteração válida gravada no arquivo por outro programa. | Must | Trocar a ação de ○ num editor de texto e salvar faz ○ executar a nova ação em até 1 s. | 🟡 |
| RF-04 | O sistema deve validar o arquivo a cada leitura e, se inválido, manter a configuração vigente, registrar no log o erro com a linha e exibi-lo no editor. | Must | Com vírgula faltando na linha 12, os atalhos vigentes continuam valendo, e log e editor citam a linha 12. | 🟡 |
| RF-05 | O sistema deve gravar mapeamento e paleta criando a pasta e o arquivo quando ausentes e preservando as demais seções. | Must | Salvar com a seção `pointer` calibrada mantém `pointer` com os mesmos campos e valores. | 🟡 |
| RF-06 | O sistema deve exibir um ícone na barra de menus com os itens "Editar atalhos", que abre o editor, e "Sair", que encerra o app soltando teclas e botões mantidos. | Must | Clicar no ícone mostra os dois itens; "Sair" com □ segurado não deixa Backspace preso. | 🟢 |
| RF-20 | Enquanto o arquivo de configuração estiver inválido, o ícone da barra de menus deve exibir um sinal de alerta, e o menu, um item com o erro e a linha; ambos somem quando uma leitura válida é aplicada. | Must | Com o editor fechado, gravar por fora um arquivo com erro na linha 12 põe o alerta no ícone em até 1 s e o menu mostra o erro da linha 12; corrigir e salvar remove o alerta. | 🟢 |
| RF-07 | A paleta deve exibir o item fixo "Editar atalhos" no fim da lista, e confirmá-lo deve abrir o editor em vez de digitar texto. | Must | Sem teclado nem mouse, o usuário pressiona PS, seleciona "Editar atalhos", confirma com ✕, e o editor abre em primeiro plano sem que nada seja digitado no aplicativo anterior. | 🟢 |
| RF-08 | O editor deve exibir os 18 botões e, para a camada escolhida, a ação de cada um, identificando modificadores, ações herdadas e funções de apontamento como não editáveis. | Must | Na camada L2, ← mostra "mesa à esquerda"; ✕ mostra "Enter (herdado)"; R1 aparece como "clique esquerdo, fixo". | 🟡 |
| RF-09 | O editor deve permitir atribuir a um gatilho uma ação dos tipos de RN-06. | Must | Atribuir Command+Z a L1+○ e salvar faz L1+○ desfazer. | 🟢 |
| RF-10 | O editor deve permitir definir o acorde de uma ação de duas formas: gravando-o pelo teclado físico, conforme RN-15, ou montando-o por seleção operável pelo controle, com a tecla escolhida numa lista e caixas para Command, Option, Control e Shift. | Must | Com o campo de gravação ativo, Command+Shift+Z é gravado e ✕ pressionado no controle não grava Enter; sem teclado, escolher Tab na lista e marcar Command define Command+Tab. | 🟢 |
| RF-11 | O editor deve permitir marcar e desmarcar um botão como modificador e escolher as teclas modificadoras que ele mantém. | Must | Marcar L3 como modificador faz aparecer a camada L3; desmarcá-lo remove a camada e suas ações próprias depois de confirmação. | 🟡 |
| RF-12 | O editor deve impedir salvar configuração inválida, indicando cada gatilho ou item com problema. | Must | Marcar ✕ como modificador mantendo Enter em ✕ na camada base desabilita "Salvar" e destaca ✕. | 🟡 |
| RF-13 | O editor deve salvar aplicando a configuração em até 1 s, permitir descartar as alterações não salvas e, ao fechar com alterações pendentes, perguntar se salva, descarta ou cancela. | Must | Após descartar, o editor volta à configuração vigente; fechar com alteração pendente e escolher cancelar mantém a janela aberta com a alteração. | 🟡 |
| RF-14 | O editor deve permitir editar a lista da paleta: incluir, remover e reordenar itens e alterar rótulo, texto e Enter ao final, nos limites de RN-12. | Must | Incluir `/reversa-docs` no topo e salvar faz a paleta abrir com ele no topo; remover o único item restante é impedido. | 🟢 |
| RF-15 | O editor deve restaurar o mapeamento e a paleta padrão após confirmação. | Should | Confirmar a restauração volta aos padrões de RN-11; cancelar a confirmação não altera nada. | 🟡 |
| RF-16 | O editor deve oferecer o modo de identificação de RN-16, ligado e desligado explicitamente. | Should | Com o modo ligado, △ seleciona △ e não envia Tab; R1 continua clicando. | 🟡 |
| RF-17 | O editor deve dispor os botões numa figura que respeite a posição física no controle. | Should | □ aparece à esquerda do grupo de botões de ação, e L1 acima de L2. | 🟡 |
| RF-18 | O editor deve avisar quando o arquivo mudar por fora com alterações não salvas, oferecendo recarregar ou manter as alterações do editor. | Should | Com uma alteração pendente no editor e o arquivo gravado por outro programa, o aviso aparece e nada é sobrescrito sem escolha do usuário. | 🟡 |
| RF-19 | Ao fechar o editor, o sistema deve devolver o foco ao aplicativo que estava em foco quando o editor foi aberto. | Should | Abrir o editor pela paleta com o Terminal em foco e fechá-lo deixa o Terminal em foco. | 🟡 |

## 6. Requisitos Não Funcionais

| Tipo | Requisito | Evidência ou justificativa | Confidência |
|------|-----------|----------------------------|-------------|
| Desempenho | Uma configuração válida vale em até 1 s após a gravação, pelo editor ou por outro programa. | `_reversa_sdd/sdd/action-mapping.md#7. Requisitos Não-Funcionais` (RNF-02). | 🟡 |
| Desempenho | A execução da ação continua em até 30 ms (percentil 95) após o evento de entrada, com o mapeamento vindo da configuração. | `_reversa_sdd/sdd/action-mapping.md#7. Requisitos Não-Funcionais` (RNF-01). | 🟡 |
| Desempenho | O editor fica visível em até 1 s após o comando de abertura. | Paridade com o tempo de inicialização em `_reversa_sdd/sdd/app-shell.md#7. Requisitos Não-Funcionais` (RNF-01). | 🟡 |
| Recursos | Com o editor fechado, a detecção de alterações no arquivo não eleva o consumo de CPU em repouso acima do medido na feature 001. | CPU em repouso verificada em `_reversa_sdd/addenda/001-poc-entrada-ponteiro.md#Resumo da entrega`. | 🟡 |
| Limites | Arquivo de configuração com mais de 1 MiB (1.048.576 bytes) é inválido. | Limite já aplicado à leitura da seção `pointer`, confirmado no código. | 🟢 |
| Legibilidade | O editor segue a escala de TV da paleta: legível e operável pelo ponteiro do controle a 3 m, com texto de pelo menos 24 pt e alvos de clique com pelo menos 44 pt no menor lado. | Esclarecimento de 2026-09-14 (pergunta 2); contexto do sofá em `_reversa_sdd/personas.md#Persona 1: Programador de sofá`; a paleta usa texto de 26 pt e linhas de 40 pt (`_reversa_sdd/addenda/002-paleta-comandos.md`). O mínimo de 44 pt para alvos é inferido. | 🟡 |
| Robustez | Nenhuma gravação, recarga ou restauração deixa tecla ou modificador presos, e uma gravação interrompida não deixa o arquivo truncado. | RN-09; `_reversa_sdd/sdd/action-mapping.md#11. Edge Cases e Tratamento de Erros` (EC-05, EC-07). | 🟡 |
| Privacidade | Log sem textos, acordes gravados nem teclas injetadas; captura de teclado restrita ao campo de gravação. | RN-14, RN-15. | 🟢 |
| Observabilidade | O log registra carga, recarga, erro de validação com linha, gravação, restauração do padrão, abertura do editor com a origem e o gatilho executado. | Log JSON Lines existente desde a feature 001. | 🟡 |
| Compatibilidade | macOS 13 ou superior, como o restante do app. | `_reversa_sdd/sdd/app-shell.md#7. Requisitos Não-Funcionais` (RNF-03), já fixado no app. | 🟢 |

## 7. Critérios de Aceitação

```gherkin
# Cobre: RF-01, RN-11
Cenário: Padrão sem arquivo
  Dado que ~/.config/joystick-ai/config.json não existe
  Quando o usuário inicia o app e pressiona ✕, L1+✕, L2+← e PS
  Então ✕ envia Enter, L1+✕ digita CONTINUAR com Enter, L2+← troca para a mesa à esquerda e a paleta abre com 17 itens e "Editar atalhos"
  E o arquivo continua inexistente

# Cobre: RF-01
Cenário: Ação carregada do arquivo
  Dado o arquivo com △ associado ao acorde Command+Z na camada base
  Quando o usuário inicia o app e pressiona △ no VS Code
  Então a última edição é desfeita

# Cobre: RF-02, RN-01, RN-02
Cenário: Camada nova com herança
  Dado L3 marcado como modificador e L3+○ associado a Mission Control
  Quando o usuário segura L3 e pressiona ○, e depois segura L3 e pressiona ✕
  Então ○ abre o Mission Control e ✕ envia Enter, herdado da camada base

# Cobre: RF-02, RN-05
Cenário: Botões de apontamento fixos
  Dado o arquivo editado à mão associando R1 a um acorde
  Quando o app lê o arquivo
  Então a configuração é rejeitada citando R1 e R1 continua fazendo o clique esquerdo

# Cobre: RF-02, RN-03
Cenário: Precedência entre modificadores
  Dado o mapeamento padrão
  Quando o usuário segura L1, depois L2, e pressiona ✕
  Então CONTINUAR é digitado com Enter, pela camada L1
  E, segurando L2, depois L1, e pressionando ✕, é enviado Enter, herdado da base pela camada L2

# Cobre: RF-03, RN-09
Cenário: Alteração externa aplicada
  Dado o app em execução e □ segurado, apagando em repetição
  Quando o usuário troca a ação de ○ num editor de texto e salva
  Então a repetição de □ para, nenhuma tecla fica presa e ○ executa a nova ação em até 1 s

# Cobre: RF-04, RN-08
Cenário: Arquivo inválido
  Dado a configuração vigente com ○ enviando Esc
  Quando o usuário salva por fora um arquivo com vírgula faltando na linha 12 e ○ trocado para Tab
  Então ○ continua enviando Esc, o log registra o erro com a linha 12 e o editor exibe o erro com a linha 12

# Cobre: RF-20
Cenário: Alerta de configuração inválida
  Dado o editor fechado e a configuração válida
  Quando outro programa grava o arquivo com erro na linha 12
  Então o ícone da barra de menus exibe o alerta em até 1 s e o menu mostra o erro com a linha 12
  E, corrigido e salvo o arquivo, o alerta e o item de erro somem

# Cobre: RF-05, RN-10
Cenário: Seções preservadas ao salvar
  Dado o arquivo com a seção pointer calibrada e sem seções de mapeamento
  Quando o usuário altera um atalho no editor e salva
  Então pointer mantém os mesmos campos e valores e o novo atalho vale em até 1 s

# Cobre: RF-05
Cenário: Pasta sem permissão de escrita
  Dado ~/.config sem permissão de escrita
  Quando o usuário salva no editor
  Então o editor exibe o erro com o caminho, a configuração vigente não muda e as alterações continuam no editor

# Cobre: RF-06
Cenário: Ícone na barra de menus
  Dado o app em execução
  Quando o usuário clica no ícone da barra de menus e escolhe "Editar atalhos"
  Então o editor abre em primeiro plano
  E, escolhendo "Sair" com □ segurado, o app encerra sem Backspace preso

# Cobre: RF-07
Cenário: Editor aberto pela paleta
  Dado o Terminal em foco
  Quando o usuário pressiona PS, seleciona "Editar atalhos" e pressiona ✕
  Então o editor abre em primeiro plano e nenhum texto é digitado no Terminal

# Cobre: RF-08
Cenário: Visão de uma camada
  Dado o mapeamento padrão
  Quando o usuário escolhe a camada L2 no editor
  Então ← mostra "mesa à esquerda", ✕ mostra Enter como herdado e R1 aparece como clique esquerdo fixo

# Cobre: RF-09, RF-13
Cenário: Atribuir e salvar
  Dado o editor aberto
  Quando o usuário atribui o acorde Command+Z a L1+○ e salva
  Então L1+○ desfaz em até 1 s após salvar

# Cobre: RF-10, RN-15
Cenário: Gravação de acorde
  Dado o campo de gravação ativo com a janela do editor em foco
  Quando o usuário pressiona Command+Shift+Z no teclado e depois ✕ no controle
  Então o acorde gravado é Command+Shift+Z e o Enter injetado pelo controle não é gravado

# Cobre: RF-10
Cenário: Acorde montado pelo controle
  Dado o editor aberto, sem teclado físico
  Quando o usuário escolhe Tab na lista de teclas com o ponteiro do controle, marca Command e salva
  Então o gatilho passa a enviar Command+Tab

# Cobre: RN-15
Cenário: Captura restrita ao campo
  Dado o editor aberto com o campo de gravação inativo
  Quando o usuário digita no Terminal
  Então nenhuma tecla é capturada pelo editor nem registrada no log

# Cobre: RF-11
Cenário: Marcar modificador
  Dado o editor aberto
  Quando o usuário marca L3 como modificador mantendo Control
  Então a camada L3 aparece e, depois de salvar, segurar L3 mantém Control pressionado

# Cobre: RF-12
Cenário: Salvar bloqueado
  Dado o editor aberto
  Quando o usuário marca ✕ como modificador sem remover o Enter de ✕ na camada base
  Então "Salvar" fica desabilitado e ✕ aparece destacado com o motivo

# Cobre: RF-13
Cenário: Fechar com alteração pendente
  Dado o editor com uma alteração não salva
  Quando o usuário fecha a janela e escolhe cancelar
  Então a janela continua aberta com a alteração
  E, fechando de novo e escolhendo descartar, a configuração vigente não muda

# Cobre: RF-14, RN-12
Cenário: Editar a paleta
  Dado o editor aberto na lista da paleta
  Quando o usuário inclui /reversa-docs no topo com Enter ao final marcado e salva
  Então a próxima abertura da paleta mostra /reversa-docs no topo e "Editar atalhos" no fim
  E confirmar /reversa-docs digita o comando e envia Enter

# Cobre: RF-14, RN-12
Cenário: Limites da paleta
  Dado a paleta com um único item
  Quando o usuário tenta removê-lo, ou incluir um 51.º item numa lista de 50, ou colar um texto com quebra de linha
  Então o editor impede a operação e informa o limite

# Cobre: RF-15
Cenário: Restaurar padrão
  Dado atalhos e paleta alterados
  Quando o usuário pede a restauração e cancela a confirmação
  Então nada muda
  E, pedindo de novo e confirmando, valem o mapeamento e a paleta de RN-11

# Cobre: RF-16, RN-16
Cenário: Modo de identificação
  Dado o editor em foco com o modo de identificação ligado
  Quando o usuário pressiona △ e depois R1 sobre um controle do editor
  Então △ fica selecionado sem enviar Tab e R1 clica no controle

# Cobre: RF-17
Cenário: Figura do controle
  Dado o editor aberto
  Quando o usuário observa a figura dos botões
  Então □ está à esquerda do grupo de ação e L1 acima de L2

# Cobre: RF-18
Cenário: Conflito com alteração externa
  Dado o editor com uma alteração não salva
  Quando outro programa grava o arquivo
  Então o editor avisa e oferece recarregar ou manter, sem sobrescrever nada até a escolha

# Cobre: RF-19
Cenário: Foco devolvido
  Dado o Terminal em foco e o editor aberto pela paleta
  Quando o usuário fecha o editor
  Então o Terminal volta a ser o aplicativo em foco

# Cobre: RN-14
Cenário: Privacidade do log
  Dado a paleta com um item de texto /reversa-docs e L1+✕ com CONTINUAR
  Quando o usuário salva a configuração e pressiona L1+✕
  Então o log registra a gravação e o gatilho executado
  E nenhuma linha do log contém "CONTINUAR", "/reversa-docs" nem acordes gravados
```

## 8. Prioridade MoSCoW

| Item | MoSCoW | Justificativa |
|------|--------|---------------|
| RF-01 a RF-05, RF-20 | Must | Atalhos e paleta configuráveis dependem de carga, execução, recarga, validação e gravação seguras. |
| RF-06 a RF-14 | Must | Constituem a interface pedida e os pontos de entrada decididos pelo usuário (resposta 4c). |
| RNF de desempenho, robustez e privacidade | Must | A troca de configuração não pode prender teclas nem expor textos; a latência das ações é regra vigente. |
| RNF de legibilidade | Must | O editor precisa servir ao uso do sofá, na escala de TV decidida pelo usuário. |
| RF-15 a RF-19 | Should | Conforto e segurança de edição; sem eles, a edição pelo mouse do controle continua possível. |
| Abrir aplicativo, toque curto e longo, alternar modo, troca dos botões de clique | Won't | Decisão do usuário (resposta 2a da feature 002). |
| Recarga da seção `pointer` sem reiniciar | Won't | Fora do pedido; a seção continua lida só ao iniciar. |
| Perfis por aplicativo, macros temporizadas e sincronização entre máquinas | Won't | `_reversa_sdd/sdd/action-mapping.md#4. Non-Goals (Fora do Escopo)` (NG-03 a NG-05). |
| Estado do controle, das permissões, do microfone e do modo no menu da barra | Won't | O ícone é mínimo por decisão do usuário (resposta 4c), acrescido só do alerta de configuração inválida (RF-20); o menu completo de `app-shell` fica para depois. |

## 9. Esclarecimentos

### Sessão 2026-09-14

- **Q:** Como o acorde deve ser definido no editor?
  **R:** Das duas formas: gravado pelo teclado físico ou montado por seleção operável pelo controle, com tecla escolhida numa lista e caixas para Command, Option, Control e Shift. Integrado em RF-10 e no cenário "Acorde montado pelo controle".
- **Q:** Qual escala visual o editor deve ter?
  **R:** Escala de TV, como a paleta: texto a partir de 24 pt e alvos de clique grandes. Integrado no RNF de legibilidade, com alvos de pelo menos 44 pt, e na seção 8.
- **Q:** Com mais de um modificador segurado, qual camada vale?
  **R:** A do modificador segurado há mais tempo, com herança só da camada base. Integrado em RN-03 e no cenário "Precedência entre modificadores".
- **Q:** Os itens da paleta editável podem enviar Enter ao final?
  **R:** Sim, com uma opção por item, desmarcada nos 17 itens padrão. Integrado em RN-12 e no cenário "Editar a paleta".
- **Q:** Como avisar um arquivo inválido gravado por fora com o editor fechado?
  **R:** Com sinal de alerta no ícone da barra de menus e um item no menu com o erro e a linha. Integrado em RF-20, no cenário "Alerta de configuração inválida" e na seção 8.

## 10. Lacunas

- 🟡 **Texto sem teclado.** Os campos de rótulo e texto da paleta e da ação de texto dependem do ditado do Raycast em R3 quando não há teclado físico; convém verificar no plano se o ditado insere texto nos campos do editor.
- 🟡 **Intervalo antes do Enter.** Com a opção de Enter por item (RN-12), o argumento `--palette-enter-delay-ms`, hoje sem uso, volta a ter efeito; a sonda P-01 da feature 002 aprovou 0 ms só no Terminal. Verificação do plano, não decisão.
- 🟡 **Formatação do arquivo.** Gravar pelo editor preserva conteúdo, mas pode alterar a indentação e a ordem das chaves das seções não gerenciadas; convém observar o impacto no versionamento em dotfiles.
- 🟡 **Convergência nas specs.** Ao entregar, o `/reversa-sync` deve registrar a revogação de `action-mapping` NG-01, RF-02 e a decisão de L1 como único modificador, e de `app-shell` NG-03.

## 11. Histórico de alterações

| Data | Alteração | Autor |
|------|-----------|-------|
| 2026-09-14 | Versão inicial gerada por `/reversa-requirements`, a partir de `backlog-editor.md` da feature 002 | reversa |
| 2026-09-14 | Sessão de esclarecimentos: cinco perguntas respondidas, três dúvidas resolvidas; acorde por teclado ou por seleção, escala de TV, precedência pelo modificador mais antigo, Enter opcional por item e alerta de configuração inválida (RF-20) | reversa |
| 2026-09-15 | Emenda E002: editor aberto pela paleta por meio do ícone da barra de menus, após a sonda P-01 | reversa |
| 2026-09-15 | Emenda E003: E002 revogada; editor em janela flutuante com clique de ativação, critério original de RF-07 restabelecido | reversa |

## Pendências de Qualidade

- **Q-018 (produto comercial no documento), exceção assumida.** DualSense, macOS, Raycast, VS Code e Terminal aparecem porque são o domínio do problema e os ambientes de uso, não escolhas de solução. Frameworks e APIs de implementação ficam para o `/reversa-plan`.
- **Q-011 e Q-019, não aplicáveis.** Não existem `_reversa_sdd/domain.md` nem `.reversa/principles.md`; as regras citam as specs SDD e os adendos das features 001 e 002 como origem.

## Emendas

### E002, 2026-09-15 (revogada pela E003)

O que muda: confirmar "Editar atalhos" na paleta não abre o editor diretamente. A paleta fecha, o ponteiro vai ao ícone do app na barra de menus da tela onde está o cursor, e o ícone fica armado por 10 s: um clique nele (R1) abre o editor em primeiro plano, sem mostrar o menu. Sem o clique, o ícone volta ao menu normal. Nada é digitado no aplicativo anterior. O critério de aceite de RF-07 e o cenário "Editor aberto pela paleta" passam a exigir esse clique no ícone.
Motivo: a sonda P-01 reprovou a abertura direta em quatro de quatro tentativas com a janela fechada (`editor.activation_failed`, janela atrás do terminal). No macOS 26, um app só é ativado logo após interação com ele, e o botão do controle não conta; um clique automático na barra de título da janela também falhou, pois acertava a janela de outro aplicativo. A abertura pelo ícone já funcionava. É a alternativa prevista em `investigation.md` §3.3 e em D-23, aceita pelo usuário antes do reteste.
Arquivos previstos: `Sources/JoystickAIPoC/App/StatusMenu.swift`, `Sources/JoystickAIPoC/App/AppDelegate.swift`, `Sources/JoystickAIPoC/Injection/EventInjector.swift`, `Sources/JoystickAIPoC/Editor/EditorWindowController.swift`

### E003, 2026-09-15

O que muda: revoga a E002 e restabelece o critério original de RF-07 e o cenário "Editor aberto pela paleta": confirmar "Editar atalhos" com ✕ abre o editor, sem clique no ícone. O editor abre acima das demais janelas e recebe um clique automático na barra de título, com o ponteiro devolvido à posição anterior. Se ainda assim não ficar em foco, a janela permanece por cima até um clique do usuário nela, e volta ao comportamento de janela comum assim que o app fica ativo.
Motivo: no reteste da E002, o clique do R1 no ícone também não ativou o app (`editor.activation_failed` em aberturas pelo menu e pelo ícone armado), o que indica que o macOS 26 não aceita o clique sintético do controle como interação que autoriza a ativação pedida pelo app. O clique do R1 dentro da própria janela, porém, sempre a ativou (gravação de acorde e colagem funcionaram depois dele), e o clique automático anterior só falhara por acertar a janela de outro aplicativo, que estava por cima. Escolha do usuário entre esta abordagem, a mesma sem clique automático e a volta ao `/reversa-clarify`.
Arquivos previstos: `Sources/JoystickAIPoC/Editor/EditorWindowController.swift`, `Sources/JoystickAIPoC/Injection/EventInjector.swift`, `Sources/JoystickAIPoC/App/AppDelegate.swift`, `Sources/JoystickAIPoC/App/StatusMenu.swift`

