# Inventário — joystick-AI

> Gerado pelo Scout em 2026-09-15 · Nível de documentação: completo
> Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA

## 1. Visão geral

Aplicativo agente para macOS (sem ícone no Dock) que lê um controle DualSense (PS5) e o converte em ponteiro de mouse, rolagem, atalhos de teclado e uma paleta de comandos de texto, com editor gráfico da configuração. 🟢

O código nasceu no ciclo greenfield do Reversa (`_reversa_sdd/prd.md` e `_reversa_sdd/sdd/`) e evoluiu em três features forward (`001-poc-entrada-ponteiro`, `002-paleta-comandos`, `003-editor-atalhos`), todas com adendo em `_reversa_sdd/addenda/`. Esta extração, portanto, documenta o que o código efetivamente faz, para confronto com as specs de origem. 🟢

| Métrica | Valor |
|---------|-------|
| Arquivos versionados | 205 (dos quais 87 Swift de produção e 29 de teste) 🟢 |
| Linhas Swift de produção | 7.836 🟢 |
| Linhas Swift de teste | 2.924 🟢 |
| Commits | 19, de 2026-09-14 a 2026-09-15 🟢 |
| Plataforma mínima | macOS 13 🟢 |
| Toolchain local | Swift 6.3.3, apenas Command Line Tools (sem Xcode) 🟢 |

## 2. Linguagens

| Linguagem | Extensões | Arquivos |
|-----------|-----------|----------|
| Swift | `.swift` | 116 (87 fontes, 29 testes) |
| Shell POSIX | `.sh` | 4 |
| JSON | `.json` | 7 amostras de configuração, mais `.vscode/launch.json` |
| Property List | `.plist` | 1 |

Linguagem principal: **Swift**. 🟢

## 3. Estrutura de pastas

```
joystick-AI/
├── Package.swift                 manifesto SwiftPM (3 produtos, 4 alvos)
├── Resources/Info.plist          bundle do app (LSUIElement, macOS 13)
├── scripts/
│   ├── build-app.sh              compila, monta, assina e instala o .app
│   ├── check-signature.sh        imprime o requisito designado da assinatura
│   ├── create-local-signing-identity.sh   certificado autoassinado de assinatura
│   ├── test.sh                   swift test compatível só com Command Line Tools
│   └── config-samples/           7 configurações de exemplo (válidas e inválidas)
├── Sources/
│   ├── JoystickCore/             lógica pura, só Foundation, Swift 6 (35 arquivos, 3.515 linhas)
│   │   ├── Analysis/   (3)  190  estatísticas de latência, análise de log, relatório de sequências
│   │   ├── App/        (1)  129  argumentos de abertura
│   │   ├── Config/     (9) 1188  modelo, carga, validação, localização de linha e rascunho do editor
│   │   ├── Input/      (5)  238  relatório DualSense, normalização, registro do controle ativo
│   │   ├── Log/        (2)  381  evento e catálogo de eventos do log
│   │   ├── Palette/    (1)  178  máquina de estados da paleta
│   │   ├── Pointer/    (8)  526  cinemática, cliques, touchpad, rolagem, união de telas
│   │   ├── Shortcuts/  (3)  341  catálogo de teclas, repetição, mapeamento de atalhos
│   │   ├── Support/    (2)  164  JSONValue e relógio monotônico
│   │   └── Targets/    (1)  180  modelo das sequências da tela de alvos
│   ├── JoystickAIPoC/            app agente com adaptadores de plataforma, Swift 5 (46 arquivos, 4.078 linhas)
│   │   ├── App/        (7)  515  AppDelegate, ciclo de vida, permissões, assinatura, menus
│   │   ├── Config/     (3)  325  armazenamento, observação e gravação do config.json
│   │   ├── Controller/ (7)  452  GameController, IOKit HID, transporte, diagnóstico
│   │   ├── Display/    (2)  101  monitor e catálogo de telas
│   │   ├── Editor/    (12) 1278  janela SwiftUI do editor de atalhos e paleta
│   │   ├── Injection/  (3)  287  injeção de mouse, teclado e rolagem por CGEvent
│   │   ├── Log/        (1)  108  gravação do log JSONL
│   │   ├── Palette/    (2)  340  painel e ações da paleta
│   │   ├── Pointer/    (4)  367  roteamento de entrada, laço de movimento, botões e atalhos
│   │   ├── Targets/    (4)  298  janela e sessão da tela de alvos
│   │   └── main.swift            ponto de entrada
│   └── poc-tools/                CLI de análise, Swift 6 (6 arquivos, 243 linhas)
└── Tests/JoystickCoreTests/      29 arquivos, 253 casos @Test
```

