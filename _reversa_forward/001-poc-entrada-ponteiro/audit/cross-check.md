# Cross-check: Prova de conceito de entrada do controle e apontamento

> Identificador: `001-poc-entrada-ponteiro`
> Data: `2026-09-14`
> Artefatos analisados: [`requirements.md`](../requirements.md), [`roadmap.md`](../roadmap.md), [`actions.md`](../actions.md)
> Apoio consultado (somente leitura): [`data-delta.md`](../data-delta.md), [`interfaces/`](../interfaces/), [`investigation.md`](../investigation.md), [`onboarding.md`](../onboarding.md), `_reversa_sdd/sdd/*.md`

## Resumo

| Severidade | Findings |
|------------|----------|
| CRITICAL | 0 |
| HIGH | 2 |
| MEDIUM | 9 |
| LOW | 4 |
| **Total** | **15** |

## Findings

| ID | Severidade | Eixo | Descrição | Onde está |
|----|------------|------|-----------|-----------|
| A001 | HIGH | Cobertura | Os critérios de aceite de RF-06 ("no curso máximo, o valor absoluto chega a 1,0") e de RF-08 ("registra X crescente com estado de toque ativo") exigem observar valores de eixo e posições do toque, que o contrato de log proíbe; nenhuma ação produz essa evidência. | `requirements.md` §5 (RF-06, RF-08) e §7 (cenário "Analógico em repouso e no curso máximo"); `interfaces/diagnostic-log.md` §3; `data-delta.md` §3.1; `actions.md` T051; `onboarding.md` §2 itens 6 e 8 |
| A002 | HIGH | Cobertura | RF-03 (adotar como ativo um DualSense já conectado ao iniciar) não tem decisão no roadmap: D-04 trata só dos observadores de conexão e desconexão. A adoção aparece apenas em `actions.md` T049. | `roadmap.md` §3 (D-04, D-09); `requirements.md` §5 RF-03 e §7 cenário "Controle ligado antes da PoC"; `actions.md` T049 |
| A003 | MEDIUM | Consistência | D-11 limita o temporizador de 120 Hz ao analógico esquerdo, mas D-13 diz que a rolagem (analógico direito) compartilha esse temporizador. T057 segue D-13 e liga o temporizador com qualquer dos analógicos, divergindo da letra de D-11. | `roadmap.md` D-11, D-13; `actions.md` T057 |
| A004 | MEDIUM | Consistência | D-15 chama `CGRequestPostEventAccess()` "na primeira execução", o que exige estado persistido entre execuções; `data-delta.md` §4 exclui `PersistedState`. T008 decompõe como "uma vez por processo", o que não é a mesma regra. | `roadmap.md` D-15; `data-delta.md` §4; `actions.md` T008 |
| A005 | MEDIUM | Consistência | RF-24 pede o aviso no log só quando o macOS não permite a supressão; D-23 registra `controller.gesture_suppression` com nível `warn` sempre, de modo que o log não distingue as duas situações. O roadmap já marca a divergência como pendente desta auditoria. | `requirements.md` RF-24 e cenários RF-24; `roadmap.md` D-23; `interfaces/diagnostic-log.md` §3; `actions.md` T052 |
| A006 | MEDIUM | Consistência | RF-26 define faixas só para `touchpadSensitivity` e `stickMaxSpeed`; D-17 e `data-delta.md` §2 acrescentam faixas para outros cinco campos numéricos, o que rejeita valores que o requisito aceitaria (por exemplo, `deadzone` 0,6). | `requirements.md` RF-26; `roadmap.md` D-17; `data-delta.md` §2; `interfaces/config-pointer.md`; `actions.md` T023, T031, T040 |
| A007 | MEDIUM | Consistência | RN-12 afirma que o sistema "não persiste as entradas do controle", mas RF-11 exige gravar cada pressionar e soltar de botão com a depuração ligada, e `TargetRun` grava `l1Held` por tentativa. O roadmap §2 declara RN-12 como respeitada considerando apenas rede e coordenadas. | `requirements.md` RN-12, RF-11; `roadmap.md` §2, D-18; `interfaces/diagnostic-log.md` §3 (`input.button`); `interfaces/target-run-result.md` §3; `actions.md` T050, T066 |
| A008 | MEDIUM | Cobertura | O cenário "Permissões sobrevivem a uma recompilação" pressupõe Acessibilidade e Input Monitoring concedidas; o portão PM-1 e o `onboarding.md` §1 testam só a Acessibilidade e mandam não conceder Input Monitoring. Nenhuma ação ou portão verifica a sobrevivência de Input Monitoring caso P-04 conclua que ele é necessário. | `requirements.md` §7 (RNF de operação); `roadmap.md` D-01, §8 Fase 0; `actions.md` PM-1; `onboarding.md` §1.5 |
| A009 | MEDIUM | Consistência | O contrato diz que a lista numerada de telas é registrada em `targets.screens` "ao iniciar", o que permite escolher `--screen` antes de abrir a tela de alvos; T068 registra o evento só com `--targets`. | `interfaces/target-run-result.md` §1; `interfaces/diagnostic-log.md` §3; `actions.md` T068 |
| A010 | MEDIUM | Consistência | O delta arquitetural inclui `controller-input` EC-01 a EC-06, mas o `requirements.md` §2 lista EC-01, EC-02, EC-03, EC-05 e EC-06, sem EC-04 (detecção de eventos ausentes em 5 s). Nenhuma ação implementa EC-04. | `roadmap.md` §5; `requirements.md` §2; `_reversa_sdd/sdd/controller-input.md` §11 EC-04 |
| A011 | MEDIUM | Sanidade do actions | As colunas de dependência citam PM-0, PM-1 e PM-2, que não são IDs de ação. A convenção está documentada no próprio `actions.md`, mas foge ao formato do template, e um executor que só leia IDs `T` não verá os portões. | `actions.md` T001 a T003, T011, T012, T048, T049, T054 a T056, T072; seção "Portões manuais" |
| A012 | LOW | Consistência | O roadmap §5 cita IDs das specs (`RF-10`, `RF-11`, `EC-01`) no mesmo texto em que o restante do documento usa os IDs do `requirements.md`, e ambos os espaços têm `RF-10` e `RF-11` com significados diferentes. | `roadmap.md` §5; `requirements.md` RF-10, RF-11 |
| A013 | LOW | Consistência | O rótulo de ambiente aparece como "sofá" no `requirements.md` e como `sofa` nos contratos e ações. A diferença é esperada entre texto e valor de argumento, mas não está declarada. | `requirements.md` §7 cenário RF-27; `interfaces/target-run-result.md` §1; `actions.md` T024, T068, T071 |
| A014 | LOW | Consistência | D-23 e T052 suprimem gestos também em `buttonOptions` (Create, conforme D-06), além do PS exigido por RF-24; o acréscimo não tem requisito de origem. | `requirements.md` RF-24; `roadmap.md` D-06, D-23; `actions.md` T052 |
| A015 | LOW | Sanidade do actions | Há paralelismo subutilizado: T005 depende só de T001 e não compartilha arquivo com ações concorrentes, e T073 e T074 são independentes entre si e têm arquivos distintos, mas os três estão marcados `-`. | `actions.md` T005, T073, T074 |

