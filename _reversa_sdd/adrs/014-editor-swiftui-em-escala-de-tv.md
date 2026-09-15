# ADR-014: Editor em SwiftUI na escala de TV, operável pelo controle

- **Status:** Aceito
- **Data:** 2026-09-14
- **Tipo:** retroativo (reconstruído pelo Detetive em 2026-09-15)

## Contexto

O editor é usado a cerca de 3 m, na TV, com o ponteiro do controle; alvos pequenos e texto de desktop são ilegíveis e difíceis de acertar. O usuário também dita textos pelo Raycast, que cola nos campos.

## Decisão

Interface SwiftUI dentro de `NSWindow`, com métricas centralizadas em `EditorMetrics` (corpo 32 pt, títulos 40 pt, alvos de 60 pt, janela mínima 1.400 × 800 pt), figura do controle com os 18 botões, modo de identificação pelo próprio controle, acordes gravados pelo teclado ou montados por seleção, rolagem só vertical e menu principal oculto com "Editar" para colar.

## Alternativas consideradas

AppKit puro (mais código de layout); tamanhos de desktop (reprovados no PM-1a, que elevou 24/30 pt para 32/40/60 pt).

## Consequências

🟢 PM-1a e PM-2 aprovados. 🟡 Linhas da paleta identificadas por índice podem reaproveitar o estado de edição errado após reordenar.

## Evidências

- `EditorMetrics.swift:9-17`
- `EditMenu.swift`
- `KeyCaptureField.swift`
- 003 D-19 a D-25
