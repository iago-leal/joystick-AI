# Roadmap: Figura do controle em página web embutida

> Identificador: `004-figura-controle-web`
> Data: `2026-09-15`
> Requirements: `_reversa_forward/004-figura-controle-web/requirements.md`
> Confidência: 🟢 CONFIRMADO, 🟡 INFERIDO, 🔴 LACUNA

> **Nota de confidência:** recebem 🟢 as decisões apoiadas no código inspecionado em 2026-09-15 (`ControllerFigureView.swift`, `EditorViewModel.swift`, `EditorWindowController.swift`, `ActionSummary.swift`, `build-app.sh`), na extração em `_reversa_sdd/` ou em decisão do usuário registrada no `requirements.md` §9. Recebem 🟡 as que dependem de comportamento do WebKit ainda não observado neste projeto; cada uma aponta a sonda do PM-1 que a confirma. Não há 🔴: o `requirements.md` não tem `[DÚVIDA]` pendente.

## 1. Resumo da abordagem

O delta é pequeno e concentrado na aba Atalhos. O núcleo `JoystickCore` ganha um tipo de valor codificável, `FigureState`, que descreve os 18 botões na camada selecionada (rótulo, resumo, espécie, problema, seleção) com as mesmas regras que `ControllerFigureView.chip` aplica hoje; o rótulo `displayName` migra do app para o núcleo para que o estado o carregue. No app, `ControllerFigureView` (fichas em SwiftUI) dá lugar a `ControllerFigureWebView`, um `NSViewRepresentable` de 830 × 620 pt que hospeda um `WKWebView` de propriedade de `FigureBridge`, objeto único por processo que carrega a página local, envia cada `FigureState` novo por `callAsyncJavaScript` sem interpolar JSON, recebe o identificador do botão clicado por `WKScriptMessageHandler` e o converte em `model.select(_:)`. A página, em `Resources/ControllerFigure/` (`index.html`, `figure.css`, `figure.js`, sem bibliotecas), desenha o DualSense em SVG plano com 18 balões de resumo ligados por linhas-guia e só grava `textContent`. O script de build passa a copiar essa pasta para `Contents/Resources/` do bundle, dentro da mesma assinatura. Se o recurso faltar ou a página falhar, a aba mostra a mensagem de RN-12 e registra um evento novo, `editor.figure_unavailable`, com motivo e sem conteúdo. Modelo do rascunho, validação, arquivo de configuração e `logSchema` não mudam. Três sondas (tema e fundo, rolagem e foco, isolamento e assinatura) formam o portão PM-1 antes do desenho final.

## 2. Princípios aplicados

Não existe `.reversa/principles.md`; não há princípio a respeitar nem conflito a registrar. As restrições equivalentes vêm da extração e das features anteriores:

| Restrição | Como a feature se relaciona | Status |
|-----------|------------------------------|--------|
| Núcleo funcional com casca imperativa; `JoystickCore` só importa `Foundation` (`architecture.md` §2 e §3) | `FigureState` e `ButtonID.displayName` entram no núcleo como valores puros e testados; `WebKit` fica só no alvo do app (`FigureBridge`, `ControllerFigureWebView`). A página não decide nada (RN-04). | respeita |
| Sem rede, sem dependências de terceiros (`architecture.md` §1; `c4-context.md` Fronteiras; 001 RN-12) | Página local carregada por `loadFileURL`, com CSP restritiva, delegado de navegação que cancela qualquer URL fora do bundle e teste automatizado que inspeciona os três arquivos (D-03, D-06). | respeita |
| Log sem textos, rótulos, teclas nem acordes (003 RN-14; `LogEventCatalogTests`) | O único evento novo leva apenas `reason`. A página não registra nada e usa armazenamento não persistente (RN-09, D-06). | respeita |
| Isolamento por filas explícitas; AppKit e SwiftUI só na main thread (001 D-22; `EditorViewModel` "Só na main thread") | `FigureBridge` vive na main thread e assina o modelo com `receive(on: RunLoop.main)`; a identificação pelo controle já chega ao modelo na main thread e não muda. | respeita |
| Escala de TV do PM-1a: 32 pt, 60 pt, janela mínima 1.400 × 800 pt (`EditorMetrics`; ADR-014) | A figura mantém 830 × 620 pt, rótulos de 26 px, resumos de 24 px e área de acerto de 60 × 60 px por botão (RN-05, RN-11). | respeita |
| Assinatura estável preserva TCC (`inventory.md` §7; ADR-002) | Recursos entram em `Contents/Resources` e são selados pela mesma assinatura; o requisito designado não muda (D-02, sonda P-03). | respeita |
| Regra de escrita do Reversa (`CLAUDE.md`) | `.reversa/reversa-config.json` está com `allowLegacyEdits: true` e `allowedPaths` vazio, liberação irrestrita. O `/reversa-coding` deve avisar uma vez por sessão. | observação |

