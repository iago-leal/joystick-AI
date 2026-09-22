---
schema_version: 1
id: BUG-20260922-33HN
display_number: 1
title: Botões de face do GameSir G8+ em modo DualShock 4 geram acionamentos repetidos numa única pressão
status: resolved
phase: delivering
severity: high
priority: P1
created: 2026-09-22
updated: 2026-09-22

origin:
  type: manual-report
  external_ref: null

area: app
module: controller-input
feature: 012-controle-dualshock-4
labels: [spec-gap, hardware-dependent, teclado-injetado]

visibility: normal
security_suspected: false

reproduction:
  classification: intermittent
  rate: "20/32 pressões de △ com intervalo < 120 ms no log de 2026-09-22; 4/4 botões de face com 3 a 6 bordas numa pressão única na sonda P-01"
  suspected_triggers:
    - "Variação de pressão do dedo com o botão segurado (relato do usuário)"
    - "Botões de face do GameSir G8+ em modo PlayStation (membrana), por Bluetooth"
    - "Não observado no DualSense nem no Ipega (usuário e logs de 2026-09-20/21)"

blocking: []

relationships: []

traceability:
  specs:
    - "_reversa_sdd/entrada-do-controle/requirements.md#regras-de-negócio"
    - "_reversa_sdd/atalhos/requirements.md#regras-de-negócio"
    - "_reversa_sdd/domain.md#31-controle-e-entrada-001"
    - "_reversa_sdd/addenda/007-controle-ipega.md"
  affected_code:
    - "Sources/JoystickAIPoC/Controller/ButtonReader.swift"
    - "Sources/JoystickCore/Input/ActiveControllerRegistry.swift"
    - "Sources/JoystickAIPoC/Pointer/ShortcutActions.swift"
  root_cause:
    state: confirmed
    hypothesis: "As bordas repetidas nascem no controle: o GameSir G8+ em modo DualShock 4 alterna o bit do botão no relatório HID 0x11 a cada 15 a 60 ms enquanto um botão de membrana é segurado com pressão variável; o app entrega cada borda sem filtro temporal e as ações que agem no pressionar disparam uma vez por borda"
    causal_path:
      - "controle: bit 7 do byte 7 do relatório 0x11 (△) alterna 0x08→0x88→0x08 a cada 30 ms (sonda P-02, sem o app)"
      - "GameController: pressedChangedHandler de buttonY acompanha cada alternância (sonda P-01)"
      - "ButtonReader.deliver: cada borda vira press/release no ActiveControllerRegistry, que deduplica só estado repetido, não bordas reais"
      - "InputSink → ShortcutActions.handle(.buttonDown): mapper.press dispara a ação a cada down (RN-AT-08)"
      - "KeyboardInjector digita 'CONTINUAR' três vezes em 120 ms (log: input.button e shortcut.triggered em sincronia)"
    evidence:
      - { ref: "evidence/sonda-012-p01-p02-oscilacao-triangulo.log", observation: "bit HID e handler do framework oscilando juntos, sem o app rodando" }
      - { ref: "evidence/log-app-2026-09-22-rajadas-botoes-de-face.jsonl", observation: "△ down/up a 15 e 30 ms com shortcut.triggered a cada down" }
      - { ref: "evidence/reproduction.md", observation: "histogramas: rajadas de 15 a 100 ms só no dualShock4 e só em botões de membrana; DualSense e Ipega sem o padrão" }
    code_refs:
      - { file: "Sources/JoystickAIPoC/Controller/ButtonReader.swift", symbol: "ButtonReader.attach / deliver", commit: "7dd87d2 + árvore da 012" }
      - { file: "Sources/JoystickCore/Input/ActiveControllerRegistry.swift", symbol: "press / release", commit: "7dd87d2" }
      - { file: "Sources/JoystickAIPoC/Pointer/ShortcutActions.swift", symbol: "handle(.buttonDown)", commit: "7dd87d2" }
  reproduction_tests:
    - "Tests/JoystickCoreTests/ButtonDebouncerTests.swift#rajadaGravadaDoTrianguloViraUmaPressao"
    - "Tests/JoystickCoreTests/ButtonDebouncerTests.swift#rajadaDoQuadradoComCadenciaDe60msViraUmaPressao"
    - "Tests/JoystickCoreTests/ButtonDebouncerTests.swift#semFiltroORegistroEntregaTresPressoes"
  regression_tests:
    - "Tests/JoystickCoreTests/ButtonDebouncerTests.swift#janelaDe120ms"
    - "Tests/JoystickCoreTests/ButtonDebouncerTests.swift#dualSenseEIpegaNaoSaoFiltrados"
    - "Tests/JoystickCoreTests/ButtonDebouncerTests.swift#soOsBotoesDeMembranaDoDualShock4SaoFiltrados"
    - "Tests/JoystickCoreTests/ButtonDebouncerTests.swift#toquesHumanosDistintosSaoEntreguesUmAUm"
    - "Tests/JoystickCoreTests/ButtonDebouncerTests.swift#flushAntesDaJanelaNaoEntregaEDepoisEntregaUmaVez"
    - "Tests/JoystickCoreTests/ButtonDebouncerTests.swift#downDentroDaJanelaCancelaOUpPendente"
    - "Tests/JoystickCoreTests/ButtonDebouncerTests.swift#pressSemUpPendenteEntregaEReleaseRepetidoNaoReagenda"
    - "Tests/JoystickCoreTests/ButtonDebouncerTests.swift#cancelAllDevolvePendentesEmOrdemEImpedeFlushPosterior"

