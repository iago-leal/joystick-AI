# Matriz código-spec

> Gerado pelo Redator em 2026-09-15 · Granularidade `module`, layout `feature-folder` · Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA

## Correspondência módulo → pasta de unit

Os módulos do Arqueólogo (`.reversa/context/modules.json`) têm nomes em inglês; as pastas de unit seguem o idioma das specs. 🟢

| Módulo | Unit |
|--------|------|
| `app-shell` | `aplicativo/` |
| `controller-input` | `entrada-do-controle/` |
| `pointer` | `ponteiro/` |
| `injection` | `injecao-de-eventos/` |
| `shortcuts` | `atalhos/` |
| `palette` | `paleta/` |
| `config` | `configuracao/` |
| `editor` | `editor/` |
| `diagnostics-log` | `log-de-diagnostico/` |
| `targets-analysis` | `tela-de-alvos-e-analise/` |

## Código de produção

| Arquivo do legado | Unit correspondente | Cobertura |
|---------|---------------------|-----------|
| `Package.swift` | `aplicativo/` | 🟢 |
| `Resources/Info.plist` | `aplicativo/` | 🟢 |
| `scripts/build-app.sh` | `aplicativo/` | 🟢 |
| `scripts/check-signature.sh` | `aplicativo/` | 🟢 |
| `scripts/config-samples/invalid-line12.json` | `configuracao/` (amostras dos portões manuais) | 🟢 |
| `scripts/config-samples/invalid-line4.json` | `configuracao/` (amostras dos portões manuais) | 🟢 |
| `scripts/config-samples/l3-modifier.json` | `configuracao/` (amostras dos portões manuais) | 🟢 |
| `scripts/config-samples/out-of-range.json` | `configuracao/` (amostras dos portões manuais) | 🟢 |
| `scripts/config-samples/palette-reversa-docs.json` | `configuracao/` (amostras dos portões manuais) | 🟢 |
| `scripts/config-samples/r1-in-layer.json` | `configuracao/` (amostras dos portões manuais) | 🟢 |
| `scripts/config-samples/stick-1800.json` | `configuracao/` (amostras dos portões manuais) | 🟢 |
| `scripts/create-local-signing-identity.sh` | `aplicativo/` | 🟢 |
| `scripts/test.sh` | `aplicativo/` | 🟢 |
| `Sources/JoystickAIPoC/main.swift` | `aplicativo/` | 🟢 |
| `Sources/JoystickAIPoC/App/AppDelegate.swift` | `aplicativo/` (bootstrap); ligações citadas em todas as units | 🟢 |
| `Sources/JoystickAIPoC/App/EditMenu.swift` | `editor/` | 🟢 |
| `Sources/JoystickAIPoC/App/InjectionGate.swift` | `aplicativo/` | 🟢 |
| `Sources/JoystickAIPoC/App/Lifecycle.swift` | `aplicativo/` | 🟢 |
| `Sources/JoystickAIPoC/App/PermissionMonitor.swift` | `aplicativo/` | 🟢 |
| `Sources/JoystickAIPoC/App/SigningInfo.swift` | `aplicativo/` | 🟢 |
| `Sources/JoystickAIPoC/App/StatusMenu.swift` | `aplicativo/` | 🟢 |
| `Sources/JoystickAIPoC/Config/ConfigStore.swift` | `configuracao/` | 🟢 |
| `Sources/JoystickAIPoC/Config/ConfigWatcher.swift` | `configuracao/` | 🟢 |
| `Sources/JoystickAIPoC/Config/ConfigWriter.swift` | `configuracao/` | 🟢 |
| `Sources/JoystickAIPoC/Controller/AxisTouchReader.swift` | `entrada-do-controle/` | 🟢 |
| `Sources/JoystickAIPoC/Controller/ButtonReader.swift` | `entrada-do-controle/` | 🟢 |
| `Sources/JoystickAIPoC/Controller/ControllerDiagnostics.swift` | `entrada-do-controle/` | 🟢 |
| `Sources/JoystickAIPoC/Controller/ControllerReader.swift` | `entrada-do-controle/` | 🟢 |
| `Sources/JoystickAIPoC/Controller/ExtendedReportActivator.swift` | `entrada-do-controle/` | 🟢 |
| `Sources/JoystickAIPoC/Controller/InputSink.swift` | `entrada-do-controle/` | 🟢 |
| `Sources/JoystickAIPoC/Controller/TransportResolver.swift` | `entrada-do-controle/` | 🟢 |
| `Sources/JoystickAIPoC/Display/DisplayMonitor.swift` | `ponteiro/` | 🟢 |
| `Sources/JoystickAIPoC/Display/ScreenCatalog.swift` | `ponteiro/`, `tela-de-alvos-e-analise/` | 🟢 |
| `Sources/JoystickAIPoC/Editor/ActionPanel.swift` | `editor/` | 🟢 |
| `Sources/JoystickAIPoC/Editor/ChordEditor.swift` | `editor/` | 🟢 |
| `Sources/JoystickAIPoC/Editor/ControllerFigureView.swift` | `editor/` | 🟢 |
| `Sources/JoystickAIPoC/Editor/EditorBanners.swift` | `editor/` | 🟢 |
| `Sources/JoystickAIPoC/Editor/EditorLabels.swift` | `editor/` | 🟢 |
| `Sources/JoystickAIPoC/Editor/EditorMetrics.swift` | `editor/` | 🟢 |
| `Sources/JoystickAIPoC/Editor/EditorRootView.swift` | `editor/` | 🟢 |
| `Sources/JoystickAIPoC/Editor/EditorViewModel.swift` | `editor/` | 🟢 |
| `Sources/JoystickAIPoC/Editor/EditorWindowController.swift` | `editor/` | 🟢 |
| `Sources/JoystickAIPoC/Editor/KeyCaptureField.swift` | `editor/` | 🟢 |
| `Sources/JoystickAIPoC/Editor/PaletteTab.swift` | `editor/` | 🟢 |
| `Sources/JoystickAIPoC/Editor/ShortcutsTab.swift` | `editor/` | 🟢 |
| `Sources/JoystickAIPoC/Injection/EventInjector.swift` | `injecao-de-eventos/` | 🟢 |
| `Sources/JoystickAIPoC/Injection/KeyboardInjector.swift` | `injecao-de-eventos/` | 🟢 |
| `Sources/JoystickAIPoC/Injection/ScrollInjector.swift` | `injecao-de-eventos/` | 🟢 |
| `Sources/JoystickAIPoC/Log/DiagnosticLog.swift` | `log-de-diagnostico/` | 🟢 |
| `Sources/JoystickAIPoC/Palette/PaletteActions.swift` | `paleta/` | 🟢 |
| `Sources/JoystickAIPoC/Palette/PalettePanel.swift` | `paleta/` | 🟢 |
| `Sources/JoystickAIPoC/Pointer/ButtonActions.swift` | `ponteiro/` | 🟢 |
| `Sources/JoystickAIPoC/Pointer/InputRouter.swift` | `ponteiro/` | 🟢 |
| `Sources/JoystickAIPoC/Pointer/MotionLoop.swift` | `ponteiro/` | 🟢 |
| `Sources/JoystickAIPoC/Pointer/ShortcutActions.swift` | `atalhos/` | 🟢 |
| `Sources/JoystickAIPoC/Targets/TargetAbortMonitor.swift` | `tela-de-alvos-e-analise/` | 🟢 |
| `Sources/JoystickAIPoC/Targets/TargetRunWriter.swift` | `tela-de-alvos-e-analise/` | 🟢 |
| `Sources/JoystickAIPoC/Targets/TargetSession.swift` | `tela-de-alvos-e-analise/` | 🟢 |
| `Sources/JoystickAIPoC/Targets/TargetWindow.swift` | `tela-de-alvos-e-analise/` | 🟢 |
| `Sources/JoystickCore/Analysis/LatencyStats.swift` | `tela-de-alvos-e-analise/` | 🟢 |
| `Sources/JoystickCore/Analysis/LogAnalysis.swift` | `tela-de-alvos-e-analise/` | 🟢 |
| `Sources/JoystickCore/Analysis/RunsReport.swift` | `tela-de-alvos-e-analise/` | 🟢 |
| `Sources/JoystickCore/App/LaunchArguments.swift` | `aplicativo/` | 🟢 |
| `Sources/JoystickCore/Config/ActionSummary.swift` | `configuracao/` (usado por `editor/`) | 🟢 |
| `Sources/JoystickCore/Config/ConfigDocument.swift` | `configuracao/` | 🟢 |
| `Sources/JoystickCore/Config/ConfigLineLocator.swift` | `configuracao/` | 🟢 |
| `Sources/JoystickCore/Config/ConfigLoader.swift` | `configuracao/` | 🟢 |
| `Sources/JoystickCore/Config/EditorDraft.swift` | `editor/` | 🟢 |
| `Sources/JoystickCore/Config/PointerSettingsValidation.swift` | `configuracao/` | 🟢 |
| `Sources/JoystickCore/Config/ShortcutConfig.swift` | `atalhos/` (ações e resolução), `configuracao/` (documento e problemas) | 🟢 |
| `Sources/JoystickCore/Config/ShortcutConfigValidation.swift` | `configuracao/` | 🟢 |
| `Sources/JoystickCore/Config/ShortcutDefaults.swift` | `atalhos/` | 🟢 |
| `Sources/JoystickCore/Input/ActiveControllerRegistry.swift` | `entrada-do-controle/` | 🟢 |
| `Sources/JoystickCore/Input/DualSenseReport.swift` | `entrada-do-controle/` | 🟢 |
| `Sources/JoystickCore/Input/InputEvent.swift` | `entrada-do-controle/` | 🟢 |
| `Sources/JoystickCore/Input/Normalization.swift` | `entrada-do-controle/` | 🟢 |
| `Sources/JoystickCore/Input/StartupAdoption.swift` | `entrada-do-controle/` | 🟢 |
| `Sources/JoystickCore/Log/LogEvent.swift` | `log-de-diagnostico/` | 🟢 |
| `Sources/JoystickCore/Log/LogEventCatalog.swift` | `log-de-diagnostico/` | 🟢 |
| `Sources/JoystickCore/Palette/CommandPalette.swift` | `paleta/` | 🟢 |
| `Sources/JoystickCore/Pointer/ClickStateMachine.swift` | `ponteiro/` | 🟢 |
| `Sources/JoystickCore/Pointer/Geometry.swift` | `ponteiro/` | 🟢 |
| `Sources/JoystickCore/Pointer/PointerMotionEngine.swift` | `ponteiro/` | 🟢 |
| `Sources/JoystickCore/Pointer/PointerSettings.swift` | `ponteiro/` | 🟢 |
| `Sources/JoystickCore/Pointer/ScreenUnion.swift` | `ponteiro/` | 🟢 |
| `Sources/JoystickCore/Pointer/ScrollMapper.swift` | `ponteiro/` | 🟢 |
| `Sources/JoystickCore/Pointer/StickKinematics.swift` | `ponteiro/` | 🟢 |
| `Sources/JoystickCore/Pointer/TouchpadTracker.swift` | `ponteiro/`, `entrada-do-controle/` (dedos e bordas) | 🟢 |
| `Sources/JoystickCore/Shortcuts/KeyCatalog.swift` | `atalhos/` | 🟢 |
| `Sources/JoystickCore/Shortcuts/KeyRepeat.swift` | `atalhos/` | 🟢 |
| `Sources/JoystickCore/Shortcuts/ShortcutMapper.swift` | `atalhos/` | 🟢 |
| `Sources/JoystickCore/Support/JSONValue.swift` | `log-de-diagnostico/` | 🟢 |
| `Sources/JoystickCore/Support/MonotonicClock.swift` | `log-de-diagnostico/` | 🟢 |
| `Sources/JoystickCore/Targets/TargetRun.swift` | `tela-de-alvos-e-analise/` | 🟢 |
| `Sources/poc-tools/ButtonsCommand.swift` | `tela-de-alvos-e-analise/` | 🟢 |
| `Sources/poc-tools/CyclesCommand.swift` | `tela-de-alvos-e-analise/` | 🟢 |
| `Sources/poc-tools/LatencyCommand.swift` | `tela-de-alvos-e-analise/` | 🟢 |
| `Sources/poc-tools/main.swift` | `tela-de-alvos-e-analise/` | 🟢 |
| `Sources/poc-tools/RunsCommand.swift` | `tela-de-alvos-e-analise/` | 🟢 |
| `Sources/poc-tools/ToolInput.swift` | `tela-de-alvos-e-analise/` | 🟢 |

