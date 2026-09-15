# Entrada do controle (controller-input), Tarefas de Implementação

> Gerado pelo Redator em 2026-09-15 · Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA

## Pré-requisitos

- [ ] App assinado com identidade estável e Acessibilidade concedida (unit `aplicativo`)
- [ ] `DiagnosticLog` e `LogEventCatalog` disponíveis (unit `log-de-diagnostico`)
- [ ] `PointerSettings.deadzone` disponível (unit `configuracao`)
- [ ] Um DualSense para os roteiros por USB e por Bluetooth

## Tarefas

- [ ] T-01, Definir `ButtonID`, `ButtonPhase`, `TouchPhase`, `ConnectionType`, `ControllerInfo`, `InputElement`, `InputEventKind` e `InputEvent`
  - Origem no legado: `Sources/JoystickCore/Input/InputEvent.swift`
  - Critério de pronto: `ButtonID.allCases` na ordem declarada e `<` coerente com ela
  - Confiança: 🟢

- [ ] T-02, Implementar `Normalization` e `TriggerTracker`
  - Origem no legado: `Sources/JoystickCore/Input/Normalization.swift`
  - Critério de pronto: zona morta por eixo sem reescala; limiar 0,5 sem histerese; toque limitado
  - Confiança: 🟢

- [ ] T-03, Implementar `StartupAdoption`
  - Origem no legado: `Sources/JoystickCore/Input/StartupAdoption.swift`
  - Critério de pronto: enumeração sempre `true`; notificação `true` só abaixo de 2 s
  - Confiança: 🟢

- [ ] T-04, Implementar `ActiveControllerRegistry` genérico
  - Origem no legado: `Sources/JoystickCore/Input/ActiveControllerRegistry.swift`
  - Critério de pronto: ativo, fila, duplicata, soltura ordenada e promoção cobertos por teste
  - Confiança: 🟢

- [ ] T-05, Implementar `DualSenseReport.homeButton` para os três formatos de relatório
  - Origem no legado: `Sources/JoystickCore/Input/DualSenseReport.swift`
  - Critério de pronto: testes com bytes sintéticos para `0x01`/64, `0x31`/12 e `0x01`/10, e `nil` nos demais
  - Confiança: 🟢

- [ ] T-06, Implementar `ZeroTransitionPhaseInference`
  - Origem no legado: `Sources/JoystickCore/Pointer/TouchpadTracker.swift:60-79`
  - Critério de pronto: tabela de transições coberta
  - Confiança: 🟢

- [ ] T-07, Implementar `InputSink`, `LoggingInputSink` e `InputContext` com `assertOnQueue`
  - Origem no legado: `Sources/JoystickAIPoC/Controller/InputSink.swift`
  - Critério de pronto: `dispatchPrecondition` falha fora da fila `input` em build de depuração
  - Confiança: 🟢

- [ ] T-08, Implementar `TransportResolver` por IORegistry
  - Origem no legado: `Sources/JoystickAIPoC/Controller/TransportResolver.swift`
  - Critério de pronto: um controle por USB → `usb`; um por Bluetooth → `bluetooth`; os dois → `unknown`
  - Confiança: 🟢

- [ ] T-09, Implementar `ButtonReader` com o mapeamento de RN-EC-16 e `deliver`
  - Origem no legado: `Sources/JoystickAIPoC/Controller/ButtonReader.swift`
  - Critério de pronto: roteiro de 18 botões com `poc-tools buttons` em 18 de 18
  - Confiança: 🟢

- [ ] T-10, Implementar `AxisTouchReader` com as duas vias do toque e supressão de repetição dos analógicos
  - Origem no legado: `Sources/JoystickAIPoC/Controller/AxisTouchReader.swift`
  - Critério de pronto: analógico em repouso sem entregas; toque com `began`/`ended` no log
  - Confiança: 🟢

- [ ] T-11, Implementar `ExtendedReportActivator` (`IOHIDManager`, relatório `0x05`, PS)
  - Origem no legado: `Sources/JoystickAIPoC/Controller/ExtendedReportActivator.swift`
  - Critério de pronto: por Bluetooth, touchpad funcional e PS entregue com o Terminal em foco
  - Confiança: 🟢

- [ ] T-12, Implementar `ControllerDiagnostics`
  - Origem no legado: `Sources/JoystickAIPoC/Controller/ControllerDiagnostics.swift`
  - Critério de pronto: `controller.gesture_suppression` registrado a cada conexão
  - Confiança: 🟢

- [ ] T-13, Implementar `ControllerReader` (início, conexão, desconexão)
  - Origem no legado: `Sources/JoystickAIPoC/Controller/ControllerReader.swift`
  - Critério de pronto: cenários de `requirements.md` passam, inclusive adoção na abertura e soltura sintética
  - Confiança: 🟢

## Tarefas de Teste

- [ ] TT-01, `ActiveControllerRegistryTests`, `NormalizationTests`, `StartupAdoptionTests`, `DualSenseReportTests`, inferência de toque em `TouchpadTrackerTests`
- [ ] TT-02, Roteiro manual de 18 botões por USB e por Bluetooth, com o Terminal em foco
- [ ] TT-03, Roteiro manual com dois DualSense: fila, promoção e botões do controle em fila
- [ ] TT-04, Desligar o controle durante um arraste com R1 e verificar o botão solto
- [ ] TT-05, 100 ciclos de conexão e desconexão verificados por `poc-tools cycles`

## Ordem Sugerida

1. T-01 a T-06 no núcleo, com testes.
2. T-07 e T-08, independentes de hardware.
3. T-09 a T-12, que exigem o controle.
4. T-13 por último, integrando os leitores.

## Lacunas Pendentes (🔴)

Nenhuma. RN-EC-17 (PS atribuído ao ativo) foi aceita pelo usuário em 2026-09-15 (L-02 / DV-04).
