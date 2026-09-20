# Requirements: controle virtual no iPhone

> Identificador: `010-joystick-virtual-iphone`
> Data: `2026-09-20`
> Pasta da extração reversa: `_reversa_sdd/`
> Confidência: 🟢 CONFIRMADO, 🟡 INFERIDO, 🔴 LACUNA / DÚVIDA

## 1. Resumo executivo

A página que hoje serve de teclado remoto passa a reunir, numa só tela na horizontal, os analógicos, os botões e os gatilhos do controle e o teclado que já existe. Os controles ficam nas laterais, sempre à vista, e o centro alterna entre três estados: a área de apontamento, um teclado reduzido e o teclado completo entregue nas features 008 e 009. Com isso, o programador de sofá aponta, clica, rola, dispara atalhos, abre a paleta e dita prompts sem nenhum controle físico ligado ao Mac, porque toda a superfície de comando cabe no aparelho que já está na mão. O ditado continua a ser acionado por um botão mapeado, como hoje, e passa a poder usar o microfone do iPhone, escolhido como entrada de áudio nas preferências do Mac. Ficam fora da feature o espelhamento da tela do Mac no iPhone e qualquer transporte de áudio pela rede local.

## 2. Contexto a partir do legado

| Fonte | Trecho relevante | Confidência |
|-------|------------------|-------------|
| Pedido do usuário, 2026-09-20 | "Criar uma interface somada ao teclado que já temos para o celular, que simularia o joystick, de modo que eu não precise mais usar um joystick, mas deixar tudo na interface do iPhone, incluindo os botões e a parte do cursor." | 🟢 |
| Pedido do usuário, 2026-09-20 | "Porque daí aproveitaríamos o microfone do próprio iPhone também." | 🟢 |
| Decisão do usuário, 2026-09-20 | "O teclado tem que estar junto dos analógicos e tudo mais": uma só tela, com os gatilhos superiores nas quinas, Options e Create ao centro e o bloco de teclado no meio | 🟢 |
| Referências visuais do usuário, 2026-09-20 | Dois exemplos de controle em tela: analógicos flutuantes nos cantos inferiores e botões de ação orbitando o analógico direito | 🟢 |
| `Sources/JoystickAIPoC/Pointer/InputRouter.swift:41` | O roteador trata entradas normalizadas, sem saber a origem, e já desvia botões ao editor no modo de identificação e à paleta quando ela está aberta | 🟢 |
| `Sources/JoystickAIPoC/Pointer/MotionLoop.swift:30` | O motor de movimento já converte analógico esquerdo, analógico direito e toque em deslocamento, rolagem e arrasto relativo | 🟢 |
| `Sources/JoystickCore/Config/ShortcutDefaults.swift` | O mapeamento padrão atribui papel a dezoito botões, entre direcional, faces, gatilhos, modificadores, Create, R3, PS e L3 | 🟢 |
| `Sources/JoystickCore/Remote/RemoteKeyGeometry.swift:48` e `Resources/RemoteKeyboard/keyboard.css` | O teclado completo tem seis linhas de quinze unidades e hoje ocupa toda a altura da tela | 🟢 |
| `_reversa_sdd/architecture.md#2. Estilo arquitetural` | Núcleo funcional com casca imperativa: a decisão de domínio mora em valores testáveis do `JoystickCore`, e o aplicativo apenas executa os efeitos | 🟢 |
| `_reversa_sdd/architecture.md#3. Camadas e dependências` | Um evento de entrada atravessa leitores, roteador, consumidores e injetores sempre na mesma fila serial | 🟢 |
| `_reversa_sdd/architecture.md#4. Integrações externas` | A saída é sempre evento sintético do sistema com a marca do injetor; não há API nem mensageria além do teclado remoto | 🟢 |
| `_reversa_sdd/domain.md#2. Glossário` | Definições de controle ativo, zona morta, botões de apontamento, precisão, paleta, camada, modificador e gatilho | 🟢 |
| `_reversa_sdd/domain.md#3.1 Controle e entrada (001)` | 001 RN-01 admite um único controle ativo; RN-02 a RN-11 fixam zona morta, cliques, duplo clique, limite às telas e mapeamento; 001 RN-12 restringe rede e log | 🟢 |
| `_reversa_sdd/domain.md#3.2 Paleta (002)` | 002 RN-02 e RN-03: a paleta não toma o foco, navega com as direções, confirma com ✕ e fecha com ○ ou PS | 🟢 |
| `_reversa_sdd/domain.md#3.3 Atalhos, configuração e editor (003)` | 003 RN-01 a RN-06 e RN-16: ação decidida no pressionar, camadas por modificador, herança da base e modo de identificação do editor | 🟢 |
| `_reversa_sdd/code-analysis.md#3. `pointer`` | Touchpad relativo com um dedo, velocidade do analógico por curva exponencial, temporizador de 120 Hz sob demanda, precisão só com L1 isolado, limite à união das telas | 🟢 |
| `_reversa_sdd/code-analysis.md#4. `injection`` | Portão de injeção, contagem de referência dos modificadores e texto emitido por unidade de código, independente do layout | 🟢 |
| `_reversa_sdd/permissions.md#2. Matriz de permissões do sistema operacional` | A única permissão de sistema exigida no Mac é a de Acessibilidade | 🟢 |
| `_reversa_sdd/permissions.md#4. Restrições de acesso internas` | Textos, rótulos e acordes nunca vão ao log; o texto recebido do iPhone vive só em memória | 🟢 |
| `_reversa_sdd/addenda/006-teclado-virtual.md#Resumo da entrega` | A digitação livre pelo Teclado de Acessibilidade do macOS depende de mover o ponteiro e clicar tecla a tecla | 🟢 |
| `_reversa_sdd/addenda/007-controle-ipega.md#Resumo da entrega` | O aplicativo já conhece mais de um modelo de controle e mapeia botões pela posição física, com a mesma configuração para todos | 🟢 |
| `_reversa_sdd/addenda/009-sugestao-de-palavras.md#Resumo da entrega` | O teclado remoto guarda em memória o texto recente para sugerir palavras e descarta esse contexto a cada botão do controle, troca de aplicativo ou fim de sessão | 🟢 |
| `_reversa_sdd/addenda/prd-l01-ditado-pelo-raycast.md#Resumo da decisão` | O ditado foi delegado a um acorde enviado ao transcritor externo; o aplicativo não captura áudio nem pede permissão de microfone | 🟢 |
| `_reversa_forward/008-iphone-teclado-remoto/requirements.md#4. Regras de negócio novas ou alteradas` | RN-01 a RN-14 do teclado remoto: recurso desligado por padrão, tráfego cifrado, pareamento por código, um aparelho por vez, soltura em perda de conexão e log sem conteúdo | 🟢 |
| `_reversa_forward/008-iphone-teclado-remoto/interfaces/remote-keyboard-protocol.md#3. Canal` | A sessão vive num canal cifrado, com vigia de inatividade, soltura geral em silêncio e recusa de segundo aparelho | 🟢 |

