# Configuração (config)

> Unit do módulo `config` · Gerado pelo Redator em 2026-09-15 · Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA

## Visão Geral

Lê, valida, localiza erros, observa, grava e aplica `~/.config/joystick-ai/config.json`, com três seções: `pointer` (ajustes do ponteiro, lidos só ao iniciar), `shortcuts` e `palette` (validadas em conjunto e reaplicadas sem reiniciar). O app nunca cria o arquivo por conta própria; só o editor grava. 🟢

## Responsabilidades

- Ler o arquivo com limite de tamanho e distinguir ausência, ilegibilidade e JSON inválido. 🟢
- Validar `pointer` campo a campo, trocando valores fora da faixa pelo padrão. 🟢
- Decodificar e validar `shortcuts` e `palette` juntas, recusando ambas diante de qualquer erro. 🟢
- Informar o caminho, a regra e a linha de cada problema, nunca o valor. 🟢
- Observar o arquivo sem varredura e reaplicar alterações externas. 🟢
- Gravar pelo editor com fusão, troca atômica, preservação de *link* simbólico e cópia `.bak` quando o arquivo atual está corrompido. 🟢
- Publicar a configuração vigente à fila `input` e o estado à barra de menus e ao editor. 🟢

## Regras de Negócio

### Leitura

- RN-CF-01: Caminho fixo `~/.config/joystick-ai/config.json`; arquivo ausente usa os padrões (`reason: file_missing`) e não é criado. 🟢
- RN-CF-02: Caminho que é diretório, arquivo acima de 1 MiB (1.048.576 bytes) ou erro de leitura: padrões, `config.unreadable { message }` e problema `unreadable` para atalhos e paleta. 🟢
- RN-CF-03: JSON malformado: padrões para tudo, `config.invalid_json { line?, message }` e problema `syntax` com a linha; raiz que não é objeto: `invalid_json` com problema `wrongType` na linha 1. 🟢
- RN-CF-04: A raiz é decodificada uma vez e entregue às três seções; chaves desconhecidas na raiz são ignoradas e preservadas na gravação. 🟢

### Seção `pointer`

- RN-CF-05: Sem `pointer`, ou `pointer` que não é objeto: padrões com `status defaults`, `reason section_missing`, sem aviso. 🟢
- RN-CF-06: Cada um dos 8 campos é validado isoladamente; `null` ou ausente mantém o padrão sem aviso; valor fora da faixa, de tipo errado ou fracionário em campo inteiro mantém o padrão e registra `config.value_rejected { field, rejected, min, max, default }`. Campos desconhecidos são ignorados. 🟢
- RN-CF-07: Faixas: `touchpadSensitivity` 0,1 a 5,0; `stickMaxSpeed` 150 a 7.500; `stickExponent` 0,5 a 4,0; `deadzone` 0 a 0,5; `scrollSpeed` 1 a 1.000; `precisionFactor` 0,05 a 1,0; `doubleClickIntervalMs` 100 a 2.000 (inteiro); `invertScrollY` booleano. Padrões em `data-dictionary.md` §2.1. 🟢
- RN-CF-08: `pointer` só é lido ao iniciar; alterações posteriores exigem reiniciar o app. 🟢
- RN-CF-09: `config.loaded { status, settings, reason? }` é registrado ao iniciar, exceto quando houve `invalid_json` ou `unreadable`. 🟢

### Seções `shortcuts` e `palette`

- RN-CF-10: Seção ausente vale o padrão; se nenhuma das duas existe, a fonte é `defaults` com `reason section_missing`; se ao menos uma existe e tudo é válido, a fonte é `file`. 🟢
- RN-CF-11: Qualquer problema em qualquer uma das duas recusa ambas; todos os problemas das duas são listados. 🟢
- RN-CF-12: Cada seção exige `version` igual a 1 (ausente ou outro número: `unsupportedVersion`; não inteiro: `wrongType`). 🟢
- RN-CF-13: Regras de forma (`wrongType`): seção, `modifiers`, `layers`, camada e ação devem ser objetos; nomes de botão válidos; lista de modificadores sem repetição; booleanos opcionais valem falso quando ausentes; `palette.items` deve ser lista de objetos com `text` textual. 🟢
- RN-CF-14: Regras de conteúdo: tecla fora do catálogo (`unknownKey`), modificador desconhecido (`unknownModifier`), atalho de sistema desconhecido (`unknownSystemShortcut`), tipo de ação desconhecido (`unknownActionType`). 🟢
- RN-CF-15: Regras semânticas: R1, R2 ou clique do touchpad como modificador ou gatilho (`pointerButtonNotAllowed`); camada de botão que não é modificador (`layerWithoutModifier`); ação atribuída a um modificador (`modifierHasAction`). 🟢
- RN-CF-16: Texto de ação ou item: não vazio (`textEmpty`), uma linha (`multiline`), até 1.000 caracteres (`textTooLong`); rótulo: uma linha, até 80 caracteres (`labelTooLong`); paleta com 1 a 50 itens (`paletteEmpty`, `paletteTooLong`). 🟢
- RN-CF-17: Camada vazia equivale a camada ausente. 🟢
- RN-CF-18: Cada problema recebe a linha do trecho existente mais próximo do caminho (o próprio valor ou o ancestral mais longo presente). 🟢
- RN-CF-19: Log de problemas: `shortcuts.invalid { trigger, rule, path?, line? }`, um por problema, sem valores. 🟢

