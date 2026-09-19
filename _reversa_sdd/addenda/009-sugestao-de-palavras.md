# Adendo: Sugestão de palavras no teclado remoto

> Identificador: `009-sugestao-de-palavras`
> Data: 2026-09-19
> Cenário: legado

## Vigência

Vigente desde 2026-09-19.

## Resumo da entrega

O teclado remoto do iPhone ganha, acima das teclas, uma faixa com até três palavras. Elas completam a palavra que o usuário está escrevendo e, logo depois de um espaço, preveem a palavra seguinte. Tocar numa sugestão escreve no aplicativo em foco só o trecho que falta, seguido de espaço. As sugestões vêm do motor de previsão local do macOS, em português do Brasil ou em inglês, conforme um seletor na faixa, que também pode ser ocultada. Idioma e visibilidade ficam guardados no navegador do iPhone.

Para isso, o Mac passa a conhecer o texto que as teclas do iPhone produzem. Depois de injetar cada tecla, o app a traduz pela fonte de entrada ativa, com as teclas mortas, e guarda em memória até 200 caracteres. Esse contexto é descartado sempre que o ponto de escrita pode ter mudado sem o app saber: setas, Esc, ⌘ ou ⌃, ⌥⌫, qualquer botão do controle, troca de aplicativo, troca de fonte de entrada e fim da sessão. Em entrada segura, o contexto nem chega a ser montado. Nada dele vai a disco nem ao log; o log registra só a quantidade de sugestões aceitas.

A feature estende a 008 (iPhone como teclado remoto), que está em código mas ainda sem adendo. Os componentes remotos citados abaixo, e o canal que eles usam, estão descritos em `_reversa_forward/008-iphone-teclado-remoto/` até que a 008 seja sincronizada.

Sincronização completa: 28 de 28 ações de `actions.md` fechadas. A T027 foi dada como não aplicável, porque a sonda P-04 aprovou a altura da barra. O PM-0 aprovou as sondas P-01 a P-04. O PM-1 aprovou o roteiro, exceto o passo 14 (aceitação com a Acessibilidade revogada), que o usuário escolheu não executar; essa recusa está só no código. `swift build -c release` passa sem avisos do código, com 379 testes em 40 suítes (351 antes da feature), medidos com o SDK 26.5.

## Impacto por artefato da extração

