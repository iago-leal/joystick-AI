# ADR-015: Ditado delegado ao Raycast, sem captura de áudio própria

- **Status:** Aceito (decisão do usuário em 2026-09-15)
- **Data:** 2026-09-14
- **Tipo:** retroativo (reconstruído pelo Detetive em 2026-09-15)

## Contexto

O PRD pede ditado de prompts pelo controle. Os testes de 2026-09-14 mostraram que o microfone do DualSense só aparece como entrada de áudio por USB, e que o Raycast escolhe o microfone pela própria lista de prioridade e transcreve bem.

## Decisão

O app não transcreve nem captura áudio. No estado atual, R3 dispara ⌘M, atalho do transcritor do Raycast configurado pelo usuário, e o menu Editar permite que o texto ditado seja colado nos campos do editor. Essa é a solução definitiva: o modo segurar para falar planejado em `sdd/voice-dictation.md` não será implementado, e a spec fica superada.

## Alternativas consideradas

Reconhecimento próprio com `Speech`/`AVAudioEngine` (escopo e permissões de microfone); microfone do controle por Bluetooth (indisponível no macOS).

## Consequências

🟢 Nenhuma permissão de microfone é pedida pelo app. 🟢 O atalho configurável substitui o componente `voice-dictation`. 🟢 O ditado depende de o usuário manter o atalho do transcritor configurado no Raycast, fora do app.

## Evidências

- `ShortcutDefaults.swift` (R3 → ⌘M)
- `EditMenu.swift:6`
- `sdd/voice-dictation.md`
- `addenda/001-poc-entrada-ponteiro.md:33`
