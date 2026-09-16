# Interface: log de diagnóstico (delta da figura em página web)

> Feature: `004-figura-controle-web`
> Tipo: arquivo, escrita (JSON Lines)
> Contrato base: `_reversa_forward/001-poc-entrada-ponteiro/interfaces/diagnostic-log.md`, com os deltas de `002-paleta-comandos` e `003-editor-atalhos`
> Origem: `requirements.md` RN-09, RN-12, RNF de observabilidade e de privacidade; `roadmap.md` D-10, D-15
> Confidência: 🟢 salvo indicação

## 1. O que muda

Localização, formato, *flush*, ordem e tratamento de erros seguem o contrato base. `logSchema` continua `1`: entra um evento novo, sem mudança em campo existente. Os consumidores do `poc-tools` ignoram eventos desconhecidos.

## 2. Evento novo

| Evento | Nível | Campos | Quando | Requisito |
|--------|-------|--------|--------|-----------|
| `editor.figure_unavailable` | warn | `reason: resource_missing \| load_failed \| process_terminated` | A figura não pôde ser exibida e a aba Atalhos mostra a mensagem de RN-12. Emitido no máximo uma vez por abertura da janela; a recarga bem-sucedida após uma queda do processo WebContent não gera evento. | RN-12, RF-13 |

Fábrica: `LogEventCatalog.editorFigureUnavailable(reason: FigureFailureReason)` em `Sources/JoystickCore/Log/LogEventCatalog.swift`; o `enum` de motivo vive no núcleo para o catálogo continuar fechado, e `FigureBridge` o converte de `FigureFailure`.

## 3. Eventos inalterados

`editor.opened`, `editor.closed`, `editor.conflict`, `editor.identify` e `editor.activation_failed` continuam iguais. A seleção de botão pela figura não gera evento, como o clique nas fichas hoje também não gera.

## 4. Privacidade

- O evento novo não tem texto, rótulo, tecla, acorde, botão nem caminho; só o motivo.
- A página não escreve no log nem em nenhum outro lugar (RN-09); o `console.log` do script, se existir durante o desenvolvimento, não chega ao arquivo e deve ser removido antes do PM-2.
- `LogEventCatalogTests.sampleEvents` recebe `editorFigureUnavailable(reason: .resourceMissing)` para o teste de chaves proibidas cobri-lo.

## 5. Latências deriváveis

- Primeira pintura da figura: não há evento de "figura pronta", por decisão (a página não fala com o app fora do clique). No PM-2, o tempo entre `editor.opened` e a figura visível é medido com cronômetro e vídeo da tela, com `--debug` para o carimbo de `editor.opened`; o limite é 500 ms (RNF de desempenho) 🟡.

## 6. Exemplo

```json
{"ts_ns":812345678901,"wall":"2026-09-16T21:02:10.112-03:00","level":"info","event":"editor.opened","source":"palette"}
{"ts_ns":812395678901,"wall":"2026-09-16T21:02:10.162-03:00","level":"warn","event":"editor.figure_unavailable","reason":"resource_missing"}
```
