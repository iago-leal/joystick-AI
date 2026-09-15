# Atalhos (shortcuts), Tarefas de Implementação

> Gerado pelo Redator em 2026-09-15 · Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA

## Pré-requisitos

- [ ] `ButtonID` e `InputEvent` (unit `entrada-do-controle`)
- [ ] `KeyboardInjector` (unit `injecao-de-eventos`)
- [ ] `LogEventCatalog.shortcutTriggered` (unit `log-de-diagnostico`)

## Tarefas

- [ ] T-01, Definir `KeyModifier`, `KeyChord` e `KeyRepeat`
  - Origem no legado: `Sources/JoystickCore/Shortcuts/ShortcutMapper.swift:1-35`, `KeyRepeat.swift`
  - Critério de pronto: ordem ⌃⌥⇧⌘; `isArrow` só para 123 a 126
  - Confiança: 🟢

- [ ] T-02, Implementar `KeyCatalog` com 73 teclas e exibição de acordes
  - Origem no legado: `Sources/JoystickCore/Shortcuts/KeyCatalog.swift`
  - Critério de pronto: `KeyCatalogTests` (nomes e teclas únicos, ida e volta, grupos, exibição)
  - Confiança: 🟢

- [ ] T-03, Implementar `SystemShortcut` com leitura de `AppleSymbolicHotKeys`
  - Origem no legado: `Sources/JoystickCore/Shortcuts/ShortcutMapper.swift:37-104`
  - Critério de pronto: entrada válida muda o acorde; ausente, desativada ou malformada mantém o padrão
  - Confiança: 🟢

- [ ] T-04, Definir `TriggerAction` e `ShortcutConfig.resolvedAction`
  - Origem no legado: `Sources/JoystickCore/Config/ShortcutConfig.swift:1-66`
  - Critério de pronto: `ShortcutConfigTests` (própria, herdada, "nenhuma" bloqueia, camada ausente)
  - Confiança: 🟢

- [ ] T-05, Implementar `ShortcutMapper` (pressionar, soltar, soltar tudo, gatilho)
  - Origem no legado: `Sources/JoystickCore/Shortcuts/ShortcutMapper.swift:106-224`
  - Critério de pronto: `ShortcutMapperTests`, incluindo invariantes em sequências aleatórias
  - Confiança: 🟢

- [ ] T-06, Declarar `ShortcutDefaults`
  - Origem no legado: `Sources/JoystickCore/Config/ShortcutDefaults.swift`
  - Critério de pronto: `ShortcutDefaultsTests` confirma equivalência ao protótipo 001 com PS na paleta
  - Confiança: 🟢

- [ ] T-07, Implementar `ShortcutActions` (execução, repetição, atalhos de sistema, solturas)
  - Origem no legado: `Sources/JoystickAIPoC/Pointer/ShortcutActions.swift`
  - Critério de pronto: cenários de `requirements.md`; nenhuma tecla presa após desconexão ou abertura da paleta
  - Confiança: 🟢

- [ ] T-08, Ligar os pontos de ruptura (identificação, encerramento, portão de injeção, configuração)
  - Origem no legado: `InputRouter.swift:28-35`, `Lifecycle.swift:33-38`, `InjectionGate.swift:39-51`, `AppDelegate.swift:57,77`
  - Critério de pronto: cada ruptura solta ⌘ mantido por Options
  - Confiança: 🟢

## Tarefas de Teste

- [ ] TT-01, `KeyCatalogTests` (6), `ShortcutConfigTests` (7), `ShortcutMapperTests` (18), `ShortcutDefaultsTests` (1)
- [ ] TT-02, Roteiro manual: camadas L1, L2 e Options no Terminal e no Finder
- [ ] TT-03, Roteiro manual: remapear Mission Control nas preferências e acionar Create sem reiniciar
- [ ] TT-04, Roteiro manual: desconectar o controle com Options segurado; revogar e restaurar a Acessibilidade com L2 + ← segurados
- [ ] TT-05, Conferir no log que `shortcut.triggered` não contém teclas nem textos

## Ordem Sugerida

1. T-01 a T-04, tipos puros.
2. T-05 e T-06, com os testes do núcleo.
3. T-07 e T-08 no app.

## Lacunas Pendentes (🔴)

Nenhuma. 🟢 L-01 fechada em 2026-09-15: o ditado permanece como R3 → ⌘M do Raycast (RN-AT-21).
