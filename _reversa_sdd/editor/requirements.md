# Editor de atalhos (editor)

> Unit do módulo `editor` · Gerado pelo Redator em 2026-09-15 · Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA

## Visão Geral

Janela em escala de TV para editar camadas, ações, modificadores e a lista da paleta, operável do sofá pelo ponteiro do controle e, na mesa, pelo teclado. As regras ficam num rascunho puro (`EditorDraft`), validado pelas mesmas regras da leitura do arquivo; a interface SwiftUI e a janela AppKit cuidam de seleção, identificação pelo controle, gravação, conflitos e ativação da janela. 🟢

## Responsabilidades

- Abrir pelo ícone da barra de menus, pelo alerta de configuração inválida e pela entrada fixa da paleta. 🟢
- Mostrar a figura do controle com a ação resumida de cada botão na camada escolhida. 🟢
- Editar ação, modificador e teclas mantidas de cada botão, por camada. 🟢
- Montar ou gravar acordes. 🟢
- Editar itens da paleta: texto, rótulo, Enter, inclusão, remoção e reordenação. 🟢
- Bloquear a gravação enquanto houver problema e avisar quando nada abre a paleta. 🟢
- Gravar, descartar e restaurar padrões, com confirmação de `.bak` quando o arquivo está corrompido. 🟢
- Tratar alterações externas do arquivo durante a edição. 🟢
- Identificar botões pressionando-os no controle. 🟢
- Ativar a janela mesmo quando o macOS recusa a ativação pedida pelo controle, e devolver o foco ao fechar. 🟢

## Regras de Negócio

### Rascunho

- RN-ED-01: O rascunho parte da configuração vigente (base) e está sujo quando difere dela; desfazer as mudanças volta a limpo. 🟢
- RN-ED-02: Problemas são os de `ShortcutConfigValidation.validate` sobre o rascunho, convertidos em alvo: gatilho (camada, botão), modificador, item da paleta ou paleta inteira. 🟢
- RN-ED-03: "Salvar" só é possível com rascunho sujo e sem problemas. 🟢
- RN-ED-04: Aviso não bloqueante `noPaletteTrigger` quando nenhum botão que não é modificador nem de apontamento tem `openPalette` em alguma camada. 🟢
- RN-ED-05: Camadas editáveis: a base e uma por modificador, na ordem de `ButtonID`. 🟢
- RN-ED-06: R1, R2 e clique do touchpad recusam ação e marcação de modificador ("R1, R2 e o clique do touchpad são cliques fixos."). 🟢
- RN-ED-07: Atribuir `nil` volta a herdar da base (na base, equivale a "nenhuma" por ausência); camada que fica vazia sai do documento. 🟢
- RN-ED-08: Marcar um botão como modificador remove dele a "nenhuma" explícita em todas as camadas e lembra de onde a tirou; ações reais permanecem e aparecem como problema `modifierHasAction`. 🟢
- RN-ED-09: Desmarcar remove o modificador e a camada dele com as ações próprias; devolve a "nenhuma" lembrada às camadas que ainda existem e não ganharam ação para o botão. 🟢
- RN-ED-10: Texto de ação ou item com quebra de linha ou acima de 1.000 caracteres é recusado na digitação; texto vazio é aceito e aparece como problema. Rótulo com quebra de linha ou acima de 80 caracteres é recusado. 🟢
- RN-ED-11: Paleta: incluir além de 50 itens é recusado; remover o último item é recusado; item novo nasce vazio (sem texto, sem Enter, sem rótulo). 🟢
- RN-ED-12: Operação recusada mostra o motivo numa faixa e não altera o rascunho. 🟢

### Interface

