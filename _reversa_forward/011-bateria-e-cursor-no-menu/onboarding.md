# Onboarding: carga do controle e ciclo do menu da barra

> Feature: `011-bateria-e-cursor-no-menu`
> Data: 2026-09-20
> Roteiro de verificação no hardware, a ser preenchido durante o `/reversa-coding`

## 1. Pré-requisitos

| Item | Como confirmar |
|------|----------------|
| Permissão de Acessibilidade concedida ao aplicativo | Ajustes do Sistema, Privacidade e Segurança, Acessibilidade |
| DualSense disponível, por cabo e sem cabo | Os dois transportes importam: a carga por cabo costuma vir com estado de carregamento, e sem cabo com estado descarregando |
| Ipega disponível | Necessário para a sonda P-03; sem ele, a sonda fica pendente e a frase de indisponibilidade segue sem confirmação no hardware |
| iPhone pareado como controle virtual | Necessário apenas para o passo de coexistência; a feature 008 precisa estar instalada, como nas features anteriores |
| Controle com carga baixa, ou disposição de esperar | O passo do destaque de carga baixa exige carga igual ou inferior a 15%; na prática, deixar um controle descarregar até lá, ou verificar no limite alcançável e registrar o desvio |
| Compilação e instalação | `swift build -c release`, `./scripts/test.sh`, `JOYSTICK_SIGN_IDENTITY="JoystickAI Local Signing" ./scripts/build-app.sh`, `./scripts/check-signature.sh` |
| Log em modo de depuração | Abrir o aplicativo com `--debug`, necessário para as sondas P-01 e P-02 |

> Antes de qualquer mudança, registrar nas notas de execução o número de testes verdes de partida, como as features anteriores fazem na primeira ação. A feature 010 fechou com 427 testes em 43 suítes.

## 2. PM-0, sondas

As três sondas de `investigation.md` §3 correm **antes** de a correção do menu ser escrita. Nenhuma exige código novo. Reprovada ou surpreendente qualquer uma delas, parar e devolver ao usuário a decisão sobre o desenho antes de seguir.

| Sonda | Resultado | Observação |
|-------|-----------|------------|
| P-01 a condução volta sozinha? | **Não** | E o menu **fica aberto** durante todo o período morto. Essa observação de um segundo é a que derrubou D-10 como cura: o método de fechamento só dispara depois do clique físico, quando a condução já voltou por conta dele |
| P-02 o app continua postando durante o defeito? | Resolvida pela P-04 | A primeira leitura do log me levou a concluir que o app deixava de ser chamado por inteiro. Estava errado: os silêncios eram inatividade sua, não o defeito. A P-04 mediu direto e corrigiu |
| P-03 o Ipega informa carga? | **Sim** | `controller.connected` com `charge: 60` e `chargeState: discharging`. O risco do `roadmap.md` §9, que dava probabilidade alta de o Ipega não expor carga, **não se confirmou**. A confirmação visual no editor fica no passo 8 do PM-1 |
| P-04 a consulta direta ao analógico fica fresca? | **Não; os botões, sim** | 156 tiques com o menu aberto: `stickX` e `stickY` em 0,000 em todos eles, enquanto `r1 down` e `r1 up` entraram pelos manipuladores normais. O sistema toma os eixos e deixa os botões passarem |
| P-05 o direcional chega durante o menu? | **Chega, e vaza** | Direcional, ○ e ✕ entregues, cada um disparando o acorde da camada base no aplicativo **atrás** do menu. Defeito que não estava no relato de campo e que a sonda achou de raspão |
| P-06 a correção funciona no hardware? | **Sim** | Realce desce pelo direcional, ✕ confirma, ○ sai, nada vaza para trás. `menu.cycle` registrou `keys=14`, `keys=6` e `keys=0` em três ciclos |

> As sondas P-04, P-05 e P-06 não estavam previstas. Nasceram porque a P-01 contrariou D-10 e a decisão voltou ao usuário, que optou por medir antes de escolher entre manter o menu e trocá-lo por painel próprio. O detalhe está em `investigation.md` §3.

### Procedimento da P-01

1. Abrir o aplicativo com `--debug` e confirmar que o cursor responde ao controle
2. Conduzir o cursor até o ícone do aplicativo na barra de menus e clicar nele **pelo controle**, anotando qual botão foi usado
3. Confirmar que o defeito ocorreu: tentar mover o cursor pelo analógico e pelo touchpad
4. **Não tocar no trackpad.** Esperar sessenta segundos, mexendo no analógico a cada dez segundos, e anotar se e quando a condução voltou
5. Se não voltar, trocar o aplicativo em foco **pelo teclado** e testar de novo
6. Só então clicar fisicamente, para confirmar que essa é mesmo a saída

