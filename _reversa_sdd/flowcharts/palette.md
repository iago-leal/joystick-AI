# Fluxogramas — `palette`

> Gerado pelo Arqueólogo em 2026-09-15. Fonte: `CommandPalette.swift`, `PaletteActions.swift`, `PalettePanel.swift`. 🟢

## 1. Máquina de estados

```mermaid
stateDiagram-v2
    [*] --> Fechada
    Fechada --> Aberta: open() e não bloqueada / seleção = último confirmado ou 0
    Fechada --> Fechada: open() bloqueada pela tela de alvos / palette.blocked
    Aberta --> Repetindo: ↑ ou ↓ pressionado / passo circular
    Repetindo --> Repetindo: tick 400 ms e depois 50 ms / passo
    Repetindo --> Aberta: mesma direção solta
    Aberta --> Fechada: ✕ num item / lembra índice, digita
    Repetindo --> Fechada: ✕ num item / para repetição, digita
    Aberta --> Fechada: ✕ em Editar atalhos / abre editor
    Aberta --> Fechada: ○ ou PS
    Aberta --> Fechada: idle 60 s, disconnected, injection_suspended, config_changed, identify
    Repetindo --> Fechada: ○, PS ou motivo externo
```

## 2. Abertura e confirmação

```mermaid
flowchart TD
    A([open na fila input]) --> B{blocked?}
    B -- sim --> C[palette.blocked] --> Z([Fim])
    B -- não --> D{Já aberta?}
    D -- sim --> Z
    D -- não --> E[palette.opened com seleção 1-based]
    E --> F[Inatividade: consulta a cada 1 s]
    F --> G[main: PalettePanel.show posiciona no centro da tela do cursor]
    G --> Z

    H([✕ pressionado]) --> I{Seleção = entrada fixa?}
    I -- sim --> J[Fecha; main: editor.show source palette] --> Z
    I -- não --> K[Fecha; palette.confirmed índice e enter]
    K --> L[type texto sem Enter]
    L --> M{pressEnter?}
    M -- não --> Z
    M -- sim --> N{atraso > 0?}
    N -- não --> O[Return agora] --> Z
    N -- sim --> P[Return após atraso na fila input] --> Z
```

## 3. Configuração nova

```mermaid
flowchart LR
    A([apply items]) --> B[close config_changed se aberta]
    B --> C[Nova PaletteMachine sem último confirmado]
    C --> D[main: painel troca a lista; tamanho recalculado na próxima abertura]
```
