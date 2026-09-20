# Roadmap: controle virtual no iPhone

> Identificador: `010-joystick-virtual-iphone`
> Data: `2026-09-20`
> Requirements: `_reversa_forward/010-joystick-virtual-iphone/requirements.md`
> Confidência: 🟢 CONFIRMADO, 🟡 INFERIDO, 🔴 LACUNA

## 1. Resumo da abordagem

O caminho é curto porque o legado já separa decisão de execução. O roteador `InputRouter` trata entradas normalizadas sem saber a origem, e o `MotionLoop` já converte analógico esquerdo, analógico direito e toque em movimento, rolagem e arrasto relativo. Basta, então, uma origem nova que produza os mesmos `InputEvent` na mesma fila `input`, e todo o comportamento confirmado do controle passa a valer para o iPhone sem duplicação de regra: cliques, camadas de atalho, paleta, identificação no editor e soltura.

O transporte reaproveita o canal cifrado da feature 008: mesma sessão, mesmo pareamento, mesmo vigia de inatividade, acrescido de três mensagens de cliente e uma de servidor. A página deixa de ser só teclado e passa a um desenho em grade, com colunas de controle nas laterais e um bloco central de três estados, de modo que analógicos, botões e teclado convivam na mesma tela, como o usuário pediu.

O único ponto do núcleo que não absorve a origem nova sem mudança é o conjunto de botões pressionados, hoje guardado pelo `ActiveControllerRegistry` e restrito ao controle ativo. Ele passa a ser consultado como união entre o físico e o virtual, o que preserva a máquina do controle ativo intacta e mantém a precisão de L1, a tela de alvos e a decisão de camada funcionando com qualquer combinação das duas origens.

O ditado não ganha uma linha de código: o botão continua enviando o acorde do transcritor, e o que muda é um arranjo do sistema, descrito no roteiro de instalação.

## 2. Princípios aplicados

Não existe `.reversa/principles.md` neste projeto, de modo que não há princípios declarados a confrontar. Valem, no lugar deles, as invariantes confirmadas na extração, tratadas como restrições de projeto ao longo deste roadmap.

| Princípio | Como a feature se relaciona | Status |
|-----------|------------------------------|--------|
| (nenhum declarado) | Em substituição, a feature se sujeita a: núcleo puro sem dependência de framework (`_reversa_sdd/architecture.md#2. Estilo arquitetural`), pipeline serializado na fila `input`, log sem conteúdo (001 RN-12, 003 RN-14) e nenhuma permissão nova de sistema (`_reversa_sdd/permissions.md#2. Matriz de permissões do sistema operacional`) | respeita |

## 3. Decisões técnicas

