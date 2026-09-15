# Cross-check: Editor de atalhos e comandos

> Identificador: `003-editor-atalhos`
> Data: `2026-09-14` (segunda passada, após a revisão do `actions.md`)
> Artefatos analisados: [`requirements.md`](../requirements.md), [`roadmap.md`](../roadmap.md), [`actions.md`](../actions.md)
> Consultados como apoio: [`data-delta.md`](../data-delta.md), [`interfaces/config-file.md`](../interfaces/config-file.md), [`interfaces/diagnostic-log.md`](../interfaces/diagnostic-log.md), [`onboarding.md`](../onboarding.md), `_reversa_sdd/addenda/001-poc-entrada-ponteiro.md`, `_reversa_sdd/addenda/002-paleta-comandos.md` e o código em `Sources/`
> Este relatório não altera nenhum dos artefatos analisados.

## Resumo

| Severidade | Findings abertos |
|------------|------------------|
| CRITICAL | 0 |
| HIGH | 0 |
| MEDIUM | 5 |
| LOW | 13 |

A primeira passada registrou 2 HIGH e 8 MEDIUM. A revisão do `actions.md` resolveu A001 a A005, e os IDs foram mantidos para rastreabilidade. Não existem `_reversa_sdd/domain.md` nem `_reversa_sdd/architecture.md`; a coerência com o legado foi verificada contra os adendos vigentes das features 001 e 002, contra as regras sob vigilância da 002 (W001 a W012) e contra o código entregue.

## Findings abertos

| ID | Severidade | Eixo | Descrição | Onde está |
|----|------------|------|-----------|-----------|
| A006 | MEDIUM | Cobertura | O RNF de 30 ms no percentil 95 (Must) depende agora da leitura das preferências a cada pressionar (D-11). A mitigação do roadmap (medir `shortcut.triggered` contra `input.button` e mudar a leitura se passar de 30 ms) não virou ação nem passo do PM-2. | `requirements.md` §6; `roadmap.md` §9; `actions.md` T035, T050; `onboarding.md` §2 |
| A007 | MEDIUM | Consistência | A assinatura da fusão diverge: D-07 usa `merge(existing:shortcuts:palette:)`, e o `data-delta.md` usa `merge(existing:document:)`. O `actions.md` adota a segunda sem reflexo no roadmap. | `roadmap.md` D-07; `data-delta.md` §2; `actions.md` T031 |
| A008 | MEDIUM | Consistência | `ShortcutIssue` aparece como `{ path, rule }` em D-05 e com `line` no `data-delta.md`. As regras `syntax` e `unreadable` constam só do contrato de log, embora T033 passe a usar `unreadable`. | `roadmap.md` D-05; `data-delta.md` §2; `interfaces/diagnostic-log.md` §2; `actions.md` T003, T033 |
| A009 | MEDIUM | Consistência | Pelo `data-delta.md`, `keyDown` passaria a carregar botão e camada, o que não cobre `shortcut.triggered` dos tipos `systemShortcut`, `text` e `openPalette`. O `actions.md` cria `ShortcutMapper.lastTrigger`, que nem o roadmap nem o `data-delta.md` preveem. | `data-delta.md` §3; `roadmap.md` D-14; `actions.md` T037, T050 |
| A010 | MEDIUM | Consistência | `editor.activation_failed` está no contrato de log e em `onboarding.md` P-01, mas falta na lista de eventos de D-27. | `interfaces/diagnostic-log.md` §2; `roadmap.md` D-27; `actions.md` T006 |
| A011 | LOW | Consistência | O `actions.md` muda a ordem do roadmap §8: P-04 sai do PM-1 e vai para um PM-1b posterior à integração, e a verificação da gravação através de *link* simbólico passa ao PM-2. A mudança está justificada, mas o roadmap segue com a ordem antiga. | `roadmap.md` §8, §9; `actions.md` ajustes de ordem 2 e 3 |
| A012 | LOW | Cobertura | Nenhum documento de origem define se confirmar "Editar atalhos" altera `lastConfirmed`. O `actions.md` decide que não altera. | `roadmap.md` D-13; `data-delta.md` §3; `actions.md` T012, T019 |
| A013 | LOW | Consistência | `ConfigLoadResult.shortcutsSource` consta do `data-delta.md` e de T033, mas não de D-08. | `data-delta.md` §3; `roadmap.md` D-08 |
| A014 | LOW | Cobertura | O RNF de CPU em repouso sem aumento na detecção de alterações não tem passo de verificação. D-16 evita varredura, mas nenhum portão mede o consumo. | `requirements.md` §6; `roadmap.md` D-16; `onboarding.md` §2 |
| A015 | LOW | Sanidade do actions | T022 pede "nenhuma" explícita na camada Options "nos botões fora de → e ←". Lido ao pé da letra, isso inclui modificadores e botões de apontamento, que T023 proíbe em qualquer camada. T027 detectaria o erro, mas a descrição induz a ele. | `actions.md` T022, T023, T027 |
| A016 | LOW | Consistência | Depois da revisão, T062 restaura pelo `ConfigStore` (T056), como pede D-26. Com isso, `EditorDraft.restoreDefaults` (T046) fica sem uso previsto pela interface, embora T048 o teste. | `roadmap.md` D-20, D-26; `actions.md` T046, T048, T056, T062 |
| A017 | LOW | Cobertura | T059 publica os itens ao painel só por `onItems` em `apply`. Não fica dito que o `PalettePanel` nasce com a paleta vigente, e não com `PaletteDefaults`, quando o arquivo já traz uma paleta ao iniciar. | `actions.md` T004, T052, T059 |
| A018 | LOW | Consistência | D-19 fala em "três abas", mas descreve duas (Atalhos e Paleta) e um rodapé. | `roadmap.md` D-19; `actions.md` T069 |
| A019 | LOW | Consistência | O RF-20 aparece entre o RF-06 e o RF-07 na tabela de requisitos funcionais. | `requirements.md` §5 |
| A020 | LOW | Consistência | O contrato proíbe teclas repetidas em `modifiers` e aceita em `layers` só `base` ou um botão, mas o enumerado de regras do `data-delta.md` não tem regra própria para nenhum dos dois casos. | `interfaces/config-file.md` §2.1; `data-delta.md` §2; `actions.md` T024 |
| A021 | LOW | Cobertura | D-28 prevê que `CommandPaletteTests` cubra uma lista configurada diferente da padrão, e T019 testa só `PaletteDefaults` e a entrada fixa. | `roadmap.md` D-28; `actions.md` T019 |
| A022 | LOW | Cobertura | A lacuna "Intervalo antes do Enter" pede verificação no plano, pois itens com Enter voltam a usar `--palette-enter-delay-ms`. O roadmap não a trata, e o passo 20 do PM-2 não fixa o aplicativo em que o Enter é verificado (a 002 aprovou 0 ms só no Terminal). | `requirements.md` §10; `roadmap.md`; `actions.md` T051; `onboarding.md` §2 passo 20 |
| A023 | LOW | Sanidade do actions | Com a revisão, T062 acumula estado, leitura inicial do `ConfigStore`, operações do rascunho, gravação e restauração com rebase e descarte. Fica no limite do critério de atomicidade (até cinco subpontos), ainda que num único arquivo e num mesmo assunto. | `actions.md` T062 |