- RN-ED-13: Escala de TV: corpo 32 pt, título 40 pt, alvo mínimo de clique 60 pt, janela mínima 1.400 × 800 pt, rolagem só vertical. 🟢
- RN-ED-14: A figura mostra os 18 botões nas posições físicas; botões fixos e modificadores em cinza, herdados esmaecidos (opacidade 0,55), com problema em vermelho, selecionado com contorno de destaque. Resumo: cliques "clique esquerdo, fixo"/"clique direito, fixo", "modificador ⌘", acorde por símbolos, nome do atalho de sistema, texto entre aspas truncado em 24 caracteres (+ " + Enter"), "abrir paleta", "nenhuma", sufixo " (herdado)". 🟢
- RN-ED-15: Tipos de ação no painel: Acorde, Atalho de sistema, Texto, Abrir paleta, Nenhuma e, só em camada de modificador, Herdar da base. Ao trocar de tipo, aproveita a ação vigente do mesmo tipo; acorde aproveitado começa sem repetição; sem aproveitamento, Return, Mission Control ou texto vazio. 🟢
- RN-ED-16: Botão modificador com ação própria na camada exibe o comando "Remover a ação de X nesta camada". Desmarcar modificador pede confirmação ("Remover a camada X e as ações dela"). 🟢
- RN-ED-17: Acorde montado pelo ponteiro (quatro modificadores, grupo de teclas, grade do catálogo) ou gravado pelo teclado; ⌘Tab e ⌘Space só pela montagem, pois o sistema os toma antes. 🟢
- RN-ED-18: A gravação pelo teclado só escuta enquanto ativa e só eventos da janela em foco, por monitor local (nunca global); descarta teclas injetadas pelo próprio app; ignora teclas fora do catálogo sem encerrar; o primeiro acorde com tecla do catálogo encerra a gravação. 🟢
- RN-ED-19: Rodapé: "Salvar" (habilitado por RN-ED-03), "Descartar alterações" (habilitado com rascunho sujo), contagem de problemas ou "Alterações não salvas", "Restaurar padrão" com confirmação "Restaurar e gravar". 🟢
- RN-ED-20: Menu principal só com "Editar" (Desfazer, Refazer, Recortar, Copiar, Colar, Selecionar tudo) e sem "Sair", para que ⌘V e demais atalhos cheguem aos campos e ⌘Q não encerre o app. 🟢

### Gravação e conflito

- RN-ED-21: Gravado com sucesso, a vigente vira a base e o rascunho fica limpo; a camada selecionada que deixou de existir volta à base. 🟢
- RN-ED-22: Arquivo corrompido: a gravação mostra a faixa "O arquivo atual tem erro de sintaxe na linha N…" com "Cancelar" e "Copiar e gravar". 🟢
- RN-ED-23: "Copiar e gravar" grava sem reverificar se o rascunho ainda pode ser salvo. 🟢 Defeito a corrigir: deve respeitar `canSave` (respondida em 2026-09-15, `questions.md` Pergunta 3).
- RN-ED-24: Falha de gravação mostra "Não foi possível gravar." com caminho e erro do sistema; o rascunho continua. 🟢
- RN-ED-25: "Restaurar padrão" grava e aplica os padrões diretamente pelo `ConfigStore`, sem passar pelo rascunho. 🟢
- RN-ED-26: Releitura externa aceita com rascunho limpo atualiza o rascunho em silêncio; com rascunho sujo abre a faixa de conflito e registra `editor.conflict { choice: pending }`. "Recarregar do arquivo" descarta (`reload`); "Manter minhas alterações" troca a base e mantém o rascunho (`keep`). 🟢
- RN-ED-27: Releitura externa recusada mostra a faixa "O arquivo de configuração tem erro na linha N: motivo. A configuração vigente foi mantida.", com "Ocultar", sem tocar no rascunho. 🟢
- RN-ED-28: Gravações do próprio editor e restaurações não abrem conflito. 🟢
- RN-ED-29: A cada abertura: rascunho limpo é rebaseado na vigente; estado inválido abre a faixa de arquivo inválido; mensagens de operação, gravação e `.bak` são limpas; o conflito de alteração externa pendente é mantido. 🟢

### Janela e identificação