| ID | Decisão | Justificativa | Alternativas descartadas | Confidência |
|----|---------|----------------|--------------------------|-------------|
| D-01 | O controle virtual viaja no canal já existente do teclado remoto, na mesma sessão e no mesmo pareamento, com quatro mensagens novas de cliente (`btn`, `stick`, `pad` e `mode`) e uma de servidor (`mode`) | Uma sessão significa um código, um vigia, uma soltura e uma recusa de segundo aparelho; abrir outro canal duplicaria pareamento, identidade e política de origem descritas em `_reversa_forward/008-iphone-teclado-remoto/interfaces/remote-keyboard-protocol.md#1. Disponibilidade` | Canal separado por porta; segunda página servida à parte | 🟢 |
| D-02 | **Revista no PM-0 e emendada por E-04.** A página passa a um desenho em grade: faixa no alto com L3, R3 e os secundários (PS, Create, Options e o clique do painel); abaixo, três colunas. Cada lateral traz, de cima para baixo, os dois gatilhos do seu lado, o agrupamento em cruz (direcional à esquerda, faces à direita) e o analógico no pé. O bloco central tem três estados, `pointer`, `compact` e `full`, e a barra de estado e sugestões está encolhida | Atende à tela única pedida sem sobrepor controles às teclas, o que inviabilizaria a digitação. A primeira revisão veio do uso: com o aparelho na horizontal, os polegares alcançam o pé da tela, de modo que os analógicos ficam embaixo. A segunda corrigiu a premissa de que os indicadores alcançariam o alto da tela: na prática o aparelho é segurado por trás e só os polegares tocam, o que tornava a faixa do alto um destino caro para os gatilhos | Versão original, com analógico no topo da coluna e faixa secundária sob o bloco central; gatilhos nas pontas da faixa do alto (PM-0); analógicos flutuantes sobre o teclado; duas páginas alternadas | 🟢 |
| D-03 | O núcleo ganha `VirtualControllerMachine`, máquina pura que traduz as mensagens do canal em `InputEvent` idênticos aos que a leitura do controle produz, com idempotência por botão, conversão do gatilho em botão e soltura geral | Mantém a decisão no núcleo testável sem hardware, como manda `_reversa_sdd/architecture.md#2. Estilo arquitetural`, e garante que nenhuma regra de apontamento ou de atalho seja reescrita | Traduzir direto no executor do app, sem núcleo; chamar `ButtonActions` e `MotionLoop` diretamente | 🟢 |
| D-04 | O controle virtual não entra no `ActiveControllerRegistry`. O `InputContext` passa a expor `pressedAll`, união entre os botões do controle ativo e os do virtual, e `MotionLoop`, `ButtonActions` e `TargetSession` consultam essa união | `press(_:from:)` só aceita o controle ativo (`ActiveControllerRegistry.swift:60`); pôr o virtual na fila faria os botões dele serem ignorados, e pô-lo como ativo bloquearia o controle físico, contra RN-01 do requirements | Registrar o iPhone como controle na fila; promover o iPhone a ativo; manter dois conjuntos sem união, aceitando que L1 do iPhone não reduza a velocidade | 🟢 |
| D-05 | A página envia posição bruta: analógicos em coordenadas de −1 a 1 com o eixo Y positivo para cima, e o dedo da área de apontamento em posição normalizada com fase. Zona morta, curva de velocidade, sensibilidade e subpixel continuam no Mac | Preserva `Normalization`, `StickKinematics` e `TouchpadTracker` como fonte única das regras, e mantém os valores de `pointer` do arquivo de configuração valendo para as duas origens | Calcular velocidade na página; enviar deslocamento já em pontos de tela | 🟢 |
| D-17 | **Nova (E-06).** O que a página mede para chegar àquelas coordenadas é assunto dela: a origem do analógico nasce onde o dedo pousa, dentro de uma área maior que o círculo, e o curso até a amplitude máxima é uma distância fixa de 64 px, não o raio desenhado. O círculo é referência visual e vai ao encontro do dedo, sem sair da sua área | Separa comando de desenho, o que D-05 já exigia sem dizer: com o curso preso ao raio, encolher o círculo por causa do arranjo mudava a sensibilidade sem que nenhuma decisão tivesse sido tomada, e foi o que E-04 fez. A origem dinâmica poupa o polegar de procurar o centro, prática corrente nos controles virtuais e reconhecida pela própria Apple, que oferece `actsAsTouchpad` no elemento de analógico do `GCVirtualController` | Manter a origem no centro e só aumentar o curso; adotar o modo touchpad de vez, abandonando o analógico; deixar o curso proporcional ao desenho, como era | 🟡 |
| D-18 | **Nova (E-07).** O analógico de cada lado ocupa o vão central do seu agrupamento em cruz: o esquerdo entre as setas, o direito entre as faces. A coluna fica com duas peças, gatilhos e cruz, centradas na altura | No pé da coluna, a origem dinâmica encostava na borda inferior e o polegar ficava sem tela para descer. No meio da cruz há curso para todos os lados, o polegar já está ali, e o dedo pode deslizar por cima das setas sem acioná-las, porque o toque foi capturado no pouso. De quebra, devolve à coluna a altura que o analógico consumia | Analógico no pé, como estava; origem fixa no centro, que devolveria o movimento ao pousar fora do centro; analógico flutuante em qualquer ponto da coluna | 🟡 |
| D-19 | **Nova (E-08).** O disco do analógico transborda a casa central e é o fundo da cruz inteira, 110 px de diâmetro; os botões ficam acima dele por `z-index` e recebem o toque que cai neles | A casa central sozinha dava um alvo de 47 px, pequeno para ser achado sem olhar. Aproveitar os quatro cantos vazios da cruz mais que dobra o alvo sem tirar nada das setas, que mantêm os 44 px exigidos. O custo é que um toque destinado a uma seta e errado para o canto move o cursor em vez de não fazer nada, o que é preferível a digitar a seta errada | Encolher as setas para alargar o centro, que as levaria abaixo de 44 px; alargar a coluna, que estreitaria o teclado completo; manter o alvo pequeno | 🟡 |
| D-06 | O analógico é amostrado no quadro de animação da página, no máximo sessenta vezes por segundo, e só se o valor mudou; o repouso é enviado uma vez e encerra a série | Sessenta amostras por segundo bastam para o temporizador de 120 Hz do Mac, que integra por tempo real (`MotionLoop.swift:72-84`), e evitam encher o canal, cujo quadro é limitado a 1 KiB | Enviar a cada evento de toque, sem agregação; enviar a 120 Hz | 🟡 |
| D-07 | L2 e R2 chegam como botões, sem valor analógico | A página não tem curso de gatilho; o limiar de 0,5 de `Normalization.isTriggerPressed` não teria o que medir, e o mapeador trata os dois como botões | Simular curso pela pressão do toque; enviar valor fixo de 1,0 como eixo | 🟢 |
| D-08 | Trocar o estado do bloco central solta o que o estado anterior mantinha: ao sair do teclado, as teclas e os modificadores; ao sair do apontamento, os botões e os cliques. A soltura é pedida pela página e executada pelas máquinas já existentes | Cumpre RN-08 do requirements e reaproveita a soltura geral que a `RemoteKeyboardMachine` e a máquina nova já precisam ter para o vigia | Deixar o estado anterior mantido; soltar só no fim da sessão | 🟢 |
| D-09 | **Revista no PM-0.** O ditado não recebe código novo: o botão mapeado para R3 envia o acorde do transcritor, e o áudio vem do **microfone do próprio Mac**, como antes da feature. O microfone do iPhone foi descartado pela P-01: escolhê-lo como entrada aciona junto a Continuity Camera, que toma a tela do aparelho, justamente a tela que precisa estar mostrando o controle; os dois recursos vêm no mesmo pacote do sistema e não se separam | Mantém a decisão registrada em `_reversa_sdd/addenda/prd-l01-ditado-pelo-raycast.md`, sem áudio no aplicativo, sem permissão nova e sem tráfego de som no canal. O risco estava previsto na seção 9 e o desfecho é o que ela antecipava | Microfone do iPhone pela Continuity, reprovado na P-01; captura de voz pela página; gravação no iPhone com transcrição no Mac | 🟢 |
| D-10 | O log ganha contagens na linha de encerramento da sessão remota, `buttons` e `clicks`, e um evento de estado para a troca do bloco central. Movimento do cursor não gera evento novo | Preserva o catálogo fechado e a proibição de conteúdo (001 RN-12, 003 RN-14); `pointer.posted` já cobre o que precisa ser observado do apontamento | Registrar cada botão do iPhone; registrar amostras do analógico | 🟢 |
| D-11 | O estado do bloco central e o ajuste de sensibilidade ficam em `localStorage`, ao lado das preferências de sugestão da feature 009, dentro de `try` | Mantém o padrão já estabelecido em `keyboard.js` e devolve a página ao estado em que o usuário a deixou | Guardar no Mac, no arquivo de configuração; não guardar | 🟢 |
| D-12 | A página segue sem `innerHTML`, `outerHTML`, `insertAdjacentHTML`, `eval` e `Function(`, e o desenho novo é montado por elementos e `textContent`, como a suíte `RemoteKeyboardAssetsTests` já exige | A suíte existente falharia de outro modo, e a restrição é a defesa que a 008 adotou para o conteúdo servido | Montagem por template com interpolação de texto | 🟢 |
| D-13 | O controle virtual não emite conexão nem desconexão de controle: a fila de controles físicos, o menu e a figura do editor seguem descrevendo só o hardware | Evita reescrever a máquina do controle ativo (`_reversa_sdd/state-machines.md#1. Controle conectado`) e a leitura de modelo introduzida pela feature 007 | Apresentar o iPhone como um `ControllerModel` novo | 🟢 |
| D-14 | A tela do aparelho é mantida acesa pelo recurso de bloqueio de tela do navegador quando ele existir, com degradação silenciosa caso não exista ou seja negado | Requisito RF-19 é Should; falhar em silêncio é preferível a pedir permissão ou quebrar a página | Reproduzir vídeo mudo em laço para impedir o bloqueio | 🟡 |
| D-15 | **Revista por E-04.** O direcional, as faces e os gatilhos usam a mesma marcação de estado do teclado (`pressed`, `held`, `latched`). Os dois gatilhos de camada, L1 e L2, prendem por toque curto, abaixo de 300 ms, e soltam por toque novo; segurar continua valendo. Os demais botões não prendem, R1 e R2 inclusive | O argumento original valia para o controle físico, em que o indicador mantém o gatilho enquanto o polegar comanda o analógico. Na tela só há dois polegares, e o da esquerda não pode estar em L1 e no analógico ao mesmo tempo: sem a prisão, a precisão do cursor (001 RN-08) e as camadas do lado esquerdo (003 RN-01) ficariam inalcançáveis. A prisão é da página, não do Mac, que continua vendo um botão mantido comum. Ficou restrita aos gatilhos de camada: R1 e R2 são os cliques do ponteiro, e clique preso é armadilha; além disso o arraste de seleção usa R1 num polegar e o analógico no outro, de modo que nunca precisou de prisão | Nenhuma prisão, como na decisão original; prisão nos quatro gatilhos; prisão em todos os botões; prisão que solta sozinha no próximo botão, à maneira das teclas de aderência | 🟢 |
| D-16 | **Nova (E-05).** Um botão da barra esconde a faixa e as colunas, entregando a tela inteira ao bloco central; a escolha fica em `remoteKeyboardPrefs.controls` e vale entre sessões. Antes de sumir, o controle solta tudo o que mantinha | É o arranjo de quem está com o DualSense na mão e quer do iPhone só o teclado, ou uma área de apontamento grande. Nada disso pede mensagem nova: a soltura sai como os `btn`, `stick` e `pad` de sempre, e o Mac não precisa saber que o desenho mudou | Quarto estado do bloco central, que gastaria um botão a menos mas impediria a área de apontamento em tela cheia; nenhuma opção, deixando o controle sempre visível | 🟡 |