> A feature 008 está em código, porém ainda sem adendo na extração; enquanto o `/reversa-sync` dela não rodar, as citações do teclado remoto apontam para a pasta da própria 008, como o adendo da 009 determina.

## 3. Personas e cenários de uso

| Persona | Objetivo | Cenário-chave |
|---------|----------|---------------|
| Programador de sofá (`_reversa_sdd/personas.md#Persona 1: Programador de sofá`) | Conduzir a sessão sem nenhum controle físico ao alcance | Deitado no sofá, com o iPhone na mão e a TV a 3 m, move o cursor pelo analógico virtual, clica no gatilho direito e abre a paleta pelo botão PS da página |
| Programador de sofá | Passar da digitação ao apontamento sem interromper a sessão | Termina de digitar um comando no teclado completo, recolhe o bloco central, rola o resultado pelo analógico direito e clica num link |
| Programador de sofá | Ditar um prompt longo para o agente | Toca o acionador de ditado, fala a instrução e vê o texto aparecer no campo do agente em foco no Mac |
| Programador de sofá | Continuar usando o controle físico quando ele estiver por perto | Com o DualSense na mão e o iPhone apoiado, aponta pelo controle e usa a página só para digitar |

A frequência esperada é contínua durante as sessões de programação, com alternância frequente entre os três estados do bloco central. 🟡

## 4. Regras de negócio novas ou alteradas

1. **RN-01:** O controle virtual é uma origem de entrada equivalente ao controle físico, com os mesmos botões lógicos, mas não disputa a vaga de controle ativo: ele funciona com ou sem controle conectado, e as entradas das duas origens chegam ao aplicativo na ordem em que são produzidas. 🟢
   - Origem no legado: `_reversa_sdd/domain.md#3.1 Controle e entrada (001)` (001 RN-01)
   - Tipo: alterada (a regra do controle ativo passa a valer apenas entre controles físicos)
2. **RN-02:** Os botões do controle virtual obedecem à configuração vigente de atalhos, com as mesmas camadas, modificadores, herança e tipos de ação do controle físico; nenhum mapeamento separado é criado para o iPhone. 🟢
   - Origem no legado: `_reversa_sdd/domain.md#3.3 Atalhos, configuração e editor (003)` (003 RN-01 a RN-06)
   - Tipo: alterada (nova origem para o mesmo mapeamento)
3. **RN-03:** Os botões de apontamento continuam reservados: o gatilho superior direito e o toque no painel central clicam com o botão esquerdo, e o gatilho inferior direito clica com o direito, em qualquer camada, também quando vêm do iPhone. 🟢
   - Origem no legado: `_reversa_sdd/domain.md#3.3 Atalhos, configuração e editor (003)` (003 RN-05)
   - Tipo: alterada
4. **RN-04:** O analógico virtual de movimento produz deslocamento contínuo do cursor enquanto o dedo estiver fora do centro, com a mesma zona morta, a mesma curva de velocidade e o mesmo limite às telas do analógico físico; soltar o dedo devolve o analógico ao repouso e para o movimento. 🟢
   - Origem no legado: `_reversa_sdd/code-analysis.md#3. `pointer`` e `_reversa_sdd/domain.md#3.1 Controle e entrada (001)` (001 RN-02, RN-10)
   - Tipo: alterada (nova origem para o mesmo motor de movimento)
