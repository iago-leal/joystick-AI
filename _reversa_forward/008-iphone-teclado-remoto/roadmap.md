# Roadmap: iPhone como teclado touch do Mac

> Identificador: `008-iphone-teclado-remoto`
> Data: `2026-09-19`
> Requirements: `_reversa_forward/008-iphone-teclado-remoto/requirements.md`
> Confidência: 🟢 CONFIRMADO, 🟡 INFERIDO, 🔴 LACUNA

## 1. Resumo da abordagem

O app passa a servir, na rede local e só quando o usuário liga o recurso, uma página cifrada que desenha o teclado do Mac no iPhone. A página envia pressionar e soltar de cada tecla, identificada pelo código virtual da posição física, por um canal WebSocket cifrado; o Mac decide modificadores presos, repetição e soltura numa máquina pura do `JoystickCore` e executa os efeitos pelo `KeyboardInjector` que o controle já usa, o que dá de graça a contagem compartilhada de modificadores, as máscaras das setas e das teclas F e o portão de injeção. Os rótulos saem da fonte de entrada ativa, lida pelo app e enviada à página. A cifragem usa uma autoridade certificadora local, criada por script como a identidade de assinatura da 001, cuja chave é descartada logo após emitir o certificado do servidor; o certificado da autoridade chega ao iPhone por AirDrop, a partir do menu do app. Nada é acrescentado ao `config.json`, e nenhuma dependência de terceiros entra no projeto.

A execução tem dois portões. O PM-0 responde às sondas de plataforma (confiança no iOS, TLS com a identidade do chaveiro, injeção por código de tecla no ABNT2, Caps Lock, latência) com o esqueleto do servidor e uma página mínima; o PM-1 percorre os cenários do `requirements.md` com a feature completa.

## 2. Princípios aplicados

`.reversa/principles.md` não existe neste projeto. Na falta dele, a tabela confronta a feature com as restrições equivalentes fixadas pelos ADRs e pelo domínio.

| Princípio | Como a feature se relaciona | Status |
|-----------|------------------------------|--------|
| ADR-001, SwiftPM sem Xcode, núcleo puro e sem dependências de terceiros | Servidor com `Network`, QR com `CoreImage`, rótulos com `Carbon.HIToolbox`, todos do sistema; regras no `JoystickCore`, que segue só com `Foundation` | respeita |
| ADR-002, assinatura local para preservar o TCC | O caminho e a identidade do app não mudam; a identidade TLS é outra, com rótulo próprio no chaveiro | respeita |
| ADR-005, injeção por `CGEvent` com marca | Toda tecla remota sai pelo `KeyboardInjector`, com a marca `0x4A4F5953` | respeita |
| ADR-008, log JSONL tipado sem dados sensíveis | Eventos `remote.*` sem teclas, rótulos, código nem endereço | respeita |
| 001 RN-12, sem rede (`_reversa_sdd/domain.md#3.1 Controle e entrada (001)`) | O app passa a escutar duas portas TCP na rede local | conflita, por decisão registrada em `requirements.md` RN-01 |
| 002 D-05, um único injetor de teclado | O teclado remoto recebe a mesma instância criada em `AppDelegate` | respeita |

## 3. Decisões técnicas

