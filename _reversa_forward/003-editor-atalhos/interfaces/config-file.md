# Interface: arquivo de configuração (`shortcuts`, `palette` e gravação)

> Feature: `003-editor-atalhos`
> Tipo: arquivo JSON, leitura e escrita
> Contrato base: `_reversa_forward/001-poc-entrada-ponteiro/interfaces/config-pointer.md` (seção `pointer`, sem alteração de conteúdo)
> Origem: `requirements.md` RN-02 a RN-13, RF-01 a RF-05, RF-20; `roadmap.md` D-01 a D-08, D-15 a D-17
> Confidência: 🟢 salvo indicação

## 1. Localização

`~/.config/joystick-ai/config.json`, como no contrato base. Se o caminho for *link* simbólico, leitura, observação e gravação usam o destino resolvido. O app cria o diretório e o arquivo só ao salvar pelo editor ou ao restaurar o padrão.

## 2. "Request": conteúdo aceito

Raiz: objeto JSON de até 1 MiB (1.048.576 *bytes*). Chaves desconhecidas na raiz são ignoradas na leitura e preservadas na gravação.

### 2.1 Seção `shortcuts`

```json
{
  "shortcuts": {
    "version": 1,
    "modifiers": {
      "l1": [],
      "l2": [],
      "options": ["command"]
    },
    "layers": {
      "base": {
        "dpadUp": { "type": "chord", "key": "upArrow", "repeat": true },
        "cross": { "type": "chord", "key": "return" },
        "create": { "type": "systemShortcut", "name": "missionControl" },
        "r3": { "type": "chord", "key": "m", "modifiers": ["command"] },
        "ps": { "type": "openPalette" },
        "l3": { "type": "none" }
      },
      "l1": {
        "cross": { "type": "text", "text": "CONTINUAR", "pressEnter": true }
      }
    }
  }
}
```

| Campo | Tipo | Regra |
|-------|------|-------|
| `version` | inteiro | Igual a 1. |
| `modifiers` | objeto botão → lista de teclas | Botão pode ser qualquer identificador de `ButtonID` exceto `r1`, `r2` e `touchpadClick`; teclas em `command`, `option`, `control`, `shift`, sem repetição. Objeto vazio: nenhum modificador. |
| `layers` | objeto | Chave `base` ou identificador de um botão presente em `modifiers`. |
| `layers.<camada>` | objeto botão → ação | Botão fora de `modifiers` e diferente de `r1`, `r2` e `touchpadClick`. Na `base`, botão ausente vale `none`; noutra camada, herda da `base`. |
| ação `chord` | `key` (nome do `KeyCatalog`), `modifiers` (lista opcional), `repeat` (booleano opcional, padrão falso) | Tecla conhecida. |
| ação `systemShortcut` | `name` | Um de `spaceLeft`, `spaceRight`, `missionControl`, `applicationWindows`, `nextWindow`; o acorde vem das preferências do macOS no uso. |
| ação `text` | `text`, `pressEnter` (booleano opcional, padrão falso) | Uma linha, de 1 a 1.000 caracteres. |
| ação `openPalette` | nenhum campo | |
| ação `none` | nenhum campo | Na camada de modificador, bloqueia a herança. |

Identificadores de botão (`ButtonID`): `cross`, `circle`, `square`, `triangle`, `l1`, `r1`, `l2`, `r2`, `l3`, `r3`, `options`, `create`, `ps`, `touchpadClick`, `dpadUp`, `dpadDown`, `dpadLeft`, `dpadRight`.

### 2.2 Seção `palette`

```json
{
  "palette": {
    "version": 1,
    "items": [
      { "label": "", "text": "CONTINUAR", "pressEnter": false },
      { "label": "Documentação", "text": "/reversa-docs", "pressEnter": true }
    ]
  }
}
```

| Campo | Tipo | Regra |
|-------|------|-------|
| `version` | inteiro | Igual a 1. |
| `items` | lista | De 1 a 50 itens, na ordem de exibição. A entrada "Editar atalhos" não é gravada. |
| `items[].text` | texto | Uma linha, de 1 a 1.000 caracteres. |
| `items[].label` | texto opcional | Uma linha, até 80 caracteres; vazio ou ausente exibe o texto. 🟡 |
| `items[].pressEnter` | booleano opcional | Padrão falso. |

