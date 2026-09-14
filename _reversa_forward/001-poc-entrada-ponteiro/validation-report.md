# Relatório de validação: Prova de conceito de entrada do controle e apontamento

> Identificador: `001-poc-entrada-ponteiro`
> Requisito: `requirements.md` RF-25
> Roteiro: `onboarding.md`
> Estado: PM-3 interrompido pelo usuário em 2026-09-14, com o roteiro do ponteiro quase completo; blocos (b), (c), latência, CPU em movimento e ciclos ainda sem medição (D-24: só valores medidos)

Cada bloco indica a fonte dos números. Os vereditos do bloco (g) citam as medições dos blocos anteriores.

## Ambiente

| Item | Valor |
|------|-------|
| Data das medições | 2026-09-14 |
| macOS (`sw_vers`) | 26 |
| Mac (modelo) | MacBook com Apple Silicon |
| Versão da PoC (`session.start.appVersion`) | 0.1.0 |
| Controle e firmware | DualSense Wireless Controller (`0x054C`/`0x0CE6`); o `system_profiler` informa "Firmware Version: 1.0.0" na conexão Bluetooth, que não é necessariamente o firmware do controle |

## (a) Elementos do controle lidos em segundo plano

> Fonte: `onboarding.md` §2, item 4, com o Terminal em foco; `swift run poc-tools buttons <log>`. Alvo: 18 de 18.

| Conexão | Log analisado | Resultado ("N de 18") | Botões ausentes |
|---------|---------------|------------------------|-----------------|
| Bluetooth | `poc-20260914-180357.jsonl` | 17 de 18 (Terminal e VS Code em primeiro plano) | `ps`: o macOS abre o Game Center e o evento não chega à PoC |
| Bluetooth, após as correções do PM-2 | `poc-20260914-183610.jsonl` | **18 de 18** (outros apps em primeiro plano) | nenhum |
| USB | `poc-20260914-181719.jsonl` | não medido; só toque e conexão foram testados por USB | |

Correções que levaram de 17 a 18 de 18: leitura do PS pelo relatório HID bruto (`DualSenseReport`) e, nos Ajustes do Sistema, "Controles de jogo" com "Pressione o Botão de Início para abrir" em **Nenhum**, sem o que o Game Center abre a cada PS. Processamento nessa sessão: p95 0,110 ms em 50 amostras.

<!-- Cole aqui a tabela impressa por `poc-tools buttons`. -->

## (b) Taxa de acerto na tela de alvos

> Fonte: `onboarding.md` §5.1; `swift run poc-tools runs --env mesa` e `--env sofa`. Alvo: pelo menos 90% em 20 alvos de 16 × 16 pt. Uma linha por rodada de calibração completa, com os parâmetros vigentes e a medição com e sem L1.

### À mesa (monitor a cerca de 60 cm)

| Tela | Resolução (px) | Escala |
|------|----------------|--------|
| | | |

<!-- Cole aqui a tabela de `poc-tools runs --env mesa`. -->

| Rodada | Data | Parâmetros diferentes do padrão | Taxa de acerto | Com L1 | Sem L1 | Tempo médio (ms) |
|--------|------|----------------------------------|----------------|--------|--------|------------------|
| 1 | | | | | | |

### No sofá (TV a cerca de 2 m)

| Tela | Resolução (px) | Escala |
|------|----------------|--------|
| | | |

<!-- Cole aqui a tabela de `poc-tools runs --env sofa`. -->

| Rodada | Data | Parâmetros diferentes do padrão | Taxa de acerto | Com L1 | Sem L1 | Tempo médio (ms) |
|--------|------|----------------------------------|----------------|--------|--------|------------------|
| 1 | | | | | | |

Parâmetros finais adotados:

```json
```

## (c) Confirmação no VS Code, no sofá

> Fonte: `onboarding.md` §5.2. Vinte alvos pequenos reais, anotados como acerto ou erro no primeiro clique, com os parâmetros finais do bloco (b).

| # | Alvo | Acerto no primeiro clique (sim/não) | Observação |
|---|------|--------------------------------------|------------|
| 1 | Fechar aba | | |
| 2 | | | |
| 3 | | | |
| 4 | | | |
| 5 | | | |
| 6 | | | |
| 7 | | | |
| 8 | | | |
| 9 | | | |
| 10 | | | |
| 11 | | | |
| 12 | | | |
| 13 | | | |
| 14 | | | |
| 15 | | | |
| 16 | | | |
| 17 | | | |
| 18 | | | |
| 19 | | | |
| 20 | | | |