**Anotar também:** o menu permanece visivelmente aberto durante o período morto, ou fechou? Essa observação de um segundo elimina metade do espaço de hipóteses.

### Procedimento da P-02

1. Repetir os passos 1 a 3 da P-01
2. Durante o período morto, mover o analógico esquerdo saindo do repouso e tocar o touchpad, pelo menos três vezes cada
3. Encerrar o aplicativo e abrir o arquivo da sessão em `~/Library/Logs/joystick-ai/`
4. Localizar o instante do clique no ícone e verificar se eventos de postagem do ponteiro continuam aparecendo depois dele

**Como ler:** postagens continuam significa que o aplicativo faz a parte dele e o sistema retém; postagens cessam significa problema interno, e a suspeita passa para o temporizador de movimento e para o estado do injetor. Lembrar que os ticks de 120 Hz não registram, apenas os eventos com origem, o que é o motivo de o passo 2 pedir saídas do repouso.

### Procedimento da P-03

1. Conectar o Ipega como único controle e confirmar que ele é o ativo
2. Abrir o editor de atalhos e anotar o que aparece na área da carga
3. Repetir com o DualSense, para comparação

## 3. PM-1, roteiro no hardware

Preencher cada passo com aprovado, reprovado ou não executado, e a observação quando houver.

### 3.1 Carga no editor

| # | Passo | Resultado esperado | Resultado |
|---|-------|--------------------|-----------|
| 1 | Com o DualSense conectado e carregado, abrir o editor pelo ícone da barra | A porcentagem aparece no cabeçalho, sem rolar a tela | _a preencher_ |
| 2 | Ler a tela a três metros, sentado onde se usa o aplicativo | O número é legível sem esforço | _a preencher_ |
| 3 | Comparar a porcentagem com a que o sistema mostra para o mesmo controle | Os dois números coincidem, ou diferem por arredondamento de um ponto | _a preencher_ |
| 4 | Ligar o cabo com o editor aberto | Em até 60 s a indicação passa a distinguir o controle que carrega | _a preencher_ |
| 5 | Desligar o controle com o editor aberto | A área passa a dizer que não há controle conectado, sem mostrar zero | _a preencher_ |
| 6 | Religar o controle | A porcentagem volta sem fechar e reabrir a janela | _a preencher_ |
| 7 | Com dois controles conectados, desligar o ativo | A carga exibida passa a ser a do controle promovido | _a preencher_ |
| 8 | Com o Ipega como ativo, abrir o editor | Conforme a P-03: a porcentagem, ou a frase de indisponibilidade, nunca "0%" | _a preencher_ |

### 3.2 Carga na paleta

| # | Passo | Resultado esperado | Resultado |
|---|-------|--------------------|-----------|
| 9 | Abrir a paleta pelo controle | A porcentagem aparece no rodapé do painel, legível a três metros | _a preencher_ |
| 10 | Percorrer a lista inteira com ↓ até dar a volta | A seleção passa pelos itens e pela entrada fixa, e **nunca** pela carga | _a preencher_ |
| 11 | Confirmar um item com ✕ | O texto é digitado no aplicativo em foco, como antes | _a preencher_ |
| 12 | Reabrir a paleta | A seleção começa no último confirmado, como antes; o rodapé não deslocou o índice | _a preencher_ |
| 13 | Abrir a paleta e não tocar em nada por 60 s | A paleta fecha sozinha, como antes | _a preencher_ |
| 14 | Com a paleta aberta, digitar no aplicativo em foco pelo teclado físico | O foco continua no aplicativo; o painel não o tomou | _a preencher_ |
| 15 | Abrir a paleta numa tela pequena, se houver segunda tela disponível | O painel cabe na área visível, com o rodapé dentro | _a preencher_ |

### 3.3 Carga baixa

| # | Passo | Resultado esperado | Resultado |
|---|-------|--------------------|-----------|
| 16 | Com o controle em 15% ou menos, abrir o editor | O valor aparece destacado, por cor **e** por símbolo | _a preencher_ |
| 17 | Abrir a paleta no mesmo estado | O destaque aparece igualmente, e é legível a três metros sobre o fundo escuro do painel | _a preencher_ |
| 18 | Confirmar que nada além do visual acontece | Nenhum som, nenhuma janela, nenhuma mudança no que o controle faz | _a preencher_ |
| 19 | Com o controle acima de 15%, repetir | Sem destaque | _a preencher_ |

### 3.4 Ciclo do menu

