# Actions: iPhone como teclado touch do Mac

> Identificador: `008-iphone-teclado-remoto`
> Data: `2026-09-19`
> Roadmap: `_reversa_forward/008-iphone-teclado-remoto/roadmap.md`

## Resumo

| Métrica | Valor |
|---------|-------|
| Total de ações | 37 |
| Paralelizáveis (`[//]`) | 24 |
| Maior cadeia de dependência | 9 (T001 → T011 → T015 → T016 → T021 → T023 → T028 → T032 → T033), seguida do PM-0, de T034, T035, do PM-1 e de T036 |

## Convenções desta decomposição

### Portões manuais

Passagens que dependem de ato humano não recebem ID `T`; aparecem como `PM-n` na coluna de dependências. O `/reversa-coding` para ao alcançar um portão e só segue quando o usuário relatar o resultado.

| Portão | Ato do usuário | Requer | Referência | Libera |
|--------|----------------|--------|------------|--------|
| PM-0 | Com o app instalado, executar o `onboarding.md` §1 e §2 e responder às sondas P-01 a P-07 do `investigation.md` §5 | T033 | Roadmap §4 (premissas), D-03, D-10, D-11, D-12, D-17 | T034 |
| PM-1 | Executar o roteiro do `onboarding.md` §4 (17 passos) com o iPhone preso ao controle | T034, T035 | Critério de pronto do roadmap §10 | T036 |

Se P-01 for reprovada no PM-0, a cifragem de RN-03 não se sustenta: o `/reversa-coding` para e devolve a decisão ao usuário, sem seguir para o PM-1. A maior cadeia conta apenas ações `T`.

### Ordem das fases

Os testes da Fase 2 dependem dos tipos criados na Fase 3; o `/reversa-coding` executa pela coluna de dependências, e não pela ordem das tabelas. Os tipos do núcleo ficam em `Sources/JoystickCore/Remote/`, e os do app em `Sources/JoystickAIPoC/Remote/`.

### Correspondência com o roadmap

| Decisões do roadmap | Ações |
|---------------------|-------|
| D-01 (página no Safari, Tela de Início) | T029, T030 |
| D-02 (dois listeners TLS, portas fixas) | T019, T020, T023 |
| D-03 (autoridade local, chave descartada) | T002, T018 |
| D-04 (AirDrop do certificado) | T025 |
| D-05 (pareamento, token) | T005, T013, T020 |
| D-06 (um aparelho por vez, retomada pelo token) | T005, T013, T020, T030 |
| D-07 (rede local, `Origin`) | T004, T012, T020 |
| D-08 (máquina no núcleo) | T007, T015, T016 |
| D-09 (execução pelo `KeyboardInjector`) | T021, T037 |
| D-10 (repetição pela cadência do macOS) | T007, T015, T021 |
| D-11 (vigia de 1 s) | T007, T016, T021, T030 |
| D-12 (rótulos pela fonte de entrada) | T010, T022 |
| D-13 (portão e ciclo de vida) | T026, T027 |
| D-14 (menu e janela de pareamento) | T024, T025, T028 |
| D-15 (arquivos da página) | T009, T029, T030, T031 |
| D-16 (mensagens validadas) | T006, T014, T020 |
| D-17 (Caps Lock por caminho próprio, condicional) | T007, T011, T015, T037, PM-0, T035 |
| D-18 (log) | T008, T017, T021, T023 |

## Fase 1, Preparação

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T001 | Registrar nas notas de execução o número de testes verdes de `./scripts/test.sh` antes de qualquer mudança (esperado 306) e o estado de `.reversa/reversa-config.json` lido na ativação do `/reversa-coding` | - | - | `_reversa_forward/008-iphone-teclado-remoto/actions.md` | 🟢 | `[X]` |
| T002 | Criar `create-remote-keyboard-identity.sh` conforme `interfaces/identidade-tls.md` §1: autoridade com restrição de nome `.local`, certificado de servidor para `<LocalHostName>.local`, importação no chaveiro com o rótulo "JoystickAI Remote Keyboard", certificado da autoridade em Application Support e remoção das chaves temporárias (D-03) | T001 | `[//]` | `scripts/create-remote-keyboard-identity.sh` | 🟡 | `[X]` |