5. **RN-05:** O analógico virtual de rolagem rola na mesma proporção do analógico direito físico e respeita a inversão vertical configurada. 🟢
   - Origem no legado: `_reversa_sdd/code-analysis.md#3. `pointer``
   - Tipo: alterada
6. **RN-06:** A área de toque do controle virtual move o cursor de forma relativa, como o touchpad do controle: pousar o dedo não move, só o primeiro dedo desloca, e o deslocamento soma-se ao do analógico virtual. 🟢
   - Origem no legado: `_reversa_sdd/domain.md#3.1 Controle e entrada (001)` (001 RN-05, RN-06)
   - Tipo: alterada
7. **RN-07:** A redução de velocidade para apontamento fino vale igualmente no controle virtual: enquanto o gatilho superior esquerdo estiver mantido e nenhum outro botão estiver pressionado, o cursor anda na fração configurada. 🟢
   - Origem no legado: `_reversa_sdd/domain.md#3.1 Controle e entrada (001)` (001 RN-08)
   - Tipo: alterada
8. **RN-08:** Teclado e controle dividem a mesma página, a mesma sessão pareada e o mesmo canal cifrado; trocar o estado do bloco central não pede código novo. Ao trocar, tudo o que o estado abandonado mantinha, teclas, modificadores, botões e cliques, é solto antes de o novo assumir. 🟢
   - Origem no legado: `_reversa_forward/008-iphone-teclado-remoto/requirements.md#4. Regras de negócio novas ou alteradas` (008 RN-04, RN-05, RN-10)
   - Tipo: alterada
9. **RN-09:** Nenhuma perda de conexão deixa entrada presa: quando o aparelho sai, a página vai a segundo plano, o vigia de inatividade dispara ou o recurso é desligado no Mac, o aplicativo solta botões, cliques, teclas e modificadores vindos do iPhone, zera os analógicos virtuais e interrompe qualquer repetição. 🟢
   - Origem no legado: `_reversa_sdd/domain.md#3.1 Controle e entrada (001)` (001 RN-04); `_reversa_forward/008-iphone-teclado-remoto/requirements.md#4. Regras de negócio novas ou alteradas` (008 RN-10)
   - Tipo: alterada
10. **RN-10:** As entradas do controle virtual passam pelo portão de injeção, o mecanismo que liga e desliga a saída de eventos conforme a permissão, como as do controle físico: sem a permissão de Acessibilidade no Mac, nada é postado, e a página informa o motivo em vez de descartar em silêncio. 🟢
    - Origem no legado: `_reversa_sdd/injecao-de-eventos/requirements.md#Regras de Negócio` (RN-IN-02); `_reversa_forward/008-iphone-teclado-remoto/requirements.md#4. Regras de negócio novas ou alteradas` (008 RN-11)
    - Tipo: alterada
11. **RN-11:** O ditado continua sendo acionado por um botão mapeado para o acorde do transcritor externo, exatamente como hoje. A diferença é a origem do som: a entrada de áudio do Mac pode ser o microfone do iPhone, escolhida nas preferências do sistema, sem cabo. O aplicativo não captura áudio, não escolhe o dispositivo de entrada, não transporta áudio pelo canal do teclado remoto e não reconhece fala. 🟢
    - Origem no legado: `_reversa_sdd/addenda/prd-l01-ditado-pelo-raycast.md#Resumo da decisão`
    - Tipo: alterada (o botão de ditado passa a existir também no controle virtual, e o microfone do aparelho entra como entrada possível)
12. **RN-12:** Nenhuma permissão nova é pedida, nem ao Mac nem ao navegador do iPhone: a página não acessa o microfone. O que autoriza o uso do som do aparelho é o vínculo entre os dois dispositivos, configurado uma vez no sistema. 🟢
    - Origem no legado: `_reversa_sdd/permissions.md#2. Matriz de permissões do sistema operacional`
    - Tipo: alterada
13. **RN-13:** O log registra apenas eventos de estado e contagens do controle virtual: face em uso, botões pressionados na sessão, cliques, acionamentos de ditado e caracteres ditados. Coordenadas do cursor, deslocamentos, texto ditado, rótulos e endereço do aparelho nunca vão ao log. 🟢
    - Origem no legado: `_reversa_sdd/domain.md#3.1 Controle e entrada (001)` (001 RN-12); `_reversa_sdd/domain.md#3.3 Atalhos, configuração e editor (003)` (003 RN-14); `_reversa_forward/008-iphone-teclado-remoto/requirements.md#4. Regras de negócio novas ou alteradas` (008 RN-13)
    - Tipo: alterada
14. **RN-14:** O contexto de texto que alimenta a sugestão de palavras é descartado a cada botão do controle virtual, a cada clique e a cada texto ditado, pelo mesmo motivo que já o descarta a cada botão do controle físico: o ponto de escrita pode ter mudado sem que o aplicativo saiba. 🟢
    - Origem no legado: `_reversa_sdd/addenda/009-sugestao-de-palavras.md#Resumo da entrega`
    - Tipo: alterada