> Reescrita pela emenda E-01. O roteiro original supunha que a condução voltasse **depois** do menu, e as sondas
> mostraram que o problema é **durante**: o sistema toma os analógicos enquanto o rastreamento dura. O que se
> verifica agora é a navegação por botão, que é a correção de E-03, e a ausência do vazamento de acordes.

| # | Passo | Resultado esperado | Resultado |
|---|-------|--------------------|-----------|
| 20 | Conduzir o cursor pelo controle e clicar no ícone da barra, pelo controle | O menu abre | _a preencher_ |
| 21 | Com o menu aberto, apertar ↓ do direcional três vezes | O realce desce pelos itens, um por aperto | _a preencher_ |
| 22 | Apertar ↑ duas vezes | O realce sobe, um por aperto | _a preencher_ |
| 23 | Apertar ○ | O menu fecha sem escolher nada | _a preencher_ |
| 24 | Reabrir, descer até "Editar atalhos" e apertar ✕ | O editor abre | _a preencher_ |
| 25 | Conferir o aplicativo que estava atrás do menu | **Nada** foi digitado nele pelos apertos do direcional, de ○ e de ✕ | _a preencher_ |
| 26 | Fechado o menu, mover o cursor pelo analógico | O cursor volta a se mover, sem tocar no trackpad | _a preencher_ |
| 27 | Clicar num aplicativo em foco pelo controle | O clique produz efeito | _a preencher_ |
| 28 | Conferir que nenhum arraste começou sozinho e que o primeiro clique vale como simples | Nada é selecionado, arrastado nem aberto por duplo clique acidental | _a preencher_ |
| 29 | Repetir 20 a 26 abrindo o menu pelo **trackpad**, com o controle em uso | Mesmo resultado | _a preencher_ |
| 30 | Repetir 20 a 26 com o Ipega como controle ativo | Mesmo resultado | _a preencher_ |
| 30b | Repetir 20 a 26 com o iPhone em coexistência com o controle físico | Mesmo resultado; o apontamento pelo iPhone também volta | _a preencher_ |
| 30c | Abrir e fechar o menu dez vezes seguidas | Nenhuma degradação; a navegação funciona todas as vezes | _a preencher_ |
| 30d | Ler o `menu.cycle` do log da sessão | Um registro por fechamento, com `keys` acompanhando quantas teclas de navegação foram enviadas | _a preencher_ |

### 3.5 Não regressão

| # | Passo | Resultado esperado | Resultado |
|---|-------|--------------------|-----------|
| 31 | Abrir o editor pelo controle, pela entrada fixa da paleta | A janela recebe o foco, sem falha de ativação no log | _a preencher_ |
| 32 | Fechar o editor | O foco volta ao aplicativo que estava à frente | _a preencher_ |
| 33 | Exercitar atalhos de várias camadas, com modificador segurado | Comportamento idêntico ao de antes da feature | _a preencher_ |
| 34 | Ler o log da sessão inteira | Eventos novos presentes e bem formados; nenhuma coordenada, texto ou acorde | _a preencher_ |
| 35 | Conferir o volume do log após uma hora de editor aberto | No máximo alguns registros de carga, não um por minuto | _a preencher_ |

## 4. Emendas aprovadas

_Preencher durante a execução, no formato das features anteriores: número, achado, decisão, efeito._

| # | Achado | Decisão | Efeito |
|---|--------|---------|--------|
| E-01 | Não há estado retido no fim do ciclo do menu: o sistema toma os analógicos enquanto o rastreamento dura e deixa os botões passarem | D-11 falsificada por inteiro; D-10 redirecionada da abertura, e não do fechamento | T026, T027 e T028 marcadas não aplicáveis; `investigation.md` §3 reescrito |
| E-02 | O roteador precisa saber, na fila `input`, que o menu está rastreando | Estado no contexto de entrada, ligado pela abertura e desligado pelo fechamento, atravessando de forma assíncrona | `InputSink.swift` |
| E-03 | Com o menu aberto, o direcional dispara acordes no aplicativo atrás dele, e o menu fica inalcançável pelo controle | Traduzir botão em tecla de navegação enquanto o rastreamento durar, e engolir o que não tem tradução | `InputRouter.swift`; o vazamento de acordes acabou junto |
| E-04 | Os campos de `menu.cycle` supunham a hipótese falsificada | `released`, `resynced` e `timerRestarted` trocados por `keys` e `durationMs` | `LogEventCatalog.swift`, `interfaces/diagnostic-log.md` |
| E-05 | A sonda P-04 foi respondida | Evento `menu.probe` retirado do catálogo | `LogEventCatalog.swift` |

## 5. Notas de execução

_Preencher durante o `/reversa-coding`: número de testes antes e depois, desvios do roteiro, passos não executados e o motivo._
