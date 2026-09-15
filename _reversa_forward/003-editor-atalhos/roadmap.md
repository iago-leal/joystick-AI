# Roadmap: Editor de atalhos e comandos

> Identificador: `003-editor-atalhos`
> Data: `2026-09-14`
> Requirements: `_reversa_forward/003-editor-atalhos/requirements.md`
> Confidência: 🟢 CONFIRMADO, 🟡 INFERIDO, 🔴 LACUNA

> **Nota de confidência:** recebem 🟢 as decisões apoiadas no código entregue pelas features 001 e 002, inspecionado em 2026-09-14, ou em decisão do usuário. Recebem 🟡 as que dependem de comportamento do macOS, do SwiftUI ou do Raycast ainda não observado neste projeto. Recebem 🔴 as que dependem de uma sonda da Fase 0.

## 1. Resumo da abordagem

O delta tem três camadas. Em `JoystickCore`, o mapeamento fixo do `ShortcutMapper` dá lugar a um modelo de configuração (`ShortcutConfig` e itens da paleta), com padrões que reproduzem o protótipo, validação que aponta caminho e linha, fusão com as seções que o app não gerencia e um rascunho de edição puro (`EditorDraft`) que concentra as regras do editor e seus limites; o mapeador passa a resolver camadas pela ordem em que os modificadores foram segurados. No app, um `ConfigStore` na main thread lê o arquivo ao iniciar, observa o diretório sem varredura, valida, grava de forma atômica e publica cada configuração vigente à fila `input`, onde atalhos e paleta a aplicam soltando antes as teclas mantidas. A interface tem três partes: um ícone na barra de menus com alerta de configuração inválida, o item fixo "Editar atalhos" na paleta e uma janela de editor em SwiftUI, na escala de TV, operável pelo ponteiro do controle, com gravação de acorde pelo teclado ou montagem por seleção e modo de identificação alimentado pelo `InputRouter`. Cinco sondas iniciais validam ativação da janela, captura de teclado, ditado nos campos, observação do arquivo e legibilidade.

## 2. Princípios aplicados

Não existe `.reversa/principles.md`; não há princípio a respeitar nem conflito a registrar. As restrições equivalentes vêm das specs e das features anteriores:

| Restrição | Como a feature se relaciona | Status |
|-----------|------------------------------|--------|
| Lógica pura em `JoystickCore`, só `Foundation` (001 D-03) | Modelo, padrões, validação, fusão, localização de linha, resolução de camadas e rascunho do editor ficam em `JoystickCore/Config` e `JoystickCore/Shortcuts`, com testes. SwiftUI e AppKit só no alvo do app. | respeita |
| `JoystickAIPoC` em modo Swift 5, isolamento por filas explícitas (001 D-22) | Configuração e editor na main thread; mapeador e paleta na fila `input`; a ponte é cópia imutável por `queue.async`. | respeita |
| Log sem teclas nem conteúdo (`action-mapping` §12, 002 RN-07, 003 RN-14) | Eventos novos levam botão, camada, tipo de ação, contagens, caminho e linha; mensagens de validação citam o caminho e a regra, nunca o valor. | respeita |
| Paleta nunca rouba o foco (002 RN-02) | O painel da paleta não muda; só o editor, janela à parte, se torna ativo, e só quando pedido. | respeita |
| Regra de escrita do Reversa (`CLAUDE.md`) | `.reversa/reversa-config.json` está com `allowLegacyEdits: true` e `allowedPaths` vazio, isto é, liberação irrestrita. O `/reversa-coding` deve avisar uma vez. | observação |

## 3. Decisões técnicas

### 3.1 Modelo e validação (`JoystickCore`)

