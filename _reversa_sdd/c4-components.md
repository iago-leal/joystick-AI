# C4 — Nível 3: Componentes

> Gerado pelo Arquiteto em 2026-09-15 · Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA
> Componentes agrupados pelos 10 módulos da extração. Nomes em `code` são tipos reais.

## 1. `JoystickAIPoC.app`: pipeline de entrada e saída

```mermaid
C4Component
    title JoystickAIPoC.app — pipeline em tempo real (fila input)

    System_Ext(gc, "GameController / IOHIDManager")
    System_Ext(cg, "CoreGraphics CGEvent")

    Container_Boundary(input, "controller-input") {
        Component(reader, "ControllerReader", "Swift", "Conexão, desconexão, fila de controles, soltura sintética")
        Component(btn, "ButtonReader", "Swift", "18 botões e gatilhos digitais")
        Component(axis, "AxisTouchReader", "Swift", "Analógicos com zona morta e toque inferido")
        Component(hid, "ExtendedReportActivator", "IOKit", "PS pelo relatório bruto; modo estendido por Bluetooth")
    }
    Container_Boundary(ptr, "pointer") {
        Component(router, "InputRouter", "InputSink", "Distribui botões, eixos e toque; modo de identificação")
        Component(bact, "ButtonActions", "Swift", "R1, R2, touchpad → ClickStateMachine")
        Component(motion, "MotionLoop", "DispatchSourceTimer 120 Hz", "PointerMotionEngine, TouchpadTracker, ScrollMapper")
        Component(disp, "DisplayMonitor", "CoreGraphics", "União das telas e reposicionamento")
    }
    Container_Boundary(sc, "shortcuts") {
        Component(sact, "ShortcutActions", "Swift", "ShortcutMapper, repetição, AppleSymbolicHotKeys")
    }
    Container_Boundary(pal, "palette") {
        Component(pact, "PaletteActions", "Swift", "PaletteMachine, inatividade, confirmação")
        Component(panel, "PalettePanel", "NSPanel", "Desenho não ativador na main")
    }
    Container_Boundary(inj, "injection") {
        Component(ev, "EventInjector", "CGEvent", "Movimento, cliques, arraste, clique de ativação")
        Component(kb, "KeyboardInjector", "CGEvent", "Acordes com contagem de modificadores, texto UTF-16")
        Component(scr, "ScrollInjector", "CGEvent", "Rolagem em pixel ou linha")
    }
    Container_Boundary(shell, "app-shell") {
        Component(gate, "InjectionGate", "Swift", "Liga e desliga injetores; repete solturas")
        Component(perm, "PermissionMonitor", "Timer 2 s", "AXIsProcessTrusted")
    }

    Rel(gc, reader, "notificações e handlers")
    Rel(gc, btn, "pressedChangedHandler")
    Rel(gc, axis, "valueChangedHandler")
    Rel(hid, reader, "onHomeButton")
    Rel(btn, router, "InputEvent")
    Rel(axis, router, "InputEvent")
    Rel(reader, router, "controllerDisconnected")
    Rel(router, bact, "botões")
    Rel(router, sact, "botões, paleta fechada")
    Rel(router, pact, "botões, paleta aberta")
    Rel(router, motion, "eixos e toque")
    Rel(bact, ev, "down/up")
    Rel(motion, ev, "move")
    Rel(motion, scr, "scroll")
    Rel(sact, kb, "chord, text")
    Rel(sact, pact, "openPalette")
    Rel(pact, kb, "type, Return")
    Rel(pact, panel, "snapshot → main")
    Rel(disp, ev, "screens")
    Rel(perm, gate, "postEvent mudou")
    Rel(gate, ev, "enabled")
    Rel(gate, kb, "enabled")
    Rel(gate, scr, "enabled")
    Rel(ev, cg, "post .cghidEventTap")
    Rel(kb, cg, "post")
    Rel(scr, cg, "post")
```

## 2. `JoystickAIPoC.app`: configuração, editor e instrumentação (main thread)

