# Cápsula de reprodução · BUG-20260922-33HN

| Campo | Valor |
|---|---|
| Commit base | `7dd87d2` (main) + árvore de trabalho da feature 012 sem commit (build instalado em 2026-09-22) |
| Ambiente | macOS 27.0; Swift 6.4 (CLT); GameSir G8+ em modo PlayStation, Bluetooth, classificado `dualShock4` |
| Reprodução 1 (com o app) | Sessão do usuário de 2026-09-22 14:32 a 14:39, log `~/Library/Logs/joystick-ai/poc-20260922-143211.jsonl`; roteiro: segurar △ (e ✕, □, ○) variando a pressão |
| Resultado 1 | △: 33 pressões, 20 com intervalo `up`→`down` < 120 ms (15 a 60 ms), durações de 15 a 60 ms; cada `down` seguido de `shortcut.triggered`. □: 241 pressões, 210 com intervalo < 120 ms (moda 60 a 80 ms). ✕ e ○ idem em menor volume |
| Reprodução 2 (sem o app) | `swift _reversa_forward/012-controle-dualshock-4/sondas/probe-ds4.swift`, 14:22, pressionar cada botão uma vez |
| Resultado 2 | Bit 7 do byte 7 do relatório `0x11` (△) alterna 0x08→0x88→0x08 três vezes a cada 30 ms; `GCControllerButtonInput.pressedChangedHandler` acompanha. A, B, X, Y, Options e Menu: 3 a 6 bordas por pressão única; L1, R1, L3, R3: uma borda |
| Exit code | não se aplica (observação de log); a sonda encerra por tecla |
| Taxa | △ 20/32 intervalos em rajada; □ 210/240; ○ 14/22; ✕ 9/27 (log do app). Sonda: 6/6 botões de membrana com rajada numa pressão única |
| Classificação | `intermittent`: depende de segurar o botão variando a pressão; pressões secas costumam produzir uma borda |
| Contraprova | Logs do Ipega (2026-09-20, dois arquivos): nenhum intervalo `up`→`down` abaixo de 120 ms em ✕, ○ e △; os poucos abaixo de 120 ms estão em □ e direcional com `repeat: true`, toques rápidos deliberados. Usuário confirma: não ocorre no DualSense nem no Ipega |
| Reprodução offline | Sequência gravada do △ (14:34:54.677 down, .692 up, .722 down, .752 up, .782 down, .797 up) reproduzida no teste `ButtonDebouncerTests` a partir do Gate 1 |

Histogramas completos por botão, nos quatro logs mais recentes, em `../../../intake/analise-intervalos-botoes-de-face.md` e na saída do `/reversa-debugger-fix` de 2026-09-22 (abaixo).

## Histograma dos intervalos `up`→`down` (ms), log do DualShock 4 de 2026-09-22

| botão | 0-20 | 20-40 | 40-60 | 60-80 | 80-100 | 100-120 | 120-150 | 150-200 | 200-500 | ≥500 |
|---|---|---|---|---|---|---|---|---|---|---|
| cross | 0 | 0 | 1 | 8 | 0 | 0 | 0 | 0 | 0 | 21 |
| circle | 0 | 1 | 8 | 3 | 2 | 0 | 0 | 0 | 0 | 8 |
| square | 2 | 5 | 74 | 113 | 21 | 1 | 3 | 2 | 12 | 21 |
| triangle | 1 | 11 | 9 | 0 | 0 | 0 | 0 | 0 | 0 | 14 |
| options | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 6 |
| create | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 5 |
| dpadDown | 0 | 0 | 0 | 4 | 0 | 0 | 0 | 3 | 5 | 20 |
| r1 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 1 | 24 |
| l1, l3, r3, ps | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | todos |

Leitura: as rajadas ficam entre 15 e 100 ms; pressões humanas distintas ficam a partir de 150 ms, salvo toques rápidos deliberados no direcional (4 casos de 60 a 80 ms). Ombros, cliques dos analógicos e PS não apresentam rajada.