Total de acertos: __ de 20.

## (d) Latência

> Fonte: `onboarding.md` §5.3; sessão de 60 s com `--debug`; `swift run poc-tools latency <log>`. Alvos: processamento p95 ≤ 5 ms; entrada ao movimento p95 ≤ 20 ms.

| Medida | Amostras | p50 (ms) | p95 (ms) | Máximo (ms) | Aprovada |
|--------|----------|----------|----------|-------------|----------|
| Processamento (`t_delivered − t_arrival`) | | | | | |
| Entrada ao movimento (`t_posted − t_arrival`) | | | | | |

Limitação (R-12): a medida termina no `CGEvent.post`, e não no pixel exibido; a latência percebida pode ser maior.

Verificação de privacidade no mesmo log (`grep` de `onboarding.md` §5.3): sessão de latência não feita. Nos 12 logs mais recentes de 2026-09-14 (de `poc-20260914-182731.jsonl` a `poc-20260914-190043.jsonl`, até 5.261 linhas cada), nenhuma chave `x`, `y`, `dx`, `dy`, `location` ou `value`; `position` só em `controller.queued`.

Consumo de CPU (`onboarding.md` §5.4): parado **1,66%** em 60 s pelo tempo de CPU do processo (`ps`), e 0,6% numa conferência de 20 s (meta 2%, aprovada); em movimento __% (meta 5%), não medido. O comando `top` do §5.4 não casava as linhas, que terminam em espaço, e foi corrigido no `onboarding.md`.

Robustez (`poc-tools cycles`): __ ciclos completos, __ sessões no arquivo (meta: 100 ciclos, 1 sessão).

## (e) Assinatura e permissões após recompilação

> Fonte: `onboarding.md` §1 (Acessibilidade) e §2, item 5a (Input Monitoring, só se P-04 o exigir); `./scripts/check-signature.sh` antes e depois do build.

| Item | Resultado |
|------|-----------|
| Caminho adotado (A: Apple Development da conta gratuita; B: certificado autoassinado local) | B, identidade "JoystickAI Local Signing" criada por `scripts/create-local-signing-identity.sh` em 2026-09-14 |
| Motivo, se o caminho A foi abandonado | Desistência registrada pelo usuário em 2026-09-14 (R-13): o Xcode não está instalado, e o caminho A exigiria baixá-lo e entrar com o Apple ID só para obter o certificado. |
| Requisito designado estável entre builds (`diff` vazio) | Sim: `identifier "dev.iagoleal.joystick-ai.poc" and certificate leaf = H"bd5fe5690ad38f5f4aa4395aaf28299c53c53839"` antes e depois de uma recompilação que alterou o binário. |
| Acessibilidade mantida após recompilar, sem nova concessão (PM-1) | Sim, em 2026-09-14: concedida uma vez; após recompilar (binário `3e5e161ec351` → `6ef09493b66e`) e reabrir, `permissions.status` na abertura trouxe `postEvent: true`, com o mesmo requisito designado. |
| Input Monitoring necessário (P-04) | Não: com só a Acessibilidade concedida, 17 botões e o analógico chegaram com a PoC em segundo plano. |
| Input Monitoring mantido após recompilar, sem nova concessão (P-11), se necessário | Dispensado (item 5a não se aplica). |

## (f) Respostas às questões abertas

> Fonte: `investigation.md` §4 (P-01 a P-11), `requirements.md` §10 e o roteiro de `onboarding.md` §2 e §3.

