# Editor de atalhos (editor), Tarefas de Implementação

> Gerado pelo Redator em 2026-09-15 · Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA

## Pré-requisitos

- [ ] `ConfigStore`, `ShortcutConfigValidation` e `ActionSummary` (unit `configuracao`)
- [ ] `KeyCatalog`, `SystemShortcut`, `TriggerAction` (unit `atalhos`)
- [ ] `InputRouter.setIdentifying` (unit `ponteiro`)
- [ ] `EventInjector.activationClick` (unit `injecao-de-eventos`)
- [ ] `StatusMenu` e bootstrap (unit `aplicativo`)

## Tarefas

- [ ] T-01, Implementar `EditorDraft` com alvos, avisos e operações
  - Origem no legado: `Sources/JoystickCore/Config/EditorDraft.swift`
  - Critério de pronto: `EditorDraftTests` (18), incluindo marcação e desmarcação de modificador com "nenhuma" devolvida
  - Confiança: 🟢

- [ ] T-02, Implementar `EditorMetrics` e estilos de TV
  - Origem no legado: `Sources/JoystickAIPoC/Editor/EditorMetrics.swift`
  - Critério de pronto: alvos de 60 pt; janela cabe em tela de 900 pt
  - Confiança: 🟢

- [ ] T-03, Implementar `EditorViewModel`
  - Origem no legado: `Sources/JoystickAIPoC/Editor/EditorViewModel.swift`
  - Critério de pronto: gravação, descarte, `.bak`, conflito e abertura conforme RN-ED-21 a RN-ED-29
  - Confiança: 🟢

- [ ] T-04, Implementar `EditorLabels`, `ControllerFigureView`, `ShortcutsTab` e `ActionPanel`
  - Origem no legado: `Sources/JoystickAIPoC/Editor/EditorLabels.swift`, `ControllerFigureView.swift`, `ShortcutsTab.swift`, `ActionPanel.swift`
  - Critério de pronto: editar todas as ações do padrão só com o ponteiro do controle
  - Confiança: 🟢

- [ ] T-05, Implementar `ChordEditor` e `KeyCaptureField`
  - Origem no legado: `Sources/JoystickAIPoC/Editor/ChordEditor.swift`, `KeyCaptureField.swift`
  - Critério de pronto: montar ⌘Tab pelo ponteiro; gravar ⌘⇧T pelo teclado; tecla injetada não é capturada
  - Confiança: 🟢

- [ ] T-06, Implementar `PaletteTab`
  - Origem no legado: `Sources/JoystickAIPoC/Editor/PaletteTab.swift`
  - Critério de pronto: incluir, editar, mover por botões e por arrastar, remover
  - Confiança: 🟢

- [ ] T-07, Implementar `EditorBanners` e `EditorRootView`
  - Origem no legado: `Sources/JoystickAIPoC/Editor/EditorBanners.swift`, `EditorRootView.swift`
  - Critério de pronto: cada faixa aparece no cenário correspondente; rodapé reflete problemas e sujeira
  - Confiança: 🟢

- [ ] T-08, Implementar `EditorWindowController` com ativação E003 e devolução de foco
  - Origem no legado: `Sources/JoystickAIPoC/Editor/EditorWindowController.swift`
  - Critério de pronto: aberto pela paleta, o editor fica ativo sem clique manual; fechar volta ao app anterior
  - Confiança: 🟢

- [ ] T-09, Instalar `EditMenu` e ligar o editor no bootstrap (menu, alerta, paleta, identificação)
  - Origem no legado: `Sources/JoystickAIPoC/App/EditMenu.swift`, `AppDelegate.swift:87-117`
  - Critério de pronto: ⌘V cola no campo; ⌘Q no editor não encerra o app; identificação seleciona botões
  - Confiança: 🟢

- [ ] T-10, Corrigir DV-05: "Copiar e gravar" só grava se `canSave` for verdadeiro no momento do toque
  - Origem no legado: `Sources/JoystickAIPoC/Editor/EditorViewModel.swift`, `Sources/JoystickAIPoC/Editor/EditorBanners.swift` (defeito, L-02 respondida em 2026-09-15)
  - Critério de pronto: com a faixa do `.bak` visível, um rascunho que ficou inválido mantém "Copiar e gravar" indisponível; a correção de `configuracao` T-11 cobre o mesmo caso na gravação
  - Confiança: 🟢

## Tarefas de Teste

- [ ] TT-01, `EditorDraftTests`
- [ ] TT-02, Roteiro manual no sofá: abrir pela paleta, editar uma ação, salvar e usar
- [ ] TT-03, Roteiro manual: conflito externo com rascunho sujo, nas duas escolhas
- [ ] TT-04, Roteiro manual: arquivo corrompido, "Copiar e gravar"; falha de gravação com diretório sem permissão
- [ ] TT-05, Roteiro manual: fechar com rascunho sujo nas três escolhas; conferir `editor.closed`
- [ ] TT-06, Conferir nos logs a ausência de `editor.activation_failed` em aberturas pelo controle

## Ordem Sugerida

1. T-01 e T-02.
2. T-03.
3. T-04 a T-07.
4. T-08 e T-09.

## Lacunas Pendentes (🔴)

Nenhuma. DV-05 foi classificada como defeito em 2026-09-15 e virou T-10.
