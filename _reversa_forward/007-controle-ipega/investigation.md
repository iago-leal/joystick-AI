# Investigation: Controle Ipega ao lado do DualSense

> Identificador: `007-controle-ipega`
> Data: `2026-09-19`
> Roadmap: `_reversa_forward/007-controle-ipega/roadmap.md`

## 1. Pergunta de fundo

Como fazer o app aceitar o Ipega, um controle que se apresenta ao macOS como Switch Pro Controller, com a mesma experiência do DualSense, sem mudar o comportamento nem a configuração do DualSense?

## 2. Estado de partida, observado em 2026-09-19

- **Sistema:** macOS 27.0.
- **IORegistry** (`ioreg -r -c IOHIDDevice -l`, só leitura): o Ipega aparece como `Product = "Pro Controller"`, `Manufacturer = "Nintendo Co., Ltd."`, `VendorID = 1406` (0x057E), `ProductID = 8201` (0x2009), `Transport = "USB"`, `SerialNumber = "Shanwan202107142050"`, `MaxInputReportSize = 64`. Shanwan é o fabricante que produz controles Ipega. Um dispositivo `GamePad-1` com a identificação do controle de Xbox 360 (0x045E / 0x028E), sem transporte, também aparece; não é tocado pela feature.
- **Interface de controles** (programa de sonda com `GCController.controllers()`): o Ipega é `vendorName = "Pro Controller"`, `productCategory = "Switch Pro Controller"`, com `extendedGamepad` da classe privada `_GCNintendoSwitchGamepad`. Botões do perfil: A, B, X, Y, Home, Menu, Options, Share, ombros, gatilhos, cliques dos analógicos, direcional; nenhum touchpad.
- **Primeira sonda de botões** (interface de controles e relatório HID lidos ao mesmo tempo, 45 s): 17 botões chegam pelos dois caminhos. O Home chega **só** pelo HID: relatório `0x30`, byte 4, bit `0x10`. Nenhum bit fora dos já conhecidos mudou; Android, iOS, Turbo e Clear não produzem entrada. ZL e ZR saltam de 0 para 1.
- **Segunda sonda** (baixo, direita, esquerda e cima, nessa ordem): chegaram `Button A`, `Button B`, `Button X`, `Button Y`. A correspondência por posição coincide com a tabela do DualSense (RN-EC-16), sem inversão. No HID, os bits do byte 3 seguem o formato Nintendo (A = 0x08, B = 0x04, X = 0x02, Y = 0x01): o firmware do Ipega põe o bit "A" no botão de baixo.
- **Leitura do controle hoje:** `ControllerReader.connect` exige `GCDualSenseGamepad` e ignora o resto com `not_dualsense`; `ButtonReader`, `AxisTouchReader` e `ControllerDiagnostics` recebem esse tipo. `ActiveControllerRegistry.connect` recebe `isDualSense` e devolve `.ignored` quando falso.
- **Leitor HID:** `ExtendedReportActivator` casa só Sony (0x054C) e os produtos 0x0CE6 e 0x0DF2, lê o PS por `DualSenseReport.homeButton` e guarda um único `homePressed`.
- **Identificadores de botão:** `ButtonID` tem 18 casos; a ordem define as camadas do editor e a ordem das solturas sintéticas. `ShortcutConfig.pointerButtons` = R1, R2, touchpad. `ShortcutDefaults.optionsLayer` grava "nenhuma" em todo botão que não é de apontamento nem modificador.
- **Figura:** `FigureState` gera sempre 18 itens; `figure.js` ignora identificadores que não conhece e não sabe esconder botões. `EditorViewModel` não sabe qual controle está ativo; `InputRouter` descarta `controllerConnected`.
- **Log e ferramentas:** `LogAnalysis.buttonCoverage` e `poc-tools buttons` conferem `ButtonID.allCases` e escrevem "de 18".
- **Testes:** 280 após a feature 006 (`_reversa_sdd/addenda/006-teclado-virtual.md`).

## 3. Alternativas avaliadas

### 3.1 Como reconhecer o Ipega

| Alternativa | Prós | Contras | Veredito |
|-------------|------|---------|----------|
| Categoria "Switch Pro Controller" mais par 0x057E / 0x2009 no IORegistry | Casa a resposta 1a; sem permissão; técnica já usada por `TransportResolver` | Não distingue o Switch Pro original, que tem a mesma identificação | **Escolhida** (D-01) |
| Só a categoria | Mais simples | Aceitaria qualquer controle que o sistema classifique assim (resposta 1b, descartada) | Descartada |
| Número de série `Shanwan…` | Distinguiria o original | Campo não documentado, variável por lote; exige ler propriedades do dispositivo | Descartada |
| Qualquer `extendedGamepad` | Genérico | Resposta 1c, descartada; mapeamentos sem teste | Descartada |

### 3.2 Como ler o Home

| Alternativa | Prós | Contras | Veredito |
|-------------|------|---------|----------|
| Estender o leitor HID do PS | Um gerenciador só; mesma entrega e deduplicação | O leitor passa a interpretar dois formatos | **Escolhida** (D-04) |
| Leitor HID separado | Isolamento | Dois `IOHIDManager` para o mesmo papel | Descartada |
| Esperar o Home pela interface de controles | Nenhum código HID | A sonda mostrou que ele não chega | Descartada |

### 3.3 Como representar o Share

| Alternativa | Prós | Contras | Veredito |
|-------------|------|---------|----------|
| `ButtonID.share`, no fim | Ordem dos 18 preservada; papel de botão livre sem código novo | Figura e ferramentas passam a conhecer 19 identificadores | **Escolhida** (D-02) |
| Reaproveitar `touchpadClick` | Nenhum identificador novo | Seria clique fixo, contra RN-05 | Descartada |

### 3.4 Como a figura sabe o controle ativo

| Alternativa | Prós | Contras | Veredito |
|-------------|------|---------|----------|
| Campo `controller` em `FigureState`, decidido no núcleo, aplicado pela página | Testável; segue o desenho da 004 (a página só apresenta) | Mais um canal entre leitura e editor | **Escolhida** (D-08) |
| Página decide pelo nome do controle | Menos código Swift | Lógica fora do núcleo, sem teste | Descartada |

## 4. Fontes externas

- Documentação da Apple sobre `GCController`, `GCExtendedGamepad`, `GCInputButtonShare` e `productCategory`; `GCInputButtonShare` existe desde o macOS 12, abaixo do mínimo declarado do app (13). 🟡
- Formato do relatório `0x30` do Switch Pro Controller, documentado pela comunidade de engenharia reversa (projeto dekuNukem, "Nintendo_Switch_Reverse_Engineering"): byte 3 com Y, X, B, A, R, ZR; byte 4 com −, +, R3, L3, Home, Captura; byte 5 com o direcional, L e ZL. As duas sondas conferiram cada bit usado pela feature. 🟢

## 5. Padrões aplicáveis

- **Casca imperativa, núcleo funcional:** classificação, leitura do bit e estado da figura como funções puras, testadas sem hardware.
- **Tabela por modelo:** um único leitor com a tabela escolhida pelo modelo, em vez de uma classe por controle.
- **Crescimento aditivo de contratos:** campo novo no log e na figura, chave nova na configuração, sem renomear nem remover o que existe (exceto o valor `not_dualsense`, sem consumidor).
