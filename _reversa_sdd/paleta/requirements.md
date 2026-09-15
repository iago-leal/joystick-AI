# Paleta de comandos (palette)

> Unit do módulo `palette` · Gerado pelo Redator em 2026-09-15 · Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA

## Visão Geral

Lista flutuante de textos prontos (comandos do Claude Code e do Reversa), operada pelo controle e legível a 3 m. Confirmar um item digita o texto no aplicativo em foco, sem tirar esse foco. A última entrada, fixa, abre o editor de atalhos. A decisão é pura (`PaletteMachine`); a execução e o desenho ficam no app (`PaletteActions`, `PalettePanel`). 🟢

## Responsabilidades

- Abrir por ação `openPalette` (PS no padrão) e fechar por ○, PS, confirmação ou evento externo. 🟢
- Navegar com ↑/↓ em lista circular, com repetição. 🟢
- Digitar o item confirmado, com Enter opcional após atraso configurável. 🟢
- Lembrar o último item confirmado enquanto o app estiver aberto. 🟢
- Oferecer a entrada fixa "Editar atalhos". 🟢
- Fechar por inatividade de 60 s. 🟢
- Exibir painel não ativador, transparente ao mouse, no centro da tela do cursor. 🟢
- Registrar abertura, confirmação, fechamento e bloqueio. 🟢

## Regras de Negócio

- RN-PA-01: Com a paleta fechada, só `open()` produz efeito. 🟢
- RN-PA-02: Abrir com a paleta já aberta não faz nada; abrir durante a tela de alvos é recusado e registra `palette.blocked { reason: targets }`. 🟢
- RN-PA-03: Ao abrir, a seleção é o último item confirmado ou, sem ele, o primeiro. 🟢
- RN-PA-04: As entradas são os itens configurados (1 a 50) mais "Editar atalhos" no índice `items.count`; ↑ e ↓ andam em círculo sobre todas. 🟢
- RN-PA-05: ↑ ou ↓ move um passo e inicia repetição (400 ms, depois 50 ms); a repetição para ao soltar o mesmo direcional, ao pressionar outro direcional (que a reinicia) ou ao fechar. 🟢
- RN-PA-06: ✕ num item fecha a paleta, grava o item como último confirmado, registra `palette.confirmed { index (base 1), enter }` e digita o texto. 🟢
- RN-PA-07: ✕ em "Editar atalhos" fecha a paleta e abre o editor, sem digitar, sem `palette.confirmed` e sem alterar o último confirmado. 🟢
- RN-PA-08: ○ e PS fecham sem confirmar (`palette.closed { reason: circle | ps }`); os demais botões não afetam a paleta. 🟢
- RN-PA-09: Fechamentos externos: `disconnected` (controle), `injection_suspended` (Acessibilidade revogada), `idle` (60 s sem entrada), `config_changed` (configuração aplicada), `identify` (modo de identificação do editor). 🟢
- RN-PA-10: Qualquer botão, eixo ou toque com a paleta aberta adia o fechamento por inatividade; a verificação ocorre a cada 1 s. 🟢
- RN-PA-11: Com a paleta aberta, os botões ainda chegam aos cliques (R1, R2, touchpad) e os eixos e toques ao movimento; os atalhos não recebem botões. 🟢
- RN-PA-12: Digitação: texto por Unicode sem Enter; se o item pede Enter, Return logo em seguida com atraso 0, ou após `--palette-enter-delay-ms` (0 a 500). Argumento inválido registra `palette.invalid_args` e usa 0. 🟢
- RN-PA-13: A lista padrão tem 17 itens, nenhum com Enter e nenhum com rótulo: `CONTINUAR`, `/reversa-forward`, `/reversa-requirements `, `/reversa-clarify`, `/reversa-plan`, `/reversa-to-do`, `/reversa-coding`, `/reversa-add `, `/reversa-audit`, `/reversa-quality`, `/reversa-sync`, `/reversa-resume`, `/reversa-debugger `, `/reversa`, `/clear`, `/compact`, `/resume`. 🟢
- RN-PA-14: Exibição de cada linha: o rótulo, se houver; sem rótulo, o texto, e texto terminado em espaço aparece sem o espaço e com o sufixo " …". 🟢
- RN-PA-15: Configuração nova: fecha a paleta aberta com `config_changed`, recria a máquina sem último confirmado e troca a lista do painel. 🟢
- RN-PA-16: O painel não ativa o app, não recebe foco nem cliques, aparece em todas as mesas e sobre tela cheia, no nível da barra de status. 🟢
- RN-PA-17: Posição e tamanho são calculados só na abertura, na área visível da tela que contém o cursor, com margem de 24 pt; sem espaço para todas as linhas, mostra as que cabem e rola até a seleção. 🟢
- RN-PA-18: Confirmação e abertura do editor não registram `palette.closed`; nos logs há 74 aberturas para 19 fechamentos e 24 confirmações. 🟡 (`domain.md` DV-07)