15. **RN-15:** Com o editor de atalhos aberto em modo de identificação, um botão do controle virtual identifica o gatilho na figura, como faria o botão físico correspondente, e não executa a ação mapeada. 🟢
    - Origem no legado: `_reversa_sdd/domain.md#3.3 Atalhos, configuração e editor (003)` (003 RN-16)
    - Tipo: alterada
16. **RN-16:** Enquanto a paleta estiver aberta, o controle virtual a opera como o controle físico: as direções navegam, o botão de confirmação digita o item e os botões de fechamento a encerram; os atalhos ficam suspensos e o apontamento continua ativo. 🟢
    - Origem no legado: `_reversa_sdd/domain.md#3.2 Paleta (002)` (002 RN-03)
    - Tipo: alterada

## 5. Requisitos Funcionais

| ID | Requisito | Prioridade | Critério de aceite | Confidência |
|----|-----------|------------|--------------------|-------------|
| RF-01 | A página reúne, numa só tela na horizontal, os analógicos e os botões nas laterais e um bloco central que alterna entre três estados: área de apontamento, teclado reduzido e teclado completo | Must | Os três estados são alcançados por um comando sempre visível, sem recarregar a página nem parear de novo | 🟢 |
| RF-02 | Os analógicos e os botões permanecem visíveis e operáveis nos estados de apontamento e de teclado reduzido; no teclado completo, o centro tem prioridade e os controles se recolhem ao que sobrar da largura | Must | No estado de teclado reduzido, mover o cursor e tocar uma tecla não exige trocar de estado | 🟢 |
| RF-03 | A página desenha todos os botões do controle, com hierarquia de tamanho: analógicos, direcional, as quatro faces (✕, ○, □, △) e os quatro gatilhos em tamanho pleno, com L1 e L2 à esquerda e R1 e R2 à direita; L3, R3, PS, Options, Create e o clique do painel menores, numa faixa central | Must | Qualquer ação do mapeamento padrão é disparada pelo iPhone sem reconfigurar o editor de atalhos | 🟢 |
| RF-04 | O analógico esquerdo move o cursor de forma contínua, conforme RN-04 | Must | Inclinar o analógico ao máximo atravessa a tela do Mac; soltar o dedo interrompe o movimento em até 100 ms | 🟢 |
| RF-05 | O analógico direito rola o conteúdo, conforme RN-05 | Must | Inclinar o analógico de rolagem para baixo rola a janela em foco no Mac; a inversão configurada é respeitada | 🟢 |
| RF-06 | No estado de apontamento, o bloco central funciona como área de toque relativa, conforme RN-06 | Must | Arrastar o dedo pela área desloca o cursor na proporção do touchpad do controle; pousar o dedo não move nada | 🟢 |
| RF-07 | Os cliques seguem o mapeamento fixo de RN-03, inclusive arraste e duplo clique | Must | Manter o gatilho superior direito e inclinar o analógico esquerdo seleciona texto; dois toques rápidos abrem o item apontado | 🟢 |
| RF-08 | O apontamento fino de RN-07 é acionado pelo gatilho superior esquerdo | Must | Com o gatilho mantido, o cursor percorre a fração configurada da distância que percorreria sem ele | 🟢 |
| RF-09 | Os botões do controle virtual disparam os atalhos configurados, inclusive camadas por modificador e herança | Must | Manter o botão definido como modificador e tocar um gatilho executa a ação da camada correspondente, como no controle físico | 🟢 |
| RF-10 | O controle virtual abre e opera a paleta, conforme RN-16 | Must | O botão mapeado para abrir a paleta a exibe no Mac, as direções navegam e a confirmação digita o item no aplicativo em foco | 🟢 |
| RF-11 | Com o editor aberto em modo de identificação, tocar um botão na página seleciona o gatilho correspondente na figura, conforme RN-15 | Must | Durante a identificação, o toque no botão seleciona o gatilho e nenhuma ação mapeada é executada | 🟢 |
| RF-12 | O estado de teclado completo preserva o teclado entregue nas features 008 e 009, com os rótulos da fonte de entrada do Mac e a faixa de sugestões de palavras | Must | Com a fonte ABNT2 ativa, a tecla à direita do L mostra Ç, os acentos por tecla morta funcionam e as sugestões aparecem como hoje | 🟢 |
| RF-13 | O estado de teclado reduzido traz os quatro modificadores, Esc, Tab, Return, apagar, espaço e as quatro setas, mais o comando que leva ao teclado completo | Must | Executar um atalho de edição e confirmar um comando no terminal não exige abrir o teclado completo | 🟡 |
| RF-14 | **Reescrito no PM-0.** O botão de ditado do controle virtual dispara o acorde do transcritor externo, como o botão físico já faz. A entrada de áudio é o **microfone do próprio Mac**: a P-01 apurou que escolher o iPhone aciona junto a Continuity Camera e toma a tela do aparelho, que precisa estar mostrando o controle, e o usuário decidiu manter o áudio no Mac | Must | Tocar o botão de ditado e falar insere o texto transcrito no campo em foco, com a entrada de áudio do Mac no microfone do próprio Mac | 🟢 |
| RF-15 | A página mostra o estado da ligação (conectado, sem permissão de Acessibilidade no Mac, desconectado) e marca visualmente cada botão tocado e cada modificador mantido ou preso | Must | Revogar a permissão no Mac leva a página ao estado "sem permissão" em até 3 s, e nenhum toque produz efeito | 🟡 |
| RF-16 | O aplicativo solta tudo o que o iPhone mantinha nas situações de RN-09 | Must | Com um botão de clique mantido, bloquear o iPhone solta o clique no Mac em até 1 s | 🟢 |
| RF-17 | O controle virtual funciona sem nenhum controle físico conectado, e com um conectado as duas origens coexistem | Must | Sem DualSense nem Ipega ligados, o cursor se move e os atalhos disparam; com o DualSense ligado, as entradas das duas origens chegam sem perda | 🟢 |
| RF-18 | O aplicativo registra no log os eventos e contagens de RN-13, sem conteúdo | Must | Uma sessão com apontamento, dez botões e um ditado gera eventos com contagens e nenhuma coordenada, texto ou rótulo | 🟢 |
| RF-19 | A página mantém a tela do iPhone acesa enquanto está em uso e não responde aos gestos de navegação do navegador dentro das áreas de comando | Should | Cinco minutos de uso contínuo não apagam a tela; arrastar na área de apontamento não navega para trás nem recarrega a página | 🟡 |
| RF-20 | A sensibilidade do apontamento pelo iPhone parte dos valores já configurados para o controle e pode ser ajustada na própria página, sem editar arquivo | Could | Alterar o ajuste na página muda a velocidade do cursor na sessão em curso | 🟡 |
| RF-21 | Os gatilhos de camada L1 e L2 prendem por toque curto e soltam por toque novo, de modo que as combinações do mesmo lado da tela funcionem com um só polegar; os cliques do ponteiro, R1 e R2, não prendem | Must | Tocar L1 e inclinar o analógico esquerdo move o cursor em precisão; tocar L1 de novo devolve a velocidade normal | 🟡 |
| RF-22 | A página esconde o controle inteiro a pedido, entregando a tela ao bloco central, e lembra a escolha entre sessões | Should | Com o DualSense em uso, esconder o controle deixa o teclado completo ocupando a tela; reabrir a página mantém a escolha | 🟡 |
| RF-23 | O analógico é comandado a partir do ponto em que o dedo pousa, no vão central da cruz do seu lado, com curso até a amplitude máxima fixo em pixels | Must | Pousar o polegar no meio das setas e deslizar 64 px dá amplitude máxima; metade disso dá metade da amplitude, qualquer que seja o tamanho do círculo na tela, e deslizar por cima das setas não as aciona | 🟡 |