## Fase 2, Testes

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T003 | Criar `RemoteKeyGeometryTests`: ANSI e ISO têm as teclas de RF-04; modificadores direitos 54, 60, 61, 62 resolvem para ⌘, ⇧, ⌥, ⌃; `contains(code:)` recusa códigos fora da geometria; Caps Lock presente enquanto a D-17 não o retirar | T011 | `[//]` | `Tests/JoystickCoreTests/RemoteKeyGeometryTests.swift` | 🟢 | `[X]` |
| T004 | Criar `LocalAddressPolicyTests`: aceita 10/8, 172.16/12, 192.168/16, 169.254/16, `fe80::/10`, `fc00::/7` e laço local só com a opção de teste; recusa 172.32.0.1, 8.8.8.8, `2001:db8::1` e endereço malformado (D-07) | T012 | `[//]` | `Tests/JoystickCoreTests/LocalAddressPolicyTests.swift` | 🟢 | `[X]` |
| T005 | Criar `RemotePairingTests` com gerador determinístico: código de 6 dígitos; código certo gera token de 16 bytes e zera falhas; quinta falha gira o código; token vale para reconectar sem sessão ativa; token da sessão com sessão ativa dá `.resumed` com `replacesActive`; código ou token desconhecido com sessão ativa dá `busy` sem somar falha; desligar invalida código e token (D-05, D-06) | T013 | `[//]` | `Tests/JoystickCoreTests/RemotePairingTests.swift` | 🟢 | `[X]` |
| T006 | Criar `RemoteKeyboardMessageTests`: decodifica `hello`, `down`, `up`, `ping`, `release`, `bye`; recusa `t` desconhecido, JSON inválido e quadro acima de 1 KiB; codifica `welcome`, `reject`, `layout`, `modifiers` e `status` com os campos de `interfaces/remote-keyboard-protocol.md` §3 (D-16) | T014 | `[//]` | `Tests/JoystickCoreTests/RemoteKeyboardMessageTests.swift` | 🟢 | `[X]` |
| T007 | Criar `RemoteKeyboardMachineTests`: modificador segurado; tocado e solto fica preso e solta depois da próxima tecla comum; tocar preso solta; ⌘ direito e esquerdo somam; só a última tecla comum repete; `down` e `up` repetidos são ignorados; Caps Lock emite `.capsLock(down:)`, não repete, não fica preso nem solta os presos e entra na soltura geral; vigia de 1 s solta tudo só com algo mantido; queda solta tudo; contagem de teclas; cinco mensagens inválidas seguidas encerram (RN-07, RN-09, RN-10, D-17) | T016 | `[//]` | `Tests/JoystickCoreTests/RemoteKeyboardMachineTests.swift` | 🟢 | `[X]` |
| T008 | Em `LogEventCatalogTests`, incluir as seis fábricas `remote.*` em `sampleEvents` e conferir os campos de `interfaces/diagnostic-log.md` §2, sem chaves proibidas (D-18, RN-13) | T017 | `[//]` | `Tests/JoystickCoreTests/LogEventCatalogTests.swift` | 🟢 | `[X]` |
| T009 | Criar `RemoteKeyboardAssetsTests`, lendo `Resources/RemoteKeyboard/` por `#filePath` como `FigureAssetsTests`: os três arquivos existem; nenhum usa `innerHTML`, `outerHTML`, `insertAdjacentHTML`, `eval` nem `Function(`; `index.html` não tem script nem estilo embutidos; `keyboard.js` conhece os tipos de mensagem do protocolo (D-15) | T030 | `[//]` | `Tests/JoystickCoreTests/RemoteKeyboardAssetsTests.swift` | 🟢 | `[X]` |

