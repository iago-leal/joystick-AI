# Investigation: Controle DualShock 4 ao lado do DualSense e do Ipega

> Identificador: `012-controle-dualshock-4`
> Data: `2026-09-22`
> Roadmap: `_reversa_forward/012-controle-dualshock-4/roadmap.md`

## 1. Pergunta de fundo

Como fazer o app aceitar um controle que se apresenta ao macOS como DualShock 4, seja o da Sony ou um clone como o GameSir G8+ no modo PlayStation, com a experiência do DualSense, sem mudar o comportamento, a configuração nem a figura do DualSense e do Ipega, e sabendo que o único aparelho disponível para teste é o clone, sem touchpad físico e só por Bluetooth?

## 2. Estado de partida, observado em 2026-09-22

- **Sistema:** macOS 26 no uso do usuário; mínimo declarado do app, 13 (`_reversa_sdd/inventory.md`).
- **Bluetooth e IORegistry** (sonda só de leitura): o controle novo aparece como "DUALSHOCK 4 Wireless Controller", fabricante 0x054C (Sony), produto 0x05C4 (DualShock 4 de primeira geração, CUH-ZCT1), transporte Bluetooth. Um segundo dispositivo, "GameSir-G8+", fabricante 0x3537 e produto 0x1108, casado por Bluetooth Low Energy com endereço quase idêntico, declara-se digitalizador e não chega à interface de controles. O usuário confirmou depois que o aparelho é o GameSir G8+ no modo PlayStation.
- **Interface de controles:** o controle recebe o perfil DualShock (categoria "DualShock 4"), com 34 elementos: quatro botões frontais, ombros, gatilhos, cliques dos analógicos, PS, Share, Options, direcional e touchpad com dois dedos e clique. A bateria é informada: 55 %, descarregando.
- **Log** (`~/Library/Logs/joystick-ai/poc-20260921-193627.jsonl`, 13:24): uma linha `controller.ignored` com `name: "DUALSHOCK 4 Wireless Controller"`, `productCategory: "DualShock 4"` e `reason: "unsupported_model"`, com o app em execução.
- **Classificação hoje** (`ControllerModel.classify`): `dualSense` pelo perfil `GCDualSenseGamepad`; `ipega` pela categoria "Switch Pro Controller" mais o par 0x057E/0x2009 no IORegistry; `nil` no resto. `ControllerReader.connect` passa a lista de pares do IORegistry só quando o perfil não é DualSense.
- **Leitura por modelo:** `ButtonReader.digitalButtons` tem um `switch` de duas entradas que decide o botão específico do modelo (`touchpadClick` do `GCDualSenseGamepad` ou `share` do perfil físico). `AxisTouchReader.attach` exige `model == .dualSense` e `GCDualSenseGamepad` para ligar analógicos e touchpad; os analógicos do Ipega vêm do HID. `ControllerDiagnostics` pede a supressão de gestos no `buttonHome` de qualquer modelo.
- **Leitor HID:** `ExtendedReportActivator` casa todos os pares de `ControllerModel.allCases`, escolhe o intérprete pelo modelo do dispositivo emissor (`DualSenseReport` ou `SwitchProReport`), guarda o estado do PS por dispositivo e pede o relatório de recurso `0x05` só para o DualSense por Bluetooth. `DualSenseReport.homeButton` conhece três formas: `0x01` com 64 bytes (PS no byte 10), `0x31` com 12 ou mais (byte 11) e `0x01` com 10 bytes (byte 7).
- **Transporte:** `TransportResolver.resolve(for:)` consulta o IORegistry pelos pares do modelo; com candidatos de transportes diferentes, `unknown`.
- **Carga:** `ControllerReader.charge(of:)` lê `controller.battery` de qualquer `GCController`; `ChargePoller` relê na main thread a cada 60 s com interface aberta e a cada mudança de ativo; `ChargeDisplay.decide` não conhece modelo. Código da 011, commitado, com o adendo ainda não gerado.
- **Figura:** `FigureState.controller` envia o `rawValue` do modelo; `figure.js` conhece `dualSense` e `ipega` e trata valor desconhecido como `dualSense`; `figure.css` oculta o Share com `dualSense` e marca o touchpad como ausente com `ipega`.
- **Log e ferramentas:** `LogAnalysis.buttonCoverage` espera `ControllerModel.buttons` do último `controller.connected`; `poc-tools buttons` imprime o modelo e os 18.
- **Testes:** 449 em 45 suítes depois da 011 (`_reversa_forward/011-bateria-e-cursor-no-menu/`).

