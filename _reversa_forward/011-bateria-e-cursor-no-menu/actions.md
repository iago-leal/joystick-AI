# Actions: carga do controle no editor e na paleta, e cursor preservado após o menu da barra

> Identificador: `011-bateria-e-cursor-no-menu`
> Data: `2026-09-20`
> Roadmap: `_reversa_forward/011-bateria-e-cursor-no-menu/roadmap.md`

## Resumo

| Métrica | Valor |
|---------|-------|
| Total de ações | 34 |
| Paralelizáveis (`[//]`) | 12 |
| Maior cadeia de dependência | 13 (T001 → T005 → T010 → T011 → T022 → T023 → T024 → T025 → T030 → T031 → T032 → T033 → T034) |

## Fase 1, Preparação

<!-- As sondas de D-12 abrem a feature e só travam a metade do defeito: a metade da carga, das fases 2 a 4, corre em paralelo a elas, como manda o `roadmap.md` §8. -->

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T001 | Registrar nas notas de execução o número de testes verdes antes de qualquer mudança (esperado 427 em 43 suítes, conforme `onboarding.md` §1, com o `SDKROOT` e o `-plugin-path` descritos na T001 da 010) e o estado de `.reversa/reversa-config.json` lido na ativação do `/reversa-coding` | - | `[//]` | `_reversa_forward/011-bateria-e-cursor-no-menu/actions.md` | 🟢 | `[X]` |
| T002 | Instalar o aplicativo a partir do código atual, sem nenhuma mudança, com `JOYSTICK_SIGN_IDENTITY="JoystickAI Local Signing" ./scripts/build-app.sh` e `./scripts/check-signature.sh`, para que as sondas corram sobre a base conhecida e com o log em modo de depuração | T001 | - | `scripts/build-app.sh` | 🟢 | `[X]` |
| T003 | Registrar no `onboarding.md` §2 e no `investigation.md` §3 os resultados de P-01, P-02 e P-03 apurados no PM-0, com a observação de o menu permanecer aberto ou não durante o período morto | PM-0 | - | `_reversa_forward/011-bateria-e-cursor-no-menu/onboarding.md` | 🔴 | `[X]` |
| T004 | Fixar, à luz das sondas, quais das três providências de D-11 entram na correção, e registrar emenda no `onboarding.md` §4 se o resultado contrariar D-10 ou D-11; se P-01 mostrar recuperação espontânea, parar e devolver ao usuário a decisão sobre o desenho da correção | T003 | - | `_reversa_forward/011-bateria-e-cursor-no-menu/roadmap.md` | 🔴 | `[X]` |

## Fase 2, Testes

<!-- A decisão de exibição é o único antídoto disponível para TD-01: tudo o que puder ser verificado sem hardware nasce aqui. -->

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T005 | Criar `ControllerChargeTests` com a precedência da decisão de exibição: sem controle ativo devolve `noController`; controle ativo sem carga devolve `unavailable`; nível 0,0 com estado `unknown` devolve `unavailable`, nunca pelo valor do número (D-02, tabela de `data-delta.md` §2) | T001 | `[//]` | `Tests/JoystickCoreTests/ControllerChargeTests.swift` | 🟢 | `[X]` |
| T006 | Em `ControllerChargeTests`, cobrir o caso `known`: `percent` é o nível multiplicado por 100 e arredondado, limitado à faixa de 0 a 100; `charging` é verdadeiro em `charging` e em `full`, e falso em `discharging` | T005 | - | `Tests/JoystickCoreTests/ControllerChargeTests.swift` | 🟢 | `[X]` |
| T007 | Em `ControllerChargeTests`, cobrir a faixa baixa com o arredondamento antes da comparação: 0,15 e 0,151 dão 15 com `low`, 0,16 dá 16 sem `low`, e 0,0 com `discharging` dá 0 com `low` | T006 | - | `Tests/JoystickCoreTests/ControllerChargeTests.swift` | 🟢 | `[X]` |
| T008 | Criar `ChargeLogPolicyTests`: a primeira leitura de uma conexão registra; leitura na mesma faixa de dez não registra; mudança de dezena registra; troca entre descarregando e carregando registra; identificador de conexão novo reinicia o estado (D-09) | T001 | `[//]` | `Tests/JoystickCoreTests/ChargeLogPolicyTests.swift` | 🟡 | `[X]` |
| T009 | Em `LogEventCatalogTests`, acrescentar as amostras de `controller.charge` e de `menu.cycle` e trocar a de `controller.connected` pela fábrica com `charge` e `chargeState`, conferindo os campos, a omissão dos dois campos quando a carga é indisponível e a ausência de chaves proibidas | T001 | `[//]` | `Tests/JoystickCoreTests/LogEventCatalogTests.swift` | 🟢 | `[X]` |