## 4. Premissas

Nenhuma premissa foi adotada a partir de marcador `[DÚVIDA]`: o `requirements.md` foi fechado pelo `/reversa-clarify` sem dúvidas pendentes. Restam dois pontos de verificação, que entram como sondas em `investigation.md` e não como premissas silenciosas.

| Premissa | Origem (`requirements.md` seção) | Risco se errada |
|----------|----------------------------------|-----------------|
| ~~O microfone do iPhone permanece disponível como entrada de áudio do Mac com o aparelho em uso, tela acesa e página aberta~~ **Premissa falsa, apurada na P-01** | §10, primeiro item | Concretizado: o ditado voltou ao microfone do Mac, RF-14 foi reescrito e o roteiro mudou, sem afetar o restante da feature |
| Os três estados do bloco central cabem na tela com alvos de ao menos 44 pt | §10, segundo item | O teclado reduzido perde teclas ou o bloco central passa a ocupar mais largura, reduzindo a faixa de botões secundários |

## 5. Delta arquitetural

| Componente | Arquivo de origem no legado | Tipo de mudança | Resumo |
|------------|------------------------------|-----------------|--------|
| `VirtualControllerMachine` | `_reversa_sdd/architecture.md#3. Camadas e dependências` | componente-novo | Máquina pura no `JoystickCore` que converte mensagens do canal em `InputEvent`, com idempotência por botão, solturas sintéticas e contagens da sessão |
| `VirtualControllerActions` | `_reversa_sdd/architecture.md#3. Camadas e dependências` | componente-novo | Executor no app que roda na fila `input`, entrega os eventos ao `InputRouter` e mantém o conjunto de botões do iPhone |
| `RemoteKeyboardMessage` | `_reversa_sdd/architecture.md#5. Modelo de dados em arquivo` | contrato-alterado | Quatro casos de cliente (`btn`, `stick`, `pad`, `mode`) e um de servidor (`mode`), com os limites descritos em `interfaces/remote-controller-protocol.md` |
| `RemoteKeyboardService` | `_reversa_sdd/code-analysis.md#1. `app-shell`` | regra-alterada | Roteia as mensagens novas ao executor do controle, propaga a troca de estado do bloco central e soma as contagens no encerramento |
| `InputContext` e `ActiveControllerRegistry` | `_reversa_sdd/state-machines.md#1. Controle conectado` | regra-alterada | O conjunto de botões pressionados passa a ser consultado como união entre controle ativo e controle virtual; a máquina do controle ativo não muda |
| `MotionLoop`, `ButtonActions`, `TargetSession` | `_reversa_sdd/code-analysis.md#3. `pointer`` | regra-alterada | Passam a ler a união de pressionados, de modo que a precisão de L1, o clique com dois detentores e a tela de alvos funcionem com qualquer das origens |
| `InputRouter` | `_reversa_sdd/code-analysis.md#3. `pointer`` | regra-alterada | Nenhuma mudança de roteamento; apenas passa a receber eventos de outra origem, e o descarte do contexto de sugestões da feature 009 é acionado também por botão do iPhone |
| Página do teclado remoto | `_reversa_sdd/addenda/009-sugestao-de-palavras.md#Impacto por artefato da extração` | regra-alterada | `index.html`, `keyboard.css` e `keyboard.js` passam a desenhar colunas de controle e o bloco central de três estados, preservando o teclado completo e a faixa de sugestões |
| `LogEventCatalog` | `_reversa_sdd/architecture.md#5. Modelo de dados em arquivo` | contrato-alterado | Contagens novas no encerramento da sessão remota e evento de troca de estado, sem conteúdo |

