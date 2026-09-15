# Tela de alvos e análise (targets-analysis)

> Unit do módulo `targets-analysis` · Gerado pelo Redator em 2026-09-15 · Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA

## Visão Geral

Instrumentos de validação da PoC. A tela de alvos mede a precisão do ponteiro em sequências reproduzíveis de 20 alvos de 16 pt, em mesa ou sofá, e grava cada sequência em JSON. A CLI `poc-tools` lê os logs de diagnóstico e esses resultados para produzir as tabelas dos blocos de validação: cobertura de botões, sequências de alvos, latências e ciclos de conexão. 🟢

## Responsabilidades

- Abrir a tela de alvos por argumentos de abertura, na tela escolhida. 🟢
- Gerar posições determinísticas a partir de uma semente. 🟢
- Contar só cliques injetados pelo app; ignorar e contar cliques físicos. 🟢
- Medir acerto, tempo até o clique e uso de L1 por tentativa, sem guardar o ponto do clique. 🟢
- Interromper por ○, Esc, remoção da tela ou suspensão da injeção. 🟢
- Gravar o resultado sem sobrescrever, com recuperação pelo log em falha. 🟢
- Analisar logs e resultados pela CLI, com códigos de saída padronizados. 🟢

## Regras de Negócio

### Abertura

- RN-TA-01: A tela abre só com `--targets` e `--env mesa|sofa` válido; `--targets` sem `--env` registra `targets.invalid_args` ("--targets exige --env mesa ou --env sofa") e não abre. 🟢
- RN-TA-02: Com `--targets`, cada erro de argumento que não é da paleta nem de `--screen` vira `targets.invalid_args { message }` (`--env`, `--seed`, `--scroll-unit`, valor ausente). 🟢
- RN-TA-03: `--screen N` (a partir de 1) escolhe a tela na ordem de `NSScreen.screens`; valor inválido ou fora da faixa usa a tela 1 e registra `targets.screen_fallback`; sem telas, `targets.invalid_args { "nenhuma tela ativa" }`. 🟢
- RN-TA-04: `--seed` (inteiro sem sinal) fixa a semente; sem ela, sorteia-se de 0 a 2³² − 1. 🟢
- RN-TA-05: `targets.screens` lista as telas numeradas a cada abertura do app, com ou sem `--targets`. 🟢
- RN-TA-06: Durante a sessão a paleta fica bloqueada; ao terminar, é liberada. 🟢

### Sessão

- RN-TA-07: 20 alvos de 16 × 16 pt; coordenadas inteiras em pt, origem no canto superior esquerdo da tela, `x ∈ [40, largura − 56]` e `y ∈ [40, altura − 56]` (mínimo 40 em telas pequenas), sorteadas por SplitMix64 com a semente. 🟢
- RN-TA-08: Janela sem borda cobrindo a tela, nível da barra de status, cinza 55%, alvo preto com contorno branco de 1 pt, contador "n / 20" no topo. 🟢
- RN-TA-09: Só `leftMouseDown` na janela com a marca `0x4A4F5953` conta como tentativa; clique esquerdo físico é consumido e somado a `ignoredPhysicalClicks`. Outros eventos seguem normalmente. 🟢
- RN-TA-10: Tentativa: `index` (1 a 20), retângulo do alvo, `hit` (ponto dentro do retângulo), `timeToClickMs` (inteiro truncado desde a exibição do alvo) e `l1Held` (L1 pressionado no controle ativo no instante). O ponto do clique não é guardado. 🟢
- RN-TA-11: Interrupções: ○ no controle (pressionar não sintético) e Esc no teclado → `user`; tela escolhida removida → `screen_removed`; injeção suspensa → `injection_suspended`. Só a primeira interrupção vale. 🟢
- RN-TA-12: Sequência completa mostra por 3 s "H de 20 acertos (P%), tempo médio T ms" e então grava e fecha; sequência interrompida grava e fecha na hora. 🟢
- RN-TA-13: `targets.started { env, seed }` ao iniciar. 🟢

### Resultado