| ID | Decisão | Justificativa | Alternativas descartadas | Confidência |
|----|---------|----------------|--------------------------|-------------|
| D-01 | Arquivo continua em `~/.config/joystick-ai/config.json`, com duas seções novas ao lado de `pointer`: `shortcuts` (`version`, `modifiers`, `layers`) e `palette` (`version`, `items`). Numa camada de modificador, botão ausente herda da base; na base, botão ausente vale "nenhuma". Formato em `interfaces/config-file.md`. | Mantém `action-mapping` §15 (local do arquivo) e o contrato `pointer` da 001; a ausência como herança dá RN-02 sem tipo extra no arquivo e deixa o JSON escrito à mão mais curto. | Arquivo separado para atalhos (duas fontes a observar e versionar); lista plana de `Mapping` como em `action-mapping` §9 (não expressa camada nem herança). | 🟢 |
| D-02 | Tipos em `Sources/JoystickCore/Config/ShortcutConfig.swift`: `ShortcutConfig { modifiers: [ButtonID: Set<KeyModifier>], layers: [ButtonID?: [ButtonID: TriggerAction]] }` (chave `nil` é a base), `TriggerAction` (`chord(KeyChord, repeats)`, `systemShortcut(SystemShortcut)`, `text(String, pressEnter)`, `openPalette`, `none`) e `PaletteItem` com `label`. Detalhe em `data-delta.md`. | Tipos de valor `Sendable`, comparáveis em teste e copiáveis entre filas. | Guardar `JSONValue` bruto e interpretar no uso (erro só aparece ao pressionar). | 🟢 |
| D-03 | `KeyCatalog` em `Sources/JoystickCore/Shortcuts/KeyCatalog.swift`: tabela fixa nome ↔ tecla virtual (`kVK_ANSI_*` e teclas especiais: letras, dígitos, pontuação por nome, Return, Tab, Space, Delete, Forward Delete, Esc, setas, Home, End, Page Up, Page Down, F1 a F12), com rótulo de exibição e grupo. `SystemShortcut` ganha nome estável (`spaceLeft`, `spaceRight`, `missionControl`, `applicationWindows`, `nextWindow`). | O arquivo guarda nomes legíveis; a mesma tabela alimenta a lista de teclas do editor (D-19) e recusa teclas sem nome ao gravar. Tecla virtual é posição física, o que mantém Command+Z no ABNT2. | Guardar código numérico (ilegível à mão); guardar caractere (depende do *layout*). | 🟢 |
| D-04 | `ShortcutDefaults` em `Sources/JoystickCore/Config/ShortcutDefaults.swift` reproduz a tabela de RN-11, e `CommandPalette.items` vira `PaletteDefaults.items`, com os 17 itens sem Enter e rótulo vazio. Um teste de equivalência percorre os 18 botões na base e com L1, L2 e Options segurados isoladamente e compara o novo mapeador com as saídas registradas do protótipo. | RF-01 exige comportamento idêntico sem arquivo; o teste congela a tabela atual antes da remoção do `switch`. | Ler o padrão de um JSON embutido no pacote (sem recursos no alvo de biblioteca hoje; erro de digitação só em tempo de execução). | 🟢 |
| D-05 | `ShortcutConfigValidation.decode(root: JSONValue) -> Result<ShortcutsDocument, [ShortcutIssue]>`: seção ausente usa o padrão; qualquer erro em `shortcuts` ou `palette` invalida as duas (RN-08). Regras: versão 1; modificador não pode ser R1, R2 nem clique do touchpad; camada só para botão modificador; botão modificador e de apontamento fora de toda camada; tecla e atalho de sistema conhecidos; texto e rótulo de uma linha, texto com 1 a 1.000 caracteres e rótulo com até 80; paleta com 1 a 50 itens. `ShortcutIssue { path, rule }`, com `path` no formato `shortcuts.layers.l2.dpadLeft` e mensagem sem valor. | Testável sem arquivo; o caminho identifica o gatilho no editor e no log sem expor conteúdo (RN-14). | Validar campo a campo com padrão por campo, como `pointer` (violaria RN-08: meia configuração vigente). | 🟢 |
| D-06 | `ConfigLineLocator` em `Sources/JoystickCore/Config/ConfigLineLocator.swift`: varredura léxica do texto que devolve a linha de início do valor de um caminho JSON; usada só quando a validação falha. Erro de sintaxe continua com a linha de `ConfigLoader.describe`. | RF-04 e RF-20 pedem a linha também para erro de conteúdo, e o `JSONDecoder` não informa posição. Rodar só na falha mantém a leitura normal barata. | Analisador JSON próprio no lugar do `JSONDecoder` (substitui código que já funciona); erro de conteúdo sem linha (descumpre RF-04). | 🟡 |
| D-07 | `ConfigDocument.merge(existing: JSONValue?, shortcuts:, palette:) -> Data`: parte do objeto raiz lido no instante da gravação, substitui só `shortcuts` e `palette` e serializa com `JSONEncoder` em `[.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]`. Ausente, cria o objeto com as duas seções. | RN-10 e RF-05: `pointer` e seções desconhecidas preservadas por valor; ler no momento da gravação incorpora o que outro programa gravou antes. A ordem das chaves pode mudar, lacuna já aceita em `requirements.md` §10. | Reescrever só o trecho textual das seções (frágil diante de formatação manual). | 🟢 |
| D-08 | `ConfigLoader` passa a decodificar a raiz uma vez e entregá-la a `PointerSettingsValidation` e a `ShortcutConfigValidation`; o resultado ganha `shortcuts: ShortcutsDocument` e `shortcutIssues`. O comportamento de `pointer` e os eventos `config.*` da 001 não mudam. | Uma leitura para as duas finalidades ao iniciar; o contrato `config-pointer.md` segue válido para `pointer`. | Segunda leitura independente do arquivo (duas visões do mesmo instante podem divergir). | 🟢 |

