# Investigação: Prova de conceito de entrada do controle e apontamento

> Identificador: `001-poc-entrada-ponteiro`
> Data: `2026-09-14`
> Roadmap: `_reversa_forward/001-poc-entrada-ponteiro/roadmap.md`
> Confidência: 🟢 observado nesta sessão, 🟡 documentado ou inferido e não observado em execução, 🔴 desconhecido

## 1. Fatos observados no ambiente

Levantados em 2026-09-14 na máquina de desenvolvimento, que é também a máquina de uso.

| Fato | Comando ou fonte | Consequência para o plano | Confidência |
|------|------------------|---------------------------|-------------|
| macOS 26 | `sw_vers` | Muito acima do piso de 13; APIs recentes estão disponíveis, mas o código deve compilar para 13. | 🟢 |
| Somente Command Line Tools; `xcodebuild` indisponível | `xcodebuild -version` | Build por SwiftPM e empacotamento por script (D-02). | 🟢 |
| Swift 6.3.3, alvo `arm64-apple-macosx26.0` | `swift --version` | `swift-tools-version: 6.0` é seguro. | 🟢 |
| SDKs presentes: 15, 15.2, 15.4, 26, 26.5 | `ls .../CommandLineTools/SDKs` | `GameController`, `AppKit`, `ApplicationServices` e `CoreGraphics` disponíveis. | 🟢 |
| `Testing.framework` presente; XCTest ausente | `ls .../CommandLineTools/Library/Developer/Frameworks` | Testes com Swift Testing (`import Testing`) (D-03). | 🟢 |
| Nenhuma identidade de assinatura de código | `security find-identity -v -p codesigning` | A Fase 0 começa criando a identidade (D-01). | 🟢 |
| `GCDualSenseGamepad` expõe `touchpadButton`, `touchpadPrimary` e `touchpadSecondary` como `GCControllerDirectionPad`, sem estado de toque | `GameController.framework/Headers/GCDualSenseGamepad.h` | Estado de toque precisa ser inferido ou obtido por outra via (D-05). | 🟢 cabeçalho; 🔴 comportamento |
| `GCControllerTouchpad.touchState` (`Up`, `Down`, `Moving`) e `GCPhysicalInputProfile.touchpads` existem | `GCControllerTouchpad.h`, `GCPhysicalInputProfile.h` | Primeira via a testar para o estado de toque. | 🟢 cabeçalho; 🔴 se o DualSense preenche |
| `shouldMonitorBackgroundEvents` é `NO` por padrão desde o macOS 11.3 | `GCController.h`, comentário da propriedade | Deve ser ligado explicitamente antes da primeira conexão (D-04). | 🟢 |
| `GCInputNames.h` declara `GCInputButtonHome` e `GCInputButtonShare`, mas nenhum nome para o botão de mudo | `GCInputNames.h` | Resposta provável de `controller-input` OQ-01: o mudo não é exposto; confirmar pela lista de elementos na conexão. | 🟡 |
| `GCPhysicalInputProfile.lastEventTimestamp` existe desde o macOS 11 | `GCPhysicalInputProfile.h` | Registrado no log como carimbo informativo do framework; a latência usa o relógio próprio (D-18). | 🟢 |
| `CGPreflightPostEventAccess` e `CGPreflightListenEventAccess` existem desde o macOS 10.15 | `CoreGraphics.framework/Headers/CGEvent.h` | Consulta de permissões sem prompt (D-15). | 🟢 |
| `handlerQueue` configurável em `GCDevice` | `GCDevice.h` | Handlers fora da main (D-04). | 🟢 |
| `.reversa/reversa-config.json` com `allowLegacyEdits: false` | leitura do arquivo | Liberação pelo usuário antes do `/reversa-coding` (D-21). | 🟢 |

## 2. Alternativas avaliadas

### 2.1 Leitura do controle

