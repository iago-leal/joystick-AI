# Análise de código — joystick-AI

> Gerado pelo Arqueólogo em 2026-09-15 · Nível: completo · Organização: por módulo
> Escala: 🟢 CONFIRMADO (lido no código) · 🟡 INFERIDO (padrão ou efeito provável) · 🔴 LACUNA (exige validação humana)
> Dicionário de dados em `data-dictionary.md`; fluxogramas em `flowcharts/<módulo>.md`.

## Sumário

| # | Módulo | Arquivos | Linhas | Complexidade |
|---|--------|----------|--------|--------------|
| 1 | [`app-shell`](#1-app-shell) | 9 | 644 | média |
| 2 | [`controller-input`](#2-controller-input) | 12 | 690 | alta |
| 3 | [`pointer`](#3-pointer) | 13 | 890 | alta |
| 4 | [`injection`](#4-injection) | 3 | 287 | média |
| 5 | [`shortcuts`](#5-shortcuts) | 4 | 475 | alta |
| 6 | [`palette`](#6-palette) | 3 | 518 | média |
| 7 | [`config`](#7-config) | 11 | 1.277 | alta |
| 8 | [`editor`](#8-editor) | 14 | 1.550 | alta |
| 9 | [`diagnostics-log`](#9-diagnostics-log) | 5 | 653 | média |
| 10 | [`targets-analysis`](#10-targets-analysis) | 14 | 856 | média |

## 0. Visão transversal

### 0.1 Modelo de concorrência 🟢

O app usa três contextos de execução, declarados em comentários e reforçados por `dispatchPrecondition`:

| Contexto | Dono | Quem roda nele |
|----------|------|----------------|
| main thread | AppKit | `AppDelegate`, `ConfigStore`, `ConfigWatcher`, `StatusMenu`, `PalettePanel`, editor, `TargetSession`, `DisplayMonitor`, `PermissionMonitor`, `ExtendedReportActivator` (run loop principal) |
| fila `input` (serial, `userInteractive`) | `AppDelegate.inputQueue` | handlers do `GCController` (`controller.handlerQueue`), `InputRouter`, `ButtonActions`, `MotionLoop` e seu temporizador de 120 Hz, `ShortcutActions`, `PaletteActions`, `InjectionGate`, injetores |
| fila `log` (serial, `utility`) | `DiagnosticLog` | formatação e escrita do JSONL |

O `JoystickCore` não tem filas: suas máquinas (`ActiveControllerRegistry`, `ClickStateMachine`, `PointerMotionEngine`, `ShortcutMapper`, `PaletteMachine`, `EditorDraft`) são `struct` de valor, e o chamador serializa as transições (`ActiveControllerRegistry.swift:5`). A travessia entre contextos é sempre por `async`, com duas exceções síncronas da main para a `input`: `Lifecycle.cleanUp` (`Lifecycle.swift:37`) e `TargetSession.recordAttempt` (`TargetSession.swift:91`). Como a fila `input` nunca faz `sync` para a main, não há risco de impasse. 🟢

### 0.2 Pipeline de entrada 🟢

```
GCController / IOHID ──► ControllerReader, ButtonReader, AxisTouchReader (fila input)
                          │  ActiveControllerRegistry filtra o controle ativo
                          ▼
                       InputSink = InputRouter
          ┌───────────────┼──────────────────┬──────────────────┐
          ▼               ▼                  ▼                  ▼
    ButtonActions     MotionLoop       ShortcutActions     PaletteActions
   (R1/R2/touchpad)  (analógicos,     (demais botões,     (botões com a
          │           touchpad)        se paleta fechada)  paleta aberta)
          ▼               ▼                  ▼                  ▼
     EventInjector ◄── ScrollInjector   KeyboardInjector ──► EventInjector
          │ CGEvent.post(.cghidEventTap), marca 0x4A4F5953 ("JOYS")
```

### 0.3 Fontes de identificadores de decisão

Os comentários citam decisões e requisitos das specs de origem (`D-nn`, `RF-nn`, `RN-nn`, `P-nn`, `PM-n`, `E00n`), muitas vezes prefixados pela feature (`002-paleta-comandos`, `003-editor-atalhos`). Sem prefixo, referem-se à feature 001. Essa rastreabilidade embutida é o principal insumo do Detetive. 🟢

---

## 1. `app-shell`

**Propósito:** processo agente sem Dock, montagem de todos os componentes, permissões, encerramento limpo, menus e argumentos de abertura.

**Arquivos:** `JoystickAIPoC/main.swift`, `App/AppDelegate.swift` (198), `App/InjectionGate.swift` (65), `App/Lifecycle.swift` (47), `App/PermissionMonitor.swift` (69), `App/SigningInfo.swift` (50), `App/StatusMenu.swift` (69), `App/EditMenu.swift` (38 — detalhado em `editor`), `JoystickCore/App/LaunchArguments.swift` (129).

### 1.1 Fluxo de controle

- **`main.swift`**: cria `NSApplication`, instala o `AppDelegate`, fixa `.accessory` e chama `run()`. 🟢
- **`AppDelegate.applicationDidFinishLaunching`** (`AppDelegate.swift:31-139`), em ordem estrita: 🟢
  1. Instância única: se outro processo com o mesmo `bundleIdentifier` roda, `NSApp.terminate` (`:32-35`, `:192-198`).
  2. `LaunchArguments.parse` e abertura do `DiagnosticLog` com `--debug`; `session.start` com versão, macOS, pid, argumentos e assinatura (`:37-46`).
  3. `ConfigLoader.load` uma única vez. `pointer` fica congelado nesta leitura; atalhos e paleta passam ao `ConfigStore` (`:48-55`).
  4. Injetores, `InputContext`, `ButtonActions`, `MotionLoop`, `KeyboardInjector` único e `ShortcutActions` (`:57-66`).
  5. Paleta: erros de argumentos da paleta vão a `palette.invalid_args`; o painel é criado oculto (`:68-78`).
  6. `configStore.onApply` leva a nova configuração à fila `input`, primeiro a paleta e depois os atalhos (`:80-86`).
  7. Editor, `EditMenu`, `StatusMenu` e observadores do `ConfigStore` (`:88-105`).
  8. `ConfigWatcher` (`:108-109`), `InputRouter` com o modo de identificação (`:111-118`), `InjectionGate` e `Lifecycle` (`:119-123`).
  9. `DisplayMonitor` e `ScreenCatalog.emit` (`:125-127`), `PermissionMonitor` ligado ao portão (`:129-131`).
  10. Por último, `ControllerReader.start()` (`:133-134`): nenhum evento do controle chega antes de todos os consumidores existirem.
  11. Com `--targets`, `openTargets` (`:136-138`).
- **`openTargets`** (`:146-190`): registra erros de argumentos, exceto os da paleta; exige `--env`; recusa sem telas; `--screen` inválido ou fora da faixa cai na tela 1 com `targets.screen_fallback`; semente aleatória de 32 bits quando ausente; bloqueia a paleta enquanto a sessão durar. 🟢
- **`applicationWillTerminate`** chama `Lifecycle.cleanUp(.quit)`. 🟢

### 1.2 Regras e algoritmos

| Regra | Local | Confiança |
|-------|-------|-----------|
| Consulta de permissões a cada 2 s, com folga de 200 ms; `postEvent` por `AXIsProcessTrusted()` e não por `CGPreflightPostEventAccess()`, que continuou verdadeiro após a revogação (P-08) | `PermissionMonitor.swift:12,39-41,48` | 🟢 |
| `CGRequestPostEventAccess()` pedido uma única vez por processo, só se a permissão faltar no início | `PermissionMonitor.swift:35-38` | 🟢 |
| Só a mudança de `postEvent` aciona o portão; `listenEvent` só é registrado | `PermissionMonitor.swift:57-63` | 🟢 |
| Suspensão: fecha a paleta (`injection_suspended`), solta teclas e botões **antes** de desativar o injetor e guarda as solturas para repeti-las na retomada | `InjectionGate.swift:53-62` | 🟢 |
| Retomada: reativa, repete `mouseUp` e `keyUp`/`flagsChanged` guardados e registra `pointer.injection_resumed` com `heldButtons` sempre vazio | `InjectionGate.swift:41-51` | 🟢 |
| Estado inicial do portão não registra suspensão nem retomada | `InjectionGate.swift:33-37` | 🟢 |
| SIGTERM, SIGINT e SIGHUP: `signal(SIG_IGN)` e depois `DispatchSource`; limpeza idempotente e `exit(0)` | `Lifecycle.swift:17-29,34-44` | 🟢 |
| Limpeza: solta atalhos e botões na fila `input` (sync), registra `app.terminating` e força o flush | `Lifecycle.swift:37-43` | 🟢 |
| Ícone `gamecontroller`; com configuração inválida, `exclamationmark.triangle` e item de topo "Configuração inválida: linha N" | `StatusMenu.swift:32-46` | 🟢 |
| Argumentos: `--targets`, `--debug`, `--env mesa\|sofa`, `--screen ≥ 1`, `--seed UInt64`, `--scroll-unit pixel\|line`, `--palette-enter-delay-ms 0…500`; desconhecidos ignorados; `--targets` sem `--env` gera `missingEnv` | `LaunchArguments.swift:56-127` | 🟢 |
| A tela de alvos só abre com `--targets` **e** `env` válido (`targetsEnabled`) | `LaunchArguments.swift:53` | 🟢 |

### 1.3 Observações

- 🟡 `targetsEnabled` é definido, mas o `AppDelegate` testa `arguments.targets` (`:136`) e retorna em `openTargets` sem `env` (`:153`). O efeito é equivalente, e a propriedade só serve aos testes.
- 🟡 O `PermissionMonitor` chama `CGPreflightListenEventAccess()`, mas nenhuma decisão depende de Input Monitoring; sem essa permissão, o `GameController` simplesmente não entrega eventos em segundo plano, e o log não aponta a causa.
- 🟢 `InjectionGate.onSuspended` é usado só pela tela de alvos (`TargetAbortMonitor.swift:37`).

---

## 2. `controller-input`

**Propósito:** descobrir DualSense conectados, eleger um controle ativo, ler 18 botões, dois analógicos e dois dedos do touchpad, e entregar `InputEvent` normalizados à fila `input`.

**Arquivos:** `JoystickCore/Input/` (`ActiveControllerRegistry`, `DualSenseReport`, `InputEvent`, `Normalization`, `StartupAdoption`), `JoystickAIPoC/Controller/` (`ControllerReader`, `ButtonReader`, `AxisTouchReader`, `ControllerDiagnostics`, `ExtendedReportActivator`, `TransportResolver`, `InputSink`).

### 2.1 Fluxo de controle

- **`ControllerReader.start()`** (main, `ControllerReader.swift:20-55`): 🟢
  1. `GCController.shouldMonitorBackgroundEvents = true` antes de qualquer observador; sem isso, só há entrada com o app em primeiro plano.
  2. Observadores de `GCControllerDidConnect` e `DidDisconnect`, que tomam `t_arrival` e despacham à fila `input`.
  3. `ExtendedReportActivator.start()` com `onHomeButton` entregando o PS ao controle **ativo**.
  4. Enumeração de `GCController.controllers()` só depois dos observadores; a deduplicação é por `ObjectIdentifier`.
- **`connect`** (`:59-92`): controle não DualSense entra em `ignored` com `controller.ignored` (`not_dualsense`). Caso contrário, cria `ControllerInfo` com UUID novo, nome, transporte e `atStartup`; registra no `ActiveControllerRegistry`; ajusta `handlerQueue` para a fila `input`; registra `controller.connected` e, na fila, `controller.queued`; liga os leitores de botões, eixos e toque e o diagnóstico. 🟢
- **`disconnect`** (`:94-116`): remove ignorados em silêncio. Para o ativo, emite `buttonUp` **sintético** de cada botão pressionado (RN-04) e `controllerDisconnected` ao destino, depois `controller.disconnected`. 🟢

### 2.2 Algoritmos

| Algoritmo | Descrição | Local | Confiança |
|-----------|-----------|-------|-----------|
| Fila de controles ativos | Lista ordenada por chegada; o primeiro é o ativo; duplicata devolve `.duplicate`; desconectar o ativo solta os pressionados em ordem estável e promove o seguinte | `ActiveControllerRegistry.swift:39-68` | 🟢 |
| Filtro do controle ativo | `press` e `release` só aceitam a chave ativa e só devolvem `true` na mudança real, o que deduplica o PS vindo por duas vias | `ActiveControllerRegistry.swift:60-68`, `ButtonReader.swift:47-48` | 🟢 |
| Adoção no início | `atStartup` = veio da enumeração **ou** chegou antes de 2 s do início do processo | `StartupAdoption.swift:10-14` | 🟢 |
| Zona morta por eixo | `\|v\| < deadzone` vale 0; o restante é limitado a ±1, sem reescala | `Normalization.swift:8-11` | 🟢 |
| Gatilho digital | L2/R2 pressionados com valor ≥ 0,5, sem histerese; `TriggerTracker` só emite na mudança | `Normalization.swift:5,18-40` | 🟢 |
| Supressão de repetição de eixo | Amostras normalizadas iguais à anterior não são entregues | `AxisTouchReader.swift:62-66` | 🟢 |
| Fonte da fase do toque | Com `physicalInputProfile.touchpads` não vazio, usa `touchDown/Moved/Up` (`touchState`); senão infere pela transição de e para (0, 0) (`zero_transition`) | `AxisTouchReader.swift:22-54`, `TouchpadTracker.swift:61-79` | 🟢 |
| PS por HID bruto | O macOS retém o PS antes do `GameController`; o bit 0 do terceiro byte de botões fica no índice 10 (USB `0x01`, ≥ 64 bytes), 11 (BT `0x31`, ≥ 12) ou 7 (BT simplificado `0x01`, 10 bytes) | `DualSenseReport.swift:7-16` | 🟢 |
| Ativação do relatório estendido | Por Bluetooth, ler o relatório de recurso `0x05` (calibração) tira o controle do modo simplificado sem touchpad | `ExtendedReportActivator.swift:57-65` | 🟢 |
| Transporte por exclusão | Consulta o IORegistry (Sony `0x054C`, produtos `0x0CE6` DualSense e `0x0DF2` Edge); só responde `usb` ou `bluetooth` se **todos** os candidatos tiverem o mesmo transporte; senão `unknown` | `TransportResolver.swift:11-47` | 🟢 |
| Supressão de gestos do PS | `buttonHome.preferredSystemGestureState = .disabled`, sem confirmação do sistema | `ControllerDiagnostics.swift:20-26` | 🟢 |

### 2.3 Mapeamento físico (D-06) 🟢

`cross`→`buttonA`, `circle`→`buttonB`, `square`→`buttonX`, `triangle`→`buttonY`, `l1`/`r1`→ombros, `l3`/`r3`→cliques dos analógicos, **`options`→`buttonMenu`**, **`create`→`buttonOptions`**, `ps`→`buttonHome`, `touchpadClick`→`touchpadButton`, direcional→`dpad.*`; `l2`/`r2` pelos gatilhos analógicos (`ButtonReader.swift:8-38`). O comentário (`:7`) ainda deixa `options` e `create` "a confirmar" (P-05), mas a sonda foi respondida no hardware: Create e Options apertados isoladamente geraram `create` e `options` (`_reversa_forward/001-poc-entrada-ponteiro/validation-report.md:136`). 🟢 Mapeamento confirmado; o comentário está desatualizado.

### 2.4 Observações

- 🟡 **O PS do HID não identifica o controle de origem.** `ExtendedReportActivator` observa todos os DualSense, e `onHomeButton` entrega o PS à chave ativa (`ControllerReader.swift:38-44`). Com dois controles, o PS do controle **em fila** age como PS do ativo, contrariando RN-01.
- 🟡 **Promoção sem registro.** `DisconnectOutcome.promoted` é calculado (`ActiveControllerRegistry.swift:56`), mas `ControllerReader.disconnect` o ignora; não há evento de log quando o controle em fila passa a ativo.
- 🟢 Eixos e posições do toque nunca vão ao log (RN-12); só as fronteiras do toque (`input.touch`) e as transições brutas (`touch.raw_transition`, em debug).
- 🟢 `LoggingInputSink` é o destino provisório da fase 1, substituído pelo `InputRouter` antes de o leitor iniciar (`AppDelegate.swift:118`).

---

## 3. `pointer`

**Propósito:** converter analógico esquerdo e touchpad em movimento, analógico direito em rolagem e R1, R2 e o clique do touchpad em cliques e arrastes; manter o cursor dentro das telas.

**Arquivos:** `JoystickCore/Pointer/` (`ClickStateMachine`, `Geometry`, `PointerMotionEngine`, `PointerSettings`, `ScreenUnion`, `ScrollMapper`, `StickKinematics`, `TouchpadTracker`), `JoystickAIPoC/Pointer/` (`InputRouter`, `MotionLoop`, `ButtonActions`), `JoystickAIPoC/Display/` (`DisplayMonitor`, `ScreenCatalog`).

### 3.1 Fluxo de controle

- **`InputRouter.handle`** (`InputRouter.swift:38-69`): 🟢
  - Botões: sempre `ButtonActions` primeiro, de modo que R1, R2 e o touchpad clicam em qualquer modo. No modo de identificação, botões fora dos de apontamento vão só ao editor, e apenas o `buttonDown` não sintético, na main. Fora dele: `noteActivity` da paleta; paleta aberta recebe o botão, fechada deixa-o aos atalhos; `onButtonDown` alimenta a tela de alvos.
  - Eixos e toque: `noteActivity` e `MotionLoop`.
  - Desconexão: fecha a paleta (`disconnected`) e repassa a botões, atalhos e movimento.
- **`setIdentifying(true)`** fecha a paleta (`identify`) e solta as teclas mantidas (`InputRouter.swift:29-36`). 🟢
- **`MotionLoop.handle`** (`MotionLoop.swift:30-59`): analógico esquerdo → `engine.setLeftStick`; direito → `setRightStick` e, na saída da zona morta, rolagem imediata; toque → `TouchpadTracker` e `engine.touchDelta`; desconexão zera tudo. 🟢
- **Temporizador único de 120 Hz** (`DispatchSource` `.strict`, folga de 1 ms, na fila `input`) liga quando um analógico sai do repouso e desliga quando os dois voltam (`MotionLoop.swift:92-106`). Cada tick usa `dt` real limitado a 50 ms (`:72-84`). 🟢

### 3.2 Algoritmos e fórmulas

| Algoritmo | Fórmula / regra | Local | Confiança |
|-----------|-----------------|-------|-----------|
| Velocidade do analógico | `h = hypot(x,y)`, `m = min(1,h)`, `v = stickMaxSpeed · m^stickExponent`, direção `(x/h, −y/h)` | `StickKinematics.swift:29-35` | 🟢 |
| Deslocamento por tick | `d = v · dt · (precisão ? precisionFactor : 1)` | `StickKinematics.swift:37-41` | 🟢 |
| Onset do analógico | Na saída da zona morta, emite de imediato um deslocamento de `dt = 1/120` e liga o temporizador (latência do bloco d) | `PointerMotionEngine.swift:56-72` | 🟢 |
| Precisão (RN-08) | Ativa **só** quando o conjunto de pressionados é exatamente `{L1}`; vale para analógico e touchpad | `PointerMotionEngine.swift:52-54,89-97` | 🟢 |
| Subpixel | Emite a parte inteira truncada em direção a zero e acumula o resto | `StickKinematics.swift:45-57` | 🟢 |
| Touchpad relativo | Só o primeiro dedo move; a primeira amostra de cada toque só fixa a referência; `Δ = (Δx, −Δy) · 400 · touchpadSensitivity`; o dedo restante assume sem salto | `TouchpadTracker.swift:8,17-47` | 🟢 |
| Descarte da atualização por eixo | Amostra em que um eixo fica igual e o outro entra ou sai do zero exato é estado intermediário do `GameController`, não movimento | `TouchpadTracker.swift:55-57` | 🟢 |
| Toque com temporizador ligado | O delta do touchpad acumula e sai no próximo tick; sem temporizador, sai de imediato | `PointerMotionEngine.swift:89-97` | 🟢 |
| Rolagem | `porSegundo = scrollSpeed · (pixel ? 20 : 1)`; `vertical = y · porSegundo · dt · (invertScrollY ? −1 : 1)`; `horizontal = −x · porSegundo · dt`; resto fracionário acumulado | `ScrollMapper.swift:12,25-35` | 🟢 |
| Clique esquerdo com dois detentores | R1 e o clique do touchpad seguram o mesmo botão esquerdo; `mouseUp` só com os dois soltos | `ClickStateMachine.swift:44-65` | 🟢 |
| Duplo clique (RN-09) | `clickState = anterior + 1` se o intervalo for ≤ `doubleClickIntervalMs` **e** a distância ≤ 4 pt; senão 1; sem teto | `ClickStateMachine.swift:21,83-89` | 🟢 |
| Arraste | Com o esquerdo mantido, `leftMouseDragged`; com o direito, `rightMouseDragged` | `ClickStateMachine.swift:36-40`, `EventInjector.swift:75-79` | 🟢 |
| Limite às telas | União dos retângulos ativos (máx. exclusivo); fora deles, o ponto mais próximo do retângulo mais próximo, recuado 1 pt da borda | `ScreenUnion.swift:11-31` | 🟢 |
| Reconfiguração de telas | Chamadas agregadas em 200 ms; atualiza a união; se o cursor ficou fora, `CGWarpMouseCursorPosition` e `cursor.reclamped` | `DisplayMonitor.swift:44-70` | 🟢 |

### 3.3 Mapeamento fixo de cliques 🟢

R1 e clique do touchpad → botão esquerdo; R2 → botão direito. O comentário registra que é a **inversão** de RN-11, pedida pelo usuário no PM-3 (`ClickStateMachine.swift:18-19`). `ShortcutConfig.pointerButtons` mantém os três fora dos atalhos (`ShortcutConfig.swift:33`).

### 3.4 Observações

- 🟢 `pointer` não é recarregado em tempo real: `PointerSettings` é lido só no início (`AppDelegate.swift:50-52`), e mudar `pointer` no arquivo exige reiniciar o app.
- 🟡 Enquanto a precisão está ativa, qualquer segundo botão pressionado (inclusive R1 durante um arraste) a desliga no mesmo tick, pois `precisionActive` exige `pressed == [.l1]`. Isso vale para arrastes precisos com L1+R1.
- 🟡 O `clickState` cresce sem limite em cliques rápidos sucessivos (3, 4, 5…), o que o macOS interpreta como clique triplo e além.

---

## 4. `injection`

**Propósito:** postar eventos sintéticos de mouse, rolagem e teclado com uma marca que os distingue do hardware.

**Arquivos:** `JoystickAIPoC/Injection/EventInjector.swift` (148), `KeyboardInjector.swift` (116), `ScrollInjector.swift` (23).

### 4.1 Regras

| Regra | Local | Confiança |
|-------|-------|-----------|
| Todos os eventos saem por `CGEventSource(.hidSystemState)`, recebem `eventSourceUserData = 0x4A4F5953` e são postados em `.cghidEventTap` | `EventInjector.swift:10,28,134-142` | 🟢 |
| `enabled = false` (padrão) descarta tudo em silêncio; só o `InjectionGate` o altera | `EventInjector.swift:22,65-66,90` | 🟢 |
| Posição acompanhada: enquanto a leitura do sistema for uma das últimas 32 posições postadas e houver menos de 100 ms desde a última emissão, vale a posição acompanhada; qualquer outra leitura vem do mouse físico e passa a valer | `EventInjector.swift:16-48,55-62` | 🟢 |
| Movimento: destino limitado à união das telas; `mouseEventDeltaX/Y` com a diferença arredondada | `EventInjector.swift:65-87` | 🟢 |
| Registro `pointer.posted` só com `origin` (onset, toque, botão); ticks de 120 Hz não registram (D-19) | `EventInjector.swift:64,143-146` | 🟢 |
| Clique de ativação do editor: `down`/`up` na barra de título e volta do cursor, sem registro (E003) | `EventInjector.swift:115-131` | 🟢 |
| Modificadores com contagem de referência: só o primeiro `down` e o último `up` postam `flagsChanged`; `flags` do evento = modificadores com contagem > 0 | `KeyboardInjector.swift:11,35-50,96-103` | 🟢 |
| Códigos virtuais: ⌘ 55, ⇧ 56, ⌥ 58, ⌃ 59 | `KeyboardInjector.swift:17-24` | 🟢 |
| Setas recebem `maskNumericPad` e `maskSecondaryFn`, como as físicas, para os atalhos de Mission Control | `KeyboardInjector.swift:110-111` | 🟢 |
| Repetição marca `keyboardEventAutorepeat = 1` | `KeyboardInjector.swift:113` | 🟢 |
| Texto: uma unidade UTF-16 por par `down`/`up` com `keyboardSetUnicodeString`, `virtualKey 0`, sem flags; independe do layout | `KeyboardInjector.swift:79-94` | 🟢 |
| `forceUp` e `forceModifierUp` repetem solturas na retomada, mas só postam o modificador se a contagem estiver zerada | `KeyboardInjector.swift:68-76` | 🟢 |
| Rolagem por `CGEvent(scrollWheelEvent2Source:)`, 2 rodas, em pixel ou linha; passos nulos não postam | `ScrollInjector.swift:15-22` | 🟢 |

### 4.2 Observações

- 🟡 **Unidades UTF-16 isoladas.** Caracteres fora do BMP (emoji) são enviados como dois eventos com metade de um par substituto cada; o comportamento depende do aplicativo de destino.
- 🟡 **Contagem de modificadores com injeção desativada.** Com `enabled = false`, `modifierDown` incrementa a contagem sem postar; o `modifierUp` correspondente mantém a coerência, mas a primeira tecla após a retomada sai sem o modificador que o botão ainda segura.
- 🟢 `KeyboardInjector` não registra teclas nem textos no log (RN-14).

---

## 5. `shortcuts`

**Propósito:** traduzir os botões que não são de apontamento em acordes, atalhos de sistema, textos e abertura da paleta, com camadas por botão modificador.

**Arquivos:** `JoystickCore/Shortcuts/` (`KeyCatalog`, `KeyRepeat`, `ShortcutMapper`), `JoystickAIPoC/Pointer/ShortcutActions.swift`.

### 5.1 Algoritmo do mapeador (`ShortcutMapper`) 🟢

1. `press(button)`: zera `lastTrigger`; ignora repetição de botão já segurado; ignora botões de apontamento (`ShortcutMapper.swift:163-166`).
2. Se o botão é modificador: entra no fim de `modifierOrder` e emite `modifierDown` de cada tecla em ordem ⌃⌥⇧⌘ (`:167-170`).
3. Senão, **resolve no pressionar** pela camada vigente = modificador segurado **há mais tempo** (`modifierOrder.first`, `:161`): ação própria da camada, herdada da base ou "nenhuma" (`ShortcutConfig.swift:60-65`).
4. Acordes e atalhos de sistema ficam em `resolved[button]` até o soltar, mesmo que o modificador seja solto antes (RN-01). Texto e abrir paleta não se mantêm (`:175-188`).
5. `lastTrigger` só é preenchido para ações diferentes de "nenhuma" (`:189-191`).
6. `release`: modificador sai de `modifierOrder` e emite `modifierUp`; demais emitem o `up` guardado (`:195-202`).
7. `releaseAll`: solta resolvidos em ordem de `ButtonID` e os modificadores na ordem em que foram segurados, e zera tudo (`:206-216`).

### 5.2 Executor (`ShortcutActions`) 🟢

| Regra | Local |
|-------|-------|
| `shortcut.triggered` é registrado **depois** de executar, com o gatilho lido **antes**, porque abrir a paleta zera o mapeador | `ShortcutActions.swift:30-36` |
| `openPalette` solta primeiro tudo o que estiver mantido e depois abre (002 D-04) | `:98-100` |
| Atalho de sistema: acorde lido de `com.apple.symbolichotkeys` → `AppleSymbolicHotKeys` **no instante do uso**; o acorde efetivamente pressionado fica guardado para o soltar | `:101-107,114-117` |
| Aplicar configuração nova: para a repetição, solta tudo e recria o mapeador; botões segurados durante a troca ficam ignorados até serem soltos | `:50-55` |
| `releaseAll` converte cada `systemUp` no `keyUp` do acorde pressionado, para a retomada da injeção repetir a soltura certa | `:60-69` |
| Repetição: 400 ms e depois a cada 50 ms, um só temporizador; um novo acorde repetido substitui o anterior | `KeyRepeat.swift:7-8`, `ShortcutActions.swift:119-133` |

### 5.3 Catálogos 🟢

- **`KeyCatalog`**: 73 teclas em 6 grupos (26 letras, 10 dígitos, 11 pontuações, 6 de edição, 8 de navegação, F1–F12), nome estável ↔ código virtual `kVK_*` (`KeyCatalog.swift:26-105`). Tecla fora da tabela não pode ser gravada (D-03).
- **`SystemShortcut`**: `nextWindow` (27, ⌘\`), `missionControl` (32, ⌃↑), `applicationWindows` (33, ⌃↓), `spaceLeft` (79, ⌃←), `spaceRight` (81, ⌃→). A máscara de `AppleSymbolicHotKeys` é convertida por bits: `0x20000` ⇧, `0x40000` ⌃, `0x80000` ⌥, `0x100000` ⌘. Entrada ausente, **desativada** ou malformada mantém o padrão (`ShortcutMapper.swift:38-103`).

### 5.4 Observações

- 🟡 **Atalho de sistema desativado.** Se o usuário desativou "Mission Control" nos Ajustes, o código posta ainda assim o acorde padrão (`:89`), que pode acionar outra função ou nenhuma.
- 🟡 **Camada pelo modificador mais antigo.** Com L1 e L2 segurados, vale a camada de quem foi segurado primeiro, e não há camada combinada (RN-03). É uma decisão, não um defeito, mas tende a surpreender quem espera a do último.
- 🟢 Com a paleta aberta, botões não chegam ao mapeador (`InputRouter.swift:50-54`); o `buttonUp` de um botão pressionado antes da abertura cai na paleta e é ignorado, mas `openPalette` já soltou tudo.

---

## 6. `palette`

**Propósito:** lista flutuante de textos, navegada pelo direcional e confirmada por ✕, que digita no aplicativo em foco sem roubar o foco; última entrada fixa abre o editor.

**Arquivos:** `JoystickCore/Palette/CommandPalette.swift` (178), `JoystickAIPoC/Palette/PaletteActions.swift` (163), `PalettePanel.swift` (177).

### 6.1 Máquina de estados (`PaletteMachine`) 🟢

| Estado | Entrada | Efeitos | Próximo |
|--------|---------|---------|---------|
| fechada | `open()` | `render(aberta, seleção = último confirmado ?? 0)` | aberta |
| fechada | qualquer outra | nenhum | fechada |
| aberta | ↑ / ↓ pressionado | passo circular sobre `itens + 1`; `render`; `startRepeat` | aberta (repetindo) |
| aberta | ↑ / ↓ solto (a mesma direção) | `stopRepeat` | aberta |
| aberta | tick de repetição | passo; `render` | aberta |
| aberta | ✕ na entrada fixa | `stopRepeat?`, `render(fechada)`, `openEditor`; **não** altera o último confirmado | fechada |
| aberta | ✕ num item | lembra o índice; `render(fechada)`; `confirm(índice+1, item)` | fechada |
| aberta | ○ / PS | `render(fechada)`; `closed(circle\|ps)` | fechada |
| aberta | `close(motivo)` externo | `render(fechada)`; `closed(motivo)` | fechada |

Motivos externos: `disconnected`, `idle`, `injection_suspended`, `config_changed`, `identify` (`CommandPalette.swift:25-32`). Local: `CommandPalette.swift:86-178`.

### 6.2 Executor e painel

| Regra | Local | Confiança |
|-------|-------|-----------|
| Com a tela de alvos aberta, `open()` registra `palette.blocked` e não abre | `PaletteActions.swift:43-48` | 🟢 |
| Inatividade: consulta a cada 1 s; fecha com `idle` após 60 s sem entrada do controle | `PaletteActions.swift:11-12,145-157` | 🟢 |
| Confirmação: `palette.confirmed` com índice e `enter`, nunca o texto; digita o texto e, se `pressEnter`, Enter imediato (padrão 0 ms) ou após `--palette-enter-delay-ms` | `PaletteActions.swift:10,99-126` | 🟢 |
| Configuração nova: fecha com `config_changed`, recria a máquina **sem** último confirmado e atualiza o painel | `PaletteActions.swift:59-65` | 🟢 |
| Painel `NSPanel` sem borda, não ativador, nunca chave nem principal, transparente ao mouse, nível `statusBar`, em todas as mesas e sobre tela cheia | `PalettePanel.swift:12-30` | 🟢 |
| Posição: centro da área visível da tela que contém o cursor, calculada só ao abrir | `PalettePanel.swift:50-58` | 🟢 |
| Legibilidade a 3 m: fonte monoespaçada de 26 pt, linha de 40 pt, largura mínima de 520 pt, marcador ▶, rolagem quando não cabe | `PalettePanel.swift:65-139` | 🟢 |
| Item sem rótulo terminado em espaço aparece com " …" (espera argumento) | `PalettePanel.swift:74,113-118` | 🟢 |
| Paleta padrão: 17 itens de comandos do Reversa e do Claude Code, nenhum com Enter | `CommandPalette.swift:37-57` | 🟢 |

### 6.3 Observações

- 🟡 **Abre sem permissão.** Com a Acessibilidade ausente desde o início, o portão nunca transita, a paleta abre e a confirmação não digita nada, sem aviso na tela.
- 🟡 **Enter atrasado não é cancelado.** O `asyncAfter` do Enter (`PaletteActions.swift:119`) dispara mesmo se, nesse intervalo, o foco mudar ou a paleta reabrir.
- 🟢 `PaletteMachine.init` tem `precondition(!items.isEmpty)`: a validação (`paletteEmpty`) e o rascunho (`lastPaletteItem`) impedem lista vazia, mas um documento sem validação que chegue a `apply(items:)` derrubaria o processo (ver 8.4).

---

## 7. `config`

**Propósito:** ler, validar, localizar erros, observar, gravar e aplicar `~/.config/joystick-ai/config.json` (seções `pointer`, `shortcuts` e `palette`).

**Arquivos:** `JoystickCore/Config/` (`ActionSummary`, `ConfigDocument`, `ConfigLineLocator`, `ConfigLoader`, `PointerSettingsValidation`, `ShortcutConfig`, `ShortcutConfigValidation`, `ShortcutDefaults`), `JoystickAIPoC/Config/` (`ConfigStore`, `ConfigWatcher`, `ConfigWriter`), `scripts/config-samples/`.

### 7.1 Leitura (`ConfigLoader`) 🟢

1. Arquivo ausente → padrões, `file_missing`; **nunca cria o arquivo** (`ConfigLoader.swift:39,52-55`).
2. Diretório, maior que 1 MiB ou ilegível → `unreadable` (`:56-70`).
3. JSON malformado → `invalidJSON` com linha, extraída de "around line N" ou do deslocamento `NSJSONSerializationErrorIndex` (`:78-81,115-143`).
4. Raiz não objeto → `invalidJSON` e `wrongType` na linha 1 (`:82-86`).
5. `pointer` validado campo a campo: valor fora da faixa, com tipo errado ou fracionário em campo inteiro é recusado, vira `config.value_rejected` e o campo fica no padrão; os demais valem (`PointerSettingsValidation.swift:11-51`).
6. `shortcuts` e `palette` decodificados e validados **juntos**: qualquer problema em uma recusa as duas (RN-08); cada problema ganha a linha pelo `ConfigLineLocator` (`ConfigLoader.swift:97-110`).

### 7.2 Validação de atalhos e paleta (`ShortcutConfigValidation`) 🟢

**Estrutural** (`SectionDecoder`, `:129-271`): `version` obrigatório e igual a 1; nomes de botão, camada (`base` ou botão) e modificador conhecidos; `type` ∈ {`chord`, `systemShortcut`, `text`, `openPalette`, `none`}; lista de modificadores sem repetição; `repeat`, `pressEnter` e `label` opcionais; camada vazia equivale a ausente.

**Semântica** (`validate`, `:12-62`):

| Regra | Condição |
|-------|----------|
| `pointerButtonNotAllowed` | R1, R2 ou touchpad como modificador ou gatilho |
| `layerWithoutModifier` | camada de um botão que não é modificador |
| `modifierHasAction` | ação (inclusive "nenhuma" explícita) para um botão modificador, em qualquer camada |
| `unknownKey` | acorde com código fora do `KeyCatalog` |
| `textEmpty` / `multiline` / `textTooLong` | texto vazio, com quebra de linha ou acima de 1.000 caracteres |
| `labelTooLong` / `multiline` | rótulo acima de 80 caracteres ou com quebra |
| `paletteEmpty` / `paletteTooLong` | 0 itens ou mais de 50 |

Os problemas citam caminho e regra, nunca o valor (RN-14).

### 7.3 Localização de linha (`ConfigLineLocator`) 🟢

Varredura léxica própria (o `JSONDecoder` não informa posições): percorre objetos e listas por caminho (`shortcuts.layers.l2.dpadLeft`, `palette.items[3].text`), respeita escapes e conta CRLF uma vez. `nearestLine` recua ao ancestral existente mais longo quando o valor não existe (`ConfigLineLocator.swift:15-30,60-184`).

### 7.4 Estado, observação e gravação 🟢

- **`ConfigStore`** (main): guarda `current`, `status`, `lastBytes` e `source`. Leitura inválida **nunca** substitui a vigente. Remoção do arquivo mantém a vigente até o próximo início (`file_removed`). Bytes iguais aos últimos lidos ou gravados geram só `shortcuts.unchanged`, o que evita reaplicar a própria gravação (`ConfigStore.swift:67-94`).
- **`ConfigWatcher`**: sem varredura periódica. Observa o diretório do arquivo e o do destino do link simbólico (ou o ancestral existente mais próximo) e o próprio arquivo, com `write`, `extend`, `rename` e `delete`; reabre as observações a cada evento e agrega releituras em 150 ms (`ConfigWatcher.swift:3-94`).
- **`ConfigWriter`**: resolve até 16 níveis de link simbólico; se o arquivo atual tem erro de sintaxe (ou raiz não objeto), exige confirmação e copia-o para `config.json.bak`; senão funde, preservando as outras chaves da raiz (inclusive `pointer`) e substituindo só `shortcuts` e `palette`; grava por troca atômica, com chaves ordenadas, `prettyPrinted`, barras sem escape e quebra final (`ConfigWriter.swift:24-61`, `ConfigDocument.swift:69-79`).
- **Codificação** omite `modifiers` vazio, `repeat` falso e camadas vazias, mas sempre escreve `pressEnter` e `label`, para que o mesmo documento produza os mesmos bytes (`ConfigDocument.swift:3-65`).

### 7.5 Mapeamento padrão (`ShortcutDefaults`) 🟢

Modificadores: L1 (sem teclas), L2 (sem teclas), Options (⌘). Base: direcional → setas com repetição; ✕ Enter; ○ Esc; □ Delete com repetição; △ Tab; Create → Mission Control; R3 → ⌘M (transcritor do Raycast); PS → abrir paleta; L3 → nenhuma. Camada L1: ✕ texto "CONTINUAR" + Enter; △ ⇧Tab. Camada L2: ←/→ mesas, ↓ janelas do aplicativo, ↑ Mission Control, △ próxima janela. Camada Options: → ⌘Tab, ← ⌘⇧Tab, todos os demais "nenhuma" (`ShortcutDefaults.swift:8-52`).

### 7.6 Observações

- 🟡 **`pointer` com tipo errado passa despercebido.** Se `pointer` existir mas não for objeto (`"pointer": 5`), a leitura o trata como `section_missing`, sem `config.value_rejected` nem erro (`ConfigLoader.swift:89-94`).
- 🟡 **Camada vazia de não modificador.** `"layers": {"l3": {}}` com L3 não modificador não gera `layerWithoutModifier`, porque o decodificador descarta camadas vazias antes da validação (`ShortcutConfigValidation.swift:175`).
- 🟡 **Limite de tamanho só na leitura.** `ConfigWriter` lê o arquivo existente sem o limite de 1 MiB antes de fundir.
- 🟢 A validação de `pointer` e a de atalhos são independentes: `pointer` inválido nunca recusa atalhos, e vice-versa.

---

## 8. `editor`

**Propósito:** janela em escala de TV para editar camadas, ações, modificadores e paleta, operável pelo ponteiro do controle, com gravação no arquivo e tratamento de conflitos.

**Arquivos:** `JoystickCore/Config/EditorDraft.swift` (236), `JoystickAIPoC/Editor/` (`EditorViewModel`, `EditorWindowController`, `EditorRootView`, `ShortcutsTab`, `ControllerFigureView`, `ActionPanel`, `ChordEditor`, `KeyCaptureField`, `PaletteTab`, `EditorBanners`, `EditorLabels`, `EditorMetrics`), `JoystickAIPoC/App/EditMenu.swift`.

### 8.1 Rascunho (`EditorDraft`) 🟢

- `base` (vigente) e `document` (editado); `isDirty = document != base`; `issues` = a mesma validação da leitura (D-05), convertida em alvos (`trigger`, `modifier`, `paletteItem`, `palette`) (`EditorDraft.swift:46-101`).
- Aviso não bloqueante `noPaletteTrigger` quando nenhum gatilho válido abre a paleta (`:66-72`).
- Operações recusadas com mensagem: botão de apontamento, texto multilinha ou longo, rótulo longo, paleta cheia (50) e remoção do último item (`:29-41`).
- **Marcar modificador** tira as "nenhuma" explícitas do botão das camadas e as lembra; ações reais permanecem e viram `modifierHasAction`. **Desmarcar** remove a camada do botão e devolve as "nenhuma" lembradas às camadas que ainda existem e não ganharam ação (`:117-143`).
- Camadas vazias saem do dicionário, para que o rascunho compare igual ao documento lido (`:146-148`).
- Reordenação por arrastar na convenção de `onMove` do SwiftUI (`:178-184`).
- `restoreDefaults` troca o documento pelos padrões sem mudar a base; `rebase(to:keepChanges:)` troca a base e opcionalmente preserva o documento (`:220-230`).

### 8.2 Modelo e janela 🟢

| Regra | Local |
|-------|-------|
| A cada abertura: rascunho limpo é rebaseado na vigente; configuração inválida vira faixa `externalInvalid`; mensagens zeradas; camada selecionada inexistente volta à base | `EditorViewModel.swift:60-76` |
| "Salvar" só com rascunho sujo e sem problemas | `:78` |
| Mudança externa com rascunho sujo → faixa de conflito e `editor.conflict(pending)`; "Recarregar do arquivo" descarta; "Manter minhas alterações" rebaseia preservando o documento | `:225-253` |
| Arquivo atual com erro de sintaxe → faixa pedindo confirmação da cópia para `.bak`, para salvar ou restaurar | `:204-221`, `EditorBanners.swift:25-32` |
| Fechar sujo abre folha Salvar/Descartar/Cancelar; falha ao salvar mantém a janela aberta com a faixa | `EditorWindowController.swift:121-151` |
| Perder o foco ou fechar desliga o modo de identificação | `:153-160` |
| Ativação no macOS 26: `NSApp.activate()`; se não ativar, nível `floating`, clique sintético no centro da barra de título após 150 ms e `editor.activation_failed` após mais 500 ms; ao ativar, volta ao nível normal (E003) | `:55-90` |
| Ao fechar, devolve o foco ao aplicativo que estava à frente na abertura | `:167-179` |
| Rolagem só vertical, porque com os dois eixos os botões paravam de responder após redimensionar (PM-1a) | `:113-115` |
| Gravação de acorde pelo teclado só com o campo ativo e a janela em foco, por monitor **local**; descarta eventos com a marca do injetor; ⌘Tab e ⌘Espaço só pela montagem | `KeyCaptureField.swift:12-89` |
| Menu principal oculto só com "Editar", sem "Sair", para ⌘V/⌘C/⌘X/⌘A/⌘Z chegarem aos campos (inclusive o ditado do Raycast, que cola) | `EditMenu.swift:3-37` |
| Escala de TV: corpo 32 pt, título 40 pt, alvo mínimo 60 pt, janela mínima 1.400 × 800 pt | `EditorMetrics.swift:9-17` |

### 8.3 Interface 🟢

- **Atalhos:** seletor de camada (base + modificadores); figura de 830 × 620 pt com os 18 botões nas posições físicas, resumo da ação por camada, herdados esmaecidos, fixos e modificadores em cinza, problemas em vermelho (`ControllerFigureView.swift:9-70`); painel com tipo de ação (Acorde, Atalho de sistema, Texto, Abrir paleta, Nenhuma, Herdar da base), alternador "Este botão é modificador" com confirmação ao desmarcar e as quatro teclas (`ActionPanel.swift:8-200`).
- **Troca de tipo:** o acorde aproveitado começa **sem repetição**, para que ⌘Tab herdado de ↓ não repita (PM-2); texto novo começa vazio e aparece como problema (`ActionPanel.swift:181-199`).
- **Paleta:** linhas com rótulo, texto, Enter, mover para cima ou para baixo, remover e arrastar; inclusão no topo ou no fim (`PaletteTab.swift:7-103`).

### 8.4 Observações

- 🟡 **Gravação com problemas pela confirmação da cópia.** `save(confirmBackup:)` aceita gravar quando `confirmBackup` é verdadeiro mesmo sem `canSave` (`EditorViewModel.swift:172`). Se o usuário editar o rascunho entre o aparecimento da faixa e "Copiar e gravar", o documento pode ter problemas; `ConfigStore.write` não revalida e aplica à fila `input`. Uma paleta vazia é impedida pelo rascunho, mas texto vazio ou ação em modificador chegariam ao arquivo e ao mapeador, e a próxima leitura do arquivo o recusaria.
- 🟡 **Identidade das linhas da paleta por índice.** `ForEach(..., id: \.offset)` com `TextField` pode reaproveitar o estado de edição da linha errada após reordenar ou remover (`PaletteTab.swift:21`).
- 🟢 O editor nunca registra textos, rótulos, teclas nem acordes; só origem, resultado, conflito e identificação.

---

## 9. `diagnostics-log`

**Propósito:** registro JSONL por sessão com esquema tipado e sem dados sensíveis, e utilitários de JSON e relógio.

**Arquivos:** `JoystickCore/Log/LogEvent.swift` (48), `LogEventCatalog.swift` (333), `JoystickCore/Support/JSONValue.swift` (156), `MonotonicClock.swift` (8), `JoystickAIPoC/Log/DiagnosticLog.swift` (108).

### 9.1 Regras 🟢

| Regra | Local |
|-------|-------|
| Um arquivo por sessão: `~/Library/Logs/joystick-ai/poc-AAAAMMDD-HHMMSS.jsonl`, com `-2`, `-3`… em colisão | `DiagnosticLog.swift:38-80` |
| Linha: `ts_ns`, `wall` (ISO 8601 com milissegundos e fuso), `level` e `event` à frente; demais campos em ordem alfabética | `LogEvent.swift:33-47` |
| `ts_ns` e `t_*` em nanossegundos de `CLOCK_UPTIME_RAW`, tomados no chamador | `MonotonicClock.swift:5-7`, `DiagnosticLog.swift:44-54` |
| Níveis `debug < info < warn < error`; `debug` só com `--debug` | `LogEvent.swift:4-17`, `DiagnosticLog.swift:45` |
| Buffer descarregado a cada 250 ms ou ao passar de 256 KiB; `flushSync` no encerramento | `DiagnosticLog.swift:8-9,57-59,87-107` |
| Acima de 50 MiB escritos, eventos `debug` são suspensos e registra-se `log.debug_suspended` uma vez | `DiagnosticLog.swift:10,102-106` |
| Falha ao abrir o arquivo vai ao `os.Logger` (subsistema `dev.iagoleal.joystick-ai.poc`) e o app segue sem log | `DiagnosticLog.swift:81-84` |
| Falha de escrita no meio da sessão descarta o pendente, sem aviso | `DiagnosticLog.swift:95-101` |
| Catálogo com **50 eventos** tipados; nenhuma fábrica aceita coordenadas, deltas, posições de toque, valores de eixo, textos, rótulos ou acordes (RN-12, RN-14) | `LogEventCatalog.swift:33-333` |
| `JSONValue`: serialização determinística com chaves ordenadas; `double` inteiro sai com `.0`; não finitos saem como `null`; decodificação tenta bool, Int64, UInt64, Double, String, lista e objeto, nessa ordem | `JSONValue.swift:15-149` |

### 9.2 Observações

- 🟡 **Sem rotação nem limpeza.** Os eventos `info`, `warn` e `error` não têm teto, e os arquivos antigos nunca são apagados.
- 🟡 **`session.start` registra todos os argumentos** (`args`), e por isso qualquer valor passado por `open --args` vai ao log.

---

## 10. `targets-analysis`

**Propósito:** instrumento de medição da PoC: tela de 20 alvos para taxa de acerto e CLI `poc-tools`, que analisa log e resultados.

**Arquivos:** `JoystickCore/Targets/TargetRun.swift` (180), `JoystickCore/Analysis/` (`LatencyStats`, `LogAnalysis`, `RunsReport`), `JoystickAIPoC/Targets/` (`TargetSession`, `TargetWindow`, `TargetAbortMonitor`, `TargetRunWriter`), `Sources/poc-tools/`.

### 10.1 Tela de alvos 🟢

| Regra | Local |
|-------|-------|
| 20 tentativas; alvos de 16 × 16 pt com margem de 40 pt; posições por SplitMix64 a partir da semente, reprodutíveis | `TargetRun.swift:74-76,151-179` |
| Janela sem borda, nível `statusBar`, sobre a tela escolhida, fundo cinza 55%, contador no topo | `TargetWindow.swift:5-66` |
| Só cliques com a marca do injetor contam; cliques físicos são descartados e contados em `ignoredPhysicalClicks` | `TargetSession.swift:72-79` |
| Acerto = ponto do clique dentro do retângulo; o ponto não é guardado (RN-12); registra tempo desde a exibição e se L1 estava pressionado | `TargetSession.swift:85-94` |
| Interrupções: Esc, ○ no controle, remoção da tela escolhida, suspensão da injeção | `TargetSession.swift:69-71`, `TargetAbortMonitor.swift:24-38` |
| Completa: mostra o resumo por 3 s e grava; incompleta: grava de imediato; `abortReason` é anulado quando completa | `TargetSession.swift:107-131`, `TargetRun.swift:100` |
| Arquivo `~/Library/Application Support/joystick-ai/target-runs/AAAAMMDD-HHMMSS-<env>.json`, sem sobrescrever; em falha, o JSON compacto vai ao log em `targets.write_failed` | `TargetRunWriter.swift:14-47`, `TargetRun.swift:135-148` |
| Resumo: acertos, total, taxa, tempo médio arredondado e taxas com e sem L1 | `TargetRun.swift:110-124` |

### 10.2 `poc-tools` 🟢

| Subcomando | Cálculo | Local |
|------------|---------|-------|
| `buttons <log>` | Botões com `down` e `up` não sintéticos em `input.button` (exige `--debug`) | `ButtonsCommand.swift`, `LogAnalysis.swift:47-59` |
| `runs [--env] [--dir]` | Tabela Markdown só das sequências completas, ordenadas por início; parâmetros diferentes do padrão; tentativas acima de 60 s como discrepantes | `RunsCommand.swift`, `RunsReport.swift:4-61` |
| `latency <log>` | p50, p95 e máximo pelo método da posição mais próxima; processamento `t_delivered − t_arrival` (meta 5 ms) e entrada ao movimento `t_posted − t_arrival` de `touch` e `stick_onset` (meta 20 ms); aprovado se p95 ≤ meta | `LatencyCommand.swift:6-39`, `LatencyStats.swift:15-23`, `LogAnalysis.swift:81-99` |
| `cycles <log>` | Pares `controller.connected`/`disconnected` por `id`, conexões órfãs e sessões (mais de uma indica reinício) | `CyclesCommand.swift`, `LogAnalysis.swift:61-78` |

Saídas: 0 sucesso, 64 uso incorreto, 66 arquivo ou diretório inexistente; linhas malformadas e arquivos ilegíveis viram aviso em stderr (`ToolInput.swift:6-33`, `RunsCommand.swift:54-56`). 🟢

### 10.3 Observações

- 🟡 **Ativação da tela de alvos.** `TargetSession.start` usa `NSApp.activate(ignoringOtherApps:)` (`:54`), o mesmo pedido que a sonda P-01 mostrou ser recusado no macOS 26 quando vem do controle; a janela `statusBar` fica visível, mas pode não receber o Esc do teclado.
- 🟡 **`TargetAbortMonitor` sobrescreve callbacks.** `displayMonitor.onChange` e `gate.onSuspended` são atribuídos, não encadeados; hoje não há outro consumidor, mas qualquer uso futuro seria perdido durante a sessão.
- 🟢 A medida de latência termina no `CGEvent.post`, não no pixel exibido (R-12).

---

## Resumo para o Reversa

- **Módulos analisados:** 10 de 10.
- **Principais algoritmos:** fila de controle ativo com soltura sintética; leitura do PS por relatório HID; inferência de toque por transição a zero com descarte de atualização por eixo; cinemática exponencial com subpixel e temporizador único de 120 Hz; duplo clique por tempo e distância; limite à união de telas; mapeador de camadas com resolução no pressionar e camada do modificador mais antigo; contagem de referência de modificadores; máquina da paleta com repetição e inatividade; validação estrutural e semântica com localizador léxico de linhas; fusão determinística com troca atômica e cópia `.bak`; rascunho do editor com memória de "nenhuma"; SplitMix64 e percentis pela posição mais próxima.
- **Entidades:** 74 tipos de dados documentados, entre structs, enums e formatos de arquivo (ver `data-dictionary.md`).
- **Observações 🟡 registradas:** 21, das quais as de maior impacto são o PS de controle em fila agindo como o ativo (2.4), a gravação com problemas pela confirmação da cópia (8.4) e a abertura da paleta sem permissão (6.3).
- **Lacunas 🔴:** nenhuma no código. O mapeamento `options`/`create` (2.3) foi confirmado pela P-05 no `validation-report.md` da 001; o ditado por voz é componente planejado e não implementado, como registra o adendo 001 (`inventory.md` §10).
