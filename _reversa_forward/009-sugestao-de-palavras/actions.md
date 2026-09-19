# Actions: Sugestão de palavras no teclado remoto

> Identificador: `009-sugestao-de-palavras`
> Data: `2026-09-19`
> Roadmap: `_reversa_forward/009-sugestao-de-palavras/roadmap.md`

## Resumo

| Métrica | Valor |
|---------|-------|
| Total de ações | 28 |
| Paralelizáveis (`[//]`) | 12 |
| Maior cadeia de dependência | 10 (T001 → T002 → T003 → T004 → T015 → T016 → T017 → T019 → T024 → T025), seguida do PM-0, de T026, T027, do PM-1 e de T028 |

## Convenções desta decomposição

### Portões manuais

Passagens que dependem de ato humano não recebem ID `T`; aparecem como `PM-n` na coluna de dependências. O `/reversa-coding` para ao alcançar um portão e só segue quando o usuário relatar o resultado.

| Portão | Ato do usuário | Requer | Referência | Libera |
|--------|----------------|--------|------------|--------|
| PM-0 | Com o app instalado, executar o `onboarding.md` §1 e responder às sondas P-01 a P-04 do `investigation.md` §5 | T025 | Roadmap §4 (premissas), D-02, D-05, D-07, D-09 | T026 |
| PM-1 | Executar o roteiro do `onboarding.md` §3 (18 passos) com o iPhone preso ao controle | T026, T027 | Critério de pronto do roadmap §10 | T028 |

Se P-01 for reprovada no PM-0, a proteção de RN-06 não se sustenta: o `/reversa-coding` para e devolve a decisão ao usuário, sem seguir para o PM-1. A maior cadeia conta apenas ações `T`.

### Ordem das fases

Os testes da Fase 2 dependem dos tipos criados na Fase 3; o `/reversa-coding` executa pela coluna de dependências, e não pela ordem das tabelas. Os tipos do núcleo ficam em `Sources/JoystickCore/Remote/`, e os do app em `Sources/JoystickAIPoC/Remote/`.

### Dependência da 008

A 009 parte do código atual da 008, pausada com a T036 aberta. Nenhuma ação desta lista altera o comportamento das teclas, os passos pendentes do PM-1 da 008 nem os artefatos da pasta `_reversa_forward/008-iphone-teclado-remoto/`.

### Correspondência com o roadmap

| Decisões do roadmap | Ações |
|---------------------|-------|
| D-01 (motor de previsão, idioma, aquecimento) | T014, T017 |
| D-02 (tradução tecla → texto) | T013, T015, T020 |
| D-03 (`SuggestionContext` no núcleo) | T002, T003, T004, T007, T008, T009 |
| D-04 (filtro por prefixo exato) | T004, T009 |
| D-05 (aceitação por `pick` e `type`) | T005, T016, T023 |
| D-06 (gatilhos de descarte) | T015, T017, T018, T019 |
| D-07 (entrada segura) | T015, T020 |
| D-08 (filas, pedido único, revisão) | T014, T017 |
| D-09 (faixa na barra superior) | T021, T023, T027 |
| D-10 (faixa esmaecida e inativa) | T023 |
| D-11 (preferências no iPhone) | T016, T022 |
| D-12 (protocolo aditivo) | T005, T010, T012, T022, T023 |
| D-13 (log) | T006, T011, T017 |

## Fase 1, Preparação

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T001 | Registrar nas notas de execução o número de testes verdes antes de qualquer mudança (esperado 351, com `SDKROOT` do SDK 26.5 e o `-plugin-path` descritos na T001 da 008) e o estado de `.reversa/reversa-config.json` lido na ativação do `/reversa-coding` | - | - | `_reversa_forward/009-sugestao-de-palavras/actions.md` | 🟢 | `[X]` |