spec_verdict: spec-gap

change_set:
  - id: CHG-001
    kind: test
    artifact: Tests/JoystickCoreTests/ButtonDebouncerTests.swift
    purpose: "Teste de reprodução (rajada gravada do △ e do □) e testes de regressão do filtro"
    diff: fix/CHG-001.diff
  - id: CHG-002
    kind: code
    artifact: Sources/JoystickCore/Input/ButtonDebouncer.swift
    purpose: "Filtro de rajadas no núcleo: down imediato, up retido por 120 ms e cancelado por novo down"
    diff: fix/CHG-002.diff
  - id: CHG-003
    kind: code
    artifact: Sources/JoystickAIPoC/Controller/InputSink.swift
    purpose: "Estado do filtro por controle no InputContext, só na fila input"
    diff: fix/CHG-003.diff
  - id: CHG-004
    kind: code
    artifact: Sources/JoystickAIPoC/Controller/ButtonReader.swift
    purpose: "Cria o filtro para dualShock4 e passa os seis botões de membrana por ele; up retido entregue por flush"
    diff: fix/CHG-004.diff
  - id: CHG-005
    kind: code
    artifact: Sources/JoystickAIPoC/Controller/ControllerReader.swift
    purpose: "Descarta o filtro na desconexão; RN-04 solta o que ainda estava pressionado"
    diff: fix/CHG-005.diff
  - id: CHG-006
    kind: specification
    artifact: _reversa_sdd/addenda/bug-BUG-20260922-33HN-v001.md
    purpose: "Adendo aditivo (spec-gap): RN-EC-18 a RN-EC-21 e RF-EC-11, filtro de rajadas do DualShock 4"
    diff: fix/CHG-006.diff

change_risk:
  classification: baixa
  reasons:
    - "Raio de alcance: um modelo (dualShock4) e seis botões; DualSense e Ipega intocados"
    - "Sem contrato externo, sem dados persistidos, sem concorrência nova (tudo na fila input)"
    - "Reversível: remover o filtro devolve o comportamento anterior"
    - "Custo aceito: up dos seis botões chega 120 ms depois do físico (acordes e o modificador Options soltam mais tarde)"

