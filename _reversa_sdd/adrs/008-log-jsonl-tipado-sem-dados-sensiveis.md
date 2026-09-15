# ADR-008: Log JSONL por sessão, tipado e sem dados sensíveis

- **Status:** Aceito
- **Data:** 2026-09-14
- **Tipo:** retroativo (reconstruído pelo Detetive em 2026-09-15)

## Contexto

A PoC precisa de evidência numérica (latência, ciclos de conexão, cobertura de botões) sem instrumentação externa, mas o log não pode revelar o que o usuário faz: posições, textos digitados, comandos da paleta ou acordes.

## Decisão

Um arquivo JSON Lines por sessão em `~/Library/Logs/joystick-ai/`, escrito por fila serial com *buffer*, carimbos em `CLOCK_UPTIME_RAW`, nível `debug` só com `--debug` e suspenso acima de 50 MiB. Um catálogo fechado de 50 fábricas tipadas impede, por construção, registrar coordenadas, valores de eixo, textos, rótulos e acordes. `poc-tools` analisa os arquivos.

## Alternativas consideradas

`os.Logger` unificado (difícil de extrair e analisar); log livre por `print` (sem garantia de privacidade).

## Consequências

🟢 Os números do `validation-report.md` saem do `poc-tools`. 🟡 Sem rotação nem limpeza; `session.start` registra os argumentos e `shortcuts.save_failed` inclui o caminho do usuário.

## Evidências

- `DiagnosticLog.swift`
- `LogEventCatalog.swift:33-333`
- 001 D-18, RN-12; 003 RN-14
