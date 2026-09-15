# ADR-003: GameController em segundo plano, complementado por HID bruto

- **Status:** Aceito
- **Data:** 2026-09-14
- **Tipo:** retroativo (reconstruído pelo Detetive em 2026-09-15)

## Contexto

O app precisa ler o DualSense com outro aplicativo em primeiro plano. No macOS, o botão PS é retido pelo sistema antes do `GameController`, e por Bluetooth o controle começa em modo simplificado, sem touchpad. `physicalInputProfile.touchpads` vem vazio.

## Decisão

Ler pelo `GameController` com `shouldMonitorBackgroundEvents = true` definido antes dos observadores e `handlerQueue` na fila `input`. Complementar com um `IOHIDManager` que lê o PS do relatório bruto e, por Bluetooth, pede o relatório de recurso `0x05` para ativar o modo estendido. Inferir a fase do toque pela transição de e para (0, 0). Pedir `preferredSystemGestureState = .disabled` no PS.

## Alternativas consideradas

Só `GameController` (sem PS e sem touchpad por Bluetooth); só IOKit HID (reimplementar todo o parsing e exigir mais permissões).

## Consequências

🟢 18 de 18 botões por Bluetooth com outros apps em primeiro plano, sem Input Monitoring (P-04), depois de ajustar em Ajustes do Sistema › Controles de jogo o PS para não abrir o Game Center (`validation-report.md` 001:26-30). 🟡 O PS do HID não identifica o controle de origem e é atribuído ao ativo. 🟡 A inferência por zero exige descartar amostras intermediárias de um eixo só.

## Evidências

- `ControllerReader.swift:20-55`
- `ExtendedReportActivator.swift:57-65`
- `DualSenseReport.swift:7-16`
- 001 D-04, D-05, D-23; P-01, P-04