### 3.2 Execução dos atalhos

| ID | Decisão | Justificativa | Alternativas descartadas | Confidência |
|----|---------|----------------|--------------------------|-------------|
| D-09 | `ShortcutMapper` recebe `ShortcutConfig` na criação e perde o `switch` fixo. Guarda `modifierOrder: [ButtonID]` na ordem de pressionar; a camada é a do primeiro da lista; a ação é `layers[camada][botão] ?? layers[base][botão] ?? none`, resolvida no pressionar e guardada por botão até o soltar (RN-01, RN-03). R1, R2 e clique do touchpad devolvem `[]` (os cliques seguem em `ButtonActions`). | Mesmo contrato de `press`, `release` e `releaseAll`, com as regras novas num só lugar e testáveis. | Resolver a camada no soltar (quebra EC-04); prioridade fixa por botão (rejeitada no esclarecimento 3). | 🟢 |
| D-10 | Botão modificador emite `modifierDown` de cada tecla de `modifiers[botão]` ao pressionar e `modifierUp` ao soltar, qualquer que seja a camada vigente. | Generaliza Options mantendo Command; a contagem por tecla do `KeyboardInjector` já tolera sobreposição. | Manter as teclas só quando a camada do botão vale (Command cairia ao segurar Options depois de L1, mudando o protótipo). | 🟢 |
| D-11 | Atalho de sistema sai do mapeador como `systemDown(SystemShortcut)` e `systemUp(SystemShortcut)`; `ShortcutActions` lê `AppleSymbolicHotKeys` por `CFPreferencesCopyAppValue` no pressionar e guarda o acorde usado para o soltar. | RN-07 pede o acorde do momento do uso; hoje ele é lido uma vez, na criação de `ShortcutActions`. A leitura passa pelo *cache* do `cfprefsd`. | Ler só ao aplicar a configuração (alteração nos Ajustes fica sem efeito até salvar); observar notificação de preferências (sem notificação pública para esse domínio). | 🟡 |
| D-12 | Aplicação na fila `input`, nesta ordem: `PaletteActions.apply(items)` fecha a paleta aberta com o motivo novo `config_changed` e recria a máquina com `lastConfirmed` nulo; `ShortcutActions.apply(config)` interrompe a repetição, executa `releaseAll()` e recria o mapeador. Botões fisicamente segurados na troca são ignorados até serem soltos, como na abertura da paleta (002 D-04). | RN-09 sem tecla presa; índice lembrado pode não existir na lista nova. | Trocar o mapeador mantendo `held` (acorde antigo seria solto com a configuração nova). | 🟢 |
| D-13 | `PaletteMachine` recebe a lista configurada e acrescenta a entrada fixa "Editar atalhos" no fim; confirmá-la produz o efeito `openEditor` em vez de `confirm`, sem `palette.confirmed`. `PaletteView` desenha rótulo ou texto (com o sufixo " …" da 002), separa a entrada fixa por uma linha e trunca textos longos pela largura da tela. | RF-07 e RN-12 sem mudar o fluxo de navegação da 002; o texto de até 1.000 caracteres não pode estourar o painel. | Entrada fixa como `PaletteItem` especial (misturaria digitação e comando interno). | 🟢 |
| D-14 | Gatilho executado registrado como `shortcut.triggered { button, layer, type }` em nível `info`, emitido por `ShortcutActions` ao executar ação diferente de "nenhuma". | RN-14 e RNF de observabilidade; os campos não revelam texto nem acorde. | Nível `debug` (sumiria do uso normal, contra RN-14). | 🟡 |

### 3.3 Arquivo, observação e barra de menus (app)

