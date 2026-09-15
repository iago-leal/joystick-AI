# Ponteiro (pointer), Design Técnico

> Gerado pelo Redator em 2026-09-15 · Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA

## Interface

### Núcleo (`JoystickCore/Pointer`) 🟢

| Símbolo | Assinatura | Retorno | Observação |
|---------|-----------|---------|------------|
| `PointerSettings` | `touchpadSensitivity 1.0`, `stickMaxSpeed 1500`, `stickExponent 2.0`, `deadzone 0.12`, `scrollSpeed 40`, `invertScrollY false`, `precisionFactor 0.3`, `doubleClickIntervalMs 400` | — | `range(for:)` e `jsonValue` usados pela validação e pelo log |
| `StickKinematics.velocity` | `(x:y:maxSpeed:exponent:)` | `(vx, vy)` pt/s | RN-PT-06 |
| `StickKinematics.displacement` | `(x:y:settings:dt:precision:)` | `PointDelta` | `v · dt · (precision ? precisionFactor : 1)` |
| `SubpixelAccumulator.take` | `(dx:dy:)` | `PointDelta` inteiro | `total = resto + d`; `inteiro = total.rounded(.towardZero)`; `resto = total − inteiro` |
| `PointerMotionEngine.precisionActive` | `(pressed: Set<ButtonID>)` | `Bool` | `pressed == [.l1]` |
| `PointerMotionEngine.setLeftStick` | `(x:y:pressed:)` | `MotionOutput` | Onset e parada |
| `PointerMotionEngine.setRightStick` | `(x:y:)` | `MotionOutput` | `scrollOnset` e parada |
| `PointerMotionEngine.touchDelta` | `(PointDelta, pressed:)` | `MotionOutput` | Escala por precisão; acumula ou emite |
| `PointerMotionEngine.tick` | `(dt:pressed:)` | `MotionOutput` | Só com temporizador ligado |
| `MotionOutput` | `move: PointDelta?`, `timer: none/start/stop`, `stickOnset`, `scrollOnset` | — | — |
| `TouchpadTracker.update` | `(finger:phase:x:y:sensitivity:)` | `PointDelta?` | RN-PT-12, RN-PT-13 |
| `ClickStateMachine.press` / `release` | `(ButtonID, at: ScreenPoint, timeNs: UInt64)` | `MouseAction?` | `.down/.up(MouseButton, clickState)` |
| `ClickStateMachine.releaseAll` | `()` | `[MouseAction]` | Esquerdo antes do direito; zera detentores |
| `ClickStateMachine.moveKind` | — | `MoveKind` | `leftDrag` > `rightDrag` > `move` |
| `ScrollMapper.step` | `(x:y:dt:)` | `(vertical: Int32, horizontal: Int32)` | Convenção do `CGEvent`: vertical negativo rola para o fim, horizontal negativo para a direita |
| `ScrollMapper.reset` | `()` | — | Zera frações |
| `ScreenUnion.contains` / `clamp` | `(ScreenPoint)` | `Bool` / `ScreenPoint` | RN-PT-20 |

### App 🟢

| Símbolo | Assinatura | Observação |
|---------|-----------|------------|
| `InputRouter: InputSink` | `handle(InputEvent)`, `setIdentifying(Bool)`, `onButtonDown: ((ButtonID) -> Void)?`, `onIdentify: ((ButtonID) -> Void)?` | Fila `input`; `onIdentify` chamado na main |
| `MotionLoop` | `handle(InputEvent)` | Fila `input`; temporizador próprio |
| `ButtonActions` | `handle(InputEvent)`, `releaseAll() -> [MouseButton]`, `postReleases([MouseButton])`, `moveKind` | Fila `input` |
| `DisplayMonitor` | `start()`, `activeRects() -> [ScreenRect]`, `onChange: (() -> Void)?` | Main thread |
| `ScreenCatalog` | `listings()`, `emit(log:)`, `descriptor(for: NSScreen)`, `displayID(of:)` | Main thread |

## Fluxo Principal

### Roteamento (`InputRouter.handle`, `InputRouter.swift:38-69`)

