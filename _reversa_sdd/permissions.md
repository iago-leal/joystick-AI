# Permissões — joystick-AI

> Gerado pelo Detetive em 2026-09-15 · Nível: completo
> Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA

## 1. Papéis de usuário

O joystick-AI é um app local de usuário único, sem contas, login, servidor nem dados compartilhados. **Não há RBAC nem ACL**: quem está diante do Mac com o controle tem acesso a todas as funções. O plano aprovado em 2026-09-15 dispensou a matriz de papéis por esse motivo. 🟢

O controle de acesso relevante é o do próprio macOS (TCC, *Transparency, Consent and Control*), que decide o que o processo pode fazer. Este documento registra essas permissões como a "matriz" do sistema.

## 2. Matriz de permissões do sistema operacional

| Permissão (Ajustes › Privacidade) | API usada | Exigida para | Sem ela | Detectada por | Confiança |
|-----------------------------------|-----------|--------------|---------|---------------|-----------|
| **Acessibilidade** | `CGEvent.post(.cghidEventTap)` | Mover o cursor, clicar, rolar, teclas, textos da paleta, clique de ativação do editor | Portão de injeção desliga; eventos são descartados; a leitura do controle continua | `AXIsProcessTrusted()` a cada 2 s (`PermissionMonitor.swift:39-48`) | 🟢 |
| **Monitoramento de Entrada** | `CGPreflightListenEventAccess()` (só consulta) | Nenhuma decisão do app | Só é registrado em `permissions.status` | Consulta a cada 2 s | 🟢 |
| Monitoramento de Entrada, efeito indireto | `GCController.shouldMonitorBackgroundEvents`, `IOHIDManager` | Nada além da Acessibilidade | Com só a Acessibilidade concedida, botões e analógico chegaram com o app em segundo plano, e `CGPreflightListenEventAccess()` passou a `true` sem a permissão na lista (P-04, `validation-report.md` 001:123,135) | — | 🟢 |
| **Preferências de outros apps** (leitura) | `CFPreferencesCopyAppValue("AppleSymbolicHotKeys", "com.apple.symbolichotkeys")` | Acorde real dos atalhos de sistema | Não exige TCC; na falha, usa o acorde padrão | — | 🟢 |
| Arquivos do usuário | `~/.config/joystick-ai/`, `~/Library/Logs/joystick-ai/`, `~/Library/Application Support/joystick-ai/` | Configuração, log e resultados | Falhas viram `shortcuts.save_failed`, `os.Logger` ou `targets.write_failed`; o app segue | — | 🟢 |
| Rede | Nenhuma | — | — | Nenhum uso de `URLSession` ou sockets em `Sources/` | 🟢 |
| Microfone | Nenhuma | — | — | O app não captura áudio | 🟢 |

## 3. Pedido e concessão

| Regra | Evidência | Confiança |
|-------|-----------|-----------|
| `CGRequestPostEventAccess()` é chamado uma única vez por processo, e só se a Acessibilidade faltar no início | `PermissionMonitor.swift:35-38` | 🟢 |
| Sem a permissão, o log recebe `permissions.guidance` com a orientação de concessão; não há diálogo próprio nem aviso na tela | `PermissionMonitor.swift:57-63` | 🟢 |
| Concessão e revogação são aplicadas sem reiniciar o app, em até cerca de 2 s | `PermissionMonitor.swift:12`; roteiro §3 item 15 aprovado | 🟢 |
| A permissão é vinculada à assinatura: o app é assinado com a identidade local "JoystickAI Local Signing" (caminho B de D-01) para a concessão sobreviver às recompilações | `scripts/create-local-signing-identity.sh`, `validation-report.md` 001:119-120; `SigningInfo.swift` registra a assinatura em `session.start` | 🟢 |
| O app é instalado em caminho fixo, `~/Applications/JoystickAIPoC.app`, porque o TCC identifica o app também pelo caminho | `scripts/build-app.sh`, 001 D-02 | 🟢 |

## 4. Restrições de acesso internas

Mesmo sem papéis, o código restringe o alcance de algumas funções:

| Restrição | Motivo | Evidência | Confiança |
|-----------|--------|-----------|-----------|
| A gravação de acorde lê o teclado físico só com o campo ativo e a janela do editor em foco, por monitor local | Não capturar teclas fora do editor (003 RN-15) | `KeyCaptureField.swift:12-89` | 🟢 |
| Eventos com a marca do injetor são descartados na gravação de acorde e contam como únicos cliques válidos na tela de alvos | Separar ações do controle das do hardware | `KeyCaptureField.swift`, `TargetSession.swift:72-79` | 🟢 |
| Textos, rótulos, acordes, coordenadas e valores de eixo nunca vão ao log | Privacidade (001 RN-12, 003 RN-14) | `LogEventCatalog.swift:33-333` | 🟢 |
| `session.start` registra todos os argumentos de abertura, e `shortcuts.save_failed` inclui o caminho absoluto com o nome do usuário | Exceções à minimização do log | `AppDelegate.swift:37-46`; log local de 2026-09-15 13:02 | 🟡 |
| Ações de texto e da paleta só digitam; nenhuma executa programa ou shell | Limitar o efeito de uma configuração maliciosa ou errada (002 RN-06, 003 RN-13) | `KeyboardInjector.swift:79-94` | 🟢 |

## 5. Lacunas

Nenhuma. A P-04 da 001 mostrou que o Monitoramento de Entrada não é necessário: a Acessibilidade basta para ler o controle em segundo plano. 🟢
