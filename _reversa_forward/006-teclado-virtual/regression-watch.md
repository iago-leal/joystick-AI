# Regression watch: Teclado virtual chamado pelo controle

> Identificador: `006-teclado-virtual`
> Âncora: legado (`_reversa_sdd/architecture.md`, `_reversa_sdd/domain.md`, extração de 2026-09-15). Os itens do watch principal nascem da seção "Modificadas" do `legacy-impact.md`; só regras originalmente 🟢 entram nele. As regras 🟡 do `requirements.md` e as decisões 🟡 do roadmap, que dependiam das sondas, ficam em "Observações", sem peso de regressão.

## Watch principal

| ID | Origem (arquivo, seção) | Regra esperada após mudança | Tipo de verificação | Sinal de violação |
|----|--------------------------|------------------------------|---------------------|-------------------|
| W001 | `_reversa_sdd/domain.md` §3.3, 003 RN-07; §2, glossário, "Atalho de sistema" | Há seis atalhos de sistema, entre eles o Atalho de Acessibilidade, todos com o acorde lido de `AppleSymbolicHotKeys` no momento do uso. | redação | Re-extração descrevendo "cinco atalhos", ou `SystemShortcut.allCases.count` diferente de 6. |
| W002 | `_reversa_sdd/atalhos/requirements.md`, RN-AT-07 e RN-AT-10 | `systemShortcut` aceita seis nomes; a leitura das preferências cobre os IDs 27, 32, 33, 79, 81 e 162, com o padrão para entrada ausente, desativada ou malformada. | redação | Lista de IDs sem 162, ou `ShortcutMapperTests.atalhosDeSistemaLidosDasPreferencias` e `atalhoDeAcessibilidadeRemapeadoOuDesativado` ausentes ou vermelhos. |
| W003 | `_reversa_sdd/atalhos/requirements.md`, RN-AT-20 | O acorde padrão do atalho de acessibilidade é ⌥⌘F5 (`KeyChord(96, [.option, .command])`). | redação | Padrão diferente de ⌥⌘F5, ou RN-AT-20 sem o atalho de acessibilidade. |
| W004 | `_reversa_sdd/injecao-de-eventos/requirements.md`, RN-IN-10 | As setas (123 a 126) recebem `maskNumericPad` e `maskSecondaryFn`; as teclas F1 a F12 recebem `maskSecondaryFn`, sem `maskNumericPad`; as demais teclas saem só com os modificadores. | presença | `KeyboardInjector.postKey` sem o ramo de `isFunctionKey`, ou ⌥⌘F5 do controle voltando a chegar ao aplicativo em foco como tecla comum. |
| W005 | `_reversa_sdd/atalhos/design.md`, `KeyChord` e `SystemShortcut`; `_reversa_sdd/data-dictionary.md` §3.2 e §3.4; `_reversa_sdd/code-analysis.md` §5.3 | `KeyChord` tem `f5` 96, `functionKeys` (os 12 códigos do grupo `function`) e `isFunctionKey`; `SystemShortcut` tem `accessibilityShortcut` 162, nome `accessibilityShortcut` e rótulo "atalho de acessibilidade". | presença | Membros ausentes, `functionKeys` divergente do catálogo (`ShortcutMapperTests.teclasDeFuncao` vermelho) ou rótulo alterado sem feature que o justifique. |
| W006 | `_reversa_sdd/architecture.md` §4, integrações externas | Existe a integração I-13, Atalho e Teclado de Acessibilidade do macOS: leitura da entrada 162, acorde postado e cliques do ponteiro, com pré-requisito do usuário nos Ajustes. | presença | Re-extração sem a integração, ou o app passando a escrever preferências do sistema ou a pedir permissão nova. |
| W007 | `_reversa_sdd/atalhos/requirements.md`, RN-AT-19; `_reversa_sdd/domain.md` §3.3, 003 RN-11 | O mapeamento padrão não aciona o atalho de acessibilidade em nenhuma camada. | ausência | `.systemShortcut(.accessibilityShortcut)` em `ShortcutDefaults`, ou `ShortcutDefaultsTests.padraoSemAtalhoDeAcessibilidade` removido. |
| W008 | `_reversa_sdd/traceability/code-spec-matrix.md` | Contagens: `ActionSummaryTests` 7, `ConfigDocumentTests` 9, `ShortcutConfigTests` 7, `ShortcutConfigValidationTests` 21, `ShortcutDefaultsTests` 2, `ShortcutMapperTests` 20; total de 280 testes. | redação | Matriz com contagens anteriores sem feature que as reduza, ou algum dos testes nomeados no `legacy-impact.md` removido. |

## Observações

Regras 🟡 do `requirements.md` e decisões 🟡 do `roadmap.md`, conferidas nos portões manuais; sem peso de regressão até uma re-extração as confirmar como 🟢.

| ID | Origem (arquivo, seção) | Regra esperada | Tipo de verificação | Sinal de violação |
|----|--------------------------|----------------|---------------------|-------------------|
| O001 | `requirements.md` RF-01, RN-02; `roadmap.md` D-01 | Com só o Teclado de Acessibilidade na lista do atalho, o botão configurado alterna o teclado; com mais recursos, abre o painel de escolha. | presença | O botão não exibe teclado nem painel com o pré-requisito cumprido. |
| O002 | `requirements.md` RF-02, RF-03, RN-05 | Os cliques de R1 no teclado digitam no aplicativo em foco, que continua em foco com o teclado visível. | presença | Texto indo ao teclado ou a outro aplicativo; aplicativo em foco trocado ao exibir o teclado. |
| O003 | `requirements.md` RF-05, RN-06, RN-09 | Com o teclado visível, atalhos e paleta operam e a paleta não o oculta. | presença | Teclado ocultado ao abrir a paleta ou ao acionar um atalho. |
| O004 | `requirements.md` RF-07, RN-11 | Redimensionado pelo sistema, o teclado permite digitar do sofá. | presença | Relato de teclas pequenas demais sem ajuste possível. |
| O005 | `roadmap.md` D-03; sonda P-01 | O ⌥⌘F5 injetado só é reconhecido pelo sistema com `maskSecondaryFn`. | presença | Nova versão do macOS aceitando ou recusando o acorde de outra forma; reavaliar W004. |
| O006 | `requirements.md` RF-10; §7, "Desconexão com o teclado visível" e "Sem permissão de Acessibilidade" | Nenhum modificador preso ao desconectar o controle ou revogar a permissão com o teclado visível. | presença | ⌥ ou ⌘ presos após a desconexão; não verificado em hardware nesta feature (PM-1, passos 9 e 10, não relatados). |

Desfecho dos portões (2026-09-16): O001 aprovada nos dois caminhos (painel no PM-0B, alternância direta com A-2 no relato "funcionou"); O002 aprovada (P-03, P-04); O003 aprovada pelo log do passo 8; O004 aprovada pelo relato geral ("ficou ótimo"); O005 confirmada pela reprovação sem a máscara e aprovação com ela; O006 sem verificação em hardware.

## Histórico de re-extrações

## Arquivadas
