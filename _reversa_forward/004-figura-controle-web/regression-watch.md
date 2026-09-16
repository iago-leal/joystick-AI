# Regression watch: Figura do controle em página web embutida

> Identificador: `004-figura-controle-web`
> Âncora: legado (`_reversa_sdd/architecture.md`, `_reversa_sdd/domain.md`, extração de 2026-09-15). Os itens do watch principal nascem da seção "Modificadas" do `legacy-impact.md`; só regras originalmente 🟢 entram nele. As decisões 🟡 do roadmap, que dependem das sondas do PM-1, ficam em "Observações", sem peso de regressão.

## Watch principal

| ID | Origem (arquivo, seção) | Regra esperada após mudança | Tipo de verificação | Sinal de violação |
|----|--------------------------|------------------------------|---------------------|-------------------|
| W001 | `_reversa_sdd/editor/design.md`, tabela de decisões, "Figura com resumo por camada (003 D-21)" | A figura de 830 × 620 pt com resumo da ação por camada, herdados esmaecidos, fixos e modificadores em cinza e problemas em vermelho continua existindo, agora como `FigureState` (núcleo) desenhado pela página `Resources/ControllerFigure/` via `FigureBridge`; a evidência deixa de ser `ControllerFigureView.swift`. | redação | Re-extração ainda citando `ControllerFigureView.swift`, ou sem localizar a figura em `FigureState.swift` + `FigureBridge.swift` + `Resources/ControllerFigure/`. |
| W002 | `_reversa_sdd/editor/design.md` §Interface, item `ShortcutsTab` | `ShortcutsTab` compõe seletor de camada, `ControllerFigureWebView(bridge:)` em 830 × 620 pt (ou o quadro com "A figura do controle não pôde ser carregada; reinstale o app." quando `figureUnavailable != nil`) e `ActionPanel`. | redação | Menção a fichas de 160 × 96 ou a `ControllerFigureView`; ausência do quadro de RN-12. |
| W003 | `_reversa_sdd/code-analysis.md` §8.3 Interface, item "Atalhos" | Figura de 830 × 620 pt com os 18 botões nas posições físicas, resumo por camada e os cinco estados, implementada pela página web; o painel de ação segue igual. | redação | Descrição apontando `ControllerFigureView.swift:9-70`, ou figura com menos de 18 botões após a Fase 4. |
| W004 | `_reversa_sdd/inventory.md` §7, "Build do app" | `build-app.sh` monta `Contents/MacOS`, `Contents/Info.plist` e `Contents/Resources/ControllerFigure/` (três arquivos) antes do `codesign`, e falha com mensagem se a pasta ou um arquivo faltar. | redação | Extração descrevendo o bundle só com binário e `Info.plist`; script montando sem a pasta. |
| W005 | `_reversa_sdd/dependencies.md` §3, frameworks por alvo | `JoystickAIPoC` importa `WebKit` (só em `FigureBridge.swift`); `JoystickCore` e `poc-tools` não. | presença | `import WebKit` fora do alvo do app, ou tabela de frameworks sem `WebKit` no app. |
| W006 | `_reversa_sdd/architecture.md` §3, "`JoystickCore` não importa nenhum framework além de `Foundation`" | Continua verdadeiro com `FigureState.swift` e `ButtonLabels.swift` no núcleo. | presença | Qualquer `import` além de `Foundation` em `Sources/JoystickCore/`. |
| W007 | `_reversa_sdd/architecture.md` §6, Privacidade; `domain.md` 003 RN-14 | O catálogo do log ganha só `editor.figure_unavailable { reason: resource_missing \| load_failed \| process_terminated }`, nível `warn`, sem texto, rótulo, tecla nem caminho; `logSchema` 1. | presença | Evento com outro campo, ou `LogEventCatalogTests` sem o evento em `sampleEvents`. |
| W008 | `_reversa_sdd/architecture.md` §4, Integrações externas | Integração nova (WebKit, processo WebContent) listada: `WKWebsiteDataStore.nonPersistent()`, sem rede, navegação restrita ao `index.html` do bundle, `messageHandlers.figure` como único canal página → app. | presença | Extração sem a integração; `~/Library/WebKit/dev.iagoleal.joystick-ai.poc` existente; handler adicional ou navegação permitida fora do bundle. |
| W009 | `_reversa_sdd/editor/design.md` (rótulos), `EditorLabels.swift:4-27` na extração | `ButtonID.displayName` vive em `Sources/JoystickCore/Config/ButtonLabels.swift`, público, com os 18 textos (✕ ○ □ △ L1 R1 L2 R2 L3 R3 Options Create PS Touchpad ↑ ↓ ← →). | presença | Extensão duplicada no app, ou algum dos 18 textos diferente (`FigureStateTests.rotulosDos18Botoes`). |
| W010 | `_reversa_sdd/code-analysis.md` §8 (lista de arquivos do editor), `editor/design.md` | `Sources/JoystickAIPoC/Editor/ControllerFigureView.swift` não existe e nenhum arquivo o referencia (vale a partir de T019, pendente de confirmação nesta rodada). | ausência | Arquivo presente, ou `grep ControllerFigureView` com resultado em `Sources/`. |