## 6. Delta no modelo de dados

- Resumo das mudanças: o arquivo de configuração não muda, e os valores de `pointer` passam a reger as duas origens. Surgem tipos novos no núcleo para o controle virtual, o log ganha duas contagens e um evento de estado, e o navegador do iPhone guarda mais duas preferências.
- Detalhe completo em: `_reversa_forward/010-joystick-virtual-iphone/data-delta.md`

## 7. Delta de contratos externos

| Contrato | Tipo | Arquivo de detalhe |
|----------|------|--------------------|
| Canal do controle remoto | WebSocket sobre TLS, porta 47811 | `_reversa_forward/010-joystick-virtual-iphone/interfaces/remote-controller-protocol.md` |
| Log de diagnóstico | arquivo JSONL | `_reversa_forward/010-joystick-virtual-iphone/interfaces/diagnostic-log.md` |

## 8. Plano de migração

Não há migração de dados: nenhum formato persistido muda de forma incompatível. O que existe é ordem de execução, em cinco fases, com dois portões manuais.

1. **Fase 0, sondas.** Responder P-01 a P-04 de `investigation.md` no aparelho e no Mac, antes de fixar o desenho da página e o roteiro do ditado. Portão PM-0.
2. **Fase 1, núcleo.** `VirtualControllerMachine`, casos novos de `RemoteKeyboardMessage` e testes correspondentes, sem tocar no app.
3. **Fase 2, aplicativo.** União dos botões pressionados, `VirtualControllerActions`, ligação no `RemoteKeyboardService` e no `AppDelegate`, contagens no log. Os testes existentes do teclado e do apontamento precisam continuar verdes sem alteração.
4. **Fase 3, página.** Grade de colunas, analógicos, botões, três estados do bloco central, preferências e tela acesa, preservando o teclado completo e a faixa de sugestões.
5. **Fase 4, portão manual.** PM-1 no hardware, com o roteiro de `onboarding.md`, incluindo o ditado pelo microfone do aparelho e a coexistência com o controle físico.

