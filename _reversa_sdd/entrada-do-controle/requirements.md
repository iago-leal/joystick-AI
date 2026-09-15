# Entrada do controle (controller-input)

> Unit do módulo `controller-input` · Gerado pelo Redator em 2026-09-15 · Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA

## Visão Geral

Descobre controles DualSense conectados por USB ou Bluetooth, elege um único controle ativo e converte seus 18 botões, dois analógicos e dois dedos do touchpad em `InputEvent` normalizados, entregues à fila `input` mesmo com outro aplicativo em primeiro plano. 🟢

## Responsabilidades

- Receber o controle em segundo plano pelo `GameController` e adotar os já conectados na abertura. 🟢
- Aceitar só DualSense (incluindo Edge) e ignorar outros modelos. 🟢
- Manter a fila de controles e o conjunto de botões pressionados do ativo. 🟢
- Normalizar analógicos (zona morta), gatilhos (limiar) e toque (limite a ±1). 🟢
- Ler o botão PS do relatório HID bruto e ativar o modo estendido por Bluetooth. 🟢
- Resolver o tipo de conexão pelo IORegistry. 🟢
- Soltar sinteticamente os botões na desconexão do ativo. 🟢
- Pedir ao macOS que o PS não dispare gestos do sistema. 🟢

## Regras de Negócio

- RN-EC-01: Existe no máximo um controle ativo: o primeiro DualSense registrado. Os seguintes ficam em fila na ordem de chegada; o ativo tem posição 0. 🟢
- RN-EC-02: Só o controle ativo produz eventos; botões, analógicos e toque de controles em fila são descartados. 🟢
- RN-EC-03: Controle cujo `extendedGamepad` não é `GCDualSenseGamepad` é ignorado e registrado uma vez com `reason: not_dualsense`; sua desconexão é silenciosa. 🟢
- RN-EC-04: O mesmo objeto de controle conectado duas vezes (enumeração e notificação) é registrado uma única vez. 🟢
- RN-EC-05: `atStartup` é verdadeiro quando o controle veio da enumeração inicial ou chegou em menos de 2 s desde a criação do `AppDelegate`. 🟢
- RN-EC-06: Um botão só gera evento quando seu estado muda no conjunto de pressionados do ativo; isso deduplica o PS que chega por duas vias. 🟢
- RN-EC-07: Na desconexão do ativo, cada botão pressionado recebe `buttonUp` com `synthetic: true`, em ordem de `ButtonID`, seguido de `controllerDisconnected`; o próximo da fila passa a ativo com o conjunto de pressionados vazio. 🟢
- RN-EC-08: Zona morta por eixo: o valor é limitado a [−1, 1] e vale 0 se `|v| < pointer.deadzone` (padrão 0,12); não há reescala do restante. 🟢
- RN-EC-09: L2 e R2 contam como pressionados com valor ≥ 0,5 e soltos abaixo, sem histerese. 🟢
- RN-EC-10: Amostra normalizada de analógico igual à anterior do mesmo analógico não é entregue. 🟢
- RN-EC-11: A fase do toque vem de `touchDown/Moved/Up` quando `physicalInputProfile.touchpads` não é vazio (`touchState`); senão, é inferida pela transição de e para (0, 0) (`zero_transition`). No DualSense, o dicionário vem vazio. 🟢
- RN-EC-12: O PS é lido no relatório HID: bit 0 do byte 10 no relatório `0x01` com ≥ 64 bytes (USB), do byte 11 no `0x31` com ≥ 12 bytes (Bluetooth estendido) e do byte 7 no `0x01` com exatamente 10 bytes (Bluetooth simplificado); só mudanças são entregues, ao controle ativo. 🟢
- RN-EC-13: Por Bluetooth, a cada DualSense casado, o app lê o relatório de recurso `0x05` para tirar o controle do modo simplificado. 🟢
- RN-EC-14: O tipo de conexão é `usb` ou `bluetooth` só se todos os DualSense do IORegistry tiverem o mesmo transporte; caso contrário, `unknown`. 🟢
- RN-EC-15: Valores de eixo e posições do toque nunca vão ao log. 🟢
- RN-EC-16: Mapeamento físico: `buttonA` ✕ `cross`, `buttonB` ○ `circle`, `buttonX` □ `square`, `buttonY` △ `triangle`, ombros `l1`/`r1`, gatilhos `l2`/`r2`, cliques dos analógicos `l3`/`r3`, `buttonMenu` → `options`, `buttonOptions` → `create`, `buttonHome` → `ps`, `touchpadButton` → `touchpadClick`, `dpad.*` → `dpadUp/Down/Left/Right`. Options e Create foram confirmados no hardware (P-05). 🟢
- RN-EC-17: O PS lido pelo HID é atribuído ao controle ativo, venha de qual DualSense vier. 🟢 Exceção aceita a RN-EC-02 com dois controles (respondida em 2026-09-15, `questions.md` Pergunta 2).

## Requisitos Funcionais