Pastas excluídas da listagem: `.build/`, `.git/`, `.claude/`, `.agents/`, `.reversa/`, `_reversa_sdd/`, `_reversa_forward/`.

A separação entre `JoystickCore` e `JoystickAIPoC` espelha as mesmas áreas de domínio: o núcleo guarda a lógica testável e o app guarda o adaptador de plataforma correspondente. 🟢 (comentários de `Package.swift` citam as decisões D-03 e D-22)

## 4. Produtos e alvos (SwiftPM)

| Alvo | Tipo | Modo de linguagem | Depende de | Papel |
|------|------|-------------------|------------|-------|
| `JoystickCore` | biblioteca | Swift 6 | — | Lógica pura, só Foundation (D-03) 🟢 |
| `JoystickAIPoC` | executável | Swift 5 | `JoystickCore` | App agente; isolamento por filas explícitas (D-22) 🟢 |
| `poc-tools` | executável | Swift 6 | `JoystickCore` | Análise do log e das sequências de alvos (RF-25) 🟢 |
| `JoystickCoreTests` | testes | Swift 6 | `JoystickCore` | Swift Testing, com flags condicionais para Command Line Tools 🟢 |

## 5. Pontos de entrada

| Caminho | Tipo | Descrição |
|---------|------|-----------|
| `Sources/JoystickAIPoC/main.swift` | app_entry | Cria `NSApplication`, instala `AppDelegate` e fixa a política `.accessory` 🟢 |
| `Sources/JoystickAIPoC/App/AppDelegate.swift` | bootstrap | Recusa segunda instância, interpreta os argumentos, cria a fila `input` (userInteractive) e liga log, permissões, leitores, roteador, injetores, paleta, configuração, editor e tela de alvos 🟢 |
| `Sources/poc-tools/main.swift` | cli_entry | Subcomandos `buttons`, `runs`, `latency` e `cycles`; saídas 0, 64 e 66 🟢 |
| `Sources/JoystickCore/App/LaunchArguments.swift` | launch_args | `--targets`, `--env mesa\|sofa`, `--screen`, `--seed`, `--debug`, `--scroll-unit pixel\|line`, `--palette-enter-delay-ms 0…500` 🟢 |

## 6. Configurações e arquivos em disco

| Caminho | Natureza | Origem no código |
|---------|----------|------------------|
| `~/.config/joystick-ai/config.json` | Configuração do usuário (atalhos, paleta, ponteiro), observada em tempo real | `JoystickCore/Config/ConfigLoader.swift:47`, `JoystickAIPoC/Config/ConfigWatcher.swift` 🟢 |
| `~/.config/joystick-ai/config.json.bak` | Cópia de segurança ao gravar sobre arquivo com erro de sintaxe | `JoystickAIPoC/Config/ConfigWriter.swift:18` 🟢 |
| `~/Library/Logs/joystick-ai/*.jsonl` | Log de diagnóstico, com sufixo em colisão de nome | `JoystickAIPoC/Log/DiagnosticLog.swift:40` 🟢 |
| `~/Library/Application Support/joystick-ai/target-runs/` | Resultados da tela de alvos | `JoystickAIPoC/Targets/TargetRunWriter.swift:16` 🟢 |
| `~/Applications/JoystickAIPoC.app` | Local fixo de instalação | `scripts/build-app.sh` 🟢 |
| `Resources/Info.plist` | `dev.iagoleal.joystick-ai.poc`, versão 0.1.0, `LSUIElement` | 🟢 |
| `scripts/config-samples/*.json` | Amostras para testes manuais: sintaxe inválida, fora de faixa, L3 como modificador, R1 em camada, paleta | 🟢 |
| `.vscode/launch.json` | Configurações de depuração da extensão Swift (não versionado) | 🟢 |

Não há `.env`, variáveis de ambiente de execução nem segredos. A única variável de ambiente é `JOYSTICK_SIGN_IDENTITY`, usada no build. 🟢

## 7. Build, assinatura e distribuição

- **Build do app:** `JOYSTICK_SIGN_IDENTITY="…" ./scripts/build-app.sh` executa `swift build -c release`, monta o bundle em `.build/app/`, assina com `codesign`, encerra a instância aberta e instala por `ditto`. 🟢
- **Assinatura estável é requisito:** a assinatura ad hoc (`-`) é recusada porque invalidaria as permissões de Acessibilidade e Input Monitoring a cada build (app-shell EC-01). 🟢
- **Identidade local:** `create-local-signing-identity.sh` gera certificado autoassinado no chaveiro de login (D-01, caminho B). 🟢
- **Testes:** `./scripts/test.sh` injeta `-F` do `Testing.framework` das Command Line Tools quando não há Xcode. 🟢

## 8. CI/CD e contêineres

