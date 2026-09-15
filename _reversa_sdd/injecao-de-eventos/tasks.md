# Injeção de eventos (injection), Tarefas de Implementação

> Gerado pelo Redator em 2026-09-15 · Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA

## Pré-requisitos

- [ ] Acessibilidade concedida ao app assinado (unit `aplicativo`)
- [ ] Tipos `ScreenUnion`, `MouseAction`, `MoveKind`, `PointDelta`, `ScrollUnit` (unit `ponteiro`)
- [ ] Tipos `KeyChord` e `KeyModifier` (unit `atalhos`)
- [ ] `LogEventCatalog.pointerPosted` (unit `log-de-diagnostico`)

## Tarefas

- [ ] T-01, Implementar `EventInjector` com fonte `.hidSystemState`, marca, `enabled` e `screens`
  - Origem no legado: `Sources/JoystickAIPoC/Injection/EventInjector.swift:8-29,133-147`
  - Critério de pronto: eventos postados carregam `eventSourceUserData = 0x4A4F5953`
  - Confiança: 🟢

- [ ] T-02, Implementar `currentLocation` e `track` com janela de 100 ms e 32 posições
  - Origem no legado: `Sources/JoystickAIPoC/Injection/EventInjector.swift:31-62`
  - Critério de pronto: deslize diagonal no touchpad não perde o componente horizontal; mouse físico retoma o controle
  - Confiança: 🟢

- [ ] T-03, Implementar `move` com clamp, tipos de arraste e deltas
  - Origem no legado: `Sources/JoystickAIPoC/Injection/EventInjector.swift:64-87`
  - Critério de pronto: arraste com R1 seleciona texto; cursor para na borda externa das telas
  - Confiança: 🟢

- [ ] T-04, Implementar `post(MouseAction)` com `clickState`
  - Origem no legado: `Sources/JoystickAIPoC/Injection/EventInjector.swift:89-108`
  - Critério de pronto: duplo clique seleciona palavra
  - Confiança: 🟢

- [ ] T-05, Implementar `activationClick(at:)`
  - Origem no legado: `Sources/JoystickAIPoC/Injection/EventInjector.swift:110-131`
  - Critério de pronto: editor aberto pela paleta fica em foco e o cursor volta à posição anterior
  - Confiança: 🟢

- [ ] T-06, Implementar `KeyboardInjector` (contagem, acordes, setas, repetição, soltura forçada)
  - Origem no legado: `Sources/JoystickAIPoC/Injection/KeyboardInjector.swift:8-76,96-115`
  - Critério de pronto: L2 + ← troca de mesa; Options + → + → mantém ⌘ entre os dois Tab
  - Confiança: 🟢

- [ ] T-07, Implementar `type(_:pressEnter:)` por unidade UTF-16
  - Origem no legado: `Sources/JoystickAIPoC/Injection/KeyboardInjector.swift:78-94`
  - Critério de pronto: texto com acentos chega igual com layouts diferentes
  - Confiança: 🟢

- [ ] T-08, Implementar `ScrollInjector`
  - Origem no legado: `Sources/JoystickAIPoC/Injection/ScrollInjector.swift`
  - Critério de pronto: rolagem em pixel e em linha; passo nulo não posta
  - Confiança: 🟢

## Tarefas de Teste

- [ ] TT-01, Roteiro manual: movimento, arraste, cliques e rolagem em Terminal, VS Code e navegador
- [ ] TT-02, Roteiro manual: acordes com modificadores sobrepostos (Options segurado + acorde com ⌘)
- [ ] TT-03, Roteiro manual: Mission Control e troca de mesas pelas setas injetadas
- [ ] TT-04, Roteiro manual: revogar a Acessibilidade e verificar que nada é postado e que a retomada solta o que ficou
- [ ] TT-05, Verificar em `--debug` que só eventos com origem geram `pointer.posted` e que nenhuma tecla aparece no log

## Ordem Sugerida

1. T-01 e T-02, base de todo evento.
2. T-03, T-04 e T-08 para o ponteiro.
3. T-06 e T-07 para atalhos e paleta.
4. T-05 junto com o editor.

## Lacunas Pendentes (🔴)

Nenhuma. Decidir se emoji e caracteres fora do BMP precisam de envio como par completo (🟡).
