# Fluxogramas — `config`

> Gerado pelo Arqueólogo em 2026-09-15. Fonte: `ConfigLoader.swift`, `ShortcutConfigValidation.swift`, `ConfigStore.swift`, `ConfigWatcher.swift`, `ConfigWriter.swift`. 🟢

## 1. Leitura (`ConfigLoader.load`)

```mermaid
flowchart TD
    A([load url]) --> B{Arquivo existe?}
    B -- não --> C([Padrões: file_missing])
    B -- sim --> D{Diretório ou maior que 1 MiB ou erro de leitura?}
    D -- sim --> E([unreadable; atalhos recusados])
    D -- não --> F{JSON válido?}
    F -- não --> G([invalidJSON com linha; syntax])
    F -- sim --> H{Raiz é objeto?}
    H -- não --> I([invalidJSON; wrongType linha 1])
    H -- sim --> J{pointer é objeto?}
    J -- sim --> K[Valida campo a campo; recusados ficam no padrão]
    J -- não --> L[Padrões: section_missing]
    K --> M[decode shortcuts e palette]
    L --> M
    M --> N{Algum problema estrutural ou semântico?}
    N -- sim --> O[Cada problema recebe a linha pelo ConfigLineLocator]
    O --> P([Atalhos e paleta recusados juntos])
    N -- não --> Q{Alguma das seções presente?}
    Q -- sim --> R([source file])
    Q -- não --> S([source defaults, section_missing])
```

## 2. Validação semântica

```mermaid
flowchart TD
    A([validate documento]) --> B[Modificador em R1, R2 ou touchpad: pointerButtonNotAllowed]
    B --> C[Para cada camada, base primeiro]
    C --> D{Camada de botão não modificador?}
    D -- sim --> E[layerWithoutModifier]
    D -- não --> F
    E --> F[Para cada gatilho da camada]
    F --> G{R1, R2 ou touchpad?}
    G -- sim --> H[pointerButtonNotAllowed]
    G -- não --> I{Gatilho é modificador?}
    I -- sim --> J[modifierHasAction]
    I -- não --> K
    H --> K{Ação}
    J --> K
    K -- text --> L[textEmpty, multiline ou textTooLong]
    K -- "chord fora do catálogo" --> M[unknownKey]
    L --> N
    M --> N[Paleta: vazia, mais de 50, texto e rótulo de cada item]
    K -- outro --> N
    N --> O([Lista de problemas, sem valores])
```

## 3. Releitura por observação

```mermaid
flowchart TD
    A([Evento no diretório, destino do link ou arquivo]) --> B[Reabre observações]
    B --> C[Agenda releitura em 150 ms, cancelando a anterior]
    C --> D[Reabre observações de novo]
    D --> E[ConfigStore.reload external]
    E --> F{Arquivo ausente?}
    F -- sim --> G{Havia bytes?}
    G -- sim --> H[shortcuts.file_removed; vigente mantida] --> Z([Fim])
    G -- não --> I[shortcuts.unchanged] --> Z
    F -- não --> J{Bytes iguais aos últimos?}
    J -- sim --> I
    J -- não --> K[Guarda bytes]
    K --> L{Problemas?}
    L -- sim --> M[status invalid; shortcuts.invalid por problema; notifica] --> Z
    L -- não --> N[current = documento; status valid; shortcuts.loaded]
    N --> O[onApply: fila input aplica paleta e atalhos]
    O --> P[Notifica: StatusMenu e editor] --> Z
```

## 4. Gravação (`ConfigWriter.write`)

```mermaid
flowchart TD
    A([write documento, confirmBackup]) --> B[Resolve links até 16 níveis]
    B --> C{Destino existe?}
    C -- não --> D[created = true; raiz nova]
    C -- sim --> E{Leitura falhou?}
    E -- sim --> F([failed com caminho e erro])
    E -- não --> G{Erro de sintaxe ou raiz não objeto?}
    G -- sim --> H{confirmBackup?}
    H -- não --> I([needsBackupConfirmation com linha])
    H -- sim --> J[Copia para config.json.bak atômico]
    J --> K{Cópia falhou?}
    K -- sim --> F
    K -- não --> L[backup = true; raiz nova]
    G -- não --> M[Raiz existente preservada]
    D --> N
    L --> N
    M --> N[Substitui shortcuts e palette; chaves ordenadas; quebra final]
    N --> O[Cria diretório e grava atômico]
    O --> P{Falhou?}
    P -- sim --> F
    P -- não --> Q([written: bytes, created, backup])
```