## 3. Decisões técnicas

### 3.1 Recurso e empacotamento

| ID | Decisão | Justificativa | Alternativas descartadas | Confidência |
|----|---------|----------------|--------------------------|-------------|
| D-01 | A página vive em `Resources/ControllerFigure/` do repositório, em três arquivos: `index.html`, `figure.css` e `figure.js`, sem bibliotecas, sem fontes externas e sem imagens (a silhueta é SVG inline). `scripts/build-app.sh` copia a pasta para `Contents/Resources/ControllerFigure/` antes do `codesign`. O app localiza `index.html` por `Bundle.main.url(forResource:withExtension:subdirectory:)`; `nil` aciona RN-12. | Mantém a regra atual de que o script monta o bundle (`inventory.md` §7) sem tocar em `Package.swift`; `Bundle.main.url` devolve `nil` sem abortar, o que RN-12 exige; três arquivos são editáveis com realce e revisáveis no diff. | `resources:` do SwiftPM com `Bundle.module` (o acessor gerado chama `fatalError` quando o bundle falta, contra RN-12, e exigiria copiar o `.bundle` gerado); HTML, CSS e JS como literais Swift (sem realce, escape de aspas, RN-12 sem sentido). | 🟢 |
| D-02 | A assinatura não muda de forma: `codesign --force --sign` sobre o `.app` sela `Contents/Resources` no `CodeResources`; identificador, autoridade e requisito designado permanecem iguais, então as permissões de Acessibilidade e Input Monitoring sobrevivem. A verificação é `./scripts/check-signature.sh` antes e depois do build, com saída idêntica, e a permissão conferida pelo `permissions.status` do log. | O TCC associa a permissão ao requisito designado, que depende do identificador e da cadeia de assinatura, não do conteúdo dos recursos (ADR-002). | Assinar os recursos em separado (não é código; desnecessário); embutir no binário para evitar o tema (D-01). | 🟡 (sonda P-03) |
| D-03 | Teste `FigureAssetsTests` em `Tests/JoystickCoreTests/`, que resolve `Resources/ControllerFigure/` a partir de `#filePath` e afirma: os três arquivos existem; nenhum contém `http://`, `https://`, `//` como início de URL em `src`, `href`, `url(` ou `@import`; todo `<script src>` e `<link href>` aponta para um dos dois arquivos irmãos; `index.html` declara a `<meta http-equiv="Content-Security-Policy">` de D-06; nenhum uso de `innerHTML`, `outerHTML`, `insertAdjacentHTML`, `document.write` nem `eval` em `figure.js`. | Torna RF-08 e RF-09 verificáveis a cada `./scripts/test.sh`, e não só por inspeção manual do bundle. | Só inspeção manual no portão (regride sem aviso); regra de conteúdo do WebKit (`WKContentRuleList`) como única defesa (compila assíncrono e grava cache em disco, contra RN-09). | 🟡 (teste do núcleo lendo arquivos fora de `Sources/`; aceitável por ser leitura só de texto) |

### 3.2 Hospedagem da página no app