## Fase 2, Testes

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T007 | Criar `SuggestionContextTests` para a entrada: texto acumula na palavra em composição e no contexto; espaço, Return e Tab encerram a palavra e mantêm o contexto; apagar remove o último caractere; apagar com contexto vazio descarta; o contexto guarda só os últimos 200 caracteres; sinais de abertura iniciais ficam fora da palavra; cada mudança sobe a revisão; `.discard` esvazia tudo | T002 | `[//]` | `Tests/JoystickCoreTests/SuggestionContextTests.swift` | 🟢 | `[X]` |
| T008 | Em `SuggestionContextTests`, cobrir `query(visible:)`: modo `complete` com palavra só de letras; nada com `/`, `~`, `.`, `-`, `_`, `=` ou dígito na palavra (RN-13); modo `next` só após espaço que encerrou palavra só de letras; nada após Return ou Tab, com contexto vazio ou com a faixa oculta (RN-12, RN-14) | T003, T007 | - | `Tests/JoystickCoreTests/SuggestionContextTests.swift` | 🟢 | `[X]` |
| T009 | Em `SuggestionContextTests`, cobrir `filter` e `accept`: tira o espaço final e a própria palavra digitada; aplica a caixa da primeira letra digitada; só mantém palavras que estendem exatamente a palavra em composição, só de letras e sem repetição, até três; no modo `next` mantém a caixa do motor; revisão velha devolve `nil`; `accept` devolve sufixo mais espaço, atualiza o contexto e soma uma aceita | T004, T008 | - | `Tests/JoystickCoreTests/SuggestionContextTests.swift` | 🟢 | `[X]` |
| T010 | Em `RemoteKeyboardMessageTests`, decodificar `prefs` e `pick` e recusar `lang` desconhecido, `visible` não booleano e `i` fora de 0 a 2; codificar `suggest` com `rev`, `mode` e `words`, com no máximo três palavras de até 48 caracteres | T005 | `[//]` | `Tests/JoystickCoreTests/RemoteKeyboardMessageTests.swift` | 🟢 | `[X]` |
| T011 | Em `LogEventCatalogTests`, trocar a amostra de `remoteDisconnected` pela fábrica com `suggestions` e conferir o campo, sem chaves proibidas (D-13, RN-08) | T006 | `[//]` | `Tests/JoystickCoreTests/LogEventCatalogTests.swift` | 🟢 | `[X]` |
| T012 | Em `RemoteKeyboardAssetsTests`, exigir que `keyboard.js` conheça `prefs`, `pick` e `suggest` e continue sem `innerHTML`, `outerHTML`, `insertAdjacentHTML`, `eval` e `Function(` | T023 | `[//]` | `Tests/JoystickCoreTests/RemoteKeyboardAssetsTests.swift` | 🟢 | `[X]` |

## Fase 3, Núcleo

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T002 | Criar `SuggestionLanguage`, `SuggestionMode`, `SuggestionInput`, `SuggestionQuery` e `SuggestionContext` com `apply(_:)`: contexto de até 200 caracteres, palavra em composição sem sinais de abertura iniciais, última fronteira, revisão monotônica e descarte, conforme `data-delta.md` §3 (D-03) | T001 | `[//]` | `Sources/JoystickCore/Remote/SuggestionContext.swift` | 🟢 | `[X]` |
| T003 | Em `SuggestionContext`, acrescentar `query(visible:)` com as regras de RN-12, RN-13 e RN-14 | T002 | - | `Sources/JoystickCore/Remote/SuggestionContext.swift` | 🟢 | `[X]` |
| T004 | Em `SuggestionContext`, acrescentar `filter(_:for:)` conforme D-04 e `accept(_:revision:)` com sufixo mais espaço e contagem de aceitas (RN-04) | T003 | - | `Sources/JoystickCore/Remote/SuggestionContext.swift` | 🟢 | `[X]` |
| T005 | Em `RemoteKeyboardMessage`, acrescentar os casos de cliente `prefs` e `pick` e o de servidor `suggest`, com os limites de `interfaces/remote-keyboard-protocol.md` §2 e §3 (D-12) | T002 | `[//]` | `Sources/JoystickCore/Remote/RemoteKeyboardMessage.swift` | 🟢 | `[X]` |
| T006 | Em `LogEventCatalog`, acrescentar o parâmetro `suggestions` a `remoteDisconnected` e ajustar a chamada em `RemoteKeyboardService` com o valor 0 até a T017 (D-13) | T001 | `[//]` | `Sources/JoystickCore/Log/LogEventCatalog.swift` | 🟢 | `[X]` |

