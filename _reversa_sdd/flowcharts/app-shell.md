# Fluxogramas — `app-shell`

> Gerado pelo Arqueólogo em 2026-09-15. Fonte: `AppDelegate.swift`, `InjectionGate.swift`, `Lifecycle.swift`, `PermissionMonitor.swift`. 🟢

## 1. Inicialização (`applicationDidFinishLaunching`)

```mermaid
flowchart TD
    A([Início do processo]) --> B{Outra instância com o mesmo bundle?}
    B -- sim --> Z([NSApp.terminate])
    B -- não --> C[LaunchArguments.parse]
    C --> D[DiagnosticLog --debug e session.start]
    D --> E[ConfigLoader.load: pointer congelado]
    E --> F[ConfigStore.start com atalhos e paleta]
    F --> G[Injetores, InputContext, ButtonActions, MotionLoop, ShortcutActions]
    G --> H[PalettePanel oculto e PaletteActions]
    H --> I[onApply: paleta e depois atalhos na fila input]
    I --> J[Editor, EditMenu, StatusMenu e observadores]
    J --> K[ConfigWatcher.start]
    K --> L[InputRouter como destino; modo de identificação]
    L --> M[InjectionGate e Lifecycle.start]
    M --> N[DisplayMonitor.start e targets.screens]
    N --> O[PermissionMonitor.start ligado ao portão]
    O --> P[ControllerReader.start]
    P --> Q{--targets?}
    Q -- não --> R([Pronto])
    Q -- sim --> S[openTargets]
    S --> R
```

## 2. `openTargets`

```mermaid
flowchart TD
    A([openTargets]) --> B[Registra erros de argumentos, exceto os da paleta e --screen]
    B --> C{env definido?}
    C -- não --> X([Retorna sem abrir])
    C -- sim --> D{Há telas?}
    D -- não --> E[targets.invalid_args: nenhuma tela ativa] --> X
    D -- sim --> F{--screen inválido ou fora da faixa?}
    F -- sim --> G[targets.screen_fallback; usa a tela 1]
    F -- não --> H[Usa a tela pedida]
    G --> I[Semente = --seed ou aleatória de 32 bits]
    H --> I
    I --> J[TargetSession e TargetAbortMonitor]
    J --> K[palette.blocked = true na fila input]
    K --> L[abortMonitor.start e session.start]
    L --> M([Ao terminar: desbloqueia a paleta e libera a sessão])
```

## 3. Portão de injeção (`InjectionGate.setAllowed`)

```mermaid
flowchart TD
    A([PermissionMonitor: postEvent mudou]) --> B[async na fila input]
    B --> C{Estado anterior existe?}
    C -- não --> D[injector.enabled = valor; sem registro] --> Z([Fim])
    C -- sim --> E{Mudou?}
    E -- não --> Z
    E -- "sim, permitido" --> F[injector.enabled = true]
    F --> G[Repete mouseUp e keyUp guardados]
    G --> H[pointer.injection_resumed] --> Z
    E -- "sim, negado" --> I[Paleta fecha: injection_suspended]
    I --> J[Solta teclas e botões e guarda as solturas]
    J --> K[injector.enabled = false]
    K --> L[pointer.injection_suspended]
    L --> M[main: onSuspended, que aborta a tela de alvos] --> Z
```

## 4. Consulta de permissões

```mermaid
flowchart LR
    A([start]) --> B[check startup]
    B --> C{postEvent?}
    C -- não --> D[CGRequestPostEventAccess uma vez]
    C -- sim --> E
    D --> E[Temporizador de 2 s]
    E --> F[check poll]
    F --> G{postEvent ou listenEvent mudou?}
    G -- não --> E
    G -- sim --> H[permissions.status]
    H --> I{postEvent mudou?}
    I -- não --> E
    I -- sim --> J{postEvent falso?}
    J -- sim --> K[permissions.guidance]
    J -- não --> L
    K --> L[onInjectionEnabledChange]
    L --> E
```

## 5. Encerramento

```mermaid
flowchart TD
    A([Sair no menu ou applicationWillTerminate]) --> C
    B([SIGTERM, SIGINT ou SIGHUP]) --> C{Já limpou?}
    C -- sim --> Z([Fim])
    C -- não --> D[fila input sync: atalhos.releaseAll e botões.releaseAll]
    D --> E[app.terminating com releasedButtons]
    E --> F[log.flushSync]
    F --> G{Veio de sinal?}
    G -- sim --> H([exit 0])
    G -- não --> Z
```
