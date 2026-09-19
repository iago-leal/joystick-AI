# Impacto no legado: Sugestão de palavras no teclado remoto

> Identificador: `009-sugestao-de-palavras`
> Data: `2026-09-19`
> Âncora: legado (`_reversa_sdd/architecture.md` + `_reversa_sdd/domain.md`, extração de 2026-09-15, com os adendos das features 001 a 007), com as specs SDD de `_reversa_sdd/` como complemento. A 008, base desta feature, está em código mas sem adendo; seus artefatos em `_reversa_forward/008-iphone-teclado-remoto/` servem de referência para os componentes remotos.
> Política de edição no momento da execução: `allowLegacyEdits: true`, `allowedPaths` vazio (liberação irrestrita do projeto), relida na ativação do `/reversa-coding`.
> Execução: completa; 28 de 28 ações fechadas (T001 a T025 na primeira rodada; T026 e T027 após o PM-0, com P-01 a P-04 aprovadas e T027 não aplicável; T028 após o PM-1, aprovado exceto o passo 14, não executado por escolha do usuário). Suíte: 351 → 379 testes, 39 → 40 suítes, todos verdes, medidos com o SDK 26.5 como na 008; `swift build -c release` sem avisos do código; app instalado e assinado com a identidade estável.

O Mac passa a saber o texto que as teclas do iPhone produzem. Depois de injetar cada tecla, o app a traduz pela fonte de entrada ativa, com as teclas mortas, e alimenta uma máquina pura do núcleo que guarda em memória até 200 caracteres do que foi escrito, aplica as regras de descarte, de caixa e de palavra com cara de código e decide o que pedir ao motor de previsão do macOS. As sugestões voltam pelo canal da 008, e a aceitação digita só o sufixo que falta, seguido de espaço, pelo `KeyboardInjector.type`. Nada vai a disco nem ao log, salvo a contagem de sugestões aceitas no fim da sessão.

## Arquivos afetados