## Fase 3, Núcleo

<!-- Nada aqui importa além de `Foundation`, conforme ADR-001 e D-03. -->

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T010 | Criar `ControllerChargeState`, com os casos `unknown`, `discharging`, `charging` e `full`, e `ControllerCharge`, com `level` de 0,0 a 1,0 e `state`, espelhando sem importar a interface de controles do sistema (D-03, `data-delta.md` §2) | T005 | - | `Sources/JoystickCore/Input/ControllerCharge.swift` | 🟢 | `[X]` |
| T011 | No mesmo arquivo, criar `ChargeDisplay` com `noController`, `unavailable` e `known(percent:charging:low:)` e a função de decisão que recebe `ControllerCharge?` e aplica a ordem de precedência de D-02 | T010 | - | `Sources/JoystickCore/Input/ControllerCharge.swift` | 🟢 | `[X]` |
| T012 | Completar o caso `known` da decisão: `percent` arredondado e limitado a 0 e 100, `charging` nos estados `charging` e `full`, e `low` em 15% ou menos, com o arredondamento acontecendo antes da comparação com o limite | T007, T011 | - | `Sources/JoystickCore/Input/ControllerCharge.swift` | 🟢 | `[X]` |
| T013 | Criar `ChargeLogPolicy`, valor puro que guarda, por identificador de conexão, a última dezena registrada e o último estado, e responde se a leitura corrente deve virar evento de log (D-09, RN-12) | T008 | `[//]` | `Sources/JoystickCore/Log/ChargeLogPolicy.swift` | 🟡 | `[X]` |

## Fase 4, Integração