- RN-TA-14: `TargetRun` (`schemaVersion 1`): `startedAt` ISO 8601 local com fuso, `environment`, `complete`, `abortReason` (nulo quando completa), `seed`, `screen { name, widthPx, heightPx, widthPt, heightPt, backingScale }`, `targetSizePt 16`, `settings` (ponteiro vigente), `scrollUnit`, `attempts`, `summary`, `ignoredPhysicalClicks`. 🟢
- RN-TA-15: `summary`: `hits`, `total`, `hitRate` (0 sem tentativas), `meanTimeMs` (média arredondada, 0 sem tentativas), `hitRateWithL1` e `hitRateWithoutL1` (nulos quando o grupo é vazio). 🟢
- RN-TA-16: Arquivo `~/Library/Application Support/joystick-ai/target-runs/AAAAMMDD-HHmmss-<env>.json`, com sufixo `-2`, `-3`… em colisão; JSON indentado, sem escape de barras; nunca sobrescreve. 🟢
- RN-TA-17: Sucesso registra `targets.finished { env, seed, complete, abortReason?, file }`; falha registra `targets.write_failed { message, payload }` com o JSON compacto para recuperação manual. 🟢

### `poc-tools`

- RN-TA-18: Subcomandos `buttons <log>`, `runs [--env mesa|sofa] [--dir <dir>]`, `latency <log>`, `cycles <log>` e `help [subcomando]`; `-h`/`--help` após um subcomando mostra a ajuda dele. 🟢
- RN-TA-19: Códigos de saída: 0 sucesso; 64 uso incorreto (subcomando desconhecido, argumentos a mais ou a menos, `--env` inválido); 66 arquivo ou diretório inexistente ou ilegível. 🟢
- RN-TA-20: Leitura de log: `~` expandido; linhas em branco ignoradas; linha que não é objeto JSON conta como malformada e gera aviso em `stderr`. 🟢
- RN-TA-21: `buttons`: tabela dos 18 botões com ✓/✗ para `down` e `up` observados em `input.button` não sintéticos e "Total: N de 18."; exige log com `--debug`. 🟢
- RN-TA-22: `cycles`: ciclos completos (conexão seguida de desconexão do mesmo `id`), conexões sem desconexão e sessões no arquivo, com "(reinício detectado)" quando há mais de uma. Meta: 100 ciclos em 1 sessão. 🟢
- RN-TA-23: `latency`: processamento = `t_delivered − t_arrival` de `input.button` e `input.touch` não sintéticos (meta p95 ≤ 5 ms); entrada ao movimento = `t_posted − t_arrival` de `pointer.posted` com `source` `touch` ou `stick_onset` (meta p95 ≤ 20 ms); amostras negativas descartadas; percentis pela posição mais próxima (`posição = max(1, ⌈p·n⌉)`), em ms com 3 casas; "sem amostras" quando vazio. A medida termina no `CGEvent.post`, não no pixel. 🟢
- RN-TA-24: `runs`: lê os `.json` do diretório em ordem de nome, ignora ilegíveis com aviso, filtra sequências completas (e ambiente, se pedido), ordena por `startedAt` e imprime a tabela: Data, Ambiente, Resolução (px), Escala, Parâmetros diferentes do padrão (ou "padrão"; inclui `scrollUnit` se não for `pixel`), Taxa de acerto, Com L1, Sem L1 (`-` quando nulo), Tempo médio, Discrepantes (tentativas acima de 60 s). Sem sequências: "_(nenhuma sequência completa encontrada)_". 🟢
- RN-TA-25: Medições pendentes do PM-3 da 001: sequências da tela de alvos (diretório `target-runs` vazio), latência de entrada ao movimento, CPU em movimento e 100 ciclos. Continuam planejadas. 🟢 (respondida em 2026-09-15, `questions.md` Pergunta 5)

## Requisitos Funcionais

| ID | Requisito | Prioridade | Critério de Aceite |
|----|-----------|-----------|-------------------|
| RF-TA-01 | Abrir a tela de alvos por argumentos | Must | `open JoystickAIPoC.app --args --targets --env sofa --screen 2 --seed 7` abre na tela 2 |
| RF-TA-02 | Posições reproduzíveis pela semente | Must | Mesma semente e tela produzem os mesmos 20 retângulos |
| RF-TA-03 | Contar só cliques do controle | Must | Clique do trackpad não avança o alvo e soma `ignoredPhysicalClicks` |
| RF-TA-04 | Medir acerto, tempo e L1 | Must | Resultado com 20 tentativas e resumo por L1 |
| RF-TA-05 | Interromper com segurança | Must | ○, Esc, remover a tela ou revogar a Acessibilidade gravam sequência incompleta com o motivo |
| RF-TA-06 | Gravar sem sobrescrever | Must | Duas sequências no mesmo segundo geram dois arquivos |
| RF-TA-07 | Relatório de sequências | Must | `poc-tools runs --env sofa` imprime a tabela do bloco (b) |
| RF-TA-08 | Cobertura de botões | Must | `poc-tools buttons <log>` mostra 18 de 18 após pressionar todos |
| RF-TA-09 | Latências | Must | `poc-tools latency <log>` informa p50, p95, máximo e aprovação |
| RF-TA-10 | Ciclos de conexão | Should | `poc-tools cycles <log>` conta 100 ciclos numa sessão |

