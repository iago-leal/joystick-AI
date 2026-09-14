# Impacto no legado: Prova de conceito de entrada do controle e apontamento

> Identificador: `001-poc-entrada-ponteiro`
> Data: `2026-09-14`
> Feature greenfield, sem legado pré-existente. Âncora: prd.md + specs SDD.
> Política de edição no momento da execução: `allowLegacyEdits: true`, `allowedPaths` vazio (liberação irrestrita do projeto)
> Execução: parcial; rodada 1 (56 de 79 ações) até o PM-1, cumprido; rodada 2 (63 de 79) até o PM-2, aprovado após as correções de touchpad por Bluetooth e botão PS; rodada 3 (79 de 79) até o portão manual PM-3, interrompido; durante o PM-3, inversão de R1 e R2 e protótipo de atalhos fora do escopo, a pedido do usuário

Todos os arquivos abaixo são novos, exceto o `.gitignore`, que recebeu uma linha. Os componentes citam as specs em `_reversa_sdd/sdd/`; os instrumentos sem spec citam o `requirements.md`.

## Arquivos afetados

| Arquivo afetado | Componente | Tipo | Severidade | Justificativa |
|-----------------|------------|------|------------|---------------|
| `Package.swift` | `app-shell` (empacotamento, RNF-05) | componente-novo | MEDIUM | Define os três alvos e o alvo de testes (D-02, D-03, D-22); contém `unsafeFlags` para o Swift Testing das Command Line Tools. |
| `.gitignore` | infraestrutura do repositório | componente-novo | LOW | Acréscimo de `.build/`, preservando as entradas existentes. |
| `Resources/Info.plist` | `app-shell` RF-01 | componente-novo | MEDIUM | App agente (`LSUIElement`), identificador `dev.iagoleal.joystick-ai.poc`, piso macOS 13; o identificador compõe o requisito designado que o TCC associa às permissões. |
| `scripts/build-app.sh` | `app-shell` RNF-05 | componente-novo | HIGH | Assina e instala em caminho fixo; um erro aqui invalida as permissões a cada build (R-01). Recusa assinatura *ad hoc*. |
| `scripts/check-signature.sh` | `app-shell` RNF-05 | componente-novo | LOW | Só leitura da assinatura instalada, para o `diff` do PM-1. |
| `scripts/create-local-signing-identity.sh` | `app-shell` RNF-05, D-01 caminho B | componente-novo | MEDIUM | Altera o chaveiro de login do usuário e pede senha de administrador; executado uma vez, criando a identidade "JoystickAI Local Signing" usada no PM-1. |
| `scripts/test.sh` | infraestrutura de testes (D-03) | componente-novo | LOW | Passa ao compilador o caminho do Swift Testing quando só há Command Line Tools. |
| `scripts/config-samples/*.json` | `action-mapping` §9 (contrato `pointer`) | componente-novo | LOW | Amostras dos cenários de RF-26; não são lidas pelo app. |
| `Sources/JoystickCore/Support/MonotonicClock.swift`, `Support/JSONValue.swift` | `controller-input` RNF-01 (carimbos) | componente-novo | LOW | Relógio `CLOCK_UPTIME_RAW` e valor JSON determinístico. |
| `Sources/JoystickCore/Log/LogEvent.swift`, `Log/LogEventCatalog.swift` | `app-shell` RF-12; `controller-input` §12 | componente-novo | HIGH | Único ponto que define os campos do log; garante por tipo a ausência de coordenadas e valores de eixo (RN-12). |
| `Sources/JoystickCore/Input/InputEvent.swift` | `controller-input` §9 | componente-novo | MEDIUM | `ButtonID` com os 18 identificadores, `InputEvent`, `ControllerInfo` com `atStartup`. |
| `Sources/JoystickCore/Input/Normalization.swift` | `controller-input` RF-05, RF-06, EC-02 | componente-novo | MEDIUM | Zona morta por eixo e limiar de gatilho sem histerese (RN-02, RN-03). |
| `Sources/JoystickCore/Input/ActiveControllerRegistry.swift` | `controller-input` RF-08, EC-01, EC-03 | componente-novo | HIGH | Controle ativo, deduplicação e soltura sintética de botões (RN-01, RN-04). |
| `Sources/JoystickCore/Input/StartupAdoption.swift` | `controller-input` Fluxo Alternativo A | componente-novo | LOW | Classificação de `atStartup` (D-25). |
| `Sources/JoystickCore/Pointer/PointerSettings.swift` | `pointer-control` §9 | delta-de-dados | MEDIUM | Mesmos nomes e padrões da spec, com as faixas de RF-26 que a spec ainda não tem. |
| `Sources/JoystickCore/Pointer/StickKinematics.swift` | `pointer-control` RF-03 | componente-novo | MEDIUM | Velocidade radial com expoente e acúmulo subpixel (RN-07). |
| `Sources/JoystickCore/Pointer/TouchpadTracker.swift` | `pointer-control` RF-01, RF-02, EC-03 | componente-novo | HIGH | Movimento relativo pelo primeiro dedo e inferência de fase por (0, 0); depende de D-05 🔴, que o PM-2 apura. |
| `Sources/JoystickCore/Pointer/PointerMotionEngine.swift` | `pointer-control` RF-03, EC-04, RF-09 | componente-novo | MEDIUM | Soma de analógico e toque, temporizador único e precisão (RN-06, RN-08). |
| `Sources/JoystickCore/Pointer/ClickStateMachine.swift` | `pointer-control` RF-05 a RF-08, EC-02, EC-06 | componente-novo | HIGH | Cliques, duplo clique, arraste e `releaseAll`; um erro deixa botão de mouse preso. No PM-3, R1 passou ao botão esquerdo e R2 ao direito, a pedido do usuário. |
| `Sources/JoystickCore/Pointer/ScrollMapper.swift` | `pointer-control` RF-04 | componente-novo | MEDIUM | Rolagem em pixels ou linhas; o sinal ainda precisa de confirmação no hardware. |
| `Sources/JoystickCore/Pointer/ScreenUnion.swift`, `Pointer/Geometry.swift` | `pointer-control` RF-12, EC-05 | componente-novo | MEDIUM | União de retângulos das telas (RN-10), com geometria própria em vez de CoreGraphics. |
| `Sources/JoystickCore/Config/PointerSettingsValidation.swift`, `Config/ConfigLoader.swift` | `action-mapping` §9; `pointer-control` RF-10 (recorte) | delta-de-contrato-externo | MEDIUM | Leitura da seção `pointer` de `~/.config/joystick-ai/config.json`, sem criar o arquivo (contrato `interfaces/config-pointer.md`). |
| `Sources/JoystickCore/App/LaunchArguments.swift` | tela de alvos (`requirements.md` RF-27) | delta-de-contrato-externo | LOW | Argumentos de abertura de `interfaces/target-run-result.md` §1. |
| `Sources/JoystickCore/Analysis/LatencyStats.swift`, `Analysis/LogAnalysis.swift`, `Analysis/RunsReport.swift` | `poc-tools` (`requirements.md` RF-25) | componente-novo | LOW | Cálculos do relatório; não fazem parte do produto. |
| `Sources/JoystickCore/Targets/TargetRun.swift` | tela de alvos (`requirements.md` RF-27) | delta-de-dados | MEDIUM | Formato persistido novo com `schemaVersion` 1 (`data-delta.md` §3.2). |
| `Sources/JoystickAIPoC/main.swift`, `App/AppDelegate.swift` | `app-shell` RF-01; `action-mapping` §9 | componente-novo | HIGH | Compõe configuração, argumentos, injeção, telas, permissão, ciclo de vida, leitura do controle e tela de alvos; a ordem de início importa (configuração antes da leitura, portão antes do monitor de permissões). |
| `Sources/JoystickAIPoC/Injection/EventInjector.swift` | `pointer-control` RF-05 a RF-08, RF-12 | componente-novo | CRITICAL | Único ponto que posta eventos de mouse; acompanha a posição postada para não perder movimento. Um erro aqui move o cursor errado ou deixa botão preso no sistema inteiro. |
| `Sources/JoystickAIPoC/Injection/ScrollInjector.swift` | `pointer-control` RF-04 | componente-novo | MEDIUM | Rolagem em pixels ou linhas com a mesma marca de origem. |
| `Sources/JoystickAIPoC/Display/ScreenCatalog.swift`, `Display/DisplayMonitor.swift` | `pointer-control` RF-12, EC-05 | componente-novo | MEDIUM | Lista de telas, união dos retângulos e reposicionamento do cursor em reconfiguração. |
| `Sources/JoystickAIPoC/Pointer/MotionLoop.swift` | `pointer-control` RF-01 a RF-04, EC-04 | componente-novo | HIGH | Temporizador único de 120 Hz para movimento e rolagem; um temporizador que não para consome CPU em repouso. |
| `Sources/JoystickAIPoC/Pointer/ButtonActions.swift`, `Pointer/InputRouter.swift` | `pointer-control` RF-05 a RF-09, EC-02 | componente-novo | HIGH | Cliques pelo mapeamento de RN-11 e soltura na desconexão. |
| `Sources/JoystickCore/Shortcuts/ShortcutMapper.swift`, `Tests/JoystickCoreTests/ShortcutMapperTests.swift` | `action-mapping` RF-05, RF-06, RF-10, EC-04 e seção 8 (protótipo) | componente-novo | MEDIUM | Protótipo de atalhos pedido no PM-3, fora do escopo da PoC: mapeamento fixo, combinações decididas no pressionar, Options segurando Command. |
| `Sources/JoystickAIPoC/Injection/KeyboardInjector.swift`, `Pointer/ShortcutActions.swift` | `action-mapping` RF-10, EC-05 (protótipo) | componente-novo | HIGH | Teclas e texto por `CGEvent` com a marca da PoC; um erro deixa tecla ou Command preso no sistema, por isso a soltura acompanha desconexão, encerramento e suspensão. |
| `Sources/JoystickAIPoC/App/InjectionGate.swift` | `pointer-control` EC-01 | componente-novo | HIGH | Suspende a injeção e solta botões ao perder a Acessibilidade; depende de P-08. |
| `Sources/JoystickAIPoC/App/Lifecycle.swift` | `app-shell` §12, RF-23 | componente-novo | HIGH | Limpeza em Sair e sinais; ignora a forma padrão de `SIGTERM`, `SIGINT` e `SIGHUP`. |
| `Sources/JoystickAIPoC/Targets/TargetWindow.swift`, `Targets/TargetSession.swift`, `Targets/TargetAbortMonitor.swift` | tela de alvos (`requirements.md` RF-27) | componente-novo | MEDIUM | Janela sobre a tela escolhida, 20 tentativas, separação de cliques injetados e físicos, interrupções. |
| `Sources/JoystickAIPoC/Controller/TransportResolver.swift` | `controller-input` RF-01 | componente-novo | LOW | Transporte pelo IORegistry, sem abrir o dispositivo; resultado só informativo em `controller.connected` (D-07, P-06). |
| `Sources/JoystickAIPoC/Controller/InputSink.swift` | `controller-input` §9 (saída) | componente-novo | MEDIUM | Protocolo de entrega e `InputContext` com o estado da fila `input`; a Fase 2 troca o destino que só registra. |
| `Sources/JoystickAIPoC/Controller/ControllerReader.swift` | `controller-input` RF-01 a RF-04, RF-08, EC-01 | componente-novo | HIGH | Adoção ao iniciar, deduplicação, controle ativo e soltura sintética na desconexão; um erro deixa botão preso ou controle duplicado (RN-01, RN-04). |
| `Sources/JoystickAIPoC/Controller/ButtonReader.swift` | `controller-input` RF-05, RF-06 | componente-novo | HIGH | Os 18 botões pelo mapeamento de D-06, com carimbos de latência; P-05 pode inverter Options e Create. |
| `Sources/JoystickAIPoC/Controller/AxisTouchReader.swift` | `controller-input` RF-05; `pointer-control` RF-01, RF-02 | componente-novo | HIGH | Analógicos e touchpad por duas vias, escolhidas por conexão; depende de D-05 🔴, que o PM-2 apura. |
| `Sources/JoystickAIPoC/Controller/ControllerDiagnostics.swift` | `controller-input` OQ-01; `app-shell` RF-24 | componente-novo | LOW | Lista de elementos com `--debug` e pedido de supressão de gestos em `buttonHome` (P-03, P-07). |
| `Sources/JoystickAIPoC/Controller/ExtendedReportActivator.swift` | `controller-input` RF-05; `pointer-control` RF-01 | componente-novo | HIGH | Abre o DualSense pelo `IOHIDManager` para ler o relatório de recurso `0x05`, sem o qual o touchpad fica mudo por Bluetooth, e para ler o PS; diverge de D-07. |
| `Sources/JoystickCore/Input/DualSenseReport.swift` | `controller-input` RF-05 | componente-novo | MEDIUM | Posição do bit do PS nos relatórios USB e Bluetooth; um deslocamento errado faz o PS sumir ou disparar sozinho. |
| `Sources/JoystickAIPoC/App/SigningInfo.swift` | `app-shell` RNF-05 | componente-novo | LOW | Lê a própria assinatura para o bloco (e). |
| `Sources/JoystickAIPoC/App/PermissionMonitor.swift` | `pointer-control` EC-01; `app-shell` §12 | componente-novo | HIGH | Consulta a Acessibilidade a cada 2 s e pede a entrada na lista uma vez por processo; nunca contorna a permissão. |
| `Sources/JoystickAIPoC/Log/DiagnosticLog.swift` | `app-shell` RF-12 | delta-de-contrato-externo | MEDIUM | Arquivo JSON Lines em `~/Library/Logs/joystick-ai/` (`interfaces/diagnostic-log.md`). |
| `Sources/JoystickAIPoC/Targets/TargetRunWriter.swift` | tela de alvos (`requirements.md` RF-27) | delta-de-contrato-externo | LOW | Grava resultados sem sobrescrever (`interfaces/target-run-result.md` §3 a §5). |
| `Sources/poc-tools/*.swift` | `poc-tools` (`requirements.md` RF-25) | componente-novo | LOW | Subcomandos `buttons`, `runs`, `latency` e `cycles`. |
| `Tests/JoystickCoreTests/*.swift` | testes de `JoystickCore` | componente-novo | LOW | 127 testes em 18 suítes; evidência automatizada de RF-06 e RF-08 (esclarecimento 6). |
| `_reversa_forward/001-poc-entrada-ponteiro/validation-report.md` | relatório de validação (`requirements.md` RF-25) | componente-novo | LOW | Esqueleto dos sete blocos, a preencher pelo avaliador. |