<!-- A metade da carga, de T014 a T025, não depende das sondas. A correção do ciclo do menu, de T026 a T030, depende. -->

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T014 | Em `LogEventCatalog`, acrescentar `charge` e `chargeState` a `controllerConnected`, omitidos e não zerados quando a carga é indisponível, e criar as fábricas de `controller.charge` e de `menu.cycle` conforme `interfaces/diagnostic-log.md` §2 e §3 | T009 | `[//]` | `Sources/JoystickCore/Log/LogEventCatalog.swift` | 🟢 | `[X]` |
| T015 | Em `ControllerReader`, ler a carga do controle aceito e levá-la ao evento de conexão; trocar `onActiveModelChange` por um canal único que publica modelo e `ControllerCharge?` juntos, disparado na conexão, na desconexão e na promoção do controle ativo (D-05, RN-02, RN-10) | T010, T014 | - | `Sources/JoystickAIPoC/Controller/ControllerReader.swift` | 🟢 | `[X]` |
| T016 | Em `ControllerReader`, expor a leitura da carga do controle ativo sob demanda, chamável da main thread, sem entrar na fila de entrada nem acrescentar trabalho ao temporizador de 120 Hz (RN-11) | T015 | - | `Sources/JoystickAIPoC/Controller/ControllerReader.swift` | 🟢 | `[X]` |
| T017 | Criar `ChargePoller`: temporizador de 60 s na main thread, ligado e desligado por contagem de interfaces abertas, que lê a carga pela T016, decide o `ChargeDisplay` pelo núcleo e publica o resultado (D-04, RN-10) | T011, T016 | - | `Sources/JoystickAIPoC/Controller/ChargePoller.swift` | 🟢 | `[X]` |
| T018 | No `ChargePoller`, aplicar a `ChargeLogPolicy` sobre cada leitura e emitir `controller.charge` apenas na mudança de faixa de dez ou de estado, nunca a cada leitura (D-09, RN-12) | T013, T017 | - | `Sources/JoystickAIPoC/Controller/ChargePoller.swift` | 🟡 | `[X]` |
| T019 | Em `EditorViewModel`, guardar o último `ChargeDisplay` publicado, ao lado de `activeModel`, sem alterar o rascunho nem a validação | T011 | `[//]` | `Sources/JoystickAIPoC/Editor/EditorViewModel.swift` | 🟢 | `[X]` |
| T020 | Em `EditorLabels`, acrescentar as frases de ausência de controle e de carga indisponível e a forma do texto com porcentagem e marca de carregamento, cobrindo os casos de RN-03, RN-04 e RN-06 | T011 | `[//]` | `Sources/JoystickAIPoC/Editor/EditorLabels.swift` | 🟡 | `[X]` |
| T021 | Em `EditorRootView`, desenhar a carga no cabeçalho, ao lado do alternador "Identificar pelo controle", no corpo de 32 pt da escala de TV, com o destaque de carga baixa por cor **e** por símbolo (D-06, D-08, RF-01, RF-03, RF-05) | T019, T020 | - | `Sources/JoystickAIPoC/Editor/EditorRootView.swift` | 🟡 | `[X]` |
| T022 | Em `PaletteView`, acrescentar o rodapé fixo com a carga, desenhado fora do arranjo de linhas, sem entrar em `rowCount`, na seleção, na contagem de itens nem no índice do último confirmado (D-07, RN-08) | T011 | `[//]` | `Sources/JoystickAIPoC/Palette/PalettePanel.swift` | 🟡 | `[X]` |
| T023 | Em `PaletteView`, incluir a altura do rodapé no cálculo de `fit(maxHeight:maxWidth:)`, de modo que o painel continue cabendo na área visível, e aplicar o destaque de carga baixa por cor e por símbolo sobre o fundo escuro do painel | T022 | - | `Sources/JoystickAIPoC/Palette/PalettePanel.swift` | 🟡 | `[X]` |
| T024 | Em `PalettePanel`, receber o `ChargeDisplay` por método próprio, que redesenha apenas o rodapé, sem alterar itens nem seleção, sem tomar o foco e sem reiniciar a contagem dos 60 s de inatividade (RN-09, RF-10) | T023 | - | `Sources/JoystickAIPoC/Palette/PalettePanel.swift` | 🟢 | `[X]` |
| T025 | Em `AppDelegate`, montar o `ChargePoller`, ligá-lo à abertura e ao fechamento do editor e da paleta, e encaminhar o `ChargeDisplay`, venha do canal da T015 ou do consultor, ao modelo do editor e ao painel da paleta | T017, T019, T024 | - | `Sources/JoystickAIPoC/App/AppDelegate.swift` | 🟢 | `[X]` |
| T026 | Em `EventInjector`, acrescentar a ressincronização explícita da posição acompanhada, que descarta `trackedPosition` e as posições recentes em favor da leitura do sistema, e é neutra quando a posição já está correta (D-11) | T004 | `[//]` | `Sources/JoystickAIPoC/Injection/EventInjector.swift` | 🟡 | `[—]` |
| T027 | Em `MotionLoop`, expor o religamento do temporizador de movimento a partir da main thread, que só liga se algum analógico estiver fora do repouso e não produz efeito se o temporizador já estiver ligado (D-11, ADR-006) | T004 | `[//]` | `Sources/JoystickAIPoC/Pointer/MotionLoop.swift` | 🟡 | `[—]` |
| T028 | Em `ButtonActions`, expor a reposta das solturas dos botões de mouse mantidos, reaproveitando `releaseAll()`, devolvendo quantos foram soltos e sem produzir clique quando não havia pressionamento correspondente (D-11, RI-04, RN-15) | T004 | `[//]` | `Sources/JoystickAIPoC/Pointer/ButtonActions.swift` | 🟡 | `[—]` |
| T029 | Em `StatusMenu`, implementar `menuDidClose` do mesmo protocolo de delegação que já traz `menuWillOpen`, disparando a reconciliação e registrando `menu.cycle` com `released`, `resynced` e `timerRestarted` (D-10, RF-11, RF-12, RF-13) | T014, T026, T027, T028 | - | `Sources/JoystickAIPoC/App/StatusMenu.swift` | 🟡 | `[X]` |
| T030 | Em `AppDelegate`, ligar o `StatusMenu` à reconciliação, atravessando a fila de entrada de forma assíncrona, sem nenhuma chamada síncrona da fila para a main thread e sem tocar o caminho de ativação do editor resolvido pela emenda E003 da 003 (RN-17, RF-14) | T025, T029 | - | `Sources/JoystickAIPoC/App/AppDelegate.swift` | 🟡 | `[X]` |