| Alternativa | Prós | Contras | Veredito |
|-------------|------|---------|----------|
| `GameController` | Suporte oficial ao DualSense, touchpad de dois dedos, supressão de gestos, entrega em segundo plano por opção do framework. | Não expõe transporte nem, pelo cabeçalho, estado de toque do DualSense; comportamento com Input Monitoring não documentado de forma clara. | Escolhida (spec `controller-input` §15). |
| IOKit HID com análise do relatório | Acesso a tudo, inclusive bit de contato do toque e botão de mudo. | Formato de relatório diferente entre USB e Bluetooth; exige Input Monitoring; compete com o framework pelo dispositivo. | Plano B restrito ao estado de toque (D-05). |
| SDL 3 | Abstração pronta, testada em muitos controles. | Dependência C extra no build por SwiftPM; herda as mesmas permissões; foge da stack Swift nativa do PRD. | Descartada. |

### 2.2 Injeção de eventos

| Alternativa | Prós | Contras | Veredito |
|-------------|------|---------|----------|
| `CGEvent` em `.cghidEventTap` | Cobre mover, arrastar, clicar, duplo clique (`clickState`) e rolar em pixels ou linhas; marca de origem por `eventSourceUserData`. | Falha silenciosa sem Acessibilidade. | Escolhida (spec `pointer-control` §10). |
| `CGEvent` em `.cgSessionEventTap` | Semelhante. | Alguns apps de baixo nível só observam o *tap* de HID. | Descartada. |
| `IOHIDPostEvent` | Nível mais baixo. | Obsoleto. | Descartada. |
| API de Acessibilidade (`AXUIElementPerformAction`) | Clica em elementos sem mover o cursor. | Não arrasta nem rola; depende da árvore de acessibilidade de cada app. | Descartada. |

### 2.3 Build, empacotamento e assinatura

| Alternativa | Prós | Contras | Veredito |
|-------------|------|---------|----------|
| SwiftPM e script de bundle | Funciona só com Command Line Tools; build reproduzível pela linha de comando; nada gerado a versionar. | O script precisa montar `Info.plist` e assinar manualmente. | Escolhida (D-02). |
| Projeto Xcode | Assinatura e bundle automáticos. | Exige Xcode instalado. | Descartada para o build; o Xcode pode ser instalado só para o certificado (D-01, caminho A). |
| XcodeGen ou Tuist | Projeto declarativo. | Não instalados e continuam exigindo Xcode. | Descartada. |
| Certificado Apple Development da conta gratuita | Identidade emitida pela Apple, com requisito designado estável. | Criação exige Xcode (Settings > Accounts); validade limitada, com renovação periódica. | Caminho A de D-01 (esclarecimento 3). |
| Certificado autoassinado local | Sem Xcode, sem conta; pode ser criado por script com `openssl` e `security import`, ou pelo Assistente de Certificado do Acesso às Chaves. | Requer marcar confiança para assinatura de código (senha de administrador); vale só nesta máquina, o que basta. | Caminho B de D-01. |
| Assinatura *ad hoc* | Nenhum passo extra. | Hash muda a cada build e o TCC invalida a concessão (`app-shell` EC-01). | Descartada. |

### 2.4 Temporização do movimento

| Alternativa | Prós | Contras | Veredito |
|-------------|------|---------|----------|
| `DispatchSourceTimer` a 120 Hz sob demanda, único para movimento e rolagem | Disponível no piso de macOS 13; liga quando qualquer analógico sai da zona morta e desliga com os dois em repouso; *leeway* controlável; um só laço na fila `input`. | Não sincroniza com a taxa de atualização da tela. | Escolhida (D-11). |
| Dois temporizadores, um por analógico | Isola movimento e rolagem. | Dois laços concorrentes na mesma fila, custo em repouso parcial e ticks desalinhados entre deslocamento e rolagem. | Descartada. |
| `CVDisplayLink` | Sincronizado com a tela. | Obsoleto no macOS 15; um por tela. | Descartada. |
| `NSScreen.displayLink` / `CADisplayLink` | Sincronizado e moderno. | Exige macOS 14, acima do piso. | Descartada; reavaliar se o piso subir. |

