# Aplicativo (app-shell)

> Unit do módulo `app-shell` · Gerado pelo Redator em 2026-09-15 · Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA

## Visão Geral

Processo agente do macOS que monta todos os componentes na ordem certa, controla a permissão de Acessibilidade, garante que nada fica pressionado ao encerrar e oferece o ícone da barra de menus. É a casca que transforma os módulos do núcleo num app residente, sem Dock, operável só pelo controle. 🟢

## Responsabilidades

- Garantir instância única e política de ativação `.accessory` (sem Dock nem menu de app visível). 🟢
- Interpretar os argumentos de abertura (`open --args`). 🟢
- Montar, em ordem estrita, log, configuração, injetores, atalhos, paleta, editor, observação do arquivo, roteador, portão de injeção, ciclo de vida, telas, permissões e, por último, a leitura do controle. 🟢
- Consultar a Acessibilidade a cada 2 s e ligar ou desligar a injeção por meio do portão, sem deixar teclas ou botões presos. 🟢
- Encerrar de forma limpa por "Sair" ou por `SIGTERM`, `SIGINT` e `SIGHUP`. 🟢
- Exibir o ícone da barra de menus, com alerta quando a configuração é inválida. 🟢
- Abrir a tela de alvos quando pedida por argumento. 🟢
- Fornecer os scripts de build, assinatura estável, instalação e testes. 🟢

## Regras de Negócio

- RN-AP-01: Se outro processo com o mesmo `bundleIdentifier` estiver rodando, a nova instância encerra-se imediatamente, sem registrar nada. 🟢
- RN-AP-02: A leitura do controle só começa depois que todos os consumidores de entrada existem. 🟢
- RN-AP-03: A seção `pointer` da configuração é lida uma única vez, na abertura; atalhos e paleta ficam a cargo do `ConfigStore`. 🟢
- RN-AP-04: A Acessibilidade é lida por `AXIsProcessTrusted()`, e não por `CGPreflightPostEventAccess()`, que não reflete a revogação no processo vivo. 🟢
- RN-AP-05: `CGRequestPostEventAccess()` é chamado no máximo uma vez por processo, e só se a Acessibilidade faltar na primeira consulta. 🟢
- RN-AP-06: Só a mudança da Acessibilidade aciona o portão; o Monitoramento de Entrada é apenas registrado. 🟢
- RN-AP-07: A primeira definição do portão não gera evento de suspensão nem de retomada. 🟢
- RN-AP-08: Ao perder a permissão, o portão fecha a paleta com `injection_suspended`, solta teclas e botões **antes** de desligar a injeção, guarda essas solturas, registra a suspensão e avisa a tela de alvos. 🟢
- RN-AP-09: Ao recuperar a permissão, o portão religa a injeção, repete as solturas guardadas e registra a retomada com `heldButtons` vazio. 🟢
- RN-AP-10: A limpeza de encerramento roda uma única vez: solta atalhos e botões de mouse de forma síncrona na fila `input`, registra `app.terminating` com os botões soltos e força a escrita do log. Nos sinais, termina com `exit(0)`. 🟢
- RN-AP-11: Erros de argumentos da paleta são sempre registrados em `palette.invalid_args`; os demais só são registrados, em `targets.invalid_args`, quando `--targets` foi pedido, e `--screen` inválido não é registrado ali, e sim como `targets.screen_fallback`. 🟢
- RN-AP-12: A tela de alvos só abre com `--targets` e `--env` válido e com ao menos uma tela ativa; `--screen` inválido ou maior que o número de telas cai na tela 1; sem `--seed`, a semente é aleatória entre 0 e 2³²−1. 🟢
- RN-AP-13: Enquanto a tela de alvos estiver aberta, a paleta fica bloqueada. 🟢
- RN-AP-14: Com a configuração inválida, o ícone vira `exclamationmark.triangle` e o menu ganha no topo "Configuração inválida: linha N" (ou sem linha), que abre o editor com origem `alert`, seguido de separador. 🟢
- RN-AP-15: A assinatura ad hoc é recusada pelo script de build, porque invalida as permissões a cada compilação. 🟢
- RN-AP-16: Sem Acessibilidade desde a abertura, não há aviso visual; a orientação vai só ao log. 🟡

## Requisitos Funcionais

| ID | Requisito | Prioridade | Critério de Aceite |
|----|-----------|-----------|-------------------|
| RF-AP-01 | Rodar como app agente com `LSUIElement` e política `.accessory` | Must | O app não aparece no Dock nem no ⌘Tab |
| RF-AP-02 | Encerrar uma segunda instância aberta | Must | Abrir o app duas vezes deixa um único processo |
| RF-AP-03 | Interpretar `--targets`, `--debug`, `--env`, `--screen`, `--seed`, `--scroll-unit`, `--palette-enter-delay-ms` conforme `design.md` §Interface | Must | Cada argumento inválido gera o erro e a mensagem previstos |
| RF-AP-04 | Montar os componentes na ordem de `design.md` §Fluxo Principal | Must | Nenhum evento do controle chega antes de o roteador existir |
| RF-AP-05 | Registrar `session.start` com versão, macOS, pid, `debug`, argumentos brutos e assinatura | Must | A primeira linha de todo log é `session.start` |
| RF-AP-06 | Consultar a Acessibilidade na abertura e a cada 2 s, registrando `permissions.status` a cada mudança | Must | Revogar e conceder a permissão com o app aberto gera dois `permissions.status` em até ~2 s cada |
| RF-AP-07 | Suspender e retomar a injeção conforme RN-AP-08 e RN-AP-09 | Must | Revogar durante um arraste não deixa o botão esquerdo preso após a nova concessão |
| RF-AP-08 | Limpar ao encerrar conforme RN-AP-10 | Must | `kill -TERM` durante um arraste solta o botão e grava `app.terminating { reason: sigterm }` |
| RF-AP-09 | Exibir ícone com "Editar atalhos", separador e "Sair", e o alerta de configuração inválida | Must | Arquivo com erro na linha 4 mostra "Configuração inválida: linha 4" |
| RF-AP-10 | Abrir a tela de alvos conforme RN-AP-12 e RN-AP-13 | Should | `--targets --env sofa --screen 9` com uma tela abre na tela 1 e registra `targets.screen_fallback` |
| RF-AP-11 | Compilar, montar, assinar com identidade fixa e instalar em `~/Applications/JoystickAIPoC.app` | Must | Recompilar mantém a Acessibilidade concedida |
| RF-AP-12 | Rodar os testes do núcleo também só com as Command Line Tools | Must | `./scripts/test.sh` executa os 253 testes |