## Fase 5, Polimento

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T031 | Rodar `swift build -c release` e `./scripts/test.sh`; registrar nas notas de execução o total de testes, o número anterior da T001 e os avisos de compilação novos, se houver | T012, T018, T021, T030 | - | `_reversa_forward/011-bateria-e-cursor-no-menu/actions.md` | 🟢 | `[X]` |
| T032 | Instalar o aplicativo com `JOYSTICK_SIGN_IDENTITY="JoystickAI Local Signing" ./scripts/build-app.sh`, conferir a assinatura com `./scripts/check-signature.sh` e parar no PM-1 | T031 | - | `scripts/build-app.sh` | 🟢 | `[X]` |
| T033 | Registrar no `onboarding.md` §3 o resultado do PM-1 por passo, com as observações, e no §4 as emendas aprovadas durante a execução | PM-1 | - | `_reversa_forward/011-bateria-e-cursor-no-menu/onboarding.md` | 🟢 | `[ ]` |
| T034 | Registrar no `investigation.md` §3 o veredito final sobre o mecanismo do defeito à luz do `menu.cycle` lido no PM-1; com os três campos em zero e falso e o defeito ainda reproduzindo, anotar que a saída de §2.3, a de substituir o menu por painel próprio, volta à mesa | T033 | - | `_reversa_forward/011-bateria-e-cursor-no-menu/investigation.md` | 🟡 | `[ ]` |

## Emendas

<!-- Nascidas do PM-0. As sondas falsificaram D-11 por inteiro e redirecionaram D-10; o detalhe está nas notas. -->

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| E-01 | Revisar D-10 e D-11 à luz das sondas: não há estado retido a reconciliar; o sistema toma os analógicos enquanto o menu rastreia e deixa os botões passarem, que por sua vez vazam acordes para o aplicativo atrás do menu | T003 | - | `_reversa_forward/011-bateria-e-cursor-no-menu/investigation.md` | 🟢 | `[X]` |
| E-02 | Guardar no contexto de entrada o estado de rastreamento do menu, ligado pela abertura e desligado pelo fechamento, atravessando para a fila `input` de forma assíncrona | E-01 | - | `Sources/JoystickAIPoC/Controller/InputSink.swift` | 🟢 | `[X]` |
| E-03 | No roteador, traduzir os botões em navegação do menu enquanto o rastreamento durar: direcional vira seta, ✕ vira Return, ○ e PS viram Esc, e os demais são engolidos para parar o vazamento de acordes | E-02 | - | `Sources/JoystickAIPoC/Pointer/InputRouter.swift` | 🟡 | `[X]` |
| E-04 | Redefinir `menu.cycle`: em lugar de `released`, `resynced` e `timerRestarted`, que supunham estado retido, registrar `keys` e `durationMs`, que dizem se o controle conseguiu navegar o menu | E-01 | - | `Sources/JoystickCore/Log/LogEventCatalog.swift` | 🟢 | `[X]` |
| E-05 | Retirar do catálogo o evento `menu.probe` da sonda P-04, respondida | E-01 | `[//]` | `Sources/JoystickCore/Log/LogEventCatalog.swift` | 🟢 | `[X]` |