```mermaid
C4Component
    title JoystickAIPoC.app — configuração, editor, log e tela de alvos

    ContainerDb(cfg, "config.json")
    ContainerDb(logs, "Logs JSONL")
    ContainerDb(runs, "target-runs")

    Container_Boundary(conf, "config") {
        Component(store, "ConfigStore", "main", "Vigente, status, bytes; onApply e observadores")
        Component(watch, "ConfigWatcher", "DispatchSource", "Diretório, destino do link e arquivo; 150 ms")
        Component(writer, "ConfigWriter", "Foundation", "Fusão, link simbólico, .bak, troca atômica")
        Component(loader, "ConfigLoader", "JoystickCore", "Leitura, validação, linhas")
    }
    Container_Boundary(ed, "editor") {
        Component(win, "EditorWindowController", "NSWindow", "Abertura, ativação E003, fechamento, foco")
        Component(vm, "EditorViewModel", "Combine", "EditorDraft, faixas, conflito, gravação")
        Component(views, "EditorRootView e abas", "SwiftUI", "Figura do controle, painel de ação, paleta, KeyCaptureField")
        Component(menu, "StatusMenu e EditMenu", "AppKit", "Ícone, alerta, Editar atalhos, colar")
    }
    Container_Boundary(diag, "diagnostics-log") {
        Component(log, "DiagnosticLog", "fila log", "JSONL com buffer; LogEventCatalog")
    }
    Container_Boundary(tgt, "targets-analysis") {
        Component(sess, "TargetSession", "AppKit", "20 alvos, tentativas, resumo")
        Component(abort, "TargetAbortMonitor", "Swift", "○, tela removida, suspensão")
        Component(rw, "TargetRunWriter", "Foundation", "Grava rodada")
    }
    Component(router, "InputRouter / ShortcutActions / PaletteActions", "fila input", "Recebem apply e identificação")

    Rel(watch, store, "reload(external)")
    Rel(store, loader, "load")
    Rel(loader, cfg, "lê")
    Rel(store, writer, "save")
    Rel(writer, cfg, "grava")
    Rel(store, router, "onApply → fila input")
    Rel(store, vm, "observador")
    Rel(store, menu, "observador: status")
    Rel(vm, store, "save / rebase")
    Rel(win, vm, "prepareForOpen")
    Rel(views, vm, "binding")
    Rel(menu, win, "show(menu|alert)")
    Rel(router, win, "show(palette), identificação")
    Rel(sess, rw, "finish")
    Rel(rw, runs, "grava")
    Rel(abort, sess, "abort")
    Rel(store, log, "shortcuts.*")
    Rel(win, log, "editor.*")
    Rel(sess, log, "targets.*")
    Rel(log, logs, "escreve")
```

## 3. `JoystickCore`: máquinas e algoritmos

| Módulo | Componentes | Responsabilidade | Testes |
|--------|-------------|------------------|--------|
| controller-input | `ActiveControllerRegistry`, `DualSenseReport`, `Normalization`, `TriggerTracker`, `StartupAdoption`, `InputEvent` | Fila de controles, PS por HID, zona morta, gatilho digital, adoção | 5 arquivos 🟢 |
| pointer | `PointerMotionEngine`, `StickKinematics`, `TouchpadTracker`, `ClickStateMachine`, `ScrollMapper`, `ScreenUnion`, `Geometry`, `PointerSettings` | Cinemática, subpixel, toque, cliques, rolagem, limite | 6 arquivos 🟢 |
| shortcuts | `ShortcutMapper`, `KeyCatalog`, `KeyRepeat`, `SystemShortcut` | Camadas, resolução no pressionar, acordes de sistema | 2 arquivos 🟢 |
| palette | `PaletteMachine`, `PaletteItem`, `PaletteDefaults` | Estado da paleta | 1 arquivo 🟢 |
| config | `ConfigLoader`, `PointerSettingsValidation`, `ShortcutConfig`, `ShortcutConfigValidation`, `ConfigLineLocator`, `ConfigDocument`, `ShortcutDefaults`, `ActionSummary` | Leitura, validação, localização, codificação, padrões, resumos | 8 arquivos 🟢 |
| editor | `EditorDraft` | Rascunho, operações e problemas | 1 arquivo 🟢 |
| app-shell | `LaunchArguments` | Argumentos de abertura | 1 arquivo 🟢 |
| diagnostics-log | `LogEvent`, `LogEventCatalog`, `JSONValue`, `MonotonicClock` | Esquema do log e JSON determinístico | 2 arquivos 🟢 |
| targets-analysis | `TargetRun`, `LatencyStats`, `LogAnalysis`, `RunsReport` | Rodadas, percentis, análise de log | 4 arquivos 🟢 |

Nenhum componente do alvo `JoystickAIPoC` tem teste automatizado; sua verificação é feita pelos portões manuais (`architecture.md` §6). 🟢