| ID | Decisão | Justificativa | Alternativas descartadas | Confidência |
|----|---------|----------------|--------------------------|-------------|
| D-04 | `WKWebView` (framework `WebKit`, presente no SDK das Command Line Tools) hospedado por `ControllerFigureWebView: NSViewRepresentable` em `Sources/JoystickAIPoC/Editor/`, com `.frame(width: 830, height: 620)` fixo, no lugar de `ControllerFigureView` dentro de `ShortcutsTab`. `ControllerFigureView.swift` é removido. | Único componente do sistema que executa HTML, CSS e JS locais no macOS 13; a área fixa preserva a largura do painel (RN-11). | `WebView` do SwiftUI (`_WebKit_SwiftUI`, macOS 26, acima do mínimo 13); `NSTextView` com HTML atribuído (não executa script nem clique por botão); desenhar o DualSense em `Canvas`/`Path` do SwiftUI (contraria a decisão do usuário por página web). | 🟢 |
| D-05 | `FigureBridge` (`Sources/JoystickAIPoC/Editor/FigureBridge.swift`), `NSObject` na main thread, é o dono único do `WKWebView`, criado uma vez no `AppDelegate` ao lado de `EditorViewModel` e entregue a `EditorRootView(model:figure:)` → `ShortcutsTab` → `ControllerFigureWebView`. `makeNSView` devolve sempre o mesmo `webView`; trocar de aba ou fechar a janela não recarrega a página. | O processo WebContent e a carga inicial custam centenas de milissegundos; carregar uma vez por processo atende ao limite de 500 ms nas aberturas seguintes e tira a primeira carga do caminho crítico (a janela é criada no primeiro `show`, e `isReleasedWhenClosed` já é falso). | `@StateObject` dentro de `ShortcutsTab` (recriado a cada troca de aba); carga a cada abertura da janela. | 🟢 |
| D-06 | Configuração do `WKWebView`: `websiteDataStore = .nonPersistent()`; `preferences.javaScriptCanOpenWindowsAutomatically = false`; `allowsMagnification = false`; `allowsBackForwardNavigationGestures = false`; carga por `loadFileURL(index, allowingReadAccessTo: <pasta ControllerFigure>)`. `WKNavigationDelegate.decidePolicyFor(navigationAction:)` cancela qualquer navegação cujo URL não seja o `index.html` do bundle. A página declara `<meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'self'; style-src 'self'">` e `<meta name="color-scheme" content="light dark">`. | RN-03, RN-09 e RNF de segurança: sem cache em `~/Library/WebKit`, sem janelas, sem ampliação, sem navegação para fora, e sem carga de rede mesmo que um subrecurso apareça por engano; a CSP cobre subrecursos, que o delegado de navegação não vê. | `WKContentRuleList` (D-03); esquema de URL próprio por `WKURLSchemeHandler` (mais código para o mesmo isolamento). | 🟡 (se o WebKit tratar a origem `file:` como opaca e `'self'` bloquear `figure.css` e `figure.js`, a página passa a um único `index.html` com CSS e JS inline e CSP `default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'`; sonda P-03) |
| D-07 | App → página: `webView.callAsyncJavaScript("figure.render(state)", arguments: ["state": object], in: nil, in: .page)`, em que `object` vem de `JSONSerialization.jsonObject` sobre o `Data` do `JSONEncoder` de `FigureState`. `figure.render` escreve rótulo e resumo com `textContent` e aplica estados por `classList`, nunca por `innerHTML`. O bridge guarda o último `FigureState`; antes de `webView(_:didFinish:)` os envios só atualizam esse último, e em `didFinish` ele é enviado (cenário "Estado enviado antes da carga"). | Nenhum JSON é interpolado em código JS, logo não há escape a fazer nem U+2028 a tratar (RN-07 e RF-09 no caminho de entrada); um único ponto de envio, idempotente, cobre carga, abertura, camada, seleção e edição (RF-05, RF-06). | `evaluateJavaScript` com JSON interpolado (exige escape de string e cuidado com separadores de linha Unicode); `WKUserScript` com o estado inicial (não cobre atualizações). | 🟢 |
| D-08 | Página → app: `configuration.userContentController.add(handler, name: "figure")`, mensagem `{ "button": "<ButtonID.rawValue>" }` enviada por `window.webkit.messageHandlers.figure.postMessage`. O bridge aceita só `body` dicionário com `button` string que `ButtonID(rawValue:)` reconheça e chama `model.select(button)`; qualquer outro corpo é ignorado, sem log e sem erro (cenário "Mensagem desconhecida da página é ignorada"). Só esse handler existe. | RN-04 e RNF de segurança: a página só devolve um identificador do catálogo; o modelo continua o único dono da seleção. | Handler com resposta (`WKScriptMessageHandlerWithReply`; sem uso); navegação para URL falso interceptada no delegado (frágil e ruidosa). | 🟢 |
| D-09 | `FigureWebView: WKWebView` (subclasse em `FigureBridge.swift`) sobrescreve `scrollWheel(with:)` para encaminhar o evento ao `enclosingScrollView` (ou ao `nextResponder` mais próximo que o tenha), porque a página nunca rola (`overflow: hidden`, 830 × 620 px exatos); sobrescreve `acceptsFirstResponder` como `false` para a figura não capturar o teclado nem mostrar anel de foco, e sobrescreve `menu(for:)` devolvendo `nil` para o clique direito (R2) não abrir o menu de contexto do WebKit. | O `WKWebView` no macOS consome os eventos de rolagem e não os repassa ao `NSScrollView` externo; a janela do editor rola só na vertical e o ponteiro do controle passa sobre a figura o tempo todo. O `KeyCaptureField` e o menu Editar dependem de o primeiro respondedor continuar nos campos. | Sem rolagem na janela (o PM-1a a exigiu numa tela de 900 pt); `hitTest` devolvendo `nil` para o WebKit (bloquearia o clique). | 🟡 (sonda P-02) |
| D-10 | Falhas: (a) `index.html` ausente ou ilegível: o bridge não cria o `WKWebView` e publica `figureUnavailable = .resourceMissing`; (b) `didFailProvisionalNavigation` ou `didFail`: `.loadFailed`; (c) `webViewWebContentProcessDidTerminate`: uma recarga imediata; nova queda dentro de 60 s: `.processTerminated`. Em qualquer caso `ShortcutsTab` mostra, num quadro de 830 × 620 pt, o texto "A figura do controle não pôde ser carregada; reinstale o app." e o restante da aba segue igual. O evento `editor.figure_unavailable { reason }` é registrado uma vez por abertura da janela. | RN-12 e RF-13: sem figura reserva, com o painel e o modo de identificação operáveis; o motivo no log orienta o diagnóstico sem conteúdo. | Fechar o editor com erro; manter `ControllerFigureView` como reserva (dois desenhos da mesma coisa, recusado no esclarecimento 3). | 🟢 (a, b) 🟡 (c: contagem de quedas) |
| D-11 | Tema: a página declara `color-scheme: light dark` no `:root` e usa as cores de sistema do WebKit (`Canvas`, `CanvasText`, `AccentColor`, `-apple-system-secondary-label`, `-apple-system-red`) com valores de reserva; `@media (prefers-color-scheme: dark)` ajusta só contrastes. O `WKWebView` herda a `effectiveAppearance` da janela, e a consulta de mídia muda ao vivo. Fundo: `webView.underPageBackgroundColor = .clear` (macOS 12+) e `body { background: transparent }`, com o quadro arredondado de 48 px desenhado em CSS por `color-mix(in srgb, CanvasText 8%, transparent)`, equivalente ao `Color.secondary.opacity(0.08)` atual. | RN-08 e RF-11 sem reabrir a janela; as cores semânticas mantêm a paridade com o restante do editor (`code-analysis.md` §8.3). | Cores fixas por tema (destoam do `accentColor` do sistema); `setValue(false, forKey: "drawsBackground")` (chave privada). | 🟡 (sonda P-01; reserva: o bridge observa `effectiveAppearance` por KVO e chama `figure.setTheme("dark"|"light")`) |

