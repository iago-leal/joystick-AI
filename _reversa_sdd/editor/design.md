# Editor de atalhos (editor), Design Técnico

> Gerado pelo Redator em 2026-09-15 · Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA

## Interface

### `EditorDraft` (núcleo, valor)

| Membro | Assinatura | Observação |
|--------|-----------|------------|
| `base`, `document` | `ShortcutsDocument` | Só leitura externa |
| `isDirty` | `Bool` | `document != base` |
| `issues` | `[EditorIssue]` | `validate(document)` → `target(of: path)` |
| `warnings` | `[EditorWarning]` | `noPaletteTrigger` |
| `layers` | `[ButtonID?]` | `[nil] + modificadores ordenados` |
| `static target(of:)` | `String → EditorTarget?` | `shortcuts.modifiers.X` → modificador; `shortcuts.layers.L.B` → gatilho; `shortcuts.layers.L` → modificador L; `palette.items[i]…` → item; outro `palette…` → paleta |
| `setAction(_:for:in:)` | `throws` | `pointerButton`, `multiline`, `textTooLong` |
| `setModifier(_:keys:)`, `unsetModifier(_:)` | `throws` / — | `removedNones` |
| `insertPaletteItem(_:at:)`, `removePaletteItem(at:)` | `throws` | `paletteFull`, `lastPaletteItem`, texto, rótulo |
| `movePaletteItemUp/Down(at:)`, `movePaletteItems(fromOffsets:toOffset:)` | — | Convenção de `onMove` |
| `setPaletteText`, `setPaletteLabel`, `setPalettePressEnter` | `(_, at:)` | Índice fora da lista é ignorado |
| `restoreDefaults()` | — | Só usado nos testes; o app restaura pelo `ConfigStore` |
| `rebase(to:keepChanges:)` | — | Troca a base; sem `keepChanges`, rascunho = base |

`EditorOperationError.message`: "A paleta precisa de ao menos um item.", "A paleta aceita no máximo 50 itens.", "O texto deve ter uma única linha.", "O texto aceita no máximo 1000 caracteres.", "O rótulo aceita no máximo 80 caracteres.", "R1, R2 e o clique do touchpad são cliques fixos." 🟢

### `EditorViewModel` (main, `ObservableObject`)

| Membro | Observação |
|--------|------------|
| `@Published draft`, `tab (.shortcuts/.palette)`, `selectedLayer`, `selectedButton = .cross`, `identifying`, `operationError`, `saveError`, `pendingBackup { line, restore }`, `conflict (.externalChange / .externalInvalid(issue))` | Estado de tela |
| `onIdentifyingChange` | Leva o modo à fila `input` |
| `prepareForOpen()`, `canSave`, `issues(for:)`, `hasIssue(_:in:)` | Derivados |
| `select`, `identified`, `setAction`, `setModifier`, `unsetModifier` | Intenções de atalho |
| `insertPaletteItem`, `removePaletteItem`, `movePaletteItemUp/Down`, `movePaletteItem(from:to:)`, `setPaletteText/Label/PressEnter` | Intenções de paleta |
| `save(confirmBackup:)`, `discard()`, `restoreDefaults(confirmBackup:)`, `confirmBackup()`, `cancelBackup()` | Gravação |
| `reloadFromFile()`, `keepChanges()`, `dismissInvalidNotice()` | Conflito |

### `EditorWindowController` (main)

| Membro | Observação |
|--------|------------|
| `clickDelay 150 ms`, `activationCheckDelay 500 ms` | E003 |
| `init(log:activateByClick:content:)` | `activateByClick` → `inputQueue.async { injector.activationClick(at:) }` |
| `show(source:)` | Abertura |
| `onWillShow`, `isDirty`, `saveForClose`, `discardForClose`, `onIdentifyOff` | Ligados ao modelo (`AppDelegate.swift:94-98`) |
| `windowShouldClose`, `windowDidResignKey`, `windowWillClose` | `NSWindowDelegate` |

## Fluxo Principal

### Operações do rascunho (`EditorDraft.swift:103-235`)

- `setAction(a, b, L)`: recusa botão de apontamento; valida texto (quebra, tamanho); `layers[L][b] = a` (nil remove); camada vazia sai.
- `setModifier(b, keys)`: recusa apontamento; se `b` ainda não é modificador, remove `.none` de `b` em todas as camadas e guarda a lista em `removedNones[b]`; `modifiers[b] = keys`.
- `unsetModifier(b)`: `modifiers[b] = nil`; `layers[b] = nil`; para cada camada lembrada (≠ `b`) que ainda existe (base ou modificador) e não tem ação para `b`, recoloca `.none`.
- Paleta: `insert` limita a 50 e prende o índice a `0…count`; `remove` exige ao menos 2 itens; `movePaletteItems` remove os de origem e reinsere em `destino − (quantos estavam antes)`.
- `rebase` e `restoreDefaults` limpam `removedNones` de botões que deixaram de ser modificadores.

