# Aplicativo (app-shell), Design Técnico

> Gerado pelo Redator em 2026-09-15 · Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA

## Interface

### Argumentos de abertura (`LaunchArguments.parse(_ arguments: [String]) -> LaunchArguments`) 🟢

Percorre a lista em ordem; argumentos desconhecidos são ignorados. Uma flag que exige valor consome o item seguinte, qualquer que seja (`--env --debug` torna `--debug` o valor de `--env`); se não houver item seguinte, gera `missingValue(flag)`.

| Argumento | Campo | Padrão | Aceita | Erro e mensagem |
|-----------|-------|--------|--------|-----------------|
| `--targets` | `targets: Bool` | `false` | — | Sem `--env` em lugar nenhum: `missingEnv`, "--targets exige --env mesa ou --env sofa" |
| `--debug` | `debug: Bool` | `false` | — | — |
| `--env <v>` | `env: TargetEnvironment?` | `nil` | `mesa`, `sofa` | `invalidEnv(v)`, "--env inválido: \"v\"; use mesa ou sofa, sem acento" |
| `--screen <n>` | `screen: Int` | 1 | inteiro ≥ 1 | `invalidScreen(v)`, "--screen inválido: \"v\"; use um inteiro a partir de 1" |
| `--seed <n>` | `seed: UInt64?` | `nil` | `UInt64` | `invalidSeed(v)`, "--seed inválido: \"v\"; use um inteiro sem sinal" |
| `--scroll-unit <v>` | `scrollUnit` | `pixel` | `pixel`, `line` | `invalidScrollUnit(v)`, "--scroll-unit inválido: \"v\"; use pixel ou line" |
| `--palette-enter-delay-ms <n>` | `paletteEnterDelayMs: Int?` | `nil` | 0…500 | `invalidPaletteEnterDelay(v)`, "--palette-enter-delay-ms inválido: \"v\"; use um inteiro de 0 a 500" |

`concernsPalette` é verdadeiro para `invalidPaletteEnterDelay` e para `missingValue("--palette-enter-delay-ms")`. `targetsEnabled = targets && env != nil`.

### Classes do app

| Símbolo | Assinatura | Retorno | Observação |
|---------|-----------|---------|------------|
| `AppDelegate.applicationDidFinishLaunching` | `(Notification)` | `Void` | Montagem completa; ver Fluxo Principal |
| `AppDelegate.applicationWillTerminate` | `(Notification)` | `Void` | `lifecycle.cleanUp(.quit)` |
| `InjectionGate.setAllowed` | `(Bool)` | `Void` | Qualquer fila; executa na fila `input` |
| `InjectionGate.onSuspended` | `(() -> Void)?` | — | Chamado na main após suspender |
| `PermissionMonitor.start` | `()` | `Void` | Fila padrão: main |
| `PermissionMonitor.onInjectionEnabledChange` | `((Bool) -> Void)?` | — | Na primeira consulta e a cada mudança de `postEvent` |
| `Lifecycle.start` / `cleanUp(reason:)` | `()` / `(TerminationReason)` | `Void` | Main thread; `cleanUp` idempotente |
| `StatusMenu.update(status:)` | `(ConfigState.Status)` | `Void` | Main thread |
| `SigningInfo.current()` | `()` | `SigningInfo` | `identifier`, `teamOrCertName` (resumo do certificado folha ou Team ID), `designatedRequirement` |

### Scripts

| Script | Entrada | Efeito | Saídas |
|--------|---------|--------|--------|
| `build-app.sh` | `JOYSTICK_SIGN_IDENTITY` | `swift build -c release`; bundle em `.build/app/`; `codesign --force --timestamp=none`; `codesign --verify --strict`; encerra a instância aberta por `osascript` (até 5 s); instala por `ditto` em `~/Applications/JoystickAIPoC.app` | 64 sem identidade ou com `-`; 65 identidade ausente |
| `create-local-signing-identity.sh <nome>` | nome | Certificado autoassinado de assinatura de código no chaveiro de login; nada faz se já existir | 64 sem nome |
| `check-signature.sh` | — | Imprime `identifier`, `authority` e `designated` do app instalado | 66 não instalado; 65 sem requisito |
| `test.sh [args]` | argumentos do `swift test` | Com `Testing.framework` das CLT e sem Xcode selecionado, acrescenta `-Xswiftc -F -Xswiftc <frameworks das CLT>` | Código do `swift test` |