### Acréscimos da rodada 4 (2026-09-16)

| ID | Origem (arquivo, seção) | Regra esperada após mudança | Tipo de verificação | Sinal de violação |
|----|--------------------------|------------------------------|---------------------|-------------------|
| W011 | `_reversa_sdd/code-analysis.md` §8.3 Interface, item "Atalhos" (posições físicas dos 18 botões); emenda E003 | A figura é uma vista de cima do DualSense: L2 e R2 ficam acima de L1 e R1 no SVG, e seus balões na faixa superior, com L1 e R1 no topo das colunas laterais. | presença | `index.html` com o grupo `l1` acima de `l2` (ou `r1` acima de `r2`), ou `positions` de `figure.js` com `l1`/`r1` em `y: 8`. |

W010 passa a valer sem ressalva: T019 removeu `ControllerFigureView.swift` em 2026-09-16.

## Observações

Decisões 🟡 do `roadmap.md` implementadas nesta rodada e que só as sondas do PM-1 confirmam; sem peso de regressão até a re-extração as classificar.

| ID | Origem (arquivo, seção) | Regra esperada | Tipo de verificação | Sinal de violação |
|----|--------------------------|----------------|---------------------|-------------------|
| O001 | `roadmap.md` D-06; `interfaces/figure-bridge.md` §6 | CSP `default-src 'none'; script-src 'self'; style-src 'self'` aceita `figure.css` e `figure.js` sob `file://` (sonda P-03, passo 4). | presença | Página sem estilo ou sem clique; reserva: arquivo único inline (T022). |
| O002 | `roadmap.md` D-09 | `FigureWebView.scrollWheel` encaminha ao primeiro `NSScrollView` da cadeia de respondedores; `acceptsFirstResponder` falso; menu de contexto suprimido por `menu(for:)`, `willOpenMenu` e `contextmenu` cancelado (sonda P-02). | presença | Janela sem rolar sobre a figura; anel de foco na figura; menu do WebKit no R2. |
| O003 | `roadmap.md` D-11 | Tema pelo `color-scheme` e cores de sistema, fundo transparente por `underPageBackgroundColor = .clear` (sonda P-01). | presença | Retângulo opaco atrás da silhueta; tema sem acompanhar a troca ao vivo; reserva: `figure.setTheme` por KVO (T020). |
| O004 | `roadmap.md` D-10 (c); `interfaces/figure-bridge.md` §2 | Primeira queda do WebContent recarrega; segunda em 60 s publica `process_terminated`. | presença | Figura em branco sem mensagem após queda, ou mais de um `editor.figure_unavailable` por abertura. |
| O005 | `roadmap.md` D-02 | Assinatura com `Contents/Resources` preserva o requisito designado e as permissões (sonda P-03, passos 1 e 2). | presença | `check-signature.sh` diferente antes e depois; novo pedido de Acessibilidade ou Input Monitoring. |

Desfecho das sondas do PM-1 (rodada 4, 2026-09-16): O001 e O005 confirmadas (P-03 aprovada nos seis passos); O002 confirmada (P-02 aprovada); O003 com o tema escuro e o fundo transparente observados, mas sem confirmação explícita do tema claro nem da troca ao vivo, a conferir no passo 15 do PM-2; O004 segue sem verificação em hardware. Nenhuma reserva (T020 a T022) foi acionada.

| ID | Origem (arquivo, seção) | Regra esperada | Tipo de verificação | Sinal de violação |
|----|--------------------------|----------------|---------------------|-------------------|
| O006 | `actions.md`, rodada 2, emenda E002 (fora do escopo da 004) | Os grupos de botões de `ChordEditor` e `ActionPanel` usam `FlowLayout` e não quebram rótulos em sílabas na largura de 470 pt do painel. | presença | Volta de `LazyVGrid` adaptativa nesses arquivos, ou "Forward Delete" quebrado no painel. |

## Histórico de re-extrações

## Arquivadas