### 3.3 Modelo e núcleo

| ID | Decisão | Justificativa | Alternativas descartadas | Confidência |
|----|---------|----------------|--------------------------|-------------|
| D-12 | `FigureState` em `Sources/JoystickCore/Config/FigureState.swift`: `struct FigureState: Codable, Equatable, Sendable { layer: String; buttons: [FigureButton] }` e `struct FigureButton { id: String; label: String; summary: String; kind: Kind; problem: Bool; selected: Bool }`, com `Kind` em `fixed | modifier | own | inherited`. Construtor `FigureState(config: ShortcutConfig, layer: ButtonID?, selected: ButtonID?, issues: [EditorIssue])` percorre `ButtonID.allCases` na ordem do catálogo e reproduz `ControllerFigureView.chip`: `fixed` para `ShortcutConfig.pointerButtons`, `modifier` para `config.isModifier`, `inherited` para `resolvedAction(...).inherited`, `own` no restante; `summary` por `ActionSummary.text(for:layer:in:)`; `problem` quando há `EditorIssue` com alvo `trigger(layer, button)` ou `modifier(button)`, como `EditorViewModel.hasIssue`. Detalhe em `data-delta.md`. | RNF de testabilidade: o contrato é um valor codificável testado sem interface; RN-02 garante o mesmo significado dos estados e o mesmo texto de resumo. | Calcular estado na página a partir de `ShortcutConfig` (contra RN-04); dicionário `[ButtonID: ...]` (ordem instável no JSON). | 🟢 |
| D-13 | `ButtonID.displayName` migra de `Sources/JoystickAIPoC/Editor/EditorLabels.swift` para `Sources/JoystickCore/Config/ButtonLabels.swift`, como extensão pública com os mesmos 18 textos; `EditorLabels.layerName` e os demais usos no app não mudam. | O `FigureState` leva o rótulo (RN-04, RF-02) e precisa dele no núcleo; mover evita duplicar a tabela. | Tabela de rótulos na página (RN-04 diz que o editor envia o rótulo); rótulo passado por fechamento ao construtor (contorna o problema sem resolvê-lo). | 🟢 |
| D-14 | `EditorViewModel` ganha `var figureState: FigureState` calculada de `draft.document.shortcuts`, `selectedLayer`, `selectedButton` e `draft.issues`, e `@Published private(set) var figureUnavailable: FigureFailure?` (`resourceMissing | loadFailed | processTerminated`), zerada em `prepareForOpen`. `FigureBridge` assina `model.objectWillChange.receive(on: RunLoop.main)` e, a cada emissão, envia `figureState` só se diferir do último enviado. `select(_:)` e `identified(_:)` não mudam. | Uma única fonte de verdade sem estado duplicado; a comparação por `Equatable` evita renderizações redundantes a cada tecla digitada no painel, mantendo o limite de 100 ms e a CPU em repouso. | `@Published figureState` recalculado em `didSet` de três propriedades (três pontos de atualização); temporizador de coalescência (adiciona latência). | 🟢 |
| D-15 | `LogEventCatalog.editorFigureUnavailable(reason:)` produz `editor.figure_unavailable`, nível `warn`, campo `reason` em `resource_missing | load_failed | process_terminated`; `LogEventCatalogTests.sampleEvents` recebe o evento; `logSchema` segue 1. Contrato em `interfaces/diagnostic-log.md`. | RNF de observabilidade: evento novo só com motivo; o catálogo fechado é a garantia de privacidade do log. | `os.Logger` (fora do catálogo e do `poc-tools`); sem evento (falha silenciosa de recurso). | 🟢 |