closure:
  policy: local-software
  satisfied: true
resolution_kind: fixed
---

# Botões de face do GameSir G8+ em modo DualShock 4 geram acionamentos repetidos numa única pressão

## Summary

Com o GameSir G8+ em modo PlayStation (classificado `dualShock4`, feature 012), uma única pressão em ✕, □, △ ou ○ chega ao app como uma rajada de bordas pressiona/solta com 15 a 30 ms de duração e 30 a 60 ms de intervalo. Cada borda de pressionar dispara a ação configurada, e o usuário vê "mais de um clique": três "CONTINUAR" digitados em 120 ms pelo △, Return repetido pelo ✕. A sonda da feature 012, rodada sem o app, mostra o próprio bit do relatório HID oscilando, o que aponta a origem para o controle; o app repassa cada borda sem filtro temporal, porque nenhuma regra da extração prevê um.

## Expected Behavior

- RN-EC-16 (`entrada-do-controle`): `buttonA` ✕, `buttonX` □, `buttonY` △ e `buttonB` ○ são entregues como `cross`, `square`, `triangle` e `circle`.
- RN-EC-06: um botão só gera evento quando seu estado muda no conjunto de pressionados do ativo. A regra deduplica leituras redundantes do mesmo estado, mas não trata bordas reais em sequência rápida.
- RN-AT-08 (`atalhos`): `text` e `openPalette` agem só no pressionar; `chord` pressiona no pressionar e solta no soltar. RN-AT-09: só repete quem tem `repeat: true`, após 400 ms.
- Comportamento esperado pelo usuário, não escrito em nenhuma spec: uma pressão física de um botão de face equivale a exatamente um pressionar e um soltar, independentemente da variação de pressão do dedo. **`spec-gap`**: a extração não define filtro temporal (debounce) para bordas de botão; a única normalização temporal existente é o limiar sem histerese de L2/R2 (RN-EC-09). A pergunta "é bug do app ou comportamento nunca especificado do controle" fica aberta para o fix.

## Actual Behavior

- Log do app de 2026-09-22 (`evidence/log-app-2026-09-22-rajadas-botoes-de-face.jsonl`): às 14:34:54, △ produz `input.button down` (.677), `up` (.692), `down` (.722), `up` (.752), `down` (.782), `up` (.797); cada `down` é seguido de `shortcut.triggered { layer: base, type: text }`, ou seja, "CONTINUAR" digitado três vezes.
- Mesmo padrão em ✕ (Return), □ (Delete) e ○ (Escape), este último não citado pelo usuário. Ver `evidence/analise-intervalos-botoes-de-face.md`: no log do DualShock 4, △ tem 20 de 32 intervalos abaixo de 120 ms, □ 210 de 240 (cadência de 60 ms por vários segundos); nos logs do Ipega de 2026-09-20 e 2026-09-21 o padrão não existe.
- Sonda da feature 012 às 14:22:56 (`evidence/sonda-012-p01-p02-oscilacao-triangulo.log`), sem o app: numa pressão única de △, o bit 7 do byte 7 do relatório `0x11` alterna 0x08→0x88→0x08 três vezes a cada 30 ms, e `GCControllerButtonInput` relata PRESSIONADO/solto em sincronia. Na P-01, com cada botão pressionado uma vez, A, B, X, Y, Options e Menu registraram de 3 a 6 pressões; L1, R1, L3 e R3 registraram exatamente uma.

## Steps to Reproduce

