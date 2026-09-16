# Actions: Figura do controle em página web embutida

> Identificador: `004-figura-controle-web`
> Data: `2026-09-15`
> Roadmap: `_reversa_forward/004-figura-controle-web/roadmap.md`

## Resumo

| Métrica | Valor |
|---------|-------|
| Total de ações | 29 |
| Paralelizáveis (`[//]`) | 11 |
| Maior cadeia de dependência | 16 (T002 → T011 → T012 → T013 → T014 → T015 → T016 → T017 → T018 → T019 → T023 → T024 → T025 → T026 → T027 → T028) |

## Convenções desta decomposição

### Portões manuais

Passagens que dependem de ato humano não recebem ID `T`; aparecem como `PM-n` na coluna de dependências. O `/reversa-coding` deve parar ao alcançar um portão e só seguir quando o usuário confirmar o resultado.

| Portão | Ato do usuário | Requer | Referência | Libera |
|--------|----------------|--------|------------|--------|
| PM-0 | Liberar a escrita fora das pastas do Reversa em `.reversa/reversa-config.json`. **Já cumprido:** `allowLegacyEdits: true` com `allowedPaths` vazio (liberação irrestrita), a reler na ativação do `/reversa-coding`. | - | `CLAUDE.md`, roadmap §2 | Todas as ações `T` |
| PM-1 | Compilar e instalar (`scripts/build-app.sh`); executar P-01 (tema e fundo), P-02 (rolagem, foco do teclado e clique direito) e P-03 (isolamento, assinatura e permissões) com a página mínima de três botões, conforme `onboarding.md` §1. | T001 a T019 | D-02, D-06, D-09, D-11, D-19 | T020, T021, T022 e a Fase 4 |
| PM-2 | Roteiro completo do `onboarding.md` §2 (21 passos) na TV a 3 m, com resultados anotados nas notas de execução, inclusive a medição dos 500 ms. | Todas as ações `T` | roadmap §10, `onboarding.md` §2 | Critério de pronto |

A maior cadeia conta apenas ações `T`.

### Correspondência com o roadmap

| Decisões do roadmap | Ações |
|---------------------|-------|
| D-01, D-02 (recurso e bundle) | T004, T005, T006, T007, PM-1 |
| D-03 (teste dos recursos) | T010 |
| D-04, D-05, D-06, D-09 (hospedagem) | T012, T016, T018, T021 |
| D-07, D-08 (ponte) | T013, T014 |
| D-10, D-15 (falhas e log) | T003, T009, T011, T015, T017 |
| D-11 (tema) | T006, T020 |
| D-12, D-13 (núcleo) | T001, T002, T008 |
| D-14 (modelo) | T011, T013 |
| D-16, D-17, D-18 (página completa) | T023, T024, T025, T026 |
| D-19 (portões) | PM-1, PM-2, T027 |

A Fase 1 e a Fase 3 desta decomposição correspondem à "Fase 0" do roadmap (página mínima e sondas); a Fase 4 é o desenho completo, que só começa depois do PM-1, porque as sondas podem mudar a estrutura da página (arquivo único inline, D-06) e a altura útil (D-09).

### Arquivos compartilhados e blocos de compilação

Ações que tocam o mesmo arquivo são sequenciais: `index.html` (T005, T022, T023), `figure.css` (T006, T025, T026), `figure.js` (T007, T024), `FigureBridge.swift` (T012 a T015, T020, T021), `EditorViewModel.swift` (T011), `ShortcutsTab.swift` (T017), `AppDelegate.swift` (T018), `onboarding.md` (T027).

O pacote deve compilar (`swift build`) ao fim de cada ação, e quem altera uma assinatura corrige os pontos de chamada na mesma ação. `./scripts/test.sh` deve passar ao fim de cada ação de teste. Única exceção em bloco: entre T017 e T019, `ControllerFigureView.swift` ainda existe sem uso, o que compila; T019 o remove.

### Acréscimos da decomposição

Detalhes que o roadmap deixa implícitos e que a decomposição fixa:

- **Página mínima da Fase 1 (D-19).** `index.html`, `figure.css` e `figure.js` nascem já com a estrutura definitiva (CSP, `color-scheme`, `<svg viewBox="0 0 830 620">`, camada de balões, delegação de clique, `figure.render`) mas com apenas três grupos: `cross`, `l1` e `touchpadClick`. A Fase 4 acrescenta os outros quinze e a silhueta completa sem reescrever a estrutura.
- **Um só tipo de falha (D-10, D-15).** O motivo da falha é um único `enum FigureFailureReason: String, Sendable` no núcleo (`resourceMissing`, `loadFailed`, `processTerminated`, com `rawValue` em `snake_case` para o log). `EditorViewModel.figureUnavailable` é `FigureFailureReason?`; não há `FigureFailure` duplicado no app. Ver inconsistência 1.
- **Registro único por abertura (D-10).** `FigureBridge` guarda `reportedFailure: Bool`, zerado por `prepareForOpen` do modelo via `figureUnavailable = nil`; o log só sai quando `figureUnavailable` passa de `nil` para um motivo.
- **Área de acerto (D-17).** Cada grupo tem um `<rect class="hit">` transparente de ao menos 60 × 60 px centrado no desenho, com `pointer-events: all`, além do balão; o `click` é resolvido por `event.target.closest('[data-button]')`.
- **Comentários de cabeçalho.** Como nos arquivos da feature 003, cada arquivo novo abre com um comentário que cita `004-figura-controle-web` e as decisões que implementa.

### Inconsistências encontradas ao decompor

Nenhuma bloqueia a execução; todas foram resolvidas pela opção indicada, mas convém revisá-las no `/reversa-audit`.

1. **Tipo do motivo de falha.** D-10 e `data-delta.md` §2 colocam `FigureFailure` em `FigureBridge.swift`; `interfaces/diagnostic-log.md` §2 coloca `FigureFailureReason` no núcleo, para o catálogo do log ficar fechado. Adotado só o tipo do núcleo, usado também pelo modelo (acréscimo acima).
2. **Contagem de cenários.** O roadmap §10 fala em 20 cenários do `requirements.md` §7; o `onboarding.md` §2 tem 21 passos, porque acrescenta a regressão do teclado (passo 14). A PM-2 usa os 21 passos.
3. **Rolagem encaminhada.** D-09 cita `enclosingScrollView`; o `WKWebView` dentro do `NSHostingView` pode não ter `enclosingScrollView` direto. T012 percorre `nextResponder` até achar um `NSScrollView` ou o fim da cadeia; T021 ajusta se a sonda P-02 reprovar.
4. **Ordem de `kind`.** `data-delta.md` §2 avalia `fixed` antes de `modifier`, o que importa só se um botão de apontamento for modificador, caso que a validação recusa (`pointerButtonNotAllowed`). T002 mantém a ordem do `ControllerFigureView.chip` atual (`fixed` = apontamento ou modificador, depois desdobrado) e o teste de T008 fixa o comportamento.

