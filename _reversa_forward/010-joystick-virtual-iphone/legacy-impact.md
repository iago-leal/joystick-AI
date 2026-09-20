# Impacto no legado: controle virtual no iPhone

> Feature: `010-joystick-virtual-iphone`
> Data: `2026-09-20`
> Cenário: **legado** (`_reversa_sdd/architecture.md` e `_reversa_sdd/domain.md` presentes)
> Política de edição do legado na execução: `allowLegacyEdits: true`, `allowedPaths` **vazio**, ou seja, liberação irrestrita do projeto inteiro. Nenhum caminho foi recusado.
> Escopo executado: T001 a T032 e T034 a T035 concluídas; T033 aguarda o PM-1, que depende do hardware e do relato do usuário. O PM-0 foi executado e produziu três emendas, e a avaliação do arranjo antes do PM-1 produziu outras duas; as cinco estão no `onboarding.md` §2 e refletidas neste documento.

## 1. Arquivos afetados

| Arquivo afetado | Componente | Tipo | Severidade | Justificativa |
|-----------------|------------|------|------------|---------------|
| `Sources/JoystickCore/Remote/VirtualController.swift` | `controller-input` (tipos de valor) | componente-novo | LOW | Enumerações e estruturas do controle virtual; nada persistido, nada compartilhado com o controle físico |
| `Sources/JoystickCore/Remote/VirtualControllerMachine.swift` | `controller-input` | componente-novo | MEDIUM | Origem nova de `InputEvent`, com idempotência, vigia e contagens próprias; puro, sem dependência de framework |
| `Sources/JoystickCore/Input/CombinedPressed.swift` | `controller-input` | componente-novo | LOW | Valor sem estado que soma os dois conjuntos de botões; não altera a máquina do controle ativo |
| `Sources/JoystickCore/Remote/RemoteKeyboardMessage.swift` | `app-shell` (canal remoto) | delta-de-contrato-externo | HIGH | Quatro mensagens de cliente (`btn`, `stick`, `pad`, `mode`) e uma de servidor (`mode`); o decodificador passa a recusar e a limitar campos novos |
| `Sources/JoystickCore/Log/LogEventCatalog.swift` | `diagnostics-log` | delta-de-contrato-externo | MEDIUM | `remote.disconnected` ganha `buttons` e `clicks`; `remote.mode` é evento novo. `logSchema` continua 1 |
| `Sources/JoystickAIPoC/Remote/VirtualControllerActions.swift` | `app-shell` | componente-novo | MEDIUM | Executor na fila `input`: aplica zona morta, entrega ao roteador, mantém o conjunto do contexto e roda o vigia |
| `Sources/JoystickAIPoC/Controller/InputSink.swift` | `controller-input` | regra-alterada | HIGH | `InputContext` ganha `virtualPressed` e `pressedAll`; o que o aplicativo consulta deixa de ser só o hardware |
| `Sources/JoystickAIPoC/Pointer/MotionLoop.swift` | `pointer` | regra-alterada | HIGH | Três leituras de `registry.pressed` viraram `pressedAll`: precisão de L1 e rolagem de precisão passam a valer para as duas origens |
| `Sources/JoystickAIPoC/Targets/TargetSession.swift` | `targets-analysis` | regra-alterada | MEDIUM | `l1Held` da tentativa passa a considerar L1 vindo do iPhone |
| `Sources/JoystickAIPoC/Remote/RemoteKeyboardService.swift` | `app-shell` | regra-alterada | HIGH | Roteia as mensagens novas, confirma o estado do bloco central, registra `remote.mode` e soma as contagens no encerramento |
| `Sources/JoystickAIPoC/Remote/RemoteKeyboardActions.swift` | `app-shell` | regra-alterada | LOW | O `switch` passa a conhecer as mensagens do controle, das quais só anota a atividade para o vigia do teclado |
| `Sources/JoystickAIPoC/Remote/RemotePageListener.swift` | `app-shell` | regra-alterada | LOW | Serve `controller.js` pelo mesmo caminho, tipo e cabeçalhos dos demais recursos |
| `Sources/JoystickAIPoC/App/AppDelegate.swift` | `app-shell` | regra-alterada | MEDIUM | Monta o executor do controle virtual e o entrega ao serviço, ao portão e ao ciclo de vida |
| `Sources/JoystickAIPoC/App/Lifecycle.swift` | `app-shell` | regra-alterada | MEDIUM | O encerramento solta também o controle virtual |
| `Sources/JoystickAIPoC/App/InjectionGate.swift` | `injection` | regra-alterada | MEDIUM | A suspensão da injeção solta também o controle virtual |
| `Resources/RemoteKeyboard/index.html` | `app-shell` (página remota) | regra-alterada | HIGH | Passa de teclado a faixa de secundários no alto mais três colunas, cada lateral com gatilhos, cruz e analógico, e bloco central de três estados; ganha o botão que esconde o controle |
| `Resources/RemoteKeyboard/keyboard.css` | `app-shell` | regra-alterada | HIGH | Faixa do alto, colunas de três peças com o analógico elástico no pé, gatilho preso, área de apontamento, barra encolhida e as regras por `data-center` e `data-controls` |
| `Resources/RemoteKeyboard/keyboard.js` | `app-shell` | regra-alterada | HIGH | Teclado dentro do bloco central, teclado reduzido novo, soltura na troca de estado, canal compartilhado por `window.RemoteKeyboard` e a preferência `controls` |
| `Resources/RemoteKeyboard/controller.js` | `app-shell` | componente-novo | HIGH | Desenho e toque do controle virtual, amostragem por quadro, área de apontamento, gatilhos aderentes, controle que se esconde, preferências e tela acesa |
| `Tests/JoystickCoreTests/VirtualControllerMachineTests.swift` | testes | componente-novo | LOW | 21 casos da máquina nova |
| `Tests/JoystickCoreTests/CombinedPressedTests.swift` | testes | componente-novo | LOW | 5 casos da união |
| `Tests/JoystickCoreTests/RemoteKeyboardMessageTests.swift` | testes | regra-nova | LOW | Decodificação e recusa das mensagens do controle |
| `Tests/JoystickCoreTests/LogEventCatalogTests.swift` | testes | regra-alterada | LOW | Amostras de `remote.disconnected` e `remote.mode`, com as chaves proibidas do controle |
| `Tests/JoystickCoreTests/RemoteKeyboardAssetsTests.swift` | testes | regra-alterada | LOW | Passa a cobrir os dois scripts, o arranjo novo da página, a prisão dos gatilhos e o estado sem controle |
| `_reversa_forward/010-joystick-virtual-iphone/actions.md` | artefato do Reversa | — | — | Notas de execução e marcação das ações |
| `~/.config/joystick-ai/config.json` | configuração do usuário, fora do repositório | regra-alterada | LOW | `pointer.stickExponent` de 2,0 para 1,3, pela emenda E-02 do PM-0; cópia de segurança em `config.json.bak-010`. Dado do usuário, não versionado, alterado com o consentimento dele |