## 6. Requisitos Não Funcionais

| Tipo | Requisito | Evidência ou justificativa | Confidência |
|------|-----------|----------------------------|-------------|
| Desempenho | Um toque em botão chega ao aplicativo em foco em até 150 ms no percentil 95, na rede doméstica | Mesmo limite adotado para as teclas em `_reversa_forward/008-iphone-teclado-remoto/requirements.md#6. Requisitos Não Funcionais` | 🟡 |
| Desempenho | O movimento do cursor acompanha o dedo com atraso de até 60 ms no percentil 95, e a posição dos analógicos é amostrada pelo menos sessenta vezes por segundo | Acima disso o apontamento deixa de parecer contínuo; o motor de movimento do aplicativo já trabalha a 120 Hz (`_reversa_sdd/code-analysis.md#3. `pointer``) | 🟡 |
| Desempenho | Nenhuma entrada é perdida ou reordenada numa rajada de vinte eventos por segundo | Apontamento e botões ocorrem juntos durante o uso | 🟡 |
| Segurança | O controle virtual não amplia a superfície de rede: mesmas portas, mesmo pareamento, mesmo limite de um aparelho por vez e mesma recusa de origem fora da rede local | `_reversa_forward/008-iphone-teclado-remoto/interfaces/remote-keyboard-protocol.md#1. Disponibilidade` | 🟢 |
| Segurança | Um aparelho pareado passa a comandar o ponteiro e os cliques, além das teclas; por isso o recurso continua desligado por padrão e a sessão termina com o recurso, com o aplicativo ou com a inatividade | `_reversa_forward/008-iphone-teclado-remoto/requirements.md#4. Regras de negócio novas ou alteradas` (008 RN-02, RN-04) | 🟢 |
| Privacidade | Nenhum áudio passa pelo canal do teclado remoto nem pelo aplicativo, que continua sem código de captura ou de reconhecimento de fala; coordenadas do cursor e texto transcrito não vão ao log nem a disco | RN-11, RN-13; `_reversa_sdd/permissions.md#4. Restrições de acesso internas` | 🟢 |
| Permissões | Nenhuma permissão nova de sistema no Mac além da Acessibilidade já exigida, e nenhuma permissão pedida ao navegador do iPhone | RN-12; `_reversa_sdd/permissions.md#2. Matriz de permissões do sistema operacional` | 🟢 |
| Usabilidade | A digitação não perde qualidade em relação ao que existe hoje: no estado de teclado completo, as teclas mantêm a altura atual de linha e a faixa de sugestões | `Resources/RemoteKeyboard/keyboard.css`; `_reversa_sdd/addenda/009-sugestao-de-palavras.md#Resumo da entrega` | 🟢 |
| Dependência externa | O ditado depende de dois arranjos fora do aplicativo: o acorde configurado no transcritor e a entrada de áudio escolhida no Mac. Se qualquer um mudar, o botão continua enviando o acorde e o aplicativo não tem como avisar | `_reversa_sdd/addenda/prd-l01-ditado-pelo-raycast.md#Pré-requisitos externos do ditado` | 🟢 |
| Compatibilidade | Funciona no navegador padrão do iOS, sem instalar aplicativo no iPhone | `_reversa_forward/008-iphone-teclado-remoto/requirements.md#6. Requisitos Não Funcionais` | 🟡 |
| Arquitetura | As decisões do controle virtual, estado dos botões, conversão do gesto em deslocamento e soltura, ficam no núcleo testável sem hardware, e o motor de movimento, o mapeador de atalhos e a máquina da paleta são reaproveitados em vez de duplicados | `_reversa_sdd/architecture.md#2. Estilo arquitetural` | 🟢 |
| Usabilidade | Os alvos de toque têm ao menos 44 pt de lado e a página é operável com os dois polegares, com o aparelho seguro na horizontal | Persona que usa o aparelho na mão, sem apoio (`_reversa_sdd/personas.md#Persona 1: Programador de sofá`) | 🟡 |
| Observabilidade | Os eventos novos entram no log em linha com o catálogo fechado existente, sem campo de conteúdo | `_reversa_sdd/architecture.md#5. Modelo de dados em arquivo` | 🟡 |
| Compatibilidade retroativa | O teclado remoto, a sugestão de palavras, o controle físico, o editor e o arquivo de configuração continuam funcionando sem alteração de formato | `_reversa_sdd/addenda/009-sugestao-de-palavras.md#Impacto por artefato da extração` | 🟢 |