## Testes

| Arquivo do legado | Unit correspondente | `@Test` | Cobertura |
|---------|---------------------|---------|-----------|
| `Tests/JoystickCoreTests/ActionSummaryTests.swift` | `configuracao/` | 5 | 🟢 |
| `Tests/JoystickCoreTests/ActiveControllerRegistryTests.swift` | `entrada-do-controle/` | 9 | 🟢 |
| `Tests/JoystickCoreTests/ClickStateMachineTests.swift` | `ponteiro/` | 9 | 🟢 |
| `Tests/JoystickCoreTests/CommandPaletteTests.swift` | `paleta/` | 20 | 🟢 |
| `Tests/JoystickCoreTests/ConfigDocumentTests.swift` | `configuracao/` | 8 | 🟢 |
| `Tests/JoystickCoreTests/ConfigLineLocatorTests.swift` | `configuracao/` | 7 | 🟢 |
| `Tests/JoystickCoreTests/ConfigLoaderTests.swift` | `configuracao/` | 16 | 🟢 |
| `Tests/JoystickCoreTests/DualSenseReportTests.swift` | `entrada-do-controle/` | 2 | 🟢 |
| `Tests/JoystickCoreTests/EditorDraftTests.swift` | `editor/` | 18 | 🟢 |
| `Tests/JoystickCoreTests/KeyCatalogTests.swift` | `atalhos/` | 6 | 🟢 |
| `Tests/JoystickCoreTests/LatencyStatsTests.swift` | `tela-de-alvos-e-analise/` | 4 | 🟢 |
| `Tests/JoystickCoreTests/LaunchArgumentsTests.swift` | `aplicativo/` | 11 | 🟢 |
| `Tests/JoystickCoreTests/LogAnalysisTests.swift` | `tela-de-alvos-e-analise/` | 4 | 🟢 |
| `Tests/JoystickCoreTests/LogEventCatalogTests.swift` | `log-de-diagnostico/` | 8 | 🟢 |
| `Tests/JoystickCoreTests/NormalizationTests.swift` | `entrada-do-controle/` | 9 | 🟢 |
| `Tests/JoystickCoreTests/PointerMotionEngineTests.swift` | `ponteiro/` | 10 | 🟢 |
| `Tests/JoystickCoreTests/PointerSettingsValidationTests.swift` | `configuracao/` | 8 | 🟢 |
| `Tests/JoystickCoreTests/RunsReportTests.swift` | `tela-de-alvos-e-analise/` | 6 | 🟢 |
| `Tests/JoystickCoreTests/ScreenUnionTests.swift` | `ponteiro/` | 5 | 🟢 |
| `Tests/JoystickCoreTests/ScrollMapperTests.swift` | `ponteiro/` | 7 | 🟢 |
| `Tests/JoystickCoreTests/ShortcutConfigTests.swift` | `atalhos/` | 7 | 🟢 |
| `Tests/JoystickCoreTests/ShortcutConfigValidationTests.swift` | `configuracao/` | 20 | 🟢 |
| `Tests/JoystickCoreTests/ShortcutDefaultsTests.swift` | `atalhos/` | 1 | 🟢 |
| `Tests/JoystickCoreTests/ShortcutMapperTests.swift` | `atalhos/` | 18 | 🟢 |
| `Tests/JoystickCoreTests/StartupAdoptionTests.swift` | `entrada-do-controle/` | 3 | 🟢 |
| `Tests/JoystickCoreTests/StickKinematicsTests.swift` | `ponteiro/` | 8 | 🟢 |
| `Tests/JoystickCoreTests/SupportTests.swift` | `log-de-diagnostico/` | 5 | 🟢 |
| `Tests/JoystickCoreTests/TargetRunTests.swift` | `tela-de-alvos-e-analise/` | 9 | 🟢 |
| `Tests/JoystickCoreTests/TouchpadTrackerTests.swift` | `ponteiro/`, `entrada-do-controle/` | 10 | 🟢 |

Total do alvo de testes: 253 `@Test` em 29 arquivos, executados por `scripts/test.sh`. 🟢

## Specs pré-existentes

As specs do ciclo forward em `_reversa_sdd/sdd/` e os adendos em `_reversa_sdd/addenda/` não foram alterados. A relação entre elas e as units está em `traceability/spec-impact-matrix.md`. 🟢

## Cobertura

| Medida | Valor |
|--------|-------|
| Arquivos de produção (87 Swift, `Package.swift`, `Info.plist`, 4 scripts, 7 amostras de configuração) | 100 |
| Arquivos de produção mapeados a alguma unit | 100 (100%) |
| Arquivos de teste mapeados | 29 de 29 (100%) |
| Arquivos com `n/a` | 0 |
| Arquivos cobertos por mais de uma unit | 4 (`AppDelegate.swift`, `ScreenCatalog.swift`, `ShortcutConfig.swift`, `TouchpadTracker.swift`) |

🟢
