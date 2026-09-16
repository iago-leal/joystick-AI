# Impacto no legado: Figura do controle em página web embutida

> Identificador: `004-figura-controle-web`
> Data: `2026-09-15`, revisado em `2026-09-16` (rodada 4)
> Âncora: legado (`_reversa_sdd/architecture.md` + `_reversa_sdd/domain.md`, extração de 2026-09-15), com as specs SDD de `_reversa_sdd/sdd/` como complemento.
> Política de edição no momento da execução (rodadas 1 a 4): `allowLegacyEdits: true`, `allowedPaths` vazio (liberação irrestrita do projeto), relida na ativação de cada rodada.
> Execução: completa; 29 de 29 ações fechadas em quatro rodadas (T001 a T018 na 1; emendas E001 e E002 na 2; T023 a T026 e T029 na 3; T019, T027 e T028 e a emenda E003 na 4), com T020 a T022 dispensadas porque nenhuma sonda do PM-1 reprovou. Falta o portão manual PM-2.

A feature entrega o contrato `FigureState` no `JoystickCore`, a ponte `FigureBridge` com o `WKWebView`, a página com a silhueta do DualSense e os 18 botões com balões e linhas-guia, e a troca da figura em SwiftUI pela página na aba Atalhos, com a figura antiga removida. Duas emendas ajustam a apresentação a partir da observação do usuário (E001, linhas-guia; E003, gatilhos acima dos ombros), e uma terceira, fora do escopo da 004, corrige a quebra dos botões do painel de acorde (E002).

## Arquivos afetados

