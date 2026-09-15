# Tela de alvos e análise (targets-analysis), Tarefas de Implementação

> Gerado pelo Redator em 2026-09-15 · Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA

## Pré-requisitos

- [ ] Log JSONL e catálogo de eventos (unit `log-de-diagnostico`)
- [ ] `PointerSettings`, `DisplayMonitor`, `InputRouter` (unit `ponteiro`)
- [ ] `EventInjector.sourceMark` (unit `injecao-de-eventos`)
- [ ] `LaunchArguments` e `InjectionGate` (unit `aplicativo`)

## Tarefas

- [ ] T-01, Implementar `TargetRun` e tipos associados, `SeededGenerator` e `TargetLayout`
  - Origem no legado: `Sources/JoystickCore/Targets/TargetRun.swift`
  - Critério de pronto: `TargetRunTests` (9): resumo, nulos por grupo, nome com sufixo, posições reproduzíveis dentro da margem
  - Confiança: 🟢

- [ ] T-02, Implementar `LatencyStats`
  - Origem no legado: `Sources/JoystickCore/Analysis/LatencyStats.swift`
  - Critério de pronto: `LatencyStatsTests` (4)
  - Confiança: 🟢

- [ ] T-03, Implementar `LogAnalysis`
  - Origem no legado: `Sources/JoystickCore/Analysis/LogAnalysis.swift`
  - Critério de pronto: `LogAnalysisTests` (4): malformadas, sintéticos ignorados, ciclos, amostras
  - Confiança: 🟢

- [ ] T-04, Implementar `RunsReport`
  - Origem no legado: `Sources/JoystickCore/Analysis/RunsReport.swift`
  - Critério de pronto: `RunsReportTests` (6): filtro, ordem, parâmetros alterados, discrepantes, lista vazia
  - Confiança: 🟢

- [ ] T-05, Implementar `ScreenCatalog`, `TargetWindow` e `TargetView`
  - Origem no legado: `Sources/JoystickAIPoC/Display/ScreenCatalog.swift`, `Sources/JoystickAIPoC/Targets/TargetWindow.swift`
  - Critério de pronto: alvo desenhado nas coordenadas de `TargetLayout`
  - Confiança: 🟢

- [ ] T-06, Implementar `TargetSession`, `TargetAbortMonitor` e `TargetRunWriter`
  - Origem no legado: `Sources/JoystickAIPoC/Targets/TargetSession.swift`, `TargetAbortMonitor.swift`, `TargetRunWriter.swift`
  - Critério de pronto: sequência completa e interrompida pelos quatro motivos gravam o arquivo correto
  - Confiança: 🟢

- [ ] T-07, Ligar `openTargets` no bootstrap com validação de argumentos e bloqueio da paleta
  - Origem no legado: `Sources/JoystickAIPoC/App/AppDelegate.swift:137-190`
  - Critério de pronto: `--screen` inválido cai na tela 1 com aviso; `--targets` sem `--env` não abre
  - Confiança: 🟢

- [ ] T-08, Implementar `poc-tools` (`main`, `ToolInput`, quatro comandos)
  - Origem no legado: `Sources/poc-tools/*.swift`
  - Critério de pronto: saídas e códigos 0/64/66 conforme RN-TA-18 a RN-TA-24
  - Confiança: 🟢

## Tarefas de Teste

- [ ] TT-01, Testes do núcleo: `TargetRunTests`, `LatencyStatsTests`, `LogAnalysisTests`, `RunsReportTests` (23)
- [ ] TT-02, Executar as sequências da tela de alvos em mesa e sofá e gerar `poc-tools runs` (PM-3 da 001)
- [ ] TT-03, Medir `poc-tools latency` com movimento pelo toque e pelo analógico e registrar CPU em movimento
- [ ] TT-04, Executar 100 ciclos de conexão e conferir `poc-tools cycles`
- [ ] TT-05, Rodar `poc-tools buttons` num log com os 18 botões

## Ordem Sugerida

1. T-01 a T-04 no núcleo.
2. T-08, que depende só do núcleo.
3. T-05 a T-07 no app.

## Lacunas Pendentes (🔴)

Nenhuma. As medições do PM-3 continuam planejadas (L-03 respondida em 2026-09-15): TT-02 a TT-04.
