# Investigação: iPhone como teclado touch do Mac

> Identificador: `008-iphone-teclado-remoto`
> Data: `2026-09-19`
> Confidência: 🟢 CONFIRMADO, 🟡 INFERIDO, 🔴 LACUNA

As afirmações sobre as plataformas da Apple vêm do conhecimento prévio e não foram verificadas nesta sessão, salvo quando há referência ao código do projeto. Por isso aparecem como 🟡 e são confirmadas pelas sondas da §5.

## 1. Pergunta

Como fazer o iPhone, preso ao controle, funcionar como um teclado de Mac completo, com ⌘, ⇧, ⌥ e ⌃, sem instalar aplicativo e sem distribuição pela App Store?

## 2. Alternativas avaliadas

| Alternativa | Avaliação | Veredito |
|-------------|-----------|----------|
| Espelhamento do iPhone (macOS 15) | O Mac controla o iPhone; o sentido é o inverso do pedido 🟡 | descartada |
| Sidecar e Controle Universal | Funcionam só com o iPad 🟡 | descartada |
| iPhone como teclado Bluetooth (perfil HID) | O `CoreBluetooth` do iOS não permite anunciar o serviço HID a aplicativos 🟡 | descartada |
| Aplicativos de controle remoto de mercado (Remote Mouse, Unified Remote e similares) | Resolvem com servidor próprio no Mac, mas acrescentam outro processo com Acessibilidade, sem os modificadores presos à maneira do Teclado de Acessibilidade e sem integração com o controle | descartada, mas confirma o padrão arquitetural |
| App nativo para iOS | Exigiria Xcode e assinatura com renovação a cada 7 dias numa conta gratuita; o projeto usa só as Command Line Tools (ADR-001) | descartada |
| Página web servida pelo app do Mac | Sem instalação; o app já injeta teclas e já empacota uma página (`Resources/ControllerFigure`, feature 004) 🟢 | escolhida (D-01) |

## 3. Transporte e cifragem

| Opção | Avaliação | Veredito |
|-------|-----------|----------|
| HTTP e WebSocket sem TLS | Rejeitada pelo usuário na sessão de 2026-09-19 (cifragem obrigatória) 🟢 | descartada |
| Certificado autoassinado aceito por exceção no Safari | O iOS não oferece "confiança total" para certificado folha, e a exceção não vale de forma confiável para o WebSocket 🟡 | descartada |
| Autoridade local instalada como perfil, com confiança total, e certificado de servidor emitido por ela | Fluxo documentado pela Apple para certificados instalados manualmente; exige SAN, `serverAuth` e validade de até 825 dias 🟡 | escolhida (D-03) |
| WebRTC com canal de dados | Cifrado por padrão, mas precisa de sinalização por outro canal e de muito mais código | descartada |

Para não guardar no Mac uma chave capaz de emitir certificados que o iPhone aceitaria para qualquer site, a chave da autoridade é apagada ao fim do script e a autoridade leva restrição de nome a `.local`. Se o iOS ignorar a restrição, a proteção restante é o descarte da chave. 🟡

## 4. Injeção e rótulos

- **Código de tecla em vez de Unicode.** O `KeyboardInjector.type` digita por `keyboardSetUnicodeString` com código 0 (`injecao-de-eventos` RN-IN-12), o que ignora a fonte de entrada. Para ⌘C, teclas mortas e Ç, a tecla precisa sair pelo código físico, como `postKey` já faz para os acordes (`Sources/JoystickAIPoC/Injection/KeyboardInjector.swift`). 🟢
- **Rótulos.** O Teclado de Acessibilidade calcula os rótulos com a fonte de entrada ativa; o equivalente programático é `UCKeyTranslate` sobre o `kTISPropertyUnicodeKeyLayoutData` da fonte atual, com o estado de tecla morta para identificar ´, ~, ^ e similares. 🟡
- **Repetição.** `NSEvent.keyRepeatDelay` e `NSEvent.keyRepeatInterval` expõem as preferências de repetição do usuário. 🟡
- **Onde fica o estado dos modificadores.** Na página, o Mac não saberia o que soltar quando o canal cai; no núcleo, a soltura é determinística e testável (D-08). 🟢

## 5. Sondas do PM-0

| ID | Pergunta | Método | Aprovação |
|----|----------|--------|-----------|
| P-01 | O iPhone confia na autoridade local para TLS? | Rodar o script, enviar o certificado por AirDrop, instalar o perfil, ligar a confiança total, abrir `https://<host>.local:47810` e conectar ao canal | Página e canal sem aviso de conexão insegura, no Safari e como aplicativo da Tela de Início |
| P-02 | O app abre os listeners com a identidade do chaveiro sem diálogo recorrente, e o firewall aceita? | Ligar o recurso em duas aberturas seguidas do app instalado | No máximo um diálogo na primeira vez, registrado no roteiro |
| P-03 | A tecla por código respeita o ABNT2? | Com ABNT2 ativo, enviar os códigos de Ç, ´ seguido de A, e ⇧ com 2 | Chegam "ç", "á" e "@" no TextEdit |
| P-04 | Caps Lock injetado alterna o estado? | `flagsChanged` do código 57 e depois uma letra | Letra maiúscula e a luz do sistema coerentes; senão, D-17 tira a tecla |
| P-05 | Latência e vigia | 200 teclas medidas pelo `ts_ns` de chegada contra o carimbo da página, com o iPhone preso ao controle no sofá | p95 abaixo de 150 ms e nenhum `remote.watchdog` durante digitação contínua |
| P-06 | Multitoque do Safari | Segurar ⌘ e tocar C; tocar duas letras quase juntas | Os dois toques chegam, sem `touchcancel` indevido |
| P-07 | Geometria física deste Mac | Registrar `KBGetLayoutType(LMGetKbdType())` e comparar com o teclado do MacBook | Página desenha ANSI ou ISO conforme o registrado |

## 6. Fontes

- `Sources/JoystickAIPoC/Injection/KeyboardInjector.swift`, `Sources/JoystickAIPoC/App/InjectionGate.swift`, `Sources/JoystickCore/Shortcuts/KeyRepeat.swift`, `scripts/create-local-signing-identity.sh`, `scripts/build-app.sh`
- `_reversa_sdd/injecao-de-eventos/requirements.md`, `_reversa_sdd/permissions.md`, `_reversa_sdd/addenda/006-teclado-virtual.md`
- Apple, "Trust manually installed certificate profiles in iOS, iPadOS, and visionOS" (support.apple.com/102390) 🟡
- Apple, "Requirements for trusted certificates in iOS 13 and macOS 10.15" (support.apple.com/103769) 🟡
- Apple Developer, `NWProtocolWebSocket`, `NWListener`, `CIQRCodeGenerator`, `UCKeyTranslate`, `NSSharingService` 🟡
- RFC 6455 (WebSocket) e RFC 1918 (faixas privadas IPv4); RFC 4193 (IPv6 ULA)