## Fase 1, Preparação

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| [//] T001 | Mover a extensão `ButtonID.displayName` de `EditorLabels.swift` para `Sources/JoystickCore/Config/ButtonLabels.swift`, pública, com os mesmos 18 textos; remover a extensão do app e manter `EditorLabels.layerName` funcionando (D-13). | - | `[//]` | `Sources/JoystickCore/Config/ButtonLabels.swift` | 🟢 | `[X]` |
| [//] T002 | Criar `FigureState`, `FigureButton`, `FigureButton.Kind` e `FigureFailureReason` (`Codable`, `Equatable`, `Sendable`) com o construtor `FigureState(config:layer:selected:issues:)` que percorre `ButtonID.allCases` e reproduz as regras de `ControllerFigureView.chip` e `EditorViewModel.hasIssue` (`data-delta.md` §2, D-12). | - | `[//]` | `Sources/JoystickCore/Config/FigureState.swift` | 🟢 | `[X]` |
| [//] T003 | Acrescentar `LogEventCatalog.editorFigureUnavailable(reason: FigureFailureReason)` produzindo `editor.figure_unavailable`, nível `warn`, campo `reason` em `snake_case` (`interfaces/diagnostic-log.md` §2, D-15). | - | `[//]` | `Sources/JoystickCore/Log/LogEventCatalog.swift` | 🟢 | `[X]` |
| [//] T004 | Em `build-app.sh`, copiar `Resources/ControllerFigure/` para `Contents/Resources/ControllerFigure/` na montagem, antes do `codesign`, falhando com mensagem se a pasta de origem não existir; manter `codesign --verify --strict` (D-01, D-02). | - | `[//]` | `scripts/build-app.sh` | 🟢 | `[X]` |
| [//] T005 | Criar `index.html` mínimo: `<meta charset>`, `<meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'self'; style-src 'self'">`, `<meta name="color-scheme" content="light dark">`, `<link>` para `figure.css`, `<svg viewBox="0 0 830 620">` com o quadro arredondado, uma silhueta provisória e três grupos `[data-button]` (`cross`, `l1`, `touchpadClick`) com desenho, `rect.hit` e `line` de guia, uma `div.balloons` com três balões, e `<script src="figure.js">` no fim (D-06, D-16, D-17). | - | `[//]` | `Resources/ControllerFigure/index.html` | 🟡 | `[X]` |
| [//] T006 | Criar `figure.css` mínimo: `:root { color-scheme: light dark }`, `html, body` em 830 × 620 px com `overflow: hidden`, `background: transparent`, `user-select: none`, fonte `-apple-system`, cores de sistema (`Canvas`, `CanvasText`, `AccentColor`, `-apple-system-secondary-label`, `-apple-system-red`) com reservas, quadro de 48 px em `color-mix(in srgb, CanvasText 8%, transparent)`, classes `is-fixed`, `is-modifier`, `is-inherited`, `is-problem`, `is-selected` com os valores de `ControllerFigureView` (0,28; 0,55; 0,25; contorno de 5 px), rótulo 26 px negrito e resumo 24 px com `-webkit-line-clamp: 2` (D-11, D-17). | - | `[//]` | `Resources/ControllerFigure/figure.css` | 🟡 | `[X]` |
| [//] T007 | Criar `figure.js` mínimo: objeto global `figure` com `render(state)` que, para cada item de `state.buttons` com `id` conhecido, escreve `label` e `summary` por `textContent` e aplica as classes de estado por `classList`; delegação de `click` no `document` por `closest('[data-button]')` enviando `window.webkit.messageHandlers.figure.postMessage({ button: id })`; `contextmenu` e `dragstart` cancelados; sem `innerHTML`, temporizadores ou armazenamento (D-07, D-08, D-18). | - | `[//]` | `Resources/ControllerFigure/figure.js` | 🟢 | `[X]` |

## Fase 2, Testes

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| [//] T008 | Criar `FigureStateTests` com os nove testes de `data-delta.md` §4: ordem e contagem, padrão na base, camada L2, problema, seleção, sem modificadores, texto do usuário intacto, instantâneo das chaves codificadas e rótulos dos 18 botões. | T001, T002 | `[//]` | `Tests/JoystickCoreTests/FigureStateTests.swift` | 🟢 | `[X]` |
| [//] T009 | Acrescentar `editorFigureUnavailable(reason: .resourceMissing)` a `LogEventCatalogTests.sampleEvents` e um teste de que `reason` codifica como `resource_missing`. | T003 | `[//]` | `Tests/JoystickCoreTests/LogEventCatalogTests.swift` | 🟢 | `[X]` |
| [//] T010 | Criar `FigureAssetsTests`: resolve `Resources/ControllerFigure/` por `#filePath`; afirma que os três arquivos existem, que nenhum contém `http://`, `https://` ou `//` como início de URL em `src`, `href`, `url(` ou `@import`, que `<script src>` e `<link href>` apontam só para os irmãos, que `index.html` tem a `<meta http-equiv="Content-Security-Policy">`, e que `figure.js` não usa `innerHTML`, `outerHTML`, `insertAdjacentHTML`, `document.write`, `eval`, `localStorage`, `sessionStorage`, `indexedDB`, `fetch`, `XMLHttpRequest`, `WebSocket`, `setInterval` nem `requestAnimationFrame` (D-03, RN-09). | T005, T006, T007 | `[//]` | `Tests/JoystickCoreTests/FigureAssetsTests.swift` | 🟡 | `[X]` |

## Fase 3, Núcleo

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T011 | Em `EditorViewModel`, acrescentar `var figureState: FigureState` calculada de `draft.document.shortcuts`, `selectedLayer`, `selectedButton` e `draft.issues`, e `@Published var figureUnavailable: FigureFailureReason?`, zerada em `prepareForOpen`; `select` e `identified` inalterados (D-14). | T002 | - | `Sources/JoystickAIPoC/Editor/EditorViewModel.swift` | 🟢 | `[X]` |
| T012 | Criar `FigureBridge.swift` com a subclasse `FigureWebView: WKWebView` (`scrollWheel(with:)` encaminhado ao primeiro `NSScrollView` da cadeia de respondedores, `acceptsFirstResponder` falso, `menu(for:)` nulo) e a classe `FigureBridge: NSObject` na main thread que configura o `WKWebView` (`WKWebsiteDataStore.nonPersistent()`, `javaScriptCanOpenWindowsAutomatically = false`, `allowsMagnification = false`, `allowsBackForwardNavigationGestures = false`, `underPageBackgroundColor = .clear`), localiza `index.html` por `Bundle.main.url(forResource:withExtension:subdirectory:)`, carrega por `loadFileURL(_:allowingReadAccessTo:)` e cancela em `decidePolicyFor(navigationAction:)` toda navegação fora desse URL (D-04, D-06, D-09, D-11). | T011 | - | `Sources/JoystickAIPoC/Editor/FigureBridge.swift` | 🟡 | `[X]` |
| T013 | Em `FigureBridge`, assinar `model.objectWillChange.receive(on: RunLoop.main)`, guardar `lastSent: FigureState?` e `isLoaded`, e enviar `figureState` por `callAsyncJavaScript("figure.render(state)", arguments: ["state": object], in: nil, in: .page)` só quando difere do último enviado e a página já terminou (`webView(_:didFinish:)` reenvia o último estado guardado) (D-07, D-14). | T012 | - | `Sources/JoystickAIPoC/Editor/FigureBridge.swift` | 🟢 | `[X]` |
| T014 | Em `FigureBridge`, registrar o `WKScriptMessageHandler` de nome `figure` e tratar `userContentController(_:didReceive:)`: só dicionário com `button` string reconhecida por `ButtonID(rawValue:)` chama `model.select`; todo o resto é ignorado sem log (D-08). | T013 | - | `Sources/JoystickAIPoC/Editor/FigureBridge.swift` | 🟢 | `[X]` |
| T015 | Em `FigureBridge`, tratar falhas: recurso ausente sem criar o `WKWebView` (`resourceMissing`), `didFailProvisionalNavigation`/`didFail` e erro de `callAsyncJavaScript` (`loadFailed`), `webViewWebContentProcessDidTerminate` com uma recarga e `processTerminated` na segunda queda em 60 s; publicar em `model.figureUnavailable` e registrar `editor.figure_unavailable` uma vez por abertura (D-10, D-15). | T014 | - | `Sources/JoystickAIPoC/Editor/FigureBridge.swift` | 🟡 | `[X]` |
| T016 | Criar `ControllerFigureWebView: NSViewRepresentable` que devolve `bridge.webView` em `makeNSView`, não faz nada em `updateNSView` e tem `.frame(width: 830, height: 620)` fixo (D-04, D-05). | T015 | - | `Sources/JoystickAIPoC/Editor/ControllerFigureWebView.swift` | 🟢 | `[X]` |
| T017 | Em `ShortcutsTab`, substituir `ControllerFigureView(model:)` por `ControllerFigureWebView(bridge:)` ou, com `model.figureUnavailable != nil`, por um quadro de 830 × 620 pt com o texto "A figura do controle não pôde ser carregada; reinstale o app." em `EditorMetrics.body`; `EditorRootView` passa a receber e repassar o `bridge` (D-10). | T016 | - | `Sources/JoystickAIPoC/Editor/ShortcutsTab.swift` | 🟢 | `[X]` |
| T018 | Em `AppDelegate`, criar `FigureBridge(model:log:)` ao lado de `EditorViewModel` e entregá-lo a `EditorRootView(model:figure:)` no fechamento de conteúdo do `EditorWindowController` (D-05). | T017 | - | `Sources/JoystickAIPoC/App/AppDelegate.swift` | 🟢 | `[X]` |
| T019 | Remover `ControllerFigureView.swift` e confirmar por `grep` que não resta referência a `ControllerFigureView`; `swift build` e `./scripts/test.sh` verdes. Ao concluir, parar no PM-1. | T018 | - | `Sources/JoystickAIPoC/Editor/ControllerFigureView.swift` | 🟢 | `[X]` |
| T020 | **Condicional, só se P-01 reprovar:** em `FigureBridge`, observar `effectiveAppearance` da janela por KVO e chamar `figure.setTheme("dark" \| "light")`; em `figure.js`, `setTheme` alterna a classe `theme-dark` no `:root`, e `figure.css` passa a derivar as cores dessa classe (reserva de D-11). | PM-1 | - | `Sources/JoystickAIPoC/Editor/FigureBridge.swift` | 🟡 | `[X]` |
| T021 | **Condicional, só se P-02 reprovar:** ajustar `FigureWebView.scrollWheel` (alvo do encaminhamento, ou `nextResponder` explícito definido pelo representable) e `acceptsFirstResponder` conforme o achado da sonda (D-09). | PM-1 | - | `Sources/JoystickAIPoC/Editor/FigureBridge.swift` | 🟡 | `[X]` |
| T022 | **Condicional, só se P-03 reprovar no passo 4:** transformar a página em `index.html` único com CSS e JS inline e CSP `default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'`; ajustar `FigureAssetsTests` para o arquivo único (reserva de D-06). | PM-1 | - | `Resources/ControllerFigure/index.html` | 🟡 | `[X]` |

## Fase 4, Integração

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T023 | Em `index.html`, desenhar a silhueta plana do DualSense (cerca de 430 × 300 px ao centro) e os 18 grupos `[data-button]` com as formas e posições de RN-01 (L1/R1 sobre L2/R2 nos ombros, direcional à esquerda, △ ○ ✕ □ à direita, touchpad ao centro com Create e Options ao lado, PS abaixo, L3 e R3 nas hastes), cada um com desenho, rótulo em `<text>`, `rect.hit` de ao menos 60 × 60 px e `line` de guia; 18 balões na `div.balloons` (D-16, D-17). | T019, PM-1 | - | `Resources/ControllerFigure/index.html` | 🟡 | `[X]` |
| T024 | Em `figure.js`, criar a tabela de posições dos 18 balões (coluna esquerda L1, L2, ↑, ←, ↓, →, L3; coluna direita R1, R2, △, ○, ✕, □, R3; faixa superior Create, Touchpad, Options; faixa inferior PS; balões de 190 × 64 px) e, na carga, posicionar balões e calcular as linhas-guia entre cada botão e seu balão, sem sobreposição (D-16). | T023 | - | `Resources/ControllerFigure/figure.js` | 🟡 | `[X]` |
| T025 | Em `figure.css`, completar os cinco estados sobre botão e balão em conjunto (`is-selected` com contorno `AccentColor` de 5 px em ambos, `is-problem` com preenchimento vermelho a 25 % e contorno vermelho, `is-fixed`/`is-modifier` neutros a 28 %, `is-inherited` com resumo a 55 %), e o estilo dos balões e linhas-guia nos dois temas com contraste ≥ 4,5:1 (D-17). | T023 | - | `Resources/ControllerFigure/figure.css` | 🟢 | `[X]` |
| T026 | Em `figure.css`, cores dos símbolos △ verde, ○ vermelho, ✕ azul e □ rosa com contraste ≥ 4,5:1 nos dois temas e contorno de seleção visível sobre elas (RF-12); realce `:hover` de 3 px a 40 % (RF-14); `transition: 120ms` em contorno e opacidade, desligada sob `@media (prefers-reduced-motion: reduce)` (RF-15, D-17, D-18). | T025 | - | `Resources/ControllerFigure/figure.css` | 🟡 | `[X]` |

## Fase 5, Polimento

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T027 | Atualizar `onboarding.md` com os nomes reais de arquivos, classes e textos, o resultado das sondas do PM-1 e as reservas acionadas (T020 a T022), para o roteiro do PM-2 refletir o entregue. | T024, T026 | - | `_reversa_forward/004-figura-controle-web/onboarding.md` | 🟢 | `[X]` |
| T028 | Limpeza antes do PM-2: remover qualquer `console.log` ou código de depuração de `figure.js`, conferir por `grep` que a página não usa APIs de armazenamento ou rede (RN-09), e rodar `swift build -c release` e `./scripts/test.sh` verdes. Ao concluir, parar no PM-2. | T027 | - | `Resources/ControllerFigure/figure.js` | 🟢 | `[X]` |
| [//] T029 | Comentários de cabeçalho nos arquivos novos e alterados (`FigureState.swift`, `ButtonLabels.swift`, `FigureBridge.swift`, `ControllerFigureWebView.swift`, `index.html`, `figure.css`, `figure.js`, `build-app.sh`) citando `004-figura-controle-web` e as decisões D-xx e RF-xx que implementam, no padrão dos arquivos da feature 003. | T026 | `[//]` | `Sources/JoystickAIPoC/Editor/FigureBridge.swift` | 🟢 | `[X]` |

## Notas de execução

<!--
Reservado para /reversa-coding registrar avisos ou observações que surgiram durante a execução.
Não use isso para corrigir ações, edits manuais ficam fora desse arquivo, vão direto no código.
-->

### Rodada 1 (2026-09-15, 18 de 29 ações: T001 a T018)

- **Política de edição.** `.reversa/reversa-config.json` relido na ativação: `allowLegacyEdits: true` com `allowedPaths` vazio, liberação irrestrita do projeto (aviso dado ao usuário nesta sessão).
- **T019 aguarda confirmação.** A política do Reversa exige confirmar com o usuário a deleção de arquivo pré-existente. O pacote compila com `ControllerFigureView.swift` sem uso (exceção prevista em "Arquivos compartilhados"); a única menção que restava fora do próprio arquivo, no cabeçalho de `FigureState.swift`, foi reescrita. Ao confirmar, T019 se resume a `git rm` e à verificação por `grep`.
- **"Return" vs. "Enter".** `data-delta.md` §4 e `onboarding.md` §2 (passo 1) esperam ✕ com resumo "Return" na base, mas `KeyCatalog` exibe a tecla Return como "Enter" (`ActionSummaryTests.camadaL2DoPadrao` já fixa "Enter (herdado)"). `FigureStateTests.padraoNaBase` usa "Enter"; T027 deve corrigir o passo 1 do onboarding.
- **`xmlns` do SVG.** O `<svg>` inline não leva `xmlns="http://www.w3.org/2000/svg"`: é desnecessário em HTML e o `FigureAssetsTests` recusa qualquer `http://` nos três arquivos (D-03).
- **Menu de contexto (D-09).** Além de `menu(for:)` devolvendo `nil`, `FigureWebView` sobrescreve `willOpenMenu(_:with:)` esvaziando o menu, e a página cancela `contextmenu`; a sonda P-02 diz qual das três camadas bastou.
- **Recurso ausente antes da primeira abertura (D-10).** Com `index.html` fora do bundle, o `FigureBridge` guarda o motivo e publica `figureUnavailable` no modelo já na criação, sem registrar no log; o evento `editor.figure_unavailable` sai na primeira abertura, quando `prepareForOpen` zera o campo e a ponte o republica. Assim há exatamente um registro por abertura.
- **Tabela de posições (D-16).** `figure.js` já tem `positions` com balão (canto superior esquerdo) e lado de ancoragem da linha-guia. Distribuição planejada para a Fase 4, em px de 830 × 620: faixa superior y=8 com Create (x=8), Touchpad (x=320) e Options (x=632); coluna esquerda x=8 e direita x=632 com sete balões cada a partir de y=84, passo 76 (L1, L2, ↑, ←, ↓, →, L3 e R1, R2, △, ○, ✕, □, R3); PS em (320, 548). Silhueta de cerca de 400 × 280 centrada em (415, 320). Ajuste fino depois do PM-1.
- **Verificação.** `swift build` verde ao fim de cada ação; `./scripts/test.sh` com 270 testes em 31 suítes verdes após T010 e ao fim da rodada.

### Rodada 2 (2026-09-15, instalação e primeira observação da página mínima)

- **Instalação.** `build-app.sh` com "JoystickAI Local Signing": bundle com `Contents/Resources/ControllerFigure/`, `codesign --verify --strict` válido, `check-signature.sh` idêntico antes e depois, `permissions.status` com `postEvent: true` e `listenEvent: true` (P-03, passos 1 e 2 aprovados).
- **Observado na TV.** A página carregou no tema escuro com fundo transparente, balões com os resumos certos ("modificador ⌘" em L1 reflete a configuração do usuário, que mantém ⌘ em L1) e sem `editor.figure_unavailable` no log. O "○ na camada Base" da captura veio do modo de identificação (`editor.identify` ligado às 21:48:46 e desligado às 21:48:51), não de clique na figura.
- **Emenda E001, linhas-guia.** As linhas saíam do centro do botão por cima do rótulo. Agora o `<line>` é o primeiro filho do grupo (fica por baixo do desenho) e `figure.js` calcula o início na borda da forma, com folga de 4 px (`edgePoint`, por `getBBox` ou raio do círculo).
- **Emenda E002, painel de acorde (feature 003).** As `LazyVGrid` adaptativas de `ChordEditor` e `ActionPanel` (mínimos de 76, 150, 200 e 260 pt) espremiam os botões na largura de 470 pt do painel e quebravam "Forward Delete" em sílabas. Trocadas por `FlowLayout` (`EditorMetrics.swift`, `Layout` do macOS 13), que dispõe cada botão no tamanho ideal e quebra a linha entre botões. Ajuste fora do escopo da 004, pedido pelo usuário na observação da rodada; toca `ChordEditor.swift`, `ActionPanel.swift` e `EditorMetrics.swift`.
- **Pendente.** Confirmar o clique na figura pelo ponteiro do controle (P-02, passo 3), a rolagem sobre a figura (P-02, passos 1 e 2), o clique direito (P-02, passos 7 e 8), o tema claro e a troca ao vivo (P-01) e os passos 3 a 6 da P-03.

### Rodada 3 (2026-09-15, Fase 4 antecipada a pedido do usuário)

- **Antecipação do PM-1.** O usuário pediu a figura completa antes das sondas ("não aparecer os outros botões"). Já observados: tema escuro com fundo transparente (parte da P-01) e assinatura e permissões preservadas (P-03, passos 1 e 2). T023 a T026 executadas com a estrutura de três arquivos e a CSP com `'self'` (P-03, passo 4, confirmada pelo fato de a página ter aplicado estilo e script); se P-02 reprovar, T021 ajusta só o Swift.
- **Disposição final (D-16).** Faixa superior com L1, Create, Options e R1 e, numa segunda linha ao centro, Touchpad; coluna esquerda L2, ↑, ←, →, ↓, L3; coluna direita R2, △, ○, □, ✕, R3; PS na faixa inferior. As alturas das colunas não são uniformes: → e □ ficam em 334 px para a linha-guia passar entre ← e ↓ (e entre ○ e ✕) sem cruzar outro botão; nenhuma linha cruza balão ou botão.
- **Rótulos.** 26 px nos botões grandes; 22 px em L1, L2, R1, R2, L3 e R3; 18 px em PS, Create e Options (estes com o rótulo acima da tecla, que tem 16 × 30 px). O tamanho vem do atributo `font-size` do `<text>`, não do CSS, para o mesmo estilo servir a todos.
- **T029.** Os cabeçalhos citando `004-figura-controle-web` já estavam nos oito arquivos desde a criação; marcada como concluída.

### Rodada 4 (2026-09-16, fechamento das ações abertas)

- **Política de edição.** `.reversa/reversa-config.json` relido na ativação: `allowLegacyEdits: true` com `allowedPaths` vazio, liberação irrestrita (aviso dado ao usuário).
- **T019.** Deleção de `ControllerFigureView.swift` autorizada pelo usuário; removido por `git rm`, sem referências restantes, `swift build` e `./scripts/test.sh` verdes (270 testes em 31 suítes).
- **PM-1.** P-02 aprovada e P-03 passo 3 (sem rede) aprovado pelo usuário; P-03 passo 5 conferido (`~/Library/WebKit/dev.iagoleal.joystick-ai.poc` ausente) e passo 6 verde após T019. Na P-01, o usuário respondeu "Melhorou", sem apontar defeito de tema, mas sem confirmar explicitamente o tema claro nem a troca ao vivo; tratada como aprovada, com a verificação remetida ao passo 15 do PM-2.
- **T020, T021 e T022 dispensadas.** As três são condicionais a reprovação de sonda e nenhuma reprovou; marcadas `[X]` com `status: skipped` no `progress.jsonl`, sem alteração de código.
- **Emenda E003, gatilhos acima dos ombros.** Observação do usuário no PM-1: a figura é vista de cima, e nessa perspectiva L2 e R2 ficam na borda de trás, acima de L1 e R1. Em `index.html`, os grupos trocaram de posição (L2 e R2 em y=132, L1 e R1 em y=172, com os de baixo por último no DOM para ganharem o clique na sobreposição das áreas de acerto); em `figure.js`, L2 e R2 foram para a faixa superior e L1 e R1 para o topo das colunas. A linha-guia de L1 (e R1) sai a cerca de 4 px abaixo de L2 (e R2), sem cruzá-lo. Isso corrige a disposição "L1/R1 sobre L2/R2" de RN-01, D-16 e T023, que ficam como registro histórico.
- **T027.** `onboarding.md` ganhou a tabela "O que foi entregue", o resultado do PM-1 e as correções do PM-2: ✕ "Enter" em vez de "Return" (passo 1), sufixo " + Enter" (passo 7), exemplo do truncamento (passo 9), ausência de teste da ponte (passo 21, TD-01) e reinstalação antes do roteiro.
- **T028.** Sem `console.*`, `debugger` ou APIs de armazenamento, rede, temporizador ou marcação nos três arquivos; `swift build -c release` e `./scripts/test.sh` verdes. Parada no PM-2.
- **Pendente.** PM-2 (21 passos na TV, com a medição dos 500 ms), após reinstalar com `build-app.sh`.

### PM-2 (2026-09-16, aceito pelo usuário sem execução do roteiro)

- **Decisão do usuário.** Após a reinstalação com a emenda E003 (assinatura idêntica, `permissions.status` com `postEvent` e `listenEvent` verdadeiros), o usuário considerou o PM-2 aprovado sem percorrer os 21 passos do `onboarding.md` §2, porque a TV apenas espelha a tela do Mac, e se comprometeu a relatar o que aparecer no uso.
- **O que isso não cobre.** O espelhamento responde pela legibilidade a 3 m, não pelos passos funcionais, que ficam sem verificação manual: carga sem rede em até 500 ms (19), página ausente com `editor.figure_unavailable` (20), camada removida por fora (17), animação com "Reduzir movimento" (12), estado antes da carga (18) e a troca de tema ao vivo (15), que também respondia a ressalva da P-01. Cobertura automática vigente: `FigureStateTests`, `FigureAssetsTests` e `LogEventCatalogTests`, com 270 testes verdes; `FigureBridge` segue sem teste (TD-01).
- **Tratamento.** Defeitos relatados pelo usuário entram como emenda nesta feature ou como bug pelo `/reversa-debugger`.

## Histórico de alterações

| Data | Alteração | Autor |
|------|-----------|-------|
| 2026-09-15 | Versão inicial gerada por `/reversa-to-do` | reversa |
| 2026-09-15 | Rodada 1 do `/reversa-coding`: T001 a T018 concluídas; T019 aguarda confirmação da deleção; PM-1 pendente | reversa |
| 2026-09-15 | Rodadas 2 e 3: emendas E001 e E002; Fase 4 (T023 a T026) e T029 antecipadas a pedido do usuário | reversa |
| 2026-09-16 | Rodada 4: T019, T027 e T028 concluídas; T020 a T022 dispensadas pelo PM-1; emenda E003; parada no PM-2 | reversa |
| 2026-09-16 | PM-2 aceito pelo usuário sem execução do roteiro; passos funcionais sem verificação manual registrados | reversa |