- RN-ED-30: Fechar com rascunho sujo abre a folha "Salvar as alterações dos atalhos?" com Salvar, Descartar e Cancelar; Salvar que não grava mantém a janela aberta. `editor.closed { outcome: clean | saved | discarded }`. 🟢
- RN-ED-31: Modo de identificação: ligado, fecha a paleta e solta os atalhos; botões que não são de apontamento, pressionados de fato (não sintéticos), selecionam o botão na aba Atalhos e não produzem ação; R1, R2 e touchpad continuam clicando. Desliga ao fechar a janela, ao abrir a folha de fechamento e quando a janela perde o foco. `editor.identify { on }`. 🟢
- RN-ED-32: Abertura (emenda E003): guarda o app em primeiro plano (se não for o próprio); pede ativação; se o app não ficou ativo, a janela sobe ao nível flutuante; 150 ms depois, se a janela não está ativa, clique sintético marcado no centro da barra de título; 500 ms depois, se ainda não está ativa, `editor.activation_failed`. Ao ativar o app, a janela volta ao nível normal. 🟢
- RN-ED-33: Ao fechar, devolve a ativação ao app guardado, se ele ainda estiver em execução. 🟢
- RN-ED-34: `editor.opened { source: menu | palette | alert }` a cada abertura. 🟢

## Requisitos Funcionais

| ID | Requisito | Prioridade | Critério de Aceite |
|----|-----------|-----------|-------------------|
| RF-ED-01 | Abrir por menu, alerta e paleta | Must | As três origens aparecem em `editor.opened` |
| RF-ED-02 | Figura com ação resumida por camada | Must | Camada L2 mostra "mesa à esquerda" em ← |
| RF-ED-03 | Editar ação por botão e camada | Must | Trocar ✕ na base para Texto e salvar muda o comportamento |
| RF-ED-04 | Marcar e desmarcar modificadores | Must | Marcar △ cria a camada △ no seletor |
| RF-ED-05 | Montar e gravar acordes | Must | Montar ⌘⇧T só com o ponteiro |
| RF-ED-06 | Editar a paleta | Must | Incluir, reordenar e remover itens refletem na paleta após salvar |
| RF-ED-07 | Bloquear gravação com problemas | Must | Texto vazio desabilita Salvar e mostra o motivo |
| RF-ED-08 | Tratar conflito externo | Must | Editar o arquivo com rascunho sujo mostra a faixa de conflito |
| RF-ED-09 | Identificar pelo controle | Should | Com identificação ligada, pressionar △ seleciona △ |
| RF-ED-10 | Ativar a janela aberta pelo controle | Must | Aberto pela paleta, o editor recebe teclado sem clique manual |
| RF-ED-11 | Devolver o foco ao fechar | Should | Fechar volta ao Terminal que estava em uso |
| RF-ED-12 | Colar e ditar nos campos | Should | ⌘V e o ditado do Raycast inserem texto no campo |
| RF-ED-13 | Restaurar padrões | Should | Confirmar "Restaurar e gravar" regrava os padrões |

## Requisitos Não Funcionais

| Tipo | Requisito inferido | Evidência no código | Confiança |
|------|--------------------|---------------------|-----------|
| Usabilidade | Legível e clicável a 3 m pelo ponteiro | `EditorMetrics.swift:3-17` | 🟢 |
| Compatibilidade | Cabe numa tela de 900 pt de altura | `EditorMetrics.swift:7` | 🟢 |
| Privacidade | Sem monitor global de teclado | `KeyCaptureField.swift:7-10` | 🟢 |
| Testabilidade | Regras em `struct` pura com 18 testes | `EditorDraftTests.swift` | 🟢 |
| Concorrência | Modelo e janela só na main | `EditorViewModel.swift:5`, `EditorWindowController.swift:5` | 🟢 |

## Critérios de Aceitação