| Questão | Resposta observada | Evidência (evento, item do roteiro) |
|---------|--------------------|---------------------------------------|
| P-01: `physicalInputProfile.touchpads` vem populado, com `touchState` confiável? | Não, nem por Bluetooth nem por USB: `touchpads` veio vazio, e a PoC adotou a inferência por (0, 0) (`source: zero_transition`). Os elementos `Touchpad 1` e `Touchpad 2` existem como direcionais. | `controller.touch_source` em `poc-20260914-180357.jsonl` e `poc-20260914-181719.jsonl` |
| P-02: `touchpadPrimary` volta a (0, 0) ao retirar o dedo? | Por USB, sim: `input.touch` com `began` e `ended` coerentes para os dedos 0 e 1, a cerca de 400 amostras/s por dedo. Uma vez o dedo 0 teve fim e novo início em 84 ms com o dedo 1 pousado, a confirmar como retirada real ou zero espúrio. **Por Bluetooth, o touchpad não envia nada** ao GameController, em segundo nem em primeiro plano (diagnóstico temporário de 80 s com toque contínuo, analógico recebido no mesmo período); só chegam dois valores iniciais na conexão, que a PoC tomou por início de toque sem fim. Causa confirmada em 2026-09-14 por sonda HID fora da PoC: por Bluetooth o controle envia só o relatório simplificado `0x01` de 10 bytes, sem touchpad; ao ler o relatório de recurso `0x05` (calibração) com `IOHIDDeviceGetReport`, ele passa em menos de 1 s ao relatório `0x31` de 78 bytes, e o GameController começa a entregar o touchpad (cerca de 120 amostras/s, em segundo plano). A abertura do dispositivo por `IOHIDManagerOpen` não pediu permissão nova. Correção aplicada na PoC (`ExtendedReportActivator`, evento `controller.extended_report`): em `poc-20260914-182731.jsonl`, `result: ok` na abertura e `input.touch` com `began` e `ended` coerentes para os dedos 0 e 1 por Bluetooth. | `poc-20260914-181719.jsonl`; `poc-20260914-180357.jsonl`; diagnóstico fora da PoC; `touch.raw_transition`, §2 item 6 |
| P-03 e `controller-input` OQ-01: o botão de mudo aparece em `allElements`? | Não: os 49 elementos listados não incluem mudo. | `controller.elements` em `poc-20260914-180357.jsonl` |
| P-04, `controller-input` OQ-03 e `app-shell` OQ-01: eventos em segundo plano sem Input Monitoring? Após concedê-lo, só relançando? | Sim, em segundo plano sem Input Monitoring na Fase 1 (botões e analógico). Observação preliminar (Fase 0): com só a Acessibilidade concedida, `CGPreflightListenEventAccess()` passou a devolver `true` (`listenEvent: true`) sem Input Monitoring na lista; antes da concessão devolvia `false`. O teste da Fase 1 deve considerar que a Acessibilidade pode já cobrir a escuta. | `poc-20260914-180357.jsonl`, §2 itens 4 e 5 |
| P-05: `buttonMenu` é Options e `buttonOptions` é Create? | Sim: Create e Options apertados isoladamente, a pedido, geraram `create` e `options`. | `poc-20260914-180357.jsonl`, §2 item 4 |
| P-06: `Transport` do IORegistry distingue USB de Bluetooth? | Sim, nas duas vias (`bluetooth` e `usb` ao abrir a PoC). Na troca a quente de Bluetooth para USB, a nova conexão chegou 58 ms após a desconexão e saiu `unknown`, provavelmente porque o registro do Bluetooth ainda existia; minutos depois só havia o candidato USB. | `poc-20260914-180357.jsonl`; `poc-20260914-181719.jsonl`, §2 itens 1 e 3 |
| P-07: a supressão em `buttonHome` impede o Launchpad? | Não: com `controller.gesture_suppression` registrado, PS abre o Game Center e nenhum `input.button` de `ps` chega à PoC. Investigação de 2026-09-14 por Bluetooth: com a supressão pedida, o `pressedChangedHandler` de `buttonHome` nunca disparou e o Game Center abriu nas duas pressões; a leitura HID bruta do mesmo processo registrou `down` e `up` do PS nas duas vezes. O botão chega do controle, e o sistema o retém antes do GameController. O teste com a janela em primeiro plano não foi concluído. **Solução adotada:** a PoC lê o PS do relatório HID bruto, e o avaliador pôs "Pressione o Botão de Início para abrir" em "Nenhum" nos Ajustes do Sistema ("Controles de jogo"); com isso o Game Center não abre e `ps` chega com `down` e `up` (`poc-20260914-183610.jsonl`). Mesmo com o ajuste, o GameController continuou sem entregar o PS. A preferência `preferredSystemGestureState` não teve efeito observável. | `poc-20260914-180357.jsonl`, §2 itens 4 e 10; `controller.gesture_suppression` |
| P-08: `CGPreflightPostEventAccess()` reflete a revogação sem relançar? | **Não, nos dois sentidos.** Na concessão (Fase 0), só a reabertura mostrou `postEvent: true`. Na revogação (§3 item 15, 2026-09-14): ao desligar a chave do JoystickAIPoC em Acessibilidade, o macOS descartou os eventos postados de imediato (cursor parado) e, ao religá-la, voltou a aceitá-los, com o processo vivo; mas a consulta a cada 2 s continuou devolvendo `true`, e o log não tem `permissions.status` de consulta, `permissions.guidance`, `pointer.injection_suspended` nem `pointer.injection_resumed`. O resultado é guardado por processo. **Correção aplicada e verificada:** a consulta passou a `AXIsProcessTrusted()`. Num diagnóstico temporário com as três fontes a cada 2 s, durante a revogação `AXIsProcessTrusted()` devolveu `false` e a criação de *event tap* falhou, enquanto `CGPreflightPostEventAccess()` seguiu `true`. Com a correção, `permissions.status` (`postEvent: false`), `permissions.guidance` e `pointer.injection_suspended` saíram às 19:52:56, e `pointer.injection_resumed` às 19:53:20. Na retomada, a PoC repete as solturas de mouse e teclas feitas na suspensão, que o sistema já descartava. Uma tentativa anterior com `AXIsProcessTrusted()` não registrou nada, provavelmente por revogação mais curta que o intervalo de 2 s. | `poc-20260914-192925.jsonl` (antes), `poc-20260914-195114.jsonl` (depois), §3 item 15 | `permissions.status`, §3 item 15 |
| P-09: o DualSense já conectado chega pela lista, por notificação ou pelas duas vias? Intervalo desde `session.start`? | Um único `controller.connected` com `atStartup: true`, 23 ms após o `session.start` por Bluetooth e 22 ms por USB. A via não é registrada, mas a deduplicação impediu registro duplo. | `controller.connected` em `poc-20260914-180357.jsonl` e `poc-20260914-181719.jsonl`, §2 item 1 |
| P-10: `CGRequestPostEventAccess()` reabre o diálogo a cada abertura sem permissão? | | §1 item 5 |
| P-11: Input Monitoring sobrevive a uma recompilação? | | §2 item 5a |
| R-07: pares `r2` espúrios com o gatilho perto de 0,5? | Não observados: cinco pressões, cinco pares `down`/`up`, sem repetição. | `poc-20260914-180357.jsonl`, §2 item 7 |
| R-15: Create aciona captura do sistema? | Nada relatado pelo avaliador ao apertar Create. | §2 item 8 |
| R-06: precisão durante arraste com R1 (com e sem L1) | Sem L1: arraste com R1 pelo analógico e com o clique do touchpad seleciona o trecho (18 emissões de arraste). Com L1 durante o arraste: não testado. Pelo código, L1 somado a R1 desativa a precisão (`precisionActive` exige só L1). | `poc-20260914-191229.jsonl`, §3 item 10 |
| `pointer-control` OQ-01: os padrões de velocidade e expoente atendem numa TV a 2 m? (resposta preliminar) | | bloco (b), sofá |
| `app-shell` OQ-03: certificado disponível | | bloco (e) |
| `pointer-control` OQ-02: rolagem em pixels ou em linhas | Não respondida: o item 16 foi interrompido. Em pixels, com `scrollSpeed` 100, a rolagem no VS Code foi considerada confortável. | §3 itens 11 e 16 |