## 3. Pesquisa de fundo

### 3.1 O DualShock 4 na interface de controles do sistema

A Apple oferece o perfil `GCDualShockGamepad` desde o macOS 11 e o iOS 14, abaixo do mínimo do projeto, como subclasse de `GCExtendedGamepad` com `touchpadButton`, `touchpadPrimary` e `touchpadSecondary`, o mesmo desenho do `GCDualSenseGamepad` que o app já usa. 🟢 A categoria de produto é "DualShock 4", conferida no log. No DualSense, o botão Create chega por `buttonOptions` e o Options por `buttonMenu` (RN-EC-16, confirmado na P-05 da 001); a documentação da Apple dá a `buttonOptions` o papel do botão à esquerda do touchpad nos controles PlayStation, o que no DualShock 4 é o Share. 🟡 A P-01 confirma no aparelho.

Fonte: documentação de `GCDualShockGamepad` e `GCExtendedGamepad` (developer.apple.com/documentation/gamecontroller).

### 3.2 Relatórios HID do DualShock 4

A disposição dos relatórios é conhecida da engenharia reversa da comunidade e dos drivers de código aberto (Linux `hid-sony` e `hid-playstation`, DS4Windows, psdevwiki). 🟡 até a P-02.

| Transporte | Relatório | Tamanho | Bloco comum começa em | PS | Clique do touchpad |
|------------|-----------|---------|------------------------|----|---------------------|
| USB | `0x01` | 64 bytes | byte 1 | byte 7, bit 0 | byte 7, bit 1 |
| Bluetooth simplificado | `0x01` | 10 bytes | byte 1 | byte 7, bit 0 | byte 7, bit 1 |
| Bluetooth completo | `0x11` | 78 bytes | byte 3 | byte 9, bit 0 | byte 9, bit 1 |

O bloco comum é: analógicos (4 bytes), botões frontais e direcional (1), ombros, gatilhos, Share, Options e cliques dos analógicos (1), PS, clique do touchpad e contador (1), gatilhos analógicos (2), depois carimbo de tempo, bateria, sensores de movimento e touchpad. O DualSense tem o mesmo desenho com o bloco de botões três bytes adiante, por isso o PS fica no byte 10 por USB e no 11 por Bluetooth; no DualShock 4, fica no 7 e no 9.

Por Bluetooth, o DualShock 4 começa no relatório simplificado `0x01`, de 10 bytes, sem touchpad nem sensores, e passa ao `0x11` quando o host lê um relatório de recurso de calibração: `0x02` por USB e `0x05` por Bluetooth, conforme `hid-sony`. O mesmo mecanismo, com o mesmo identificador `0x05`, é o que a 001 descobriu para o DualSense (RN-EC-13) e que `ExtendedReportActivator.activate` executa. O relatório `0x05` do DualShock 4 tem 41 bytes; o buffer de 64 bytes do app o comporta.

Fontes: `drivers/hid/hid-sony.c` e `drivers/hid/hid-playstation.c` do kernel Linux (funções de calibração e comentários sobre os relatórios 1 e 17); psdevwiki.com/ps4, páginas "DS4-USB" e "DS4-BT"; DS4Windows (github.com/Ryochan7/DS4Windows), `DS4Device.cs`.

### 3.3 Identidades Sony do DualShock 4

| Produto | Aparelho | Decisão |
|---------|----------|---------|
| 0x05C4 | DualShock 4 de primeira geração (CUH-ZCT1); é a identidade que os clones costumam emular, inclusive o GameSir G8+ | aceito (RN-01) |
| 0x09CC | DualShock 4 de segunda geração (CUH-ZCT2) | aceito (RN-01) |
| 0x0BA0 | Adaptador USB sem fio oficial; apresenta-se por USB e envia o relatório `0x01` de 64 bytes quando há controle casado | fora, sem sonda (D-01) |

Fontes: psdevwiki.com/ps4/DS4-USB; tabela de identidades de `hid-sony.c`.

