# Interface: controle Ipega (interface de controles do sistema e relatório HID)

> Feature: `007-controle-ipega`
> Tipo: dispositivo de entrada, leitura; sem escrita no dispositivo
> Origem: `requirements.md` RN-01, RN-03, RN-04, RN-10, RN-11; `roadmap.md` D-01, D-03, D-04, D-06
> Integrações do legado afetadas: I-01 (`GameController`) e I-02 (IOKit HID), `_reversa_sdd/architecture.md#4. Integrações externas`
> Confidência: 🟢 salvo indicação (sondas de 2026-09-19, por cabo)

## 1. Identificação

| Propriedade | Valor observado | Uso |
|-------------|-----------------|-----|
| `GCController.productCategory` | `"Switch Pro Controller"` | Primeira condição de `ControllerModel.classify` |
| `GCController.vendorName` | `"Pro Controller"` | Só o campo `name` do log |
| IORegistry `VendorID` / `ProductID` | 1406 (0x057E) / 8201 (0x2009) | Segunda condição; também casamento do leitor HID e do `TransportResolver` |
| IORegistry `Transport` | `"USB"` | `connection: usb` |
| IORegistry `SerialNumber` | `"Shanwan…"` | Não usado |

Um Switch Pro Controller original da Nintendo tem a mesma identificação e seria aceito como `ipega` (premissa do `roadmap.md` §4). Controles com outra categoria ou outro par são ignorados.

## 2. Entrada pela interface de controles

O leitor usa `controller.extendedGamepad` e `controller.physicalInputProfile`. Tabela de correspondência em `data-delta.md` §3. Regras:

- `pressedChangedHandler` nos botões digitais; `valueChangedHandler` com `TriggerTracker` (limiar 0,5) em `leftTrigger` e `rightTrigger`, que no Ipega saltam de 0 para 1.
- `leftThumbstick` e `rightThumbstick` com a normalização atual (RN-EC-08, RN-EC-10).
- Nenhum touchpad é ligado.
- `buttonHome.preferredSystemGestureState = .disabled`, como no DualSense.
- Elemento ausente (por exemplo, `GCInputButtonShare` fora do perfil) gera `controller.error` com "elemento ausente para share", e os demais seguem.
- O Home não chegou por esta via na sonda; se passar a chegar, a deduplicação de RN-EC-06 evita a repetição.

## 3. Entrada pelo relatório HID

| Item | Valor |
|------|-------|
| Casamento | `kIOHIDVendorIDKey` 0x057E e `kIOHIDProductIDKey` 0x2009, no mesmo `IOHIDManager` do PS |
| Abertura | `kIOHIDOptionsTypeNone` (não exclusiva); a sonda leu os relatórios com a interface de controles ativa ao mesmo tempo |
| Relatório | `0x30`, 64 bytes por cabo, com o identificador no byte 0 |
| Home | Byte 4, bit `0x10` (`SwitchProReport.homeButton`); relatório com menos de 13 bytes ou outro identificador → `nil` |
| Entrega | Só mudanças, por dispositivo; ao controle ativo, como o PS (RN-EC-17) |
| Pedido de recurso | Nenhum: o `0x05` continua só para o DualSense sem fio |

Bits do relatório `0x30` conferidos nas sondas, para referência (a feature só lê o do Home):

| Byte | 0x01 | 0x02 | 0x04 | 0x08 | 0x10 | 0x20 | 0x40 | 0x80 |
|------|------|------|------|------|------|------|------|------|
| 3 | Y (cima) | X (esquerda) | B (direita) | A (baixo) | — | — | R | ZR |
| 4 | − (Select) | + (Start) | R3 | L3 | Home | Share | — | — |
| 5 | ↓ | ↑ | → | ← | — | — | L | ZL |

## 4. Erros e ausências

| Situação | Comportamento |
|----------|---------------|
| Ipega em outro modo (Android, iOS) | Outra identidade; `controller.ignored` com `reason: unsupported_model`, uma vez |
| `IOHIDManagerOpen` falha | `controller.error` atual; o Home deixa de chegar, os outros 17 botões seguem |
| Sem fio | Não verificado; P-02 no PM-1 🟡 |
| Botões Android, iOS, Turbo, Clear | Não chegam ao Mac; nenhum tratamento |

## 5. Tempos

Sem tempo de resposta próprio: a entrega segue a fila `input` do legado. O RNF de desempenho compara a latência do Ipega com a do DualSense no PM-1, pela ferramenta `poc-tools latency` quando aplicável.
