# Impacto no legado: iPhone como teclado remoto do Mac

> Identificador: `008-iphone-teclado-remoto`
> Data: `2026-09-19`
> Âncora: legado (`_reversa_sdd/architecture.md` + `_reversa_sdd/domain.md`, extração de 2026-09-15, com os adendos das features 001 a 007), com as specs SDD de `_reversa_sdd/` como complemento.
> Política de edição no momento da execução: `allowLegacyEdits: true`, `allowedPaths` vazio (liberação irrestrita do projeto), relida na ativação do `/reversa-coding`.
> Execução: parcial; 34 de 37 ações fechadas numa rodada (T001 a T033 e T037). Parada no portão manual PM-0, que libera T034; T035 depende da sonda P-04 e T036 do PM-1. Suíte: 306 → 351 testes, 33 → 39 suítes, todos verdes, medidos com o SDK 26.5 porque o `./scripts/test.sh` falha no ambiente atual (notas de execução de T001 e T032); `swift build -c release` sem avisos do código; app instalado e assinado com a identidade estável.

O app ganha, pela primeira vez, uma superfície de rede. Com o recurso ligado pelo menu, serve em HTTPS (47810) uma página que desenha o teclado do Mac no iPhone e recebe em WSS (47811) cada toque, só de endereços da rede local, de um aparelho por vez e depois do pareamento por código de seis dígitos. O núcleo decide o pareamento, a origem, as mensagens e o estado das teclas (modificadores mantidos e presos, vigia de 1 s, contagem de inválidas); o app executa os efeitos pelo `KeyboardInjector` existente, que ganha só o caminho do Caps Lock. O portão de injeção e o ciclo de vida passam a soltar também o teclado remoto. A identidade TLS vem do chaveiro, criada por script com uma autoridade local restrita a `.local`, cuja chave privada é apagada.

## Arquivos afetados

