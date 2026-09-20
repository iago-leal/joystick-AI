# Onboarding: controle virtual no iPhone

> Feature: `010-joystick-virtual-iphone`
> Data: 2026-09-20
> Roteiro de verificação no hardware, a ser preenchido durante o `/reversa-coding`

## 1. Pré-requisitos

| Item | Como confirmar |
|------|----------------|
| Permissão de Acessibilidade concedida ao aplicativo | Ajustes do Sistema, Privacidade e Segurança, Acessibilidade |
| Identidade do teclado remoto instalada e confiada no iPhone | Feita uma vez na feature 008; a página abre sem aviso de conexão insegura |
| Mac e iPhone na mesma rede doméstica | A página abre pelo endereço `.local` do Mac |
| Transcritor configurado com o acorde do botão de ditado, ⌘M por padrão | Ajustes do transcritor, seção de ditado |
| Entrada de áudio do Mac para o ditado | Microfone do próprio Mac, **não** o do iPhone: escolher o aparelho aciona a Continuity Camera, que toma a tela dele e derruba o controle (P-01, D-09 revista) |
| Compilação e instalação | `swift build -c release`, `./scripts/test.sh`, `JOYSTICK_SIGN_IDENTITY="JoystickAI Local Signing" ./scripts/build-app.sh`, `./scripts/check-signature.sh` |

## 2. PM-0, sondas

Preencher com o resultado de cada sonda de `investigation.md` §7. Reprovada a P-01, parar e devolver ao usuário a decisão sobre o arranjo de áudio antes de escrever o roteiro final do ditado.

| Sonda | Resultado | Observação |
|-------|-----------|------------|
| P-01 microfone do aparelho | **Reprovada** | O áudio até chega, mas escolher o iPhone como entrada aciona junto a Continuity Camera e ocupa a tela do aparelho, que precisa estar mostrando o controle; os dois recursos vêm no mesmo pacote do sistema e não se separam. Decisão do usuário, tomada na execução: o ditado fica com o microfone do Mac, como antes da feature. RF-14 reescrito, D-09 revista; nenhum código mudou, só o pré-requisito do §1 |
| P-02 atraso do apontamento | **Aprovada com ressalvas** | Sem atraso que impeça o uso, mas com três queixas de conforto, todas atendidas na execução: o eixo Y da área de apontamento estava invertido (defeito, corrigido); a curva do analógico começava lenta demais e acelerava demais (`stickExponent` baixado de 2,0 para 1,3 na configuração, sem código); e o arranjo da tela não caía bem na mão (D-02 revista, ver abaixo) |
| P-03 medidas da tela | **Não executada** | Falta cabo para o inspetor do Safari. Fica pendente; o arranjo mudou depois do PM-0, de modo que a medição, quando houver cabo, deve ser feita sobre o desenho novo |
| P-04 gestos e tela acesa | **Aprovada** | Nenhuma navegação nem recarga no arrasto de borda, e a tela permaneceu acesa |

### Emendas aprovadas no PM-0

| # | Achado | Decisão | Efeito |
|---|--------|---------|--------|
| E-01 | Eixo Y da área de apontamento invertido: dedo para cima levava o cursor para baixo | Corrigir | Defeito da página, não do protocolo: `controller.js` enviava a coordenada no sentido da tela, e o `TouchpadTracker` do Mac a invertia de novo. A página passou a enviar o Y crescendo para cima, como o touchpad do DualSense entrega, conforme o `data-delta.md` §2 já dizia. Dois passos novos no roteiro fora do navegador |
| E-02 | Curva do analógico desagradável nos extremos | Ajustar a configuração | `pointer.stickExponent` de 2,0 para 1,3 em `~/.config/joystick-ai/config.json`, com cópia de segurança em `config.json.bak-010`. Vale para as duas origens, como o `data-delta.md` §1 previu. A seção `pointer` só é lida na abertura (003 RN-10, TD-08), de modo que o valor passou a valer na reinstalação |
| E-03 | Arranjo da tela incômodo de segurar na horizontal | Reorganizar, D-02 revista | Gatilhos e secundários numa faixa no alto, atravessando a tela, em três grupos separados por vãos: L2, L1, L3 à esquerda; PS, Create, Options e Painel no meio; R3, R1, R2 à direita. Direcional e faces no topo das colunas, analógicos no pé, na altura dos polegares. Barra de estado e sugestões encolhida de uma linha de teclas para 38 px, e para 24 px com a faixa oculta |