## 9. Riscos e mitigações

| Risco | Impacto | Probabilidade | Mitigação |
|-------|---------|---------------|-----------|
| O microfone do aparelho não fica disponível ao Mac com o iPhone em uso | médio | alto | Sonda P-01 antes de escrever o roteiro; reprovada, o ditado segue pelo microfone do Mac e o requisito RF-14 é reescrito com essa condição |
| Latência ou tremor do analógico pela rede doméstica tornam o apontamento desagradável | alto | médio | Sonda P-02 mede o atraso entre o dedo e o cursor; a amostragem de D-06 e a integração por tempo real do motor absorvem variação; a área de apontamento relativa permanece como caminho alternativo |
| A união dos botões pressionados quebra a precisão de L1, o clique com dois detentores ou a tela de alvos | alto | baixo | Testes no núcleo para a união, e a suíte existente do apontamento roda sem alteração como controle de regressão |
| Os três estados do bloco central não cabem com alvos de 44 pt | médio | médio | Sonda P-03 com medida na tela real; ajuste da composição do teclado reduzido antes da Fase 3 |
| Gestos de borda do navegador interrompem o arrasto na área de apontamento | médio | médio | Sonda P-04; a página já cancela `touchmove` e usa `touch-action: none`, o que precisa ser confirmado nas bordas |
| A página cresce e passa a confundir teclado e controle no mesmo arquivo | baixo | médio | Separar o controle em arquivo próprio servido pela mesma origem, mantendo a política de conteúdo e a suíte de conferência dos recursos |
| Um segundo aparelho ou uma reconexão deixa botão preso no Mac | alto | baixo | A soltura geral já existente passa a cobrir a máquina nova, acionada pelo vigia, pelo `release`, pela substituição de sessão e pelo desligamento |