### Modelo (`EditorViewModel.swift`)

1. `perform(op)`: aplica numa cópia; sucesso publica e limpa `operationError`; `EditorOperationError` publica a mensagem.
2. `save(confirmBackup)`: exige `canSave || confirmBackup`; `store.save(document, confirmBackup)` → `handle`.
3. `handle`: `saved` → `rebase(current, false)`, limpa erros, `.bak` e conflito, corrige `selectedLayer`; `needsBackupConfirmation(line)` → `pendingBackup`; `failed(message)` → `saveError`.
4. `confirmBackup()`: consome `pendingBackup` e repete `save` ou `restoreDefaults` com `confirmBackup: true`.
5. `discard()`: `rebase(current, false)`, limpa mensagens e conflito de alteração externa.
6. Observador do `ConfigStore` (`configChanged`): ignora gatilhos que não são `external`; inválido → `externalInvalid`; sujo → `externalChange` + `editor.conflict pending`; limpo → `rebase`.
7. `identifying.didSet` → `onIdentifyingChange(on)` → `editor.identify { on }` e `inputQueue.async { router.setIdentifying(on) }` (`AppDelegate.swift:112-117`); `router.onIdentify` → main → `identified(button)`.

### Abertura e fechamento (`EditorWindowController.swift`)

```
show(source):
  front ← app em primeiro plano; se não é este processo: previousApp ← front
  onWillShow()                         // prepareForOpen
  window ← existente ou makeWindow()   // título "Editar atalhos", 1400×800 mín., moveToActiveSpace, ScrollView vertical, centralizada
  NSApp.activate()
  se !NSApp.isActive: window.level ← .floating
  makeKeyAndOrderFront; orderFrontRegardless
  log editor.opened { source }
  após 150 ms: se visível e não ativa → activateByClick(centro da barra de título em coordenadas Quartz)
     após 500 ms: se visível e não ativa → log editor.activation_failed
didBecomeActive: window.level ← .normal

windowShouldClose: aprovado ou limpo → fecha
  senão (folha não aberta): onIdentifyOff; folha Salvar / Descartar / Cancelar
     Salvar → saveForClose(); falso → fica aberta; verdadeiro → outcome saved
     Descartar → discardForClose(); outcome discarded
     aprovado → close()
windowDidResignKey: onIdentifyOff
windowWillClose: level normal; onIdentifyOff; log editor.closed { outcome }; zera; devolve ativação a previousApp (yieldActivation + activate)
```

Ponto da barra de título: `y = frame.maxY − max(altura da barra, 1)/2`, convertido para Quartz por `telaPrincipal.maxY − y`. 🟢

### Interface

- `EditorRootView`: abas Atalhos/Paleta, alternador "Identificar pelo controle" com instrução, `EditorBanners`, aba, rodapé.
- `EditorBanners` (ordem): conflito externo ou arquivo inválido; `.bak` pendente; erro de gravação; operação recusada ("Ok"); aviso sem gatilho da paleta ("…o editor continuará acessível só pelo ícone da barra de menus.").
- `ShortcutsTab`: seletor de camada (`draft.layers`), `ControllerFigureView` (tela 830 × 620, fichas 160 × 96, posições fixas) e `ActionPanel`.
- `ActionPanel`: título "X na camada Y"; botão de apontamento → texto fixo; senão problemas, alternador de modificador com ⌘ ⌥ ⌃ ⇧, e ações (tipo, detalhe do tipo, texto de herança).
- `ChordEditor`: exibição do acorde, "Gravar pelo teclado"/"Pressione o acorde…", nota sobre ⌘Tab e ⌘Space, alternadores de modificador, grupos (Letras, Dígitos, Pontuação, Edição, Navegação, Funções), grade de teclas; o grupo inicial é o da tecla atual.
- `KeyCaptureView`: `NSEvent.addLocalMonitorForEvents([.keyDown, .flagsChanged])` só ativo e com janela; evento de outra janela ou janela sem foco segue; marca do app → consumido; `flagsChanged` → consumido; tecla fora do catálogo → consumida; tecla do catálogo → desativa, `onCapture(chord)`, `onFinish`.
- `PaletteTab`: "N de 50 itens; "Editar atalhos" fica sempre no fim.", "Incluir no topo"/"Incluir no fim", linhas com alça, número, rótulo (280 pt), texto, Enter, ↑, ↓, lixeira e problemas; arrastar solta na posição da linha de destino.
- `EditMenu.install()`: menu principal vazio de app + "Editar". 🟢

## Fluxos Alternativos