## 2. Diff conceitual por componente

### `controller-input`

O componente deixa de ter uma origem única. Até aqui, `ActiveControllerRegistry` era ao mesmo tempo o cadastro dos controles e a verdade sobre o que está pressionado, e essas duas funções coincidiam porque só o hardware produzia botão. Com o iPhone, elas se separam: o cadastro continua descrevendo apenas o hardware, com a mesma fila, a mesma promoção e a mesma soltura sintética, e a verdade sobre o pressionado passa a ser a união, calculada em `InputContext.pressedAll` a partir de `CombinedPressed`.

A escolha preserva 001 RN-01 ao pé da letra: o iPhone não disputa a vaga de controle ativo, não aparece na fila, não emite conexão nem desconexão e não altera a figura do editor. O preço é que quem quisesse saber "o que o hardware mantém" precisa agora dizê-lo explicitamente, lendo `registry.pressed`; quem quer saber "o que o usuário mantém" lê `pressedAll`. Os três pontos do aplicativo que faziam a segunda pergunta foram migrados; nenhum fazia a primeira.

### `pointer`

Nenhuma regra de apontamento foi reescrita. `Normalization`, `StickKinematics`, `TouchpadTracker`, `PointerMotionEngine` e `ScrollMapper` seguem intactos, e é justamente por isso que a feature é curta: o iPhone produz os mesmos `InputEvent` que a leitura do controle produz, e tudo o que vinha depois continua valendo sem saber da diferença.