| E-04 | Com o aparelho na horizontal só os polegares tocam a tela, e o esquerdo não pode estar em L1 e no analógico ao mesmo tempo: a precisão do cursor e as camadas do lado esquerdo ficavam inalcançáveis | Prender por toque e realocar, D-15 revista | Os gatilhos de camada L1 e L2 prendem por toque curto, abaixo de 300 ms, e soltam por toque novo, no mesmo laranja dos modificadores presos do teclado; segurar com o dedo continua funcionando. R1 e R2 ficaram de fora a pedido do usuário: são os cliques do ponteiro, e clique preso atrapalha mais do que ajuda. Eles saíram da faixa do alto para o topo da coluna do seu lado, a um toque do polegar que comanda aquele analógico, e a faixa ficou com L3, R3 e os secundários. Toda soltura desfaz a prisão: troca do bloco central, controle que se esconde, queda do canal e fim de sessão |
| E-05 | Com o DualSense na mão, o controle virtual só atrapalha, e o teclado fica espremido no meio da tela | Acrescentar o interruptor, D-16 nova | Um botão na barra esconde a faixa e as colunas e entrega a tela inteira ao bloco central, que continua ciclando entre apontamento, teclado reduzido e teclado completo; a escolha fica em `remoteKeyboardPrefs.controls`. Nenhuma mensagem nova: o controle solta o que mantinha pelos mesmos `btn`, `stick` e `pad` de sempre |

| E-06 | O analógico continuava incômodo depois de E-02: difícil de acertar e manter, saturando cedo demais e com resposta desigual ao longo do curso. A emenda E-04 tinha agravado o quadro, porque encolher o círculo para caber os gatilhos encolheu junto o curso útil, de uns 65 px para 32 a 44 px | Separar comando de desenho, com pesquisa | O analógico deixou de ser o círculo e passou a ser a área que o contém: o toque em qualquer ponto dela fixa ali a origem, e o desenho vai ao encontro do dedo, sem sair da própria área. O curso até a amplitude máxima virou uma distância fixa de 64 px, independente do tamanho desenhado, e o dedo pode escorregar além dele com a saída saturada. `pointer.stickExponent` foi a 1,0, resposta proporcional, agora que a saturação precoce não mascara mais a curva. A pesquisa confirmou o caminho: o `GCVirtualController` da Apple oferece `actsAsTouchpad` no próprio elemento de analógico, e a HIG registra que analógico desenhado na tela não se compara ao físico |

| E-07 | Com a origem nascendo onde o dedo pousa, pousar baixo deixava o polegar sem tela para descer, e o analógico no pé da coluna era justamente onde isso acontecia | Levar o analógico para dentro da cruz | O analógico de cada lado passou a ocupar o vão central do seu agrupamento: o esquerdo no meio das setas, o direito no meio de ✕, ○, □ e △. O polegar já vive ali, há curso para todos os lados e o dedo desliza por cima dos botões vizinhos sem acioná-los, porque o toque foi capturado pelo analógico. A coluna ficou com duas peças em vez de três, os gatilhos e a cruz, centradas na altura, e o que sobra virou respiro. A cruz cresceu de 142 px para 150 px |

| E-08 | O alvo do analógico, restrito à casa central da cruz, era pequeno demais para ser achado sem olhar o aparelho | Aumentar o disco sem encolher as setas | O círculo do analógico transborda a casa e vira o fundo da cruz inteira, com 110 px de diâmetro, cobrindo também os quatro cantos, que estavam vazios. As setas continuam com a casa inteira de 47 px, porque ficam acima do disco no empilhamento e recebem o toque que cai nelas. Na prática, mirar o meio da cruz e errar um pouco ainda acerta o analógico, e só cair sobre uma seta aciona a seta |
| E-09 | O passo 5 do PM-1 passou com ressalva: o arrasto na área de apontamento movia o cursor a distância certa, mas aos pulos | Coalescer por quadro e medir a área por série | O `touchmove` do iOS entrega mais amostras do que o Mac transforma em movimento contínuo, e cada uma virava uma mensagem e um `move` imediato, de modo que a rajada chegava como salto; o analógico já não tinha o defeito porque drena por `requestAnimationFrame` desde a origem. O arrasto passou a usar o mesmo mecanismo, com no máximo um envio por quadro e por dedo, e pousar e levantar seguem imediatos, porque deles dependem o começo e o fim da série. Junto, a caixa da área deixou de ser pedida a cada amostra, o que forçava recálculo de layout no Safari no meio do gesto: agora é medida quando a série começa, o que também cobre giro do aparelho, troca de bloco central e controle escondido |
| E-10 | O reteste do passo 5 depois da E-09 continuou travado, ainda que menos: coalescer na página regularizou o que sai do iPhone, mas não o que chega ao Mac | Alisar o arrasto remoto no laço de 120 Hz | O touchpad do controle entrega centenas de amostras por segundo em cadência estável, e por isso aplicar cada delta na chegada basta; o iPhone entrega no máximo uma por quadro e ainda por Wi-Fi, de modo que elas chegam em rajada e em vazio e o cursor transcreve o jitter da rede. O `InputEvent` passou a dizer se a entrada é remota, e o arrasto remoto deixou de virar movimento na chegada: entra num planador (`TouchGlide`), que gasta uma fração do que falta andar a cada tick, com constante de tempo de 22 ms. O temporizador de 120 Hz, antes ligado só pelos analógicos, passa a ser ligado também pelo arrasto remoto e a se desligar quando o planador esvazia. O touchpad físico segue pelo caminho de antes, sem atraso acrescentado |

