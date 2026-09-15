# Ponteiro (pointer)

> Unit do módulo `pointer` · Gerado pelo Redator em 2026-09-15 · Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA

## Visão Geral

Transforma o controle em mouse: o analógico esquerdo e o touchpad movem o cursor, o analógico direito rola, R1 e o clique do touchpad fazem o botão esquerdo e R2 o direito, e L1 sozinho reduz a velocidade. Também distribui cada entrada entre cliques, atalhos, paleta, editor e movimento, e mantém o cursor dentro das telas conectadas. 🟢

## Responsabilidades

- Rotear entradas do controle (`InputRouter`) para cliques, atalhos, paleta, identificação do editor, tela de alvos e movimento. 🟢
- Converter o analógico esquerdo em velocidade contínua com curva exponencial e acúmulo subpixel. 🟢
- Converter o touchpad em deslocamento relativo, só pelo primeiro dedo. 🟢
- Converter o analógico direito em rolagem vertical e horizontal. 🟢
- Gerar cliques, duplo clique e arrastes. 🟢
- Governar um único temporizador de 120 Hz, ativo só com analógico fora do repouso. 🟢
- Acompanhar a união das telas ativas e reposicionar o cursor quando uma tela some. 🟢

## Regras de Negócio

- RN-PT-01: Todo botão vai primeiro aos cliques, em qualquer modo, inclusive com a paleta aberta e no modo de identificação. 🟢
- RN-PT-02: No modo de identificação do editor, botões que não são R1, R2 ou clique do touchpad não vão a atalhos nem à paleta; o `buttonDown` não sintético é entregue ao editor na main thread. 🟢
- RN-PT-03: Fora do modo de identificação, todo botão marca atividade na paleta; com a paleta aberta, vai a ela; fechada, aos atalhos. `buttonDown` não sintético também é repassado ao observador da tela de alvos. 🟢
- RN-PT-04: Ligar o modo de identificação fecha a paleta com `identify` e solta as teclas mantidas pelos atalhos. 🟢
- RN-PT-05: Desconexão fecha a paleta com `disconnected` e é repassada a cliques, atalhos e movimento, nessa ordem. 🟢
- RN-PT-06: Velocidade do analógico esquerdo: `h = hypot(x, y)`; se `h = 0`, zero; `m = min(1, h)`; `v = stickMaxSpeed · m^stickExponent`; direção `(x/h, −y/h)` (Y invertido para a tela). 🟢
- RN-PT-07: Precisão ativa só quando o conjunto de botões pressionados do controle ativo é exatamente `{L1}`; multiplica analógico e touchpad por `precisionFactor`. 🟢
- RN-PT-08: Ao sair da zona morta, o analógico esquerdo emite imediatamente um deslocamento de `1/120 s` (onset) e liga o temporizador. 🟢
- RN-PT-09: O temporizador (120 Hz, estrito, folga de 1 ms) liga quando qualquer analógico sai do repouso e desliga só quando os dois estão em repouso; ao desligar, emite o delta pendente do touchpad. 🟢
- RN-PT-10: Cada tick usa o intervalo real desde o anterior, limitado a 50 ms, e emite delta pendente do touchpad + deslocamento do analógico esquerdo, e rolagem se o direito estiver ativo. 🟢
- RN-PT-11: Deslocamentos saem em pontos inteiros, truncados em direção a zero; o resto fracionário acumula para a emissão seguinte. 🟢
- RN-PT-12: Touchpad relativo: só o dedo primário move; a primeira amostra de cada toque (ou de um novo primário) só fixa a referência; `Δ = (Δx, −Δy) · 400 · touchpadSensitivity`; quando o primário sai, o menor dedo restante assume sem salto. 🟢
- RN-PT-13: Amostra do touchpad em que um eixo permanece igual e o outro entra ou sai do zero exato é descartada, por ser atualização parcial do framework. 🟢
- RN-PT-14: Com o temporizador ligado, o delta do touchpad acumula para o próximo tick; desligado, sai de imediato. Touchpad e analógico somam-se. 🟢
- RN-PT-15: Rolagem: `porSegundo = scrollSpeed · (pixel ? 20 : 1)`; `vertical = y · porSegundo · dt · (invertScrollY ? −1 : 1)`; `horizontal = −x · porSegundo · dt`; frações acumulam. Na saída da zona morta do analógico direito, o resto é zerado e uma rolagem de `1/120 s` sai imediatamente. 🟢
- RN-PT-16: R1 e clique do touchpad seguram o mesmo botão esquerdo: o `mouseDown` sai quando o primeiro detentor pressiona e o `mouseUp` só quando o último solta. R2 faz o botão direito. Os três ficam fora dos atalhos (inversão de 001 RN-11, pedida no PM-3). 🟢
- RN-PT-17: Duplo clique: um novo `mouseDown` esquerdo recebe `clickState = anterior + 1` se ocorrer em até `doubleClickIntervalMs` e a no máximo 4 pt do anterior; senão 1. Não há teto. O direito sempre usa 1. 🟢
- RN-PT-18: Com o esquerdo mantido, o movimento é `leftMouseDragged`; senão, com o direito, `rightMouseDragged`; senão `mouseMoved`. 🟢
- RN-PT-19: Desconexão do controle e suspensão da injeção soltam todos os botões de mouse mantidos. 🟢
- RN-PT-20: O cursor fica na união dos retângulos das telas ativas (máximos exclusivos); fora dela, vai ao ponto mais próximo do retângulo mais próximo, com `max − 1`. 🟢
- RN-PT-21: Reconfigurações de tela são agregadas em 200 ms; a união é atualizada e, se o cursor ficou fora, ele é reposicionado com `CGWarpMouseCursorPosition` e `cursor.reclamped`. 🟢
- RN-PT-22: A seção `pointer` só vale a partir da abertura seguinte. 🟢

