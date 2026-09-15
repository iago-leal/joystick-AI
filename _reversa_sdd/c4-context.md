# C4 — Nível 1: Contexto

> Gerado pelo Arquiteto em 2026-09-15 · Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA

## Diagrama

```mermaid
C4Context
    title joystick-AI — Contexto

    Person(sofa, "Programador de sofá", "Conduz sessões com agentes de IA a ~3 m da TV, só com o DualSense")

    System(joy, "joystick-AI", "App agente para macOS: controle como mouse, atalhos configuráveis, paleta de comandos e editor")

    System_Ext(ds, "DualSense (PS5)", "Controle por USB ou Bluetooth")
    System_Ext(macos, "macOS", "GameController, IOKit HID, CGEvent, TCC, WindowServer, preferências")
    System_Ext(apps, "Aplicativos em foco", "Terminal com Claude Code, VS Code, navegador")
    System_Ext(raycast, "Raycast", "Transcritor de ditado acionado por ⌘M")
    System_Ext(fs, "Sistema de arquivos do usuário", "config.json, logs JSONL, resultados da tela de alvos")
    Person(dev, "Avaliador da PoC", "Mesmo usuário, analisando logs com poc-tools")

    Rel(sofa, ds, "Aperta botões, move analógicos e o touchpad")
    Rel(ds, macos, "Relatórios HID", "USB / Bluetooth")
    Rel(macos, joy, "Eventos do controle em segundo plano", "GameController, IOHIDManager")
    Rel(joy, macos, "Eventos sintéticos de mouse, rolagem e teclado", "CGEvent em .cghidEventTap")
    Rel(macos, apps, "Entrega os eventos como se fossem hardware")
    Rel(joy, raycast, "Aciona o ditado", "atalho ⌘M injetado")
    Rel(raycast, apps, "Cola o texto transcrito")
    Rel(joy, fs, "Lê, observa e grava configuração; escreve logs e resultados", "JSON, JSONL")
    Rel(sofa, joy, "Edita atalhos e paleta na TV", "Editor e barra de menus")
    Rel(dev, fs, "Analisa logs e rodadas", "poc-tools")
```

## Atores e sistemas

| Elemento | Tipo | Papel | Confiança |
|----------|------|-------|-----------|
| Programador de sofá | Pessoa | Único usuário; opera tudo pelo controle, inclusive o editor (`personas.md`) | 🟢 |
| Avaliador da PoC | Pessoa | O mesmo usuário em outro papel: roda os portões manuais e o `poc-tools` | 🟢 |
| DualSense | Hardware externo | Fonte de entrada; 18 botões, 2 analógicos, touchpad de 2 dedos | 🟢 |
| macOS | Plataforma | Entrega o controle, recebe os eventos sintéticos e controla permissões (TCC) | 🟢 |
| Aplicativos em foco | Sistemas externos | Destino dos eventos; o app não se integra a nenhum por API | 🟢 |
| Raycast | Sistema externo | Transcrição de voz; integração só por atalho de teclado configurado pelo usuário | 🟢 |
| Sistema de arquivos | Armazenamento | Único "banco de dados": três locais fixos em `~` | 🟢 |

## Fronteiras

- 🟢 Sem rede: nenhum uso de `URLSession`, sockets ou serviços remotos.
- 🟢 Sem API pública: o app não expõe porta, esquema de URL nem serviço XPC.
- 🟢 Integração com aplicativos só por eventos de entrada; o app não sabe qual aplicativo recebe os eventos, exceto o que guarda para devolver o foco ao fechar o editor.
