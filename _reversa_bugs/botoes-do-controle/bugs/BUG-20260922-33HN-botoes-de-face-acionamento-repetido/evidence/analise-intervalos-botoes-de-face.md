# Intervalos entre pressões dos botões de face (gerado em 2026-09-22 pelo /reversa-debugger)

Fonte: ~/Library/Logs/joystick-ai/. Para cada botão, intervalo entre o `up` e o `down` seguinte e duração de cada pressão.
Rajada: gap < 120 ms ou duração < 25 ms, cadência incompatível com pressões humanas distintas.

## poc-20260920-191619.jsonl (model: ipega, 342 eventos de face)

| botão | pressões | gap mín (ms) | gap mediano (ms) | gaps < 120 ms | durações < 25 ms |
|---|---|---|---|---|---|
| cross | 78 | 375 | 52306 | 0 | 0 |
| circle | 39 | 150 | 5716 | 0 | 0 |
| square | 40 | 30 | 4065 | 8 | 0 |
| triangle | 14 | 34739 | 475482 | 0 | 0 |

## poc-20260921-193627.jsonl (model: ipega, 0 eventos de face)

| botão | pressões | gap mín (ms) | gap mediano (ms) | gaps < 120 ms | durações < 25 ms |
|---|---|---|---|---|---|
| cross | 0 | - | - | 0 | 0 |
| circle | 0 | - | - | 0 | 0 |
| square | 0 | - | - | 0 | 0 |
| triangle | 0 | - | - | 0 | 0 |

## poc-20260922-143211.jsonl (model: dualShock4, 634 eventos de face)

| botão | pressões | gap mín (ms) | gap mediano (ms) | gaps < 120 ms | durações < 25 ms |
|---|---|---|---|---|---|
| cross | 20 | 60 | 4155 | 7 | 4 |
| circle | 23 | 30 | 75 | 14 | 5 |
| square | 241 | 15 | 60 | 210 | 13 |
| triangle | 33 | 15 | 45 | 20 | 7 |
