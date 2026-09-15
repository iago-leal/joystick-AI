# ADR-006: Temporizador único de 120 Hz, ativo só com analógico fora do repouso

- **Status:** Aceito
- **Data:** 2026-09-14
- **Tipo:** retroativo (reconstruído pelo Detetive em 2026-09-15)

## Contexto

O movimento contínuo do analógico precisa de amostragem regular, mas um temporizador sempre ligado consome CPU em repouso, e o PRD pede consumo desprezível parado. A latência de entrada ao movimento tem meta de 20 ms no p95.

## Decisão

Um único `DispatchSourceTimer` de 1/120 s na fila `input`, ligado quando qualquer analógico sai da zona morta e desligado quando os dois voltam. A saída da zona morta emite um passo imediato (onset). O touchpad é tratado por evento e soma ao tick quando o temporizador está ligado. `dt` real limitado a 50 ms.

## Alternativas consideradas

Um temporizador por analógico (duplicação e dessincronia); CADisplayLink (vinculado à tela, sem uso em app agente).

## Consequências

🟢 CPU em repouso verificada no PM-3. 🟢 A latência é medida do `t_arrival` ao `CGEvent.post` (`poc-tools latency`). 🟢 Processamento com p95 de 0,110 ms numa sessão do PM-2. 🔴 A latência de entrada ao movimento e a CPU em movimento ficaram pendentes no PM-3.

## Evidências

- `MotionLoop.swift:72-106`
- `PointerMotionEngine.swift:56-97`
- 001 D-11, D-12, D-19