### 3.4 Desenho e comportamento da página

| ID | Decisão | Justificativa | Alternativas descartadas | Confidência |
|----|---------|----------------|--------------------------|-------------|
| D-16 | `index.html` contém um `<svg viewBox="0 0 830 620">` com a silhueta plana do DualSense ao centro (cerca de 430 × 300 px), os 18 botões como `path`, `circle` e `rect` nas posições de RN-01, uma `<line>` de linha-guia por botão e, sobre o SVG, 18 `<div class="balloon" data-button="…">` posicionados em absoluto. Distribuição proposta: coluna esquerda com L1, L2, ↑, ←, ↓, →, L3; coluna direita com R1, R2, △, ○, ✕, □, R3; faixa superior com Create, Touchpad, Options; faixa inferior com PS. Balões de 190 × 64 px, dois de altura de linha para o resumo (`-webkit-line-clamp: 2`), sem sobreposição entre si nem com botões. As posições ficam numa tabela em `figure.js`, como `positions` hoje. | RN-01, RN-02 e o cenário "Balões visíveis ao mesmo tempo"; sete balões de 64 px com folga de 12 px cabem em 620 px de altura; a tabela de posições no script deixa o ajuste fino no PM-1 sem tocar no app. | Balão só do botão selecionado e resumo por `title` (recusado no esclarecimento 2); `<canvas>` (sem elementos clicáveis nem `:hover` nativos). | 🟡 (as medidas exatas saem do PM-1; a estrutura é 🟢) |
| D-17 | Cada botão é um grupo `[data-button]` com três partes: o desenho, o balão e uma área de acerto invisível de ao menos 60 × 60 px centrada no desenho; `click` é delegado no `document` pelo ancestral `[data-button]`, e um clique em qualquer das três partes envia o identificador (RN-05, RF-07). Estados por classe no grupo: `is-fixed` e `is-modifier` (preenchimento neutro a 28 %), `is-inherited` (resumo a 55 % de opacidade), `is-problem` (preenchimento vermelho a 25 % e contorno vermelho), `is-selected` (contorno `AccentColor` de 5 px sobre botão e balão), `:hover` (contorno de 3 px a 40 %, RF-14). Rótulo em 26 px negrito dentro do botão; resumo em 24 px no balão; os símbolos △, ○, ✕ e □ com as cores do aparelho (verde, vermelho, azul e rosa) em tons com contraste ≥ 4,5:1 nos dois temas (RF-12). `user-select: none`, `contextmenu` e `dragstart` cancelados. | Reproduz os cinco estados de RN-02 com os mesmos valores numéricos de `ControllerFigureView` (0,55; 0,28; 0,25; 5 pt) para não haver regressão visual de significado. | Estados calculados por CSS a partir de atributos de dados (mesma coisa com mais indireção). | 🟢 |
| D-18 | Transições só por CSS, `transition: 120ms` em contorno e opacidade ao mudar de classe, desligadas sob `@media (prefers-reduced-motion: reduce)`; nenhum `requestAnimationFrame`, `setInterval` nem `setTimeout` periódico no script. | RF-15 e RNF de CPU em repouso. | Animação por script (laço contínuo). | 🟢 |