## Notas de execução

- **T001 (2026-09-20):** `.reversa/reversa-config.json` lido na ativação: `allowLegacyEdits: true`, `allowedPaths` vazio, isto é, liberação irrestrita do projeto. Linha de base: **427 testes em 43 suítes**, todos verdes, exatamente o número que o `onboarding.md` §1 previa. Medidos com `SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk` e `-Xswiftc -plugin-path -Xswiftc /Library/Developer/CommandLineTools/usr/lib/swift/host/plugins/testing`, o mesmo arranjo da T001 das features 008, 009 e 010; sem ele, o SDK 27.0 ainda falha por ausência do plugin `SwiftUIMacros`.

- **T002 (2026-09-20):** aplicativo compilado em release e instalado em `~/Applications/JoystickAIPoC.app` **sem nenhuma mudança de código**, para que as sondas de D-12 corram sobre a base conhecida, a mesma que produziu o defeito relatado. Assinatura conferida: identificador `dev.iagoleal.joystick-ai.poc`, autoridade `JoystickAI Local Signing`, folha `bd5fe569…`, a mesma de sempre, de modo que as permissões de Acessibilidade e de Entrada não precisam ser concedidas de novo. O `build-app.sh` precisou do `SDKROOT` do SDK 26.5 na linha de comando, pelo mesmo defeito de ambiente da T001; o script não foi alterado. Aberto em seguida com `--debug`, como as sondas P-01 e P-02 exigem.

- **T005 a T025 (2026-09-20):** metade da carga inteira, das duas suítes novas ao arranque, verde antes de as sondas correrem, como o `roadmap.md` §8 autoriza. **449 testes em 45 suítes**, contra 427 em 43 da linha de base: +22 testes, com `ControllerChargeTests` (14) e `ChargeLogPolicyTests` (6), mais dois casos acrescentados a `LogEventCatalogTests`. Cinco desvios do plano, todos por fidelidade ao legado ou por contradição entre documentos, e registrados aqui:
  - **Assinatura da decisão (T011, D-03 contra `data-delta.md` §2).** O `data-delta.md` diz que a função "recebe `ControllerCharge?`", mas a tabela de verdade logo abaixo distingue três entradas, das quais duas seriam o mesmo `nil`: sem controle ativo e controle sem carga. O roadmap é o documento explícito, e D-03 fala em "nível, estado **e presença de controle ativo**"; a função ficou `decide(hasActiveController:charge:)`. Sem isso, RN-03 e RN-04 seriam indistinguíveis no núcleo, e a escolha entre as duas frases voltaria para a camada de interface, exatamente o que D-03 existe para impedir.
  - **T012 absorvida pela T011.** A decisão de precedência e o caso `known` saíram na mesma função e no mesmo turno: separá-los produziria um estado intermediário que não compila, sem ganho de revisão. Os testes das duas, porém, continuaram separados, que é onde a separação valia.
  - **Leitura da carga pela main thread (T016, RN-11).** O `GCController` do ativo viaja no canal de D-05, e o consultor relê `battery` dele na main thread. A alternativa seria despachar a leitura para a fila `input`, onde moram o registro e os controles: seria exatamente o trabalho na fila de entrada que RN-11 proíbe. A referência serve **só** à leitura da propriedade de bateria; tudo o mais que se faz com o controle segue no `handlerQueue`.
  - **Redação única do texto da carga (T020, T022).** O rodapé da paleta chama `EditorLabels.charge(_:)`, apesar do nome ligado ao editor. Duas redações da mesma informação divergiriam com o tempo, e é a divergência entre as duas interfaces que D-03 existe para evitar; o preço é o nome do tipo, que ficou mais estreito que o seu uso.
  - **Símbolo do destaque por glifo na paleta (T023, D-08).** No editor o símbolo é um `Image(systemName:)`; no painel, que é `NSView` desenhado à mão em fonte monoespaçada, o segundo canal do destaque virou o glifo `⚠` (ou `⚡` no cabo) à frente do texto. É símbolo de verdade, como D-08 pede, e sobrevive ao fundo escuro sem depender de matiz.
  Fora do previsto: `EditorWindowController` ganhou `onDidClose`, porque o consultor precisa saber do fechamento e a janela só anunciava a abertura; e a contagem de interfaces abertas virou número, e não booleano, porque editor e paleta abrem e fecham sem ordem entre si.