## Impacto e direção dos findings HIGH

### A001

Sem valores de eixo nem posições do toque no log, o avaliador não consegue demonstrar, na forma escrita, que o analógico chega a 1,0 nem que o X do toque cresce. Há só evidências indiretas: a travessia de RF-13 praticamente exige inclinação plena, e o cursor seguindo o dedo em RF-12 sugere X crescente. Os testes T014 e T017 cobrem a lógica, mas não o hardware. A resolução pede uma escolha: reescrever os dois critérios em termos de efeito observável (travessia, direção do cursor, transições `began` e `ended`) ou abrir uma exceção de depuração que registre valores sem persistir coordenadas do cursor. Direção sugerida: `/reversa-clarify` para decidir a forma do critério; se a escolha mexer no contrato de log, `/reversa-plan` para refletir a mudança em D-18 e em `interfaces/diagnostic-log.md`.

### A002

A ação T049 cobre RF-03, mas sem uma decisão que a justifique. Com isso o roadmap perde a rastreabilidade do requisito, e fica em aberto um ponto técnico: com `shouldMonitorBackgroundEvents` ligado, se `GCController.controllers()` já devolve o DualSense ao iniciar ou se é preciso aguardar a notificação de conexão. O cenário "Controle ligado antes da PoC" é Must. Direção sugerida: `/reversa-plan`, para acrescentar a decisão (ou ampliar D-04) e, se couber, um ponto a apurar em `investigation.md` §4.