### 3.4 O GameSir G8+ no modo PlayStation

O GameSir G8+ é um controle para telefone com modos alternáveis (Xbox, Switch, PlayStation, entre outros); no modo PlayStation, emula um DualShock 4 de primeira geração por Bluetooth clássico e mantém um segundo canal Bluetooth Low Energy próprio, para o aplicativo do fabricante, que o macOS vê como digitalizador. O aparelho não tem touchpad físico; o perfil declarado inclui os elementos do touchpad porque a identidade emulada os tem. 🟢 (sonda e confirmação do usuário). O que o clone faz com o relatório de recurso `0x05` e se põe o bit do PS no relatório bruto não está documentado; só a P-02 responde. 🟡

### 3.5 Resultados das sondas do PM-0 (2026-09-22)

Sonda `sondas/probe-ds4.swift`, log íntegro em `sondas/probe-ds4-2026-09-22.log`; tabela completa no `onboarding.md` §1. O que muda no que estava acima:

- **§3.1 confirmado.** Perfil `GCDualShockGamepad`; o Share físico chega por `buttonOptions` e o Options por `buttonMenu`, como no DualSense. O PS **não** chega pela interface de controles (RI-08 vale também aqui). O dicionário `touchpads` vem vazio; `touchpadPrimary` e `touchpadSecondary` existem e, no SDK, são opcionais no perfil DualShock.
- **§3.2 confirmado no `0x11`, e com uma diferença de premissa.** Por Bluetooth o sistema já entrega o relatório completo `0x11` de 78 bytes desde a conexão, sem o pedido do recurso `0x05`; o relatório simplificado `0x01` nunca apareceu. O PS é o bit 0 do byte 9, o clique do touchpad o bit 1, o contador os bits 2 a 7; direcional e faces no byte 7, ombros, gatilhos, Share, Options e cliques dos analógicos no byte 8, gatilhos analógicos nos bytes 10 e 11, sensores nos bytes 13 a 26, toque a partir do byte 35, CRC nos bytes 74 a 77. O pedido do recurso `0x05` respondeu `ok` com 41 bytes de calibração e não mudou o formato. O índice do PS no `0x01` (byte 7) permanece da literatura. 🟢 no `0x11`; 🟡 no `0x01`.
- **§3.4 corrigido.** O GameSir G8+ **tem** tecla para o clique do touchpad, entregue como `touchpadButton`, e acompanha cada clique de um ponto de toque fixo (127, 173) na superfície primária, que entra e sai com o clique. Não é ruído: é o firmware simulando um dedo no pad. No app, `TouchpadTracker.isAxisSplit` descarta a sequência (x, 0) → (x, y) → (0, y) → (0, 0) desse toque fixo, e o cursor não se move; sobra um par de eventos `input.touch` por clique no log.
- **Bateria e transporte:** 45 % descarregando pela propriedade `battery`; `Transport = "Bluetooth"`, `maxInputReport = 547`, `maxFeatureReport = 64`.

## 4. Alternativas avaliadas

### 4.1 Como reconhecer o DualShock 4

| Alternativa | Prós | Contras | Veredito |
|-------------|------|---------|----------|
| Perfil `GCDualShockGamepad` mais par Sony 0x05C4 ou 0x09CC no IORegistry | Segue RN-01 ao pé da letra e a técnica da 007; recusa limpa (`unsupported_model`) para identidades não sondadas, como o adaptador | Depende de o IORegistry já listar o dispositivo na notificação de conexão (na 007 e na sonda de hoje, lista) | **Escolhida** (D-01) |
| Só o perfil, como o DualSense | Sem dependência do IORegistry | Um DualShock 4 pelo adaptador seria aceito com transporte `unknown` e sem PS, um estado degradado sem aviso | Descartada |
| Categoria "DualShock 4" mais par | Sem depender da classe do perfil | A classe é a API pública e estável; a categoria é texto | Descartada |
| Incluir 0x0BA0 | Um controle pelo adaptador funcionaria, se o sistema o suportar | Ninguém pode observar o relatório do adaptador; contraria o rito de sonda antes do código | Adiada (premissa no `roadmap.md` §4) |

### 4.2 Como ler o PS

