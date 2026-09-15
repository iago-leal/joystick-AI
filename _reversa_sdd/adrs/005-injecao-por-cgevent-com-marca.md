# ADR-005: Injeção por CGEvent no tap HID, com marca própria

- **Status:** Aceito
- **Data:** 2026-09-14
- **Tipo:** retroativo (reconstruído pelo Detetive em 2026-09-15)

## Contexto

O app precisa produzir movimento, cliques, arrastes, rolagem e teclas que qualquer aplicativo trate como hardware, e distinguir esses eventos dos físicos na tela de alvos e na gravação de acordes.

## Decisão

Postar todos os eventos por `CGEventSource(.hidSystemState)` em `.cghidEventTap`, com `eventSourceUserData = 0x4A4F5953` ("JOYS"). Acompanhar a posição sintética para não depender da leitura atrasada do sistema. Modificadores com contagem de referência num `KeyboardInjector` único; setas com as máscaras do teclado físico; texto por `unicodeString`.

## Alternativas consideradas

Driver HID virtual (exige extensão de sistema e assinatura paga); AppleScript ou Acessibilidade por elemento (lento, sem arraste nem Mission Control).

## Consequências

🟢 Funciona em qualquer app, inclusive Mission Control e mesas. 🟢 Depende só da Acessibilidade. 🟡 Emoji e caracteres fora do BMP saem como metades de par substituto.

## Evidências

- `EventInjector.swift`
- `KeyboardInjector.swift`
- 001 D-10; 002 D-05