Não há finding CRITICAL nem HIGH aberto, por isso não há detalhamento de impacto nesta passada.

## Findings resolvidos na revisão do `actions.md`

| ID | Severidade original | Resolução verificada |
|----|---------------------|----------------------|
| A001 | HIGH | T035 faz `releaseAll()` devolver cada `systemUp` convertido em `keyUp` do acorde pressionado, o que mantém `repeatReleases` e o `InjectionGate` sem alteração; T038 testa `releaseAll` com atalho de sistema segurado; T075 acrescenta ao PM-2 a revogação da Acessibilidade com L2+← segurado. |
| A002 | HIGH | T033 produz `ShortcutIssue` com `rule: unreadable` para arquivo ilegível, acima de 1 MiB ou diretório; T034 testa os dois últimos; T055 trata como inválida toda leitura com `shortcutIssues` não vazio, o que mantém a vigente, conforme `interfaces/config-file.md` §3 e RN-08. |
| A003 | MEDIUM | T055 entrega o `trigger` aos observadores; T062 rebaseia o rascunho após `save()` e `restoreDefaults()` bem-sucedidos; T063 só abre conflito com `trigger: external`. |
| A004 | MEDIUM | T062 lê o estado do `ConfigStore` a cada abertura e exibe `externalInvalid(line)` quando a configuração já está inválida, cobrindo RF-04 e a abertura pelo item de alerta. |
| A005 | MEDIUM | A nova T076, sem dependências, adapta o `onboarding.md` §1 antes do PM-1a, que passa a exigi-la; T075 fica com o §2, o §3 e os ajustes posteriores a T061, e depende de T076. |

## Itens verificados que passaram

### Cobertura

