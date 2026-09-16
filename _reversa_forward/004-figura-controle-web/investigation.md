# Investigation: Figura do controle em página web embutida

> Identificador: `004-figura-controle-web`
> Data: `2026-09-15`
> Roadmap: `_reversa_forward/004-figura-controle-web/roadmap.md`

## 1. Pergunta de fundo

Como trocar as 18 fichas retangulares da aba Atalhos por um desenho fiel do DualSense feito em HTML, CSS e JavaScript, embutido na janela SwiftUI do editor, sem que a página decida nada, sem rede, sem gravar nada, sem quebrar a rolagem, o teclado, o tema e a assinatura que os portões da feature 003 aprovaram, e com a mesma legibilidade a 3 m?

## 2. Estado de partida, observado no código em 2026-09-15

- `ControllerFigureView` (`Sources/JoystickAIPoC/Editor/ControllerFigureView.swift`, 70 linhas) desenha um `RoundedRectangle` de 830 × 620 pt com `Color.secondary.opacity(0.08)` e 18 `Button` de 160 × 96 pt em posições fixas (`positions`). Cada ficha calcula `fixed`, `inherited`, `selected` e `problem` a partir de `model.selectedLayer`, `model.draft.document.shortcuts`, `model.selectedButton` e `model.hasIssue(_:in:)`, e mostra `button.displayName` (26 pt negrito) e `ActionSummary.text(for:layer:in:)` (24 pt, duas linhas, opacidade 0,55 se herdado). Preenchimentos: vermelho a 25 % (problema), cinza a 28 % (fixo ou modificador), cinza a 14 % (demais); contorno de 5 pt em `accentColor` (selecionado) ou vermelho (problema).
- `ShortcutsTab` compõe seletor de camada, `ControllerFigureView(model:)` e `ActionPanel(model:)` num `HStack`; o painel toma a largura restante.
- `EditorViewModel` é `ObservableObject` só na main thread; `select(_:)` e `identified(_:)` mudam `selectedButton`; `identified` também força a aba Atalhos. O modo de identificação chega do `InputRouter` por `router.onIdentify` no `AppDelegate`, já na main thread.
- `EditorWindowController` cria a janela uma vez (`isReleasedWhenClosed = false`), com `NSHostingView(rootView: ScrollView(.vertical) { … })`, e a rolagem só vertical foi imposta pelo reteste do PM-1a. A ativação usa clique sintético na barra de título (E003).
- `ActionSummary.text` é público no núcleo; `ButtonID.displayName` é uma extensão no alvo do app (`EditorLabels.swift`).
- `scripts/build-app.sh` copia para o bundle só o binário e `Resources/Info.plist`; `Resources/` não tem mais nada. `Package.swift` não declara `resources:` em nenhum alvo.
- O SDK das Command Line Tools (Swift 6.3.3, macOS 26) traz `WebKit.framework` e `_WebKit_SwiftUI.framework`; o mínimo do app é macOS 13.
- O log tem catálogo fechado, testado por `LogEventCatalogTests` contra chaves proibidas; os eventos `editor.*` são cinco.
- Não há teste automatizado no alvo do app (TD-01).

## 3. Alternativas avaliadas

### 3.1 Como executar HTML, CSS e JS dentro da janela

| Alternativa | Prós | Contras | Veredito |
|-------------|------|---------|----------|
| `WKWebView` em `NSViewRepresentable` | Disponível no macOS 13; processo isolado; `callAsyncJavaScript` e `WKScriptMessageHandler` prontos; `loadFileURL` com escopo de leitura | Consome `scrollWheel`; toma primeiro respondedor; fundo opaco por padrão; carga inicial em centenas de ms | **Escolhida** (D-04) |
| `WebView` do SwiftUI (`_WebKit_SwiftUI`) | API SwiftUI direta | Exige macOS 26, acima do mínimo 13 | Descartada |
| `NSTextView` com `NSAttributedString(html:)` | Sem WebKit | Não executa script, sem clique por elemento, sem CSS moderno | Descartada |
| SwiftUI `Canvas`/`Path` desenhando o DualSense | Sem processo extra, sem recurso no bundle | Contraria a decisão do usuário por página web; sem CSS | Descartada |

### 3.2 Onde a página vive e como chega ao bundle