| ID | Requisito | Prioridade | Critério de Aceite |
|----|-----------|-----------|-------------------|
| RF-EC-01 | Receber entradas com outro app em primeiro plano | Must | Com o Terminal em foco, `input.button` registra os 18 botões |
| RF-EC-02 | Adotar o controle já conectado na abertura | Must | Abrir o app com o controle ligado gera `controller.connected { atStartup: true }` |
| RF-EC-03 | Aplicar RN-EC-01, RN-EC-02 e RN-EC-07 | Must | Com dois DualSense, só o primeiro move o cursor; desligado este, o segundo assume |
| RF-EC-04 | Ignorar controles de outros modelos | Must | Um controle Xbox gera `controller.ignored` e nenhum evento |
| RF-EC-05 | Entregar os 18 botões com o mapeamento RN-EC-16 | Must | `poc-tools buttons` lista 18 de 18 |
| RF-EC-06 | Entregar analógicos com zona morta e sem repetições | Must | Analógico em repouso não gera entregas |
| RF-EC-07 | Entregar toque com fases e posição limitada | Must | Pousar e levantar o dedo gera `input.touch` `began` e `ended` |
| RF-EC-08 | Ler o PS pelo HID e ativar o touchpad por Bluetooth | Must | Por Bluetooth, `controller.extended_report { result: ok }` e toque funcional |
| RF-EC-09 | Informar o tipo de conexão | Should | `controller.connected.connection` é `usb` ou `bluetooth` com um só controle |
| RF-EC-10 | Pedir supressão de gestos no PS e listar elementos em `--debug` | Could | `controller.gesture_suppression` sempre; `controller.elements` só com `--debug` |

## Requisitos Não Funcionais

| Tipo | Requisito inferido | Evidência no código | Confiança |
|------|--------------------|---------------------|-----------|
| Performance | Handlers do framework executam direto na fila serial `input` (`handlerQueue`), sem salto de fila | `ControllerReader.swift:83` | 🟢 |
| Performance | Processamento p95 de 0,110 ms medido | `validation-report.md` 001:30 | 🟢 |
| Privacidade | Sem valores de eixo nem posições no log | `AxisTouchReader.swift:5-7` | 🟢 |
| Segurança | Leitura do IORegistry sem abrir o dispositivo; abertura HID só para PS e relatório `0x05` | `TransportResolver.swift:6-9`, `ExtendedReportActivator.swift:5-10` | 🟢 |
| Compatibilidade | Funciona sem Monitoramento de Entrada, só com Acessibilidade | P-04, `validation-report.md` 001:123 | 🟢 |

## Critérios de Aceitação

```gherkin
Dado o app aberto sem controle
Quando um DualSense é ligado por Bluetooth
Então o log registra controller.connected com connection bluetooth e atStartup false
E controller.extended_report com result ok
E controller.touch_source com source zero_transition

Dado um DualSense ativo e outro em fila
Quando o controle em fila pressiona ✕
Então nenhum InputEvent é entregue

Dado R2 e ✕ pressionados no controle ativo
Quando o controle desconecta
Então são entregues buttonUp sintéticos de cross e depois r2, seguidos de controllerDisconnected
E o controle em fila passa a ser o ativo sem evento de log próprio

Dado o analógico esquerdo em (0,05; 0,5) com deadzone 0,12
Quando a amostra chega
Então é entregue axis com x 0 e y 0,5

Dado L2 em 0,49
Quando o valor sobe para 0,5
Então é entregue buttonDown de l2 com value 0,5

Dado um controle de outro modelo
Quando conecta
Então controller.ignored é registrado e nenhum leitor é ligado

Dado o PS pressionado por Bluetooth e o GameController também entregando buttonHome
Quando as duas vias chegam
Então só um buttonDown de ps é entregue
```

## Prioridade (MoSCoW)

| Requisito | MoSCoW | Justificativa |
|-----------|--------|---------------|
| Leitura em segundo plano, 18 botões, analógicos, toque | Must | Toda funcionalidade depende |
| Controle ativo e soltura sintética | Must | Evita entradas presas e conflito |
| PS por HID e modo estendido | Must | Sem eles, paleta e touchpad por Bluetooth não funcionam |
| Transporte | Should | Só informativo |
| Supressão de gestos e lista de elementos | Could | Diagnóstico |

## Rastreabilidade de Código

| Arquivo | Função / Classe | Cobertura |
|---------|-----------------|-----------|
| `Sources/JoystickAIPoC/Controller/ControllerReader.swift` | `ControllerReader` | 🟢 |
| `Sources/JoystickAIPoC/Controller/ButtonReader.swift` | `ButtonReader` | 🟢 |
| `Sources/JoystickAIPoC/Controller/AxisTouchReader.swift` | `AxisTouchReader` | 🟢 |
| `Sources/JoystickAIPoC/Controller/ExtendedReportActivator.swift` | `ExtendedReportActivator` | 🟢 |
| `Sources/JoystickAIPoC/Controller/TransportResolver.swift` | `TransportResolver` | 🟢 |
| `Sources/JoystickAIPoC/Controller/ControllerDiagnostics.swift` | `ControllerDiagnostics` | 🟢 |
| `Sources/JoystickAIPoC/Controller/InputSink.swift` | `InputSink`, `LoggingInputSink`, `InputContext` | 🟢 |
| `Sources/JoystickCore/Input/ActiveControllerRegistry.swift` | `ActiveControllerRegistry` | 🟢 |
| `Sources/JoystickCore/Input/DualSenseReport.swift` | `DualSenseReport` | 🟢 |
| `Sources/JoystickCore/Input/InputEvent.swift` | `ButtonID`, `InputEvent`, `ControllerInfo` | 🟢 |
| `Sources/JoystickCore/Input/Normalization.swift` | `Normalization`, `TriggerTracker` | 🟢 |
| `Sources/JoystickCore/Input/StartupAdoption.swift` | `StartupAdoption` | 🟢 |
| `Sources/JoystickCore/Pointer/TouchpadTracker.swift` | `ZeroTransitionPhaseInference` | 🟢 |