- Os 20 requisitos funcionais (RF-01 a RF-20) têm decisão no roadmap: D-01, D-04 e D-08 (RF-01); D-09 e D-10 (RF-02); D-16 (RF-03); D-05 e D-06 (RF-04); D-07 e D-17 (RF-05); D-18 (RF-06, RF-20); D-13 e D-23 (RF-07); D-21 (RF-08, RF-17); D-20 e D-21 (RF-09, RF-11, RF-12, RF-14); D-22 (RF-10); D-20 e D-23 (RF-13); D-26 (RF-15); D-24 (RF-16); D-25 (RF-18); D-23 (RF-19).
- As 28 decisões (D-01 a D-28) têm ao menos uma ação no `actions.md`.
- As 16 regras de negócio têm decisão, e as de comportamento puro (RN-01 a RN-13) têm teste automatizado previsto (T017 a T048).
- Os 29 cenários Gherkin da seção 7 têm ação correspondente e passo no PM-2 do `onboarding.md`, inclusive "Arquivo inválido" e "Restaurar padrão" após a revisão.
- As lacunas "Texto sem teclado" (sonda P-03), "Formatação do arquivo" (aceita no `data-delta.md` §1) e "Convergência nas specs" (`data-delta.md` §6) estão tratadas.
- As sondas P-01 a P-05 têm portão e ação de registro (T015, T061), como exige o critério de pronto do roadmap §10.
- Todas as linhas da tabela de efeitos de `interfaces/config-file.md` §3 têm ação, inclusive o arquivo ilegível ou acima de 1 MiB (T033, T055).

### Consistência

- Os identificadores citados existem: RF-01 a RF-20, RN-01 a RN-16, D-01 a D-28, P-01 a P-05, as seções dos `interfaces/` e os 29 passos do `onboarding.md`.
- As âncoras citadas no legado existem: `action-mapping.md` §4, §6.1, §7, §9, §11, §12, §15; `app-shell.md` §4, §6.1, §7, §9; adendos 001 e 002, "Resumo da entrega" e "Impacto por artefato da extração"; `investigation.md` §3.3 das features 002 e 003; `backlog-editor.md`.
- Os dois contratos de `interfaces/` estão no roadmap §7, e seus eventos e regras aparecem em D-27 e D-01 a D-08, salvo A008 e A010.
- A terminologia é estável nos três documentos: "Editar atalhos", camada, gatilho, acorde, configuração vigente, rascunho, modo de identificação, "Restaurar padrão", `shortcuts`, `palette`.

### Coerência com o legado

- O mapeamento padrão (RN-11, T022) reproduz o `ShortcutMapper` atual para os 18 botões na base e com L1, L2 e Options segurados isoladamente, incluindo PS na base, com L1 e com L2, e sem efeito com Options (W001).
- A repetição das solturas na retomada da injeção (adendo 001, `pointer-control` EC-01) fica preservada para os atalhos de sistema (A001 resolvido).
- A mudança de precedência entre modificadores (RN-03) está decidida pelo usuário e registrada como regra alterada; a alteração de `ShortcutMapperTests` (W008) tem decisão em D-09 e D-28.
- A lista fixa de 17 itens (W007) passa a padrão por decisão registrada (RN-11, RN-12), sem Enter (W006).
- O painel da paleta segue não ativador (W002, D-13), a paleta aberta continua recebendo só os botões (W003), e a abertura e a aplicação de configuração soltam teclas mantidas (W004, D-12).
- O bloqueio da paleta com a tela de alvos (W011) fica em `PaletteActions.blocked`, não na máquina recriada por T051.
- Continua existindo um único `KeyboardInjector` (W012); nenhuma ação cria outro.
- A revogação de "nunca cria o arquivo" (adendo 001) e de `action-mapping` NG-01 e `app-shell` NG-03 é intencional e está marcada para o `/reversa-sync`.

### Sanidade do actions

- As 76 ações têm IDs contínuos de T001 a T076, sem reciclagem; T076 foi acrescentada ao fim da numeração, na tabela da Fase 1.
- Todas as dependências apontam para IDs existentes ou para os portões PM-1a e PM-1b.
- Não há ciclo de dependência; a maior cadeia tem 14 ações, como declarado no resumo.
- Nenhuma ação `[//]` compartilha arquivo alvo com outra de que não dependa, inclusive nos arquivos secundários e em `onboarding.md` (T076 antes de T075).
- As contagens do resumo conferem: 17, 5, 27, 25 e 2 ações por fase, 42 paralelizáveis.
