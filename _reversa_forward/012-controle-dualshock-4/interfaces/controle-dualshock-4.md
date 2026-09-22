# Interface: controle DualShock 4 (interface de controles do sistema e relatório HID)

> Feature: `012-controle-dualshock-4`
> Tipo: dispositivo de entrada, leitura; a única escrita é o pedido de leitura do relatório de recurso `0x05`, que o app já faz no DualSense
> Origem: `requirements.md` RN-01, RN-03, RN-04, RN-05, RN-08, RN-11; `roadmap.md` D-01 a D-06
> Integrações do legado afetadas: I-01 (`GameController`) e I-02 (IOKit HID), `_reversa_sdd/architecture.md#4. Integrações externas`
> Confidência: 🟢 na identificação e na interface de controles (sonda e log de 2026-09-22, por Bluetooth); 🟡 no relatório HID (literatura; a P-02 do PM-0 confirma)

## 1. Identificação

| Propriedade | Valor observado | Uso |
|-------------|-----------------|-----|
| `GCController.productCategory` | `"DualShock 4"` | Só o campo `productCategory` do log; a classificação usa a classe do perfil |
| Classe de `extendedGamepad` | `GCDualShockGamepad` (esperado; P-01 confirma) | Primeira condição de `ControllerModel.classify` (`SystemProfile.dualShock`) |
| `GCController.vendorName` | `"DUALSHOCK 4 Wireless Controller"` | Só o campo `name` do log |
| IORegistry `VendorID` / `ProductID` | 1356 (0x054C) / 1476 (0x05C4) no GameSir G8+; 0x09CC no DualShock 4 de segunda geração | Segunda condição; casamento do leitor HID e do `TransportResolver` |
| IORegistry `Transport` | `"Bluetooth"` | `connection: bluetooth`; `usb` por cabo, verificado só por teste |
| Endereço Bluetooth | não lido | Fora do log (RNF de privacidade) |

Um DualShock 4 da Sony e um clone com a mesma identidade são indistinguíveis para o app e recebem o mesmo tratamento. Dispositivos fora deste contrato:

| Dispositivo | Identidade | Tratamento |
|-------------|------------|------------|
| Canal Bluetooth Low Energy do GameSir G8+ | 0x3537 / 0x1108, digitalizador | Não chega à interface de controles; não casa com nenhum par de `ControllerModel`; `TransportResolver` o filtra pelo fabricante. Nenhum evento, erro ou registro |
| Adaptador USB sem fio da Sony | 0x054C / 0x0BA0 | Fora do conjunto aceito (D-01); um controle ligado por ele recebe `controller.ignored` com `unsupported_model` |
| GameSir em outro modo | Identidade de Xbox ou de Switch | `unsupported_model`, uma vez por conexão |

## 2. Entrada pela interface de controles

O leitor usa `controller.extendedGamepad` (como `GCDualShockGamepad`) e `controller.physicalInputProfile`. Tabela de correspondência em `data-delta.md` §3. Regras:

- `pressedChangedHandler` nos botões digitais; `valueChangedHandler` com `TriggerTracker` (limiar 0,5) em `leftTrigger` e `rightTrigger`, que no DualShock 4 são analógicos como no DualSense.
- `leftThumbstick` e `rightThumbstick` com a normalização atual (RN-EC-08, RN-EC-10).
- `touchpadButton` → `touchpadClick`; `touchpadPrimary` e `touchpadSecondary` ligados com a mesma lógica do DualSense: fase por `touchDown/Moved/Up` quando `physicalInputProfile.touchpads` não é vazio, senão inferida pela transição de e para a origem (RN-EC-11); `controller.touch_source` registrado. Num aparelho sem touchpad físico, os elementos existem e nunca mudam de valor; nenhum evento, erro ou aviso é produzido.
- `buttonHome.preferredSystemGestureState = .disabled`, como nos outros modelos.
- Elemento ausente (por exemplo, `touchpadButton` fora do perfil) gera `controller.error` com "elemento ausente para touchpadClick", e os demais seguem.
- Se o PS chegar por esta via além do HID, a deduplicação de RN-EC-06 descarta a repetição.
- `battery` lido na conexão, na promoção e a cada 60 s com interface aberta (011 D-04); a sonda mostrou nível e estado informados.

## 3. Entrada pelo relatório HID

| Item | Valor |
|------|-------|
| Casamento | `kIOHIDVendorIDKey` 0x054C com `kIOHIDProductIDKey` 0x05C4 e 0x09CC, no mesmo `IOHIDManager` do PS |
| Abertura | `kIOHIDOptionsTypeNone` (não exclusiva), como hoje |
| Pedido de recurso | Por Bluetooth, `IOHIDDeviceGetReport` do recurso `0x05` (calibração, 41 bytes) na conexão, como no DualSense; resultado em `controller.extended_report` 🟡 (P-02) |
| Relatórios | `0x01` com 10 bytes (Bluetooth simplificado) ou 64 (USB); `0x11` com 78 bytes (Bluetooth completo) 🟡 (P-02) |
| PS | `DualShock4Report.homeButton`: `0x01` com ≥ 10 bytes → byte 7, bit 0; `0x11` com ≥ 12 bytes → byte 9, bit 0; outros → `nil` 🟡 (P-02) |
| Entrega | Só mudanças, por dispositivo emissor; ao controle ativo e só quando o emissor for do mesmo modelo (RN-EC-17) |
| Outros campos | Não lidos: eixos, toque, bateria, sensores, contador |

Disposição do bloco comum, conforme a literatura, para referência (a feature só lê o bit do PS):

| Deslocamento no bloco | Conteúdo |
|-----------------------|----------|
| +0 a +3 | analógicos esquerdo e direito |
| +4 | direcional (4 bits) e □ ✕ ○ △ |
| +5 | L1, R1, L2, R2, Share, Options, L3, R3 |
| +6 | bit 0 PS, bit 1 clique do touchpad, bits 2 a 7 contador |
| +7, +8 | L2 e R2 analógicos |

O bloco começa no byte 1 em `0x01` e no byte 3 em `0x11`.

## 4. Erros e ausências

| Situação | Comportamento |
|----------|---------------|
| Perfil DualShock sem par Sony no IORegistry | `controller.ignored` com `reason: unsupported_model` (D-01) |
| `IOHIDManagerOpen` falha | `controller.error` atual; o PS deixa de chegar pelo HID; os demais 17 botões seguem |
| Pedido do recurso `0x05` falha | `controller.extended_report` com o código; o PS continua legível no relatório simplificado; o touchpad de um DualShock 4 da Sony pode ficar mudo |
| Clone sem touchpad físico | Elementos mudos, sem efeito |
| Botões traseiros e de firmware do clone | Não chegam ao Mac ou chegam como botões já mapeados, conforme o firmware; nenhum tratamento |

## 5. Tempos

Sem tempo de resposta próprio: a entrega segue a fila `input` do legado. O RNF de desempenho compara a latência do DualShock 4 com a do DualSense pela ferramenta `poc-tools latency` quando aplicável; a leitura do PS e do toque não entra no laço de 120 Hz.
