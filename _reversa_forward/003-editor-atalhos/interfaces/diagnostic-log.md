# Interface: log de diagnóstico (delta do editor)

> Feature: `003-editor-atalhos`
> Tipo: arquivo, escrita (JSON Lines)
> Contrato base: `_reversa_forward/001-poc-entrada-ponteiro/interfaces/diagnostic-log.md`, com o delta de `_reversa_forward/002-paleta-comandos/interfaces/diagnostic-log.md`
> Origem: `requirements.md` RN-14, RNF de observabilidade e de privacidade; `roadmap.md` D-14, D-27
> Confidência: 🟢 salvo indicação

## 1. O que muda

Localização, formato do registro, *flush*, ordem e tratamento de erros seguem o contrato base. `logSchema` continua `1`: entram eventos novos e um valor novo num campo enumerado, sem mudança de campo existente. Os consumidores do `poc-tools` ignoram eventos desconhecidos.

## 2. Eventos novos

| Evento | Nível | Campos | Quando | Requisito |
|--------|-------|--------|--------|-----------|
| `shortcuts.loaded` | info | `trigger: startup \| external \| editor \| restore`, `source: defaults \| file`, `reason?: file_missing \| section_missing`, `modifiers: [string]`, `items: int` | Uma configuração válida passou a vigorar. | RF-01, RF-03 |
| `shortcuts.unchanged` | debug | `trigger` | Releitura com conteúdo igual ao vigente. | RF-03 |
| `shortcuts.invalid` | error | `trigger`, `rule`, `path?`, `line?` | Leitura recusada; vigente mantida. | RF-04, RF-20 |
| `shortcuts.file_removed` | info | nenhum | Arquivo removido com o app aberto. | RN-10 |
| `shortcuts.saved` | info | `created: bool`, `backup: bool` | Gravação pelo editor concluída. | RF-05, RF-13 |
| `shortcuts.save_failed` | error | `message` | Gravação recusada pelo sistema; `message` traz caminho e erro do sistema. | RF-05 |
| `shortcuts.restored` | info | nenhum | Padrão restaurado e gravado. | RF-15 |
| `shortcut.triggered` | info | `button`, `layer: base \| <botão>`, `type: chord \| systemShortcut \| text \| openPalette` | Um botão executou ação diferente de "nenhuma". | RN-14 |
| `editor.opened` | info | `source: menu \| palette \| alert` | Janela do editor exibida. | RF-06, RF-07 |
| `editor.closed` | info | `outcome: clean \| saved \| discarded` | Janela fechada. | RF-13 |
| `editor.conflict` | warn | `choice: reload \| keep \| pending` | Gravação externa com rascunho sujo. | RF-18 |
| `editor.identify` | info | `on: bool` | Modo de identificação ligado ou desligado. | RF-16 |
| `editor.activation_failed` | warn | nenhum | A janela não se tornou ativa após o pedido (sonda P-01). 🟡 | RF-07 |

Valores de `rule`: os de `data-delta.md` §2 (`ShortcutIssue.rule`), acrescidos de `syntax` e `unreadable`.

## 3. Evento alterado

| Evento | Campo | Antes | Depois |
|--------|-------|-------|--------|
| `palette.closed` | `reason` | `circle \| ps \| disconnected \| injection_suspended \| idle` | Acrescenta `config_changed`, quando uma configuração nova é aplicada com a paleta aberta, e `identify`, quando o modo de identificação do editor é ligado com a paleta aberta (D-24; acrescentado no `/reversa-coding`, T057). |

Confirmar "Editar atalhos" na paleta não gera `palette.confirmed`; gera `editor.opened` com `source: palette`.

## 4. Privacidade

- Nenhum evento contém texto de item ou de ação, rótulo, nome de tecla, acorde gravado ou montado, nem teclas injetadas (RN-14).
- `path` identifica a posição no arquivo (`shortcuts.layers.l1.cross`, `palette.items[3].text`), nunca o valor.
- Com a paleta editável, `palette.confirmed { index, enter }` deixa de apontar um texto público; o índice continua sem revelar conteúdo.
- A captura de acorde não gera evento por tecla; só a gravação da configuração é registrada.

## 5. Latências deriváveis

- Execução de atalho: `shortcut.triggered.ts_ns − input.button(down).ts_ns`, com `--debug`; inclui a leitura das preferências em `systemShortcut` (`roadmap.md` D-11).
- Recarga externa: diferença entre a data de modificação do arquivo e o `wall` de `shortcuts.loaded` com `trigger: external`, como indicador; o limite de 1 s é verificado no portão manual.

## 6. Exemplo

```json
{"ts_ns":812345678901,"wall":"2026-09-16T21:02:10.112-03:00","level":"info","event":"editor.opened","source":"palette"}
{"ts_ns":845901234567,"wall":"2026-09-16T21:02:43.668-03:00","level":"info","event":"shortcuts.saved","backup":false,"created":false}
{"ts_ns":845912345678,"wall":"2026-09-16T21:02:43.679-03:00","level":"info","event":"shortcuts.loaded","items":18,"modifiers":["l1","l2","l3","options"],"source":"file","trigger":"editor"}
{"ts_ns":851001234567,"wall":"2026-09-16T21:02:48.768-03:00","level":"info","event":"shortcut.triggered","button":"circle","layer":"l3","type":"systemShortcut"}
{"ts_ns":990001234567,"wall":"2026-09-16T21:05:07.768-03:00","level":"error","event":"shortcuts.invalid","line":12,"rule":"syntax","trigger":"external"}
```
