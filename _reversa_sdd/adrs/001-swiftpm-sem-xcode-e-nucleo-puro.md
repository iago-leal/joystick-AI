# ADR-001: SwiftPM sem Xcode, com núcleo puro testável

- **Status:** Aceito
- **Data:** 2026-09-14
- **Tipo:** retroativo (reconstruído pelo Detetive em 2026-09-15)

## Contexto

Só as Command Line Tools estão instaladas (Swift 6.3.3), e a lógica de entrada, cinemática, atalhos e configuração precisa ser verificável sem o controle na mão. Os *handlers* do `GameController` e os *callbacks* do CoreGraphics não se ajustam bem ao isolamento estrito do Swift 6.

## Decisão

Pacote SwiftPM com três alvos e um de testes: `JoystickCore` (biblioteca só com `Foundation`, modo Swift 6, máquinas como `struct` de valor), `JoystickAIPoC` (app, modo Swift 5, isolamento por filas explícitas), `poc-tools` (CLI) e `JoystickCoreTests` (Swift Testing). O `.app` é montado e assinado por `scripts/build-app.sh`; os testes rodam por `scripts/test.sh`, que contorna o `Testing.framework` fora do caminho de busca nas CLT.

## Alternativas consideradas

Projeto Xcode (exigiria instalar o Xcode); um único alvo executável (lógica sem teste isolado); tudo em modo Swift 6 (atrito com APIs de *callback*).

## Consequências

🟢 253 testes sem hardware; `swift test` puro compila e sai com 0 sem executar teste algum nas CLT, por isso existe `scripts/test.sh`. 🟡 O app em modo Swift 5 depende de disciplina de filas, verificada por `dispatchPrecondition`, e não pelo compilador.

## Evidências

- `Package.swift`
- 001 D-02, D-03, D-22
- `_reversa_forward/001-poc-entrada-ponteiro/actions.md:170`