## Requisitos Funcionais

| ID | Requisito | Prioridade | Critério de Aceite |
|----|-----------|-----------|-------------------|
| RF-PA-01 | Abrir e fechar pelo controle | Must | PS abre; ○ ou PS fecham |
| RF-PA-02 | Navegar em círculo com repetição | Must | ↑ no primeiro item vai a "Editar atalhos"; ↓ segurado percorre a lista |
| RF-PA-03 | Digitar o item no app em foco | Must | Confirmar `/clear` no Terminal deixa `/clear` na linha, sem Enter |
| RF-PA-04 | Enviar Enter quando o item pede | Must | Item com `pressEnter` executa o comando |
| RF-PA-05 | Lembrar o último confirmado | Should | Reabrir começa no último item usado |
| RF-PA-06 | Abrir o editor pela entrada fixa | Must | ✕ em "Editar atalhos" abre o editor em foco |
| RF-PA-07 | Fechar por eventos externos | Must | Desconectar o controle fecha a paleta |
| RF-PA-08 | Fechar por inatividade | Should | 60 s sem entrada fecham a paleta |
| RF-PA-09 | Manter o foco do app em uso | Must | O cursor de texto do Terminal continua ativo com a paleta aberta |
| RF-PA-10 | Legibilidade a 3 m | Must | Fonte monoespaçada de 26 pt, linha de 40 pt |
| RF-PA-11 | Bloquear durante a tela de alvos | Should | PS na tela de alvos não abre a paleta |

## Requisitos Não Funcionais

| Tipo | Requisito inferido | Evidência no código | Confiança |
|------|--------------------|---------------------|-----------|
| Performance | Painel criado oculto na abertura do app para abrir sem atraso | `AppDelegate.swift:66,71` | 🟢 |
| Usabilidade | Seleção por cor e por marcador ▶ | `PalettePanel.swift:158-172` | 🟢 |
| Privacidade | Log sem texto de item | `LogEventCatalog.swift:237-251` | 🟢 |
| Concorrência | Estado na fila `input`; painel recebe cópias na main | `PaletteActions.swift:6`, D-11 | 🟢 |

## Critérios de Aceitação

```gherkin
Dado a lista padrão e nenhum item confirmado
Quando a paleta é aberta
Então o primeiro item está selecionado e palette.opened registra selection 1

Dado a paleta aberta no item 1
Quando ↑ é pressionado
Então a seleção vai para "Editar atalhos" (índice 17)

Dado a paleta aberta no item 3
Quando ✕ é pressionado
Então a paleta fecha, palette.confirmed registra index 3 e enter false
E "/reversa-requirements " é digitado no aplicativo em foco

Dado o item 3 confirmado antes
Quando a paleta é aberta de novo
Então a seleção começa no item 3

Dado a paleta aberta em "Editar atalhos"
Quando ✕ é pressionado
Então a paleta fecha e o editor abre, sem digitação e sem palette.confirmed

Dado a paleta aberta e ↓ pressionado
Quando ↓ continua pressionado e ocorrem 10 disparos de repetição
Então a seleção avançou 1 + 10 passos

Dado a paleta aberta
Quando passam 60 s sem entrada do controle
Então palette.closed registra reason idle

Dado a tela de alvos aberta
Quando PS é pressionado
Então a paleta não abre e palette.blocked é registrado
```

## Prioridade (MoSCoW)

| Requisito | MoSCoW | Justificativa |
|-----------|--------|---------------|
| Abrir, navegar, confirmar, fechar | Must | Núcleo da feature 002 |
| Painel não ativador | Must | Digitar exige o foco no app de destino |
| Entrada fixa do editor | Must | Único acesso ao editor pelo controle |
| Último confirmado, inatividade | Should | Conforto |
| Bloqueio na tela de alvos | Should | Evita contaminar medições |

## Rastreabilidade de Código

| Arquivo | Função / Classe | Cobertura |
|---------|-----------------|-----------|
| `Sources/JoystickCore/Palette/CommandPalette.swift` | `PaletteItem`, `PaletteDefaults`, `PaletteSnapshot`, `PaletteEffect`, `PaletteCloseReason`, `PaletteMachine` | 🟢 |
| `Sources/JoystickAIPoC/Palette/PaletteActions.swift` | `PaletteActions` | 🟢 |
| `Sources/JoystickAIPoC/Palette/PalettePanel.swift` | `PalettePanel`, `PaletteView` | 🟢 |