## Itens verificados sem problema

### Cobertura

- Todos os 27 RF do `requirements.md` têm pelo menos uma ação em `actions.md`, contando os intervalos citados ("RF-01 a RF-04", "RF-15 a RF-18").
- RF-01, RF-02, RF-04 a RF-27 têm decisão correspondente no roadmap, pelo ID ou pelo conteúdo (RF-02 e RF-04 em D-04; RF-07 em D-08; RF-15 a RF-18 em D-10 e D-12; RF-19 em D-12; RF-20 em D-11).
- As 24 decisões D-01 a D-24 aparecem em `actions.md`; D-21 é tratada pelo portão PM-0, por ser ato exclusivo do usuário.
- Os 35 cenários Gherkin têm ação ou portão correspondente, ressalvadas as coberturas parciais de A001 e A008; os de validação manual (RF-25, RNF de operação) dependem de PM-1 e PM-3, com esqueleto de relatório em T013 e ferramentas em T053, T069 a T071.
- Os RNF de desempenho, suavidade, consumo, robustez, compatibilidade, privacidade, observabilidade, acessibilidade e empacotamento têm decisão (D-02, D-11, D-15, D-18, D-19, D-22) e ação ou portão de medição.
- Os riscos R-06 (precisão durante arraste), R-08, R-09 e R-10 são conflitos conhecidos, registrados com mitigação no roadmap e no `onboarding.md`.

### Consistência

- Todos os identificadores RF, RN, D, R e P citados em `roadmap.md` e `actions.md` existem nos documentos de origem (P-01 e P-02 em `investigation.md` §4).
- Os três contratos de `interfaces/` (`config-pointer.md`, `diagnostic-log.md`, `target-run-result.md`) aparecem no roadmap §7 e são implementados por ações identificadas.
- Os 18 identificadores de botão coincidem entre `requirements.md` RF-05, `roadmap.md` D-06, `data-delta.md` §1.1 e `actions.md` T030.
- Os nomes e padrões dos oito campos de `PointerSettings` coincidem entre `requirements.md` RF-26, `data-delta.md` §2, `interfaces/config-pointer.md` §2 e `actions.md` T031.
- Os termos centrais ("controle ativo", "zona morta", "tela de alvos", "precisão", "Acessibilidade", "Input Monitoring") têm o mesmo nome nos três documentos.
- Os nomes de scripts e da variável `JOYSTICK_SIGN_IDENTITY` coincidem entre `roadmap.md` §5, `onboarding.md` §1 e `actions.md` T010 a T012.

### Coerência com o legado

- Não existem `_reversa_sdd/domain.md` nem `_reversa_sdd/architecture.md`; não há regra 🟢 de domínio a contradizer nem componente arquitetural a conferir.
- As specs em `_reversa_sdd/sdd/` não contêm selo 🟢; todas as origens são 🟡 PLANEJADO, coerentes com a nota de confidência do `requirements.md`.

### Sanidade do actions

- As 74 ações têm IDs únicos e sequenciais, de T001 a T074.
- Toda dependência `T` aponta para um ID existente.
- Não há ciclo de dependência.
- Nenhum par de ações marcadas `[//]` compartilha arquivo alvo; os arquivos compartilhados (`AppDelegate.swift` e `poc-tools/main.swift`) só aparecem em ações sequenciais.
- As contagens do resumo (74 ações, 59 paralelizáveis, cadeia de 17) conferem com as tabelas.

## Histórico de alterações

| Data | Alteração | Autor |
|------|-----------|-------|
| 2026-09-14 | Versão inicial gerada por `/reversa-audit` | reversa |
