# Actions: Teclado virtual chamado pelo controle

> Identificador: `006-teclado-virtual`
> Data: `2026-09-16`
> Roadmap: `_reversa_forward/006-teclado-virtual/roadmap.md`

## Resumo

| Métrica | Valor |
|---------|-------|
| Total de ações | 15 |
| Paralelizáveis (`[//]`) | 10 |
| Maior cadeia de dependência | 6 (T003 → T004 → T005 → T012 → T014 → T015) |

## Convenções desta decomposição

### Portões manuais

Passagens que dependem de ato humano não recebem ID `T`; aparecem como `PM-n` na coluna de dependências. O `/reversa-coding` deve parar ao alcançar um portão e só seguir quando o usuário confirmar o resultado.

| Portão | Ato do usuário | Requer | Referência | Libera |
|--------|----------------|--------|------------|--------|
| PM-0 | Com o app atual, executar o roteiro do `onboarding.md` §1 (12 passos) e relatar P-01 a P-05 e o caminho real dos menus nos Ajustes. A liberação de escrita já está cumprida: `.reversa/reversa-config.json` com `allowLegacyEdits: true` e `allowedPaths` vazio (liberação irrestrita), a reler na ativação do `/reversa-coding`. | - | D-08, `onboarding.md` §1, `investigation.md` §5 | T001, T002, T003 |
| PM-0B | **Só se P-01 for reprovada.** Instalar o app com D-03 (`scripts/build-app.sh`) e repetir o passo 5 do PM-0. Com P-01 aprovada no PM-0, o portão é dispensado e conta como cumprido. | T005, T013 | D-03, `onboarding.md` §1, passo 5 | T014 |
| PM-1 | Instalar o app da feature e executar o roteiro do `onboarding.md` §3 (13 passos) com os ajustes A-1 a A-4 feitos. | T014 | D-08, `onboarding.md` §3 | T015 e o critério de pronto |

A maior cadeia conta apenas ações `T`.

**Parada da feature.** Se o PM-0 reprovar P-03 (foco) ou P-04 (cliques no teclado), nenhuma ação `T` é executada: o `/reversa-coding` registra o resultado nas notas e devolve a continuidade ao usuário (roadmap §4 e §9). Com P-01 reprovada, P-03 e P-04 ainda se respondem exibindo o teclado pelo ⌥⌘F5 físico.

### Ações condicionais

T005, T012 e T013 implementam D-03 e só são executadas se T001 registrar P-01 reprovada. Com P-01 aprovada, o `/reversa-coding` as marca `[X]` com a indicação "dispensada (P-01 aprovada)" nas notas de execução, sem tocar os arquivos alvo, e o PM-0B também fica dispensado. Se P-01 seguir reprovada no PM-0B mesmo com D-03, o `/reversa-coding` para e sugere o plano de contingência do roadmap §9 (módulo de Atalhos de Acessibilidade na barra de menus), que não tem ação reservada.

### Correspondência com o roadmap

| Decisões do roadmap | Ações |
|---------------------|-------|
| D-01 (Teclado de Acessibilidade pelo ⌥⌘F5) | PM-0, T001; conferida no PM-1 |
| D-02 (`accessibilityShortcut`, ID 162, `KeyChord.f5`) | T003, T004 |
| D-03 (máscara de função nas teclas F, condicional) | T005, T012, T013, PM-0B |
| D-04 (mapeamento padrão intacto) | T011 |
| D-05 (nada muda em log, ações, roteador, paleta e editor) | nenhuma ação; conferido por T014 e pelo PM-1 |
| D-06 (pré-requisitos no `onboarding.md`) | T002, T015 |
| D-07 (testes) | T006, T007, T008, T009, T010, T011, T012 |
| D-08 (portões PM-0 e PM-1) | PM-0, PM-1, T001, T015 |

### Arquivos compartilhados e blocos de compilação

Ações que tocam o mesmo arquivo são sequenciais: `ShortcutMapper.swift` (T003, T004, T005), `ShortcutMapperTests.swift` (T007, T012) e `onboarding.md` (T002, T015). O pacote deve compilar (`swift build`) ao fim de cada ação de código, e `./scripts/test.sh` deve passar ao fim de cada ação de teste. Nenhum `switch` exaustivo sobre `SystemShortcut` existe fora de `ShortcutMapper.swift`, conferido em 2026-09-16; o caso novo não quebra outros arquivos.