- CI/CD: **ausente** (sem `.github/workflows/`, Jenkins ou GitLab CI). 🟢
- Docker: **ausente**, e inaplicável a um app de desktop macOS. 🟢

## 9. Banco de dados

**Ausente.** A persistência é inteiramente em arquivos: `config.json`, log JSONL e resultados de sequências de alvos (seção 6). Não há DDL, migrations nem ORM; por isso o plano dispensou o Data Master. 🟢

## 10. Integrações com o sistema operacional

| Integração | Framework | Onde |
|------------|-----------|------|
| Leitura do DualSense (botões, eixos, touchpad) | GameController | `JoystickAIPoC/Controller/*Reader.swift` 🟢 |
| Relatório estendido, calibração e transporte USB/Bluetooth | IOKit HID | `ExtendedReportActivator.swift`, `TransportResolver.swift` 🟢 |
| Injeção de mouse, teclado e rolagem | CoreGraphics (`CGEvent`) | `JoystickAIPoC/Injection/` 🟢 |
| Permissão de Acessibilidade (consulta periódica) | ApplicationServices (`AXIsProcessTrusted`) | `App/PermissionMonitor.swift` 🟢 |
| Inspeção da própria assinatura (`SecCodeCopySelf`, requisito designado) | Security | `App/SigningInfo.swift` 🟢 |
| Sinais POSIX para encerramento limpo | Dispatch | `App/Lifecycle.swift` 🟢 |
| Barra de menus, painel da paleta, menu Editar | AppKit | `App/StatusMenu.swift`, `App/EditMenu.swift`, `Palette/PalettePanel.swift` 🟢 |
| Editor de atalhos | SwiftUI e Combine | `JoystickAIPoC/Editor/` 🟢 |
| Ditado por voz | Nenhum código próprio: o editor depende do ditado de terceiros (Raycast) colando texto nos campos | `App/EditMenu.swift:6` 🟡 |

🟢 **LACUNA FECHADA (2026-09-15):** a spec greenfield `_reversa_sdd/sdd/voice-dictation.md` planeja o ditado no modo segurar para falar, acionando o Raycast, que transcreve (o app nunca transcreveria áudio). Nada disso existe como componente: o adendo da 001 registra que, no lugar dele, R3 dispara ⌘M para o transcritor do Raycast (`ShortcutDefaults.swift`), e o editor aceita o texto colado pelo ditado graças ao `EditMenu`. O usuário decidiu que o atalho configurável substitui o componente `voice-dictation`, cuja spec fica superada (`questions.md` Pergunta 1).

## 11. Testes

| Item | Valor |
|------|-------|
| Framework | Swift Testing (`import Testing`) 🟢 |
| Arquivos de teste | 29 🟢 |
| Casos `@Test` | 253 🟢 |
| Alvo coberto | Apenas `JoystickCore` 🟢 |
| Alvos sem teste automatizado | `JoystickAIPoC` (adaptadores de plataforma, editor, injeção) e `poc-tools` 🟢 |

Dos 35 arquivos do núcleo, 28 têm arquivo de teste homônimo. Os demais são `InputEvent`, `LogEvent`, `Geometry`, `PointerSettings` e `KeyRepeat`, possivelmente exercitados de forma indireta, além de `JSONValue` e `MonotonicClock`, que `SupportTests` agrupa. 🟡 (estimativa por nome de arquivo, não por cobertura medida)

## 12. Módulos identificados

A organização das specs já foi decidida como **por módulo** (`.reversa/config.toml`, `[specs]`). Os módulos abaixo agrupam, por área de domínio, a lógica do `JoystickCore` e o adaptador correspondente do `JoystickAIPoC`:

| Módulo | JoystickCore | JoystickAIPoC | Outros |
|--------|--------------|---------------|--------|
| `app-shell` | `App/` | `App/`, `main.swift` | `Resources/`, `scripts/*.sh` |
| `controller-input` | `Input/` | `Controller/` | — |
| `pointer` | `Pointer/` | `Pointer/MotionLoop`, `Pointer/ButtonActions`, `Pointer/InputRouter`, `Display/` | — |
| `injection` | — | `Injection/` | — |
| `shortcuts` | `Shortcuts/` | `Pointer/ShortcutActions` | — |
| `palette` | `Palette/` | `Palette/` | — |
| `config` | `Config/` (exceto `EditorDraft`) | `Config/` | `scripts/config-samples/` |
| `editor` | `Config/EditorDraft` | `Editor/`, `App/EditMenu` | — |
| `diagnostics-log` | `Log/`, `Support/` | `Log/` | — |
| `targets-analysis` | `Targets/`, `Analysis/` | `Targets/` | `poc-tools/` |