## 10. Critério de pronto

- [ ] Todas as ações do `actions.md` marcadas `[X]`
- [ ] `swift build -c release` sem avisos novos e `./scripts/test.sh` verde, com o total de testes registrado antes e depois
- [ ] PM-0 aprovado, com P-01 a P-04 respondidas em `onboarding.md`
- [ ] PM-1 aprovado no hardware, incluindo apontamento, cliques, atalhos, paleta, identificação no editor, ditado e coexistência com o controle físico
- [ ] Nenhuma regressão no teclado remoto e na sugestão de palavras, verificada pelas suítes existentes e pelo roteiro
- [ ] `regression-watch.md` gerado
- [ ] Re-extração reversa executada e sem regressão vermelha (recomendado, não obrigatório)

## 11. Histórico de alterações

| Data | Alteração | Autor |
|------|-----------|-------|
| 2026-09-20 | Versão inicial gerada por `/reversa-plan` | reversa |
| 2026-09-20 | D-02 e D-09 revistas no PM-0, e a premissa do microfone do aparelho registrada como falsa | reversa |
| 2026-09-20 | D-15 revista e D-16 criada, pelas emendas E-04 (gatilhos aderentes e realocados) e E-05 (controle que se esconde) | reversa |
| 2026-09-20 | D-17 criada pela emenda E-06 (analógico de origem dinâmica e curso fixo), depois de pesquisa sobre o controle virtual do iOS | reversa |
| 2026-09-20 | D-18 criada pela emenda E-07 (analógico no vão central da cruz, dos dois lados) | reversa |
| 2026-09-20 | D-19 criada pela emenda E-08 (o disco do analógico vira o fundo da cruz, com as setas por cima) | reversa |