| Alternativa | Prós | Contras | Veredito |
|-------------|------|---------|----------|
| Pasta `Resources/ControllerFigure/` copiada por `build-app.sh` para `Contents/Resources/` | Mesma regra de montagem de hoje; `Bundle.main.url` devolve `nil` sem abortar (RN-12); `Package.swift` intacto | Rodar o binário fora do `.app` fica sem figura (o fluxo do projeto sempre usa o `.app` assinado) | **Escolhida** (D-01) |
| `resources: [.copy("ControllerFigure")]` no alvo `JoystickAIPoC` | `swift build` já produz o `.bundle` | O acessor `Bundle.module` gerado chama `fatalError` quando o bundle falta, contra RN-12; o script precisaria copiar o `.bundle` | Descartada |
| HTML, CSS e JS como literais Swift com `loadHTMLString` | Nada no bundle; RN-12 impossível | Sem realce, escape de aspas, diff ilegível; contradiz "recurso do bundle assinado" do esclarecimento 3 | Descartada |

### 3.3 Ponte de estado app → página

| Alternativa | Prós | Contras | Veredito |
|-------------|------|---------|----------|
| `callAsyncJavaScript(_:arguments:)` com o estado como dicionário nativo | Argumentos convertidos pelo WebKit, sem interpolação nem escape; macOS 11+ | Exige `[String: Any]` (obtido de `JSONSerialization` sobre o `JSONEncoder`) | **Escolhida** (D-07) |
| `evaluateJavaScript("figure.render(\(json))")` | Uma chamada | JSON interpolado em código: escape de aspas, barras e U+2028/2029 por conta do app | Descartada |
| `WKUserScript` com o estado inicial | Chega antes do `didFinish` | Não cobre atualizações; o estado inicial pode mudar antes da carga | Descartada |

### 3.4 Ponte de clique página → app

| Alternativa | Prós | Contras | Veredito |
|-------------|------|---------|----------|
| `WKScriptMessageHandler` com `{ button }` validado por `ButtonID(rawValue:)` | Um canal, corpo mínimo, validação trivial | Nenhum relevante | **Escolhida** (D-08) |
| Navegação para `figure://select/cross` interceptada no delegado | Sem handler | Ruidosa, fácil de confundir com navegação real | Descartada |

### 3.5 Conteúdo do usuário na página (RN-07)

| Alternativa | Prós | Contras | Veredito |
|-------------|------|---------|----------|
| Só `textContent` e `classList`; teste automatizado proíbe `innerHTML` e afins no script | Impossível interpretar marcação; verificável | Nenhum | **Escolhida** (D-07, D-03) |
| Escapar HTML no app antes de enviar | Defesa em profundidade | Duplica a responsabilidade e mascara um uso indevido de `innerHTML` | Descartada como única defesa; o teste de D-03 cumpre o papel |

### 3.6 Garantia de ausência de rede (RN-03, RF-08)

| Alternativa | Prós | Contras | Veredito |
|-------------|------|---------|----------|
| CSP `default-src 'none'` na página + delegado de navegação que cancela URLs fora do bundle + teste que inspeciona os arquivos | Cobre subrecursos, navegação e regressão no repositório | `'self'` sob `file://` pode ser tratado como origem opaca pelo WebKit (reserva: arquivo único inline) | **Escolhida** (D-03, D-06) |
| `WKContentRuleList` bloqueando tudo exceto `file:` | Bloqueio no motor | Compilação assíncrona; cache em disco em `~/Library`, contra RN-09 | Descartada |
| Só inspeção manual do bundle | Sem código | Regride sem aviso | Descartada |

### 3.7 Tema e fundo

| Alternativa | Prós | Contras | Veredito |
|-------------|------|---------|----------|
| `color-scheme: light dark`, cores de sistema do WebKit, `underPageBackgroundColor = .clear` | Acompanha `accentColor` e o tema ao vivo; API pública | Dependente do WebKit seguir a `effectiveAppearance` da janela (documentado para macOS, não observado no projeto) | **Escolhida** (D-11) |
| Bridge envia o tema por `figure.setTheme` a partir de KVO de `effectiveAppearance` | Independente da consulta de mídia | Duplica o que o WebKit já faz | Reserva de D-11 |
| `setValue(false, forKey: "drawsBackground")` | Funciona há anos | Chave privada | Descartada |

### 3.8 Rolagem da janela com o ponteiro sobre a figura