1. `buttonDown`/`buttonUp`:
   1. `ButtonActions.handle(event)`.
   2. Se `identifying` e o botão não está em `ShortcutConfig.pointerButtons`: se `buttonDown` e não sintético, `DispatchQueue.main.async { onIdentify(button) }`; retorna.
   3. `palette.noteActivity()`; se `palette.isOpen`, `palette.handle`; senão `shortcuts.handle`.
   4. Se `buttonDown` não sintético, `onButtonDown?(button)`.
2. `axis`/`touch`: `palette.noteActivity()`; `motion.handle`.
3. `controllerDisconnected`: `palette.close(.disconnected)`; `buttons.handle`; `shortcuts.handle`; `motion.handle`.
4. `controllerConnected`/`controllerError`: ignorados.

`setIdentifying(on)`: sem mudança, nada; ao ligar, `palette.close(.identify)` e `shortcuts.releaseAll()`.

### Cliques (`ButtonActions.handle`)

`point = injector.currentLocation()`; `press` ou `release` na máquina com `event.timestamp`; se houver ação, `injector.post(action, tArrival:)`. Em `controllerDisconnected`, `releaseAll()` (posta cada `up`).

`ClickStateMachine.press`: R1/touchpad → insere detentor; se já havia detentor, `nil`; senão calcula `clickState` (RN-PT-17: exige `timeNs ≥ last.timeNs`, `Δt ≤ intervalo·10⁶ ns` e `hypot ≤ 4`), guarda `lastLeftClick`, marca esquerdo mantido e devolve `.down(.left, clickState)`. R2 → se o direito já estava mantido, `nil`; senão `.down(.right, 1)`. `release`: R1/touchpad → só devolve `.up(.left, clickStateAtual)` se o detentor existia, o conjunto ficou vazio e o esquerdo estava mantido; R2 → `.up(.right, 1)` se mantido.

### Movimento (`MotionLoop.handle`, `MotionLoop.swift:30-59`)

1. `pressed = registry.pressed`.
2. `axis leftStick` → `engine.setLeftStick`; aplica com origem `stickOnset` quando houver onset.
3. `axis rightStick` → `engine.setRightStick`; se `scrollOnset`, `scrollMapper.reset()` e `scrollStep(dt: 1/120, origem stickOnset)`; aplica.
4. `touch` → `tracker.update(sensitivity: engine.settings.touchpadSensitivity)`; se houver delta, aplica `engine.touchDelta` com origem `touch`.
5. `controllerDisconnected` → `setLeftStick(0,0,[])`, `setRightStick(0,0)`, novo `TouchpadTracker`, `scrollMapper.reset()`.

`apply(out)`: se `move`, `injector.move(by:kind: buttons.moveKind, origin:, tArrival: origin == nil ? nil : t)`; `timer .start` cria `DispatchSourceTimer(flags: .strict, queue: input)` com intervalo `1/120 s` e folga de 1 ms, e `lastTickNs = agora`; `.stop` cancela.

`tick()`: `dt = min(0,05, (agora − lastTickNs)/1e9)`; `engine.tick(dt, pressed)`; `move` sem origem; se o analógico direito não está em (0,0), `scrollStep(dt)` sem origem.

### Motor (`PointerMotionEngine`)

- `setLeftStick`: ativo = `x ≠ 0 ∨ y ≠ 0` (os valores já vêm com zona morta). Transição para ativo → `stickOnset`, `move = emit(displacement(dt: 1/120, precision))`, liga o temporizador se desligado. Transição para repouso → `stopTimerIfIdle`.
- `setRightStick`: transição para ativo → `scrollOnset` e liga; para repouso → `stopTimerIfIdle`.
- `stopTimerIfIdle`: só com temporizador ligado e os dois analógicos em repouso: desliga, `timer .stop` e emite o pendente do toque.
- `touchDelta`: `scaled = delta · (precisão ? precisionFactor : 1)`; ligado → acumula; desligado → `emit`.
- `tick`: `total = pendente + (esquerdo ativo ? displacement(dt, precisão) : 0)`; zera o pendente; `emit`.
- `emit` passa pelo `SubpixelAccumulator` e devolve `nil` se o inteiro for (0, 0).

### Telas (`DisplayMonitor`)

