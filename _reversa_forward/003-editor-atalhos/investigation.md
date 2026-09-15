# Investigation: Editor de atalhos e comandos

> Identificador: `003-editor-atalhos`
> Data: `2026-09-14`
> Roadmap: `_reversa_forward/003-editor-atalhos/roadmap.md`

## 1. Pergunta de fundo

Como transformar o mapeamento fixo do protótipo e a lista fixa da paleta em configuração editável por uma janela operada do sofá, com o controle como único dispositivo, sem regressão nos atalhos em uso, sem tecla presa na troca e sem perder o que o usuário escreve à mão no arquivo?

## 2. Estado de partida, observado no código em 2026-09-14

- `ShortcutMapper` (`Sources/JoystickCore/Shortcuts/ShortcutMapper.swift`) resolve camadas num `switch` com prioridade fixa: Options, depois L2, depois L1, depois base. L1 e L2 caem na base quando não têm ação própria; com Options, botões fora de ← e → devolvem `[]`. Options emite `modifierDown(.command)` ao pressionar.
- Os acordes dos atalhos de sistema são lidos de `AppleSymbolicHotKeys` uma única vez, na criação de `ShortcutActions`.
- `ConfigLoader` decodifica `config.json` com `JSONDecoder` para `JSONValue`, lê só `pointer`, recusa arquivos acima de 1 MiB, informa a linha do erro de sintaxe e nunca cria arquivo nem diretório. A leitura acontece uma vez, no `AppDelegate`, antes do controle.
- `CommandPalette.items` é uma lista estática de 17 `PaletteItem { text, pressEnter }`; `PaletteMachine` recebe a lista na criação, e `PalettePanel` a recebe no início.
- `EventInjector.deliver` marca todo evento injetado com `eventSourceUserData = 0x4A4F5953` ("JOYS").
- O app roda com `setActivationPolicy(.accessory)` e `LSUIElement`, sem ícone na barra de menus, sem menu principal e sem nenhum código SwiftUI.
- `PointerMotionEngine.precisionActive` ativa a precisão só com L1 como único botão pressionado.
- Existe `~/.config/joystick-ai/config.json` na máquina de uso, com 46 *bytes* e só a seção `pointer`.
- Ambiente: macOS 26.6.2, Swift 6.3.3, apenas Command Line Tools; o SDK traz `SwiftUI.framework`.

## 3. Alternativas avaliadas

### 3.1 Onde guardar atalhos e paleta

| Alternativa | Prós | Contras | Veredito |
|-------------|------|---------|----------|
| Seções `shortcuts` e `palette` em `config.json` | Um arquivo para versionar; contrato `pointer` intacto; decisão já registrada em `action-mapping` §15 | Gravação precisa preservar `pointer` | **Escolhida** (D-01, D-07) |
| Arquivo `shortcuts.json` separado | Gravação sem fusão | Duas fontes a observar; divergência entre `action-mapping` e o arquivo | Descartada |
| `UserDefaults` do app | API pronta | Fora de `~/.config`, difícil de versionar e editar à mão, contra `action-mapping` §15 | Descartada |

### 3.2 Representação de camada e herança

| Alternativa | Prós | Contras | Veredito |
|-------------|------|---------|----------|
| Objeto por camada, botão ausente herda da base | Curto à mão; herança sem tipo extra; "nenhuma" explícito continua possível | Na base, ausência tem outro sentido ("nenhuma"), o que exige documentação | **Escolhida** (D-01) |
| Tipo `inherit` explícito em toda entrada | Nada implícito | 18 entradas por camada, arquivo longo e ruidoso | Descartada |
| Lista plana de `Mapping { button, withModifier, trigger }` (`action-mapping` §9) | Já especificada | Só um modificador; sem camadas; inclui `tap` e `longPress`, fora do escopo | Descartada |

### 3.3 Abertura do editor sem roubar ou perder foco

| Alternativa | Prós | Contras | Veredito |
|-------------|------|---------|----------|
| Janela comum com `NSApp.activate` e devolução do foco ao aplicativo anterior ao fechar | Recebe teclado e ditado; comportamento de janela conhecido | No macOS 14 ou superior, a ativação cooperativa pode recusar pedido que não venha de interação com o app | **Escolhida**, condicionada à sonda P-01 (D-23) |
| Painel não ativador que se torna `key`, como lançadores de terceiros | Nunca disputa ativação | O ditado do Raycast cola no aplicativo ativo, que continuaria sendo o terminal; o texto iria para o lugar errado | Descartada |
| Abrir só pelo ícone da barra de menus, com a paleta levando o ponteiro até ele | Clique no ícone é interação com o app | Um passo a mais do sofá; descumpre RF-07 literalmente | Alternativa se P-01 falhar |

### 3.4 Tecnologia da interface

| Alternativa | Prós | Contras | Veredito |
|-------------|------|---------|----------|
| SwiftUI em `NSHostingView` | Formulários, listas, diálogos e estado observável com pouco código; disponível no macOS 13 e nas Command Line Tools | Estilos próprios para chegar a 44 pt; primeira dependência de SwiftUI no alvo | **Escolhida** (D-19) |
| AppKit puro, no padrão de `PaletteView` | Sem dependência nova; controle total do desenho | Formulário com dezenas de controles, diálogos e reordenação exigiria muito código de *layout* | Descartada |
| Editar o JSON num editor de texto aberto pelo menu | Nenhuma interface nova | Não atende ao pedido nem ao uso do sofá | Descartada; continua possível por fora (RF-03) |

