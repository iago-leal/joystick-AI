# Fluxogramas — `pointer`

> Gerado pelo Arqueólogo em 2026-09-15. Fonte: `InputRouter.swift`, `MotionLoop.swift`, `PointerMotionEngine.swift`, `TouchpadTracker.swift`, `ClickStateMachine.swift`, `DisplayMonitor.swift`. 🟢

## 1. Roteamento de entradas (`InputRouter.handle`)

```mermaid
flowchart TD
    A([InputEvent]) --> B{Tipo}
    B -- botão --> C[ButtonActions.handle]
    C --> D{Modo de identificação e botão fora de R1, R2, touchpad?}
    D -- sim --> E{buttonDown não sintético?}
    E -- sim --> F[main: onIdentify] --> Z([Fim])
    E -- não --> Z
    D -- não --> G[palette.noteActivity]
    G --> H{Paleta aberta?}
    H -- sim --> I[PaletteActions.handle]
    H -- não --> J[ShortcutActions.handle]
    I --> K{buttonDown não sintético?}
    J --> K
    K -- sim --> L[onButtonDown: tela de alvos] --> Z
    K -- não --> Z
    B -- "eixo ou toque" --> M[palette.noteActivity] --> N[MotionLoop.handle] --> Z
    B -- desconexão --> O[Paleta fecha: disconnected]
    O --> P[Botões, atalhos e movimento tratam a desconexão] --> Z
```

## 2. Movimento e temporizador

```mermaid
flowchart TD
    A([MotionLoop.handle]) --> B{Elemento}
    B -- analógico esquerdo --> C[engine.setLeftStick]
    C --> D{Saiu do repouso?}
    D -- sim --> E[Deslocamento de 1/120 s agora, origem stick_onset; liga temporizador]
    D -- não --> F{Voltou ao repouso?}
    F -- sim --> G[Desliga se o direito também repousa e emite o delta pendente do toque]
    B -- analógico direito --> H[engine.setRightStick]
    H --> I{Saiu do repouso?}
    I -- sim --> J[Zera resto e rola 1/120 s agora; liga temporizador]
    B -- toque --> K[TouchpadTracker.update]
    K --> L{Delta?}
    L -- não --> Z([Fim])
    L -- sim --> M{Temporizador ligado?}
    M -- sim --> N[Acumula para o próximo tick]
    M -- não --> O[Emite agora, origem touch]
    B -- desconexão --> P[Zera analógicos, rastreador e rolagem]

    T([Tick de 120 Hz]) --> U[dt = min 50 ms, tempo real]
    U --> V[total = delta pendente + analógico esquerdo · dt]
    V --> W[Subpixel: parte inteira]
    W --> X[injector.move sem registro]
    X --> Y{Analógico direito ativo?}
    Y -- sim --> AA[ScrollMapper.step e ScrollInjector.scroll]
    Y -- não --> Z
    AA --> Z
```

## 3. Cinemática do analógico

```mermaid
flowchart LR
    A([x, y com zona morta]) --> B["h = hypot(x, y)"]
    B --> C{h = 0?}
    C -- sim --> D([0, 0])
    C -- não --> E["m = min(1, h)"]
    E --> F["v = stickMaxSpeed · m^stickExponent"]
    F --> G["(vx, vy) = v · (x/h, −y/h)"]
    G --> H{"pressionados = {L1}?"}
    H -- sim --> I[fator = precisionFactor]
    H -- não --> J[fator = 1]
    I --> K["d = v · dt · fator"]
    J --> K
```

## 4. Rastreador do touchpad

```mermaid
flowchart TD
    A([update dedo, fase, x, y]) --> B{fase = ended?}
    B -- sim --> C[Remove contato]
    C --> D{Era o primário?}
    D -- sim --> E[Primário = menor contato restante; zera referência]
    D -- não --> Z([nil])
    E --> Z
    B -- não --> F[Adiciona contato]
    F --> G{Sem primário?}
    G -- sim --> H[Primário = este dedo; zera referência]
    G -- não --> I
    H --> I{Este dedo é o primário?}
    I -- não --> Z
    I -- sim --> J{fase = moved e há referência?}
    J -- não --> K[Fixa referência] --> Z
    J -- sim --> L[Nova referência]
    L --> M{Atualização por eixo: um eixo igual e o outro cruzou o zero exato?}
    M -- sim --> Z
    M -- não --> N["Δ = (Δx, −Δy) · 400 · sensibilidade"]
    N --> O([Δ])
```

## 5. Cliques

```mermaid
flowchart TD
    A([press botão, ponto, tempo]) --> B{Botão}
    B -- "R1 ou touchpad" --> C{Detentores estavam vazios?}
    C -- não --> D[Só adiciona detentor] --> Z([nil])
    C -- sim --> E{Último clique a ≤ intervalo e ≤ 4 pt?}
    E -- sim --> F[clickState = anterior + 1]
    E -- não --> G[clickState = 1]
    F --> H[down left]
    G --> H
    B -- R2 --> I{Direito já mantido?}
    I -- sim --> Z
    I -- não --> J[down right, clickState 1]
    B -- outro --> Z

    R([release]) --> S{"R1 ou touchpad"}
    S -- sim --> T{Removeu e detentores vazios?}
    T -- sim --> U[up left com o mesmo clickState]
    T -- não --> Z
    S -- "não, R2" --> V[up right]
```

## 6. Reconfiguração de telas

```mermaid
flowchart TD
    A([CGDisplay callback, exceto início de configuração]) --> B[main: agenda atualização]
    B --> C{Já agendada?}
    C -- sim --> Z([Fim])
    C -- não --> D[Espera 200 ms]
    D --> E[Retângulos ativos; displays.changed; targets.screens]
    E --> F[fila input: injector.screens = união]
    F --> G{Há telas e o cursor está fora?}
    G -- não --> H
    G -- sim --> I[CGWarpMouseCursorPosition para o ponto mais próximo; cursor.reclamped]
    I --> H[onChange: tela de alvos confere remoção] --> Z
```