## Fase 3, Núcleo

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T010 | Criar `KeyLabelTable`: por código, rótulos `plain`, `shift`, `option`, `shiftOption` e o conjunto de estados com tecla morta, `Codable` e `Sendable` (D-12) | T001 | `[//]` | `Sources/JoystickCore/Remote/KeyLabelTable.swift` | 🟢 | `[X]` |
| T011 | Criar `RemoteKey` e `RemoteKeyGeometry` (ANSI e ISO, linhas de RF-04, modificadores direitos mapeados, Caps Lock, `contains(code:)`), conforme `data-delta.md` §3 (D-16, D-17) | T001 | `[//]` | `Sources/JoystickCore/Remote/RemoteKeyGeometry.swift` | 🟡 | `[X]` |
| T012 | Criar `LocalAddressPolicy.isAllowed(_:allowLoopback:)` para IPv4 e IPv6 em texto, sem depender de rede (D-07) | T001 | `[//]` | `Sources/JoystickCore/Remote/LocalAddressPolicy.swift` | 🟢 | `[X]` |
| T013 | Criar `RemotePairing` e `PairingOutcome` com gerador injetável, limite de cinco falhas, token de 16 bytes, comparação em tempo constante e estado de sessão ativa (D-05, D-06) | T001 | `[//]` | `Sources/JoystickCore/Remote/RemotePairing.swift` | 🟢 | `[X]` |
| T014 | Criar `RemoteKeyboardMessage` (cliente e servidor) com codificação e decodificação JSON pelo campo `t`, limite de 1 KiB e o `layout` com `physical` e `KeyLabelTable` (D-16) | T010, T011 | `[//]` | `Sources/JoystickCore/Remote/RemoteKeyboardMessage.swift` | 🟢 | `[X]` |
| T015 | Criar `RemoteKeyboardMachine`, `ModifierState` e `RemoteKeyboardEffect`: `down` e `up` por código, modificadores segurados e presos conforme RN-07, soltura dos presos após a próxima tecla comum, repetição só da última tecla comum, Caps Lock como `.capsLock(down:)` fora dos modificadores presos, idempotência por tecla (D-08, D-10, D-17) | T011 | `[//]` | `Sources/JoystickCore/Remote/RemoteKeyboardMachine.swift` | 🟢 | `[X]` |
| T016 | Em `RemoteKeyboardMachine`, acrescentar o vigia (`tick(nowNs:)` com 1 s sem mensagem e algo mantido), a soltura geral por motivo, a contagem de teclas da sessão e o contador de mensagens inválidas seguidas (D-11, D-16, RN-10) | T015 | - | `Sources/JoystickCore/Remote/RemoteKeyboardMachine.swift` | 🟡 | `[X]` |
| T017 | Em `LogEventCatalog`, acrescentar os enums `RemoteRejectReason` e `RemoteDisconnectReason` e as fábricas `remoteEnabled`, `remoteDisabled`, `remoteConnected`, `remoteRejected`, `remoteWatchdog` e `remoteDisconnected` (D-18) | T001 | `[//]` | `Sources/JoystickCore/Log/LogEventCatalog.swift` | 🟢 | `[X]` |

