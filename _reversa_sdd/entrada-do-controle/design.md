# Entrada do controle (controller-input), Design Técnico

> Gerado pelo Redator em 2026-09-15 · Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA

## Interface

### Contrato de saída 🟢

```swift
protocol InputSink: AnyObject { func handle(_ event: InputEvent) }   // sempre na fila input

enum ButtonID: String, CaseIterable, Codable, Comparable {           // ordem de declaração = ordem de comparação
    case cross, circle, square, triangle, l1, r1, l2, r2, l3, r3,
         options, create, ps, touchpadClick, dpadUp, dpadDown, dpadLeft, dpadRight
}
enum InputElement { case button(ButtonID), leftStick, rightStick, touch(Int) }
enum InputEventKind: String { case controllerConnected, controllerDisconnected, buttonDown, buttonUp, axis, touch, controllerError }
struct InputEvent {
    var kind: InputEventKind; var element: InputElement?; var value: Double?  // gatilhos 0…1
    var x, y: Double?                                                        // analógico com zona morta ou toque em [-1,1]
    var touchIndex: Int?; var touchPhase: TouchPhase?                         // began | moved | ended
    var synthetic: Bool = false; var timestamp: UInt64                        // t_arrival, CLOCK_UPTIME_RAW ns
    var frameworkTimestamp: Double?
}
struct ControllerInfo { let id: UUID; let name: String; let connection: ConnectionType; let connectedAt: UInt64; let atStartup: Bool }
```

| Evento entregue | Campos preenchidos | Origem |
|-----------------|--------------------|--------|
| `buttonDown` / `buttonUp` | `element .button`, `value` (só L2/R2), `timestamp`, `frameworkTimestamp` (só pelo GameController) | `ButtonReader.deliver` |
| `buttonUp` sintético | `element .button`, `synthetic true` | `ControllerReader.disconnect` |
| `axis` | `element .leftStick` ou `.rightStick`, `x`, `y` | `AxisTouchReader.attachStick` |
| `touch` | `element .touch(i)`, `x`, `y`, `touchIndex`, `touchPhase` | `AxisTouchReader.deliverTouch` |
| `controllerDisconnected` | `timestamp` | só quando o removido era o ativo |

`controllerConnected` e `controllerError` existem no enum, mas não são entregues ao destino pelo leitor; `LoggingInputSink` só trata `controllerError`. 🟢

### Núcleo 🟢

| Símbolo | Assinatura | Retorno | Observação |
|---------|-----------|---------|------------|
| `ActiveControllerRegistry<Key>.connect` | `(key:info:isDualSense:)` | `.active`, `.queued(position)`, `.duplicate`, `.ignored` | Anexa ao fim |
| `ActiveControllerRegistry.disconnect` | `(key:)` | `DisconnectOutcome(removed, wasActive, syntheticReleases, promoted)` | `syntheticReleases = pressed.sorted()` só se era o ativo |
| `ActiveControllerRegistry.press` / `release` | `(ButtonID, from: Key)` | `Bool` | `false` se não ativo ou sem mudança |
| `activeKey`, `active`, `isActive(_:)`, `queue`, `info(for:)` | — | — | Consultas |
| `Normalization.applyDeadzone` | `(Double, deadzone:)` | `Double` | `c = clamp(v,−1,1)`; `|c| < dz ? 0 : c` |
| `Normalization.stick` | `(x:y:deadzone:)` | `(x, y)` | Por eixo |
| `Normalization.touchPosition` | `(x:y:)` | `(x, y)` | Limita a [−1, 1] |
| `TriggerTracker.update` | `(Double)` | `Bool?` | Novo estado só na mudança; limiar 0,5 |
| `StartupAdoption.isAtStartup` | `(source:elapsedNs:)` | `Bool` | `enumeration` ou `< 2_000_000_000` |
| `DualSenseReport.homeButton` | `(reportID: UInt32, bytes: [UInt8])` | `Bool?` | `bytes[0]` é o id; ver RN-EC-12 |
| `ZeroTransitionPhaseInference.phase` | `(x:y:)` | `TouchPhase?` | Tabela abaixo |

`ZeroTransitionPhaseInference`: (não tocando, em 0) → `nil`; (não tocando, fora de 0) → `began`; (tocando, fora de 0) → `moved`; (tocando, em 0) → `ended`. "Em 0" é `x == 0 && y == 0` exatos.

