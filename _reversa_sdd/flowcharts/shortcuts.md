# Fluxogramas — `shortcuts`

> Gerado pelo Arqueólogo em 2026-09-15. Fonte: `ShortcutMapper.swift`, `ShortcutActions.swift`, `ShortcutConfig.swift`. 🟢

## 1. Pressionar (`ShortcutMapper.press`)

```mermaid
flowchart TD
    A([press botão]) --> B[lastTrigger = nil]
    B --> C{Já segurado?}
    C -- sim --> Z([nenhuma ação])
    C -- não --> D{R1, R2 ou touchpad?}
    D -- sim --> Z
    D -- não --> E{É modificador?}
    E -- sim --> F[Entra no fim de modifierOrder]
    F --> G([modifierDown de cada tecla, ⌃⌥⇧⌘])
    E -- não --> H[camada = modificador segurado há mais tempo, ou base]
    H --> I{Camada tem ação própria para o botão?}
    I -- sim --> J[ação própria]
    I -- não --> K[ação da base, ou nenhuma]
    J --> L{Tipo}
    K --> L
    L -- chord --> M[resolved = chord] --> N([keyDown com repeats])
    L -- systemShortcut --> O[resolved = system] --> P([systemDown])
    L -- text --> Q([text])
    L -- openPalette --> R([openPalette])
    L -- none --> Z
    N --> S[lastTrigger com botão, camada, tipo]
    P --> S
    Q --> S
    R --> S
```

## 2. Soltar e soltar tudo

```mermaid
flowchart TD
    A([release botão]) --> B{Estava segurado?}
    B -- não --> Z([nenhuma ação])
    B -- sim --> C{Está em modifierOrder?}
    C -- sim --> D([modifierUp das teclas dele])
    C -- não --> E{Há ação mantida?}
    E -- sim --> F([keyUp ou systemUp guardado])
    E -- não --> Z

    G([releaseAll]) --> H[Solta mantidos em ordem de ButtonID]
    H --> I[modifierUp na ordem em que foram segurados]
    I --> J[Zera held, modifierOrder, resolved, lastTrigger]
```

## 3. Execução (`ShortcutActions`)

```mermaid
flowchart TD
    A([buttonDown]) --> B[ações = mapper.press]
    B --> C[gatilho = mapper.lastTrigger]
    C --> D[perform ações]
    D --> E{gatilho?}
    E -- sim --> F[shortcut.triggered] --> Z([Fim])
    E -- não --> Z

    P([perform]) --> Q{Ação}
    Q -- keyDown --> R[chordDown; se repeats, repetição 400 ms e depois 50 ms]
    Q -- keyUp --> S[Para a repetição se for o acorde repetido; chordUp]
    Q -- text --> T[type]
    Q -- modifierDown/Up --> U[contagem de referência]
    Q -- openPalette --> V[releaseAll e depois onOpenPalette]
    Q -- systemDown --> W[Lê AppleSymbolicHotKeys agora; guarda acorde; chordDown]
    Q -- systemUp --> X[chordUp do acorde guardado]

    CA([apply nova configuração]) --> CB[Para repetição]
    CB --> CC[releaseAll]
    CC --> CD[Novo ShortcutMapper: botões segurados ficam ignorados até soltar]
```

## 4. Acorde de atalho de sistema

```mermaid
flowchart LR
    A([SystemShortcut]) --> B[Entrada em AppleSymbolicHotKeys pelo id]
    B --> C{Existe, enabled e parameters com 3 números?}
    C -- não --> D([Acorde padrão])
    C -- sim --> E[keyCode = parameters 1]
    E --> F["máscara: 0x20000 ⇧, 0x40000 ⌃, 0x80000 ⌥, 0x100000 ⌘"]
    F --> G([Acorde das preferências])
```