## Requisitos Funcionais

| ID | Requisito | Prioridade | Critério de Aceite |
|----|-----------|-----------|-------------------|
| RF-PT-01 | Mover o cursor com o analógico esquerdo conforme RN-PT-06 a RN-PT-11 | Must | 30% de inclinação move a menos de 10% da velocidade máxima; inclinação total atravessa 1.920 pt em até 1,5 s |
| RF-PT-02 | Mover o cursor pelo touchpad conforme RN-PT-12 a RN-PT-14 | Must | Pousar o dedo não move; deslizar para a direita move para a direita |
| RF-PT-03 | Rolar com o analógico direito conforme RN-PT-15 | Must | Inclinação total para baixo rola `scrollSpeed` linhas por segundo em direção ao fim |
| RF-PT-04 | Clicar, arrastar e dar duplo clique conforme RN-PT-16 a RN-PT-18 | Must | Dois R1 em menos de 400 ms sobre uma palavra a selecionam |
| RF-PT-05 | Aplicar a precisão de RN-PT-07 | Should | Com só L1, a mesma inclinação desloca 30% ± 5% |
| RF-PT-06 | Manter o cursor na união das telas e reagir a mudanças | Must | Desligar a TV com o cursor nela traz o cursor para a tela restante |
| RF-PT-07 | Rotear entradas conforme RN-PT-01 a RN-PT-05 | Must | Com a paleta aberta, □ não envia Delete e R1 continua clicando |
| RF-PT-08 | Registrar a lista numerada de telas a cada abertura e mudança | Should | `targets.screens` com índice, nome, tamanho em pt e escala |

## Requisitos Não Funcionais

| Tipo | Requisito inferido | Evidência no código | Confiança |
|------|--------------------|---------------------|-----------|
| Performance | Temporizador de 120 Hz estrito com folga de 1 ms; onset imediato para latência | `MotionLoop.swift:92-101`, `PointerMotionEngine.swift:56-72` | 🟢 |
| Performance | Meta de entrada ao movimento de 20 ms no p95 | `LatencyCommand.swift:6-7` | 🟢 |
| Eficiência | Temporizador desligado em repouso | `PointerMotionEngine.swift:126-135` | 🟢 |
| Robustez | Tick limitado a 50 ms para não gerar saltos | `MotionLoop.swift:19,74` | 🟢 |
| Privacidade | Ponto do último clique só em memória | `ClickStateMachine.swift:28-29` | 🟢 |

