# Adendo: Figura do controle em página web embutida

> Identificador: `004-figura-controle-web`
> Data: 2026-09-15
> Cenário: legado

## Vigência

Vigente desde 2026-09-15.

## Resumo da entrega

A feature substitui a figura esquemática do controle na aba Atalhos do editor, até então 18 fichas retangulares em SwiftUI sobre um retângulo cinza, por uma representação plana do DualSense desenhada numa página web local (HTML, CSS e JavaScript sem bibliotecas) embutida na janela por um `WKWebView`. Os estados visuais (fixo, modificador, herdado, problema, selecionado) e o resumo da ação por camada são os mesmos; toda a lógica continua no rascunho e no modelo do editor, e a página apenas apresenta o estado que recebe e devolve o botão clicado. Arquivo de configuração, validação, modelo do rascunho e esquema do log não mudam.

Sincronização parcial: 18 das 29 ações de `actions.md` estão concluídas (T001 a T018, rodada 1 de 2026-09-15). O que está entregue é o núcleo da feature: o contrato `FigureState` no `JoystickCore`, a ponte `FigureBridge` com o `WKWebView`, a página mínima de três botões (✕, L1 e Touchpad) e a troca da figura na aba Atalhos, com `swift build` e `./scripts/test.sh` verdes (270 testes). Pendências: T019 (remoção de `ControllerFigureView.swift`, ainda presente e sem uso, aguardando autorização do usuário), o portão manual PM-1 (sondas de tema, rolagem e isolamento com a página mínima), as reservas condicionais T020 a T022, a Fase 4 (silhueta e 18 botões, T023 a T026) e a Fase 5 (T027 a T029). Enquanto a Fase 4 não fechar, a figura exibida tem só três botões.

## Impacto por artefato da extração