## Fluxo Principal

1. **`ControllerReader.start()`**, main, uma vez (`ControllerReader.swift:20-55`):
   1. `GCController.shouldMonitorBackgroundEvents = true` antes de tudo.
   2. Observa `GCControllerDidConnect` e `GCControllerDidDisconnect` (`queue: nil`); cada notificação toma `t_arrival` e despacha `connect(source: .notification)` ou `disconnect` na fila `input`.
   3. `ExtendedReportActivator.onHomeButton = { pressed, t in input.async { se houver activeKey: ButtonReader.deliver(.ps, pressed, value: nil, controller: nil, key: activeKey) } }`; `start()`.
   4. `GCController.controllers()` com um único `t_arrival`; na fila `input`, `connect(source: .enumeration)` para cada um.
2. **`connect`** (fila `input`, `:59-92`):
   1. Se a chave (`ObjectIdentifier`) já está em `controllers` ou `ignored`, retorna.
   2. Se não é `GCDualSenseGamepad`: guarda em `ignored` e `controllers`; `controller.ignored { name: vendorName ?? "desconhecido", productCategory, reason: "not_dualsense" }`.
   3. `elapsed = t_arrival − processStartNs` (0 se negativo); `ControllerInfo(id: UUID(), name: vendorName ?? "DualSense", connection: TransportResolver.resolve(), connectedAt: t_arrival, atStartup:)`.
   4. `registry.connect`; se `duplicate`, retorna.
   5. `controllers[key] = controller`; `controller.handlerQueue = fila input`; `controller.connected`; se `queued(p)`, `controller.queued { id, position: p }`.
   6. `ButtonReader.attach`, `AxisTouchReader.attach`, `ControllerDiagnostics.attach`.
3. **`ButtonReader.attach`** (`ButtonReader.swift:19-39`): para os 16 botões digitais, `pressedChangedHandler` → `deliver`; elemento ausente gera `controller.error { "elemento ausente para <botão>" }`. Para L2 e R2, um `TriggerTracker` por gatilho em `valueChangedHandler`; só a mudança chama `deliver` com `value`.
4. **`ButtonReader.deliver`** (`:42-57`): `changed = pressed ? registry.press : registry.release`; se falso, retorna; `t_delivered`; `input.button { button, phase, synthetic: false, t_arrival, t_delivered, t_framework? }` (debug); `sink.handle(InputEvent)`.
5. **`AxisTouchReader.attach`** (`AxisTouchReader.swift:18-55`):
   - Analógicos: se não ativo, descarta; normaliza com `context.settings.deadzone`; se igual ao último entregue, descarta; entrega `axis`.
   - `source = touchpads.isEmpty ? zeroTransition : touchState`; `controller.touch_source { id, source }`.
   - Para `touchpadPrimary` (dedo 0) e `touchpadSecondary` (dedo 1), `valueChangedHandler`: se ativo e a inferência devolve fase: se fase ≠ `moved`, `touch.raw_transition { finger, toZero }` (debug); se `zeroTransition`, `deliverTouch`.
   - Se `touchState`: os dois primeiros touchpads por nome ordenado recebem `touchDown/Moved/Up` → `deliverTouch` com a fase respectiva, se ativo.
   - `deliverTouch`: limita a posição; em `began`/`ended`, `input.touch { finger, phase, t_arrival, t_delivered }` (debug); entrega `touch`.
6. **`ControllerDiagnostics.attach`** (`ControllerDiagnostics.swift:13-27`): com `--debug`, `controller.elements { names, touchpads }` ordenados; `buttonHome.preferredSystemGestureState = .disabled` e `controller.gesture_suppression { elements: ["buttonHome"], message }`, ou `elements: []` com "buttonHome ausente no perfil do controle; supressão não pedida.".

## Fluxos Alternativos

