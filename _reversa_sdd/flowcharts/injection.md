# Fluxogramas — `injection`

> Gerado pelo Arqueólogo em 2026-09-15. Fonte: `EventInjector.swift`, `KeyboardInjector.swift`, `ScrollInjector.swift`. 🟢

## 1. Posição de partida (`currentLocation`)

```mermaid
flowchart TD
    A([currentLocation]) --> B[Leitura do sistema: CGEvent source nil]
    B --> C{Há posição acompanhada, menos de 100 ms desde a última emissão e a leitura é uma das 32 últimas postadas?}
    C -- sim --> D([Posição acompanhada])
    C -- não --> E[Descarta o acompanhamento; histórico = leitura]
    E --> F([Leitura do sistema, que pode vir do mouse físico])
```

## 2. Movimento

```mermaid
flowchart TD
    A([move delta, tipo, origem]) --> B{enabled?}
    B -- não --> Z([Descarta])
    B -- sim --> C[de = currentLocation]
    C --> D[para = de + delta]
    D --> E{Há telas?}
    E -- sim --> F[para = união.clamp]
    E -- não --> G
    F --> G[mouseMoved, leftMouseDragged ou rightMouseDragged]
    G --> H[mouseEventDeltaX/Y = para − de arredondado]
    H --> I[Acompanha para]
    I --> J[Marca 0x4A4F5953 e post em cghidEventTap]
    J --> K{Tem origem e t_arrival?}
    K -- sim --> L[pointer.posted]
    K -- não --> Z2([Fim])
    L --> Z2
```

## 3. Teclado

```mermaid
flowchart TD
    A([chordDown acorde]) --> B[Para cada modificador em ordem ⌃⌥⇧⌘: modifierDown]
    B --> C{Contagem passou a 1?}
    C -- sim --> D[flagsChanged com flags mantidas]
    C -- não --> E
    D --> E[keyDown com flags mantidas; setas + numericPad e secondaryFn]
    E --> Z([Fim])

    F([chordUp acorde]) --> G[keyUp]
    G --> H[Para cada modificador em ordem inversa: modifierUp]
    H --> I{Contagem chegou a 0?}
    I -- sim --> J[flagsChanged]
    I -- não --> Z
    J --> Z

    K([type texto, Enter]) --> L{enabled?}
    L -- não --> Z
    L -- sim --> M[Para cada unidade UTF-16: keyDown e keyUp com unicodeString, sem flags]
    M --> N{pressEnter?}
    N -- sim --> O[chordDown e chordUp de Return]
    N -- não --> Z
    O --> Z
```

## 4. Rolagem

```mermaid
flowchart LR
    A([scroll vertical, horizontal]) --> B{enabled e algum não nulo?}
    B -- não --> Z([Fim])
    B -- sim --> C[scrollWheelEvent2: pixel ou linha, 2 rodas]
    C --> D[deliver com kind scroll e registro se houver origem]
    D --> Z
```