| Arquivo afetado | Componente | Tipo | Severidade | Justificativa |
|-----------------|------------|------|------------|---------------|
| `Sources/JoystickCore/Config/FigureState.swift` | `JoystickCore` (architecture.md §3, camada Core); `editor/design.md` (003 D-21) | componente-novo | LOW | Valor codificável com os 18 botões da camada; reproduz as regras das fichas (`fixed`, `modifier`, `inherited`, `own`, problema, seleção) e é o único contrato entre editor e página. Coberto por `FigureStateTests`. |
| `Sources/JoystickCore/Config/ButtonLabels.swift` | `JoystickCore` (architecture.md §3) | componente-novo | LOW | `ButtonID.displayName` migrado do app, público, com os 18 textos idênticos (D-13). |
| `Sources/JoystickAIPoC/Editor/EditorLabels.swift` | `editor` (`editor/design.md` §Interface) | regra-alterada | LOW | Perde a extensão de `ButtonID`; `layerName` e os demais textos continuam iguais e passam a usar o rótulo do núcleo. |
| `Sources/JoystickCore/Log/LogEventCatalog.swift` | `diagnostics-log` (architecture.md §4 I-11, ADR-008; `editor/design.md` §Observabilidade) | delta-de-contrato-externo | LOW | Evento novo `editor.figure_unavailable { reason }`, nível `warn`, sem conteúdo; `logSchema` segue 1. Coberto por `LogEventCatalogTests` (chaves proibidas e campos). |
| `Sources/JoystickAIPoC/Editor/EditorViewModel.swift` | `editor` (`editor/design.md` §Interface, `EditorViewModel`) | regra-alterada | MEDIUM | Ganha `figureState` derivado a cada leitura (recalcula `draft.issues`) e `@Published figureUnavailable`, zerado em `prepareForOpen`; `select`, `identified` e `hasIssue` inalterados (D-14). |
| `Sources/JoystickAIPoC/Editor/FigureBridge.swift` | `editor` (architecture.md §3, camada App; integração nova I-13 WebKit) | componente-novo | HIGH | Primeiro uso de `WebKit` no app: processo WebContent, armazenamento não persistente, carga por `loadFileURL`, navegação restrita a `index.html`, `callAsyncJavaScript` sem JSON interpolado, `WKScriptMessageHandler` que só aceita `ButtonID` válido, tratamento de falhas com um registro por abertura. `FigureWebView` recusa o primeiro respondedor, encaminha a rolagem ao `NSScrollView` da janela e suprime o menu de contexto (D-04 a D-10, D-14, D-15). Sem teste automatizado (TD-01); sondas P-01 a P-03. |
| `Sources/JoystickAIPoC/Editor/ControllerFigureWebView.swift` | `editor` (architecture.md §3, camada App) | componente-novo | LOW | `NSViewRepresentable` que devolve sempre o mesmo `webView` da ponte; `NSView` vazio quando a ponte não o criou (recurso ausente). |
| `Sources/JoystickAIPoC/Editor/ShortcutsTab.swift` | `editor` (`editor/design.md` §Interface, `ShortcutsTab`; `code-analysis.md` §8.3) | regra-alterada | MEDIUM | `ControllerFigureView(model:)` sai; entra `ControllerFigureWebView(bridge:)` em 830 × 620 pt ou, com `figureUnavailable`, o quadro com "A figura do controle não pôde ser carregada; reinstale o app." (RN-12, D-10). Seletor de camada e `ActionPanel` iguais. |
| `Sources/JoystickAIPoC/Editor/EditorRootView.swift` | `editor` (`editor/design.md` §Interface) | regra-alterada | LOW | Recebe e repassa o `FigureBridge` à aba Atalhos; abas, faixas e rodapé inalterados. |
| `Sources/JoystickAIPoC/App/AppDelegate.swift` | `app-shell` (architecture.md §3, ponto único de montagem) | regra-alterada | LOW | Cria `FigureBridge(model:log:)` ao lado de `EditorViewModel` e o entrega a `EditorRootView(model:figure:)`; a ordem de inicialização (RI-02) não muda. |
| `Sources/JoystickAIPoC/Editor/ControllerFigureView.swift` | `editor` (`editor/design.md` 003 D-21; `code-analysis.md` §8.3) | componente-extinto | MEDIUM | Fichas em SwiftUI sem uso desde T017, removidas em T019 com autorização do usuário; `grep` sem referências, build e testes verdes. A evidência `ControllerFigureView.swift:4-8` de `editor/design.md` deixa de existir. |
| `Resources/ControllerFigure/index.html`, `figure.css`, `figure.js` | `editor` (página da figura; `inventory.md` §7) | componente-novo | MEDIUM | Primeiro código executado fora do Swift: HTML, CSS e JS locais com CSP `default-src 'none'`, `color-scheme`, `textContent` apenas, delegação de clique e `postMessage`. Silhueta plana do DualSense com 18 grupos `[data-button]` (desenho, rótulo, área de acerto de 60 × 60 e linha-guia saindo da borda da forma, E001) e 18 balões posicionados pela tabela `positions`. Vista de cima (E003): L2 e R2 na faixa superior, acima de L1 e R1. Coberto por `FigureAssetsTests` (referências externas, subrecursos, CSP, APIs proibidas). |
| `scripts/build-app.sh` | build e bundle (`inventory.md` §7, ADR-002) | delta-de-contrato-externo | MEDIUM | Copia `Resources/ControllerFigure/` para `Contents/Resources/ControllerFigure/` antes do `codesign`, falhando com mensagem se a pasta ou um dos três arquivos faltar; a assinatura passa a selar os recursos (D-01, D-02). O requisito designado não muda; a sonda P-03 confere as permissões. |
| `Tests/JoystickCoreTests/FigureStateTests.swift` | testes | componente-novo | LOW | Dez testes: ordem e contagem, padrão na base, camada L2, problema, seleção, sem modificadores, texto intacto, codificação (instantâneo), rótulos dos 18 botões e motivos em `snake_case`. |
| `Tests/JoystickCoreTests/FigureAssetsTests.swift` | testes | componente-novo | LOW | Cinco testes sobre os três arquivos da página (D-03). |
| `Tests/JoystickCoreTests/LogEventCatalogTests.swift` | testes | regra-alterada | LOW | `editor.figure_unavailable` em `sampleEvents`, no mapa nome → nível e num teste de campos. |
| `Sources/JoystickAIPoC/Editor/EditorMetrics.swift`, `ChordEditor.swift`, `ActionPanel.swift` | `editor` (`editor/design.md` §Interface, painel de ação e editor de acorde da 003) | regra-alterada | LOW | Emenda E002, fora do escopo da 004 e pedida pelo usuário: as `LazyVGrid` adaptativas davam lugar a botões espremidos e rótulos quebrados em sílabas; entra `FlowLayout` (`Layout` do macOS 13), que dispõe cada botão no tamanho ideal e quebra a linha entre botões. Opções, ações e tamanhos mínimos de alvo inalterados. |

## Diff conceitual por componente

**Editor, figura.** Antes, a figura era um `ZStack` com 18 `Button` de 160 × 96 pt em posições fixas, cada um calculando na hora o rótulo, o resumo e os estados a partir do modelo. Agora o modelo expõe um valor puro, `FigureState`, com essas mesmas regras; a ponte o serializa e o entrega a uma página local por `figure.render`, que só escreve texto e classes. O clique volta como identificador e vira `select`, como antes. A seleção pelo modo de identificação continua chegando ao modelo pelo mesmo caminho e aparece na figura pela mesma atualização de estado. A página desenha os 18 botões numa vista de cima do controle, com os gatilhos L2 e R2 na borda de trás; os cenários da figura completa são verificados no PM-2.

**Editor, falha.** Antes não havia modo de a figura faltar. Agora, sem `index.html` no bundle, com falha de carga, com erro no script ou com duas quedas do processo WebContent em 60 s, a aba mostra um quadro do mesmo tamanho com a mensagem de RN-12, o painel e a identificação continuam operáveis, e o log recebe `editor.figure_unavailable` com o motivo, uma vez por abertura.

**Núcleo.** `JoystickCore` ganha dois tipos de valor (`FigureState`, `FigureButton`), um enum de motivo (`FigureFailureReason`) e o rótulo de exibição dos botões. Continua importando só `Foundation`; `WebKit` fica restrito ao alvo do app.