## 7. Critérios de Aceitação

```gherkin
Cenário: Apontar e clicar sem controle físico
  Dado o aplicativo aberto com a permissão de Acessibilidade e nenhum controle conectado
  E um iPhone pareado, com a página aberta
  Quando o usuário inclina o analógico de movimento até o cursor cobrir um botão na tela do Mac
  E toca o gatilho superior direito
  Então o Mac recebe um clique esquerdo na posição do cursor

Cenário: Ida e volta entre teclado e apontamento
  Dado um iPhone pareado, no estado de teclado completo, com nenhuma tecla mantida
  Quando o usuário recolhe o bloco central para o estado de apontamento e volta ao teclado completo
  Então a sessão continua a mesma, sem pedir o código de pareamento
  E nenhuma tecla, botão ou clique fica preso no Mac

Cenário: Troca de estado com entrada mantida
  Dado um iPhone pareado, no estado de apontamento, com o gatilho de clique mantido
  Quando o usuário passa ao estado de teclado completo
  Então o clique é solto no Mac antes de o teclado assumir

Cenário: Atalho configurado disparado pelo iPhone
  Dado um iPhone pareado e um botão configurado no editor como acorde
  Quando o usuário toca esse botão na página
  Então o Mac recebe o acorde configurado, como se o botão físico tivesse sido pressionado

Cenário: Camada por modificador
  Dado um iPhone pareado e um botão configurado como modificador com camada própria
  Quando o usuário mantém esse botão e toca um gatilho da camada
  Então o Mac executa a ação da camada, e não a da base

Cenário: Paleta operada pelo controle virtual
  Dado um iPhone pareado e o botão de abrir a paleta configurado
  Quando o usuário toca esse botão, navega com as direções e confirma um item
  Então a paleta abre sem tomar o foco, a seleção se move e o texto do item é digitado no aplicativo em foco

Cenário: Apontamento fino
  Dado um iPhone pareado e o cursor parado
  Quando o usuário mantém o gatilho superior esquerdo e inclina o analógico de movimento por um segundo
  Então o cursor percorre a fração configurada da distância que percorreria sem o gatilho

Cenário: Apontamento relativo pela área de toque
  Dado um iPhone pareado, com o bloco central no estado de apontamento
  Quando o usuário pousa o dedo na área de apontamento e o arrasta para a direita
  Então o cursor anda para a direita na proporção configurada
  E o simples pousar do dedo, antes do arrasto, não moveu o cursor

Cenário: Tela acesa e gestos do navegador
  Dado um iPhone pareado, com a página aberta e em uso
  Quando o usuário arrasta o dedo da borda esquerda para o centro da área de apontamento
  Então a página continua aberta, sem navegar para trás nem recarregar
  E a tela do aparelho permanece acesa durante cinco minutos de uso contínuo

Cenário: Ajuste de sensibilidade na página
  Dado um iPhone pareado, com a página aberta
  Quando o usuário aumenta a sensibilidade do apontamento na própria página
  Então o mesmo gesto passa a deslocar o cursor por uma distância maior, ainda na sessão em curso

Cenário: Rolagem
  Dado um iPhone pareado e uma janela rolável em foco no Mac
  Quando o usuário inclina o analógico de rolagem para baixo
  Então o conteúdo rola para baixo, e a inversão configurada é respeitada

Cenário: Ditado com o microfone do iPhone
  Dado um iPhone pareado, sem cabo, escolhido como entrada de áudio nas preferências do Mac
  E o campo de um agente em foco no Mac
  Quando o usuário toca o botão de ditado na página e fala uma frase
  Então o transcritor externo recebe o acorde, capta pelo microfone do aparelho e escreve a frase no campo em foco
  E nenhum áudio passa pelo canal do teclado remoto

Cenário: Microfone do iPhone indisponível
  Dado um iPhone pareado que deixou de estar disponível como entrada de áudio do Mac
  Quando o usuário toca o botão de ditado
  Então o acorde é enviado como sempre, e o transcritor capta pelo microfone que o Mac estiver usando
  E o aplicativo não trata a troca como erro, porque não conhece o dispositivo de entrada

Cenário: Alternar os estados do bloco central
  Dado um iPhone pareado, no estado de apontamento
  Quando o usuário passa ao teclado reduzido e depois ao teclado completo
  Então os analógicos e os botões seguem operáveis nos dois primeiros estados
  E nenhuma tecla, botão ou clique fica preso no Mac em nenhuma troca

Cenário: Identificação de gatilho pelo editor
  Dado um iPhone pareado e o editor de atalhos aberto no modo de identificação
  Quando o usuário toca o botão ✕ na página
  Então o editor seleciona o gatilho ✕ na figura
  E nenhuma ação mapeada é executada no Mac

Cenário: Controle físico e virtual ao mesmo tempo
  Dado um iPhone pareado e o DualSense conectado
  Quando o usuário move o cursor pelo analógico do controle e toca um botão no iPhone
  Então o movimento e o botão produzem efeito, sem que uma origem anule a outra

Cenário: Segundo controle físico não desloca o iPhone
  Dado um iPhone pareado e dois controles físicos conectados
  Quando o segundo controle é conectado e depois desconectado
  Então o controle virtual continua funcionando durante todo o período

Cenário: Conexão perdida com botão mantido
  Dado um iPhone pareado com o gatilho de clique mantido e o cursor em movimento
  Quando o iPhone é bloqueado
  Então em até 1 s o Mac solta o clique, para o movimento e zera os analógicos

Cenário: Sem permissão de Acessibilidade
  Dado um iPhone pareado e a permissão de Acessibilidade revogada no Mac
  Quando o usuário toca um botão ou inclina o analógico
  Então nada é postado no Mac
  E a página mostra "sem permissão" em até 3 s

Cenário: Recurso desligado no Mac
  Dado um iPhone com a página aberta
  Quando o usuário desliga o teclado remoto no menu do Mac
  Então a sessão termina, tudo o que estava mantido é solto e a página deixa de comandar o Mac

Cenário: Log sem conteúdo
  Dado uma sessão com apontamento, dez botões tocados e um ditado
  Quando a sessão termina
  Então o log traz as contagens da sessão
  E não traz coordenada, deslocamento, texto ditado nem endereço do aparelho

Cenário: Contexto de sugestão descartado pelo controle virtual
  Dado um iPhone pareado que acabou de digitar uma palavra no teclado completo
  Quando o usuário toca um botão do controle e volta ao teclado
  Então a faixa de sugestões volta vazia, porque o contexto foi descartado
```