1. GameSir G8+ em modo PlayStation, pareado por Bluetooth; app instalado com a feature 012 (build de 2026-09-22) aberto com `--debug`; configuração vigente com △ = texto "CONTINUAR" na camada base.
2. Com um editor de texto em foco, segure △ e varie a pressão do dedo ("aperte um pouquinho a mais"), depois solte.
3. Observar o texto digitado mais de uma vez e, no log (`~/Library/Logs/joystick-ai/poc-*.jsonl`), pares `input.button` down/up de △ com intervalos de 15 a 60 ms, cada `down` com o seu `shortcut.triggered`.
4. Repetir com ✕ (Return), □ (Delete) e ○ (Escape). Repetir com o DualSense e com o Ipega: não reproduz (relato do usuário e logs anteriores).
5. Reprodução fora do app: `swift _reversa_forward/012-controle-dualshock-4/sondas/probe-ds4.swift`, pressionar △ uma vez e observar o byte 7 alternar.

## Evidence

- `evidence/log-app-2026-09-22-rajadas-botoes-de-face.jsonl`: extrato do log do app (janela 14:34:40 a 14:35:00, botões de face e atalhos disparados) e o `controller.connected` da sessão
- `evidence/analise-intervalos-botoes-de-face.md`: intervalos entre pressões nos três logs mais recentes (Ipega, Ipega, DualShock 4)
- `evidence/sonda-012-p01-p02-oscilacao-triangulo.log`: extrato da sonda da feature 012 com o relatório HID bruto oscilando e a contagem de bordas por botão na P-01
- Relato bruto: `../../intake/relato-20260922-1441.md`

## Suspected Area

- `Sources/JoystickAIPoC/Controller/ButtonReader.swift`: `attach` liga `pressedChangedHandler` de cada botão digital e entrega toda mudança a `deliver`, sem janela temporal. Os gatilhos analógicos passam por `TriggerTracker` (`Sources/JoystickCore/Input/Normalization.swift`), único filtro existente, e sem histerese.
- `Sources/JoystickCore/Input/ActiveControllerRegistry.swift`: `press`/`release` deduplicam só por estado (RN-EC-06); uma sequência real down/up/down passa inteira.
- `Sources/JoystickAIPoC/Pointer/ShortcutActions.swift`: age a cada `buttonDown` (RN-AT-08), o que transforma cada borda em ação de teclado.
- Origem provável fora do app (hipótese apoiada pela sonda): firmware ou contato dos botões de membrana do GameSir G8+ em modo DualShock 4. O DualSense e o Ipega (mesmo GameSir em outro modo) não apresentam o padrão, o que sugere diferença de firmware entre os modos do mesmo aparelho.

## Acceptance Criteria

1. Com o padrão de bordas registrado na evidência (down/up de 15 a 30 ms, intervalos de 30 a 60 ms), uma pressão física de ✕, □, △ ou ○ produz exatamente um `buttonDown` e um `buttonUp` no `InputSink`, e a ação configurada dispara uma vez.
2. DualSense e Ipega mantêm o comportamento atual: pressões rápidas deliberadas (por exemplo, □ com `repeat: true` a intervalos de 90 a 200 ms nos logs do Ipega) continuam entregues uma a uma.
3. Nenhum botão fica preso: a soltura sintética na desconexão (RN-EC-07) e a suspensão da injeção (RI-04) seguem válidas com o filtro.
4. A latência de entrada ao movimento e de processamento continua dentro do RNF (p95 ≤ 20 ms e ≤ 5 ms, RI-29), ou o custo adicional fica documentado e aceito no veredito de spec.
5. Testes de reprodução no núcleo cobrem a rajada observada; testes de regressão cobrem pressões humanas rápidas e a fila com três modelos.
6. Veredito de spec registrado (`spec-gap` resolvido por adendo, ou declarado comportamento aceito do controle).

## Traceability