## 3. PM-1, roteiro no hardware

Executar com o aplicativo instalado, o teclado remoto ligado pelo menu e o iPhone pareado. Cada passo tem resultado esperado; anotar o que divergir.

A coluna "Resultado" distingue três estados. **Aprovado** é o passo que o usuário executou e relatou, com data.
_Observado no uso_ é o comportamento que ocorreu durante a sessão de trabalho, sem conferência dirigida: vale como
indício, não como verificação, e um passo assim volta à fila se alguém duvidar dele. Em branco é o passo que
ninguém tocou.

**Estado em 2026-09-20: os 40 passos aprovados, nenhum reprovado e nenhuma ressalva pendente.** O roteiro
correu inteiro no aparelho em um dia, com dez emendas pelo caminho, das quais a E-09 e a E-10 nasceram de um
único passo, o 5. Dois desvios ficam registrados, e nenhum dos dois reprova o que foi testado: a coexistência
com controle físico (21 e 22) correu com o Ipega, porque o DualSense não estava à mão, de modo que o cruzamento
do touchpad físico com o apontamento do iPhone, que dividem o mesmo rastreador de dedos, ficou sem cobertura; e
o passo 28 foi executado por mim, lendo `~/Library/Logs/joystick-ai/`, por ser leitura de arquivo, e não prova
de uso.

Os passos nomeiam os botões como eles aparecem escritos na tela, L1, L2, R1 e R2, e não pela posição que ocupariam
num controle físico: na página os quatro são retângulos lado a lado na faixa do alto de cada coluna, L2 e L1 à
esquerda, R1 e R2 à direita, com os dois "1" voltados para o centro (emenda E-04). A marcação corrente também vive numa lista operável em
`~/.claude/tarefas/joystick-AI.md`, pela skill `tarefas`, e numa página marcável em
https://claude.ai/artifact/BMWo3XasnbVtX3eNRX9Svu; esta tabela é o registro de referência, e as outras duas são
onde o usuário marca enquanto testa.