## Fase 4, Integração

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T037 | Em `KeyboardInjector`, acrescentar `capsLock(down:)`: `flagsChanged` do código 57 com `maskAlphaShift` no pressionar, sem passar por `modifierCounts` e descartado com a injeção desligada; em `postKey`, acrescentar `maskAlphaShift` quando `CGEventSource.flagsState(.hidSystemState)` o indicar (D-17) | T001 | `[//]` | `Sources/JoystickAIPoC/Injection/KeyboardInjector.swift` | 🟡 | `[X]` |
| T018 | Criar `RemoteKeyboardIdentity`: busca a `SecIdentity` pelo rótulo no chaveiro, confere o SAN contra `LocalHostName` e a validade, e devolve `no_identity`, `host_mismatch` ou `expired` (D-03) | T002 | `[//]` | `Sources/JoystickAIPoC/Remote/RemoteKeyboardIdentity.swift` | 🟡 | `[X]` |
| T019 | Criar `RemotePageListener`: `NWListener` TLS na porta 47810, `GET` dos três arquivos do bundle com os cabeçalhos de `interfaces/remote-keyboard-protocol.md` §2, 404, 405, limite de 8 KiB e 5 s, `Connection: close` (D-02) | T018 | - | `Sources/JoystickAIPoC/Remote/RemotePageListener.swift` | 🟡 | `[X]` |
| T020 | Criar `RemoteChannelListener`: `NWListener` TLS com `NWProtocolWebSocket` na porta 47811, filtro por `LocalAddressPolicy`, checagem de `Origin`, `hello` em até 5 s com `RemotePairing`, substituição da conexão ativa pelo token da sessão (soltura e código 4004) e `busy` para qualquer outro `hello` com conexão ativa, decodificação e validação contra a geometria, fechamento após 10 s sem mensagem; entrega na fila `input` (D-02, D-05 a D-07, D-16) | T012, T013, T014, T018 | - | `Sources/JoystickAIPoC/Remote/RemoteChannelListener.swift` | 🟡 | `[X]` |
| T021 | Criar `RemoteKeyboardActions` na fila `input`: executa os efeitos da máquina pelo `KeyboardInjector`, inclusive `.capsLock(down:)` (D-09, D-17), repete com `NSEvent.keyRepeatDelay` e `keyRepeatInterval` (D-10), roda o vigia a cada 250 ms (D-11), expõe `releaseAll()` e registra `remote.watchdog` | T016, T017, T037 | - | `Sources/JoystickAIPoC/Remote/RemoteKeyboardActions.swift` | 🟡 | `[X]` |
| T022 | Criar `KeyboardLayoutReader`: `KeyLabelTable` da fonte ativa por `UCKeyTranslate` nos quatro estados com teclas mortas, geometria por `KBGetLayoutType(LMGetKbdType())` e aviso de troca por `kTISNotifySelectedKeyboardInputSourceChanged` (D-12) | T010, T011 | `[//]` | `Sources/JoystickAIPoC/Remote/KeyboardLayoutReader.swift` | 🟡 | `[X]` |
| T023 | Criar `RemoteKeyboardService`: liga e desliga identidade, listeners e pareamento; envia `layout`, `modifiers` e `status`; publica código, URL e estado para a janela e o menu; registra `remote.enabled`, `remote.disabled`, `remote.connected`, `remote.rejected` e `remote.disconnected` (D-02, D-14, D-18) | T017, T019, T020, T021, T022 | - | `Sources/JoystickAIPoC/Remote/RemoteKeyboardService.swift` | 🟡 | `[X]` |
| T024 | Criar `PairingWindow` em SwiftUI com `EditorMetrics`: QR de `CIQRCodeGenerator` para a URL com `#c=`, endereço, código em dígitos grandes e estado; fecha ao parear (D-14, RF-02) | T001 | `[//]` | `Sources/JoystickAIPoC/Remote/PairingWindow.swift` | 🟢 | `[X]` |
| T025 | Em `StatusMenu`, acrescentar "Teclado remoto" com marca de ligado, "Mostrar pareamento", "Enviar certificado ao iPhone…" por `NSSharingService` `.sendViaAirDrop` (desabilitado sem o arquivo) e a linha de erro de identidade ou porta ocupada (D-04, D-14) | T001 | `[//]` | `Sources/JoystickAIPoC/App/StatusMenu.swift` | 🟢 | `[X]` |
| T026 | Em `InjectionGate`, receber `RemoteKeyboardActions`, soltar o remoto na suspensão, repetir as solturas na retomada e avisar o serviço da mudança de permissão (D-13, RN-11) | T021 | `[//]` | `Sources/JoystickAIPoC/App/InjectionGate.swift` | 🟢 | `[X]` |
| T027 | Em `Lifecycle.cleanUp`, soltar o remoto dentro do mesmo `queue.sync` e pedir ao serviço que feche os listeners (D-13, 001 RN-04) | T021 | `[//]` | `Sources/JoystickAIPoC/App/Lifecycle.swift` | 🟢 | `[X]` |
| T028 | Em `AppDelegate`, montar `KeyboardLayoutReader`, `RemoteKeyboardActions` com o `keyboard` único, `RemoteKeyboardService`, `PairingWindow`, os itens do menu, o portão e o ciclo de vida, com o recurso desligado na abertura (RN-02) | T023, T024, T025, T026, T027 | - | `Sources/JoystickAIPoC/App/AppDelegate.swift` | 🟢 | `[X]` |
| T029 | Criar `index.html` e `keyboard.css`: teclado na horizontal numa só tela, estados de modificador (solto, mantido, preso), marca de toque, faixa de estado, aviso "gire o iPhone" na vertical, zoom e rolagem desligados, metadados de aplicativo da Tela de Início (D-01, D-15, RF-04, RF-06, RF-10) | T001 | `[//]` | `Resources/RemoteKeyboard/index.html` | 🟡 | `[X]` |
| T030 | Criar `keyboard.js`: lê e apaga o `#c=`, abre o canal, envia `hello` com código ou token, desenha as teclas do `layout` por APIs do DOM, envia `down` e `up` por toque com vários dedos, `ping` a cada 250 ms, `release` em `visibilitychange` e `pagehide`, reconecta a cada 1 s com o token só após fechamento sem código de aplicação ou por `timeout`; com `busy` (4001) mostra "ocupado", com 4004 mostra "sessão aberta noutra aba" e com `bad_token` volta a pedir o QR, sem tentar de novo (D-05, D-06, D-11, D-15) | T014, T029 | - | `Resources/RemoteKeyboard/keyboard.js` | 🟡 | `[X]` |
| T031 | Em `build-app.sh`, copiar `Resources/RemoteKeyboard` para `Contents/Resources` antes da assinatura, como a figura da 004 (D-15) | T029 | `[//]` | `scripts/build-app.sh` | 🟢 | `[X]` |

