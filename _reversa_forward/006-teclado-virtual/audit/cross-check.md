# Cross-check: Teclado virtual chamado pelo controle

> Identificador: `006-teclado-virtual`
> Data: `2026-09-16`
> Artefatos analisados: [`requirements.md`](../requirements.md), [`roadmap.md`](../roadmap.md), [`actions.md`](../actions.md)
> Apoio: [`data-delta.md`](../data-delta.md), [`interfaces/atalho-de-acessibilidade.md`](../interfaces/atalho-de-acessibilidade.md), [`investigation.md`](../investigation.md), [`onboarding.md`](../onboarding.md), `_reversa_sdd/domain.md`, `_reversa_sdd/architecture.md`, `_reversa_sdd/atalhos/requirements.md`, `_reversa_sdd/injecao-de-eventos/requirements.md`
> Auditoria estritamente leitora: nenhum artefato da feature foi alterado.

## Resumo

| Severidade | Findings |
|------------|----------|
| CRITICAL | 0 |
| HIGH | 0 |
| MEDIUM | 5 |
| LOW | 5 |
| **Total** | **10** |

## Findings

| ID | Severidade | Eixo | Descrição | Onde está |
|----|------------|------|-----------|-----------|
| A001 | MEDIUM | Cobertura (cenário) | A verificação do cenário "Log sem texto digitado" no PM-0 reprova sempre, mesmo sem vazamento. `grep -ci 'f5' "$LOG"` espera 0, mas o evento `session.start` registra o hash do certificado de assinatura, que contém `f5` (`…ad38f5f4…`). Conferido em 2026-09-16: os 49 logs em `~/Library/Logs/joystick-ai/` contêm a sequência. | `onboarding.md` §1, passo 11; `actions.md`, "Observação da decomposição" |
| A002 | MEDIUM | Coerência com o legado | D-02 muda o número de atalhos de sistema de cinco para seis, mas o delta arquitetural cita só RN-AT-10 e RN-AT-20. Ficam de fora três textos 🟢 que também fixam "cinco": `003 RN-07` ("Cinco atalhos de sistema"), `RN-AT-07` ("`systemShortcut` (5 atalhos)") e o verbete "Atalho de sistema" do glossário ("Um dos cinco atalhos do macOS"). | `roadmap.md` §5; `_reversa_sdd/domain.md` §2 e §3.3; `_reversa_sdd/atalhos/requirements.md` |
| A003 | MEDIUM | Consistência | Os três documentos não indicam o mesmo destino para os resultados dos portões. O critério de pronto do roadmap diz "P-01 a P-05 registradas em `onboarding.md`"; o `onboarding.md` §1 e §3 manda registrar sondas e passos no `actions.md`; o `actions.md` grava as sondas nas notas (T001) e os passos do PM-1 no `onboarding.md` §3 (T015). | `roadmap.md` §10; `onboarding.md` §1 e §3 (fecho de cada tabela); `actions.md` T001 e T015 |
| A004 | MEDIUM | Consistência (identificadores) | "D-01" e "D-03" do `requirements.md` são as dúvidas do esclarecimento, que não têm mais rótulo no documento, e colidem com as decisões D-01 a D-08 do roadmap, que têm outro sentido. O §10 fala do "passo extra escolhido em D-01", e o histórico, de "D-01 a D-03 resolvidas". A origem da primeira premissa do roadmap, "§9, D-01", também não aponta a qual das duas se refere. | `requirements.md` §10 e §11; `roadmap.md` §4 |
| A005 | MEDIUM | Sanidade do actions | A regra de parada da feature contradiz as dependências. Ela diz que, com P-03 ou P-04 reprovadas, "nenhuma ação `T` é executada", mas T001 é justamente a ação que registra a parada. Além disso, T002 e T003 dependem só do PM-0 e continuam elegíveis nesse caso, inclusive a primeira alteração de código (T003). | `actions.md`, "Portões manuais" (Parada da feature), T001 a T003 |
| A006 | LOW | Consistência | D-08 define "dois portões manuais", e o `actions.md` introduz um terceiro, o PM-0B, condicional. O repasso já estava previsto no `onboarding.md` §1, passo 5, mas sem nome de portão. | `roadmap.md` D-08; `actions.md`, "Portões manuais" |
| A007 | LOW | Cobertura (regra) | A RN-09 diz que o app não oculta o teclado ao abrir o editor, mas nenhum passo abre o editor com o teclado visível. O PM-1, passo 5, usa o editor logo depois de o passo 4 ocultar o teclado. Paleta e Return estão cobertos. | `requirements.md` RN-09; `onboarding.md` §3, passos 4 e 5 |
| A008 | LOW | Cobertura (RNF) | O RNF de compatibilidade pede não quebrar o mínimo declarado (macOS 13). Nenhuma decisão registra se isso é aceito sem verificação, e nenhuma ação o confere; só a investigação anota, com 🟡, que só o macOS 26 é verificado. | `requirements.md` §6; `investigation.md` §4; `roadmap.md` §3 |
| A009 | LOW | Cobertura (cenário) | O cenário "Pré-requisito documentado" parte de um Mac em que os ajustes nunca foram feitos, mas A-1 (atalho 162 ativo) já está ativo nesta máquina. Só A-2 é exercitado do zero (PM-0, passo 1; PM-1, passo 11). | `requirements.md` §7; `onboarding.md` §0, §1 e §3; `investigation.md` §2 |
| A010 | LOW | Consistência (contratos) | O roadmap numera a nova integração como I-13, continuando I-01 a I-12 de `architecture.md` §4, mas o arquivo de interface não cita esse identificador no cabeçalho. | `roadmap.md` §5; `interfaces/atalho-de-acessibilidade.md` |