### 3.5 Verificação

| ID | Decisão | Justificativa | Alternativas descartadas | Confidência |
|----|---------|----------------|--------------------------|-------------|
| D-19 | Portão PM-1 com página mínima (silhueta e três botões) e as sondas P-01 (tema e fundo transparente), P-02 (rolagem, foco do teclado e clique direito) e P-03 (CSP em `file://`, ausência de rede, assinatura e permissões preservadas, `~/Library/WebKit` intocado). Portão PM-2 com os 20 cenários do `requirements.md` §7 na TV a 3 m, mais a medição dos 500 ms (diferença entre `editor.opened` e o primeiro `figure.render`, com `--debug`). Roteiros em `onboarding.md`. | TD-01: não há testes automatizados no alvo do app; o que depende do WebKit só se prova no hardware e na TV. | Portão único no fim (retrabalho do desenho se uma sonda reprovar). | 🟢 |

## 4. Premissas

Nenhuma. O `requirements.md` §10 não tem `[DÚVIDA]` pendente; as cinco perguntas da sessão de esclarecimentos de 2026-09-15 estão resolvidas e incorporadas às RN-01, RN-02, RN-05, RN-10, RN-11 e RN-12.

## 5. Delta arquitetural

| Componente | Arquivo de origem no legado | Tipo de mudança | Resumo |
|------------|------------------------------|-----------------|--------|
| `editor` › `ControllerFigureView` | `_reversa_sdd/code-analysis.md#8.3 Interface`; `_reversa_sdd/editor/design.md#Interface` | componente-extinto | As 18 fichas em SwiftUI saem; `ShortcutsTab` passa a compor `ControllerFigureWebView` ou o quadro de RN-12. |
| `editor` › `ControllerFigureWebView` + `FigureBridge` | `_reversa_sdd/architecture.md#3` (camada App) | componente-novo | Hospedagem do `WKWebView`, carga do recurso, ponte de estado e de clique, tratamento de falha (D-04 a D-11). |
| `editor` › `EditorViewModel` | `_reversa_sdd/editor/design.md#Interface` (`EditorViewModel`) | regra-alterada | Ganha `figureState` derivado e `figureUnavailable`; seleção e identificação inalteradas (D-14). |
| `JoystickCore` › `FigureState`, `ButtonLabels` | `_reversa_sdd/architecture.md#3` (camada Core) | componente-novo | Contrato de estado da figura como valor codificável; rótulos dos botões no núcleo (D-12, D-13). |
| `diagnostics-log` › catálogo | `_reversa_sdd/architecture.md#4` (I-11 e ADR-008); `_reversa_sdd/editor/design.md#Observabilidade` | contrato-alterado | Evento `editor.figure_unavailable { reason }`; `logSchema` 1 (D-15). |
| Build e bundle | `_reversa_sdd/inventory.md#7. Build, assinatura e distribuição` | contrato-alterado | O bundle passa a ter `Contents/Resources/ControllerFigure/`; a assinatura sela os recursos (D-01, D-02). |
| Frameworks do app | `_reversa_sdd/dependencies.md#3. Frameworks do sistema por alvo` | contrato-novo | `JoystickAIPoC` passa a importar `WebKit`; o núcleo segue só com `Foundation`. |
| Integrações | `_reversa_sdd/architecture.md#4. Integrações externas` | contrato-novo | I-13: WebKit (processo WebContent) como hospedeiro da figura, sem rede, com armazenamento não persistente. |