| ID | Decisão | Justificativa | Alternativas descartadas | Confidência |
|----|---------|----------------|--------------------------|-------------|
| D-01 | Página web servida pelo app, aberta no Safari do iPhone e, de preferência, adicionada à Tela de Início para abrir sem a barra do navegador | Única via sem instalar aplicativo nem depender de função que o iOS não oferece (`investigation.md` §2) | App nativo para iOS; teclado Bluetooth emulado; Controle Universal | 🟢 |
| D-02 | Dois `NWListener` com TLS 1.2 ou superior: porta 47810 para a página (HTTP/1.1 mínimo, só `GET` dos arquivos estáticos) e porta 47811 para o canal (`NWProtocolWebSocket` em modo servidor). Portas fixas; ocupadas, o recurso não liga e o menu mostra o erro | `Network` faz TLS e o aperto de mão do WebSocket sem código próprio de criptografia nem de enquadramento; portas fixas mantêm a URL estável | Uma porta com HTTP e WebSocket escritos à mão; `BSD sockets` com `SecureTransport`, obsoleto; servidor de terceiros, vedado pelo ADR-001 | 🟡 |
| D-03 | Identidade TLS por `scripts/create-remote-keyboard-identity.sh`, com o `openssl` do sistema: autoridade local com restrição de nome a `.local` (10 anos) e certificado de servidor para `<LocalHostName>.local` (825 dias, `serverAuth`). A chave da autoridade é apagada ao fim do script; a identidade do servidor vai ao chaveiro de sessão com o rótulo "JoystickAI Remote Keyboard"; o certificado da autoridade fica em `~/Library/Application Support/joystick-ai/remote-keyboard/JoystickAI-Local-CA.cer` | Segue o precedente de `create-local-signing-identity.sh`; sem a chave da autoridade, ninguém que a obtenha do Mac consegue forjar outros sites para o iPhone | Certificado autoassinado sem autoridade, que o iOS não deixa marcar como confiável para TLS; gerar X.509 dentro do app, que exigiria codificador ASN.1 próprio; guardar a chave da autoridade | 🟡 |
| D-04 | Menu "Enviar certificado ao iPhone…" abre o AirDrop com o arquivo da autoridade (`NSSharingService` `.sendViaAirDrop`); o `onboarding.md` descreve instalar o perfil e ligar a confiança total no iOS | Atende RF-03 (o app oferece a identidade) sem abrir porta sem cifragem para baixar o certificado | Servir o certificado por HTTP sem TLS durante a instalação | 🟡 |
| D-05 | Pareamento no núcleo (`RemotePairing`): código de 6 dígitos por sessão, colocado no fragmento da URL do QR (`#c=`), que o navegador não envia no HTTP; a página o apresenta na primeira mensagem do canal. Cinco códigos errados geram código novo. Aceito o código, o Mac devolve um token aleatório de 128 bits, válido até o recurso desligar, que a página guarda em `sessionStorage` para reconectar (RF-12). Comparações em tempo constante | RN-04, RF-12; o fragmento mantém o código fora de qualquer registro de requisição | Senha fixa em configuração; pareamento permanente por aparelho | 🟢 |
| D-06 | Um aparelho por vez: com sessão ativa, a nova conexão só é examinada pelo `hello`. Com o token da sessão, ela substitui a conexão ativa, que tem tudo solto e é fechada (código 4004, `reason: replaced`); com código ou outro token, recebe `busy` e é fechada. A sessão termina com `bye`, queda do canal, substituição ou recurso desligado. A página trata `busy` como final e não tenta de novo; fechada com 4004, entende que outra aba assumiu a sessão e também não tenta de novo, o que evita duas abas com o mesmo token tomarem a sessão uma da outra | RN-05; RF-12: ao desbloquear, a página retoma pelo token sem esperar o Mac notar a queda da conexão antiga, que pode levar até 10 s (§3.5 do protocolo) | Última conexão derruba a anterior sem token, o que deixaria outro aparelho com o código tomar a sessão; recusar a retomada até o tempo esgotar | 🟡 |
| D-07 | Filtro de origem no núcleo (`LocalAddressPolicy`): aceita IPv4 10/8, 172.16/12, 192.168/16 e 169.254/16, IPv6 `fe80::/10` e `fc00::/7`, e laço local só em teste; demais conexões são fechadas sem resposta. O canal também exige o cabeçalho `Origin` igual a `https://<LocalHostName>.local:47810` | RN-01; o `Origin` impede que outra página aberta no iPhone use o canal | Confiar só no roteador doméstico | 🟢 |
| D-08 | Máquina pura `RemoteKeyboardMachine` no `JoystickCore`: recebe pressionar e soltar por código de tecla, sinal de vida e queda; devolve efeitos (tecla, modificador, iniciar e parar repetição, soltar tudo) e o estado de cada modificador (solto, mantido, preso) para a página. Implementa RN-07: modificador pressionado vira efeito imediato; solto sem outra tecla no meio fica preso; a próxima tecla comum, ao ser solta, solta os presos; tocar um preso o solta | RNF de arquitetura; permite testar RN-07, RN-09 e RN-10 sem rede nem hardware | Estado de modificadores na página, que deixaria o Mac sem saber o que soltar numa queda | 🟢 |
| D-09 | Execução pelo `KeyboardInjector` existente: tecla comum por `chordDown`/`chordUp` com `KeyChord(código)` sem modificadores; modificadores por `modifierDown`/`modifierUp`, com ⌘, ⇧, ⌥ e ⌃ direitos mapeados ao mesmo `KeyModifier` dos esquerdos; repetição por `chordRepeat` | RN-06, RN-08 (contagem compartilhada, `injecao-de-eventos` RN-IN-07); herda as máscaras de setas e teclas F (RN-IN-10, adendo 006) | Injeção por `keyboardSetUnicodeString`, que ignoraria a fonte de entrada e as teclas mortas | 🟢 |
| D-10 | Repetição no Mac, na fila `input`: atraso e intervalo lidos de `NSEvent.keyRepeatDelay` e `NSEvent.keyRepeatInterval` a cada início; só a última tecla comum segurada repete; modificadores nunca repetem. O `KeyRepeat` fixo do controle não muda | RN-09; repetir no Mac torna a cadência imune ao atraso da rede | Repetição gerada pela página, sujeita à variação do Wi-Fi | 🟡 |
| D-11 | Vigia: a página envia `ping` a cada 250 ms; se o Mac ficar 1 s sem mensagem com qualquer tecla ou modificador mantido ou preso, a máquina solta tudo e interrompe a repetição, sem encerrar a sessão. Fechamento do canal e `visibilitychange` para oculto também soltam tudo | RN-10, RF-11 (soltura em até 1 s) | Depender só do fechamento do TCP, que pode levar dezenas de segundos com o iPhone bloqueado | 🟡 |
| D-12 | Rótulos por `KeyboardLayoutReader` no app: `TISCopyCurrentKeyboardLayoutInputSource` e `UCKeyTranslate` para cada código da geometria, nos estados sem modificador, ⇧, ⌥ e ⇧⌥, marcando teclas mortas; a troca de fonte, observada por `kTISNotifySelectedKeyboardInputSourceChanged`, reenvia a tabela. A geometria (ANSI ou ISO) segue `KBGetLayoutType(LMGetKbdType())`. **Revista no PM-0:** a disposição desenhada é sempre ANSI, por escolha do usuário; a detecção do teclado embutido (P-07, ISO) saiu do app | RN-12, RF-08, RF-09; é o mesmo cálculo que o Teclado de Acessibilidade faz | Tabelas fixas por layout na página | 🟡 |
| D-13 | Portão e ciclo de vida: `InjectionGate` passa a soltar o teclado remoto na suspensão e a repetir as solturas na retomada, como faz com `ShortcutActions`, e avisa a página (`status`); `Lifecycle.cleanUp` solta tudo e fecha os listeners | RN-11, RF-10; 001 RN-04 | Deixar o descarte silencioso de RN-IN-02 | 🟢 |
| D-14 | Mac: `StatusMenu` ganha "Teclado remoto" (ligar e desligar, com marca), "Mostrar pareamento" e "Enviar certificado ao iPhone…"; ligar abre `PairingWindow` (SwiftUI em escala de TV, `EditorMetrics`) com QR de `CIQRCodeGenerator`, endereço e código, que fecha ao parear e reabre pelo menu. O recurso nasce desligado a cada abertura | RF-01, RF-02, RN-02 | Preferência persistida de "ligado" | 🟢 |
| D-15 | Página em `Resources/RemoteKeyboard/` (`index.html`, `keyboard.css`, `keyboard.js`), copiada ao bundle por `scripts/build-app.sh` como a figura da 004. Toque por `touchstart`, `touchend` e `touchcancel` em cada tecla, com vários dedos; sem `innerHTML` nem avaliação de código; zoom e rolagem desativados; na vertical, mostra só o aviso "gire o iPhone" | RF-04 a RF-06, RF-10; mesma regra de segurança de `FigureAssetsTests` | Eventos de clique, que perdem o multitoque e atrasam | 🟡 |
| D-16 | Mensagens do canal em JSON com campo `t`; códigos de tecla aceitos só se estiverem na geometria enviada; mensagem inválida é descartada e contada, e cinco seguidas encerram a sessão | Limita o canal ao que a página desenha (`requirements.md` RN-01) | Aceitar qualquer código virtual | 🟢 |
| D-17 | Caps Lock por caminho próprio: o `KeyboardInjector` ganha `capsLock(down:)`, que no pressionar inverte a trava do sistema por `IOHIDSetModifierLockState` (`CapsLockSwitch`), fora da contagem de `KeyModifier`, e no soltar não posta nada; o estado da trava vai à página pela mensagem `caps`; a máquina emite `.capsLock(down:)` para a tecla de tipo `.capsLock`, que não repete, não fica presa nem solta os modificadores presos, e entra na soltura geral se estiver pressionada. Como o estado alternado é do sistema, e não da máquina, `postKey` passa a acrescentar `maskAlphaShift` às `flags` quando `CGEventSource.flagsState(.hidSystemState)` o indicar, o que vale também para o Caps Lock físico e para os acordes do controle (amplia RN-IN-08). **Revista no PM-0:** a sonda P-04 reprovou o `flagsChanged` sintético do código 57, que não alterna a trava; a IOKit alterna, e a tecla fica | O sistema trata Caps Lock de forma especial, e `modifierDown` só cobre ⌘, ⇧, ⌥ e ⌃; sem o método, a P-04 não teria o que testar | Emular Caps Lock com ⇧ preso, que erra números e símbolos; mandar o 57 como tecla comum por `chordDown`, que posta `keyDown` em vez de `flagsChanged` | 🟡 |
| D-18 | Log: eventos aditivos `remote.enabled`, `remote.disabled`, `remote.connected`, `remote.rejected` (`reason`), `remote.watchdog` e `remote.disconnected` (`reason`, `keys`); `logSchema` segue 1 | RN-13, RF-13 | Contar teclas por tipo, que se aproximaria do conteúdo | 🟢 |

