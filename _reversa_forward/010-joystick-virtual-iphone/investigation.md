# Investigação: controle virtual no iPhone

> Feature: `010-joystick-virtual-iphone`
> Data: 2026-09-20
> Requirements: `_reversa_forward/010-joystick-virtual-iphone/requirements.md`
> Confidência: 🟢 CONFIRMADO no código ou em entrega anterior, 🟡 INFERIDO, 🔴 a responder por sonda

## 1. Perguntas

Três perguntas comandam o desenho: por onde a entrada do iPhone deve entrar no aplicativo para não duplicar regra; como acomodar controles e teclado na mesma tela sem estragar a digitação; e o que exatamente muda para o ditado passar a ouvir pelo microfone do aparelho.

## 2. Por onde a entrada entra

O pipeline confirmado vai de leitores para `InputRouter`, deste para consumidores e destes para injetores, sempre na fila `input` (`_reversa_sdd/architecture.md#2. Estilo arquitetural`). O roteador recebe `InputEvent` com elemento `button`, `leftStick`, `rightStick` ou `touch` e não guarda nada sobre a procedência (`Sources/JoystickAIPoC/Pointer/InputRouter.swift:41`). 🟢

Disso decorre que uma origem nova que produza os mesmos eventos herda, sem código adicional: o clique com dois detentores e o duplo clique de `ClickStateMachine`; a curva de velocidade, o subpixel e o limite às telas de `StickKinematics` e `ScreenUnion`; a rolagem de `ScrollMapper`; o arrasto relativo de `TouchpadTracker`; a decisão de camada de `ShortcutMapper`; a navegação da paleta; e o desvio ao editor durante a identificação. 🟢

Há um único ponto de atrito. O conjunto de botões pressionados vive em `ActiveControllerRegistry.pressed`, e `press(_:from:)` recusa qualquer chave que não seja a do controle ativo (`Sources/JoystickCore/Input/ActiveControllerRegistry.swift:60`). Esse conjunto decide a precisão de L1 (`PointerMotionEngine.precisionActive`), o estado do clique e a leitura da tela de alvos. Registrar o iPhone como controle na fila faria os botões dele serem descartados; registrá-lo como ativo tomaria a vaga do hardware, contra a regra de coexistência. A saída é manter a máquina intacta e consultar a união dos dois conjuntos, o que está fixado em D-04 do roadmap. 🟢

## 3. Como o iPhone conversa com o Mac

O canal da feature 008 já resolve pareamento, cifra, política de origem local, recusa de segundo aparelho, vigia de um segundo e soltura geral em qualquer fechamento (`_reversa_forward/008-iphone-teclado-remoto/interfaces/remote-keyboard-protocol.md`). As mensagens são objetos JSON de até 1 KiB, e cinco inválidas seguidas encerram a sessão. 🟢

O que falta é vocabulário: uma mensagem para botão, uma para a posição dos analógicos, uma para o dedo na área de apontamento e uma para a troca do estado do bloco central, esta última confirmada por uma mensagem do servidor. O detalhe está em `interfaces/remote-controller-protocol.md`.

A página hoje rastreia dedos por identificador em `touchstart` e `touchend`, e cancela todo `touchmove` (`Resources/RemoteKeyboard/keyboard.js:647`). Analógico e área de apontamento exigem justamente o movimento: o mesmo identificador precisa ser seguido do toque inicial até o fim, com o vetor calculado em relação ao centro do analógico. É código novo, porém pequeno, e convive com o rastreio de teclas porque as áreas são disjuntas. 🟢

## 4. Como os controles cabem com o teclado

O teclado completo tem seis linhas de quinze unidades, e o estilo reparte toda a altura entre elas (`Sources/JoystickCore/Remote/RemoteKeyGeometry.swift:48`, `Resources/RemoteKeyboard/keyboard.css`). Num aparelho na horizontal, isso dá cerca de sessenta pontos por tecla, confortável. Sobrepor analógicos de cerca de cento e vinte pontos nos cantos cobriria de quatro a seis teclas de cada lado, entre elas ⇧, ⌃, ⌥ e as setas, o que inviabiliza digitar. 🟢

A alternativa que preserva as duas coisas é dividir a largura: colunas de controle fixas nas laterais e um bloco central que muda de conteúdo. No estado de apontamento, o centro é área de arrasto; no reduzido, traz modificadores, Esc, Tab, Return, apagar, espaço e setas; no completo, devolve o teclado inteiro e recolhe as colunas. A medida exata de cada estado depende da tela real, e por isso vira sonda. 🟡

O mapeamento padrão do projeto dá papel a praticamente todos os botões, entre direcional, faces, gatilhos, modificadores L1, L2 e Options, Create, R3, PS e L3 (`Sources/JoystickCore/Config/ShortcutDefaults.swift`), o que sustenta a decisão de desenhar os dezoito com hierarquia de tamanho em vez de um subconjunto. 🟢

## 5. O que muda para o ditado

Nada no aplicativo. O ditado já é um acorde comum enviado ao transcritor externo, decisão registrada em `_reversa_sdd/addenda/prd-l01-ditado-pelo-raycast.md`, que também documenta o arranjo do microfone: o transcritor escolhe a entrada pela própria lista de prioridade, e o microfone do controle só funcionava por cabo. 🟢