| Arquivo afetado | Componente | Tipo | Severidade | Justificativa |
|-----------------|------------|------|------------|---------------|
| `Sources/JoystickCore/Remote/SuggestionContext.swift` | Núcleo, remote (008; `architecture.md` §3) | componente-novo | HIGH | Guarda o contexto recente, conteúdo digitado pelo usuário, e decide consulta, filtro e aceitação. É a garantia de RN-02, RN-04, RN-12 e RN-13, e do limite de 200 caracteres. |
| `Sources/JoystickCore/Remote/RemoteKeyboardMessage.swift` | Núcleo, remote (008) | delta-de-contrato-externo | MEDIUM | Cliente ganha `prefs` e `pick`; servidor ganha `suggest`, com até três palavras de 1 a 48 caracteres. Primeira mensagem do Mac com conteúdo derivado do que foi digitado. |
| `Sources/JoystickCore/Log/LogEventCatalog.swift` | `diagnostics-log` (`architecture.md` §5) | delta-de-contrato-externo | LOW | `remote.disconnected` ganha `suggestions`, só contagem; `logSchema` segue 1. |
| `Sources/JoystickAIPoC/Remote/KeyTextTranslator.swift` | app, remote-keyboard (008) | componente-novo | MEDIUM | `UCKeyTranslate` com estado de tecla morta próprio, sobre o layout lido na main thread; zera a cada descarte e troca de fonte. |
| `Sources/JoystickAIPoC/Remote/WordSuggester.swift` | app, remote-keyboard; integração nova I-16 | componente-novo | MEDIUM | `NSSpellChecker.requestCandidates` com ortografia `pt_BR` ou `en`, etiqueta por sessão, aquecimento, um pedido em curso com o pendente substituído e prazo de 1 s por pedido. |
| `Sources/JoystickAIPoC/Remote/SuggestionProbe.swift` | app, depuração | componente-novo | MEDIUM | Arquivo das sondas P-01 e P-02, só com `JOYSTICK_SUGGEST_PROBE`; grava texto traduzido fora da entrada segura. Único caminho pelo qual texto digitado chega a disco, e só por ato explícito do usuário. |
| `Sources/JoystickAIPoC/Remote/RemoteKeyboardActions.swift` | app, remote-keyboard (008) | regra-alterada | HIGH | Depois de cada `keyDown` e repetição, alimenta o contexto ou descarta (setas, Esc, ⌘ ou ⌃, ⌥⌫, portão fechado, entrada segura); trata `prefs` e `pick`; `end()` devolve teclas e sugestões aceitas e apaga o contexto. A ordem tecla antes de sugestão (RN-09) mora aqui. |
| `Sources/JoystickAIPoC/Remote/RemoteKeyboardService.swift` | app, remote-keyboard (008) | regra-alterada | MEDIUM | Liga o sugeridor ao início e ao fim da sessão, leva as consultas à main thread, envia `suggest` só da revisão atual, descarta na troca de fonte e registra `suggestions`. |
| `Sources/JoystickAIPoC/Remote/KeyboardLayoutReader.swift` | app, remote-keyboard (I-15) | regra-alterada | LOW | `currentLayout()` extraído de `labels(for:)`, sem mudança nos rótulos. |
| `Sources/JoystickAIPoC/Injection/KeyboardInjector.swift` | `injection` (RN-IN-02) | regra-alterada | LOW | Expõe `enabled`, leitura do portão; nenhum evento postado muda. |
| `Sources/JoystickAIPoC/Pointer/InputRouter.swift` | `pointer`, roteamento (002 RN-03, 003 RN-16) | regra-alterada | LOW | `onControllerButtonDown` a cada botão não sintético, antes da paleta e do modo de identificação; o roteamento não muda. |
| `Sources/JoystickAIPoC/App/AppDelegate.swift` | `app-shell`, montagem (I-07) | regra-alterada | LOW | Monta tradutor e sugeridor; liga os descartes externos (botão do controle, `NSWorkspace.didActivateApplicationNotification`). |
| `Resources/RemoteKeyboard/index.html`, `keyboard.css`, `keyboard.js` | página do teclado (008) | regra-alterada | MEDIUM | Barra ampliada à altura de uma linha de teclas, com indicador, três sugestões, seletor PT / EN, ocultar e "Sair"; preferências em `localStorage`; esmaecimento e inatividade da faixa; `pick` por toque que termina sobre a sugestão. |
| `Tests/JoystickCoreTests/SuggestionContextTests.swift` | testes | regra-nova | LOW | Suíte nova, 23 testes. |
| `Tests/JoystickCoreTests/RemoteKeyboardMessageTests.swift`, `RemoteKeyboardAssetsTests.swift`, `LogEventCatalogTests.swift` | testes | regra-alterada | LOW | +4 testes de mensagem (7 → 11), +1 de ativos (5 → 6); `LogEventCatalogTests` segue com 11, com `suggestions` na amostra e chaves proibidas das sugestões. |
| `localStorage` da página no iPhone (`remoteKeyboardPrefs`) | dados fora do Mac (`data-delta.md` §2) | delta-de-dados | LOW | `{lang, visible}`, sem conteúdo digitado. `config.json` não muda. |
| `~/Library/Logs/joystick-ai/poc-*.jsonl` (formato) | `diagnostics-log` | delta-de-dados | LOW | Campo `suggestions` em `remote.disconnected`. |
| Integração I-16 (motor de previsão de texto); I-07 (AppKit) | integrações externas (`architecture.md` §4) | delta-de-contrato-externo | MEDIUM | Consulta local de candidatos, sem rede nem permissão TCC nova; observação da troca de aplicativo em foco e consulta a `IsSecureEventInputEnabled()`. |

## Diff conceitual por componente