Uma sutileza mereceu cuidado. O motor de movimento documenta receber analógicos já com a zona morta aplicada, e decide acender o temporizador comparando os eixos com zero. Se a amostra do iPhone chegasse crua, o tremor do dedo dentro da zona morta manteria o temporizador aceso e arrastaria o cursor devagar, sem que nenhuma regra escrita tivesse sido violada. A zona morta passou então a ser aplicada em `VirtualControllerActions`, com os mesmos valores de `pointer` e pelo mesmo `Normalization.stick` que `AxisTouchReader` usa, deixando a máquina do núcleo pura como o plano pedia.

### `injection`

O portão ganhou um terceiro cliente. A suspensão por perda de permissão já soltava as teclas do teclado remoto e os botões de mouse; passa a soltar também os botões do iPhone, pelo mesmo motivo de RI-04: com a permissão de volta, nada pode ter ficado pendurado no meio do caminho.

### `app-shell` e o canal remoto

A sessão continua uma só. Um código, um pareamento, um token, um vigia de inatividade, uma recusa de segundo aparelho, e agora duas máquinas alimentadas pelo mesmo fluxo de mensagens. Toda mensagem passa pelas duas: o controle trata as suas e o teclado, das do controle, só anota que a sessão está viva. Essa dupla anotação é o que impede o efeito perverso de o usuário jogar com o controle virtual por um minuto e o teclado soltar sozinho as teclas que ele mantinha, ou o contrário.

O vigia do controle precisou existir à parte. O da `RemoteKeyboardMachine` só dispara quando ela própria mantém tecla, de modo que um iPhone mudo com botão apertado não seria socorrido por ele. A `VirtualControllerMachine` ganhou `holdsAnything`, `noteMessage` e `tick` simétricos, e o executor roda o mesmo temporizador de 250 ms na mesma fila.

### `diagnostics-log`

O catálogo continua fechado e sem conteúdo. Nenhum nome de botão, nenhuma posição de analógico, nenhuma coordenada de dedo e nenhum estado por evento de movimento entraram no log. O que entrou foram duas contagens no encerramento da sessão e um evento de estado do bloco central, ambos verificados pela suíte, que agora também recusa as chaves `b`, `s`, `f`, `p` e `m` em qualquer fábrica.

### Página remota

É a mudança de maior superfície e a de menor risco para o Mac, porque nada do que a página faz escapa da validação do canal. O teclado completo continua idêntico ao de antes, montado da mesma mensagem `layout`, com as mesmas larguras e os mesmos rótulos; ele apenas mudou de lugar, para dentro do bloco central. O teclado reduzido é desenho novo, e a faixa de sugestões da feature 009 seguiu intocada na barra superior.

## 3. Preservadas

Regras 🟢 do `_reversa_sdd/domain.md` que continuam valendo, verificadas pelas suítes existentes, que passaram sem alteração:

- **001 RN-01** (um só controle ativo, primeiro DualSense conectado): o iPhone não entra na fila nem disputa a vaga. `ActiveControllerRegistryTests` intacta.
- **001 RN-04** (nenhuma desconexão deixa entrada presa): a soltura sintética do hardware não mudou, e a do iPhone segue o mesmo formato, em ordem estável de `ButtonID`.
- **001 RN-08** (precisão de L1 sem outro botão): continua exata, agora sobre a união; `CombinedPressedTests` fixa o comportamento nas quatro combinações.
- **001 RN-11 / 003 RN-05** (mapeamento fixo do ponteiro, R1 e painel à esquerda, R2 à direita): a `ClickStateMachine` não foi tocada e recebe os botões do iPhone pelo mesmo caminho, inclusive o clique com dois detentores.
- **001 RN-12** (sem coordenadas no log): reforçada, com chaves proibidas novas.
- **002 RN-01 e RN-04** (PS abre a paleta; abrir a paleta solta o que estava mantido): o PS do iPhone passa pelo mesmo roteador e produz o mesmo efeito.
- **003 RN-01** (ação decidida no pressionar e mantida até soltar): intacta; é ela que exige o botão de camada mantido, e por isso nenhum botão do controle virtual fica preso por toque (D-15).
- **008 RN-10 e RN-14** (soltura em qualquer fim de caminho; ordem entre as origens): estendidas ao controle virtual sem exceção, pela mesma fila `input`.
- **009 RN-03 e D-06** (descarte do contexto de sugestões quando o ponto de escrita pode ter mudado): valia para o botão do controle e passou a valer para o do iPhone sem código novo, porque `InputRouter.onControllerButtonDown` dispara para qualquer `buttonDown` não sintético.