## Diff conceitual por componente

### `controller-input` (recorte PoC)

A lógica pura (identificadores, normalização, registro do controle ativo e adoção ao iniciar) ganhou, na rodada 2, o adaptador de plataforma: `ControllerReader` liga a leitura em segundo plano, adota os controles já conectados e os que chegam por notificação, e alimenta o registro na fila `input`; `ButtonReader`, `AxisTouchReader` e `ControllerDiagnostics` entregam botões, analógicos e toque ao `InputSink`, que por ora só registra. O PM-2 aprovou a leitura com duas correções que as specs não previam: por Bluetooth, a PoC abre o dispositivo HID para tirar o controle do relatório simplificado, e lê o PS do relatório bruto, porque o macOS o retém antes do GameController. Ambas contrariam D-07 e ficam para o `/reversa-sync`.

### `pointer-control` (recorte PoC)

A lógica de `JoystickCore` ganhou os adaptadores de injeção: `MotionLoop` aplica o temporizador único a movimento e rolagem, `ButtonActions` converte botões em cliques, `EventInjector` e `ScrollInjector` postam os eventos, `DisplayMonitor` limita o cursor à união das telas, `InjectionGate` liga a injeção à Acessibilidade e `Lifecycle` solta os botões ao encerrar. A verificação com o controle revelou duas incompatibilidades com o comportamento real do macOS, corrigidas no rastreador de toque e na posição de partida do injetor.

### `app-shell` (subconjunto mínimo)

O app agente abre, recusa segunda instância, grava `session.start` com a assinatura e monitora permissões. O empacotamento, a assinatura e a instalação em caminho fixo estão nos scripts. O PM-1 confirmou que a Acessibilidade sobrevive a uma recompilação; resta verificar o Input Monitoring (P-11), se P-04 o exigir.

### `action-mapping` (contrato de configuração)

Leitura da seção `pointer` com faixas, padrões e linha do erro de JSON, carregada no `AppDelegate` antes da leitura do controle e repassada a todos os componentes.

### Tela de alvos e `poc-tools`

Janela, sessão de 20 tentativas e interrupções por ○, Esc, tela removida e injeção suspensa estão implementadas, mas a tela de alvos ainda não foi aberta com o controle. O `poc-tools` está completo para os quatro subcomandos.

## Preservadas

Sem regras 🟢 de domínio extraídas de código: não existe `_reversa_sdd/domain.md` e nenhum código anterior foi alterado. Seção vazia por se tratar de feature greenfield.

## Modificadas

Nenhuma regra 🟢 de legado foi alterada ou removida. Seção vazia por se tratar de feature greenfield.