### Fase 2 sem ações próprias

Como nas features anteriores, os testes são escritos junto do núcleo, depois da API que exercitam, para que cada ação termine compilando. Os testes de D-07 estão na Fase 3, logo após T004 e T005.

### Acréscimos da decomposição

- **Comentários de documentação.** Os membros novos (`KeyChord.f5`, o caso `accessibilityShortcut` e, com D-03, `isFunctionKey`) citam `006-teclado-virtual` e a decisão que implementam, no estilo dos comentários existentes em `SystemShortcut`, que citam `003-editor-atalhos`.
- **Sem teste de `isArrow` para imitar.** Não há teste de `KeyChord.isArrow` em `Tests/JoystickCoreTests/`; T012 cria o primeiro teste de classificação de teclas, em `ShortcutMapperTests`, onde `KeyChord` é declarado.

### Observação da decomposição

- **Falso positivo no PM-0, passo 11.** O comando `grep -ci 'f5' "$LOG"` espera 0, mas o log vigente (`poc-20260916-184700.jsonl`) já devolve 1: o evento `session.start` traz o hash do certificado de assinatura, que contém a sequência `f5` (`…ad38f5f4…`). A contagem deve excluir `session.start`, por exemplo `grep -v '"session.start"' "$LOG" | grep -ci 'f5'`. A correção cabe ao `onboarding.md` antes do PM-0; ver o relatório do `/reversa-to-do`.

## Fase 1, Preparação

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T001 | Registrar nas notas de execução o resultado de P-01 a P-05 relatado no PM-0, com o tempo de resposta do passo 5, e a decisão sobre D-03: "executar" se P-01 foi reprovada, "dispensada" se aprovada; se P-03 ou P-04 foram reprovadas, registrar a parada da feature (D-01, D-03, D-08) | PM-0 | `[//]` | `_reversa_forward/006-teclado-virtual/actions.md` | 🟡 | `[X]` |
| T002 | Corrigir o quadro "Ajustes do sistema exigidos pela feature" do `onboarding.md` §0 com os caminhos de menu anotados no passo 1 do PM-0 para A-1 a A-4, removendo a ressalva de conferência dos itens confirmados (D-06, RF-08) | PM-0 | `[//]` | `_reversa_forward/006-teclado-virtual/onboarding.md` | 🟡 | `[X]` |
| T003 | Acrescentar a `KeyChord` a constante `public static let f5: UInt16 = 96`, em decimal e na posição ordenada pelo código entre as teclas nomeadas (D-02, `data-delta.md` §3) | PM-0 | `[//]` | `Sources/JoystickCore/Shortcuts/ShortcutMapper.swift` | 🟢 | `[X]` |

## Fase 2, Testes

Sem ações nesta fase; ver "Fase 2 sem ações próprias".