## 3. "Response": efeito e registro

| Situação | Efeito nos atalhos e na paleta | Registro | Ícone |
|----------|-------------------------------|----------|-------|
| Arquivo ausente ao iniciar | Padrões (`requirements.md` RN-11) | `shortcuts.loaded` com `source: defaults`, `reason: file_missing` | normal |
| Sem `shortcuts` e sem `palette` | Padrões | `shortcuts.loaded` com `reason: section_missing` | normal |
| Só uma das seções presente | Seção presente lida; a outra no padrão | `shortcuts.loaded` com `source: file` | normal |
| Seções válidas | Aplicadas em até 1 s, soltando antes teclas mantidas | `shortcuts.loaded` com `trigger: startup`, `external` ou `editor` | normal |
| Conteúdo igual ao já aplicado | Nada muda | `shortcuts.unchanged` (`debug`) | inalterado |
| Regra da seção 2 violada | Vigente mantida (padrões, no início) | `shortcuts.invalid` com `path`, `line` e `rule` | alerta |
| Erro de sintaxe | Vigente mantida; `pointer` padrão se for o início | `shortcuts.invalid` com `line` e `rule: syntax`, além de `config.invalid_json` no início (001) | alerta |
| Arquivo removido com o app aberto | Vigente mantida até reiniciar | `shortcuts.file_removed` | inalterado |
| Arquivo ilegível ou acima de 1 MiB | Vigente mantida | `shortcuts.invalid` com `rule: unreadable` | alerta |

A seção `pointer` continua lida só ao iniciar, com os eventos `config.*` do contrato base.

## 4. Gravação

1. Resolver *link* simbólico e ler a raiz atual do destino.
2. Raiz válida: substituir `shortcuts` e `palette`, mantendo as demais chaves. Arquivo ausente: criar objeto com as duas seções. Erro de sintaxe: pedir confirmação no editor, copiar o conteúdo atual para `config.json.bak` no mesmo diretório e criar objeto com as duas seções.
3. Serializar com indentação, chaves em ordem alfabética e barras sem escape.
4. Gravar por arquivo temporário e troca atômica no destino, criando o diretório se necessário.
5. Guardar os *bytes* gravados como última leitura, para que a observação não reaplique nem acuse conflito.
6. Aplicar a configuração gravada e registrar `shortcuts.saved { created, backup }`.

| Erro | Efeito | Registro |
|------|--------|----------|
| Sem permissão de escrita no diretório | Nada gravado; vigente e rascunho mantidos; editor mostra o caminho | `shortcuts.save_failed` com caminho e erro do sistema |
| Disco cheio ou falha na troca | Arquivo anterior intacto; mesmo tratamento | idem |
| Rascunho inválido | "Salvar" desabilitado; nenhuma tentativa | nenhum |

## 5. Idempotência e concorrência

- Gravar duas vezes o mesmo rascunho produz os mesmos *bytes*.
- Gravação externa durante a edição: a próxima gravação do editor funde sobre o conteúdo mais recente do disco (passo 1); com rascunho sujo, o editor avisa antes (`roadmap.md` D-25).
- Leitura durante gravação externa não atômica pode encontrar JSON truncado: vira `shortcuts.invalid` com `rule: syntax`, e a gravação seguinte do outro programa gera nova leitura.
- Várias notificações em sequência geram uma releitura, 150 ms após a última.

## 6. Timeouts e limites

- Aplicação em até 1 s após a gravação (`requirements.md`, RNF de desempenho).
- 1 MiB por arquivo; 50 itens na paleta; 1.000 caracteres por texto; 80 por rótulo.
- Nenhum limite de modificadores além dos 15 botões elegíveis.

## 7. Compatibilidade

- A versão da feature 002 ignora `shortcuts` e `palette` e continua lendo `pointer`.
- `version` diferente de 1 é recusada como `unsupportedVersion`, o que reserva migrações futuras.
- A mensagem de erro nunca inclui o valor recusado, apenas caminho, linha e regra (`requirements.md` RN-14).