## Requisitos Não Funcionais

| Tipo | Requisito inferido | Evidência no código | Confiança |
|------|--------------------|---------------------|-----------|
| Disponibilidade | Perda de permissão não encerra o processo; a injeção retoma sozinha | `InjectionGate.swift:28-58` | 🟢 |
| Robustez | Sinais de término não deixam entradas presas | `Lifecycle.swift:18-42` | 🟢 |
| Performance | Consulta de permissões com folga de 200 ms, fora da fila de entrada | `PermissionMonitor.swift:39-40` | 🟢 |
| Segurança | Assinatura com identidade fixa; ad hoc recusada | `scripts/build-app.sh:19-31` | 🟢 |
| Privacidade | `session.start` inclui os argumentos brutos | `AppDelegate.swift:45` | 🟢 |
| Compatibilidade | macOS 13 ou posterior | `Package.swift`, `Resources/Info.plist` | 🟢 |

## Critérios de Aceitação

```gherkin
Dado o app instalado e já aberto
Quando o usuário o abre de novo
Então a nova instância encerra-se e só um processo continua

Dado o app aberto com Acessibilidade concedida e R1 segurado sobre um texto
Quando o usuário revoga a Acessibilidade
Então em até ~2 s o log registra permissions.status, permissions.guidance e pointer.injection_suspended com heldButtons ["left"]
E a paleta, se aberta, fecha com o motivo injection_suspended

Dado a injeção suspensa com a soltura do botão esquerdo guardada
Quando o usuário concede a Acessibilidade de novo
Então o app repete o mouseUp guardado e registra pointer.injection_resumed com heldButtons vazio

Dado o app aberto sem Acessibilidade desde o início
Quando o processo inicia
Então CGRequestPostEventAccess é chamado uma única vez e nenhum evento de suspensão é registrado

Dado R2 segurado
Quando o processo recebe SIGTERM
Então o botão direito é solto, app.terminating registra reason sigterm e releasedButtons ["right"], o log é descarregado e o processo sai com código 0

Dado --targets sem --env
Quando o app abre
Então targets.invalid_args registra "--targets exige --env mesa ou --env sofa" e a tela de alvos não abre

Dado --palette-enter-delay-ms 900
Quando o app abre sem --targets
Então palette.invalid_args é registrado e a paleta usa o atraso padrão de 0 ms

Dado JOYSTICK_SIGN_IDENTITY igual a "-"
Quando build-app.sh é executado
Então o script termina com código 64 sem compilar
```

## Prioridade (MoSCoW)

| Requisito | MoSCoW | Justificativa |
|-----------|--------|---------------|
| Ordem de montagem, instância única, `session.start` | Must | Caminho de toda execução |
| Portão de injeção e consulta de permissão | Must | Sem ele, revogação deixa entradas presas |
| Limpeza de encerramento | Must | Robustez exigida pela 001 (RF-23) |
| Ícone e alerta de configuração | Must | Única via visual de erro de configuração |
| Tela de alvos por argumento | Should | Instrumento de medição, não uso diário |
| Aviso visual sem permissão | Won't | Não implementado; só log |

## Rastreabilidade de Código

| Arquivo | Função / Classe | Cobertura |
|---------|-----------------|-----------|
| `Sources/JoystickAIPoC/main.swift` | ponto de entrada | 🟢 |
| `Sources/JoystickAIPoC/App/AppDelegate.swift` | `AppDelegate` | 🟢 |
| `Sources/JoystickAIPoC/App/InjectionGate.swift` | `InjectionGate` | 🟢 |
| `Sources/JoystickAIPoC/App/Lifecycle.swift` | `Lifecycle` | 🟢 |
| `Sources/JoystickAIPoC/App/PermissionMonitor.swift` | `PermissionMonitor` | 🟢 |
| `Sources/JoystickAIPoC/App/SigningInfo.swift` | `SigningInfo` | 🟢 |
| `Sources/JoystickAIPoC/App/StatusMenu.swift` | `StatusMenu` | 🟢 |
| `Sources/JoystickCore/App/LaunchArguments.swift` | `LaunchArguments`, `LaunchArgumentError` | 🟢 |
| `Resources/Info.plist` | bundle | 🟢 |
| `Package.swift` | alvos | 🟢 |
| `scripts/build-app.sh`, `check-signature.sh`, `create-local-signing-identity.sh`, `test.sh` | build e testes | 🟢 |