| Arquivo afetado | Componente | Tipo | Severidade | Justificativa |
|-----------------|------------|------|------------|---------------|
| `Sources/JoystickCore/Remote/RemoteKeyGeometry.swift` | Núcleo, remote (novo; `architecture.md` §3) | componente-novo | MEDIUM | Geometria ANSI e ISO em 6 linhas, com papel de cada tecla; modificadores direitos (54, 60, 61, 62) resolvem para o mesmo `KeyModifier` dos esquerdos. Define o que o canal aceita. |
| `Sources/JoystickCore/Remote/KeyLabelTable.swift` | Núcleo, remote | componente-novo | LOW | Rótulos nos quatro estados (sem modificador, ⇧, ⌥, ⇧⌥) e marca de tecla morta. |
| `Sources/JoystickCore/Remote/LocalAddressPolicy.swift` | Núcleo, remote | componente-novo | HIGH | Único filtro de origem: IPv4 privado e de enlace, IPv6 local e de enlace, v4 mapeado em v6; laço local só com a chave de teste. Decide quem chega ao canal (RN-01). |
| `Sources/JoystickCore/Remote/RemotePairing.swift` | Núcleo, remote | componente-novo | HIGH | Código de seis dígitos, token de 16 bytes, comparação em tempo constante, rotação na quinta falha, retomada pelo token e fim da sessão (RN-04, RN-05, RF-12). |
| `Sources/JoystickCore/Remote/RemoteKeyboardMessage.swift` | Núcleo, remote | delta-de-contrato-externo | MEDIUM | Codificação e decodificação das mensagens do canal, com limite de 1 KiB (`interfaces/remote-keyboard-protocol.md` §3). |
| `Sources/JoystickCore/Remote/RemoteKeyboardMachine.swift` | Núcleo, remote | componente-novo | HIGH | Teclas mantidas, modificadores soltos, mantidos ou presos (RN-07), Caps Lock, soltura geral, vigia de 1 s e cinco inválidas seguidas. Garante que nada fique preso pelo canal. |
| `Sources/JoystickCore/Log/LogEventCatalog.swift` | `diagnostics-log` (`architecture.md` §5) | delta-de-contrato-externo | LOW | Seis eventos `remote.*` e três enumerações de motivo; nenhum carrega tecla, código, token, rótulo ou endereço. `logSchema` segue 1. |
| `Sources/JoystickAIPoC/Injection/KeyboardInjector.swift` | `injection` (RN-IN-08) | regra-alterada | HIGH | `capsLock(down:)` posta `flagsChanged` do código 57 fora da contagem de `KeyModifier`, e `postKey` soma `maskAlphaShift` lido de `CGEventSource.flagsState(.hidSystemState)`. As assinaturas existentes não mudam. |
| `Sources/JoystickAIPoC/App/InjectionGate.swift` | `app-shell`, portão (RI-04) | regra-alterada | MEDIUM | Na suspensão, solta também o teclado remoto e guarda as solturas; na retomada, repete-as; avisa a página por `onAllowedChange`. |
| `Sources/JoystickAIPoC/App/Lifecycle.swift` | `app-shell` (001 RN-04) | regra-alterada | MEDIUM | O encerramento solta o remoto na fila `input` e depois fecha os listeners (`onCleanUp`). |
| `Sources/JoystickAIPoC/App/StatusMenu.swift` | `app-shell`, menu (003 RF-06) | regra-alterada | LOW | Itens "Teclado remoto", "Mostrar pareamento", "Enviar certificado ao iPhone…" e a linha de erro. |
| `Sources/JoystickAIPoC/App/AppDelegate.swift` | `app-shell`, montagem | regra-alterada | LOW | Monta ações, leitor de layout, serviço e janela de pareamento, e liga menu, portão e ciclo de vida. O recurso nasce desligado (RN-02). |
| `Sources/JoystickAIPoC/Remote/RemoteKeyboardIdentity.swift` | app, remote-keyboard (novo) | componente-novo | MEDIUM | Identidade TLS do chaveiro por nome, com verificação de validade e do nome `.local`; mensagens de falha para o menu. |
| `Sources/JoystickAIPoC/Remote/RemotePageListener.swift` | app, remote-keyboard | delta-de-contrato-externo | HIGH | HTTPS estático em 47810: três caminhos, 404, 405, 8 KiB, 5 s, cabeçalhos de CSP e `no-store`; conexões de fora da rede local fechadas sem resposta. |
| `Sources/JoystickAIPoC/Remote/RemoteChannelListener.swift` | app, remote-keyboard | delta-de-contrato-externo | HIGH | WSS em 47811: `Origin` conferido, `hello` em 5 s, 10 s de inatividade, códigos 4001 a 4004, substituição pela mesma sessão com soltura prévia. |
| `Sources/JoystickAIPoC/Remote/RemoteKeyboardActions.swift` | app, remote-keyboard | componente-novo | MEDIUM | Executa os efeitos da máquina na fila `input`, com repetição pelos tempos do sistema e vigia a cada 250 ms. |
| `Sources/JoystickAIPoC/Remote/KeyboardLayoutReader.swift` | app, remote-keyboard (I-15) | delta-de-contrato-externo | LOW | Disposição física e rótulos da fonte de entrada ativa, com a notificação de troca. |
| `Sources/JoystickAIPoC/Remote/RemoteKeyboardService.swift` | app, remote-keyboard | componente-novo | MEDIUM | Liga e desliga, publica código e URL, envia `layout`, `modifiers` e `status`, registra os eventos `remote.*`. |
| `Sources/JoystickAIPoC/Remote/PairingWindow.swift` | app, remote-keyboard | componente-novo | LOW | Janela flutuante com QR, código e endereço, legível a 3 m (RI-23 aplicada à janela nova). |
| `Resources/RemoteKeyboard/index.html`, `keyboard.css`, `keyboard.js` | página do teclado (nova) | componente-novo | MEDIUM | Teclado montado por APIs do DOM, multitoque, `ping` a 250 ms, `release` ao ocultar, reconexão só após fechamento sem código de aplicação; estados finais para `busy`, 4004 e recusas. |
| `scripts/build-app.sh` | Bundle (`architecture.md` §1) | regra-alterada | LOW | Copia `Resources/RemoteKeyboard` antes da assinatura e recusa montar sem os três arquivos. |
| `scripts/create-remote-keyboard-identity.sh` | Operação (novo) | componente-novo | MEDIUM | Autoridade local com restrição de nome `.local`, identidade do servidor importada no chaveiro, certificado da autoridade em Application Support, chave da autoridade apagada. |
| `Tests/JoystickCoreTests/RemoteKeyGeometryTests.swift`, `LocalAddressPolicyTests.swift`, `RemotePairingTests.swift`, `RemoteKeyboardMessageTests.swift`, `RemoteKeyboardMachineTests.swift`, `RemoteKeyboardAssetsTests.swift` | testes | regra-nova | LOW | Suítes novas: 5, 4, 9, 7, 14 e 5 testes. |
| `Tests/JoystickCoreTests/LogEventCatalogTests.swift` | testes | regra-alterada | LOW | Eventos `remote.*` em `sampleEvents` e níveis; +1 (`eventosDoTecladoRemotoSemConteudo`). 11 testes. |
| Chaveiro de sessão e `~/Library/Application Support/joystick-ai/` | dados fora do app (`data-delta.md`) | delta-de-dados | MEDIUM | Identidade "JoystickAI Remote Keyboard" e certificado da autoridade, criados só pelo script. `config.json` não muda. |
| `~/Library/Logs/joystick-ai/poc-*.jsonl` (formato) | `diagnostics-log` | delta-de-dados | LOW | Eventos `remote.enabled`, `remote.disabled`, `remote.connected`, `remote.rejected`, `remote.watchdog`, `remote.disconnected`. |
| Integrações I-14 (rede local) e I-15 (fontes de entrada); I-05 (TCC e firewall) | integrações externas (`architecture.md` §4) | delta-de-contrato-externo | HIGH | Primeira escuta de rede do app; nenhuma permissão TCC nova, mas o firewall do macOS pode perguntar na primeira escuta. `permissions.md` registrava "Rede: nenhuma". |