- **Salvar na folha com problemas ou `.bak` pendente:** `save()` devolve falso; a janela fica aberta, com a faixa do `.bak` quando for o caso, e sem mensagem quando o motivo são problemas (o rodapé já os conta). 🟢
- **Abertura com a janela já aberta:** reutiliza a janela, repete a ativação e registra novo `editor.opened`. 🟢
- **Clique sintético com a injeção desligada:** `activationClick` é descartado; a janela fica flutuante até o usuário clicar. 🟢
- **Rascunho limpo e releitura externa inválida:** a vigente não muda; a faixa aparece; o rascunho continua igual à base. 🟢

## Dependências

- `configuracao`: `ConfigStore` (estado, `save`, `restoreDefaults`, observador), `ShortcutConfigValidation`, `ActionSummary`. 🟢
- `atalhos`: `ShortcutConfig`, `TriggerAction`, `KeyCatalog`, `SystemShortcut`, `KeyChord`. 🟢
- `paleta`: `PaletteItem`, `PaletteMachine.editorEntryTitle`, `PaletteActions.onOpenEditor`. 🟢
- `ponteiro`: `InputRouter.setIdentifying`, `onIdentify`. 🟢
- `injecao-de-eventos`: `EventInjector.activationClick`, `sourceMark`. 🟢
- `aplicativo`: `StatusMenu.onEditShortcuts`, `onOpenFromAlert`. 🟢
- `log-de-diagnostico`: `editor.opened`, `editor.closed`, `editor.conflict`, `editor.identify`, `editor.activation_failed`. 🟢
- SwiftUI, AppKit, Combine, UniformTypeIdentifiers. 🟢

## Decisões de Design Identificadas

| Decisão | Evidência | Confiança |
|---------|-----------|-----------|
| Ícone na barra de menus como acesso permanente (003 D-18) | `AppDelegate.swift:100-104` | 🟢 |
| Escala de TV com estilos próprios, valores do reteste P-05 (003 D-19, ADR-014) | `EditorMetrics.swift:3-7` | 🟢 |
| Rascunho puro com a mesma validação do arquivo (003 D-20) | `EditorDraft.swift:44-45` | 🟢 |
| Figura com resumo por camada (003 D-21) | `ControllerFigureView.swift:4-8` | 🟢 |
| Acorde por montagem e por gravação local (003 D-22, RN-15) | `ChordEditor.swift:4-6`, `KeyCaptureField.swift:5-10` | 🟢 |
| Ativação por clique sintético na barra de título (003 E003, ADR-013) | `EditorWindowController.swift:13-17` | 🟢 |
| Identificação pelo controle na fila `input` (003 D-24) | `AppDelegate.swift:112-117` | 🟢 |
| Conflito externo com recarregar ou manter (003 D-25) | `EditorViewModel.swift:223-253` | 🟢 |
| Restaurar padrões grava imediatamente (003 D-26) | `EditorRootView.swift:58-63` | 🟢 |
| Menu "Editar" sem "Sair" (003 P-03) | `EditMenu.swift:3-8` | 🟢 |
| Rolagem só vertical (reteste do PM-1a) | `EditorWindowController.swift:113-115` | 🟢 |
| Acorde aproveitado sem repetição (PM-2) | `ActionPanel.swift:179-186` | 🟢 |

## Estado Interno

`EditorDraft.removedNones`; os `@Published` do modelo; no controlador, `window`, `previousApp`, `closeOutcome`, `closeSheetOpen`, `closeApproved`; na interface, `confirmingRestore`, `confirmingUnset`, `recording`, `group`, `dragging`. Máquina de estados: `state-machines.md` §9. 🟢

## Observabilidade

`editor.opened { source }`, `editor.closed { outcome }`, `editor.conflict { choice }`, `editor.identify { on }`, `editor.activation_failed`. Nos 43 logs locais, nenhum `editor.activation_failed` após a E003 (`domain.md`). 🟢

## Riscos e Lacunas

- 🟢 DV-05, defeito confirmado pelo usuário: `save(confirmBackup: true)` ignora `canSave`; editar o rascunho com a faixa do `.bak` visível permite gravar documento inválido. Correção em `tasks.md` T-10.
- 🟡 Salvar pela folha de fechamento com problemas falha em silêncio: a janela continua aberta sem explicação na folha.
- 🟢 `EditorDraft.restoreDefaults` (`EditorDraft.swift:220`) não é chamado pelo app; a interface usa `ConfigStore.restoreDefaults` (`EditorViewModel.swift:187`) [Revisor].
- 🟡 A reordenação por arrastar depende de `NSItemProvider` com índice textual; arrastar entre janelas não é tratado.
- 🟡 O clique sintético pressupõe a barra de título visível na tela principal; com a janela noutra tela, a conversão usa a altura da tela principal, que é o sistema do Quartz, mas não foi validada com telas empilhadas.