`Info.plist`: `CFBundleIdentifier dev.iagoleal.joystick-ai.poc`, executável e nome `JoystickAIPoC`, versão `0.1.0` (build 1), `LSUIElement true`, `LSMinimumSystemVersion 13.0`, `NSHighResolutionCapable true`. 🟢

## Fluxo Principal

`main.swift` cria `NSApplication.shared`, instala o `AppDelegate`, define `.accessory` e chama `run()`. O delegate toma `processStartNs = MonotonicClock.nowNs()` na criação e cria a fila serial `input` (`qos .userInteractive`). Em `applicationDidFinishLaunching` (`AppDelegate.swift:31-139`): 🟢

1. Se `NSRunningApplication.runningApplications(withBundleIdentifier:)` contém outro pid, `NSApp.terminate(nil)` e retorna.
2. `LaunchArguments.parse(CommandLine.arguments.dropFirst())`; `DiagnosticLog(debug:)`; `session.start`.
3. `ConfigLoader.load(from: ~/.config/joystick-ai/config.json)`; registra os eventos `config.*`; guarda `settings`; `ConfigStore(url:log:).start(with:)`; lê a configuração vigente.
4. `EventInjector`, `ScrollInjector(unit: arguments.scrollUnit)`, `InputContext(queue:log:settings:sink: LoggingInputSink)`, `ButtonActions`, `MotionLoop`, **um único** `KeyboardInjector`, `ShortcutActions(config:)`.
5. Registra `palette.invalid_args` para cada erro de paleta; `PalettePanel(items:)` oculto; `PaletteActions(enterDelayMs: argumento ?? 0, items:)`; liga `onRender`, `onItems` e `shortcutActions.onOpenPalette`.
6. `configStore.onApply` → `inputQueue.async { paletteActions.apply(items:); shortcutActions.apply(config) }`, nessa ordem.
7. `EditorViewModel(store:log:)`; `EditorWindowController` com `activateByClick` pelo injetor na fila `input`, `onWillShow`, `isDirty`, `saveForClose`, `discardForClose`, `onIdentifyOff`; `EditMenu.install()`; `StatusMenu` ligado ao editor (`menu`, `alert`) e observando o `ConfigStore`; `paletteActions.onOpenEditor` → editor (`palette`).
8. `ConfigWatcher(url:) { configStore.reload(trigger: .external) }.start()`.
9. `InputRouter(buttons:motion:shortcuts:palette:)`; `onIdentify` → `editorModel.identified`; `editorModel.onIdentifyingChange` registra `editor.identify` e chama `router.setIdentifying` na fila `input`; `inputContext.sink = router`.
10. `InjectionGate(...)`; `Lifecycle(...).start()`.
11. `DisplayMonitor(...).start()`; `ScreenCatalog.emit` (`targets.screens`).
12. `PermissionMonitor(log:)`, `onInjectionEnabledChange` → `gate.setAllowed`, `start()`.
13. `ControllerReader(context:processStartNs:).start()`.
14. Se `arguments.targets`, `openTargets`.

## Fluxos Alternativos

- **`openTargets`** (`AppDelegate.swift:146-190`): registra `targets.invalid_args` para cada erro não da paleta, exceto `invalidScreen`; sem `env`, retorna; sem `NSScreen.screens`, registra "nenhuma tela ativa" e retorna; com `invalidScreen`, registra `targets.screen_fallback` "<mensagem>; usando a tela 1"; com `screen > telas`, "--screen N fora da faixa de 1 a M; usando a tela 1"; semente = argumento ou aleatória; cria `TargetSession` e `TargetAbortMonitor`; na fila `input`, `palette.blocked = true`; `onFinish` desbloqueia a paleta, para o monitor e solta as referências. 🟢
- **Consulta de permissão** (`PermissionMonitor.swift:31-65`): na primeira execução (`startup`) e a cada 2 s (`poll`, folga de 200 ms): lê `AXIsProcessTrusted()` e `CGPreflightListenEventAccess()`; se nenhum mudou, nada; senão guarda, registra `permissions.status`; se `postEvent` mudou, registra `permissions.guidance` quando falso e chama `onInjectionEnabledChange`. Depois da primeira consulta, se `postEvent` é falso, `CGRequestPostEventAccess()`. 🟢
- **Portão** (`InjectionGate.swift:28-58`): ver `state-machines.md` §2. Orientação registrada: "Conceda a permissão em Ajustes do Sistema > Privacidade e Segurança > Acessibilidade > JoystickAIPoC; a PoC retoma o cursor sozinha em até 2 s." 🟢
- **Sinais** (`Lifecycle.swift:18-29`): para cada sinal, `signal(n, SIG_IGN)` e `DispatchSource.makeSignalSource(queue: .main)`, cujo handler chama `cleanUp(reason)` e `exit(0)`. 🟢
- **Menu** (`StatusMenu.swift`): "Sair" chama `NSApp.terminate(nil)`, que passa por `applicationWillTerminate`. 🟢