Arquivos que a mudança deve tocar, para o `legacy-impact.md` do `/reversa-coding`:

- Novos: `Sources/JoystickCore/Config/FigureState.swift`, `Sources/JoystickCore/Config/ButtonLabels.swift`, `Sources/JoystickAIPoC/Editor/FigureBridge.swift`, `Sources/JoystickAIPoC/Editor/ControllerFigureWebView.swift`, `Resources/ControllerFigure/index.html`, `Resources/ControllerFigure/figure.css`, `Resources/ControllerFigure/figure.js`, `Tests/JoystickCoreTests/FigureStateTests.swift`, `Tests/JoystickCoreTests/FigureAssetsTests.swift`.
- Alterados: `Sources/JoystickAIPoC/Editor/ShortcutsTab.swift`, `Sources/JoystickAIPoC/Editor/EditorRootView.swift` (recebe o bridge), `Sources/JoystickAIPoC/Editor/EditorViewModel.swift`, `Sources/JoystickAIPoC/Editor/EditorLabels.swift` (perde a extensão de `ButtonID`), `Sources/JoystickAIPoC/App/AppDelegate.swift` (cria o bridge), `Sources/JoystickCore/Log/LogEventCatalog.swift`, `Tests/JoystickCoreTests/LogEventCatalogTests.swift`, `scripts/build-app.sh`.
- Removido: `Sources/JoystickAIPoC/Editor/ControllerFigureView.swift`.
- Inalterados por decisão: `Package.swift`, `Resources/Info.plist`, `EditorDraft.swift`, `ShortcutConfig*.swift`, `ConfigStore.swift`, `ActionPanel.swift`, `PaletteTab.swift`, `EditorWindowController.swift`, `KeyCaptureField.swift`.

## 6. Delta no modelo de dados

- Resumo das mudanças: nenhum arquivo persistido muda (`config.json`, log JSONL e rodadas da tela de alvos seguem iguais; `logSchema` 1). Surgem dois tipos de valor em memória no núcleo (`FigureState`, `FigureButton`) e um layout novo no bundle do app. A página não persiste nada, e o armazenamento do WebKit é não persistente.
- Detalhe completo em: `_reversa_forward/004-figura-controle-web/data-delta.md`

## 7. Delta de contratos externos