O que o usuário deseja é substituir essa entrada pelo microfone do iPhone, escolhido nas preferências de som do Mac, pelo vínculo entre os dois aparelhos oferecido pelo sistema. Isso é configuração, não código, e não pede permissão nova ao aplicativo. Resta a dúvida de disponibilidade: esse vínculo costuma pressupor o aparelho parado e bloqueado, enquanto aqui ele estará com a tela acesa servindo de controle. É a sonda P-01, e dela depende apenas o roteiro, não o restante da feature. 🔴

## 6. Alternativas avaliadas e descartadas

| Alternativa | Por que foi descartada |
|-------------|------------------------|
| Captura de voz pela própria página | Pediria permissão de microfone ao navegador e poderia enviar áudio a serviço externo, contra a restrição de privacidade vigente; decisão do usuário na sessão de esclarecimento |
| Botões físicos de volume do aparelho como L1 e L2 | Os botões de volume são tratados pelo sistema do aparelho e não chegam como evento ao conteúdo de uma página; só um aplicativo instalado teria acesso, e o projeto não distribui aplicativo |
| Segundo canal ou segunda página para o controle | Duplicaria pareamento, identidade, política de origem e vigia, e abriria a possibilidade de estados divergentes entre as duas conexões |
| Apresentar o iPhone como um modelo de controle no registro do controle ativo | Ou ocuparia a vaga do hardware, ou teria os botões descartados pela própria máquina; em ambos os casos, contra a coexistência exigida |
| Calcular velocidade e aceleração do cursor na página | Tiraria do Mac a fonte única das regras de apontamento e faria os valores de `pointer` do arquivo deixarem de valer para o iPhone |
| Aplicativo nativo para o iPhone | Resolveria os botões físicos e o áudio, mas o projeto não distribui pela App Store e a decisão de usar página no navegador vem da feature 008 |

## 7. Sondas do PM-0

| Sonda | Método | Critério de aprovação |
|-------|--------|-----------------------|
| P-01 microfone do aparelho | Escolher o iPhone como entrada de áudio nas preferências de som do Mac; abrir a página no aparelho, deixar a tela acesa em uso e acionar o ditado pelo botão do controle virtual, falando uma frase | A entrada permanece no aparelho durante o uso e a frase é transcrita no campo em foco; se a entrada cair para outro microfone, a sonda é reprovada e o roteiro muda |
| P-02 atraso do apontamento | Com a página aberta, inclinar o analógico e cronometrar, por vídeo a 240 quadros por segundo da tela do iPhone e da tela do Mac, o intervalo entre o dedo sair do centro e o cursor começar a andar; repetir dez vezes | Percentil noventa e cinco em até sessenta milissegundos, sem paradas perceptíveis durante dez segundos de movimento contínuo |
| P-03 medidas da tela | Abrir a página de desenho nos três estados do bloco central, no iPhone do usuário, na horizontal, e medir os alvos com a régua do inspetor | Todo alvo tocável com ao menos quarenta e quatro pontos de lado nos três estados, e teclado completo idêntico ao de hoje |
| P-04 gestos e tela acesa | Arrastar da borda esquerda para o centro da área de apontamento; deixar a página aberta em uso por cinco minutos sem tocar | Nenhuma navegação para trás nem recarga, e a tela permanece acesa; caso o bloqueio de tela não possa ser impedido, registrar a reprovação e tratar RF-19 como parcialmente atendido |

## 8. Padrões aplicáveis

- Núcleo funcional com casca imperativa (`_reversa_sdd/architecture.md#2. Estilo arquitetural`): a máquina do controle virtual é pura e testada sem hardware, como `RemoteKeyboardMachine` na 008 e `SuggestionContext` na 009.
- Idempotência por elemento, já adotada no teclado remoto: pressionar duas vezes o mesmo botão não duplica o efeito, e soltar o que não está pressionado é ignorado.
- Soltura geral em qualquer fim de caminho, herdada de 001 RN-04 e de 008 RN-10: vigia, página oculta, substituição de sessão, desligamento e encerramento do aplicativo passam pelo mesmo ponto.
- Amostragem por quadro com envio apenas na mudança, padrão comum em controles em tela, que evita encher o canal em repouso.

## 9. Fontes

- `Sources/JoystickAIPoC/Pointer/InputRouter.swift`, `MotionLoop.swift`
- `Sources/JoystickCore/Input/ActiveControllerRegistry.swift`, `InputEvent.swift`, `Normalization.swift`
- `Sources/JoystickCore/Config/ShortcutDefaults.swift`
- `Sources/JoystickCore/Remote/RemoteKeyGeometry.swift`, `RemoteKeyboardMachine.swift`, `RemoteKeyboardMessage.swift`
- `Resources/RemoteKeyboard/index.html`, `keyboard.css`, `keyboard.js`
- `_reversa_forward/008-iphone-teclado-remoto/interfaces/remote-keyboard-protocol.md`
- `_reversa_sdd/addenda/prd-l01-ditado-pelo-raycast.md`, `_reversa_sdd/addenda/009-sugestao-de-palavras.md`