## Fase 4, Integração

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T013 | Criar `KeyTextTranslator`: `UCKeyTranslate` sobre a fonte de entrada ativa, com estado de tecla morta próprio, ⇧ e ⌥ recebidos do chamador, Caps Lock pela trava do sistema, `reset()` para descarte e troca de fonte; devolve o texto produzido pela tecla, vazio quando só arma um acento (D-02) | T001 | `[//]` | `Sources/JoystickAIPoC/Remote/KeyTextTranslator.swift` | 🟡 | `[X]` |
| T014 | Criar `WordSuggester` na main thread: `requestCandidates` com a ortografia `pt_BR` ou `en`, etiqueta por sessão, aquecimento, no máximo um pedido em curso com o pendente substituído pelo mais novo, e entrega da resposta com a revisão a um fechamento na fila `input` (D-01, D-08) | T002 | `[//]` | `Sources/JoystickAIPoC/Remote/WordSuggester.swift` | 🟡 | `[X]` |
| T015 | Em `RemoteKeyboardActions`, depois de executar cada `keyDown` e cada repetição, consultar `IsSecureEventInputEnabled()`, traduzir a tecla com o `KeyTextTranslator` e alimentar o `SuggestionContext`; descartar em setas, Esc, tecla comum com ⌘ ou ⌃ mantido ou preso, ⌥⌫ e entrada segura; publicar a consulta por um fechamento `onSuggestionQuery` (D-02, D-06, D-07, RN-09) | T004, T013 | - | `Sources/JoystickAIPoC/Remote/RemoteKeyboardActions.swift` | 🟡 | `[X]` |
| T016 | Em `RemoteKeyboardActions`, tratar `prefs` (idioma e visibilidade da sessão, nova consulta) e `pick` (revisão, injeção ligada, nenhum modificador mantido ou preso, `keyboard.type` do sufixo); expor `discard()` e devolver as aceitas no `end()` (D-05, D-11, RN-10, RN-11) | T005, T015 | - | `Sources/JoystickAIPoC/Remote/RemoteKeyboardActions.swift` | 🟢 | `[X]` |
| T017 | Em `RemoteKeyboardService`, ligar o `WordSuggester` ao início e ao fim da sessão, com aquecimento; enviar `suggest` só da revisão atual e `suggest` vazio em descarte, faixa oculta ou consulta nula; descartar na troca de fonte em `labelsChanged`; registrar `suggestions` em `remote.disconnected` (D-01, D-06, D-08, D-13) | T006, T014, T016 | - | `Sources/JoystickAIPoC/Remote/RemoteKeyboardService.swift` | 🟡 | `[X]` |
| T018 | Em `InputRouter`, acrescentar `onControllerButtonDown`, chamado na fila `input` a cada botão pressionado do controle que não seja sintético, independente da paleta e do modo de identificação (D-06) | T001 | `[//]` | `Sources/JoystickAIPoC/Pointer/InputRouter.swift` | 🟢 | `[X]` |
| T019 | Em `AppDelegate`, montar o `WordSuggester` e o `KeyTextTranslator` no remoto e ligar os descartes externos: `InputRouter.onControllerButtonDown` e `NSWorkspace.didActivateApplicationNotification` chamam `RemoteKeyboardActions.discard()` na fila `input` (D-06) | T017, T018 | - | `Sources/JoystickAIPoC/App/AppDelegate.swift` | 🟡 | `[X]` |
| T020 | Criar `SuggestionProbe`, ativo só com a variável de ambiente `JOYSTICK_SUGGEST_PROBE` apontando um arquivo: grava por tecla o valor da entrada segura e o texto traduzido, fora do log, para as sondas P-01 e P-02; sem a variável, não faz nada (`investigation.md` §5) | T015 | `[//]` | `Sources/JoystickAIPoC/Remote/SuggestionProbe.swift` | 🟡 | `[X]` |
| T021 | Em `index.html` e `keyboard.css`, ampliar a barra para a altura de uma linha de teclas, com indicador de estado curto, três botões de sugestão, seletor PT / EN, botão de ocultar e "Sair"; estados esmaecido e inativo; barra recolhida à altura atual com a faixa oculta (D-09, RF-01, RF-13) | T001 | `[//]` | `Resources/RemoteKeyboard/index.html` | 🟡 | `[X]` |
| T022 | Em `keyboard.js`, ler e gravar `remoteKeyboardPrefs` em `localStorage` dentro de `try`, com padrão `pt` e visível; ligar o seletor e o botão de ocultar; enviar `prefs` após `welcome` e a cada troca (D-11, RN-05, RN-14) | T005, T021 | - | `Resources/RemoteKeyboard/keyboard.js` | 🟢 | `[X]` |
| T023 | Em `keyboard.js`, receber `suggest` e desenhar as palavras por `textContent`; esmaecer a faixa ao enviar `down` de tecla comum até a próxima `suggest`; inativá-la com modificador mantido ou preso; enviar `pick` com `rev` e `i`; mostrar o texto do estado no lugar das sugestões quando não conectado (D-10, D-12, RN-09, RN-11) | T022 | - | `Resources/RemoteKeyboard/keyboard.js` | 🟡 | `[X]` |