## 4. Modificadas

Nenhuma regra 🟢 foi removida. Três tiveram o alcance alargado, sem mudança de enunciado, e uma quarta ganhou uma origem a mais no mesmo enunciado:

| Regra | Como era | Como ficou |
|-------|----------|------------|
| **001 RN-08** (precisão com L1) | O conjunto consultado era `registry.pressed`, alimentado só pelo controle ativo | O conjunto é a união; L1 do iPhone reduz a velocidade, e L1 do controle com qualquer botão do iPhone a desliga, como desligaria com dois botões do controle |
| **003 RN-01 e RN-02** (camadas por botão mantido) | A camada só podia ser decidida por botão do hardware | Qualquer das duas origens mantém a camada, e as combinações entre elas funcionam |
| **004 RN-05** (L1 mantido na tentativa da tela de alvos) | `l1Held` descrevia só o hardware | Descreve o que o usuário mantinha, de qualquer origem; uma corrida feita pelo iPhone passa a registrar `l1Held` verdadeiro |
| **008 RN-13 / D-18** (`remote.disconnected` sem conteúdo) | Campos `reason`, `keys` e `suggestions` | Acrescenta `buttons` e `clicks`, contagens sem identificar nada; a proibição de conteúdo segue verificada |

A DV-03 do `domain.md`, já registrada como 🟡 ("a precisão desliga durante arraste com L1+R1, e a spec não trata o caso"), ganha uma variação nova: agora isso vale também para L1 do controle com R1 do iPhone. A divergência não piorou nem melhorou; apenas passou a ter mais maneiras de acontecer, e continua sem tratamento na spec.

## 5. Emendas do PM-0

O PM-0 correu em 2026-09-20, com o aplicativo instalado e o iPhone pareado, e mudou três coisas depois de o código estar pronto. A apuração por sonda está no `onboarding.md` §2; o que interessa ao impacto no legado é o seguinte.

**E-01, eixo Y da área de apontamento.** Era defeito, não decisão: a página calculava `y` direto de `clientY`, que cresce para baixo, e o `TouchpadTracker` do Mac invertia o delta de novo, na linha que documenta que "o eixo Y do touchpad cresce para cima; o da tela, para baixo". As duas inversões se somavam e o cursor andava ao contrário do dedo. A correção ficou toda em `controller.js`, do lado da página, porque é ela que deve entregar a coordenada no formato do touchpad do DualSense, como o `data-delta.md` §2 já descrevia; nada do núcleo mudou. Vigiada por O010.

**E-02, curva do analógico.** Ajuste de configuração, sem uma linha de código: `pointer.stickExponent` de 2,0 para 1,3. Confirma, na prática, o que a feature supunha em projeto: a cinemática é uma só, `StickKinematics`, e vale igualmente para as duas origens. A seção `pointer` continua lida apenas na abertura do aplicativo, de modo que o valor passou a valer na reinstalação. Vigiada por O011.

**E-03, arranjo da página.** Revisão de D-02 por ergonomia, depois de o usuário segurar o aparelho na horizontal: gatilhos e secundários numa faixa que atravessa o alto da tela, em três grupos; direcional e faces no topo das colunas laterais; analógicos no pé, na altura dos polegares; barra de estado e sugestões encolhida de uma linha de teclas para 38 px. Alcança `index.html`, `keyboard.css` e a tabela `TRAY` de `controller.js`, e obrigou `RemoteKeyboardAssetsTests` a acompanhar os identificadores novos. Como o desenho mudou depois da sonda, a P-03, que mediria os alvos com o inspetor do Safari e não pôde ser feita por falta de cabo, incide agora sobre este arranjo e segue pendente em O003.