| ID | Decisão | Justificativa | Alternativas descartadas | Confidência |
|----|---------|----------------|--------------------------|-------------|
| D-15 | `ConfigStore` em `Sources/JoystickAIPoC/Config/ConfigStore.swift`, só na main thread: guarda a configuração vigente, o estado (válida, inválida com `ShortcutIssue` e linha) e os *bytes* da última leitura; publica a vigente à fila `input` (D-12) e o estado à barra de menus e ao editor por observadores. Leitura ao iniciar feita pelo `AppDelegate` antes do controle, como hoje. | Um dono para a configuração; o arquivo tem no máximo 1 MiB, leitura curta na main thread. | Fila própria de configuração (terceira fila a sincronizar com o editor na main thread, sem ganho). | 🟢 |
| D-16 | `ConfigWatcher` com `DispatchSource.makeFileSystemObjectSource` (`.write`, `.rename`, `.delete`) no diretório do arquivo e, se `config.json` for *link* simbólico, também no diretório do destino; sem diretório, observa o ancestral existente mais próximo (`~/.config`, depois `~`) e passa ao filho quando ele surge. Cada evento agenda releitura após 150 ms; *bytes* iguais aos da última leitura não geram aplicação nem aviso. Arquivo removido mantém a vigente e registra `shortcuts.file_removed`. | Editores gravam por troca atômica, que substitui o arquivo e invalida a observação por descritor; observar o diretório cobre esse caso sem varredura (RNF de CPU). A comparação de *bytes* evita reaplicar e acusar conflito após a própria gravação. | Varredura periódica (contra `action-mapping` RNF-02); FSEvents (latência de agrupamento próxima do limite de 1 s e API C mais extensa). | 🔴 |
| D-17 | `ConfigWriter`: resolve *links* simbólicos, lê a raiz atual, funde por D-07 e grava com `Data.write(options: .atomic)` no destino resolvido, criando o diretório com permissão padrão. Se o arquivo atual tiver erro de sintaxe, o editor pede confirmação e o conteúdo antigo é copiado para `config.json.bak` antes da gravação. Erro de escrita volta ao editor com o caminho, sem alterar a vigente. | Gravação interrompida não trunca (RNF de robustez); resolver o *link* mantém o arquivo dentro do repositório de dotfiles; nada escrito à mão se perde sem aviso. | Gravação direta sem arquivo temporário (trunca na falha); gravar sobre o *link* (a troca atômica substituiria o *link* por arquivo comum). | 🟡 |
| D-18 | `StatusMenu` com `NSStatusItem`: símbolo `gamecontroller` como imagem modelo; com configuração inválida, símbolo `exclamationmark.triangle` e, no topo do menu, item "Configuração inválida: linha N" (abre o editor) e separador; depois "Editar atalhos" e "Sair" (`NSApp.terminate`, que já passa pela limpeza de `Lifecycle`). | RF-06 e RF-20 com o menor menu possível; a limpeza de teclas e botões ao sair já existe (001 RF-23). | Menu de estado completo de `app-shell` §8 (Won't nesta feature). | 🟢 |

### 3.4 Editor

| ID | Decisão | Justificativa | Alternativas descartadas | Confidência |
|----|---------|----------------|--------------------------|-------------|
| D-19 | Interface em SwiftUI hospedada em `NSHostingView` dentro de `EditorWindowController` (`NSWindow` redimensionável, fechável, com tamanho mínimo de 1.100 × 720 pt e rolagem interna). Escala de TV por constantes em `EditorMetrics`: texto base de 24 pt, títulos de 30 pt e alvos com pelo menos 44 pt no menor lado, por estilos próprios de botão, alternador e campo. Três abas: Atalhos, Paleta e, no rodapé, Salvar, Descartar e Restaurar padrão. | O editor tem listas, formulários, reordenação e diálogos, em que SwiftUI reduz muito o código em relação ao AppKit puro (adiado para cá em 002 `investigation.md` §3.3); `controlSize` do sistema não chega a 44 pt no macOS 13, por isso os estilos próprios. | AppKit puro com `NSStackView` (volume de código de *layout*); janela sem rolagem (não cabe em telas de 900 pt de altura na escala de TV). | 🟡 |
| D-20 | `EditorDraft` em `Sources/JoystickCore/Config/EditorDraft.swift`, puro: parte da vigente, aplica operações (atribuir ação, marcar e desmarcar modificador com teclas mantidas, incluir, remover, mover para cima e para baixo, editar rótulo, texto e Enter de item, restaurar padrão), expõe `isDirty`, `issues` por alvo (gatilho, modificador, item) e os avisos não bloqueantes (nenhum gatilho abre a paleta). As operações que violam limite (remover o último item, incluir o 51.º, texto com quebra de linha) são recusadas com motivo. `EditorViewModel` (`ObservableObject`, main thread) só adapta o rascunho à interface. | RF-11 a RF-15 testáveis sem interface; a validação do rascunho reutiliza D-05, e "Salvar" fica desabilitado com `issues` não vazio (RF-12). | Estado e regras dentro das *views* SwiftUI (sem teste). | 🟢 |
| D-21 | Tela de atalhos: seletor de camada (base e uma por modificador), figura do controle desenhada com formas SwiftUI nas posições físicas (gatilhos e bumpers no topo, direcional à esquerda, botões de ação à direita, touchpad, Create, Options e PS no centro, analógicos embaixo), cada botão clicável com a ação resumida; painel lateral do botão selecionado com tipo de ação, detalhe e "Este botão é modificador". Ações herdadas aparecem esmaecidas com "(herdado)"; modificadores e botões de apontamento, com o rótulo "fixo" e sem edição. Reordenação da paleta por botões "Mover para cima" e "Mover para baixo", além de arrastar. | RF-08, RF-17 e RF-14 operáveis só com cliques do controle; arrastar com R1 é possível, mas pouco preciso a 3 m. | Tabela de 18 linhas por camada (sem posição física, contra RF-17). | 🟡 |
| D-22 | Acorde definido de duas formas no painel da ação: (a) "Gravar pelo teclado", `NSViewRepresentable` que, só enquanto ativo e com a janela em foco, instala `NSEvent.addLocalMonitorForEvents` para `keyDown` e `flagsChanged`, descarta eventos cujo `cgEvent` tenha `eventSourceUserData` igual a `EventInjector.sourceMark`, consome o evento e encerra ao primeiro acorde com tecla do `KeyCatalog`; (b) "Montar", grade de teclas por grupo do `KeyCatalog` e quatro alternadores de modificador. | Esclarecimento 1 e RN-15: captura local à janela, nunca global; a marca que o app já põe em todo evento injetado separa o teclado físico do controle. A montagem cobre Command+Tab e outros acordes que o sistema consome antes do app. | Monitor global (`addGlobalMonitorForEvents`, captura fora do editor, contra RN-15); só gravação (exige teclado, rejeitada no esclarecimento 1). | 🔴 |
| D-23 | Abertura do editor, pelo menu ou pela paleta, na main thread: guarda `NSWorkspace.shared.frontmostApplication`, cria ou reutiliza a janela, chama `NSApp.activate(ignoringOtherApps: true)` e `makeKeyAndOrderFront`. Ao fechar, reativa o aplicativo guardado se ele ainda estiver em execução (RF-19). Fechar com rascunho sujo abre diálogo Salvar, Descartar e Cancelar (RF-13). | App `.accessory` precisa ativar-se para a janela receber teclado e o ditado; guardar o aplicativo anterior permite devolver o foco. | Painel não ativador que recebe teclado (o ditado do Raycast cola no aplicativo ativo, que continuaria sendo o terminal). | 🔴 |
| D-24 | Modo de identificação: alternador no editor que publica `identifying = true` à fila `input` e fecha a paleta aberta. Com ele ligado, o `InputRouter` entrega a `ButtonActions` todo botão, como sempre, e envia os demais botões (fora R1, R2 e clique do touchpad) só ao editor, por `DispatchQueue.main.async`, sem passar por atalhos nem paleta. O modo desliga ao fechar a janela ou ao perder o foco. | RN-16 e RF-16 com um único ponto de desvio, igual ao da paleta (002 D-03). | Filtrar no `ShortcutMapper` (misturaria dois estados); manter ligado com a janela sem foco (o controle ficaria sem atalhos sem indicação visível). | 🟢 |
| D-25 | Conflito com gravação externa (RF-18): com rascunho sujo, a releitura válida vira faixa no editor com "Recarregar do arquivo" (descarta o rascunho) e "Manter minhas alterações" (a próxima gravação funde sobre o arquivo novo, D-07); sem rascunho sujo, o editor adota a vigente nova sem aviso. Leitura inválida mostra o erro na mesma faixa sem tocar no rascunho. | Nada é sobrescrito sem escolha; a fusão no instante da gravação preserva o que veio de fora nas outras seções. | Bloquear a gravação externa (impossível); recarregar sempre (perde trabalho). | 🟢 |
| D-26 | "Restaurar padrão" substitui mapeamento e paleta pelos de D-04 após confirmação e grava em seguida, com `shortcuts.restored`. | RF-15 em uma operação; cancelar não altera rascunho nem arquivo. | Restaurar só no rascunho (exige um segundo passo não descrito no critério). | 🟡 |

### 3.5 Log e testes

| ID | Decisão | Justificativa | Alternativas descartadas | Confidência |
|----|---------|----------------|--------------------------|-------------|
| D-27 | Eventos novos em `LogEventCatalog`: `shortcuts.loaded { trigger, source, reason?, modifiers, items }`, `shortcuts.invalid { trigger, path?, line?, rule }`, `shortcuts.unchanged { trigger }` em `debug`, `shortcuts.file_removed`, `shortcuts.saved { created, backup }`, `shortcuts.save_failed { message }`, `shortcuts.restored`, `shortcut.triggered` (D-14), `editor.opened { source }`, `editor.closed { outcome }`, `editor.conflict { choice }`, `editor.identify { on }`; `palette.closed` ganha o motivo `config_changed`. `logSchema` continua 1. Contrato em `interfaces/diagnostic-log.md`. | RNF de observabilidade com a privacidade de RN-14; `message` de falha de gravação traz só caminho e erro do sistema. | Reaproveitar `config.*` da 001 (os consumidores esperam `settings` de `pointer` nesses eventos). | 🟢 |
| D-28 | Testes em `JoystickCoreTests`: `ShortcutConfigValidationTests` (cada regra de D-05, seção ausente, RN-08), `ShortcutDefaultsTests` (equivalência de D-04), `ShortcutMapperTests` reescrito sobre configuração (herança, "nenhuma" própria, modificador novo com teclas mantidas, RN-01, RN-03 nas duas ordens, botões de apontamento, `systemDown`/`systemUp`), `ConfigDocumentTests` (fusão preserva `pointer` por valor, cria objeto, raiz inválida), `ConfigLineLocatorTests`, `KeyCatalogTests` (nomes únicos, ida e volta), `EditorDraftTests` (operações, limites, `isDirty`, restauração, avisos), `CommandPaletteTests` (lista configurada, entrada fixa, `openEditor`, `config_changed`) e `LogEventCatalogTests` (eventos novos sem texto nem acorde). Interface, observação de arquivo, ativação e captura de teclado verificadas no portão manual. | Cobre RN-01 a RN-13 e RF-01 a RF-05, RF-09, RF-11 a RF-15 automaticamente. | Testes de interface automatizados (sem Xcode na máquina, 001 D-02). | 🟢 |

## 4. Premissas

Não há `[DÚVIDA]` pendente no `requirements.md`. As incertezas técnicas viram sondas da Fase 0, e não premissas:

| Sonda | Pergunta | Decisão que depende dela |
|-------|----------|--------------------------|
| P-01 | Com o app `.accessory` no macOS 26 e o terminal em foco, abrir o editor por evento do controle (sem clique no app) torna a janela ativa e com foco de teclado? Ao fechar, `activate` devolve o foco ao terminal? | D-23; se falhar, voltar a `investigation.md` §3.3 (janela aberta só pelo menu, com a paleta levando o ponteiro ao ícone). |
| P-02 | O monitor local recebe Command+Shift+Z do teclado físico, e os eventos injetados pelo app chegam com `eventSourceUserData` igual à marca? Quais acordes o sistema consome antes (Command+Tab, Command+Space, Command+Q sem menu principal)? | D-22: filtro por marca e lista de acordes que exigem a montagem. |
| P-03 | O ditado do Raycast, acionado por R3 (Command+M), insere o texto num `TextField` SwiftUI do editor ativo? | Lacuna "Texto sem teclado" do `requirements.md` §10; se falhar, registrar a limitação no `onboarding.md` e seguir, pois a gravação e a montagem de acordes independem de texto. |
| P-04 | A observação de diretório de D-16 detecta, em até 1 s, gravações do VS Code, do `vim`, de `echo >` e de `mv` sobre o arquivo, inclusive com `config.json` como *link* simbólico para outro diretório? | D-16 e D-17. |
| P-05 | Uma janela SwiftUI com texto de 24 pt e alvos de 44 pt é legível e clicável com o ponteiro do controle a 3 m da TV, e cabe com rolagem numa tela de 900 pt de altura? | D-19 e D-21: ajuste das constantes de `EditorMetrics` antes das telas completas. |

## 5. Delta arquitetural

Não existe `_reversa_sdd/architecture.md`; os componentes são citados pela spec SDD e pelo código entregue nas features 001 e 002.

| Componente | Arquivo de origem no legado | Tipo de mudança | Resumo |
|------------|------------------------------|-----------------|--------|
| Modelo de configuração (`ShortcutConfig`, `TriggerAction`, `ShortcutsDocument`, `ShortcutDefaults`, `PaletteDefaults`, `KeyCatalog`) | `_reversa_sdd/sdd/action-mapping.md#9. Modelo de Dados` | componente-novo | Mapeamento e paleta como dados, com padrões iguais ao protótipo. |
| Validação, fusão e localização de linha (`ShortcutConfigValidation`, `ConfigDocument`, `ConfigLineLocator`) | `_reversa_sdd/sdd/action-mapping.md#11. Edge Cases e Tratamento de Erros` | componente-novo | Validação conjunta com caminho e linha; gravação preservando seções. |
| `ConfigLoader` | `_reversa_forward/001-poc-entrada-ponteiro/interfaces/config-pointer.md` | regra-alterada | Uma decodificação entregue a `pointer` e às seções novas. |
| `ShortcutMapper` | `_reversa_sdd/addenda/002-paleta-comandos.md#Impacto por artefato da extração` | regra-alterada | Resolução por configuração, camada do modificador mais antigo e atalho de sistema resolvido no uso. |
| `ShortcutActions` | idem | regra-alterada | `apply(config)`, leitura das preferências no pressionar e `shortcut.triggered`. |
| `PaletteMachine`, `PaletteActions`, `PaletteView` | `_reversa_sdd/addenda/002-paleta-comandos.md#Impacto por artefato da extração` | regra-alterada | Lista configurada, entrada fixa "Editar atalhos", `apply(items)` e motivo `config_changed`. |
| `InputRouter` | idem | regra-alterada | Desvio dos botões ao editor no modo de identificação. |
| `ConfigStore`, `ConfigWatcher`, `ConfigWriter` | `_reversa_sdd/sdd/action-mapping.md#6.1 Requisitos Principais` (RF-03, RF-04) | componente-novo | Dono da configuração vigente, observação sem varredura e gravação atômica. |
| `StatusMenu` | `_reversa_sdd/sdd/app-shell.md#6.1 Requisitos Principais` (RF-01, RF-08) | componente-novo | Ícone com "Editar atalhos", "Sair" e alerta de configuração inválida. |
| `EditorWindowController`, `EditorViewModel`, `EditorDraft` e *views* SwiftUI | `_reversa_sdd/sdd/app-shell.md#4. Non-Goals (Fora do Escopo)` (NG-03, revogado) | componente-novo | Janela do editor na escala de TV. |
| `AppDelegate` | `_reversa_sdd/sdd/app-shell.md#6.1 Requisitos Principais` | regra-alterada | Cria `ConfigStore`, `StatusMenu` e editor; liga paleta e roteador ao editor. |
| Arquivo de configuração | `_reversa_forward/001-poc-entrada-ponteiro/interfaces/config-pointer.md` | contrato-alterado | Seções `shortcuts` e `palette`; o app passa a criar o arquivo ao salvar. |
| Log de diagnóstico (`LogEventCatalog`) | `_reversa_forward/002-paleta-comandos/interfaces/diagnostic-log.md` | contrato-alterado | Eventos `shortcuts.*`, `shortcut.triggered`, `editor.*` e motivo `config_changed`. |

## 6. Delta no modelo de dados

- Resumo das mudanças: primeira persistência escrita pelo app. `config.json` ganha `shortcuts` e `palette`, criados só ao salvar; `pointer` e seções desconhecidas ficam preservados por valor. Em memória, o mapeamento fixo vira `ShortcutConfig`, `PaletteItem` ganha `label`, `PaletteCloseReason` ganha `config_changed`, `ShortcutAction` ganha `systemDown` e `systemUp`, e surgem o estado da configuração e o rascunho do editor.
- Detalhe completo em: `_reversa_forward/003-editor-atalhos/data-delta.md`

## 7. Delta de contratos externos

| Contrato | Tipo | Arquivo de detalhe |
|----------|------|--------------------|
| Arquivo de configuração (`shortcuts`, `palette` e gravação) | arquivo (JSON) | `_reversa_forward/003-editor-atalhos/interfaces/config-file.md` |
| Log de diagnóstico | arquivo (JSON Lines) | `_reversa_forward/003-editor-atalhos/interfaces/diagnostic-log.md` |

Os argumentos de abertura não mudam.

## 8. Plano de migração

Sem migração de dados: arquivo ausente ou só com `pointer` resulta nos padrões de D-04, e nada é gravado até o primeiro "Salvar". A execução segue em fases que falham cedo:

1. **Fase 0, sondas (portão PM-1).** P-01, P-02 e P-03 com um editor mínimo já no app (janela SwiftUI com um `TextField`, um campo de gravação e o item "Editar atalhos" no menu e na paleta), P-04 com o `ConfigWatcher` registrando eventos em `debug` e P-05 com a janela mínima na TV. Resultados nas notas do `actions.md`. Se P-01 falhar sem alternativa aceitável, parar e voltar ao `/reversa-clarify`.
2. **Fase 1, núcleo.** `KeyCatalog`, modelo, padrões com o teste de equivalência escrito antes de remover o `switch`, validação, localizador de linha, fusão, `ShortcutMapper` por configuração, paleta configurável, `EditorDraft` e eventos de log, com os testes de D-28. `scripts/test.sh` verde.
3. **Fase 2, integração sem editor.** `ConfigStore`, `ConfigWatcher`, `ConfigWriter`, `apply` na fila `input`, atalho de sistema resolvido no uso e `StatusMenu` com alerta. Nesse ponto, editar o JSON à mão já altera atalhos e paleta.
4. **Fase 3, editor.** Janela, métricas de TV, tela de atalhos com figura, painel de ação com gravação e montagem, tela da paleta, modo de identificação, conflito, restauração e devolução de foco.
5. **Portão manual PM-2.** Roteiro do `onboarding.md`, com os cenários da seção 7 do `requirements.md`, a verificação de que o comportamento sem arquivo é o do protótipo e a legibilidade a 3 m.

Reversão: a entrega é um conjunto de commits; voltar ao commit anterior restaura o protótipo. Um `config.json` com as seções novas continua legível pela versão anterior, que só lê `pointer`.

## 9. Riscos e mitigações

| Risco | Impacto | Probabilidade | Mitigação |
|-------|---------|---------------|-----------|
| O macOS recusa ativar o editor quando o pedido vem do controle, e a janela abre atrás do terminal | alto | média | Sonda P-01 antes das telas; alternativa de abrir só pelo ícone, alcançável pelo ponteiro (D-23). |
| Regressão nos atalhos ao trocar o `switch` pela configuração | alto | média | Teste de equivalência de D-04 escrito primeiro; `ShortcutMapperTests` atuais mantidos como casos da configuração padrão. |
| A troca atômica de editores ou o *link* simbólico escapam à observação | médio | média | Observação do diretório e do destino do *link*, releitura por *bytes* (D-16); sonda P-04; "Salvar" do editor independe da observação. |
| A gravação pelo app desfaz o *link* simbólico dos dotfiles | médio | baixa | Gravação no destino resolvido (D-17); verificado em P-04. |
| Mudança de precedência entre modificadores surpreende em uso | baixo | baixa | Regra decidida no esclarecimento 3; cenário próprio no PM-2; afeta só combinações de dois modificadores. |
| Leitura de `AppleSymbolicHotKeys` a cada uso eleva a latência | baixo | baixa | Leitura com *cache* do `cfprefsd` (D-11); medir `shortcut.triggered` contra `input.button` com `--debug`; se passar de 30 ms, ler ao aplicar e ao abrir o editor. |
| Editor ilegível ou alvos difíceis de acertar a 3 m | médio | média | Sonda P-05 com a janela mínima; constantes centralizadas em `EditorMetrics`. |
| Tab e setas injetados pelo controle não percorrem todos os controles do editor | baixo | alta | Operação principal por cliques (D-21); navegação por teclado tratada como complemento; anotar no PM-2. |
| Captura de teclado grava tecla injetada pelo controle | médio | baixa | Filtro pela marca `sourceMark` (D-22); sonda P-02; cenário "Gravação de acorde". |
| Arquivo sem gatilho de abrir a paleta deixa o sofá sem acesso ao editor pela paleta | baixo | baixa | Aviso não bloqueante no editor (D-20); o ícone da barra de menus segue alcançável pelo ponteiro. |

## 10. Critério de pronto

- [ ] Sondas P-01 a P-05 registradas em `actions.md`, com as decisões dependentes confirmadas ou ajustadas
- [ ] Todas as ações do `actions.md` marcadas `[X]`
- [ ] `scripts/test.sh` verde, incluindo os testes de D-28 e o de equivalência de D-04
- [ ] Portão PM-2 executado: cenários da seção 7 do `requirements.md` aprovados, com o editor aberto pela paleta e pelo menu
- [ ] Sem arquivo de configuração, atalhos e paleta idênticos aos da feature 002
- [ ] `cross-check.md` (se executado) sem CRITICAL nem HIGH
- [ ] `regression-watch.md` gerado
- [ ] Re-extração reversa executada e sem regressão vermelha (recomendado, não obrigatório)

## 11. Histórico de alterações

| Data | Alteração | Autor |
|------|-----------|-------|
| 2026-09-14 | Versão inicial gerada por `/reversa-plan` | reversa |