**Privacidade (001 RN-12, `permissions.md` §4).** Até a 008, o app nunca conhecia o texto digitado: injetava códigos de tecla e textos fixos da configuração. Agora guarda em memória um trecho do que o usuário escreve pelo iPhone, até 200 caracteres, apagado a cada descarte e no fim da sessão, e envia à página palavras derivadas dele. O trecho não vai ao log nem a disco, e em entrada segura nem chega a ser montado. A exceção é a sonda de depuração, que só existe com a variável de ambiente e não grava texto em entrada segura.

**Núcleo.** `SuggestionContext` segue o estilo da `RemoteKeyboardMachine`: puro, só `Foundation`, com a palavra em composição e a última fronteira derivadas do contexto, de modo que apagar um espaço devolve a palavra anterior, como no aplicativo em foco. O filtro só aceita palavras que estendem exatamente a digitada, e por isso aceitar nunca apaga texto no Mac, mesmo com o contexto dessincronizado.

**`injection`.** Nenhuma mudança de comportamento: a aceitação usa `type`, o mesmo caminho das ações de texto (RN-IN-12), e o portão continua decidindo tudo (RN-IN-02). O injetor só expõe a leitura do portão, para que uma tecla barrada não entre no contexto.

**`pointer` e `app-shell`.** O roteador ganha um observador a mais, sem mudar para onde vai cada botão; a montagem liga os dois descartes externos. A troca da fonte de entrada, já observada pela 008, passa a descartar o contexto e a trocar o layout do tradutor.

**Página.** A barra de estado da 008 vira a faixa de sugestões. Continua sem HTML montado a partir de texto; as palavras entram por `textContent`. O toque numa sugestão não passa pelos manipuladores das teclas e não envia `down` nem `up`.

## Preservadas

Regras 🟢 de `_reversa_sdd/domain.md` e das specs que continuam intactas:

- 001 RN-01 a RN-11: controle, zonas mortas, gatilhos, touchpad, precisão, clique duplo, telas e mapeamento do ponteiro.
- 002 RN-01 a RN-07 e E001; 003 RN-16: paleta e modo de identificação recebem os mesmos botões de antes; `onControllerButtonDown` só observa.
- 003 RN-01 a RN-15: atalhos, configuração e editor; `config.json` não ganha campo.
- RN-IN-02: a injeção começa desligada e só o portão a altera; `pick` com o portão fechado não digita nada.
- RN-IN-08, RN-IN-10, RN-IN-13, RN-IN-17: flags, setas, soltura forçada e contagem de modificadores, sem mudança.
- RN-IN-12: o texto da sugestão aceita sai unidade UTF-16 por unidade, com `flags` vazias, sem Return.
- RN-IN-16 e 003 RN-14: nenhuma palavra digitada, sugerida ou escolhida vai ao log.
- RI-01 a RI-29: instância única, ordem de montagem, permissões, cursor, HID e demais regras implícitas.

## Modificadas

| Regra | Antes | Depois | Tipo |
|-------|-------|--------|------|
| 001 RN-12 (`domain.md` §3.1) e `permissions.md` §4 | Sem rede; entradas só no log e nos resultados locais; o app não conhece o texto digitado | O teclado remoto guarda em memória até 200 caracteres do que o iPhone escreve, nunca em disco nem no log, e envia pelo canal da 008 só as palavras sugeridas; em entrada segura, nada é guardado | alterada |
| RN-IN-16 (`injecao-de-eventos/requirements.md`) e 003 RN-14 (`domain.md` §3.3) | Teclas, acordes e textos nunca vão ao log | Idem, e `remote.disconnected` passa a trazer só a contagem `suggestions` | estendida |
| RN-IN-02 (`injecao-de-eventos/requirements.md`) | O portão decide teclas, texto e cliques do controle e do teclado remoto | Decide também a aceitação de sugestão, nova origem de texto; recusada, o contexto não muda | estendida |
