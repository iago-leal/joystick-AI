# Aplicativo (app-shell), Tarefas de Implementação

> Gerado pelo Redator em 2026-09-15 · Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA

## Pré-requisitos

- [ ] Command Line Tools com Swift 6.x; macOS 13 ou posterior
- [ ] Identidade de assinatura de código estável no chaveiro de login
- [ ] Units `entrada-do-controle`, `ponteiro`, `injecao-de-eventos`, `atalhos`, `paleta`, `configuracao`, `editor`, `log-de-diagnostico` e `tela-de-alvos-e-analise` disponíveis, pois esta unit apenas as monta

## Tarefas

- [ ] T-01, Criar o `Package.swift` com `JoystickCore` (Swift 6), `JoystickAIPoC` (Swift 5), `poc-tools` (Swift 6) e `JoystickCoreTests`, com as flags condicionais do `Testing.framework` das CLT
  - Origem no legado: `Package.swift`
  - Critério de pronto: `swift build` compila os três produtos
  - Confiança: 🟢

- [ ] T-02, Implementar `LaunchArguments.parse` com os sete argumentos, erros, mensagens e `concernsPalette`
  - Origem no legado: `Sources/JoystickCore/App/LaunchArguments.swift:3-128`
  - Critério de pronto: testes cobrem cada erro, `missingValue` no fim da lista e `missingEnv`
  - Confiança: 🟢

- [ ] T-03, Criar `main.swift` e `Info.plist` de app agente
  - Origem no legado: `Sources/JoystickAIPoC/main.swift`, `Resources/Info.plist`
  - Critério de pronto: o app não aparece no Dock
  - Confiança: 🟢

- [ ] T-04, Implementar `SigningInfo.current()` pela API Security
  - Origem no legado: `Sources/JoystickAIPoC/App/SigningInfo.swift`
  - Critério de pronto: `session.start.signing` traz identificador, certificado e requisito
  - Confiança: 🟢

- [ ] T-05, Implementar `PermissionMonitor` com `AXIsProcessTrusted`, `CGPreflightListenEventAccess`, pedido único e temporizador de 2 s
  - Origem no legado: `Sources/JoystickAIPoC/App/PermissionMonitor.swift:11-65`
  - Critério de pronto: revogar e conceder com o app aberto gera `permissions.status` e aciona o callback
  - Confiança: 🟢

- [ ] T-06, Implementar `InjectionGate` com estado inicial silencioso, suspensão que solta antes de desligar e retomada que repete solturas
  - Origem no legado: `Sources/JoystickAIPoC/App/InjectionGate.swift:5-59`
  - Critério de pronto: roteiro de revogação durante arraste deixa o botão solto após a nova concessão
  - Confiança: 🟢

- [ ] T-07, Implementar `Lifecycle` com sinais `SIGTERM`, `SIGINT`, `SIGHUP` e limpeza idempotente
  - Origem no legado: `Sources/JoystickAIPoC/App/Lifecycle.swift:5-43`
  - Critério de pronto: `kill -INT` grava `app.terminating { reason: sigint }` e sai com 0
  - Confiança: 🟢

- [ ] T-08, Implementar `StatusMenu` com ícone modelo, itens e alerta de configuração inválida
  - Origem no legado: `Sources/JoystickAIPoC/App/StatusMenu.swift`
  - Critério de pronto: configuração inválida troca o ícone e insere o item com a linha
  - Confiança: 🟢

- [ ] T-09, Implementar `AppDelegate.applicationDidFinishLaunching` na ordem de `design.md`, com instância única
  - Origem no legado: `Sources/JoystickAIPoC/App/AppDelegate.swift:31-139,192-198`
  - Critério de pronto: `session.start` é a primeira linha; o controle só é lido depois do roteador; segunda instância encerra-se
  - Confiança: 🟢

- [ ] T-10, Implementar `openTargets` com validação, telas, semente e bloqueio da paleta
  - Origem no legado: `Sources/JoystickAIPoC/App/AppDelegate.swift:146-190`
  - Critério de pronto: cenários de `requirements.md` para `--targets` passam
  - Confiança: 🟢

- [ ] T-11, Criar os scripts `build-app.sh`, `create-local-signing-identity.sh`, `check-signature.sh` e `test.sh`
  - Origem no legado: `scripts/`
  - Critério de pronto: recompilar e reinstalar preserva a Acessibilidade; `test.sh` executa os testes nas CLT
  - Confiança: 🟢

## Tarefas de Teste

- [ ] TT-01, `LaunchArgumentsTests`: todos os argumentos válidos, cada erro, `concernsPalette`, argumento desconhecido ignorado
- [ ] TT-02, Roteiro manual: revogação e concessão da Acessibilidade durante arraste com R1 e com um acorde mantido
- [ ] TT-03, Roteiro manual: `SIGTERM`, `SIGINT`, `SIGHUP` e "Sair" com botões pressionados
- [ ] TT-04, Roteiro manual: segunda instância; alerta de configuração inválida no menu
- [ ] TT-05, Roteiro manual: `--targets` sem `--env`, com `--screen` fora da faixa e sem telas

## Ordem Sugerida

1. T-01 a T-04: pacote, argumentos e identidade, que não dependem das outras units.
2. T-11: build assinado antes de qualquer teste com permissão.
3. T-05 a T-08: componentes da casca.
4. T-09 e T-10 por último, depois que as demais units existem.

## Lacunas Pendentes (🔴)

Nenhuma nesta unit. A falta de aviso visual sem Acessibilidade (🟡) é candidata a decisão de produto.