| Tipo | Localizador | Observação |
|------|-------------|------------|
| Spec | `_reversa_sdd/entrada-do-controle/requirements.md#regras-de-negócio` | RN-EC-06 (evento só na mudança de estado), RN-EC-09 (limiar sem histerese de L2/R2), RN-EC-16 (mapeamento) |
| Spec | `_reversa_sdd/atalhos/requirements.md#regras-de-negócio` | RN-AT-06 (pressionar já pressionado não faz nada), RN-AT-08 (text age no pressionar), RN-AT-09 (repetição só com `repeat`) |
| Spec | `_reversa_sdd/domain.md#31-controle-e-entrada-001` | 001 RN-03 e RN-04; ausência de regra de debounce |
| Adendo vigente | `_reversa_sdd/addenda/007-controle-ipega.md` | Segundo modelo aceito; o terceiro (DualShock 4) ainda não tem adendo, a feature 012 está em coding |
| Código afetado | `Sources/JoystickAIPoC/Controller/ButtonReader.swift` | Onde o bug aparece |
| Código afetado | `Sources/JoystickCore/Input/ActiveControllerRegistry.swift` | Dedupe por estado |
| Código afetado | `Sources/JoystickAIPoC/Pointer/ShortcutActions.swift` | Ação por borda |
| Testes existentes | `Tests/JoystickCoreTests/ActiveControllerRegistryTests.swift`, `Tests/JoystickCoreTests/NormalizationTests.swift`, `Tests/JoystickCoreTests/ShortcutMapperTests.swift` | Relacionados; nenhum cobre rajadas |
| Feature | `_reversa_forward/012-controle-dualshock-4/` | Coding em andamento; sonda em `sondas/`; PM-1 pendente |

## Resolution

**Causa raiz (confirmed).** O GameSir G8+ em modo DualShock 4 alterna o bit dos botões de membrana no relatório HID `0x11` a cada 15 a 100 ms enquanto o botão é segurado com pressão variável (sonda P-02, sem o app). O app repassava cada borda sem filtro temporal e as ações que agem no pressionar disparavam uma vez por borda. Caminho causal e evidências no bloco `root_cause`.

**Mitigação.** Dispensada pelo usuário (investigação direta).

**Reprodução.** Cápsula em `evidence/reproduction.md`: reprodução com o app (log de 14:32) e sem o app (sonda de 14:22), classificação `intermittent`, histogramas por botão e modelo; contraprova nos logs do Ipega.

**Estratégia.** Correção direta, aprovada em `fix/plan.html`: filtro de rajadas no núcleo, só para `dualShock4` e só para ✕, ○, □, △, Options e Create; `down` imediato, `up` retido por 120 ms e cancelado por novo `down`.

**Veredito de spec (decisão do usuário, 2026-09-22): `spec-gap`.** A extração não previa filtro temporal para bordas de botão. Adendo aditivo `_reversa_sdd/addenda/bug-BUG-20260922-33HN-v001.md` (RN-EC-18 a RN-EC-21, RF-EC-11). Specs originais intocadas.

**resolution_kind: `fixed`.**

| CHG | Tipo | Artefato | Propósito | Diff |
|-----|------|----------|-----------|------|
| CHG-001 | test | `Tests/JoystickCoreTests/ButtonDebouncerTests.swift` | 3 testes de reprodução, 8 de regressão | `fix/CHG-001.diff` |
| CHG-002 | code | `Sources/JoystickCore/Input/ButtonDebouncer.swift` | Filtro no núcleo (`press`, `release`, `flush`, `cancelAll`, `applies`) | `fix/CHG-002.diff` |
| CHG-003 | code | `Sources/JoystickAIPoC/Controller/InputSink.swift` | `InputContext.debouncers` | `fix/CHG-003.diff` |
| CHG-004 | code | `Sources/JoystickAIPoC/Controller/ButtonReader.swift` | Filtro em `attach`; `up` retido entregue por `flush` na fila `input` | `fix/CHG-004.diff` |
| CHG-005 | code | `Sources/JoystickAIPoC/Controller/ControllerReader.swift` | Descarte do filtro na desconexão | `fix/CHG-005.diff` |
| CHG-006 | specification | `_reversa_sdd/addenda/bug-BUG-20260922-33HN-v001.md` | Regra nova especificada | `fix/CHG-006.diff` |