- **PM-0 e T003, T004, emendas E-01 a E-05 (2026-09-20):** as sondas viraram o plano do avesso, e o detalhe está no `investigation.md` §3 e no `onboarding.md` §2 e §4. Em resumo: **D-11 falsificada**, porque não há estado retido — enquanto o menu rastreia, o sistema toma os analógicos, que chegam zerados, e deixa os botões passarem; e **D-10 redirecionada**, porque o protocolo de delegação continua sendo o ponto certo, só que pela abertura, e não pelo fechamento. Foi preciso acrescentar três sondas não previstas, P-04, P-05 e P-06, depois que a P-01 contrariou D-10 e a decisão voltou ao usuário, que optou por medir antes de escolher entre manter o menu e trocá-lo por painel próprio. A P-05 achou de raspão um defeito que não estava no relato de campo: com o menu aberto, cada aperto do direcional disparava o acorde da camada base no aplicativo **atrás** do menu. A correção de E-03 o elimina junto, porque engolir o que não tem tradução é parte dela. A saída do `investigation.md` §2.3, o painel próprio, não foi necessária e fica registrada para o caso de o comportamento do sistema mudar. T026, T027 e T028 ficaram `[—]`, não aplicáveis, com o motivo no `progress.jsonl`; os IDs não foram reciclados.

- **T031 (2026-09-20):** `swift build -c release` concluído sem nenhum aviso do código, só com os avisos do `ld` sobre caminhos ausentes das Command Line Tools, os mesmos das features 008, 009 e 010. Testes: **449 em 45 suítes**, todos verdes, contra 427 em 43 da linha de base da T001: +22 testes e +2 suítes, `ControllerChargeTests` com 14 casos e `ChargeLogPolicyTests` com 6.

- **T032 (2026-09-20):** aplicativo instalado em `~/Applications/JoystickAIPoC.app` e assinatura conferida: identificador `dev.iagoleal.joystick-ai.poc`, autoridade `JoystickAI Local Signing`, a mesma folha de sempre, de modo que as permissões de Acessibilidade e de Entrada não precisam ser concedidas de novo.

- **Sequência do PM-0, desvio deliberado (2026-09-20):** a T002 instalou o aplicativo sem mudança, para as sondas correrem sobre a base conhecida, mas a **P-03 pergunta o que o editor mostra na área da carga**, que não existe nessa base. Como a metade da carga não toca o menu, a injeção nem o temporizador de movimento, o aplicativo foi reinstalado com ela antes do PM-0: P-01 e P-02 continuam medindo o mesmo defeito, sobre o mesmo caminho de entrada, e P-03 passou a ser executável na mesma sessão. O desvio fica registrado porque muda o binário sob o qual as três sondas correm, e quem ler o log da sessão precisa saber disso.

## Histórico de alterações

| Data | Alteração | Autor |
|------|-----------|-------|
| 2026-09-20 | Versão inicial gerada por `/reversa-to-do` | reversa |