### Estado vigente

- RN-CF-20: Leitura recusada nunca substitui a vigente; ao iniciar com recusa, valem os padrões e o estado fica inválido com o primeiro problema. 🟢
- RN-CF-21: Releitura externa: arquivo removido mantém a vigente até o próximo início (`shortcuts.file_removed` se havia arquivo, `shortcuts.unchanged` se não havia); *bytes* iguais aos últimos lidos ou gravados não reaplicam (`shortcuts.unchanged`, `debug`); recusa marca inválido e notifica; aceite aplica. 🟢
- RN-CF-22: Aplicar: atualiza vigente, estado válido e fonte; registra `shortcuts.loaded { trigger, source, reason?, modifiers, items }`; entrega o documento à fila `input` (primeiro a paleta, depois os atalhos); notifica os observadores. Ao iniciar não há entrega, pois atalhos e paleta nascem com a vigente. 🟢
- RN-CF-23: Gatilhos: `startup`, `external`, `editor`, `restore`. 🟢

### Observação

- RN-CF-24: Observa o diretório do arquivo, o diretório do destino do *link* e o próprio arquivo de destino (eventos escrita, extensão, renomeação e remoção); diretório inexistente é substituído pelo ancestral existente mais próximo. 🟢
- RN-CF-25: Cada evento reabre as observações e agenda a releitura 150 ms após o último evento. 🟢

### Gravação

- RN-CF-26: O destino segue *links* simbólicos (até 16 níveis), inclusive para destino inexistente; o *link* continua sendo *link*. 🟢
- RN-CF-27: Com arquivo existente de sintaxe inválida ou raiz não objeto, a gravação exige confirmação; confirmada, copia o conteúdo para `config.json.bak` (substituindo cópia anterior) e grava só `shortcuts` e `palette`. 🟢
- RN-CF-28: Com arquivo existente legível, substitui apenas `shortcuts` e `palette` na raiz lida no instante da gravação e preserva o restante, inclusive seções com erros semânticos. 🟢
- RN-CF-29: Serialização determinística: JSON indentado, chaves em ordem alfabética, barras sem escape e quebra de linha final; campos com valor padrão omitidos (`modifiers` vazio no acorde, `repeat` falso, camadas vazias); `pressEnter` e `label` sempre escritos; `modifiers` da seção sempre escrito. 🟢
- RN-CF-30: Cria diretórios intermediários e grava por troca atômica; falha registra `shortcuts.save_failed { message }` com caminho e erro do sistema, sem conteúdo, e não altera a vigente. 🟢
- RN-CF-31: Sucesso registra `shortcuts.saved { created, backup }` (ou `shortcuts.restored` na restauração dos padrões), guarda os *bytes* gravados e aplica com fonte `file`. 🟢
- RN-CF-32: A gravação não reverifica o documento: a validação cabe a quem chama (editor). 🟢 Defeito a corrigir: configuração inválida nunca deve ser gravada (respondida em 2026-09-15, `questions.md` Pergunta 3).

## Requisitos Funcionais

| ID | Requisito | Prioridade | Critério de Aceite |
|----|-----------|-----------|-------------------|
| RF-CF-01 | Ler e validar `pointer` ao iniciar | Must | `deadzone: 0.9` gera `value_rejected` e usa 0,12 |
| RF-CF-02 | Ler e validar `shortcuts` e `palette` em conjunto | Must | Tecla inválida na paleta impede também os atalhos do arquivo |
| RF-CF-03 | Localizar a linha de cada problema | Must | O alerta cita a linha do valor errado |
| RF-CF-04 | Reaplicar alterações externas sem reiniciar | Must | Editar com `vim` (troca atômica) e com `echo >` aplica em até ~200 ms |
| RF-CF-05 | Manter a vigente diante de arquivo inválido ou removido | Must | Apagar o arquivo não muda os atalhos em uso |
| RF-CF-06 | Gravar com fusão e troca atômica | Must | Seção `pointer` e chaves desconhecidas continuam no arquivo após gravar |
| RF-CF-07 | Preservar *link* simbólico dos dotfiles | Must | `config.json` que é *link* continua *link* após gravar |
| RF-CF-08 | Exigir confirmação e `.bak` com arquivo corrompido | Must | Gravar sobre JSON quebrado pede confirmação e cria `config.json.bak` |
| RF-CF-09 | Restaurar padrões | Should | "Restaurar padrões" grava e aplica o mapeamento padrão |
| RF-CF-10 | Publicar o estado à barra de menus e ao editor | Must | Após recusa, o ícone vira alerta e o menu mostra "Configuração inválida: linha N" |