Diffs de código e de spec ficam juntos em `fix/`. Emenda ao CHG-001 depois do Gate 2: quatro asserções que chamavam método mutante como expressão de topo do `#expect` (recusado pelo Swift Testing) passaram a guardar o resultado numa constante antes de afirmar; a intenção dos testes não mudou e o diff em `fix/CHG-001.diff` é o final.

**Prova vermelho → verde.**
- Gate 1 (`fix/gate1-red.log`): `error: cannot find 'ButtonDebouncer' in scope` (9 ocorrências), `Build failed`, exit 1.
- Gate 2 (`fix/gate2-green.log`): `Test run with 476 tests in 47 suites passed`, exit 0; base anterior 465 em 46. `swift build -c release` sem avisos no código (só avisos do vinculador sobre caminhos de busca das Command Line Tools, pré-existentes).

**Testes.** Reprodução: `rajadaGravadaDoTrianguloViraUmaPressao`, `rajadaDoQuadradoComCadenciaDe60msViraUmaPressao`, `semFiltroORegistroEntregaTresPressoes` (caracterização). Regressão: `janelaDe120ms`, `dualSenseEIpegaNaoSaoFiltrados`, `soOsBotoesDeMembranaDoDualShock4SaoFiltrados`, `toquesHumanosDistintosSaoEntreguesUmAUm`, `flushAntesDaJanelaNaoEntregaEDepoisEntregaUmaVez`, `downDentroDaJanelaCancelaOUpPendente`, `pressSemUpPendenteEntregaEReleaseRepetidoNaoReagenda`, `cancelAllDevolvePendentesEmOrdemEImpedeFlushPosterior`.

**Dados.** Sem impacto: nenhum estado persistido.

**Closure policy `local-software`:** regressão verde + veredito registrado → satisfeita em 2026-09-22. Entrega local: app recompilado e instalado em `~/Applications/JoystickAIPoC.app` com a mesma identidade de assinatura (resultado em `fix/install.log`). A confirmação no hardware (RF-EC-11: uma pressão do △ digita um único "CONTINUAR") fica como observação do PM-1 da feature 012; se falhar, registra-se bug novo com `regression-of` apontando para este.

## Agent Notes

- Não corrigir aqui. Registro pelo fluxo completo do `/reversa-debugger`; `express` não se aplica.
- Hipótese de causa raiz (estado `hypothesized`, a confirmar no fix): as bordas repetidas nascem no controle (bit HID oscila na sonda, sem o app). O app é fiel à spec; o defeito percebido é a ausência de um filtro temporal que a spec nunca previu. Hipótese alternativa a descartar: limiar do GameController sobre valor analógico; improvável, porque o bit digital do relatório bruto já oscila.
- Decisões que cabem ao fix, com gate humano: (a) se o filtro é regra do domínio (adendo de spec, `spec-gap` fechado) ou comportamento aceito do controle; (b) onde mora o filtro, com preferência pelo núcleo (`JoystickCore`, testável, no molde de `TriggerTracker`) e não no `ButtonReader`; (c) se vale só para `dualShock4` ou para todos os modelos; (d) o tamanho da janela, justificado pelas medições (rajadas de 15 a 60 ms; pressões humanas rápidas a partir de 90 ms nos logs do Ipega).
- O filtro não pode reintroduzir botão preso (RN-EC-07, RI-04) nem afetar o PS, que já é deduplicado por RN-EC-06 e chega por duas vias.
- A árvore de trabalho tem a feature 012 em coding, sem commit (T023, T025 e T026 abertas). O change set do fix deve ficar separado dessa entrega ou explicitamente coordenado com ela.
- Taxonomia: sem termo novo proposto; `feature: 012-controle-dualshock-4` semeada hoje.
- Severidade `high` e prioridade `P1` escolhidas pelo usuário em 2026-09-22.
