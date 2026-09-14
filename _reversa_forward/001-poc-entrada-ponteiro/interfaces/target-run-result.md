# Interface: tela de alvos (abertura e resultado)

> Feature: `001-poc-entrada-ponteiro`
> Tipo: argumentos de linha de comando (entrada) e arquivo JSON (saída)
> Produtor do resultado: `JoystickAIPoC` em modo `--targets`
> Consumidores: `poc-tools runs`; o avaliador, ao preencher o bloco (b) do relatório
> Origem: `requirements.md` RF-25 (b), RF-27; esclarecimentos 2 e 5; `_reversa_sdd/sdd/pointer-control.md#3. Goals (Objetivos)` (G-01)
> Confidência: 🟢 conteúdo exigido; 🟡 formato e mecanismo

## 1. Abertura ("request")

Sempre por LaunchServices, para que o processo responsável perante o TCC seja o app:

```sh
osascript -e 'quit app "JoystickAIPoC"'   # argumentos só valem numa abertura nova
open ~/Applications/JoystickAIPoC.app --args --targets --env sofa --screen 2
```

| Argumento | Valores | Obrigatório | Padrão | Efeito |
|-----------|---------|-------------|--------|--------|
| `--targets` | flag | não | ausente | Abre a tela de alvos além do ponteiro. |
| `--env` | `mesa`, `sofa` | sim com `--targets` | nenhum | Rótulo do ambiente, sem acento; corresponde aos ambientes "mesa" e "sofá" do requirements. Ausente ou inválido: a tela não abre e o log registra `targets.invalid_args`. |
| `--screen` | inteiro a partir de 1 | não | 1 (tela com a barra de menus) | Índice em `NSScreen.screens`; a lista numerada é registrada em `targets.screens` a cada início da PoC, com ou sem `--targets`, para consulta antes de abrir a tela de alvos. |
| `--seed` | inteiro sem sinal | não | aleatório | Repete uma sequência de posições para comparar rodadas. |
| `--debug` | flag | não | ausente | Eventos `debug` no log (independente de `--targets`). |
| `--scroll-unit` | `pixel`, `line` | não | `pixel` | Unidade da rolagem (D-13), registrada no resultado. |

## 2. Interação

1. Uma janela sem borda cobre a tela escolhida, acima das demais, com fundo neutro e contador "n / 20".
2. Surge um alvo de 16 × 16 pt em posição sorteada, com margem de 40 pt das bordas; o cronômetro começa.
3. O primeiro clique esquerdo **injetado pela PoC** (marca `eventSourceUserData`) encerra a tentativa: acerto se o ponto do `mouseDown` estiver dentro do alvo. Cliques do mouse físico não encerram a tentativa e são contados em `ignoredPhysicalClicks`.
4. `l1Held` registra se L1 estava pressionado no instante do `mouseDown`.
5. Após a vigésima tentativa, a janela mostra o resumo por 3 s, grava o arquivo e fecha; o ponteiro continua ativo.
6. ○ no controle ou Esc no teclado interrompe: grava com `complete: false` e fecha.

## 3. Resultado ("response")

Arquivo `~/Library/Application Support/joystick-ai/target-runs/<AAAAMMDD-HHMMSS>-<env>.json`, diretório criado se ausente:

```json
{
  "schemaVersion": 1,
  "startedAt": "2026-09-20T21:14:03-03:00",
  "environment": "sofa",
  "complete": true,
  "seed": 184467,
  "screen": { "name": "LG TV", "widthPx": 3840, "heightPx": 2160, "widthPt": 1920, "heightPt": 1080, "backingScale": 2.0 },
  "targetSizePt": 16,
  "settings": { "touchpadSensitivity": 1.0, "stickMaxSpeed": 1500, "stickExponent": 2.0, "deadzone": 0.12, "scrollSpeed": 100, "invertScrollY": false, "precisionFactor": 0.3, "doubleClickIntervalMs": 400 },
  "scrollUnit": "pixel",
  "attempts": [
    { "index": 1, "targetRectPt": { "x": 812, "y": 403, "w": 16, "h": 16 }, "hit": true, "timeToClickMs": 2140, "l1Held": true }
  ],
  "summary": { "hits": 18, "total": 20, "hitRate": 0.9, "meanTimeMs": 2380, "hitRateWithL1": 0.93, "hitRateWithoutL1": 0.8 },
  "ignoredPhysicalClicks": 0
}
```

- `targetRectPt` descreve o alvo, não o cursor; o ponto do clique não é gravado (RN-12).
- `hitRateWithL1` e `hitRateWithoutL1` são omitidos quando não há tentativa no grupo.
- Numa sequência incompleta, `summary` reflete apenas as tentativas feitas, e `poc-tools runs` a exclui do cálculo (RF-27).

## 4. Erros

| Situação | Comportamento |
|----------|---------------|
| `--env` ausente ou inválido | A tela não abre; `targets.invalid_args` no log; o ponteiro segue ativo. |
| `--screen` fora da faixa | Usa a tela 1 e registra `targets.screen_fallback`. |
| Tela escolhida desconectada durante a sequência | Interrompe como incompleta, com `abortReason: "screen_removed"`. |
| Acessibilidade revogada durante a sequência | Interrompe como incompleta, com `abortReason: "injection_suspended"`. |
| Falha ao gravar o arquivo | Registra `targets.write_failed` com a mensagem e inclui o JSON completo no log, para recuperação manual. |

## 5. Idempotência

- Cada sequência gera um arquivo novo; nada é sobrescrito. Colisão de nome no mesmo segundo recebe sufixo `-2`.
- A mesma `--seed` com a mesma tela reproduz as mesmas posições.

## 6. Timeouts

- Sem limite por tentativa, pois o tempo até o clique é a própria medida; tentativa acima de 60 s é registrada normalmente e sinalizada por `poc-tools runs` como discrepante.
- Resumo exibido por 3 s antes de fechar.

## 7. Consumo por `poc-tools runs`

`poc-tools runs [--env mesa|sofa]` lê o diretório e imprime uma tabela Markdown, uma linha por sequência completa, com data, ambiente, resolução, escala, parâmetros que diferem do padrão, taxa de acerto, taxa com e sem L1 e tempo médio, pronta para colar no bloco (b) do `validation-report.md`.
