# Data delta: Editor de atalhos e comandos

> Identificador: `003-editor-atalhos`
> Data: `2026-09-14`
> Base: `_reversa_sdd/sdd/action-mapping.md#9. Modelo de Dados` e o código entregue pelas features 001 e 002
> Confidência: 🟢 salvo indicação

## 1. Persistência

Primeira escrita em disco feita pelo app além do log. `~/.config/joystick-ai/config.json` ganha duas seções, `shortcuts` e `palette`, gravadas só quando o usuário salva no editor ou restaura o padrão. A seção `pointer` e qualquer outra chave da raiz são preservadas por valor. Formato, regras e comportamento de gravação em `interfaces/config-file.md`.

| Situação no disco | Leitura | Gravação pelo editor |
|-------------------|---------|----------------------|
| Arquivo ausente | Padrões de mapeamento e paleta; `pointer` padrão | Cria diretório e arquivo com `shortcuts` e `palette` |
| Só `pointer` (caso da máquina de uso) | Padrões de mapeamento e paleta; `pointer` lido | Acrescenta as duas seções, mantendo `pointer` |
| Seções válidas | Valores lidos | Substitui as duas seções |
| Seção inválida | Mantém a vigente (padrões, se for o início); alerta | Substitui as duas seções |
| Erro de sintaxe | Mantém a vigente; alerta | Pede confirmação, copia o conteúdo para `config.json.bak` e grava as duas seções num objeto novo |

Números de `pointer` são relidos como `JSONValue` e regravados pelo `JSONEncoder`: `2.0` pode voltar como `2`, com o mesmo valor. 🟡

## 2. Tipos novos em `JoystickCore`

```
KeyCatalog                                  // Sources/JoystickCore/Shortcuts/KeyCatalog.swift (D-03)
  entries: [KeyEntry]
KeyEntry {
  name: String                              // nome no arquivo: "z", "return", "upArrow", "f5", "leftBracket"
  keyCode: UInt16                           // tecla virtual kVK_*
  display: String                           // "Z", "Return", "↑", "F5", "["
  group: Enum                               // letters | digits | punctuation | editing | navigation | function
}

TriggerAction: Enum                         // Sources/JoystickCore/Config/ShortcutConfig.swift (D-02)
  chord(KeyChord, repeats: Bool)
  systemShortcut(SystemShortcut)
  text(String, pressEnter: Bool)            // uma linha, 1 a 1.000 caracteres (RN-13)
  openPalette
  none

ShortcutConfig {
  modifiers: [ButtonID: Set<KeyModifier>]   // botão modificador → teclas mantidas enquanto segurado (RN-04)
  layers: [ButtonID?: [ButtonID: TriggerAction]]  // nil = base; ausência na camada de modificador = herdar (RN-02)
}

ShortcutsDocument {
  shortcuts: ShortcutConfig
  palette: [PaletteItem]                    // 1 a 50 itens (RN-12)
}

ShortcutIssue {
  path: String                              // "shortcuts.layers.l2.dpadLeft", "palette.items[3].text"
  rule: Enum                                // unsupportedVersion | pointerButtonNotAllowed | layerWithoutModifier |
                                            // modifierHasAction | unknownKey | unknownModifier | unknownSystemShortcut |
                                            // unknownActionType | textEmpty | textTooLong | multiline | labelTooLong |
                                            // paletteEmpty | paletteTooLong | wrongType
  line: Int?                                // preenchida pelo ConfigLineLocator (D-06)
}

ShortcutDefaults.config: ShortcutConfig     // tabela de requirements.md RN-11 (D-04)
PaletteDefaults.items: [PaletteItem]        // os 17 itens da feature 002, sem Enter e sem rótulo

EditorDraft {                               // Sources/JoystickCore/Config/EditorDraft.swift (D-20)
  base: ShortcutsDocument                   // vigente quando o rascunho foi criado ou recarregado
  document: ShortcutsDocument               // rascunho
  isDirty: Bool                             // document != base
  issues: [EditorIssue]                     // bloqueiam "Salvar"
  warnings: [EditorWarning]                 // não bloqueiam: noPaletteTrigger
}
EditorIssue { target: EditorTarget, rule: ShortcutIssue.Rule }
EditorTarget: Enum                          // trigger(layer: ButtonID?, button: ButtonID) | modifier(ButtonID) | paletteItem(Int)
EditorOperationError: Enum                  // lastPaletteItem | paletteFull | multiline | textTooLong | labelTooLong | pointerButton
```

`ConfigLineLocator.line(of path: String, in data: Data) -> Int?` e `ConfigDocument.merge(existing: JSONValue?, document: ShortcutsDocument) -> Data` completam o núcleo.

## 3. Tipos alterados