### 2.5 Rolagem: pixels ou linhas (`pointer-control` OQ-02)

| Alternativa | Prós | Contras | Veredito |
|-------------|------|---------|----------|
| Eventos em pixels | Rolagem suave no VS Code e em apps AppKit; velocidade contínua proporcional à inclinação. | Conversão de linhas por segundo para pixels depende da altura de linha do app. | Padrão (D-13). |
| Eventos em linhas | Unidade idêntica à de `scrollSpeed`. | Rolagem em saltos; o Terminal pode tratar diferente. | Testada por `--scroll-unit line`; a resposta vai ao bloco (f). |

### 2.6 Formato do log e ferramentas de análise

| Alternativa | Prós | Contras | Veredito |
|-------------|------|---------|----------|
| JSON Lines próprio e `poc-tools` em Swift | Uma linha por evento, sem dependências; reaproveita tipos de `JoystickCore`. | Escritor próprio precisa de *buffer* para não afetar a latência. | Escolhida (D-18). |
| Unified Logging (`os_log`) | Integração com o Console; baixo custo. | Extração por `log show` com filtros, formato menos estável para análise; o RNF de empacotamento pede arquivo em `~/Library/Logs/joystick-ai/`. | Descartada. |
| Scripts Python | Estatística simples na biblioteca padrão. | Segunda linguagem; tipos duplicados. | Descartada. |

## 3. Padrões aplicáveis

- **Núcleo funcional com casca imperativa.** Toda regra de negócio (RN-01 a RN-11) é função pura ou máquina de estados em `JoystickCore`, alimentada por valores e relógio injetados; os adaptadores de plataforma apenas traduzem eventos e executam efeitos. Permite testar RN-09 (duplo clique), RN-08 (precisão), RN-10 (união das telas) e RN-07 (curva) sem hardware.
- **Fila serial como fronteira de isolamento.** Uma fila `input` recebe handlers do framework, transições de controle ativo e o temporizador; a fila `log` escreve em disco; a main cuida apenas da tela de alvos. Nenhum estado mutável é compartilhado sem passar por uma dessas filas.
- **Liberação garantida de recursos.** O conjunto de botões de mouse pressionados pela PoC é mantido explicitamente e esvaziado em três pontos: desconexão (RN-04), encerramento (RF-23) e perda de permissão (registro do caso R-08).
- **Medição por carimbo, não por amostragem externa.** Carimbos monotônicos no próprio caminho do evento permitem calcular p95 fora do processo, sem instrumentação adicional.
- **Configuração tolerante.** Campo ausente usa padrão, campo inválido usa padrão com aviso, arquivo inválido usa padrões com erro; a PoC nunca deixa de iniciar por causa da configuração.

## 4. Pontos a apurar na Fase 1