`start()`: calcula a união por `CGGetActiveDisplayList` + `CGDisplayBounds` e a entrega ao injetor na fila `input`; registra `CGDisplayRegisterReconfigurationCallback`, que ignora `beginConfigurationFlag` e agenda `scheduleRefresh` na main. `scheduleRefresh` agrega em 200 ms. `refresh()`: `displays.changed { count }`, `targets.screens`, união nova ao injetor; na fila `input`, se houver telas e o cursor estiver fora, `CGWarpMouseCursorPosition(clamp)`, `CGAssociateMouseAndMouseCursorPosition(1)`, `cursor.reclamped`; na main, `onChange?()`.

## Fluxos Alternativos

- **Paleta aberta:** botões seguem aos cliques e à paleta; eixos e toque seguem ao movimento. 🟢
- **Suspensão da injeção:** `InjectionGate` chama `ButtonActions.releaseAll()` e, na retomada, `postReleases` com `clickState 1`. 🟢
- **Sem telas:** o injetor não limita o destino, e o reposicionamento não ocorre. 🟢
- **Tela de alvos:** `onButtonDown` é atribuído pelo `TargetAbortMonitor` para encerrar com ○. 🟢

## Dependências

- `entrada-do-controle`: `InputEvent`, `InputContext.registry.pressed`, `ButtonID`. 🟢
- `injecao-de-eventos`: `EventInjector.move`, `post`, `currentLocation`, `screens`; `ScrollInjector.scroll`. 🟢
- `atalhos` (`ShortcutActions`), `paleta` (`PaletteActions`), `editor` (identificação), `tela-de-alvos-e-analise` (`onButtonDown`, `onChange`). 🟢
- `configuracao`: `PointerSettings` e `ShortcutConfig.pointerButtons`. 🟢
- CoreGraphics e AppKit (`NSScreen`). 🟢

## Decisões de Design Identificadas

| Decisão | Evidência no código | Confiança |
|---------|---------------------|-----------|
| Motor puro que devolve comandos de temporizador em vez de controlá-lo | `PointerMotionEngine.swift:15-34` | 🟢 |
| Temporizador único e sob demanda (ADR-006) | `MotionLoop.swift:92-106` | 🟢 |
| Dois detentores para o botão esquerdo | `ClickStateMachine.swift:26-27,42-64` | 🟢 |
| R1 esquerdo e R2 direito (ADR-009) | `ClickStateMachine.swift:18-19` | 🟢 |
| Clamp à união, não ao retângulo envolvente (D-14) | `ScreenUnion.swift` | 🟢 |
| Descarte da atualização por eixo (achado da Fase 2) | `TouchpadTracker.swift:59-66` | 🟢 |

## Estado Interno

| Onde | Campos |
|------|--------|
| `PointerMotionEngine.state` | `leftStick`, `rightStick`, `pendingTouchDelta`, `subpixel.remainder`, `timerRunning` |
| `TouchpadTracker` | `contacts: Set<Int>`, `primary: Int?`, `baseline: (x, y)?` |
| `ClickStateMachine` | `heldMouseButtons`, `leftHolders`, `lastLeftClick (timeNs, point, clickState)`, `currentLeftClickState` |
| `ScrollMapper` | `remainder (vertical, horizontal)` |
| `MotionLoop` | `timer`, `lastTickNs` |
| `InputRouter` | `identifying`, `onButtonDown`, `onIdentify` |
| `DisplayMonitor` | `refreshPending`, `onChange` |

Máquinas em `state-machines.md` §5, §6 e §7.

## Observabilidade

- `pointer.posted` (debug) só para movimentos com origem (`stick_onset`, `touch`), cliques (`button`) e rolagem de onset; os ticks não registram. 🟢
- `displays.changed`, `cursor.reclamped`, `targets.screens`. 🟢

## Riscos e Lacunas

- 🟡 Precisão desliga com qualquer segundo botão, inclusive R1 num arraste com L1.
- 🟢 `clickState` sem teto gera clique triplo e além em cliques rápidos (`ClickStateMachine.swift:83-88`; [Revisor]).
- 🟡 O touchpad gera duas emissões por leitura (uma por eixo), dobrando `pointer.posted` com origem `touch` em `--debug`.
- 🟢 `pointer` não é recarregado com o app aberto.
