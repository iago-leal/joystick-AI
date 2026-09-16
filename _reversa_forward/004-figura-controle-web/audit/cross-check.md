# Cross-check: Figura do controle em página web embutida

> Identificador: `004-figura-controle-web`
> Data: `2026-09-15`
> Artefatos analisados: [`requirements.md`](../requirements.md), [`roadmap.md`](../roadmap.md), [`actions.md`](../actions.md)
> Consultados como apoio: `data-delta.md`, `interfaces/figure-bridge.md`, `interfaces/diagnostic-log.md`, `onboarding.md`, `_reversa_sdd/domain.md`, `_reversa_sdd/architecture.md`, `_reversa_sdd/editor/requirements.md`, `_reversa_sdd/adrs/`, e o código em `Sources/` em 2026-09-15
> Este relatório é só leitura: nenhum artefato da feature foi alterado.

## Resumo

| Severidade | Findings |
|------------|----------|
| CRITICAL | 0 |
| HIGH | 0 |
| MEDIUM | 5 |
| LOW | 6 |

Nenhum finding impede o `/reversa-coding`. Os MEDIUM são divergências entre documentos que o `actions.md` já resolveu por uma das opções, ou lacunas de procedimento no portão manual; convém alinhar o `roadmap.md` e o `data-delta.md` por edição manual antes do `/reversa-sync`, para o adendo não herdar a versão antiga.

## Findings

| ID | Severidade | Eixo | Descrição | Onde está |
|----|------------|------|-----------|-----------|
| A001 | MEDIUM | Consistência | O tipo do motivo de falha tem dois nomes e dois lugares: `FigureFailure` no app (`roadmap.md` D-10 e D-14; `data-delta.md` §2) e `FigureFailureReason` no núcleo (`interfaces/diagnostic-log.md` §2). O `actions.md` adotou só o do núcleo (acréscimo "Um só tipo de falha", T002, T011, T015). | `roadmap.md` §3.2 D-10, §3.3 D-14; `data-delta.md` §2; `interfaces/diagnostic-log.md` §2; `actions.md` "Acréscimos" |
| A002 | MEDIUM | Consistência | D-09 encaminha `scrollWheel` ao `enclosingScrollView`, mas o `WKWebView` dentro do `NSHostingView` de `EditorWindowController.makeWindow` pode não ter `enclosingScrollView` direto. T012 percorre a cadeia de respondedores até um `NSScrollView`; T021 ajusta após a sonda P-02. | `roadmap.md` D-09; `actions.md` T012, T021, inconsistência 3 |
| A003 | MEDIUM | Consistência | `interfaces/figure-bridge.md` §3 acrescenta um quarto gatilho de `load_failed` (erro devolvido por `callAsyncJavaScript`), que D-10 não lista. T015 já o inclui, mas o roadmap e a interface divergem sobre quando o evento é emitido. | `roadmap.md` D-10; `interfaces/figure-bridge.md` §3; `actions.md` T015 |
| A004 | MEDIUM | Cobertura | O cenário "Página indisponível" e RF-13 exigem testar o bundle sem o recurso, mas T004 faz o build falhar se `Resources/ControllerFigure/` faltar, e o passo 20 do `onboarding.md` renomeia `index.html` dentro do `.app` já assinado, o que rompe o selo da assinatura (`codesign --verify` falha) e pode impedir a abertura ou derrubar as permissões do TCC durante o teste. Falta um procedimento que remova o recurso e reassine com a mesma identidade (`codesign --force --sign`), preservando o requisito designado. | `requirements.md` §7 "Página indisponível", RF-13; `actions.md` T004; `onboarding.md` §2 passo 20 |
| A005 | MEDIUM | Coerência com o legado | ADR-014 (Aceito) registra "figura do controle com os 18 botões" como parte da decisão pelo SwiftUI. A feature tira a figura do SwiftUI e a põe num `WKWebView`, o que supera parcialmente o ADR, mas o roadmap §5 não lista `_reversa_sdd/adrs/014-editor-swiftui-em-escala-de-tv.md` como afetado nem prevê ADR novo. Não contradiz regra 🟢 do `domain.md`; é lacuna de rastreabilidade para o `/reversa-sync`. | `roadmap.md` §2 e §5; `_reversa_sdd/adrs/014-editor-swiftui-em-escala-de-tv.md` |
| A006 | LOW | Consistência | O roadmap §10 e D-19 falam em "20 cenários"; o `onboarding.md` §2 tem 21 passos (acrescenta a regressão do teclado) e o PM-2 do `actions.md` cita 21. O `requirements.md` §7 tem de fato 20 cenários. | `roadmap.md` §3.5 D-19, §10; `actions.md` PM-2; `onboarding.md` §2 |
| A007 | LOW | Consistência | `data-delta.md` §2 avalia `kind = fixed` antes de `modifier`; `ControllerFigureView.chip` funde os dois em `fixed`. Sem efeito prático, porque a validação recusa botão de apontamento como modificador (`pointerButtonNotAllowed`). T002 e T008 fixam o comportamento. | `data-delta.md` §2; `actions.md` inconsistência 4 |
| A008 | LOW | Cobertura | RF-01, RF-03, RF-04, RF-10 e RN-06 não aparecem por identificador em nenhuma decisão do roadmap, embora estejam cobertos (RF-01 por D-16, RF-03 por D-17, RF-04 por D-08, RF-10 por D-04 e RN-11, RN-06 por D-07 e D-14). A rastreabilidade por ID fica incompleta. | `roadmap.md` §3 |
| A009 | LOW | Sanidade do actions | T029 está marcada `[//]` com arquivo alvo `FigureBridge.swift`, compartilhado com T012 a T015, T020 e T021. Como T029 depende de T026 e as demais já estão concluídas ou são condicionais, não há execução simultânea real, mas a regra do template ("tarefas `[//]` não compartilham arquivo alvo") não é observada à risca. | `actions.md` T029 |
| A010 | LOW | Sanidade do actions | T017 altera `ShortcutsTab.swift` e `EditorRootView.swift`, mas a coluna de arquivo alvo cita só o primeiro; o roadmap §5 lista os dois. | `actions.md` T017; `roadmap.md` §5 |
| A011 | LOW | Cobertura | O passo 21 do `onboarding.md` (cenário "Mensagem desconhecida da página é ignorada") pressupõe o inspetor do WebKit habilitado, mas nenhuma decisão define `isInspectable` (macOS 13.3+) nem o condiciona ao argumento `--debug`; habilitá-lo sem condição contraria o espírito de D-06. | `onboarding.md` §2 passo 21; `roadmap.md` D-06 |