## Fase 3, Núcleo

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T004 | Acrescentar a `SystemShortcut` o caso `accessibilityShortcut = 162`, com `name` `"accessibilityShortcut"`, `displayName` `"atalho de acessibilidade"` e `defaultChord` `KeyChord(KeyChord.f5, [.option, .command])`, sem mudar `chords(fromSymbolicHotKeys:)` (D-02, RF-04, `data-delta.md` §2) | T003 | - | `Sources/JoystickCore/Shortcuts/ShortcutMapper.swift` | 🟢 | `[X]` |
| T005 | **Condicional a D-03.** Acrescentar a `KeyChord` a propriedade `public var isFunctionKey: Bool`, verdadeira para os 12 códigos de F1 a F12 de `data-delta.md` §3 (`0x7A`, `0x78`, `0x63`, `0x76`, `0x60`, `0x61`, `0x62`, `0x64`, `0x65`, `0x6D`, `0x67`, `0x6F`), junto de `isArrow` (D-03) | T001, T004 | - | `Sources/JoystickCore/Shortcuts/ShortcutMapper.swift` | 🟡 | `[X]` |
| T006 | Em `ShortcutConfigTests.atalhoDeSistemaIdaEVoltaPeloNome`, incluir `"accessibilityShortcut"` no conjunto esperado de seis nomes e afirmar que `SystemShortcut.accessibilityShortcut.displayName` é "atalho de acessibilidade" (D-07, RF-04) | T004 | `[//]` | `Tests/JoystickCoreTests/ShortcutConfigTests.swift` | 🟢 | `[X]` |
| T007 | Em `ShortcutMapperTests.atalhosDeSistemaLidosDasPreferencias`, acrescentar a entrada `"162"` ativa com `[65535, 96, 1572864]` e esperar ⌥⌘F5; em teste novo, esperar o acorde remapeado de uma entrada `"162"` com outra tecla e máscara, e o padrão ⌥⌘F5 com a entrada desativada (D-07, RN-AT-10, RN-AT-22) | T004 | `[//]` | `Tests/JoystickCoreTests/ShortcutMapperTests.swift` | 🟢 | `[X]` |
| T008 | Em `ShortcutConfigValidationTests`, afirmar que `{"type": "systemShortcut", "name": "accessibilityShortcut"}` é aceito e resolve em `.systemShortcut(.accessibilityShortcut)`, sem `unknownSystemShortcut` (D-07, `data-delta.md` §1) | T004 | `[//]` | `Tests/JoystickCoreTests/ShortcutConfigValidationTests.swift` | 🟢 | `[X]` |
| T009 | Em `ConfigDocumentTests`, testar a ida e volta de um documento com `.systemShortcut(.accessibilityShortcut)` num botão da camada base, conferindo o documento decodificado e o `"name": "accessibilityShortcut"` no JSON gravado (D-07, RF-04) | T004 | `[//]` | `Tests/JoystickCoreTests/ConfigDocumentTests.swift` | 🟢 | `[X]` |
| T010 | Em `ActionSummaryTests`, testar que um botão com `.systemShortcut(.accessibilityShortcut)` resume "atalho de acessibilidade" (D-07, RF-04) | T004 | `[//]` | `Tests/JoystickCoreTests/ActionSummaryTests.swift` | 🟢 | `[X]` |
| T011 | Em `ShortcutDefaultsTests`, testar que nenhuma ação de nenhuma camada de `ShortcutDefaults` é `.systemShortcut(.accessibilityShortcut)` (D-04, D-07, RN-10, RF-06) | T004 | `[//]` | `Tests/JoystickCoreTests/ShortcutDefaultsTests.swift` | 🟢 | `[X]` |
| T012 | **Condicional a D-03.** Em `ShortcutMapperTests`, testar `isFunctionKey` verdadeiro para F1 (`0x7A`), F5 (`KeyChord.f5`) e F12 (`0x6F`), e falso para `KeyChord.equal` (`0x18`) e as quatro setas (D-03, D-07) | T005, T007 | - | `Tests/JoystickCoreTests/ShortcutMapperTests.swift` | 🟡 | `[X]` |

## Fase 4, Integração

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T013 | **Condicional a D-03.** Em `KeyboardInjector.postKey`, acrescentar `.maskSecondaryFn` às `flags` quando `chord.isFunctionKey`, sem `.maskNumericPad`, mantendo a regra das setas, e registrar o motivo num comentário ao lado do das setas (D-03, `data-delta.md` §4, RN-IN-10) | T005 | `[//]` | `Sources/JoystickAIPoC/Injection/KeyboardInjector.swift` | 🟡 | `[X]` |

## Fase 5, Polimento

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T014 | Rodar `swift build -c release` e `./scripts/test.sh`, confirmar ambos verdes e registrar nas notas a contagem de testes (274 antes da feature) e a lista de arquivos alterados, que deve se limitar aos alvos de T003 a T013 e excluir os de T005, T012 e T013 quando D-03 for dispensada (D-05, D-07) | T006, T007, T008, T009, T010, T011, T012, T013, PM-0B | - | `_reversa_forward/006-teclado-virtual/actions.md` | 🟢 | `[X]` |
| T015 | Atualizar o `onboarding.md` §3 com o resultado de cada passo do PM-1 e ajustar nomes e rótulos do roteiro que divergirem do código entregue, registrando se D-03 foi executada (D-06, D-08) | T002, T014, PM-1 | - | `_reversa_forward/006-teclado-virtual/onboarding.md` | 🟡 | `[X]` |

## Notas de execução

### Rodada de 2026-09-16 (`/reversa-coding`), parada no PM-0

