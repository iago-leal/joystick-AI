# Fluxogramas — `editor`

> Gerado pelo Arqueólogo em 2026-09-15. Fonte: `EditorWindowController.swift`, `EditorViewModel.swift`, `EditorDraft.swift`, `KeyCaptureField.swift`. 🟢

## 1. Abertura e ativação da janela

```mermaid
flowchart TD
    A([show source: menu, palette ou alert]) --> B[Guarda aplicativo à frente, se não for o próprio]
    B --> C[prepareForOpen: rebase se limpo; faixa se inválida; zera mensagens]
    C --> D[Cria janela na primeira vez]
    D --> E[NSApp.activate]
    E --> F{App ativo?}
    F -- não --> G[Nível floating]
    F -- sim --> H
    G --> H[makeKeyAndOrderFront e orderFrontRegardless; editor.opened]
    H --> I[Após 150 ms]
    I --> J{Visível e ainda inativa?}
    J -- não --> Z([Fim])
    J -- sim --> K[Clique sintético no centro da barra de título, pela fila input]
    K --> L[Após 500 ms]
    L --> M{Ainda inativa?}
    M -- sim --> N[editor.activation_failed] --> Z
    M -- não --> Z
    O([didBecomeActive]) --> P[Nível normal]
```

## 2. Gravação e confirmação da cópia

```mermaid
flowchart TD
    A([Salvar]) --> B{canSave ou confirmBackup?}
    B -- não --> Z([Nada])
    B -- sim --> C[ConfigStore.save]
    C --> D{Resultado}
    D -- saved --> E[shortcuts.saved; aplica; rebase no gravado; limpa faixas] --> Z
    D -- needsBackupConfirmation --> F[Faixa: copiar para .bak e gravar]
    F --> G{Usuário}
    G -- Cancelar --> Z
    G -- "Copiar e gravar" --> H[save confirmBackup = true, sem reverificar canSave]
    H --> C
    D -- failed --> I[shortcuts.save_failed; faixa com caminho e erro] --> Z
```

## 3. Mudança externa do arquivo

```mermaid
flowchart TD
    A([Observador do ConfigStore, trigger external]) --> B{Status inválido?}
    B -- sim --> C[Faixa externalInvalid; rascunho intocado] --> Z([Fim])
    B -- não --> D{Rascunho sujo?}
    D -- não --> E[Rebase na vigente nova] --> Z
    D -- sim --> F[Faixa de conflito; editor.conflict pending]
    F --> G{Escolha}
    G -- "Recarregar do arquivo" --> H[Rebase descartando; editor.conflict reload] --> Z
    G -- "Manter minhas alterações" --> I[Rebase mantendo o documento; editor.conflict keep] --> Z
```

## 4. Fechamento

```mermaid
flowchart TD
    A([windowShouldClose]) --> B{Aprovado ou limpo?}
    B -- sim --> C([Fecha])
    B -- não --> D{Folha já aberta?}
    D -- sim --> E([Não fecha])
    D -- não --> F[Desliga identificação; folha Salvar, Descartar, Cancelar]
    F --> G{Resposta}
    G -- Salvar --> H{Gravou?}
    H -- não --> E
    H -- sim --> I[outcome saved; aprovado; close]
    G -- Descartar --> J[discard; outcome discarded; aprovado; close]
    G -- Cancelar --> E
    I --> K
    J --> K([windowWillClose: nível normal, identificação desligada, editor.closed, foco devolvido])
```

## 5. Marcar e desmarcar modificador (`EditorDraft`)

```mermaid
flowchart TD
    A([setModifier botão, teclas]) --> B{Botão de apontamento?}
    B -- sim --> X([pointerButton recusado])
    B -- não --> C{Ainda não era modificador?}
    C -- sim --> D[Remove as nenhuma explícitas do botão em todas as camadas e as lembra]
    C -- não --> E
    D --> E[modifiers botão = teclas]
    E --> F([Ações reais do botão permanecem e viram modifierHasAction])

    G([unsetModifier botão]) --> H[Remove de modifiers e remove a camada dele]
    H --> I[Para cada camada lembrada que ainda existe e não ganhou ação para o botão]
    I --> J[Devolve nenhuma explícita]
```

## 6. Gravação de acorde pelo teclado

```mermaid
flowchart TD
    A([Evento local keyDown ou flagsChanged]) --> B{Janela do campo é a chave?}
    B -- não --> P([Segue normalmente])
    B -- sim --> C{Marca do injetor?}
    C -- sim --> D([Consome e ignora])
    C -- não --> E{keyDown?}
    E -- não --> D
    E -- sim --> F{Tecla no KeyCatalog?}
    F -- não --> D
    F -- sim --> G[Acorde com ⌘⌥⌃⇧ das flags]
    G --> H[Desativa monitor; onCapture; onFinish]
    H --> D
```