## (g) Veredito das premissas

> Opções: sustentada, sustentada com ajustes ou refutada. Cada veredito cita as medições que o sustentam; o da premissa 1 se baseia nos resultados do sofá.

| Premissa | Veredito | Medições que o sustentam | Ajustes propostos ao `/reversa-sync` |
|----------|----------|---------------------------|---------------------------------------|
| 1, precisão do apontamento: o analógico ou o touchpad do DualSense são precisos o bastante para clicar em alvos pequenos de uma IDE sem frustração | | blocos (b) sofá e (c) | |
| 2, acesso ao hardware no macOS: é possível ler todos os controles do DualSense e injetar movimento de mouse sob as permissões de Acessibilidade e Input Monitoring | | blocos (a), (d) e (e) | |

## Roteiro do ponteiro (`onboarding.md` §3)

> Fonte: sessões com `--debug` de 2026-09-14 (`poc-20260914-190523.jsonl`, `poc-20260914-191229.jsonl`, `poc-20260914-192139.jsonl` a `poc-20260914-192925.jsonl`) e um medidor temporário fora da PoC, que lia o DualSense pelo GameController e a posição do cursor a 100 Hz, sem gravar nada. Velocidades são medianas de janelas de 100 ms com inclinação estável.

**Mapeamento de cliques alterado durante o portão**, a pedido do usuário: R1 e o clique do touchpad fazem o botão esquerdo, e R2 o direito, invertendo RN-11 e D-06. Os itens 7 a 14 foram feitos já com o mapeamento novo.