## 4. Premissas

O `requirements.md` não tem `[DÚVIDA]` pendente. As premissas abaixo vêm das lacunas 🟡 da seção 10 e são respondidas pelas sondas do PM-0 (`investigation.md` §5).

| Premissa | Origem (`requirements.md` seção) | Risco se errada |
|----------|----------------------------------|-----------------|
| O iOS aceita, como raiz confiável para TLS, uma autoridade instalada por perfil com confiança total, e o Safari abre a página e o WebSocket sem aviso (P-01) | §10, primeira lacuna; RF-03 | Sem cifragem viável, RN-03 cai; volta ao usuário a escolha da sessão de 2026-09-19 |
| `NWListener` usa a identidade do chaveiro sem pedir senha a cada abertura, e o firewall aceita o app assinado localmente (P-02) | §10, quarta lacuna | Diálogos a cada abertura; a identidade teria de ir para arquivo protegido |
| A tecla injetada por código respeita a fonte ABNT2, inclusive teclas mortas (P-03) | §10, segunda lacuna | Rótulos certos e caracteres errados; exigiria tradução para Unicode no Mac |
| A latência p95 fica abaixo de 150 ms e o vigia de 1 s não solta teclas em uso normal (P-05) | §6, desempenho; §10, quinta lacuna | Digitação atrasada ou modificadores soltos no meio de um atalho |

