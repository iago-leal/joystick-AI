# Fluxogramas — `controller-input`

> Gerado pelo Arqueólogo em 2026-09-15. Fonte: `ControllerReader.swift`, `ButtonReader.swift`, `AxisTouchReader.swift`, `ExtendedReportActivator.swift`, `ActiveControllerRegistry.swift`. 🟢

## 1. Partida do leitor

```mermaid
flowchart TD
    A([ControllerReader.start, main]) --> B[shouldMonitorBackgroundEvents = true]
    B --> C[Observa DidConnect e DidDisconnect]
    C --> D[ExtendedReportActivator.start: IOHIDManager no run loop principal]
    D --> E[GCController.controllers]
    E --> F[fila input: connect de cada um, via enumeração]
```

## 2. Conexão

```mermaid
flowchart TD
    A([connect na fila input]) --> B{Já conhecido ou ignorado?}
    B -- sim --> Z([Fim])
    B -- não --> C{extendedGamepad é GCDualSenseGamepad?}
    C -- não --> D[ignored e controller.ignored: not_dualsense] --> Z
    C -- sim --> E[ControllerInfo: UUID, nome, TransportResolver, t_arrival]
    E --> F[atStartup = enumeração ou menos de 2 s]
    F --> G[registry.connect]
    G --> H{duplicate?}
    H -- sim --> Z
    H -- não --> I[handlerQueue = fila input]
    I --> J[controller.connected]
    J --> K{queued?}
    K -- sim --> L[controller.queued com posição]
    K -- não --> M
    L --> M[ButtonReader.attach]
    M --> N[AxisTouchReader.attach e controller.touch_source]
    N --> O[ControllerDiagnostics: supressão de gestos do PS]
    O --> Z
```

## 3. Botão

```mermaid
flowchart TD
    A([pressedChangedHandler ou gatilho]) --> B[t_arrival]
    B --> C{Gatilho L2/R2?}
    C -- sim --> D{TriggerTracker mudou com limiar 0,5?}
    D -- não --> Z([Fim])
    D -- sim --> E
    C -- não --> E[deliver]
    E --> F{Chave é a ativa e o estado mudou?}
    F -- não --> Z
    F -- sim --> G[input.button em debug]
    G --> H[sink.handle buttonDown/buttonUp]
    H --> Z
    P([Relatório HID bruto]) --> Q{DualSenseReport.homeButton mudou?}
    Q -- não --> Z
    Q -- sim --> R[main: onHomeButton]
    R --> S[fila input: deliver .ps para a chave ativa]
    S --> F
```

## 4. Analógicos e toque

```mermaid
flowchart TD
    A([valueChangedHandler do analógico]) --> B{Controle ativo?}
    B -- não --> Z([Fim])
    B -- sim --> C[Zona morta por eixo]
    C --> D{Igual à amostra anterior?}
    D -- sim --> Z
    D -- não --> E[sink.handle axis] --> Z

    T([Toque]) --> U{Perfil tem touchpads?}
    U -- sim --> V[touchDown, touchMoved, touchUp dão a fase]
    U -- não --> W[ZeroTransitionPhaseInference pela transição a 0,0]
    W --> X[touch.raw_transition em debug]
    V --> Y{Controle ativo?}
    X --> Y
    Y -- não --> Z
    Y -- sim --> AA[Limita posição a -1..1]
    AA --> AB{began ou ended?}
    AB -- sim --> AC[input.touch]
    AB -- não --> AD
    AC --> AD[sink.handle touch] --> Z
```

## 5. Desconexão

```mermaid
flowchart TD
    A([disconnect na fila input]) --> B{Era ignorado?}
    B -- sim --> C[Remove em silêncio] --> Z([Fim])
    B -- não --> D[registry.disconnect]
    D --> E{Estava registrado?}
    E -- não --> Z
    E -- sim --> F{Era o ativo?}
    F -- sim --> G[Para cada botão pressionado, em ordem: input.button sintético e buttonUp sintético]
    G --> H[sink.handle controllerDisconnected]
    H --> I[O seguinte na fila vira ativo, sem evento de log]
    F -- não --> J
    I --> J[controller.disconnected] --> Z
```

## 6. Bluetooth: relatório estendido

```mermaid
flowchart LR
    A([IOHIDManager: DualSense casado]) --> B{Transporte contém bluetooth?}
    B -- não --> Z([Fim])
    B -- sim --> C[IOHIDDeviceGetReport recurso 0x05]
    C --> D[controller.extended_report: ok ou código]
    D --> Z
```