- **Política de edição:** `allowLegacyEdits: true` com `allowedPaths` vazio, liberação irrestrita. Âncora de legado presente (`architecture.md` e `domain.md`).
- **Nenhuma ação executada.** T001, T002 e T003 dependem do PM-0; as demais dependem delas. `legacy-impact.md` e `regression-watch.md` ainda não foram gerados, porque nenhum arquivo do projeto foi tocado.
- **Auditoria:** `audit/cross-check.md` com 0 CRITICAL, 0 HIGH, 5 MEDIUM e 5 LOW, sem correção nos artefatos. Para A005, esta execução só inicia T002 e T003 depois de T001 registrar as sondas.
- **Estado de partida conferido (só leitura):** app instalado e em execução (`--debug`), assinado com "JoystickAI Local Signing"; entrada 162 ativa com `(65535, 96, 1572864)`, ou seja, ⌥⌘F5; `axShortcutExposedFeatures` ausente, o que indica a lista padrão com vários recursos (A-2 ainda por fazer).
- **Roteiro do PM-0 divergente da configuração vigente.** O `onboarding.md` §1 supõe o mapeamento padrão, mas o `config.json` do usuário tem outro:
  - L3 na base não está livre: envia Tab. O botão da sonda passa a ser **Options + ○**, sem ação própria na camada Options (herda Esc da base), o mesmo que o PM-1 já usa.
  - PS na base envia Espaço; a paleta abre por **Create**.
  - L1 + ✕ envia ⌘A; "CONTINUAR" sai por **△** na base, sem Enter.
  - O passo 11 usa a contagem corrigida de A001: `grep -v '"session.start"' "$LOG" | grep -ci 'f5'`.
  O roteiro adaptado foi entregue ao usuário na conversa; a correção no `onboarding.md` cabe a T002 ou à edição manual.
- **Primeira tentativa do PM-0 inválida (19:29).** O salvamento pelo editor não chegou ao arquivo; Options + ○ enviou o Esc herdado da base, e não ⌥⌘F5. A pedido do usuário, a ação foi gravada direto no arquivo: cópia em `config.pre-006.json` e `options.circle = {"type": "chord", "key": "f5", "modifiers": ["option", "command"]}`. O app recarregou (`shortcuts.loaded`, `source: file`, `trigger: external`). Os passos 3 e 4 do roteiro ficam cumpridos sem a conferência visual do editor, repetida no PM-1.

### Rodada 2 de 2026-09-16 (P-01 reprovada, D-03 executada)

- **T001, sondas até aqui.** **P-01 reprovada:** Options + ○ enviou ⌥⌘F5 (cinco `shortcut.triggered` com `type: chord` após a recarga), mas o sistema o tratou como tecla comum: o cursor se ocultou, como ao digitar, e nenhum painel apareceu. **Referência física aprovada:** ⌥⌘F5 no teclado do Mac abre o painel de atalhos de acessibilidade, com locução, o que confirma A-1 ativo e A-2 ainda por fazer. **Decisão sobre D-03: executar.** P-02 a P-05 e os caminhos dos menus aguardam o PM-0B; a regra de parada para P-03 e P-04 continua valendo.
- **T002 pendente:** depende dos caminhos de menu do passo 1, ainda não relatados.
- **T003:** `KeyChord.f5 = 96`, em decimal, depois de `m`.
- **T004:** caso `accessibilityShortcut = 162` com nome, rótulo e acorde padrão; nenhum outro arquivo precisou mudar para compilar.
- **T005:** além de `isFunctionKey`, a lista de códigos ficou pública em `KeyChord.functionKeys`, para que o teste a compare com o grupo `function` de `KeyCatalog`.
- **T006 a T012:** testes `atalhoDeSistemaIdaEVoltaPeloNome` (ampliado), `atalhosDeSistemaLidosDasPreferencias` (entrada 162), `atalhoDeAcessibilidadeRemapeadoOuDesativado`, `teclasDeFuncao`, `atalhoDeAcessibilidadeAceito`, `idaEVoltaComAtalhoDeAcessibilidade`, `atalhoDeAcessibilidade` (resumo) e `padraoSemAtalhoDeAcessibilidade`. `./scripts/test.sh`: **280 testes em 31 suítes, todos verdes** (274 antes).
- **T013:** `KeyboardInjector.postKey` acrescenta `.maskSecondaryFn` às teclas F1 a F12, sem `.maskNumericPad`.
- **Instalação para o PM-0B:** `build-app.sh` com "JoystickAI Local Signing"; app reaberto com `--debug`, `permissions.status` com `postEvent: true`, controle conectado, configuração do teste (Options + ○ = ⌥⌘F5) carregada. T014 aguarda o PM-0B.

### Rodada 3 de 2026-09-16 (PM-0B e T014)