## Dependências

- `controller-input` (`ControllerReader`, `InputContext`, `LoggingInputSink`): leitura do controle. 🟢
- `pointer` (`InputRouter`, `ButtonActions`, `MotionLoop`, `DisplayMonitor`, `ScreenCatalog`). 🟢
- `injection` (`EventInjector`, `KeyboardInjector`, `ScrollInjector`). 🟢
- `shortcuts` (`ShortcutActions`), `palette` (`PaletteActions`, `PalettePanel`), `config` (`ConfigLoader`, `ConfigStore`, `ConfigWatcher`), `editor` (`EditorViewModel`, `EditorWindowController`, `EditMenu`), `diagnostics-log` (`DiagnosticLog`, `LogEventCatalog`), `targets-analysis` (`TargetSession`, `TargetAbortMonitor`, `TargetRunWriter`). 🟢
- Frameworks: AppKit, SwiftUI, ApplicationServices (`AXIsProcessTrusted`), CoreGraphics, Security. 🟢

## Decisões de Design Identificadas

| Decisão | Evidência no código | Confiança |
|---------|---------------------|-----------|
| Injeção de dependências manual num único ponto de montagem | `AppDelegate.swift:31-139` | 🟢 |
| Um único `KeyboardInjector` para atalhos e paleta (002 D-05) | `AppDelegate.swift:64` | 🟢 |
| Paleta aplicada antes dos atalhos (003 D-12) | `AppDelegate.swift:80-85` | 🟢 |
| Detecção por `AXIsProcessTrusted` (ADR-007) | `PermissionMonitor.swift:48` | 🟢 |
| Soltar antes de desligar e repetir ao religar | `InjectionGate.swift:38-56` | 🟢 |
| Assinatura estável e caminho fixo (ADR-002) | `scripts/build-app.sh` | 🟢 |

## Estado Interno

| Componente | Campos | Contexto |
|------------|--------|----------|
| `AppDelegate` | referências fortes a todos os componentes; `targetSession`, `targetAbortMonitor` opcionais | main |
| `InjectionGate` | `allowed: Bool?`, `pendingMouseReleases: [MouseButton]`, `pendingKeyReleases: [ShortcutAction]` | fila `input` |
| `PermissionMonitor` | `lastPostEvent`, `lastListenEvent: Bool?`, `postEventAllowed`, `timer` | main |
| `Lifecycle` | `signalSources`, `cleanedUp` | main |
| `StatusMenu` | `statusItem`, `menu`, `alertItems` | main |

## Observabilidade

`session.start`, `permissions.status`, `permissions.guidance`, `pointer.injection_suspended`, `pointer.injection_resumed`, `app.terminating`, `palette.invalid_args`, `targets.invalid_args`, `targets.screen_fallback`, `editor.identify`. Campos em `data-dictionary.md` §9.2. 🟢

## Riscos e Lacunas

- 🟡 Sem Acessibilidade desde o início, a falta de permissão só aparece no log; a paleta abre e não digita.
- 🟡 `targetsEnabled` existe no núcleo, mas o app testa `arguments.targets` e retorna sem `env` dentro de `openTargets`; o efeito é equivalente.
- 🟡 `session.start` grava argumentos brutos, inclusive valores arbitrários passados por `open --args`.
- 🟢 A promoção de um controle em fila não é notificada por esta unit (ver `entrada-do-controle`).