| Contrato | Tipo | Arquivo de detalhe |
|----------|------|--------------------|
| Ponte editor ↔ página (`figure.render` e `messageHandlers.figure`) | JSON em memória, entre processos do WebKit | `_reversa_forward/004-figura-controle-web/interfaces/figure-bridge.md` |
| Log de diagnóstico (delta) | arquivo JSON Lines | `_reversa_forward/004-figura-controle-web/interfaces/diagnostic-log.md` |

O arquivo de configuração (`003-editor-atalhos/interfaces/config-file.md`) não muda.

## 8. Plano de migração

n/a. Não há dado persistido a migrar. Ao instalar o build novo, `build-app.sh` substitui o `.app` inteiro por `ditto`, como hoje, e o bundle já sai com `Contents/Resources/ControllerFigure/`. Um `.app` antigo com o binário novo é impossível pelo fluxo do script; se ocorrer por cópia manual, vale RN-12.

## 9. Riscos e mitigações

| Risco | Impacto | Probabilidade | Mitigação |
|-------|---------|---------------|-----------|
| A rolagem vertical da janela para de responder com o ponteiro sobre a figura, por o `WKWebView` consumir o `scrollWheel` | alto (PM-1a exigiu rolagem na tela de 900 pt) | médio | D-09; sonda P-02 antes do desenho final; reserva: reduzir a altura da figura só se a sonda reprovar, com nova decisão do usuário |
| CSP com `'self'` bloqueia os próprios `figure.css` e `figure.js` sob `file://` | médio (a página não carrega) | médio | D-06 com reserva de arquivo único inline; sonda P-03 |
| A assinatura com recursos altera o requisito designado e as permissões caem | alto (app sem injeção até reconceder) | baixo | D-02; `check-signature.sh` antes e depois; `permissions.status` no log; sonda P-03 |
| Primeira carga da página acima de 500 ms na abertura do editor pelo sofá | médio (regressão percebida) | médio | D-05 (uma carga por processo); medição no PM-2; reserva: pré-aquecer o bridge na inicialização do app, depois do controle |
| Fundo do `WKWebView` opaco ou tema não acompanha o sistema ao vivo | baixo (visual) | médio | D-11 com reserva por KVO de `effectiveAppearance`; sonda P-01 |
| O `WKWebView` toma o primeiro respondedor e a gravação de acorde ou o ditado nos campos deixa de funcionar | alto (regressão do PM-1a da 003) | baixo | D-09 (`acceptsFirstResponder` falso); cenários de acorde e ditado repetidos no PM-2 |
| O processo WebContent cai e a figura some sem aviso | baixo | baixo | D-10 (recarga única e mensagem de RN-12 com `editor.figure_unavailable`) |
| Balões não cabem sem sobreposição em 830 × 620 com resumos de duas linhas | médio (RN-02 exige os 18 visíveis) | médio | D-16 com tabela de posições ajustável; PM-1 com o resumo mais longo possível ("“…24 caracteres…” + Enter (herdado)") |
| `FigureAssetsTests` frágil por depender de caminho relativo ao repositório | baixo | baixo | Resolver por `#filePath` e pular com `withKnownIssue` se a pasta não existir fora do repositório |

## 10. Critério de pronto

- [ ] Todas as ações do `actions.md` marcadas `[X]`
- [ ] `cross-check.md` (se executado) sem CRITICAL nem HIGH
- [ ] `regression-watch.md` gerado
- [ ] Re-extração reversa executada e sem regressão vermelha (recomendado, não obrigatório)
- [ ] `./scripts/test.sh` verde com `FigureStateTests`, `FigureAssetsTests` e `LogEventCatalogTests` atualizados
- [ ] PM-1 (P-01, P-02, P-03) e PM-2 (20 cenários do `requirements.md` §7) aprovados na TV, com `check-signature.sh` idêntico antes e depois e `permissions.status` com `postEvent: true`
- [ ] `ControllerFigureView.swift` removido e nenhuma referência restante
- [ ] `editor/design.md`, `code-analysis.md` §8.3, `dependencies.md` §3 e `inventory.md` §7 com adendo pelo `/reversa-sync`

## 11. Histórico de alterações

| Data | Alteração | Autor |
|------|-----------|-------|
| 2026-09-15 | Versão inicial gerada por `/reversa-plan` | reversa |