## Requisitos Não Funcionais

| Tipo | Requisito inferido | Evidência no código | Confiança |
|------|--------------------|---------------------|-----------|
| Privacidade | Ponto do clique nunca registrado | `TargetSession.swift:89` | 🟢 |
| Reprodutibilidade | Gerador próprio com semente | `TargetRun.swift:151-166` | 🟢 |
| Robustez | Resultado recuperável pelo log em falha de gravação | `TargetRunWriter.swift:19,42-45` | 🟢 |
| Usabilidade | Saída em Markdown pronta para colar nos relatórios | `RunsReport.swift`, comandos | 🟢 |
| Portabilidade | CLI só com Foundation e o núcleo | `Sources/poc-tools` | 🟢 |

## Critérios de Aceitação

```gherkin
Dado o app aberto com --targets --env mesa --seed 42
Quando a tela de alvos começa
Então targets.started registra env mesa e seed 42
E o primeiro alvo tem a posição definida por TargetLayout.positions(seed: 42, …)

Dado um alvo em (100, 200, 16, 16) exibido há 1.234,9 ms
Quando R1 clica em (108, 207) com L1 segurado
Então a tentativa registra hit true, timeToClickMs 1234 e l1Held true

Dado a tela de alvos na tentativa 5
Quando ○ é pressionado no controle
Então o arquivo é gravado com complete false, abortReason user e 4 tentativas

Dado --targets sem --env
Quando o app abre
Então targets.invalid_args registra "--targets exige --env mesa ou --env sofa" e a tela não abre

Dado amostras de 1, 2, 3, …, 20 ms
Quando LatencyStats.summarize é aplicado
Então p50 é 10 ms, p95 é 19 ms e máximo é 20 ms

Dado poc-tools latency sem argumento
Quando é executado
Então imprime o uso em stderr e sai com 64

Dado poc-tools runs --dir /inexistente
Quando é executado
Então sai com 66
```

## Prioridade (MoSCoW)

| Requisito | MoSCoW | Justificativa |
|-----------|--------|---------------|
| Tela de alvos com semente e marca | Must | Critério de precisão da 001 |
| Gravação do resultado | Must | Evidência do bloco (b) |
| `buttons`, `latency`, `runs` | Must | Blocos (a), (d) e (b) |
| `cycles` | Should | RNF de robustez |
| Medições do PM-3 | Must (pendente, planejada) | 🟢 L-03 respondida |

## Rastreabilidade de Código

| Arquivo | Função / Classe | Cobertura |
|---------|-----------------|-----------|
| `Sources/JoystickCore/Targets/TargetRun.swift` | `TargetEnvironment`, `AbortReason`, `RectPt`, `ScreenDescriptor`, `TargetAttempt`, `TargetSummary`, `TargetRun`, `SeededGenerator`, `TargetLayout` | 🟢 |
| `Sources/JoystickCore/Analysis/LatencyStats.swift` | `LatencySummary`, `LatencyStats` | 🟢 |
| `Sources/JoystickCore/Analysis/LogAnalysis.swift` | `LogReadResult`, `ButtonObservation`, `ButtonCoverage`, `CycleSummary`, `LogAnalysis` | 🟢 |
| `Sources/JoystickCore/Analysis/RunsReport.swift` | `RunsReport` | 🟢 |
| `Sources/JoystickAIPoC/Targets/TargetSession.swift` | `TargetSession` | 🟢 |
| `Sources/JoystickAIPoC/Targets/TargetAbortMonitor.swift` | `TargetAbortMonitor` | 🟢 |
| `Sources/JoystickAIPoC/Targets/TargetRunWriter.swift` | `TargetRunWriter` | 🟢 |
| `Sources/JoystickAIPoC/Targets/TargetWindow.swift` | `TargetWindow`, `TargetView` | 🟢 |
| `Sources/JoystickAIPoC/Display/ScreenCatalog.swift` | `ScreenCatalog` (compartilhado com `ponteiro`) | 🟢 |
| `Sources/poc-tools/*.swift` | `main`, `ButtonsCommand`, `CyclesCommand`, `LatencyCommand`, `RunsCommand`, `ToolInput` | 🟢 |