## Fase 5, Polimento

| ID | Descrição | Dependências | Paralelismo | Arquivo alvo | Confidência | Status |
|----|-----------|--------------|-------------|--------------|-------------|--------|
| T032 | Rodar `swift build -c release` e `./scripts/test.sh`; registrar nas notas de execução o total de testes, o número anterior (T001) e os avisos de compilação novos, se houver | T003, T004, T005, T006, T007, T008, T009, T028, T031 | - | `_reversa_forward/008-iphone-teclado-remoto/actions.md` | 🟢 | `[X]` |
| T033 | Instalar o app com `JOYSTICK_SIGN_IDENTITY="JoystickAI Local Signing" ./scripts/build-app.sh`, conferir a assinatura com `./scripts/check-signature.sh` e parar no PM-0 | T032 | - | `scripts/build-app.sh` | 🟢 | `[X]` |
| T034 | Registrar no `onboarding.md` §3 o resultado de P-01 a P-07; se P-01 for reprovada, parar e devolver a decisão de cifragem ao usuário | PM-0 | - | `_reversa_forward/008-iphone-teclado-remoto/onboarding.md` | 🟡 | `[X]` |
| T035 | Só se P-04 for reprovada: retirar o Caps Lock de `RemoteKeyGeometry` e de `RemoteKeyGeometryTests`, rodar `./scripts/test.sh` e reinstalar o app; aprovada, registrar "não aplicável" nas notas de execução (D-17) | T034 | - | `Sources/JoystickCore/Remote/RemoteKeyGeometry.swift` | 🟡 | `[X]` |
| T036 | Registrar no `onboarding.md` §4 o resultado do PM-1 por passo, com as observações | PM-1 | - | `_reversa_forward/008-iphone-teclado-remoto/onboarding.md` | 🟢 | `[ ]` |

## Notas de execução

- **T001 (2026-09-19):** `.reversa/reversa-config.json` lido na ativação do `/reversa-coding`: `allowLegacyEdits: true`, `allowedPaths` vazio (liberação irrestrita). Linha de base: 306 testes em 33 suítes, todos verdes. O `./scripts/test.sh` e o `swift build` falham no ambiente atual, sem relação com a feature: as Command Line Tools foram atualizadas em 2026-09-19 às 12h42 (Swift 6.4, SDK 27.0), o SDK 27 exige o plugin `SwiftUIMacros`, que as ferramentas não trazem, e o plugin `TestingMacros` passou para `usr/lib/swift/host/plugins/testing/`. A linha de base foi medida com `SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk` e `-Xswiftc -plugin-path -Xswiftc /Library/Developer/CommandLineTools/usr/lib/swift/host/plugins/testing`, sem alterar os scripts.