### 3.5 Captura do acorde

| Alternativa | Prós | Contras | Veredito |
|-------------|------|---------|----------|
| Monitor local de `keyDown` e `flagsChanged`, ativo só com o campo ligado, filtrando a marca `sourceMark` | Captura restrita à janela (RN-15); separa teclado físico do controle | Acordes consumidos pelo sistema não chegam | **Escolhida**, com a montagem por seleção (D-22) |
| Monitor global de eventos | Captura qualquer acorde | Exige Input Monitoring e captura fora do editor, contra RN-15 | Descartada |
| `CGEventTap` de escuta | Vê acordes antes de alguns consumidores | Mesmo problema de privacidade; permissão adicional | Descartada |
| Só montagem por seleção | Operável pelo controle; cobre acordes do sistema | Mais lento para quem tem teclado | Mantida como segunda forma (esclarecimento 1) |

### 3.6 Detecção de alteração externa

| Alternativa | Prós | Contras | Veredito |
|-------------|------|---------|----------|
| `DispatchSource` de sistema de arquivos no diretório, com releitura adiada e comparação de *bytes* | Sem varredura; sobrevive à troca atômica; pouca API | Diretório inexistente exige observar o ancestral; *link* simbólico exige observar o destino | **Escolhida**, condicionada à sonda P-04 (D-16) |
| `DispatchSource` no descritor do próprio arquivo | Simples | Perde a observação quando o editor troca o arquivo por outro | Descartada |
| FSEvents | Robusto para árvores grandes | Latência de agrupamento a ajustar contra o limite de 1 s; API C mais extensa | Descartada |
| Varredura periódica de data de modificação | Trivial | Consumo em repouso, contra `action-mapping` RNF-02 | Descartada |

### 3.7 Linha do erro de conteúdo

O `JSONDecoder` informa a linha só em erro de sintaxe, já tratado por `ConfigLoader.describe`. Para erros de conteúdo (tecla desconhecida, camada de botão que não é modificador), a validação produz o caminho JSON; um localizador léxico percorre o texto acompanhando chaves e índices e devolve a linha do início do valor desse caminho. Roda só quando há erro, de modo que a leitura válida continua com um único `JSONDecoder` (D-06). Um analisador JSON próprio daria posições para tudo, mas substituiria código que funciona e acrescentaria superfície de erro sem ganho para o caso comum.

### 3.8 Precedência entre modificadores

Decidida no esclarecimento 3: vale o modificador segurado há mais tempo, com herança só da base. A implementação guarda a ordem de pressionar (D-09). Diferenças em relação ao protótipo aparecem só com dois modificadores segurados, por exemplo L2 e depois L1 com ✕, que passa de `CONTINUAR` a Enter. As teclas modificadoras mantidas por um botão continuam valendo enquanto ele está segurado, qualquer que seja a camada (D-10), o que preserva o Command de Options.

## 4. Padrões aplicáveis

- **Máquina pura com efeitos** (`ShortcutMapper`, `PaletteMachine`, `ClickStateMachine`): o mapeador por configuração e o `EditorDraft` seguem o mesmo padrão, testáveis sem AppKit.
- **Fila dona do estado** (001 D-22, 002 D-11): configuração e editor na main thread, atalhos e paleta na fila `input`, com cópias imutáveis entre elas.
- **Soltura antes de mudar de modo** (`InjectionGate`, abertura da paleta): aplicar configuração, abrir a paleta e ligar a identificação soltam antes o que está mantido.
- **Gravação atômica com fusão tardia:** ler a raiz no instante da gravação, substituir só as seções gerenciadas e trocar o arquivo de uma vez.
- **Validação total antes da troca:** a configuração nova só substitui a vigente depois de validada por inteiro (RN-08).

## 5. Fontes

- Documentação da Apple, `NSApplication.activate(ignoringOtherApps:)` e ativação cooperativa: <https://developer.apple.com/documentation/appkit/nsapplication/activate(ignoringotherapps:)>
- Documentação da Apple, `NSEvent.addLocalMonitorForEvents(matching:handler:)`: <https://developer.apple.com/documentation/appkit/nsevent/addlocalmonitorforevents(matching:handler:)>
- Documentação da Apple, `DispatchSource.makeFileSystemObjectSource(fileDescriptor:eventMask:queue:)`: <https://developer.apple.com/documentation/dispatch/dispatchsource/makefilesystemobjectsource(filedescriptor:eventmask:queue:)>
- Documentação da Apple, `NSStatusItem`: <https://developer.apple.com/documentation/appkit/nsstatusitem>
- Documentação da Apple, `NSHostingView`: <https://developer.apple.com/documentation/swiftui/nshostingview>
- Código das features 001 e 002: `ShortcutMapper.swift`, `ShortcutActions.swift`, `ConfigLoader.swift`, `CommandPalette.swift`, `PaletteActions.swift`, `PalettePanel.swift`, `InputRouter.swift`, `EventInjector.swift`, `AppDelegate.swift`.
- `_reversa_forward/002-paleta-comandos/backlog-editor.md`; `_reversa_sdd/sdd/action-mapping.md` §6.1, §9, §11, §15; `_reversa_sdd/sdd/app-shell.md` §4, §6.1, §8.

> Os caminhos das páginas da Apple seguem o formato atual do site e não foram abertos nesta sessão; se algum mudar, a busca pelo nome do símbolo leva à página correspondente.