| Alternativa | Prós | Contras | Veredito |
|-------------|------|---------|----------|
| Intérprete próprio `DualShock4Report`, no leitor HID existente | Um gerenciador só; nomes claros para cada formato; mesma entrega e deduplicação | Mais um arquivo no núcleo, com testes | **Escolhida** (D-04) |
| Parametrizar `DualSenseReport` com deslocamentos | Um arquivo | Três parâmetros para dois formatos ficam menos legíveis que dois tipos | Descartada |
| Só a interface de controles | Nenhum código HID | RI-08 mostra que o sistema retém o PS no DualSense; supor o contrário sem sonda é imprudente; se a P-01 mostrar entrega, o intérprete continua correto e a deduplicação descarta a repetição | Descartada |

### 4.3 Como ligar analógicos e touchpad

| Alternativa | Prós | Contras | Veredito |
|-------------|------|---------|----------|
| `switch` por modelo que devolve as superfícies do touchpad de `GCDualSenseGamepad` ou `GCDualShockGamepad`, e analógicos do `GCExtendedGamepad` para os dois | Duas linhas; as duas fontes de fase (RN-EC-11) continuam iguais | Nenhum | **Escolhida** (D-03) |
| Protocolo do app sobre os dois perfis | Elegante | Código a mais para o mesmo `switch` | Descartada |
| Touchpad só no DualSense | Nada muda | Um DualShock 4 da Sony perderia o touchpad; RN-04 o exige | Descartada |

### 4.4 Como mostrar a figura

| Alternativa | Prós | Contras | Veredito |
|-------------|------|---------|----------|
| `controller: "dualShock4"` explícito na ponte, com regra de estilo estendida | Contrato verdadeiro; teste de recurso fixa a regra | Toca `figure.js` e `figure.css` em uma linha cada | **Escolhida** (D-08) |
| Mapear para `"dualSense"` em `FigureState` | Nenhuma mudança na página | O contrato diz que `controller` é o `rawValue`; a rastreabilidade se perde | Descartada |
| Confiar no padrão da página | Nenhuma mudança | Intenção escondida num *fallback* | Descartada |

### 4.5 Portões

| Alternativa | Prós | Contras | Veredito |
|-------------|------|---------|----------|
| PM-0 com sondas antes do código, PM-1 mínimo depois | Resolve as lacunas do `requirements.md` §10 onde elas vivem, no relatório bruto; reduz o portão posterior ao que o usuário pediu | Uma sessão a mais com o aparelho | **Escolhida** (D-11) |
| Só PM-1 | Como na 007 | As sondas da 007 já estavam feitas; aqui não estão, e D-04 e D-05 dependem delas | Descartada |

## 5. Padrões aplicáveis

- **Tabela por modelo em vez de classe por modelo** (007 D-03): o leitor continua um só, e a variação fica num `switch` pequeno por modelo.
- **Intérprete puro por formato** (001 `DualSenseReport`, 007 `SwitchProReport`): função sem estado que recebe identificador e bytes e devolve o bit, testável sem hardware.
- **Sonda antes do código** (001, 007, 011 D-12): comportamento do sistema que a literatura descreve mas o aparelho ainda não mostrou vira sonda registrada no `actions.md`.
- **Valor explícito no contrato, sem *fallback* silencioso** (004 D-07, 007 D-08): a página só aplica o que recebe, e o que recebe é verdadeiro.

## 6. Fontes externas

- Apple, GameController: `GCDualShockGamepad`, `GCDualSenseGamepad`, `GCExtendedGamepad`, `GCDeviceBattery` (developer.apple.com/documentation/gamecontroller).
- Kernel Linux: `drivers/hid/hid-sony.c` (calibração do DualShock 4 e comentário sobre os relatórios 1 e 17), `drivers/hid/hid-playstation.c` (DualSense, para comparação).
- psdevwiki.com/ps4: "DS4-USB", "DS4-BT".
- DS4Windows: github.com/Ryochan7/DS4Windows.
- Precedentes internos: `_reversa_forward/007-controle-ipega/investigation.md`, `_reversa_forward/001-poc-entrada-ponteiro/validation-report.md` (P-02, P-07), `_reversa_forward/011-bateria-e-cursor-no-menu/roadmap.md` (D-01 a D-05).