## Findings CRITICAL e HIGH

Nenhum.

## Direção sugerida para os findings MEDIUM

Esta auditoria não corrige nada. As correções cabem ao `/reversa-clarify` ou à edição manual, conforme o caso.

- **A001.** O PM-0 é o próximo ato da feature, por isso este é o item a resolver primeiro. Edite manualmente o passo 11 do `onboarding.md` §1 para excluir `session.start` da contagem, por exemplo `grep -v '"session.start"' "$LOG" | grep -ci 'f5'`. Convém dar o mesmo tratamento a toda contagem por sequência curta.
- **A002.** Edite manualmente o `roadmap.md` §5 para incluir `003 RN-07`, `RN-AT-07` e o glossário entre as regras alteradas. Depois do código, a re-extração ou o `/reversa-sync` deve atualizar esses textos no `_reversa_sdd/`. Não é CRITICAL porque a mudança é intencional e o componente já está declarado como `regra-alterada`: falta só a lista completa das regras afetadas.
- **A003.** Escolha um destino único para os resultados e alinhe o roteiro e o critério de pronto, por edição manual no `roadmap.md` §10 e no `onboarding.md`. Na feature 005, as sondas e o PM-1 ficaram nas notas do `actions.md`, com o detalhe dos passos no `onboarding.md` §3.
- **A004.** Pelo `/reversa-clarify` ou manualmente, troque a menção a "D-01" no `requirements.md` §10 pela referência ao esclarecimento, como "§9, primeira pergunta", e deixe explícita a origem da premissa no `roadmap.md` §4.
- **A005.** Edite manualmente o `actions.md`: restrinja a regra de parada às ações a partir de T002, ou faça T002 e T003 dependerem de T001, para que nada de código comece antes de a decisão sobre as sondas estar registrada.

## Verificações que passaram

### Cobertura

- **RF → decisão:** RF-01 (D-01, D-02, D-08), RF-02 (D-01, P-04), RF-03 (D-01, P-03), RF-04 (D-02, D-07), RF-05 (D-05), RF-06 (D-04), RF-07 (D-06, P-05), RF-08 (D-06), RF-09 (D-05), RF-10 (D-05, RN-AT-14, RN-AT-15). Todos os dez RF têm decisão.
- **Decisão → ação:** D-01 (PM-0, T001), D-02 (T003, T004), D-03 (T005, T012, T013, PM-0B), D-04 (T011), D-06 (T002, T015), D-07 (T006 a T012), D-08 (PM-0, PM-1). D-05 declara que nada muda e é conferida por T014 e pelo PM-1, sem ação órfã.
- **Cenários Gherkin → verificação:** os 15 cenários do §7 têm passo no `onboarding.md`: digitar no terminal (PM-0, passos 5 a 7; PM-1, passo 4), ocultar pelo mesmo botão (PM-0, passo 5; PM-1, passo 4), passo extra (PM-0, passo 9; PM-1, passo 11), atalhos ativos e paleta sem ocultar o teclado (PM-0, passo 8), trocar o botão pelo editor (PM-1, passos 2, 3 e 5), mapeamento padrão (PM-1, passo 1; T011), paleta retém o botão (PM-1, passo 6), modo de identificação (PM-1, passo 7), pré-requisito ausente (PM-1, passo 8), sem Acessibilidade (PM-1, passo 10), desconexão (PM-1, passo 9), digitação a 3 m (PM-0, passo 10), pré-requisito documentado (PM-0, passo 1; PM-1, passo 11, ressalva em A009) e log sem texto (PM-0, passo 11, ressalva em A001; PM-1, passo 12).
- **RNF de desempenho (1 s):** medido no PM-0, passo 5.
- **Mapeamento padrão intacto (RN-10, RF-06):** D-04, T011 e PM-1, passo 1.

### Consistência