| # | Passo | Resultado esperado | Resultado |
|---|-------|--------------------|-----------|
| 1 | Abrir a página no iPhone, na horizontal, sem nenhum controle físico ligado | A página abre no estado guardado do bloco central, com analógicos e botões visíveis nas laterais e o indicador de conexão verde | **Aprovado** (2026-09-20), reconfirmado no arranjo das emendas E-06 a E-08 |
| 1b | Pousar o polegar no vão central do direcional, onde fica o analógico esquerdo | Nada se move até o dedo deslizar, e o círculo acompanha o ponto de pouso dentro do vão (emendas E-06 e E-07) | **Aprovado** (2026-09-20), já com o disco ampliado da E-08 |
| 1b2 | De olhos na tela do Mac, pousar o polegar no meio da cruz várias vezes seguidas | O analógico responde em todas, inclusive quando o dedo cai num dos cantos da cruz; só cair sobre uma seta aciona a seta (emenda E-08) | **Aprovado** (2026-09-20), com a ressalva da §4 |
| 1c | Deslizar o analógico por cima das setas, até passar delas | O cursor anda e nenhuma seta é acionada: o toque pertence ao analógico desde o pouso | **Aprovado** (2026-09-20) |
| 2 | Inclinar o analógico esquerdo em cada uma das quatro direções | O cursor anda na direção correspondente, com o Y para cima movendo o cursor para cima | **Aprovado** (2026-09-20), com `pointer.stickExponent` em 1,0 |
| 2b | No estado de apontamento, deslizar o dedo para cima e para baixo na área | O cursor acompanha o dedo nos dois sentidos (conferência da emenda E-01 do PM-0) | **Aprovado** (2026-09-20) |
| 2d | Deslizar o polegar bem além do curso, até o pé da tela | A velocidade satura e não cresce mais; soltar devolve o cursor ao repouso | **Aprovado** (2026-09-20), conferência da E-06 |
| 3 | Inclinar o analógico esquerdo até o limite e soltar | O cursor atravessa a tela e para em menos de um piscar após o dedo sair | **Aprovado** (2026-09-20) |
| 4 | Inclinar o analógico direito para baixo e para cima numa janela rolável | O conteúdo rola nos dois sentidos, respeitando a inversão configurada | **Aprovado** (2026-09-20) |
| 5 | Passar o bloco central ao estado de apontamento e arrastar o dedo pela área | O cursor acompanha o arrasto; pousar o dedo não move nada | **Aprovado** (2026-09-20) depois das emendas E-09 e E-10; passou por ressalva no caminho, com o arrasto travado, e é o que a §4 conta |
| 6 | Tocar R1 sobre um item | Clique esquerdo no item | **Aprovado** (2026-09-20) |
| 7 | Tocar duas vezes rápido R1 sobre uma pasta | A pasta abre, o que confirma o duplo clique | **Aprovado** (2026-09-20) |
| 8 | Manter R1 e inclinar o analógico esquerdo sobre um texto | O texto é selecionado pelo arraste | **Aprovado** (2026-09-20) |
| 9 | Tocar R2 sobre a mesa | Menu de contexto, o que confirma o clique direito | **Aprovado** (2026-09-20) |
| 10 | Manter L1 e inclinar o analógico esquerdo | O cursor anda visivelmente mais devagar | **Aprovado** (2026-09-20) |
| 10b | Tocar rápido L1, tirar o dedo e inclinar o analógico esquerdo | L1 fica aceso em laranja e o cursor anda devagar, com o polegar livre no analógico (emenda E-04) | **Aprovado** (2026-09-20) |
| 10c | Tocar L1 de novo | O laranja apaga e o cursor volta à velocidade normal | **Aprovado** (2026-09-20) |
| 10d | Tocar rápido R1 sobre um item | Clique simples, sem laranja e sem prisão: os cliques do ponteiro não prendem | **Aprovado** (2026-09-20) |
| 11 | Tocar ✕, ○, □ e △ com um campo de texto em foco | As ações do mapeamento padrão ocorrem: Return, Esc, apagar e Tab | **Aprovado** (2026-09-20); as teclas devolvidas são as que o usuário configurou |
| 12 | Manter L1 e tocar ✕ | O texto configurado na camada é digitado, com Return ao fim | **Aprovado** (2026-09-20) |
| 12b | Prender L1 por toque e, com ele aceso, tocar ✕ | O texto da camada é digitado, o que confirma que a camada vale com o gatilho preso, e não só com o dedo em cima | **Aprovado** (2026-09-20) |
| 13 | Tocar PS | A paleta abre no Mac, sem tomar o foco | **Aprovado** (2026-09-20) |
| 14 | Com a paleta aberta, tocar as direções e depois ✕ | A seleção se move e o item é digitado no aplicativo em foco | **Aprovado** (2026-09-20) |
| 15 | Tocar Create | O Mission Control abre | **Aprovado** (2026-09-20) |
| 16 | Passar o bloco central ao teclado completo e digitar "ação" | O texto sai com acento, e a faixa de sugestões funciona como antes | **Aprovado** (2026-09-20) |
| 17 | Voltar ao estado de apontamento com uma tecla ainda mantida | A tecla é solta no Mac antes da troca, sem repetição presa | **Aprovado** (2026-09-20) |
| 18 | No estado de teclado reduzido, executar um atalho de edição com ⌘ e tocar o analógico esquerdo em seguida | Atalho executado e cursor movendo, sem trocar de estado | **Aprovado** (2026-09-20) |
| 19 | Abrir o editor de atalhos, entrar no modo de identificação e tocar ✕ na página | O editor seleciona o gatilho ✕ na figura, e nada é executado no Mac | **Aprovado** (2026-09-20) |
| 20 | Tocar o botão de ditado e falar uma frase, com a entrada de áudio do Mac no **microfone do próprio Mac** | A frase é transcrita no campo em foco. O microfone do aparelho saiu do roteiro pela P-01 | **Aprovado** (2026-09-20) |
| 21 | Ligar o controle físico e usar as duas origens alternadamente | As duas funcionam, sem que uma anule a outra | **Aprovado** (2026-09-20) com o Ipega; o DualSense não estava à mão, de modo que o cruzamento do touchpad físico com o apontamento do iPhone, que dividem o mesmo rastreador de dedos, ficou sem cobertura |
| 22 | Com o controle físico mantendo um modificador de camada, tocar um gatilho na página | A ação da camada é executada, o que confirma a união dos botões pressionados | **Aprovado** (2026-09-20) com o Ipega, L1 preso no controle e ✕ tocado na tela |
| 23 | Bloquear o iPhone com R1 mantido e o cursor em movimento | Em até um segundo o clique é solto, o movimento para e nada fica preso | **Aprovado** (2026-09-20) |
| 24 | Desbloquear o iPhone | A página reconecta sozinha, sem pedir o código | **Aprovado** (2026-09-20) |
| 25 | Revogar a permissão de Acessibilidade com a página aberta | Em até três segundos a página mostra "sem permissão", e nenhum toque produz efeito | **Aprovado** (2026-09-20) |
| 26 | Devolver a permissão | A página volta a "conectado" e o controle volta a funcionar | **Aprovado** (2026-09-20) |
| 26b | Com um gatilho preso, tocar o botão Controle na barra | O gatilho solta antes de sumir, o controle desaparece e o bloco central ocupa a tela inteira (emenda E-05) | **Aprovado** (2026-09-20) |
| 26c | Com o controle oculto, passar ao teclado completo, digitar, voltar ao apontamento e recarregar a página | O teclado ocupa a tela toda, a área de apontamento vira um trackpad grande e o controle continua oculto depois da recarga | **Aprovado** (2026-09-20) |
| 26d | Tocar Controle de novo | Faixa e colunas voltam, no mesmo estado do bloco central | **Aprovado** (2026-09-20) |
| 27 | Desligar o teclado remoto pelo menu do Mac | A sessão termina, tudo o que estava mantido é solto e a página deixa de comandar | **Aprovado** (2026-09-20). |
| 28 | Abrir o log da sessão | Aparecem as contagens de teclas, botões, cliques e sugestões, e o estado do bloco central; nenhuma coordenada, tecla ou texto | **Aprovado** (2026-09-20). Log lido por mim: 16 botões, 5 cliques, 43 teclas, 1 sugestão e os estados do bloco central, sem nenhuma coordenada, tecla ou texto. |