## Fase 5, Polimento

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T024 | Rodar `swift build -c release` e os testes; registrar nas notas de execução o total de testes, o número anterior (T001) e os avisos de compilação novos, se houver | T009, T010, T011, T012, T019, T020, T023 | - | `_reversa_forward/009-sugestao-de-palavras/actions.md` | 🟢 | `[X]` |
| T025 | Instalar o app com `JOYSTICK_SIGN_IDENTITY="JoystickAI Local Signing" ./scripts/build-app.sh`, conferir a assinatura com `./scripts/check-signature.sh` e parar no PM-0 | T024 | - | `scripts/build-app.sh` | 🟢 | `[X]` |
| T026 | Registrar no `onboarding.md` §2 o resultado de P-01 a P-04; se P-01 for reprovada, parar e devolver ao usuário a decisão sobre a entrada segura | PM-0 | - | `_reversa_forward/009-sugestao-de-palavras/onboarding.md` | 🟡 | `[X]` |
| T027 | Só se P-04 for reprovada: ajustar em `keyboard.css` a altura da barra à medida registrada e reinstalar o app; aprovada, registrar "não aplicável" nas notas de execução (D-09) | T026 | - | `Resources/RemoteKeyboard/keyboard.css` | 🟡 | `[X]` |
| T028 | Registrar no `onboarding.md` §3 o resultado do PM-1 por passo, com as observações | PM-1 | - | `_reversa_forward/009-sugestao-de-palavras/onboarding.md` | 🟢 | `[X]` |

## Notas de execução

- **T001 (2026-09-19):** `.reversa/reversa-config.json` lido na ativação do `/reversa-coding`: `allowLegacyEdits: true`, `allowedPaths` vazio (liberação irrestrita). Linha de base: 351 testes em 39 suítes, todos verdes, medidos com `SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk`, `-F` para o `Testing.framework` das Command Line Tools e `-plugin-path` para `usr/lib/swift/host/plugins/testing`, como na T001 da 008.
- **T002 a T012 (2026-09-19):** núcleo e testes verdes antes da integração: 378 testes em 40 suítes. Um caso provisório `.prefs?, .pick?` no `switch` de `RemoteKeyboardActions` manteve o app compilando até a T016, que o substituiu.
- **T020 a T023 (2026-09-19):** `keyboard.js` exercitado fora do navegador por um roteiro com DOM e WebSocket simulados (`prefs` após `welcome`, desenho de `suggest` com descarte de itens inválidos, `pick` com `rev` e `i`, esmaecimento por tecla comum e não por modificador, faixa inativa com ⇧ mantido, toque ignorado em faixa vazia ou esmaecida, seletor e botão de ocultar gravando `remoteKeyboardPrefs`, estado no lugar das sugestões sem permissão, leitura das preferências na reabertura e queda no padrão com valor corrompido), todos aprovados; o teste no Safari fica para o PM-0. Fora do previsto: `WordSuggester` dá por encerrado o pedido sem resposta em 1 s, para que um motor mudo não congele a faixa pela sessão; `KeyboardInjector` ganhou `enabled`, lido pelas ações para não alimentar o contexto com teclas barradas pelo portão; `KeyboardLayoutReader.currentLayout()` lê o layout na main thread para o tradutor, que roda na fila `input`. A sonda grava o texto só fora da entrada segura, para que a P-01 não leve senha a disco.
- **T024 (2026-09-19):** `swift build -c release` concluído sem aviso do código, só com os avisos do `ld` sobre caminhos ausentes das Command Line Tools, os mesmos da 008 (um aviso de captura de `self` no `WordSuggester` apareceu na primeira compilação e foi corrigido). Testes: 379 em 40 suítes, todos verdes, contra 351 em 39 da linha de base (+28 testes, +1 suíte, `SuggestionContextTests`). A contagem veio de `swift test` com o SDK 26.5 e o `-plugin-path`, como na T001.
- **PM-0, P-01 e P-02 (2026-09-19):** aprovadas, pelo relato do usuário; a proteção de RN-06 se sustenta, e o PM-1 fica liberado desse lado. T026 segue aberta até P-03 e P-04.
- **PM-0, P-03 e P-04 (2026-09-19):** aprovadas, pelo relato do usuário. PM-0 concluído.
- **T026 (2026-09-19):** P-01 a P-04 registradas no `onboarding.md` §2, todas aprovadas.
- **T027 (2026-09-19):** não aplicável: P-04 aprovada, e a altura da barra segue a de uma linha de teclas; nenhuma mudança em `keyboard.css` nem reinstalação.
- **PM-1, parcial (2026-09-19):** passos 1 a 13 e 15 a 17 aprovados, pelo relato do usuário; o 14 (Acessibilidade revogada) não foi executado, por escolha do usuário; o 18 aguarda o fim da sessão, porque `remote.disconnected` só é gravado quando a página sai. T028 segue aberta até o 18.
- **PM-1, passo 18, e T028 (2026-09-19):** `remote.disconnected` conferido no log com `suggestions: 19` (todas as aceitações da sessão do roteiro) e sem conteúdo; resultado do PM-1 registrado no `onboarding.md` §3. PM-1 aprovado, exceto o passo 14, não executado por escolha do usuário.

## Histórico de alterações

| Data | Alteração | Autor |
|------|-----------|-------|
| 2026-09-19 | Versão inicial gerada por `/reversa-to-do` | reversa |