- **Termos:** "teclado virtual" é o conceito do requisito, e "Teclado de Acessibilidade" nomeia a escolha técnica (D-01); `accessibilityShortcut`, "atalho de acessibilidade", ID 162, ⌥⌘F5 e `KeyChord.f5 = 96` são idênticos em `roadmap.md`, `data-delta.md`, `interfaces/` e `actions.md`.
- **Identificadores do requirements citados:** RF-01 a RF-10 e RN-01 a RN-11 existem.
- **Identificadores do legado citados:** RN-AT-05, 06, 07, 08, 10, 11, 13, 14, 15, 17, 18, 19, 20 e 22; RN-IN-01, 05, 09 e 10; RN-ED-13; 001 RN-04 e RN-12; 002 RN-02; 003 RN-02, 05, 07, 08 e 14; RI-23; TD-01. Todos existem no `_reversa_sdd/`.
- **Arquivos e âncoras citados:** `code-analysis.md#5.3 Catálogos`, `addenda/prd-l01-ditado-pelo-raycast.md#Pré-requisitos externos do ditado`, `personas.md#Persona 1`, `permissions.md` §2 e §3, `addenda/005-sinais-matematicos.md`, os contratos `003-editor-atalhos/interfaces/config-file.md` e `004-figura-controle-web/interfaces/diagnostic-log.md`, e os scripts `build-app.sh`, `test.sh` e `check-signature.sh` existem.
- **Contratos de `interfaces/`:** o único contrato, "Atalho e Teclado de Acessibilidade do macOS", aparece no `roadmap.md` §5 e §7. Os eventos postados (§3) seguem RN-IN-01 e RN-IN-09, e a leitura da máscara (§2) segue RN-AT-11.
- **Contagens do roteiro:** o PM-0 tem 12 passos, e o PM-1, 13, como declara o `actions.md`; a base de 274 testes coincide entre `investigation.md`, `roadmap.md` §10 e T014.
- **PM-1, passo 12:** `grep -ci 'accessibility'` não tem falso positivo no log vigente (contagem 0).

### Coerência com o legado

- **Decisões e regras 🟢:** D-02 segue RN-AT-10 (leitura no pressionar) e RN-AT-22 (entrada desativada posta o padrão); D-03 estende o precedente de RN-IN-10 sob evidência, com mudança declarada no roadmap §5; D-04 preserva RN-AT-19 e 003 RN-11; D-05 preserva RN-AT-17 e 003 RN-14. A ressalva documental está em A002.
- **Componentes e símbolos citados existem no código:** `SystemShortcut` e `KeyChord` (`ShortcutMapper.swift`), `ShortcutActions.currentChord(for:)`, `ActionPanel` (percorre `SystemShortcut.allCases`), `ActionSummary` (usa `displayName`), `ConfigDocument` (grava `name`), `ShortcutConfigValidation` (usa `SystemShortcut(name:)`), `KeyboardInjector.postKey` (regra `isArrow`), `EventInjector`, `InputRouter`, `PaletteActions`, `EditorViewModel` e `LogEventCatalog`.
- **Componentes de arquitetura:** `shortcuts` e `injection` existem no mapa de módulos da extração; o contrato I-06 (preferências do sistema) é o que D-02 reutiliza.
- **Ausência de `switch` exaustivo:** fora de `ShortcutMapper.swift`, nenhum código trata os casos de `SystemShortcut` um a um; o caso novo não exige outra mudança, como afirma D-02.
- **Testes citados em D-07:** `ShortcutConfigTests.atalhoDeSistemaIdaEVoltaPeloNome`, `ShortcutMapperTests.atalhosDeSistemaLidosDasPreferencias`, `ShortcutConfigValidationTests`, `ConfigDocumentTests`, `ActionSummaryTests` e `ShortcutDefaultsTests` existem.

### Sanidade do actions

- **Dependências:** todas apontam para IDs existentes (T001 a T015) ou para portões definidos no próprio documento (PM-0, PM-0B, PM-1).
- **Paralelismo:** as dez ações `[//]` (T001, T002, T003, T006 a T011 e T013) têm arquivos alvo distintos entre si. As que compartilham arquivo (`ShortcutMapper.swift`: T003, T004, T005; `ShortcutMapperTests.swift`: T007, T012; `onboarding.md`: T002, T015; `actions.md`: T001, T014) estão encadeadas ou fora do `[//]`.
- **Ciclos:** nenhum. O grafo segue PM-0 → T001 a T003 → T004 → T005 a T011 → T012 e T013 → PM-0B → T014 → PM-1 → T015, sem retorno.
- **Maior cadeia:** 6 ações (T003 → T004 → T005 → T012 → T014 → T015), como declarado.
- **Ações condicionais:** T005, T012 e T013, ligadas a D-03, têm regra de dispensa explícita e são as únicas marcadas 🟡 por dependerem da P-01.

## Histórico de alterações

| Data | Alteração | Autor |
|------|-----------|-------|
| 2026-09-16 | Versão inicial gerada por `/reversa-audit` | reversa |