## 4. Observações da rodada

> Espaço para o relato do usuário, emendas aprovadas durante a execução e o que ficou por fazer.

**Arrasto travado no estado de apontamento, passo 5, resolvido em 2026-09-20.** O passo passou primeiro com
ressalva, "funciona, mas é travado": o cursor ia à distância certa e o pouso do dedo não deslocava nada, que é
o que o passo cobra, mas o acompanhamento não era contínuo. A causa era dupla, e cada emenda pegou uma metade.
A E-09 regularizou o que sai do iPhone, coalescendo as amostras por quadro, e o reteste devolveu "ainda está um
pouco travado" — resposta que localizou o resto do problema na chegada, e não na saída: as amostras atravessam
o Wi-Fi e chegam ao Mac em rajada e em vazio. A E-10 alisa essa chegada no laço de 120 Hz do apontamento. Com
as duas, o usuário aprovou o passo. Fica o registro do método, que vale para o que vier: uma fonte remota de
movimento tem duas cadências a cuidar, a de amostragem e a de entrega, e corrigir só a primeira melhora sem
resolver.

**Analógico, arranjo aceito em 2026-09-20, com ressalva.** Depois das emendas E-06 a E-08, o usuário testou no
aparelho e decidiu manter o desenho atual, dizendo em seguida que "há um espaço para mudanças no futuro". Ou seja:
aceito para seguir, não encerrado. O que sobrou por decidir, se e quando voltar ao assunto:

- O tamanho do disco, hoje 110 px, e o do alvo das setas, hoje 47 px, disputam a mesma cruz de 150 px. Alargá-la
  custaria largura do teclado completo, que é o outro inquilino da tela.
- Os dois números que governam a sensação continuam fáceis de mexer: o curso, hoje 64 px em `controller.js`, e
  `pointer.stickExponent`, hoje 1,0 na configuração do usuário.
- O modo touchpad do analógico, que a Apple oferece como `actsAsTouchpad` no `GCVirtualController`, ficou como
  alternativa não experimentada; está registrado entre as opções descartadas de D-17.
- A sonda P-03, que mede os alvos com o inspetor do Safari, segue pendente por falta de cabo, e agora incide sobre
  este desenho, não sobre o que o PM-0 examinou.