| Tipo | Antes | Depois |
|------|-------|--------|
| `PaletteItem` | `text`, `pressEnter` | Acrescenta `label: String` (vazio exibe o texto); ganha `displayText`. |
| `CommandPalette.items` | Lista fixa usada por máquina e painel | Passa a `PaletteDefaults.items`; máquina e painel recebem a lista vigente. |
| `PaletteMachine` | `items` fixos; confirmação sempre digita | Recebe itens configurados e acrescenta a entrada fixa "Editar atalhos" no índice `items.count`; confirmá-la produz `openEditor`. `selection` percorre `items.count + 1` posições. |
| `PaletteEffect` | `render`, `startRepeat`, `stopRepeat`, `confirm`, `closed` | Acrescenta `openEditor`. |
| `PaletteCloseReason` | `circle`, `ps`, `disconnected`, `injection_suspended`, `idle` | Acrescenta `config_changed`. |
| `ShortcutMapper` | `switch` fixo; `systemChords` na criação | Recebe `ShortcutConfig`; guarda `modifierOrder: [ButtonID]` e `resolved: [ButtonID: ResolvedAction]`; sem `systemChords`. |
| `ShortcutAction` | `keyDown`, `keyUp`, `text`, `modifierDown`, `modifierUp`, `openPalette` | Acrescenta `systemDown(SystemShortcut)` e `systemUp(SystemShortcut)`; `keyDown` carrega também o botão e a camada para o log de `shortcut.triggered`. 🟡 |
| `SystemShortcut` | `rawValue` numérico | Acrescenta `name` estável e `init?(name:)`. |
| `ConfigLoadResult` | `settings`, `status`, `reason`, `issues` | Acrescenta `shortcuts: ShortcutsDocument`, `shortcutsSource` (`defaults` ou `file`) e `shortcutIssues: [ShortcutIssue]`. |
| `LogEventCatalog` | eventos da 001 e da 002 | Eventos de `interfaces/diagnostic-log.md` §2. |

## 4. Resolução de um botão pressionado (`ShortcutMapper.press`)

| Condição, na ordem | Resultado |
|--------------------|-----------|
| Botão já em `held` | `[]` |
| R1, R2 ou clique do touchpad | `[]` (cliques em `ButtonActions`) |
| Botão é modificador em `config.modifiers` | Acrescenta a `modifierOrder`; `modifierDown` de cada tecla mantida, em ordem estável |
| Há modificador em `modifierOrder` | Camada = `modifierOrder.first`; ação = `layers[camada][botão] ?? layers[nil][botão] ?? .none` |
| Sem modificador | Ação = `layers[nil][botão] ?? .none` |
| Ação `chord` | `keyDown(chord, repeats)`; guarda o acorde para o soltar |
| Ação `systemShortcut` | `systemDown(atalho)`; guarda o atalho para o soltar |
| Ação `text` | `text(texto, pressEnter)`; nada a soltar |
| Ação `openPalette` | `openPalette` |
| Ação `none` | `[]` |

`release` devolve `keyUp` ou `systemUp` do que foi guardado no pressionar, ou `modifierUp` das teclas mantidas se o botão for modificador (removendo-o de `modifierOrder`). `releaseAll` solta tudo e esvazia `held`, `modifierOrder` e `resolved`.

Invariantes verificados em teste: a ação solta é sempre a resolvida no pressionar; nenhum botão de apontamento produz ação; um modificador nunca produz ação de tecla; após `releaseAll`, as contagens de modificadores voltam a zero.

## 5. Estado em memória no app

```
ConfigState {                               // main thread, ConfigStore (D-15)
  current: ShortcutsDocument                // vigente
  status: Enum                              // valid | invalid(ShortcutIssue) | invalidSyntax(line: Int?, message)
  lastBytes: Data?                          // última leitura; iguala a própria gravação (D-16)
  source: Enum                              // defaults | file
}

EditorViewModel {                           // main thread (D-20)
  draft: EditorDraft
  selectedLayer: ButtonID?
  selectedButton: ButtonID?
  identifying: Bool                         // espelhado na fila input (D-24)
  conflict: Enum?                           // externalChange | externalInvalid(line)
  previousApp: NSRunningApplication?        // devolução de foco (D-23)
}
```

Nada disso é persistido; fechar o app descarta rascunho, seleção e último item confirmado da paleta.

## 6. Reflexo esperado na extração (para o `/reversa-sync`)

- `action-mapping` §9: substituir `Mapping` e `Action` por `ShortcutConfig`, `TriggerAction` e `PaletteItem { label, text, pressEnter }`; retirar `openApp`, `mouseLeft`, `mouseRight`, `dictation`, `toggleMode` e os gatilhos `tap`, `longPress` e `hold` do modelo vigente.
- `action-mapping` RF-02: o arquivo passa a ser criado ao salvar, e não ao iniciar.
- `action-mapping` NG-01 e `app-shell` NG-03: revogados.
- `action-mapping` §15: L1 deixa de ser o único modificador; vale a camada do modificador segurado há mais tempo.
- `app-shell` §9 `AppState.configStatus`: materializado em `ConfigState.status`, exibido só como alerta no ícone.