## 8. Prioridade MoSCoW

| Item | MoSCoW | Justificativa |
|------|--------|---------------|
| RF-01, RF-02, RF-03 | Must | A tela única com controles nas laterais e bloco central alternável é a decisão de desenho que sustenta todo o resto |
| RF-04, RF-06, RF-07 | Must | Sem movimento, arrasto relativo e clique, o iPhone não substitui o controle, que é o pedido |
| RF-05, RF-08, RF-09, RF-10, RF-11 | Must | Rolagem, apontamento fino, atalhos, paleta e identificação são as funções que hoje se exercem pelo controle e se perderiam ao largá-lo |
| RF-12 | Must | O teclado completo já existe e não pode regredir: perder os rótulos da fonte de entrada ou as sugestões seria desfazer as features 008 e 009 |
| RF-13 | Must | O teclado reduzido é o que permite manter teclado e controles na mesma tela sem encolher alvos de toque |
| RF-14 | Must | O ditado é parte explícita do pedido, e o que a feature entrega é o botão no controle virtual; o arranjo de áudio ficou no microfone do Mac, pela P-01 |
| RF-15, RF-16, RF-17, RF-18 | Must | Estado visível, soltura, coexistência e log sem conteúdo preservam invariantes já confirmadas do legado |
| RF-19 | Should | Tela acesa e gestos contidos melhoram muito o uso, mas o conjunto funciona sem eles |
| RF-20 | Could | O ajuste de sensibilidade na página é conveniência; os valores do arquivo já servem de partida |
| RF-21 | Must | Sem a prisão, a precisão do cursor e as camadas do lado esquerdo são inalcançáveis na tela, o que derrubaria RN-08 e RN-01 do legado na origem do iPhone |
| RF-22 | Should | Some com o controle quando ele atrapalha, mas o conjunto funciona sem o botão |
| RF-23 | Must | Sem separar comando de desenho, a sensibilidade do analógico muda a cada ajuste de arranjo, e o polegar gasta atenção procurando o centro em vez de olhar a tela do Mac |
| RNF de desempenho do cursor | Should | Abaixo do limite o apontamento ainda funciona, porém desagrada; a medição depende do portão manual |
| Botões físicos de volume do iPhone como teclas do controle | Won't | A página aberta no navegador não recebe esses botões: eles são tratados pelo sistema do aparelho e não chegam como evento ao conteúdo. Só um aplicativo instalado no iPhone teria acesso, e o projeto não distribui aplicativo (`_reversa_sdd/prd.md#5. Não-objetivos (out)`). O papel pretendido para eles, L1 e L2, fica com os gatilhos desenhados no topo das colunas laterais, que prendem por toque curto (RF-21) |
| Captura de voz pela própria página | Won't | Pediria permissão de microfone ao navegador e poderia enviar áudio a serviço externo, o que contraria a restrição de privacidade vigente; o ditado permanece com o transcritor externo |
| Espelhamento da tela do Mac no iPhone | Won't | Fora do escopo, como já decidido na 008 |
| Aplicativo nativo para o iPhone | Won't | O projeto não distribui pela App Store (`_reversa_sdd/prd.md#5. Não-objetivos (out)`) |