## Critérios de Aceitação

```gherkin
Dado o analógico esquerdo em repouso e o temporizador desligado
Quando chega axis leftStick (1, 0) sem botões pressionados
Então sai de imediato um move de 12 pt para a direita com origem stick_onset
E o temporizador de 120 Hz é ligado

Dado só L1 pressionado
Quando o analógico esquerdo está em (1, 0) por um tick de 1/120 s
Então o deslocamento é 1500 · 0,3 / 120 = 3,75 pt, emitido como 3 pt com 0,75 acumulado

Dado L1 e R1 pressionados
Quando o analógico esquerdo se move
Então a precisão não é aplicada

Dado o dedo 0 pousado em (0, 0,2) no touchpad
Quando chega moved em (0,1, 0,2) com sensibilidade 1
Então o deslocamento é (40, 0) pt

Dado o dedo 0 em (0,3, 0,2)
Quando chega a amostra parcial (0,3, 0)
Então nenhum deslocamento é emitido

Dado R1 e o clique do touchpad pressionados
Quando R1 é solto
Então nenhum mouseUp é emitido até soltar também o clique do touchpad

Dado um clique esquerdo há 300 ms a 2 pt de distância com clickState 1
Quando R1 é pressionado
Então sai leftMouseDown com clickState 2

Dado um clique esquerdo há 500 ms com doubleClickIntervalMs 400
Quando R1 é pressionado
Então sai leftMouseDown com clickState 1

Dado o cursor na TV à direita da tela do Mac
Quando a TV é desconectada
Então após ~200 ms o cursor é reposicionado na borda da tela do Mac e cursor.reclamped é registrado

Dado o modo de identificação ligado
Quando ✕ é pressionado
Então o editor recebe cross e nenhum atalho é executado
```

## Prioridade (MoSCoW)

| Requisito | MoSCoW | Justificativa |
|-----------|--------|---------------|
| Roteamento, movimento, cliques, limite de telas | Must | Função central do produto |
| Rolagem | Must | Leitura de agentes na TV depende dela |
| Precisão com L1 | Should | Há alternativa (touchpad) |
| Lista de telas no log | Should | Suporte a `--screen` |
| `clickState` além de 2 | Could | Clique triplo, efeito colateral aceito |

## Rastreabilidade de Código

| Arquivo | Função / Classe | Cobertura |
|---------|-----------------|-----------|
| `Sources/JoystickAIPoC/Pointer/InputRouter.swift` | `InputRouter` | 🟢 |
| `Sources/JoystickAIPoC/Pointer/MotionLoop.swift` | `MotionLoop` | 🟢 |
| `Sources/JoystickAIPoC/Pointer/ButtonActions.swift` | `ButtonActions` | 🟢 |
| `Sources/JoystickAIPoC/Display/DisplayMonitor.swift` | `DisplayMonitor` | 🟢 |
| `Sources/JoystickAIPoC/Display/ScreenCatalog.swift` | `ScreenCatalog` | 🟢 |
| `Sources/JoystickCore/Pointer/PointerMotionEngine.swift` | `PointerMotionEngine`, `PointerState`, `MotionOutput` | 🟢 |
| `Sources/JoystickCore/Pointer/StickKinematics.swift` | `StickKinematics`, `SubpixelAccumulator`, `PointDelta` | 🟢 |
| `Sources/JoystickCore/Pointer/TouchpadTracker.swift` | `TouchpadTracker` | 🟢 |
| `Sources/JoystickCore/Pointer/ClickStateMachine.swift` | `ClickStateMachine`, `MouseButton`, `MouseAction`, `MoveKind` | 🟢 |
| `Sources/JoystickCore/Pointer/ScrollMapper.swift` | `ScrollMapper`, `ScrollUnit` | 🟢 |
| `Sources/JoystickCore/Pointer/ScreenUnion.swift` | `ScreenUnion` | 🟢 |
| `Sources/JoystickCore/Pointer/Geometry.swift` | `ScreenPoint`, `ScreenRect` | 🟢 |
| `Sources/JoystickCore/Pointer/PointerSettings.swift` | `PointerSettings` | 🟢 |