| # | Resultado | Medição ou observação | Veredito |
|---|-----------|------------------------|----------|
| 1 | Cursor parado com dedo pousado e com o analógico em repouso | Em minutos de repouso, desvios isolados de 1 pt, compatíveis com toque no trackpad do Mac | aprovado |
| 2 | Cursor para a direita, seguindo só o primeiro dedo | Observação do avaliador | aprovado |
| 3 | Velocidade máxima 1.500 pt/s | 1.489 a 1.511 pt/s em várias medições: 1.920 pt em **1,28 s** (alvo 1,5 s) | aprovado |
| 4 | Movimento lento em inclinação parcial | Velocidade medida igual à fórmula `1500 · m²` (razão 0,99 a 1,01 em inclinações de 0,24 a 0,46); a 30%, 135 pt/s, 9% da máxima. Abaixo de um décimo, mas por pouco: "bem abaixo" depende de `stickExponent` | aprovado com observação |
| 5 | Analógico e touchpad somam | Observação do avaliador | aprovado |
| 6 | Precisão com L1 | 444 a 448 pt/s com inclinação total, **29,7%** (faixa 25% a 35%) | aprovado |
| 7 | R1 e clique do touchpad selecionam abas | Observação do avaliador; cliques esquerdos com `clickState` 1 no log | aprovado |
| 8 | R2 abre o menu de contexto | Observação do avaliador; `down` e `up` do botão direito | aprovado |
| 9 | Duplo R1 seleciona palavra | 4 pares com `clickState` 2 | aprovado |
| 10 | Arraste com R1 e com o clique do touchpad seleciona trecho | 18 emissões `drag` à esquerda | aprovado |
| 11 | Rolagem até o fim de 1.000 linhas no VS Code | Com o padrão de 40 linhas/s, cerca de 22 s estimados pela taxa medida (acima dos 10 s). Com `scrollSpeed` **100** em `~/.config/joystick-ai/config.json` (R-10), fim do arquivo em **6,7 s** de inclinação contínua, velocidade confortável. Rolagem horizontal não confirmada explicitamente | aprovado com `scrollSpeed` 100 |
| 12 | Cursor para nas bordas | Quatro bordas da tela interna (1.680 × 1.050 pt); TV não conectada, parte da TV pendente | aprovado em parte |
| 13 | Desligar o controle arrastando solta o botão | `mouseUp` esquerdo no instante da desconexão, PS com soltura sintética antes de `controller.disconnected`; seleção não acompanhou o trackpad. R1 foi solto pelo próprio controle 11 ms antes da desconexão, então a soltura sintética de R1 em si não foi exercitada | aprovado |
| 14 | Encerrar com R1 segurado solta o botão | Encerramento com R1 segurado há 3,2 s: `mouseUp` e `app.terminating` com `reason: quit` e `releasedButtons: ["left"]`, uma vez; seleção não acompanhou | aprovado |
| 15 | Revogar a Acessibilidade | Primeira execução: cursor parou e voltou, mas sem nenhum evento (P-08). Após trocar a consulta por `AXIsProcessTrusted()`: `permissions.guidance`, `pointer.injection_suspended` e `pointer.injection_resumed` registrados, processo vivo, cursor de volta | aprovado após correção |
| 16 | Rolagem em linhas | Interrompido pelo usuário | não feito |

## Parâmetros sem recompilar (`onboarding.md` §4)

| Cenário | Resultado |
|---------|-----------|
| Arquivo válido | `config.loaded` com `status: loaded`, `stickMaxSpeed` 1800 e `scrollSpeed` 100 |
| JSON inválido | `config.invalid_json` com `line: 4` |
| Valor fora da faixa | `config.value_rejected` para `touchpadSensitivity` 9, com `min` 0,1 e `max` 5,0 |
| Arquivo ausente | `config.loaded` com `reason: file_missing` e `status: defaults`; arquivo não recriado |

## Pendências do PM-3

- Bloco (b): rodadas da tela de alvos à mesa e no sofá, com `poc-tools runs`, e a verificação de que a marca em `eventSourceUserData` chega ao `NSEvent`.
- Bloco (c): confirmação no VS Code com 20 alvos.
- Bloco (d): sessão de latência, CPU em movimento e 100 ciclos de conexão.
- §3 item 12 com a TV e item 16.
- P-10, P-11 (dispensada), `app-shell` OQ-03 e os vereditos do bloco (g).

## Cenários Gherkin executados

> Fonte: `requirements.md` §7. Anote o resultado de cada cenário.

| Cenário | Cobre | Resultado | Observação |
|---------|-------|-----------|------------|
| | | | |