- **T029 a T031, T009 (2026-09-19):** `keyboard.js` exercitado fora do navegador por um roteiro com DOM e WebSocket simulados (pareamento por código, desenho com espaçador, toque, `modifiers`, `status`, `release`, reconexão com token após fechamento 1000 e parada definitiva no 4004), todos aprovados; o teste real no Safari fica para o PM-0. `index.html` não traz `meta` de CSP: a política vem no cabeçalho, único ponto que conhece o host do `connect-src`.
- **T032 (2026-09-19):** `swift build -c release` concluído sem erro nem aviso do código, só com os avisos do `ld` sobre caminhos ausentes das Command Line Tools (`Developer/usr/lib`, `Developer/Library/Frameworks`), do mesmo ambiente descrito em T001. Testes: 351 em 39 suítes, todos verdes, contra 306 em 33 da linha de base (+45 testes, +6 suítes). O `./scripts/test.sh` continua falhando pelo ambiente (T001); a contagem veio de `swift test` com o SDK 26.5 e o `-plugin-path`.
- **PM-0, correção (2026-09-19):** a página abriu por HTTPS, mas o canal recusava toda conexão com `remote.rejected` `bad_origin`: o Safari envia o `Origin` com o host em minúsculas (`macbook-pro-de-iago.local`), e `RemoteChannelListener` o comparava letra a letra com o `LocalHostName` (`MacBook-Pro-de-Iago.local`). A comparação passou a ignorar a caixa, como manda a RFC 4343; app reinstalado.
- **PM-0, sondas P-03 e P-04 (2026-09-19):** P-03 aprovada: "ç", "´" seguido de "a" e "⇧2" chegaram como "ç", "á" e "@" (o layout do usuário não é ABNT2). P-04 reprovada: o `flagsChanged` sintético do código 57 não mantém a trava. Um teste isolado confirmou que `IOHIDSetModifierLockState` liga e desliga a trava do sistema, e o usuário escolheu esse caminho em vez de T035: `CapsLockSwitch` novo, `KeyboardInjector.capsLock(down:)` alterna no pressionar, mensagem `caps` do servidor e ⇪ aceso na página com letras maiúsculas. D-17 revista no roadmap; T035 passa a "não aplicável". Suíte: 351 testes, todos verdes (+2 expectativas em `RemoteKeyboardMessageTests.codificaModificadoresEStatus`, sem teste novo); app reinstalado.
- **PM-0, P-04 revista (2026-09-19):** com a IOKit, o usuário confirmou no iPhone que o ⇪ liga e desliga a trava do sistema. P-04 aprovada pelo caminho revisto.
- **PM-0, P-06 (2026-09-19):** multitoque aprovado: ⌘ segurado com um dedo e C com outro copiaram no Mac.
- **PM-0, P-07 (2026-09-19):** `KBGetLayoutType(LMGetKbdType())` informa ISO (tipo 89), e o teclado físico do MacBook é o português de Portugal, ISO: aprovada. O usuário digita com a fonte "EUA Internacional" (que explica o ´ morto da P-03) e costuma ligar teclados externos ANSI; a página segue o teclado embutido, e o usuário preferiu manter assim por ora.
- **PM-0, P-02 (2026-09-19):** app reaberto e recurso ligado sem nenhum diálogo do chaveiro nem do firewall: aprovada.
- **PM-0, formato da página (2026-09-19):** com a geometria ISO, o canto superior esquerdo mostrava § (código 10), e o usuário, acostumado a teclados americanos com a fonte EUA Internacional, esperava ` e ~ (código 50). Por escolha dele, `KeyboardLayoutReader.physicalLayout` passou a devolver sempre ANSI; a detecção por `KBGetLayoutType` saiu, e a geometria ISO continua no núcleo e nos testes. D-12 revista; app reinstalado.
- **T034 e T035 (2026-09-19):** sondas P-01 a P-07 registradas no `onboarding.md` §3; P-05 aprovada no vigia, com a latência sem medição. T035 não aplicável: P-04 reprovada no caminho original, mas resolvida pela IOKit, com o ⇪ mantido por escolha do usuário.
- **PM-1, passo 7 (2026-09-19):** rótulos da página não acompanhavam a troca de fonte de entrada. `KeyboardLayoutReader` observava `kTISNotifySelectedKeyboardInputSourceChanged` com a entrega padrão, que o `NSApplication` suspende com o app fora de foco; passou a observar com `.deliverImmediately` (agora `NSObject`, com seletor). App reinstalado; passo a repetir.
- **PM-1, parcial (2026-09-19):** passos 1 a 12 aprovados (o 7 após a correção do `KeyboardLayoutReader`, o 8 pela P-03); 13 a 15 suspensos por falta de segundo aparelho; 16 e 17 pendentes. T036 segue aberta até o roteiro terminar; resultados parciais já no `onboarding.md` §4.

## Histórico de alterações

| Data | Alteração | Autor |
|------|-----------|-------|
| 2026-09-19 | Versão inicial gerada por `/reversa-to-do` | reversa |
| 2026-09-19 | Revisão após a segunda rodada do `audit/cross-check.md` (A014 a A016): T005, T020, T030 e T037 ajustadas | reversa |
| 2026-09-19 | Revisão após o `audit/cross-check.md` (A001, A002): T037 novo; T005, T007, T015, T020, T021 e T030 ajustados à D-06 e à D-17 revisadas | reversa |