| Alternativa | Prós | Contras | Veredito |
|-------------|------|---------|----------|
| Subclasse de `WKWebView` encaminhando `scrollWheel` ao `enclosingScrollView` | Solução conhecida para o macOS; a página nunca rola | Depende da cadeia de respondedores do `NSHostingView` | **Escolhida** (D-09), sonda P-02 |
| Tirar a rolagem da janela | Simples | O PM-1a a exigiu na tela de 900 pt | Descartada |
| `hitTest` devolvendo `nil` no `WKWebView` | Sem interceptar eventos | Bloqueia o clique também | Descartada |

## 4. Padrões aplicáveis

- **Núcleo funcional com casca imperativa** (`architecture.md` §2): `FigureState` é um valor puro; o bridge é a casca que executa efeitos (carga, envio, recepção).
- **Ponte por valor imutável**: o app envia uma cópia codificada do estado; a página não guarda nada além do último estado desenhado.
- **Catálogo fechado de eventos** (ADR-008): o evento novo entra pela fábrica e pelo teste de chaves proibidas.
- **Portão com sonda antes do desenho final** (feature 003, PM-1a): as três dúvidas de WebKit viram sondas com página mínima, antes dos 18 balões.

## 5. Fontes externas

Consultadas por busca nesta sessão de planejamento; os pontos marcados 🟡 no `roadmap.md` continuam dependentes das sondas.

- Apple, `callAsyncJavaScript(_:arguments:in:in:completionHandler:)`: os argumentos são um dicionário `[String: Any]` mapeado para tipos JS pelo WebKit. https://developer.apple.com/documentation/webkit/wkwebview/callasyncjavascript(_:arguments:in:in:completionhandler:)
- Apple, WWDC20 "Discover WKWebView enhancements" (`callAsyncJavaScript`, mundos de conteúdo). https://developer.apple.com/videos/play/wwdc2020/10188/
- Apple Developer Forums, "Scroll parent view of WKWebView": o `WKWebView` consome os eventos de rolagem no macOS; a solução usual é subclasse com `scrollWheel(with:)` encaminhado à cadeia de respondedores. https://developer.apple.com/forums/thread/70106
- Use Your Loaf, "Supporting Dark Mode in WKWebView": o WebKit não escurece conteúdo por conta própria; a página opta por `color-scheme` e usa `prefers-color-scheme`. https://useyourloaf.com/blog/supporting-dark-mode-in-wkwebview/
- W3C CSS archive, mensagem de Timothy Hatcher sobre `color-scheme` no macOS: a escolha é binária e segue a aparência do sistema, do app ou da view. https://lists.w3.org/Archives/Public/public-css-archive/2018Nov/0305.html
- WebKit blog, "A Refined Content Security Policy": suporte a CSP nível 2 no WebKit. https://webkit.org/blog/6830/a-refined-content-security-policy/
- Apple Developer Forums, "allowUniversalAccessFromFileURLs configuration for WKWebView": contexto sobre origens `file://` (não responde à pergunta sobre `'self'`; por isso a sonda P-03). https://developer.apple.com/forums/thread/708660
- MDN, `prefers-reduced-motion`: https://developer.mozilla.org/en-US/docs/Web/CSS/@media/prefers-reduced-motion
- MDN, cores de sistema CSS (`Canvas`, `CanvasText`, `AccentColor`): https://developer.mozilla.org/en-US/docs/Web/CSS/system-color

## 6. Perguntas que ficam para as sondas

| # | Pergunta | Sonda | Decisão afetada |
|---|----------|-------|-----------------|
| 1 | O `WKWebView` dentro do `NSHostingView` com `ScrollView(.vertical)` repassa a rolagem com a subclasse de D-09? | P-02 | D-09 |
| 2 | `acceptsFirstResponder = false` mantém o clique funcionando e deixa o teclado nos campos? | P-02 | D-09 |
| 3 | A CSP `script-src 'self'` carrega `figure.js` sob `file://`? | P-03 | D-06 |
| 4 | `check-signature.sh` dá saída idêntica com `Contents/Resources` no bundle, e a Acessibilidade permanece concedida? | P-03 | D-02 |
| 5 | `underPageBackgroundColor = .clear` deixa o fundo da janela visível, e a troca de tema atualiza a página sem reabrir? | P-01 | D-11 |
| 6 | Quanto tempo leva do `editor.opened` ao primeiro `figure.render` na primeira abertura e nas seguintes? | PM-2 | D-05 |