```gherkin
Dado o mapeamento padrão no rascunho
Quando △ é marcado como modificador na base
Então △ some das ações "nenhuma" da camada Options
E as ações de △ na base (Tab), em L1 (⇧Tab) e em L2 (próxima janela) aparecem como problema modifierHasAction
E Salvar fica desabilitado

Dado △ marcado como modificador no passo anterior
Quando △ é desmarcado
Então a camada △ desaparece e a "nenhuma" de △ volta à camada Options

Dado a camada L1 selecionada e ○ sem ação própria
Quando o painel de ○ é exibido
Então o tipo selecionado é "Herdar da base" e o texto diz "Herdado da base: Esc."

Dado a aba Paleta com 50 itens
Quando "Incluir no fim" é escolhido
Então a faixa mostra "A paleta aceita no máximo 50 itens." e a lista não muda

Dado o rascunho sujo
Quando o arquivo é alterado por outro programa e a releitura é aceita
Então a faixa de conflito aparece e editor.conflict registra choice pending

Dado a gravação pelo teclado ativa
Quando o usuário pressiona ⌘⇧T
Então o acorde vira ⌘⇧T e a gravação termina

Dado o editor aberto pela paleta com o Terminal em primeiro plano
Quando o macOS recusa a ativação
Então a janela aparece por cima, recebe o clique sintético na barra de título e fica ativa
E ao fechar o Terminal volta ao primeiro plano
```

## Prioridade (MoSCoW)

| Requisito | MoSCoW | Justificativa |
|-----------|--------|---------------|
| Rascunho, validação, gravação | Must | Núcleo da feature 003 |
| Figura e painel operáveis pelo ponteiro | Must | Uso no sofá |
| Ativação E003 | Must | Sem ela, a janela fica atrás do terminal |
| Conflito externo | Must | Arquivo nos dotfiles pode mudar por fora |
| Identificação pelo controle | Should | Conforto |
| Gravação de acorde pelo teclado | Should | Uso na mesa |
| Arrastar para reordenar | Could | Há botões ↑/↓ |

## Rastreabilidade de Código

| Arquivo | Função / Classe | Cobertura |
|---------|-----------------|-----------|
| `Sources/JoystickCore/Config/EditorDraft.swift` | `EditorTarget`, `EditorIssue`, `EditorWarning`, `EditorOperationError`, `EditorDraft` | 🟢 |
| `Sources/JoystickAIPoC/Editor/EditorViewModel.swift` | `EditorViewModel` | 🟢 |
| `Sources/JoystickAIPoC/Editor/EditorWindowController.swift` | `EditorWindowController` | 🟢 |
| `Sources/JoystickAIPoC/Editor/EditorRootView.swift` | `EditorRootView` | 🟢 |
| `Sources/JoystickAIPoC/Editor/ShortcutsTab.swift` | `ShortcutsTab` | 🟢 |
| `Sources/JoystickAIPoC/Editor/ControllerFigureView.swift` | `ControllerFigureView` | 🟢 |
| `Sources/JoystickAIPoC/Editor/ActionPanel.swift` | `ActionPanel` | 🟢 |
| `Sources/JoystickAIPoC/Editor/ChordEditor.swift` | `ChordEditor` | 🟢 |
| `Sources/JoystickAIPoC/Editor/KeyCaptureField.swift` | `KeyCaptureField`, `KeyCaptureView` | 🟢 |
| `Sources/JoystickAIPoC/Editor/PaletteTab.swift` | `PaletteTab`, `RowDropDelegate` | 🟢 |
| `Sources/JoystickAIPoC/Editor/EditorBanners.swift` | `EditorBanners` | 🟢 |
| `Sources/JoystickAIPoC/Editor/EditorLabels.swift` | `ButtonID.displayName`, `EditorLabels` | 🟢 |
| `Sources/JoystickAIPoC/Editor/EditorMetrics.swift` | `EditorMetrics`, `TVButtonStyle`, `TVToggleStyle`, `TVFieldModifier` | 🟢 |
| `Sources/JoystickAIPoC/App/EditMenu.swift` | `EditMenu` | 🟢 |
