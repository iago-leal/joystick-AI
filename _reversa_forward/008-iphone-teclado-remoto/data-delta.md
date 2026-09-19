# Delta de dados: iPhone como teclado touch do Mac

> Identificador: `008-iphone-teclado-remoto`
> Data: `2026-09-19`
> Base: `_reversa_sdd/data-dictionary.md`, `_reversa_sdd/architecture.md#5. Modelo de dados em arquivo`
> Confidência: 🟢 salvo indicação

## 1. Arquivos persistidos

| Formato | Mudança | Migração |
|---------|---------|----------|
| `config.json` (`~/.config/joystick-ai/`) | Nenhuma: o recurso nasce desligado a cada abertura (RN-02) e não tem preferência gravada | n/a |
| Log JSONL (`~/Library/Logs/joystick-ai/`) | Seis eventos novos, aditivos; `logSchema` segue 1 (`interfaces/diagnostic-log.md`) | n/a |
| Resultados da tela de alvos | Nenhuma | n/a |

## 2. Itens novos fora do app

Criados só pelo `scripts/create-remote-keyboard-identity.sh`; o app apenas os lê (`interfaces/identidade-tls.md`).

| Item | Local | Conteúdo | Proteção |
|------|-------|----------|----------|
| Identidade do servidor | Chaveiro de sessão, rótulo "JoystickAI Remote Keyboard" | Chave privada RSA 2048 e certificado para `<LocalHostName>.local`, 825 dias | Controle de acesso do chaveiro, liberado ao app assinado por "JoystickAI Local Signing" 🟡 |
| Certificado da autoridade | `~/Library/Application Support/joystick-ai/remote-keyboard/JoystickAI-Local-CA.cer` | Só o certificado público, DER, 10 anos, restrição de nome `.local` | Pasta `0700`, arquivo `0600` |
| Chave da autoridade | Nenhum | Apagada ao fim do script | n/a |

## 3. Tipos novos no `JoystickCore`

| Tipo | Campos e casos | Uso |
|------|----------------|-----|
| `RemoteKey` | `code: UInt16`, `kind: .regular \| .modifier(KeyModifier) \| .capsLock` | Tecla da geometria |
| `RemoteKeyGeometry` | `physical: .ansi \| .iso`, `rows: [[RemoteKey]]`, `contains(code:)` | Lista de teclas aceitas e desenhadas (D-16); modificadores direitos 54, 60, 61, 62 mapeados a ⌘, ⇧, ⌥, ⌃ |
| `ModifierState` | `.released \| .held \| .latched` | Estado enviado à página (RF-06) |
| `RemoteKeyboardMachine` | teclas comuns mantidas, estado por modificador, `pendingLatchRelease`, `repeating: UInt16?`, `lastMessageNs`, `keyCount`, `invalidInARow` (contador de mensagens inválidas seguidas; o listener decodifica e a máquina conta) | Máquina de D-08 |
| `RemoteKeyboardEffect` | `.keyDown(UInt16)`, `.keyUp(UInt16)`, `.modifierDown(KeyModifier)`, `.modifierUp(KeyModifier)`, `.capsLock(down: Bool)`, `.startRepeat(UInt16)`, `.stopRepeat`, `.modifiers([KeyModifier: ModifierState])` | Saída da máquina, executada pelo app |
| `RemotePairing` | `code: String` (6 dígitos), `failures: Int`, `token: [UInt8]?` (16 bytes), `activeSession: Bool` | D-05, D-06 |
| `PairingOutcome` | `.accepted(token)`, `.resumed(token, replacesActive: Bool)`, `.rejected(.badCode \| .busy \| .badToken)`, `.codeRotated` | Resposta à primeira mensagem; `replacesActive` manda o servidor soltar e fechar a conexão ativa (D-06) |
| `LocalAddressPolicy` | `isAllowed(_ address: String) -> Bool` | D-07 |
| `RemoteKeyboardMessage` | cliente: `hello`, `down`, `up`, `ping`, `release`, `bye`; servidor: `welcome`, `reject`, `layout`, `modifiers`, `status` | Codificação JSON do canal (`interfaces/remote-keyboard-protocol.md`) |
| `KeyLabelTable` | por código: `plain`, `shift`, `option`, `shiftOption` (String) e `dead: Set<Estado>` | Rótulos de D-12, calculados no app e serializados pelo núcleo |

## 4. Tipos alterados

| Tipo | Mudança |
|------|---------|
| `LogEventCatalog` | Fábricas `remoteEnabled`, `remoteDisabled`, `remoteConnected`, `remoteRejected(reason:)`, `remoteWatchdog(held:)`, `remoteDisconnected(reason:keys:)`, e os enums `RemoteRejectReason` e `RemoteDisconnectReason` |
| `KeyboardInjector` (app) | Método novo `capsLock(down:) -> Bool?`: no pressionar, inverte a trava do sistema por `CapsLockSwitch` (IOKit, `IOHIDSetModifierLockState`) e devolve o estado novo; fora de `modifierCounts`; `postKey` acrescenta `maskAlphaShift` quando `CGEventSource.flagsState(.hidSystemState)` o indicar (D-17, revista no PM-0) 🟢 |
| `KeyChord` | Nenhuma mudança de tipo; passa a ser criado com códigos fora do `KeyCatalog` pelo teclado remoto 🟢 |

## 5. Estado em memória no app

| Estado | Dono | Vida |
|--------|------|------|
| Listeners, conexão ativa | `RemoteKeyboardServer` (fila própria do `Network`, que entrega na fila `input`) | Do ligar ao desligar |
| Máquina, temporizador de repetição, vigia | `RemoteKeyboardActions` (fila `input`) | Da conexão à queda |
| Tabela de rótulos | `KeyboardLayoutReader` (main thread) | Recalculada a cada troca de fonte |
| Código e token | `RemotePairing` dentro do servidor | Do ligar ao desligar; nunca em disco |