| # | Pergunta | Como apurar | Destino da resposta |
|---|----------|-------------|---------------------|
| P-01 | `physicalInputProfile.touchpads` vem populado para o DualSense, com `touchState` confiável? | Registrar as chaves do dicionário e as transições de `touchState` durante toques de um e dois dedos. | D-05; se não, acionar a inferência por (0, 0). |
| P-02 | `touchpadPrimary` volta a (0, 0) ao retirar o dedo? | Registrar valores brutos com depuração ligada durante pousos e retiradas. | D-05, plano intermediário. |
| P-03 | O botão de mudo aparece em `allElements`? | Lista de elementos na conexão. | Bloco (f), `controller-input` OQ-01. |
| P-04 | Eventos chegam em segundo plano sem Input Monitoring? E após concedê-lo, só depois de relançar? | Três rodadas: sem permissão, com permissão sem relançar, com permissão relançando. | Bloco (f), `controller-input` OQ-03 e `app-shell` OQ-01. |
| P-05 | `buttonMenu` corresponde a Options e `buttonOptions` a Create? | Roteiro guiado de 18 botões. | D-06. |
| P-06 | A propriedade `Transport` do IORegistry distingue USB de Bluetooth e é correlacionável? | Conectar por cabo, depois por Bluetooth, registrar os candidatos encontrados. | D-07, RF-01. |
| P-07 | A supressão de gestos em `buttonHome` impede o Launchpad no macOS 26? | Pressionar PS com a PoC aberta e fechada. | RF-24, D-23. |
| P-08 | `CGPreflightPostEventAccess()` reflete a revogação sem relançar? | Revogar com a PoC aberta e observar o log. | RF-22, D-15. |
| P-09 | Um DualSense já conectado chega pela lista `GCController.controllers()`, por notificação logo após o início, ou pelas duas vias? | Abrir a PoC com o controle ligado, com `--debug`, e registrar a via e o intervalo desde `session.start`; repetir com USB e Bluetooth. | D-25, RF-03, R-14. |
| P-10 | `CGRequestPostEventAccess()` reabre o diálogo do sistema a cada abertura enquanto a permissão estiver negada? | Abrir a PoC duas vezes sem conceder Acessibilidade e observar se o diálogo reaparece. | D-15, R-16. |
| P-11 | Se Input Monitoring for necessário (P-04), a concessão sobrevive a uma recompilação com o método de assinatura adotado? | Recompilar pelo `build-app.sh`, reabrir e repetir o item de botões com o Terminal em foco, sem nova concessão. | D-01, RNF de operação, esclarecimento 9. |

## 5. Fontes externas

Referências da documentação da Apple consultadas por nome de símbolo; os endereços seguem o padrão público de `developer.apple.com/documentation` e devem ser conferidos no navegador, pois não foram abertos nesta sessão.

- 🟡 GameController, `GCController.shouldMonitorBackgroundEvents`: https://developer.apple.com/documentation/gamecontroller/gccontroller/shouldmonitorbackgroundevents
- 🟡 GameController, `GCController.controllers()` e `GCControllerDidConnectNotification`: https://developer.apple.com/documentation/gamecontroller/gccontroller/controllers()
- 🟡 GameController, `GCDualSenseGamepad`: https://developer.apple.com/documentation/gamecontroller/gcdualsensegamepad
- 🟡 GameController, `GCControllerElement.preferredSystemGestureState`: https://developer.apple.com/documentation/gamecontroller/gccontrollerelement/preferredsystemgesturestate
- 🟡 CoreGraphics, `CGEvent`: https://developer.apple.com/documentation/coregraphics/cgevent
- 🟡 CoreGraphics, `CGPreflightPostEventAccess()`: https://developer.apple.com/documentation/coregraphics/cgpreflightposteventaccess()
- 🟡 CoreGraphics, `CGDisplayRegisterReconfigurationCallback`: https://developer.apple.com/documentation/coregraphics/cgdisplayregisterreconfigurationcallback(_:_:)
- 🟡 Nota técnica TN3127, *Inside Code Signing: Requirements* (requisito designado e sua estabilidade entre builds): https://developer.apple.com/documentation/technotes/tn3127-inside-code-signing-requirements
- 🟡 Swift Testing: https://developer.apple.com/documentation/testing
- 🟢 Cabeçalhos locais do SDK, lidos nesta sessão: `/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/Frameworks/GameController.framework/Headers/` e `CoreGraphics.framework/Headers/CGEvent.h`

## 6. Histórico de alterações

| Data | Alteração | Autor |
|------|-----------|-------|
| 2026-09-14 | Versão inicial gerada por `/reversa-plan` | reversa |
| 2026-09-14 | Revisão após `/reversa-audit`: temporizador único em §2.4; pontos P-09 (adoção ao iniciar), P-10 (pedido de permissão repetido) e P-11 (Input Monitoring após recompilar) | reversa |