- **PM-0B aprovado.** Com D-03 instalada, Options + ○ (⌥⌘F5) abriu pelo controle o painel de atalhos de acessibilidade; escolher o Teclado de Acessibilidade com R1 o exibiu. **P-01 aprovada com D-03.**
- **P-02, caminho com passo extra: aprovada.** O caminho direto, com só o teclado marcado (A-2), ainda não foi testado.
- **P-03 aprovada.** O teclado flutua à frente, mas o terminal continua sendo o aplicativo em foco e recebe o texto.
- **P-04 aprovada.** `l`, `s` e Return clicados com R1 digitaram `ls` no terminal, confirmado pelo usuário como digitação no teclado, e não pelo ditado. Log da sessão (`poc-20260916-193645.jsonl`): dois `shortcut.triggered` de `circle`/`options` e 8 cliques; contagens de `"ls"`, `f5` (fora de `session.start`) e `accessibility` iguais a 0.
- **Pendentes do PM-0:** tempo de resposta (até 1 s), passo 8 (△ e Create com o teclado visível), P-05 (A-3, A-4 e palavra de oito letras a 3 m) e os caminhos dos menus (T002).
- **T014:** `swift build -c release` verde; `./scripts/test.sh` com **280 testes em 31 suítes, todos verdes** (274 antes). Arquivos de projeto alterados, todos alvos de T003 a T013: `Sources/JoystickCore/Shortcuts/ShortcutMapper.swift`, `Sources/JoystickAIPoC/Injection/KeyboardInjector.swift`, `Tests/JoystickCoreTests/ShortcutConfigTests.swift`, `ShortcutMapperTests.swift`, `ShortcutConfigValidationTests.swift`, `ConfigDocumentTests.swift`, `ActionSummaryTests.swift` e `ShortcutDefaultsTests.swift`. Nada mudou em `LogEventCatalog`, `ShortcutActions`, `InputRouter`, `PaletteActions` nem `EditorViewModel` (D-05). `.reversa/active-requirements.json` aparece modificado desde antes desta rodada, por outro skill.
- **App instalado já é o da feature:** o PM-1 pode rodar sem nova instalação.

### Rodada 4 de 2026-09-16 (PM-1, T002 e T015)

- **Relato do usuário:** "Funcionou, eu já configurei. Ficou ótimo."
- **Conferido nas preferências:** `axShortcutExposedFeatures` só com `feature.virtualKeyboard = 1` (A-2 feito); entrada 162 ativa (A-1).
- **Conferido no arquivo e no log:** pelo editor, às 19:48:00 (`shortcuts.saved`), o usuário pôs "atalho de acessibilidade" em **Options + →**, gravado como `{"name": "accessibilityShortcut", "type": "systemShortcut"}`, e o acionou às 19:48:02 (`type: systemShortcut`, sem nome). Options + ○ ficou com a ação "nenhuma" e deixou de herdar Esc da base. O passo 8 do PM-0 aparece no log às 19:46 (△, Create e fechamento da paleta por ○). Contagens de vazamento iguais a 0.
- **PM-1 aprovado**, com os passos 1 e 6 a 11 não relatados; detalhe em `onboarding.md` §4.
- **T002:** quadro do §0 com a conferência de A-1 e A-2 pelas preferências; o caminho textual dos menus não foi relatado e ficou marcado como indicação. Passo 11 do §1 corrigido com a exclusão de `session.start` (auditoria A001).
- **T015:** `onboarding.md` recebeu o §4, com o resultado do PM-0, do PM-0B e do PM-1 e a adaptação do roteiro à configuração do usuário.
- **Rastros:** `legacy-impact.md` e `regression-watch.md` gerados (8 itens no watch principal, 6 observações).

## Histórico de alterações

| Data | Alteração | Autor |
|------|-----------|-------|
| 2026-09-16 | Versão inicial gerada por `/reversa-to-do` | reversa |
| 2026-09-16 | `/reversa-coding` parado no PM-0, sem ação executada; roteiro adaptado à configuração vigente | reversa |
| 2026-09-16 | P-01 reprovada; T001 e T003 a T013 executadas; app instalado para o PM-0B | reversa |
| 2026-09-16 | PM-0B aprovado (P-01 a P-04); T014 executada | reversa |
| 2026-09-16 | PM-1 aprovado; T002 e T015 executadas; todas as ações fechadas | reversa |
