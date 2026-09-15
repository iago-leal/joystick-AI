# ADR-007: Detecção da Acessibilidade por AXIsProcessTrusted, com portão de injeção

- **Status:** Aceito
- **Data:** 2026-09-14
- **Tipo:** retroativo (reconstruído pelo Detetive em 2026-09-15)

## Contexto

A spec previa consultar `CGPreflightPostEventAccess()` a cada 2 s. No PM-3, ao revogar a Acessibilidade com o app aberto, o macOS passou a descartar os eventos, mas a função continuou a devolver `true`, e o app não percebeu (P-08).

## Decisão

Consultar `AXIsProcessTrusted()` a cada 2 s. Na revogação, o `InjectionGate` fecha a paleta, solta tudo **antes** de desligar o injetor e guarda as solturas; na nova concessão, reativa e repete as solturas, para nenhum aplicativo ficar com tecla ou botão preso.

## Alternativas consideradas

Manter `CGPreflightPostEventAccess()` (não detecta a revogação); pedir relançamento (quebra o uso contínuo).

## Consequências

🟢 Revogação e concessão detectadas no hardware sem reiniciar. 🟡 Sem permissão desde o início, não há aviso visível: só `permissions.guidance` no log.

## Evidências

- `PermissionMonitor.swift:39-63`
- `InjectionGate.swift:33-62`
- `validation-report.md` 001:139,181