## Impacto e direção de correção

Não há findings CRITICAL nem HIGH. Os MEDIUM pedem alinhamento de texto, não mudança de abordagem:

- **A001, A002, A003:** o `actions.md` já escolheu uma opção para cada um. Para o `roadmap.md`, o `data-delta.md` e o `interfaces/figure-bridge.md` não ficarem com a versão antiga, a correção é edição manual desses arquivos (o `/reversa-plan` não deve ser rodado de novo, pois regeraria tudo). Alternativa: deixar como está e registrar no `legacy-impact.md` durante o `/reversa-coding`.
- **A004:** a lacuna é de procedimento de teste. A direção é ajustar o passo 20 do `onboarding.md` (tarefa já prevista em T027 pelo `/reversa-coding`, ou edição manual agora) para: encerrar o app, remover `Contents/Resources/ControllerFigure/index.html`, reassinar com `codesign --force --timestamp=none --sign "JoystickAI Local Signing" ~/Applications/JoystickAIPoC.app`, confirmar `check-signature.sh` idêntico, executar o cenário e depois rodar `build-app.sh` para restaurar. T004 pode continuar falhando quando a pasta de origem falta, pois o cenário não depende do build.
- **A005:** direção é o `/reversa-sync`, que gera o adendo; convém que o `roadmap.md` §5 cite o ADR-014 como "parcialmente superado" para o adendo o registrar, ou que se crie um ADR-016 retroativo na re-extração.

## Itens verificados que passaram

### Cobertura

- Todos os quinze RF do `requirements.md` §5 têm decisão correspondente no roadmap (RF-01 a RF-10 por D-04, D-07, D-08, D-12, D-16, D-17; RF-11 por D-11; RF-12 por D-17; RF-13 por D-10; RF-14 e RF-15 por D-17 e D-18), ainda que cinco não sejam citados por ID (A008).
- Todas as doze RN do `requirements.md` §4 têm decisão correspondente: RN-01 e RN-02 (D-12, D-16, D-17), RN-03 (D-01, D-06), RN-04 (D-07, D-08, D-12), RN-05 (D-17), RN-06 (D-07, D-14), RN-07 (D-03, D-07), RN-08 (D-11), RN-09 (D-06, D-18), RN-10 (§5 "Inalterados por decisão"), RN-11 (D-04), RN-12 (D-10).
- As dezenove decisões D-01 a D-19 têm ação no `actions.md` (tabela "Correspondência com o roadmap"); D-19 corresponde aos portões PM-1 e PM-2.
- Os vinte cenários Gherkin do `requirements.md` §7 têm decisão e ação: figura fiel, balões e cores (D-16, D-17; T023 a T026); resumo por camada, clique, identificação, edição, problema, sem modificadores, camada some, estado antes da carga (D-07, D-12, D-14; T002, T011, T013, T014); alvo mínimo (D-17; T023); texto do usuário e mensagem desconhecida (D-03, D-07, D-08; T007, T010, T014); sem rede (D-01, D-06; T005, T010, PM-1); página indisponível (D-10; T015, T017, com a ressalva A004); área constante (D-04; T016); tema (D-11; T006, T020); realce e transição (D-17, D-18; T026).
- Os onze RNF do `requirements.md` §6 têm tratamento: desempenho (D-05, D-14, D-18, risco no §9), segurança (D-03, D-06, D-08), privacidade (D-06, D-15), usabilidade (D-17), compatibilidade (D-04, `interfaces/figure-bridge.md` §7), entrega (D-01, D-02), manutenibilidade (D-12, `interfaces/`), testabilidade (D-12, T008), observabilidade (D-15).