## 5. Delta arquitetural

| Componente | Arquivo de origem no legado | Tipo de mudança | Resumo |
|------------|------------------------------|-----------------|--------|
| `JoystickCore` / remote (novo) | `_reversa_sdd/architecture.md#3. Camadas e dependências` | componente-novo | `RemoteKeyboardMachine`, `RemotePairing`, `LocalAddressPolicy`, `RemoteKeyboardMessage` e `RemoteKeyGeometry`, só com `Foundation` |
| app / remote-keyboard (novo) | `_reversa_sdd/architecture.md#3. Camadas e dependências` | componente-novo | `RemoteKeyboardServer` (listeners, HTTP estático, canal), `RemoteKeyboardIdentity` (chaveiro), `RemoteKeyboardActions` (fila `input`, repetição, vigia), `KeyboardLayoutReader`, `PairingWindow` |
| `injection` | `_reversa_sdd/architecture.md#3. Camadas e dependências` | regra-alterada | `KeyboardInjector` ganha um consumidor e o método `capsLock(down:)` (D-17); as assinaturas existentes não mudam |
| `app-shell` | `_reversa_sdd/architecture.md#3. Camadas e dependências` | regra-alterada | `AppDelegate` monta o remoto; `StatusMenu` ganha três itens; `InjectionGate` e `Lifecycle` passam a soltar o remoto |
| Integração nova I-14, rede local | `_reversa_sdd/architecture.md#4. Integrações externas` | contrato-novo | HTTPS em 47810 e WSS em 47811, só rede local, com pareamento (`interfaces/remote-keyboard-protocol.md`) |
| Integração nova I-15, fontes de entrada | `_reversa_sdd/architecture.md#4. Integrações externas` | contrato-novo | Leitura da fonte ativa e da tradução de teclas; notificação de troca |
| I-05 TCC e firewall | `_reversa_sdd/architecture.md#4. Integrações externas` | regra-alterada | Nenhuma permissão TCC nova; possível aviso do firewall para conexões recebidas |
| `diagnostics-log` | `_reversa_sdd/architecture.md#5. Modelo de dados em arquivo` | contrato-alterado | Seis eventos `remote.*` (`interfaces/diagnostic-log.md`) |
| Bundle | `_reversa_sdd/architecture.md#1. Visão geral` | regra-alterada | `Contents/Resources/RemoteKeyboard/` com três arquivos, selados pela assinatura |

## 6. Delta no modelo de dados