**E-04, gatilhos aderentes e realocados.** A avaliação do arranjo antes do PM-1 derrubou uma premissa do desenho: com o aparelho na horizontal, segurado por trás, só os polegares tocam a tela, de modo que a faixa do alto não é alcançável pelos indicadores como se supunha. Os gatilhos desceram para o topo da coluna do seu lado, e L1 e L2 passaram a prender por toque curto, abaixo de 300 ms, soltando por toque novo; R1 e R2 ficaram de fora, por serem os cliques do ponteiro. Isso revê D-15, que proibia prisão por toque no controle, e é o que devolve as combinações do mesmo lado, entre elas a precisão do cursor de 001 RN-08 e as camadas de 003 RN-01. A prisão é inteiramente da página: o Mac recebe um `btn` de descida sem a subida correspondente, isto é, um botão mantido comum, e nenhuma regra do núcleo muda. Toda soltura já existente a desfaz. Alcança `index.html`, `keyboard.css` e `controller.js`.

**E-05, controle que se esconde.** Um botão novo na barra esconde a faixa e as colunas e entrega a tela ao bloco central, para quem está com o DualSense na mão. Antes de sumir, o controle solta botões, gatilhos presos, analógicos e dedos da área de apontamento, pelas mensagens de sempre. Não há mensagem nova nem alteração no Swift: o Mac não precisa saber que o desenho mudou, e `remote.mode` continua descrevendo só o bloco central. A preferência entrou em `remoteKeyboardPrefs.controls`, ao lado das outras.

**E-06, analógico de origem dinâmica.** A queixa persistia depois de E-02, e a apuração mostrou que E-04 a tinha agravado: o curso do analógico era o raio desenhado, de modo que encolher o círculo para caber os gatilhos encolheu junto a resolução do comando, de uns 65 px de curso para 32 a 44 px. O analógico passou a ser a área que contém o círculo, a origem nasce onde o dedo pousa e o curso virou uma distância fixa de 64 px. Isso torna explícito o que D-05 já pressupunha: a página mede como quiser, contanto que entregue a posição de −1 a 1; zona morta, curva e sensibilidade continuam no Mac, em `Normalization` e `StickKinematics`, intocados. Pela mesma razão, `pointer.stickExponent` foi a 1,0 na configuração do usuário, sem código. A pesquisa que orientou a decisão está resumida no `onboarding.md` §2.

**E-07, analógico dentro da cruz.** A origem dinâmica trouxe um efeito de borda: com o analógico no pé da coluna, pousar o dedo baixo deixava pouca tela para descer. O analógico de cada lado foi então para o vão central do seu agrupamento, entre as setas à esquerda e entre as faces à direita, onde há curso para todos os lados e o polegar já está. O `controller.js` move o elemento para lá ao montar o desenho, de modo que o documento continua declarando um só analógico por lado. A coluna passou a ter duas peças, centradas na altura. Nenhuma mensagem, nenhuma regra e nenhum arquivo do Mac mudaram.

**E-08, disco maior que a casa.** O alvo do analógico, preso à casa central, media 47 px e era difícil de achar sem olhar o aparelho. O disco passou a transbordar a casa e a servir de fundo para a cruz inteira, com 110 px, cobrindo os quatro cantos que estavam vazios; os botões ficam acima dele por `z-index` e continuam recebendo o toque que cai neles, de modo que os 44 px de alvo das setas seguem intactos. Mudança apenas de `keyboard.css`, mais o limite de deslocamento do desenho em `controller.js`, que passou da casa para a cruz.

Nenhuma das oito alterou regra 🟢 do legado nem acrescentou arquivo à seção 1, salvo a configuração do usuário, e os testes continuaram verdes: 414 casos em 42 suítes, dois a mais que antes das emendas de arranjo.

## 6. O que não foi tocado

`ControllerReader`, `ButtonReader`, `AxisTouchReader`, `ExtendedReportActivator`, `TransportResolver`, `DualSenseReport`, `SwitchProReport`, `ControllerModel`, `StartupAdoption`, toda a configuração, todo o editor, toda a paleta e todo o `targets-analysis` além da linha de `l1Held`. A leitura do controle físico não sabe que o controle virtual existe, e é assim que se pretende manter.