### Consistência

- Os identificadores RF e RN citados no roadmap e no `actions.md` existem no `requirements.md`; "RN-14" no roadmap §2 refere-se a "003 RN-14" do legado, e é assim que aparece.
- Os dois contratos de `interfaces/` (`figure-bridge.md`, `diagnostic-log.md`) constam do roadmap §7, e o roadmap declara que `config-file.md` da 003 não muda.
- Terminologia estável nos três documentos: "balão", "linha-guia", "silhueta", "quadro" (reserva de RN-12), "sonda P-01/P-02/P-03", "PM-1/PM-2", "`FigureState`", "`FigureBridge`", "`ControllerFigureWebView`", "escala de TV".
- Medidas coerentes: 830 × 620 (RN-11, D-04, T005, T016), 60 px de acerto (RN-05, D-17, T023), 26 px e 24 px (RN-05, D-17, T006), opacidades 0,55 / 0,28 / 0,25 e contorno de 5 (RN-02, D-17, T006, T025), 150 ms de transição em RF-15 contra 120 ms em D-18 (dentro do limite).

### Coerência com o legado

- Nenhuma decisão contradiz regra 🟢 do `domain.md`: 001 RN-12 (sem rede) respeitada por D-06 e D-03; 003 RN-13 e RN-14 (texto só digita; log sem conteúdo) respeitadas por D-07 e D-15; 003 RN-16 (identificação) intacta, pois `identified(_:)` não muda; 003 RN-10 (arquivo) intacta por RN-10 da feature.
- RN-ED-13 (rolagem só vertical, alvos de 60 pt, janela mínima) e RN-ED-14 (estados e resumos da figura) do `editor/requirements.md` são preservadas por D-09, D-12 e D-17; RN-ED-31 e RF-ED-09 pela ausência de mudança em `identified`.
- Componentes citados existem no código inspecionado: `ControllerFigureView` (`Sources/JoystickAIPoC/Editor/ControllerFigureView.swift:9-70`), `EditorViewModel.hasIssue` (`:85-93`), `select` e `identified` (`:97-105`), `ShortcutsTab`, `EditorRootView`, `EditorWindowController.makeWindow` (`:105-119`), `ActionSummary.text` (`Sources/JoystickCore/Config/ActionSummary.swift:8-21`), `ShortcutConfig.pointerButtons`, `isModifier`, `resolvedAction` (`ShortcutConfig.swift:33-64`), `EditorTarget.trigger/modifier` e `EditorIssue` (`EditorDraft.swift:4-12`), `ButtonID` com 18 casos (`InputEvent.swift:4-13`), `LogEventCatalog.editor*` (`LogEventCatalog.swift:310-327`), `build-app.sh` copiando só binário e `Info.plist`.
- Referências ao `_reversa_sdd/` existem: `architecture.md` §1 a §7 (I-11, TD-01), `code-analysis.md` §8.2 e §8.3, `editor/design.md#Interface` e `#Observabilidade`, `inventory.md` §7, `dependencies.md` §3, `c4-context.md` Fronteiras, ADR-002, ADR-008, ADR-014, `addenda/003-editor-atalhos.md`.
- `WebKit.framework` está no SDK das Command Line Tools em uso (`MacOSX.sdk/System/Library/Frameworks/`), como o roadmap afirma.

### Sanidade do actions

- As 29 ações têm IDs T001 a T029 sem lacuna nem repetição; toda dependência aponta para ID existente ou para PM-1.
- Não há ciclo: as dependências são sempre para IDs menores ou para o portão.
- As tarefas `[//]` da Fase 1 (T001 a T007) e da Fase 2 (T008 a T010) têm arquivos alvo distintos entre si; T001 toca também `EditorLabels.swift`, que nenhuma outra tarefa paralela toca.
- A maior cadeia declarada (16 ações, T002 → T028) confere com as dependências.
- Não há ações de IDE, lint ou PR.
- Os portões PM-1 e PM-2 têm "requer" e "libera" coerentes com as dependências das ações condicionais T020 a T022 e da Fase 4.