**Log.** Um evento novo, com um campo fechado; nenhum evento existente muda. A página não escreve no log.

**Build e bundle.** O `.app` passa a ter `Contents/Resources/ControllerFigure/` com três arquivos, selados pela mesma assinatura. O script recusa montar sem eles. `Package.swift` e `Info.plist` não mudam.

**Editor, painel de acorde (E002).** Os grupos de botões do editor de acorde e do painel de ação deixam de usar grades adaptativas e passam a fluir em linhas, sem mudar opções nem comportamento.

**Integrações.** Entra o WebKit (processo WebContent) como hospedeiro da figura, sem rede, sem armazenamento persistente e sem navegação fora do arquivo do bundle. A CSP da página e o `FigureAssetsTests` guardam essa fronteira no repositório; a sonda P-03 a confere no hardware.

## Preservadas

Regras 🟢 do `domain.md` e da extração que continuam intactas, com a evidência conferida nesta rodada:

- **003 RN-02** (herança da base; "nenhuma" é ação própria; botões de apontamento não são modificadores): `FigureState` consome `resolvedAction` e `pointerButtons` sem reinterpretá-los; `FigureStateTests.camadaL2` e `semModificadores`.
- **003 RN-14** (log sem textos, rótulos nem acordes): o evento novo leva só `reason`; `LogEventCatalogTests.eventosDeAtalhosSemTextoTeclaNemAcorde` o inclui.
- **003 RN-16** (com o editor aberto a configuração vigente continua ativa; identificação só seleciona): `identified(_:)`, `InputRouter` e `onIdentifyingChange` não mudaram.
- **Modo de identificação** e **Escala de TV** (`domain.md` §2): a seleção pelo controle segue o mesmo caminho até o modelo; a página usa rótulo de 26 px, resumo de 24 px e área de acerto de 60 × 60 px.
- **RI-02** (o leitor do controle inicia por último): a ponte é criada junto com o modelo do editor, antes de `controllerReader.start()`.
- **RI-23** e **RI-24** (abertura em nível flutuante com clique sintético; devolução do foco): `EditorWindowController` não foi tocado.
- **RI-25** (menu principal só com "Editar"): `EditMenu` não foi tocado; `FigureWebView` recusa o primeiro respondedor para os campos continuarem recebendo colar e ditado (sonda P-02 aprovada em 2026-09-16).
- **architecture.md §3**: `JoystickCore` só importa `Foundation`; `app-shell` é o único ponto de montagem (a ponte nasce em `AppDelegate`).
- **architecture.md §6, Privacidade**: catálogo fechado de eventos, verificado por `LogEventCatalogTests`.
- **`editor/design.md`, decisões 003 D-18, D-19, D-20, D-22, E003, D-24, D-25**: ícone na barra, métricas de TV, rascunho puro, acorde por gravação, ativação por clique, identificação na fila `input` e conflito externo, todas sem alteração.

## Modificadas

Regras 🟢 alteradas ou cuja evidência muda de lugar; cada uma gera um item no `regression-watch.md`:

- **`editor/design.md`, "Figura com resumo por camada (003 D-21)"** com evidência `ControllerFigureView.swift:4-8`: a regra permanece (figura de 830 × 620 com resumo por camada, herdados esmaecidos, fixos e modificadores em cinza, problemas em vermelho), mas a evidência passa a `FigureState.swift`, `FigureBridge.swift`, `ShortcutsTab.swift` e `Resources/ControllerFigure/`. O arquivo citado foi removido em T019.
- **`editor/design.md` §Interface, `ShortcutsTab`** ("seletor de camada, `ControllerFigureView` (tela 830 × 620, fichas 160 × 96, posições fixas) e `ActionPanel`"): as fichas de 160 × 96 saem; entram `ControllerFigureWebView` sobre `FigureBridge` e o quadro de RN-12.
- **`code-analysis.md` §8.3 Interface** (figura com os 18 botões em `ControllerFigureView.swift:9-70`): a descrição funcional continua válida, a implementação muda para a página, que desenha os 18 botões numa vista de cima, com L2 e R2 acima de L1 e R1 (E003).
- **`inventory.md` §7, Build do app**: além do binário e do `Info.plist`, o bundle leva `Contents/Resources/ControllerFigure/`, selado pelo mesmo `codesign`; o script falha sem a pasta.
- **`dependencies.md` §3, Frameworks do sistema por alvo**: `JoystickAIPoC` passa a importar `WebKit`.
- **`architecture.md` §4, Integrações externas**: entra o WebKit (processo WebContent) como integração nova, com armazenamento não persistente e sem rede.
- **Localização de `ButtonID.displayName`** (`EditorLabels.swift:4-27`, citada por `data-delta.md` §2 e pela extração do editor): agora em `Sources/JoystickCore/Config/ButtonLabels.swift`.