## Diff conceitual por componente

**Rede (001 RN-12, `permissions.md`).** Antes, o app não abria socket algum, e a extração registrava a ausência de rede como regra 🟢. Agora, só com o recurso ligado, duas portas TCP escutam em todas as interfaces, mas o filtro de origem fecha qualquer conexão de fora da rede local antes de um byte de resposta, o TLS é obrigatório, e só o aparelho pareado envia teclas. Desligado, as portas não existem. A regra passa a ler "sem rede, exceto o teclado remoto, restrito à rede local e desligado por padrão".

**Núcleo.** Ganha a pasta `Remote/`, fiel ao estilo "núcleo funcional com casca imperativa": a máquina devolve `RemoteKeyboardEffect`, o pareamento devolve `PairingOutcome`, e nenhum tipo importa algo além de `Foundation`. A máquina é a garantia de RN-04 para o canal: fechamento, suspensão, vigia e encerramento passam por `releaseAll`.

**`injection`.** O `KeyboardInjector` recebe um segundo consumidor de teclado. Os modificadores remotos usam a contagem existente, somada à do controle, e por isso um ⌘ do controle e outro do iPhone só soltam quando os dois soltam. O Caps Lock fica fora da contagem, por caminho próprio; o `maskAlphaShift` passa a acompanhar toda tecla postada, o que estende RN-IN-08.

**`app-shell`.** O portão de injeção, que já soltava botões de mouse e atalhos na suspensão (RI-04), passa a soltar também o remoto e a avisar a página; o ciclo de vida solta o remoto antes de fechar os listeners. O menu ganha três itens e a linha de erro; a montagem em `AppDelegate` cria os objetos sem ligar o recurso.

**Página.** Nova, servida pelo app e não pelo `WKWebView`; segue as regras de isolamento da figura da 004 (sem HTML em texto, sem avaliação de código, só arquivos irmãos), com a diferença deliberada de usar rede (o canal) e `sessionStorage` (o token).

## Preservadas

Regras 🟢 de `_reversa_sdd/domain.md` e das specs que continuam intactas:

- 001 RN-01 a RN-11: controle ativo, zonas mortas, gatilhos, touchpad, precisão, clique duplo, telas e mapeamento do ponteiro.
- 002 RN-01 a RN-07 e E001: a paleta não conhece o remoto; o remoto não abre a paleta.
- 003 RN-01 a RN-16: atalhos, configuração e editor; `config.json` não ganha campo.
- RN-IN-02: a injeção continua começando desligada e só o portão a altera; o remoto, com a injeção desligada, é descartado como o resto e a página é avisada.
- RN-IN-10 e RI-06: setas remotas passam por `postKey` e recebem `maskNumericPad` e `maskSecondaryFn`.
- RN-IN-12, RN-IN-13, RN-IN-16, RN-IN-17 e RI-07: texto, soltura forçada, ausência de teclas no log e contagem com a injeção desligada.
- 003 RN-14 e RN-IN-16: nenhum evento `remote.*` carrega tecla, código, token, rótulo ou endereço.
- RI-01 a RI-03, RI-05, RI-08 a RI-29: instância única, ordem de montagem, detecção de permissão, cursor, HID e demais regras implícitas.

## Modificadas

| Regra | Antes | Depois | Tipo |
|-------|-------|--------|------|
| 001 RN-12 (`domain.md` §3.1) e `permissions.md` §2, linha "Rede" | Sem rede; nenhum socket em `Sources/` | Sem rede, exceto o teclado remoto: desligado por padrão, só rede local, TLS, um aparelho pareado | alterada |
| 001 RN-04 (`domain.md` §3.1) | Nenhuma desconexão do controle deixa entrada presa | Vale também para o canal remoto: fechamento, substituição, vigia de 1 s, suspensão e encerramento soltam tudo | estendida |
| RI-04 (`domain.md` §4) | A suspensão solta botões de mouse e atalhos e repete as solturas na retomada | Solta também o teclado remoto, repete as solturas dele e avisa a página | estendida |
| RN-IN-08 (`injecao-de-eventos/requirements.md`) | `flags` são os modificadores com contagem maior que zero | Somam `maskAlphaShift` quando o Caps Lock do sistema está ligado; o Caps Lock remoto é postado por `capsLock(down:)`, fora da contagem | alterada |
