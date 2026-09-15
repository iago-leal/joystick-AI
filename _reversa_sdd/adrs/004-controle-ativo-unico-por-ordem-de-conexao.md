# ADR-004: Um único controle ativo, por ordem de conexão

- **Status:** Aceito
- **Data:** 2026-09-14
- **Tipo:** retroativo (reconstruído pelo Detetive em 2026-09-15)

## Contexto

Mais de um DualSense pode estar pareado, e entradas simultâneas de dois controles produziriam cliques e teclas conflitantes. Uma desconexão no meio de um arraste não pode deixar botões presos.

## Decisão

`ActiveControllerRegistry` mantém a fila por ordem de chegada; o primeiro é o ativo, os outros aguardam. Ao desconectar o ativo, cada botão pressionado recebe `buttonUp` sintético em ordem estável e o seguinte assume. Controles que não são DualSense são ignorados.

## Alternativas consideradas

Aceitar todos os controles (conflitos); último conectado vence (tomada acidental por um controle ligado ao lado).

## Consequências

🟢 RN-01 e RN-04 da 001 atendidas. 🟡 A promoção não gera evento de log. 🟡 Ver ADR-003 sobre o PS.

## Evidências

- `ActiveControllerRegistry.swift:39-68`
- `ControllerReader.swift:94-116`
- 001 D-09, RN-01, RN-04
