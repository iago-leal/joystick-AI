# Investigation: Paleta de comandos pelo controle

> Identificador: `002-paleta-comandos`
> Data: `2026-09-14`
> Roadmap: `_reversa_forward/002-paleta-comandos/roadmap.md`

## 1. Pergunta de fundo

Como acionar cerca de vinte comandos de texto (`/reversa-*`, `CONTINUAR`, `/clear`, `/compact`, `/resume`) com um controle que tem 18 botões, a maior parte já ocupada por apontamento, navegação e atalhos, sem tirar o foco do terminal onde o Claude Code roda?

## 2. Estado de partida, observado no código em 2026-09-14

- `ShortcutMapper` (`Sources/JoystickCore/Shortcuts/ShortcutMapper.swift`) já resolve camadas: L2 e L1 caem na camada base quando o botão não tem ação própria; Options devolve `[]` para botões fora de ← e →. PS não tem ação em nenhuma camada.
- `KeyboardInjector.type(_:pressEnter:)` digita cada unidade UTF-16 com `CGEventKeyboardSetUnicodeString` e `virtualKey` 0, sem modificadores, e posta Return logo em seguida. É o caminho de L1+✕ (`CONTINUAR`).
- `InputRouter` entrega todo botão a `ButtonActions` e a `ShortcutActions`; não há ponto de desvio.
- `InjectionGate.onSuspended` tem um único observador, ocupado pela tela de alvos.
- A `TargetWindow` usa `level = .statusBar` e `collectionBehavior [.canJoinAllSpaces, .fullScreenAuxiliary]`, mas é janela que se torna `key`, porque a tela de alvos precisa de Esc.
- O app roda com `setActivationPolicy(.accessory)` e `LSUIElement`, sem ícone no Dock nem menu.

## 3. Alternativas avaliadas

### 3.1 Forma de acionar os comandos

| Alternativa | Prós | Contras | Veredito |
|-------------|------|---------|----------|
| Um botão ou combinação por comando | Um toque, sem tela | Faltam botões: 17 comandos contra poucas combinações livres; memorização difícil | Descartada |
| Paleta sobreposta, navegada pelo controle | Escala para dezenas de itens; lista visível dispensa memorização; um só botão reservado | Um passo a mais que o toque direto; exige janela que não roube o foco | **Escolhida** (esclarecimento 3) |
| Lançador de terceiros com trechos de texto (por exemplo, o do Raycast) | Sem código novo | Ativa o próprio app e tira o foco; exige digitar a busca; fora do controle | Descartada |
| Atalhos de teclado do próprio Claude Code | Integração nativa | Específico de uma ferramenta; ainda um acorde por comando; não resolve `CONTINUAR` fora dela | Descartada |
| Ditado dos comandos pelo R3 | Já existe | A transcrição de "barra reversa hífen plan" não produz o texto literal com confiabilidade | Descartada |

### 3.2 Janela da paleta

| Alternativa | Prós | Contras | Veredito |
|-------------|------|---------|----------|
| `NSPanel` com `.nonactivatingPanel`, sem `key`, ignorando mouse | Não ativa o app; o terminal segue em foco; cliques passam | Não recebe teclado, o que é irrelevante porque a entrada vem do controle | **Escolhida** (D-08) |
| `NSWindow` comum com `NSApp.activate` | Simples | Tira o foco do terminal; o texto iria para a própria paleta | Descartada |
| Desenho em camada de sobreposição por Core Graphics sem janela | Nenhum risco de foco | Não há API pública para desenhar sobre outros apps sem janela | Descartada |

### 3.3 Tecnologia de desenho

| Alternativa | Prós | Contras | Veredito |
|-------------|------|---------|----------|
| `NSView` com `draw(_:)`, como `TargetView` | Padrão já presente; controle total de fonte, cores e rolagem | Mais código de layout | **Escolhida** (D-09) |
| SwiftUI em `NSHostingView` | Declarativo | Primeira dependência de SwiftUI no alvo em modo Swift 5; ganho pequeno para uma lista fixa | Adiada para o editor da feature seguinte |
| `NSTableView` | Seleção pronta | Pensada para mouse e teclado; estilização para TV trabalhosa | Descartada |

### 3.4 Envio do Enter

O Claude Code abre sugestões de autocompletar ao receber `/`. A paleta digita o comando completo, e o Enter deveria executar a correspondência exata. Não se observou ainda se um Enter no mesmo instante do último caractere é tratado igual, nem se a digitação muito rápida é interpretada como colagem. Por isso o roadmap prevê a sonda P-01 com 0, 50 e 150 ms e deixa o intervalo ajustável por argumento (D-06), em vez de fixar um valor sem medição.

## 4. Padrões aplicáveis

- **Máquina de estados pura com efeitos** (`ShortcutMapper`, `ClickStateMachine`): a lógica devolve ações e o adaptador as executa, o que permite testar sem AppKit.
- **Fila dona do estado** (001 D-04, D-22): estado mutável só na fila `input`; a interface recebe cópias imutáveis.
- **Soltura antes de mudar de modo** (`InjectionGate`, `Lifecycle`): toda transição que muda o destino dos botões solta antes o que está mantido.

## 5. Fontes

- Documentação da Apple, `NSWindow.StyleMask.nonactivatingPanel`: <https://developer.apple.com/documentation/appkit/nswindow/stylemask-swift.struct/nonactivatingpanel>
- Documentação da Apple, `NSWindow.CollectionBehavior`: <https://developer.apple.com/documentation/appkit/nswindow/collectionbehavior-swift.struct>
- Documentação da Apple, `CGEvent.keyboardSetUnicodeString(stringLength:unicodeString:)`: <https://developer.apple.com/documentation/coregraphics/cgevent/keyboardsetunicodestring(stringlength:unicodestring:)>
- Código da feature 001: `ShortcutMapper.swift`, `KeyboardInjector.swift`, `InputRouter.swift`, `InjectionGate.swift`, `TargetWindow.swift`.
- `_reversa_sdd/sdd/action-mapping.md` §6.1 (RF-09, RF-10), §11 (EC-05, EC-06), §12 e §14 (OQ-02).

> Os caminhos das páginas da Apple seguem o formato atual do site e não foram abertos nesta sessão; se algum mudar, a busca pelo nome do símbolo leva à página correspondente.