- **Desconexão** (`ControllerReader.swift:94-116`): chave ignorada → remove e retorna. `registry.disconnect`; sem `removed`, retorna. Para cada `syntheticReleases`: `input.button { phase: up, synthetic: true, t_framework: nil }` e `buttonUp` sintético. Se `wasActive`, `controllerDisconnected`. `controller.disconnected { id, t_arrival }`. Remove de `controllers`. `promoted` não é usado. 🟢
- **HID** (`ExtendedReportActivator.swift`): `IOHIDManager` casando Sony `0x054C` com produtos `0x0CE6` e `0x0DF2`, agendado no run loop principal. Callback de dispositivo: se `kIOHIDTransportKey` contém "bluetooth", `IOHIDDeviceGetReport(feature, 0x05, buffer 64)` e `controller.extended_report { transport: bluetooth, result: "ok" | "0x<hex>" }`. Callback de relatório: `DualSenseReport.homeButton`; se mudou em relação a `homePressed`, chama `onHomeButton(pressed, t_arrival)` na main. `IOHIDManagerOpen` falho gera `controller.error { "IOHIDManagerOpen falhou: 0x…" }`. 🟢
- **Transporte** (`TransportResolver.swift`): `IOServiceMatching(kIOHIDDeviceKey)` com vendor Sony; para cada serviço com produto DualSense, `Transport` em minúsculas contendo "bluetooth" → `bluetooth`, "usb" → `usb`, senão `unknown`; `resolve` devolve o único valor do conjunto, ou `unknown`. 🟢

## Dependências

- `GameController` (`GCController`, `GCDualSenseGamepad`, `physicalInputProfile`), `IOKit.hid`, `IOKit`. 🟢
- `pointer`: `InputRouter` é o `InputSink` real; `ZeroTransitionPhaseInference` mora em `TouchpadTracker.swift`. 🟢
- `diagnostics-log`: `DiagnosticLog`, `LogEventCatalog`, `MonotonicClock`. 🟢
- `config`: `PointerSettings.deadzone` via `InputContext.settings`. 🟢

## Decisões de Design Identificadas

| Decisão | Evidência no código | Confiança |
|---------|---------------------|-----------|
| Observadores antes da enumeração; deduplicação por identidade (D-25) | `ControllerReader.swift:24-54` | 🟢 |
| Registro genérico e puro, testável sem hardware (D-09) | `ActiveControllerRegistry.swift:7` | 🟢 |
| PS pelo HID porque o macOS o retém (P-07) | `ExtendedReportActivator.swift:5-10` | 🟢 |
| Inferência por zero porque `touchpads` vem vazio (P-01) | `AxisTouchReader.swift:22-23` | 🟢 |
| Transporte por exclusão sem abrir o dispositivo (D-07) | `TransportResolver.swift:6-19` | 🟢 |

## Estado Interno

| Onde | Campos | Evolução |
|------|--------|----------|
| `InputContext` (fila `input`) | `registry`, `settings`, `sink`, `queue`, `log` | `sink` troca de `LoggingInputSink` para `InputRouter` na montagem |
| `ControllerReader` | `controllers: [ObjectIdentifier: GCController]`, `ignored: Set`, `observers` | Conexão e desconexão |
| `ExtendedReportActivator` | `homePressed: Bool` | Por processo, não por dispositivo |
| Por gatilho | `TriggerTracker.pressed` | Captura do handler |
| Por analógico | `StickState.last` | Captura do handler |
| Por dedo | `ZeroTransitionPhaseInference.touching` | Captura do handler |

Máquina completa em `state-machines.md` §1 e §7.

## Observabilidade

`controller.connected`, `controller.ignored`, `controller.queued`, `controller.disconnected`, `controller.touch_source`, `controller.gesture_suppression`, `controller.extended_report`, `controller.error`, e em debug `controller.elements`, `input.button`, `input.touch`, `touch.raw_transition`. Campos em `data-dictionary.md` §9.2. 🟢

## Riscos e Lacunas

- 🟢 PS de controle em fila age como PS do ativo (RN-EC-17), porque `homePressed` e `onHomeButton` não identificam o dispositivo; comportamento aceito pelo usuário (L-02 / DV-04).
- 🟡 A promoção de controle em fila não é registrada no log.
- 🟡 `TriggerTracker` e `StickState` de um controle em fila continuam a acompanhar valores; ao ser promovido, um gatilho já pressionado só gera evento ao cruzar o limiar de novo.
- 🟡 `ExtendedReportActivator.homePressed` é global: dois controles alternando o PS podem gerar transições inesperadas.
- 🟢 O comentário de `ButtonReader.swift:7` sobre P-05 está desatualizado.