## 9. Esclarecimentos

### Sessão 2026-09-20

- **Q:** Com o iPhone substituindo o controle, as duas faces continuam em telas separadas e alternadas, ou existe disposição em que os botões convivam com o teclado na mesma tela?
  **R:** Tela única. O teclado fica junto dos analógicos, com os gatilhos superiores nas quinas (L1 e L2 à esquerda, R1 e R2 à direita), Options e Create mais ao centro e o bloco de teclado no meio. O usuário anexou duas referências visuais de controle em tela, com analógicos flutuantes nos cantos inferiores e botões de ação orbitando o analógico direito.
- **Q:** O controle virtual precisa cobrir as funções que hoje dependem do controle físico dentro do próprio aplicativo?
  **R:** Sim, incluindo o modo de identificação do editor de atalhos (opção b). A tela de alvos não é objetivo da feature, embora passe a funcionar por consequência, já que a entrada do iPhone chega ao roteador pelo mesmo caminho da entrada do controle.
- **Q:** Como o ditado deve capturar a voz no iPhone?
  **R:** Mantendo o arranjo atual: o botão continua enviando o acorde ao transcritor externo, e a diferença é poder escolher, nas preferências do Mac, o microfone do próprio iPhone como entrada de áudio. Nem a página nem o aplicativo capturam som, e nenhum áudio trafega pelo canal do teclado remoto.
- **Q:** O que é o bloco central, o "teclado cut"?
  **R:** Centro alternável (opção c), com os controles sempre nas laterais e três estados no meio: área de apontamento, teclado reduzido e teclado completo. O usuário sugeriu ainda aproveitar os botões físicos de volume do iPhone para teclas modificadoras como L1 e L2; a sugestão não é realizável numa página aberta no navegador, porque esses botões são tratados pelo sistema do aparelho e não chegam ao conteúdo, de modo que o papel fica com os gatilhos desenhados nas quinas (registrado como Won't na seção 8).
- **Q:** Quais botões entram na face de controle?
  **R:** Todos os dezoito, com hierarquia de tamanho (opção c). O mapeamento padrão do projeto atribui papel a praticamente todos, e cortar qualquer um obrigaria a reconfigurar o editor só para usar o iPhone.
- **Q:** A área de toque relativa para o cursor continua?
  **R:** Sim, no estado em que o centro não mostra teclado (opção c). O analógico resolve percursos longos e o arrasto relativo resolve o ajuste fino, como já ocorre no controle físico.

## 10. Lacunas

Nenhuma dúvida bloqueia o plano. Restam dois pontos para verificação no hardware e no desenho, que cabem como sondas da fase de investigação:

- 🟡 O microfone do iPhone continua disponível como entrada de áudio do Mac enquanto o aparelho está em uso ativo, com a tela ligada e a página aberta? O vínculo entre os dois dispositivos costuma pressupor o aparelho em repouso. Reprovada a sonda, é preciso decidir entre manter o microfone do Mac para o ditado ou rever o arranjo de áudio.
- 🟡 A composição exata do teclado reduzido e da faixa de botões secundários depende de medida na tela real: é preciso confirmar que os alvos de toque permanecem com ao menos 44 pt em cada estado do bloco central, num iPhone na horizontal.

## 11. Histórico de alterações

| Data | Alteração | Autor |
|------|-----------|-------|
| 2026-09-20 | Versão inicial gerada por `/reversa-requirements` | reversa |
| 2026-09-20 | Seis esclarecimentos integrados por `/reversa-clarify`: tela única com bloco central alternável, cobertura do modo de identificação, ditado pelo arranjo de áudio do sistema, conjunto completo de botões e área de toque no estado sem teclado | reversa |
