# Paleta de comandos (palette), Tarefas de Implementação

> Gerado pelo Redator em 2026-09-15 · Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA

## Pré-requisitos

- [ ] `KeyboardInjector` (unit `injecao-de-eventos`)
- [ ] Ação `openPalette` e `KeyRepeat` (unit `atalhos`)
- [ ] Lista validada e `onApply` (unit `configuracao`)
- [ ] Eventos `palette.*` (unit `log-de-diagnostico`)

## Tarefas

- [ ] T-01, Definir `PaletteItem`, `PaletteDefaults`, `PaletteSnapshot`, `PaletteEffect` e `PaletteCloseReason`
  - Origem no legado: `Sources/JoystickCore/Palette/CommandPalette.swift:1-80`
  - Critério de pronto: 17 itens na ordem, sem Enter e sem rótulo
  - Confiança: 🟢

- [ ] T-02, Implementar `PaletteMachine` com entrada fixa
  - Origem no legado: `Sources/JoystickCore/Palette/CommandPalette.swift:82-178`
  - Critério de pronto: `CommandPaletteTests` (20 testes), incluindo navegação circular e entrada fixa
  - Confiança: 🟢

- [ ] T-03, Implementar `PaletteActions` (log, repetição, digitação, Enter com atraso, inatividade, `apply`)
  - Origem no legado: `Sources/JoystickAIPoC/Palette/PaletteActions.swift`
  - Critério de pronto: cenários de `requirements.md`; fechamento por inatividade em 60 s
  - Confiança: 🟢

- [ ] T-04, Implementar `PalettePanel` e `PaletteView`
  - Origem no legado: `Sources/JoystickAIPoC/Palette/PalettePanel.swift`
  - Critério de pronto: painel não tira o foco do Terminal; cliques atravessam; rolagem quando a tela é baixa
  - Confiança: 🟢

- [ ] T-05, Ligar a paleta no bootstrap e nos pontos de fechamento externo
  - Origem no legado: `AppDelegate.swift:66-82,105,177-181`, `InputRouter.swift:33,48-62`, `InjectionGate.swift:49`
  - Critério de pronto: cada motivo de `PaletteCloseReason` aparece no log no cenário correspondente
  - Confiança: 🟢

## Tarefas de Teste

- [ ] TT-01, `CommandPaletteTests`
- [ ] TT-02, Roteiro manual: abrir, navegar, confirmar no Terminal e no VS Code, verificar o foco
- [ ] TT-03, Roteiro manual: `--palette-enter-delay-ms 120` com item de Enter e valor inválido (`palette.invalid_args`)
- [ ] TT-04, Roteiro manual: fechar por desconexão, revogação, inatividade, gravação no editor e identificação
- [ ] TT-05, Legibilidade a 3 m na TV, com a lista padrão e com 50 itens

## Ordem Sugerida

1. T-01 e T-02 no núcleo.
2. T-04, independente da execução.
3. T-03 e T-05.

## Lacunas Pendentes (🔴)

Nenhuma. DV-07 (fechamentos sem `palette.closed`) está registrada como 🟡.