## Requisitos Não Funcionais

| Tipo | Requisito inferido | Evidência no código | Confiança |
|------|--------------------|---------------------|-----------|
| Privacidade | Log e mensagens sem valores do arquivo | `ShortcutConfig.swift:83`, `ConfigWriter.swift:73` | 🟢 |
| Robustez | Arquivo nunca truncado por gravação interrompida | `.atomic` em `ConfigWriter.swift:56` | 🟢 |
| Performance | Observação por eventos do sistema, sem varredura | `ConfigWatcher.swift:3` | 🟢 |
| Reprodutibilidade | Mesmo documento produz os mesmos *bytes* | `ConfigDocument.swift:67-79` | 🟢 |
| Segurança | Limite de 1 MiB na leitura | `ConfigLoader.swift:44` | 🟢 |
| Concorrência | `ConfigStore` e `ConfigWatcher` só na main | `dispatchPrecondition` | 🟢 |

## Critérios de Aceitação

```gherkin
Dado que config.json não existe
Quando o app inicia
Então config.loaded registra status defaults e reason file_missing
E shortcuts.loaded registra source defaults e reason file_missing
E nenhum arquivo é criado

Dado config.json com {"pointer": {"deadzone": 0.9, "scrollSpeed": 30}}
Quando o app inicia
Então deadzone vale o padrão e scrollSpeed vale 30
E config.value_rejected registra field deadzone, min 0, max 0.5

Dado config.json com shortcuts válido e palette.items[2].text com quebra de linha
Quando o arquivo é lido
Então shortcuts e palette são recusados
E shortcuts.invalid registra rule multiline, path palette.items[2].text e a linha do valor

Dado a configuração vigente válida vinda do arquivo
Quando o arquivo é substituído por JSON malformado
Então a vigente continua e o estado passa a inválido com a regra syntax

Dado o editor gravando um documento
Quando o observador dispara com os mesmos bytes gravados
Então shortcuts.unchanged é registrado e nada é reaplicado

Dado config.json com erro de sintaxe na linha 7
Quando o editor grava sem confirmar
Então o resultado pede confirmação citando a linha 7 e nada é gravado

Dado config.json como link para ~/dotfiles/joystick.json
Quando o editor grava
Então o conteúdo novo está em ~/dotfiles/joystick.json e config.json continua sendo link
```

## Prioridade (MoSCoW)

| Requisito | MoSCoW | Justificativa |
|-----------|--------|---------------|
| Leitura e validação | Must | Base de ponteiro, atalhos e paleta |
| Vigente preservada diante de erro | Must | Nunca aplicar configuração inválida |
| Observação e reaplicação | Must | Edição sem reiniciar (003) |
| Gravação com fusão, atômica, *link* | Must | Arquivo dos dotfiles do usuário |
| `.bak` com confirmação | Should | Recuperação de arquivo corrompido |
| Recarga de `pointer` sem reiniciar | Won't (nesta versão) | Fora do escopo da 003 |

## Rastreabilidade de Código

| Arquivo | Função / Classe | Cobertura |
|---------|-----------------|-----------|
| `Sources/JoystickCore/Config/ConfigLoader.swift` | `ConfigStatus`, `ConfigLoadResult`, `ConfigLoader` | 🟢 |
| `Sources/JoystickCore/Config/PointerSettingsValidation.swift` | `ConfigIssue`, `PointerSettingsValidation` | 🟢 |
| `Sources/JoystickCore/Config/ShortcutConfig.swift` | `ShortcutsDocument`, `ShortcutIssue`, `ShortcutIssues` (tipos de ação em `atalhos`) | 🟢 |
| `Sources/JoystickCore/Config/ShortcutConfigValidation.swift` | `ShortcutConfigValidation`, `SectionDecoder` | 🟢 |
| `Sources/JoystickCore/Config/ConfigLineLocator.swift` | `ConfigLineLocator` | 🟢 |
| `Sources/JoystickCore/Config/ConfigDocument.swift` | `ConfigDocument.encode`, `merge` | 🟢 |
| `Sources/JoystickCore/Config/ActionSummary.swift` | `ActionSummary` (usado pela figura do editor) | 🟢 |
| `Sources/JoystickCore/Config/ShortcutDefaults.swift` | Especificado em `atalhos` | 🟢 |
| `Sources/JoystickAIPoC/Config/ConfigStore.swift` | `ConfigState`, `ConfigStore` | 🟢 |
| `Sources/JoystickAIPoC/Config/ConfigWatcher.swift` | `ConfigWatcher` | 🟢 |
| `Sources/JoystickAIPoC/Config/ConfigWriter.swift` | `ConfigWriter` | 🟢 |
