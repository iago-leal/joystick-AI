# ADR-009: R1 e touchpad no clique esquerdo, R2 no direito

- **Status:** Aceito (substitui 001 RN-11)
- **Data:** 2026-09-14
- **Tipo:** retroativo (reconstruído pelo Detetive em 2026-09-15)

## Contexto

A spec da 001 colocava o clique esquerdo em R2 e no touchpad, e o direito em R1. No PM-3, o usuário pediu a troca por ergonomia.

## Decisão

R1 e o clique do touchpad seguram o mesmo botão esquerdo (dois detentores, `mouseUp` só com os dois soltos); R2 faz o direito. Os três botões ficam fora dos atalhos e não podem ser modificadores.

## Alternativas consideradas

Manter o mapeamento da spec; torná-lo configurável (adiado: 003 manteve os três como fixos).

## Consequências

🟢 Incorporado em 003 RN-05. 🟡 A spec da 001 não foi reescrita; quem ler só a 001 encontra o mapeamento antigo.

## Evidências

- `ClickStateMachine.swift:18-19,44-65`
- `ShortcutConfig.swift:33`
- `actions.md` 001:210