| Artefato | Seção | Tipo de impacto | Delta |
|----------|-------|-----------------|-------|
| `_reversa_sdd/architecture.md` | `#3. Camadas e dependências` | componente-novo | O `JoystickCore` ganha `FigureState`, `FigureButton`, `FigureFailureReason` (`Config/FigureState.swift`) e `ButtonID.displayName` (`Config/ButtonLabels.swift`); continua importando só `Foundation`. O `editor` do app ganha `FigureBridge` e `ControllerFigureWebView`; o `app-shell` segue como único ponto de montagem, criando a ponte em `AppDelegate`. |
| `_reversa_sdd/architecture.md` | `#4. Integrações externas` | delta-de-contrato-externo | Entra uma integração nova, WebKit (processo WebContent), hospedeira da figura: `WKWebsiteDataStore.nonPersistent()`, carga por `loadFileURL` restrita a `Contents/Resources/ControllerFigure/`, navegação cancelada fora do `index.html`, `callAsyncJavaScript("figure.render(state)")` no sentido app → página e `messageHandlers.figure` como único canal página → app. Sem rede. Contrato em `interfaces/figure-bridge.md` da feature. |
| `_reversa_sdd/architecture.md` | `#6. Qualidade e verificação` | regra-nova | O catálogo fechado do log continua garantido por `LogEventCatalogTests`; soma-se `FigureAssetsTests`, que lê `Resources/ControllerFigure/` e recusa referência externa, subrecurso fora dos irmãos, ausência da CSP e APIs de marcação, armazenamento, rede ou animação em `figure.js`. TD-01 permanece: `FigureBridge` não tem teste automatizado. |
| `_reversa_sdd/domain.md` | `#3.3 Atalhos, configuração e editor (003)` | regra-nova | Regra nova do editor: sem figura (recurso ausente, falha de carga, erro no script ou duas quedas do WebContent em 60 s), a aba mostra um quadro de 830 × 620 pt com "A figura do controle não pôde ser carregada; reinstale o app.", o painel e a identificação pelo controle seguem operáveis, e o log recebe `editor.figure_unavailable { reason }` uma vez por abertura. 003 RN-02, RN-14 e RN-16 continuam intactas. |
| `_reversa_sdd/domain.md` | `#2. Glossário` | regra-alterada | "Modo de identificação" e "Escala de TV" valem como antes, mas a figura em que a seleção aparece é a página web; os tamanhos da figura são rótulo de 26 px, resumo de 24 px e área de acerto de 60 × 60 px por botão. |
| `_reversa_sdd/editor/design.md` | `#Interface` (`EditorViewModel`) | regra-alterada | `EditorViewModel` ganha `figureState: FigureState`, derivado a cada leitura de `draft`, `selectedLayer`, `selectedButton` e `draft.issues`, e `@Published figureUnavailable: FigureFailureReason?`, zerado em `prepareForOpen` e republicado pela ponte se a falha persistir. `select`, `identified` e `hasIssue` não mudam. |
| `_reversa_sdd/editor/design.md` | `#Interface` (`ShortcutsTab`) | componente-extinto | As fichas de 160 × 96 pt de `ControllerFigureView` deixam de compor a aba; `ShortcutsTab` recebe o `FigureBridge` via `EditorRootView(model:figure:)` e mostra `ControllerFigureWebView(bridge:)` em 830 × 620 pt ou o quadro de RN-12. O arquivo `ControllerFigureView.swift` ainda existe sem uso até T019. |
| `_reversa_sdd/editor/design.md` | `#Decisões de Design Identificadas` | regra-alterada | "Figura com resumo por camada (003 D-21)" permanece como regra, mas a evidência passa de `ControllerFigureView.swift:4-8` para `FigureState.swift`, `FigureBridge.swift`, `ShortcutsTab.swift` e `Resources/ControllerFigure/`. |
| `_reversa_sdd/editor/design.md` | `#Observabilidade` | delta-de-contrato-externo | Evento novo `editor.figure_unavailable`, nível `warn`, campo `reason` em `resource_missing`, `load_failed` ou `process_terminated`; `logSchema` segue 1. Contrato em `interfaces/diagnostic-log.md` da feature. |
| `_reversa_sdd/code-analysis.md` | `#8.3 Interface` | regra-alterada | A descrição funcional da figura (830 × 620 pt, 18 botões, resumo por camada, cinco estados) continua válida, mas a implementação é a página `Resources/ControllerFigure/` desenhada pelo `WKWebView`; nesta sincronização a página tem três botões, e os 18 chegam na Fase 4. `ButtonID.displayName` saiu de `EditorLabels.swift` para o núcleo. |
| `_reversa_sdd/inventory.md` | `#7. Build, assinatura e distribuição` | delta-de-contrato-externo | `build-app.sh` passa a copiar `Resources/ControllerFigure/` (`index.html`, `figure.css`, `figure.js`) para `Contents/Resources/ControllerFigure/` antes do `codesign`, falhando com mensagem se a pasta ou um arquivo faltar; a mesma assinatura sela os recursos. `Package.swift` e `Info.plist` não mudam. |
| `_reversa_sdd/dependencies.md` | `#3. Frameworks do sistema por alvo` | delta-de-contrato-externo | `JoystickAIPoC` importa `WebKit` (só em `FigureBridge.swift`); `JoystickCore` e `poc-tools` seguem sem framework além de `Foundation`. |

## Regras sob vigilância

W001 a W010 no watch principal e O001 a O005 em "Observações", em [`_reversa_forward/004-figura-controle-web/regression-watch.md`](../../_reversa_forward/004-figura-controle-web/regression-watch.md). W010 (ausência de `ControllerFigureView.swift`) só passa a valer depois de T019.

## Fontes

- `_reversa_forward/004-figura-controle-web/legacy-impact.md`
- `_reversa_forward/004-figura-controle-web/regression-watch.md`
- `_reversa_forward/004-figura-controle-web/requirements.md`
- `_reversa_forward/004-figura-controle-web/progress.jsonl`
- `_reversa_forward/004-figura-controle-web/actions.md` (notas da rodada 1)
- `_reversa_forward/004-figura-controle-web/interfaces/figure-bridge.md`
- `_reversa_forward/004-figura-controle-web/interfaces/diagnostic-log.md`
