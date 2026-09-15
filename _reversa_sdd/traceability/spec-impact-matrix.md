# Spec Impact Matrix — joystick-AI

> Gerado pelo Arquiteto em 2026-09-15 · Escala: 🟢 CONFIRMADO · 🟡 INFERIDO
> Leitura: a linha é o módulo alterado; a coluna é o módulo afetado. Base: dependências de código em `.reversa/context/modules.json`, contratos de dados em `data-dictionary.md` e eventos de log em `LogEventCatalog`.

## 1. Matriz

Legenda: **●** impacto direto (chamada, tipo ou contrato compartilhado) · **○** impacto indireto (efeito observável, evento de log ou regra transversal) · vazio: sem impacto conhecido.

| Alterado ↓ / Afetado → | app-shell | controller-input | pointer | injection | shortcuts | palette | config | editor | diagnostics-log | targets-analysis |
|------------------------|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| **app-shell** | — | ● | ● | ● | ● | ● | ● | ● | ● | ● |
| **controller-input** | ○ | — | ● | ○ | ○ | ○ | | ○ | ● | ● |
| **pointer** | ○ | | — | ● | ● | ● | ○ | ● | ● | ● |
| **injection** | ● | | ● | — | ● | ● | | ● | ● | ● |
| **shortcuts** | ○ | | ○ | ● | — | ● | ● | ● | ● | |
| **palette** | ● | | ● | ○ | ● | — | ● | ● | ● | ● |
| **config** | ● | | ○ | | ● | ● | — | ● | ● | ○ |
| **editor** | ● | | ● | ● | ○ | ● | ● | — | ● | |
| **diagnostics-log** | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | — | ● |
| **targets-analysis** | ● | | ○ | | | ● | | | ● | — |

## 2. Contratos que propagam impacto

| Contrato | Definido em | Consumido por | Mudança típica e efeito | Confiança |
|----------|-------------|---------------|-------------------------|-----------|
| `ButtonID` (18 valores e ordem) | controller-input | pointer, shortcuts, palette, config, editor, diagnostics-log, targets-analysis | Novo botão ou reordenação muda a ordem de solturas, o esquema do `config.json`, a figura do editor e `poc-tools buttons` | 🟢 |
| `InputEvent` / `InputSink` | controller-input | pointer (`InputRouter`) | Novo tipo de evento exige tratamento no roteador e em todos os consumidores | 🟢 |
| `PointerSettings` | pointer | config (validação), app-shell (leitura no início), targets-analysis (gravado na rodada), diagnostics-log | Campo novo exige faixa em `PointerSettingsValidation`, padrão e `schemaVersion` da rodada | 🟢 |
| Botões de apontamento (R1, R2, touchpad) | pointer (`ClickStateMachine`), config (`ShortcutConfig.pointerButtons`) | shortcuts, config (validação), editor (figura e rascunho), palette (roteamento) | Tornar um deles configurável quebra 003 RN-05 em quatro módulos | 🟢 |
| `EventInjector.enabled` e marca `0x4A4F5953` | injection | app-shell (portão), editor (`KeyCaptureField`), targets-analysis (cliques válidos) | Mudar a marca invalida o filtro de gravação de acordes e a tela de alvos | 🟢 |
| `KeyboardInjector` único | injection | shortcuts, palette | Dois injetores dessincronizam a contagem de modificadores (002 D-05) | 🟢 |
| `ShortcutConfig`, `TriggerAction`, `KeyCatalog`, `SystemShortcut` | shortcuts / config | editor, palette (ação `openPalette`), config (validação e codificação) | Novo tipo de ação exige decodificador, validação, codificação, `ActionSummary`, painel de ação e mapeador | 🟢 |
| `PaletteItem` e entrada fixa | palette | config, editor (`PaletteTab`), app-shell (argumentos), shortcuts (`openPalette`) | Campo novo muda o esquema e a gravação determinística | 🟢 |
| `ShortcutsDocument` e `ShortcutIssue` | config | editor (`EditorDraft` usa a mesma validação), app-shell (`StatusMenu`) | Regra nova aparece no editor e no ícone de alerta; exige `ConfigLineLocator` para a linha | 🟢 |
| `ConfigStore.onApply` (ordem paleta → atalhos) | config | palette, shortcuts | Inverter a ordem pode abrir a paleta com mapeador antigo | 🟡 |
| `LogEventCatalog` (50 eventos) | diagnostics-log | todos; `poc-tools` depende de `input.button`, `pointer.posted`, `controller.*`, `session.start` | Renomear campos `t_*` ou eventos quebra `latency`, `buttons` e `cycles` | 🟢 |
| `TargetRun` (`schemaVersion` 1) | targets-analysis | `poc-tools runs` | Campo novo sem versão quebra a leitura das rodadas antigas | 🟢 |
| Modo de identificação | editor | pointer (`InputRouter`), palette (fecha com `identify`) | Mudar os botões excluídos altera o que o controle faz com o editor aberto | 🟢 |
| `InjectionGate.onSuspended` | app-shell | targets-analysis (atribuição única) | Segundo consumidor apaga o primeiro (TD-09) | 🟢 |

## 3. Mapa de specs existentes → módulos da extração

| Spec existente | Módulos cobertos | Situação frente ao código |
|----------------|------------------|---------------------------|
| `_reversa_sdd/sdd/app-shell.md` | app-shell, diagnostics-log | Parcial: menu, ícone e editor chegaram na 003; sem ditado |
| `_reversa_sdd/sdd/controller-input.md` | controller-input | Coberta pela 001; PS por HID e modo estendido não estavam previstos |
| `_reversa_sdd/sdd/pointer-control.md` | pointer, injection | Coberta pela 001, com R1/R2 invertidos |
| `_reversa_sdd/sdd/action-mapping.md` | shortcuts, palette, config, editor | Coberta em outra forma pelas 002 e 003 (camadas por modificador em vez de `tap`/`longPress` e modo de condução) 🟡 |
| `_reversa_sdd/sdd/voice-dictation.md` | nenhum | Superada: substituída pelo atalho R3 → ⌘M do Raycast (unit `atalhos`, RN-AT-21) 🟢 |
| `_reversa_forward/001-poc-entrada-ponteiro` | controller-input, pointer, injection, app-shell, diagnostics-log, targets-analysis | Implementada; PM-3 parcial |
| `_reversa_forward/002-paleta-comandos` | palette, shortcuts | Implementada, com E001 |
| `_reversa_forward/003-editor-atalhos` | shortcuts, palette, config, editor, app-shell | Implementada, com E003 a E005 |

## 4. Pontos de alto acoplamento

1. 🟢 **`app-shell`** monta todos os módulos; qualquer novo componente passa por `AppDelegate.applicationDidFinishLaunching`, cuja ordem é regra (RI-02).
2. 🟢 **`pointer` (`InputRouter`)** é o ponto de despacho de toda entrada; mudanças de roteamento afetam atalhos, paleta, editor e tela de alvos ao mesmo tempo.
3. 🟢 **`config` ↔ `editor`** compartilham validação, codificação e padrões; uma regra nova precisa de teste nos dois caminhos (leitura e rascunho).
4. 🟢 **`diagnostics-log` ↔ `targets-analysis`**: o `poc-tools` é consumidor rígido dos nomes de evento e campos `t_*`.