| Artefato | Seção | Tipo de impacto | Delta |
|----------|-------|-----------------|-------|
| `_reversa_sdd/architecture.md` | `#3. Camadas e dependências` | componente-novo | O `JoystickCore` ganha `SuggestionContext`, máquina pura que guarda o contexto recente e decide consulta, filtro e aceitação; continua importando só `Foundation`. |
| `_reversa_sdd/architecture.md` | `#3. Camadas e dependências` | componente-novo | O app ganha `KeyTextTranslator` (tecla em texto, com teclas mortas), `WordSuggester` (motor de previsão, um pedido por vez, prazo de 1 s) e `SuggestionProbe` (arquivo de depuração, só com `JOYSTICK_SUGGEST_PROBE` e sem texto em entrada segura). |
| `_reversa_sdd/architecture.md` | `#3. Camadas e dependências` | regra-alterada | `RemoteKeyboardActions` alimenta ou descarta o contexto depois de cada tecla injetada e trata `prefs` e `pick`; `RemoteKeyboardService` leva as consultas à main thread e só envia sugestões da revisão atual; `InputRouter` avisa cada botão pressionado do controle, sem mudar o roteamento; `AppDelegate` liga os descartes externos. |
| `_reversa_sdd/architecture.md` | `#4. Integrações externas` | delta-de-contrato-externo | Nova integração I-16, motor de previsão de texto do macOS (`NSSpellChecker.requestCandidates`), local e sem permissão TCC nova. I-07 passa a observar a troca de aplicativo em foco e a consultar `IsSecureEventInputEnabled()`. |
| `_reversa_sdd/architecture.md` | `#5. Modelo de dados em arquivo` | delta-de-dados | `config.json` não muda. O log ganha `suggestions` em `remote.disconnected` (`logSchema` segue 1); no iPhone, a página grava `remoteKeyboardPrefs` (`lang`, `visible`) em `localStorage`. |
| `_reversa_sdd/architecture.md` | `#5. Modelo de dados em arquivo` | delta-de-contrato-externo | O canal da 008 ganha `prefs` e `pick`, do iPhone, e `suggest`, do Mac, com até três palavras de 1 a 48 caracteres. Contrato em `_reversa_forward/009-sugestao-de-palavras/interfaces/remote-keyboard-protocol.md`. |
| `_reversa_sdd/domain.md` | `#3.1 Controle e entrada (001)` | regra-alterada | 001 RN-12 deve ser lida com mais uma exceção: o teclado remoto guarda em memória até 200 caracteres do que o iPhone escreve, nunca em disco nem no log, e envia pelo canal da 008 só as palavras sugeridas; em entrada segura, nada é guardado. |
| `_reversa_sdd/domain.md` | `#3.3 Atalhos, configuração e editor (003)` | regra-alterada | 003 RN-14 se mantém e se estende: `remote.disconnected` passa a trazer a contagem `suggestions`, sem palavra digitada, sugerida ou escolhida. |
| `_reversa_sdd/permissions.md` | `#4. Restrições de acesso internas` | regra-alterada | "Textos nunca vão ao log" continua valendo; acrescenta-se que o texto digitado pelo iPhone vive só em memória, limitado a 200 caracteres, e é apagado a cada descarte. |
| `_reversa_sdd/injecao-de-eventos/requirements.md` | `#Regras de Negócio` (RN-IN-02, RN-IN-12, RN-IN-16) | regra-alterada | RN-IN-02: o portão decide também a aceitação de sugestão, nova origem de texto; com ele fechado, nada é escrito e o contexto não muda. RN-IN-12: a sugestão aceita sai pelo mesmo `type`, sem Return. RN-IN-16: o log continua sem textos. `KeyboardInjector` só expõe a leitura do portão (`enabled`). |
| `_reversa_sdd/code-analysis.md` | `#1. app-shell`; `#3. pointer`; `#4. injection` | regra-alterada | Montagem do tradutor e do sugeridor e observação de `NSWorkspace.didActivateApplicationNotification`; `InputRouter.onControllerButtonDown`, chamado a cada botão não sintético, antes da paleta e do modo de identificação; `KeyboardInjector.enabled`. |
| `_reversa_sdd/data-dictionary.md` | `#9. Log de diagnóstico (JSONL)` | delta-de-dados | `remote.disconnected` com `reason`, `keys` e `suggestions`. Os tipos novos do núcleo (`SuggestionLanguage`, `SuggestionMode`, `SuggestionInput`, `SuggestionQuery`, `SuggestionContext`) estão em `_reversa_forward/009-sugestao-de-palavras/data-delta.md` §3. |
| `_reversa_sdd/traceability/code-spec-matrix.md` | `#Testes` | regra-nova | Suíte nova `SuggestionContextTests` (23). `RemoteKeyboardMessageTests` passa de 7 a 11 e `RemoteKeyboardAssetsTests` de 5 a 6; `LogEventCatalogTests` segue com 11. O total do projeto passa a 379 testes em 40 suítes. |

## Regras sob vigilância

W001 a W005 no watch principal e O001 a O011 em "Observações", em [`_reversa_forward/009-sugestao-de-palavras/regression-watch.md`](../../_reversa_forward/009-sugestao-de-palavras/regression-watch.md). A O005 cobre os descartes do contexto, e a W004, a aceitação com o portão fechado, que o PM-1 não verificou no aparelho (passo 14).

## Fontes

- `_reversa_forward/009-sugestao-de-palavras/legacy-impact.md`
- `_reversa_forward/009-sugestao-de-palavras/regression-watch.md`
- `_reversa_forward/009-sugestao-de-palavras/requirements.md`
- `_reversa_forward/009-sugestao-de-palavras/progress.jsonl`
- `_reversa_forward/009-sugestao-de-palavras/actions.md` (notas de execução)
- `_reversa_forward/009-sugestao-de-palavras/onboarding.md` (resultados do PM-0 e do PM-1)
- `_reversa_forward/009-sugestao-de-palavras/data-delta.md`
- `_reversa_forward/009-sugestao-de-palavras/interfaces/remote-keyboard-protocol.md`
- `_reversa_forward/009-sugestao-de-palavras/interfaces/diagnostic-log.md`
