# Ponteiro (pointer), Tarefas de Implementação

> Gerado pelo Redator em 2026-09-15 · Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA

## Pré-requisitos

- [ ] `InputEvent`, `ButtonID` e `InputContext` (unit `entrada-do-controle`)
- [ ] `EventInjector` e `ScrollInjector` (unit `injecao-de-eventos`)
- [ ] `PointerSettings` validados (unit `configuracao`)
- [ ] `ShortcutActions` e `PaletteActions` para o roteador (units `atalhos` e `paleta`)

## Tarefas

- [ ] T-01, Definir `ScreenPoint`, `ScreenRect`, `PointDelta` e `PointerSettings` com faixas e `jsonValue`
  - Origem no legado: `Sources/JoystickCore/Pointer/Geometry.swift`, `PointerSettings.swift`, `StickKinematics.swift:1-24`
  - Critério de pronto: padrões e faixas iguais aos de `data-dictionary.md` §2.1
  - Confiança: 🟢

- [ ] T-02, Implementar `StickKinematics` e `SubpixelAccumulator`
  - Origem no legado: `Sources/JoystickCore/Pointer/StickKinematics.swift:26-58`
  - Critério de pronto: 30% de inclinação abaixo de 10% da máxima; diagonal com `m` limitado a 1; Y invertido; resto acumulado
  - Confiança: 🟢

- [ ] T-03, Implementar `TouchpadTracker` com dedo primário e descarte de atualização por eixo
  - Origem no legado: `Sources/JoystickCore/Pointer/TouchpadTracker.swift:1-58`
  - Critério de pronto: pousar não move; troca de primário sem salto; amostra parcial descartada
  - Confiança: 🟢

- [ ] T-04, Implementar `PointerMotionEngine` com onset, temporizador, pendente do toque e precisão
  - Origem no legado: `Sources/JoystickCore/Pointer/PointerMotionEngine.swift`
  - Critério de pronto: `MotionOutput` correto nas transições; parada só com os dois analógicos em repouso
  - Confiança: 🟢

- [ ] T-05, Implementar `ClickStateMachine`
  - Origem no legado: `Sources/JoystickCore/Pointer/ClickStateMachine.swift`
  - Critério de pronto: dois detentores; duplo clique por tempo e distância; `releaseAll` ordenado
  - Confiança: 🟢

- [ ] T-06, Implementar `ScrollMapper` para pixel e linha
  - Origem no legado: `Sources/JoystickCore/Pointer/ScrollMapper.swift`
  - Critério de pronto: 20 px por linha; inversão; frações acumuladas; sinais da convenção do `CGEvent`
  - Confiança: 🟢

- [ ] T-07, Implementar `ScreenUnion`
  - Origem no legado: `Sources/JoystickCore/Pointer/ScreenUnion.swift`
  - Critério de pronto: ponto no vão entre telas desalinhadas vai ao retângulo mais próximo
  - Confiança: 🟢

- [ ] T-08, Implementar `ButtonActions`
  - Origem no legado: `Sources/JoystickAIPoC/Pointer/ButtonActions.swift`
  - Critério de pronto: arraste com R1; desconexão solta o botão
  - Confiança: 🟢

- [ ] T-09, Implementar `MotionLoop` com o temporizador estrito de 120 Hz
  - Origem no legado: `Sources/JoystickAIPoC/Pointer/MotionLoop.swift`
  - Critério de pronto: CPU próxima de zero em repouso; movimento contínuo com o analógico; rolagem imediata no onset
  - Confiança: 🟢

- [ ] T-10, Implementar `DisplayMonitor` e `ScreenCatalog`
  - Origem no legado: `Sources/JoystickAIPoC/Display/DisplayMonitor.swift`, `ScreenCatalog.swift`
  - Critério de pronto: desconectar uma tela com o cursor nela reposiciona o cursor
  - Confiança: 🟢

- [ ] T-11, Implementar `InputRouter` com modo de identificação
  - Origem no legado: `Sources/JoystickAIPoC/Pointer/InputRouter.swift`
  - Critério de pronto: cenários de roteamento de `requirements.md` passam
  - Confiança: 🟢

## Tarefas de Teste

- [ ] TT-01, `StickKinematicsTests`, `TouchpadTrackerTests`, `PointerMotionEngineTests`, `ClickStateMachineTests`, `ScrollMapperTests`, `ScreenUnionTests`
- [ ] TT-02, Roteiro manual: movimento, arraste, duplo clique, rolagem e precisão no VS Code e no Terminal
- [ ] TT-03, Tela de alvos em mesa e sofá (unit `tela-de-alvos-e-analise`)
- [ ] TT-04, `poc-tools latency` com p95 de entrada ao movimento ≤ 20 ms
- [ ] TT-05, Duas telas lado a lado e desconexão de uma delas

## Ordem Sugerida

1. T-01 a T-07 no núcleo, cada uma com testes.
2. T-08 a T-10 no app.
3. T-11 por último, porque depende de atalhos e paleta.

## Lacunas Pendentes (🔴)

Nenhuma. As medições pendentes do PM-3 da 001 continuam planejadas (L-03 respondida em 2026-09-15; `tela-de-alvos-e-analise` TT-02 a TT-04).