- Resumo das mudanças: nenhum campo novo em `config.json`. Persistem fora do app a identidade TLS no chaveiro e o certificado da autoridade em Application Support, ambos criados pelo script. Em memória, o núcleo ganha os tipos do pareamento, da máquina e das mensagens; o log ganha seis eventos.
- Detalhe completo em: `_reversa_forward/008-iphone-teclado-remoto/data-delta.md`

## 7. Delta de contratos externos

| Contrato | Tipo | Arquivo de detalhe |
|----------|------|--------------------|
| Página e canal do teclado remoto | HTTP e WebSocket, ambos sobre TLS | `_reversa_forward/008-iphone-teclado-remoto/interfaces/remote-keyboard-protocol.md` |
| Identidade TLS (script, chaveiro, arquivo) | arquivo e chaveiro | `_reversa_forward/008-iphone-teclado-remoto/interfaces/identidade-tls.md` |
| Log de diagnóstico | arquivo JSONL | `_reversa_forward/008-iphone-teclado-remoto/interfaces/diagnostic-log.md` |

## 8. Plano de migração

n/a. A feature não altera `config.json` nem o formato do log além de eventos aditivos. Quem não rodar o script de identidade continua com o app como antes; ligar o recurso sem identidade mostra no menu "Identidade do teclado remoto ausente" e registra `remote.rejected` com `reason: no_identity`.

## 9. Riscos e mitigações

| Risco | Impacto | Probabilidade | Mitigação |
|-------|---------|---------------|-----------|
| O fluxo de confiança do iOS falha ou muda entre versões | alto | médio | Sonda P-01 no PM-0, antes de construir o resto; passos exatos no `onboarding.md` |
| Tecla ou modificador preso no Mac após queda do Wi-Fi | alto | médio | Vigia de 1 s (D-11), soltura em `visibilitychange`, no fechamento e em `Lifecycle` |
| Aparelho indevido na rede dispara atalhos | alto | baixo | Recurso desligado por padrão, código por sessão com limite de tentativas, TLS com autoridade própria, `Origin` e filtro de faixa |
| Chave da autoridade vazada permitiria forjar sites no iPhone | alto | baixo | Chave apagada ao fim do script e restrição de nome a `.local` (D-03) |
| Renomear o Mac invalida o certificado | médio | baixo | O app compara `LocalHostName` com o SAN ao ligar e orienta rodar o script de novo |
| Economia de energia do Wi-Fi do iPhone gera atrasos acima de 150 ms ou soltura falsa pelo vigia | médio | médio | Medição em P-05; o vigia só age com tecla mantida e não encerra a sessão |
| Página ocupa a tela com a barra do Safari na horizontal | médio | alto | Uso como aplicativo da Tela de Início (D-01) |
| Colisão com o controle segurando o mesmo modificador | baixo | médio | Contagem compartilhada do `KeyboardInjector` (D-09), coberta por teste |

## 10. Critério de pronto

- [ ] Todas as ações do `actions.md` marcadas `[X]`
- [ ] `cross-check.md` (se executado) sem CRITICAL nem HIGH
- [ ] `regression-watch.md` gerado
- [ ] Re-extração reversa executada e sem regressão vermelha (recomendado, não obrigatório)
- [ ] PM-0 com P-01 a P-07 respondidas e registradas no `onboarding.md`
- [ ] PM-1 com os cenários do `requirements.md` §7 aprovados no iPhone e no Mac
- [ ] `./scripts/test.sh` verde, com as suítes novas do núcleo, e `swift build -c release` sem avisos novos

## 11. Histórico de alterações

| Data | Alteração | Autor |
|------|-----------|-------|
| 2026-09-19 | Versão inicial gerada por `/reversa-plan` | reversa |
| 2026-09-19 | D-12 revista no PM-0: a página desenha sempre ANSI, por escolha do usuário (fonte EUA Internacional com teclados externos americanos); a geometria ISO fica no núcleo | reversa |
| 2026-09-19 | D-17 revista no PM-0: P-04 reprovou o `flagsChanged` sintético; Caps Lock pela IOKit, com a mensagem `caps` à página (escolha do usuário em vez de T035) | reversa |
| 2026-09-19 | Correção dos achados A014 a A016 da segunda rodada do `audit/cross-check.md`: D-17 leva `maskAlphaShift` do estado do sistema às teclas seguintes; D-06 define 4004 como final na página; o protocolo responde `busy` a qualquer `hello` sem o token da sessão enquanto houver conexão ativa | reversa |
| 2026-09-19 | Correção dos achados A001 e A002 do `audit/cross-check.md`: D-17 ganha o caminho de injeção do Caps Lock (`capsLock(down:)`, efeito `.capsLock`); D-06 deixa o token da sessão substituir a conexão ativa, e a página trata `busy` como final | reversa |
