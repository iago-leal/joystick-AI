# Delta de dados: Sugestão de palavras no teclado remoto

> Identificador: `009-sugestao-de-palavras`
> Data: `2026-09-19`
> Base: `_reversa_sdd/data-dictionary.md`, `_reversa_forward/008-iphone-teclado-remoto/data-delta.md`
> Confidência: 🟢 salvo indicação

## 1. Arquivos persistidos

| Formato | Mudança | Migração |
|---------|---------|----------|
| `config.json` (`~/.config/joystick-ai/`) | Nenhuma | n/a |
| Log JSONL (`~/Library/Logs/joystick-ai/`) | Campo `suggestions` em `remote.disconnected`; `logSchema` segue 1 (`interfaces/diagnostic-log.md`) | n/a |
| Chaveiro e Application Support (008) | Nenhuma | n/a |

## 2. Itens novos no iPhone

| Item | Local | Conteúdo | Observação |
|------|-------|----------|------------|
| Preferências da faixa | `localStorage` da origem `https://<LocalHostName>.local:47810`, chave `remoteKeyboardPrefs` | `{"lang": "pt" \| "en", "visible": true \| false}`; ausente, vale `{"lang": "pt", "visible": true}` | Não contém conteúdo digitado; lido e gravado dentro de `try`, como o token da 008 |

O token da 008 continua em `sessionStorage`, sem mudança.

## 3. Tipos novos no `JoystickCore`

| Tipo | Campos e casos | Uso |
|------|----------------|-----|
| `SuggestionLanguage` | `.pt`, `.en` | Seletor de RN-05; o app converte em `pt_BR` e `en` |
| `SuggestionMode` | `.complete`, `.next` | Completar a palavra em composição ou prever a seguinte (RN-01, RN-12) |
| `SuggestionQuery` | `text: String` (contexto recente, com o cursor no fim), `mode`, `revision: UInt64` | Pedido ao motor |
| `SuggestionInput` | `.text(String)`, `.backspace`, `.boundary(.space \| .return \| .tab)`, `.discard` | Entrada do contexto |
| `SuggestionContext` | `context: String` (até 200 caracteres), `word: String` (palavra em composição), `lastBoundary`, `revision: UInt64`, `accepted: Int` | Máquina de D-03 |

Operações de `SuggestionContext`:

| Operação | Efeito |
|----------|--------|
| `apply(_: SuggestionInput)` | Atualiza `context` e `word` e sobe `revision`; `.backspace` com `word` vazio e contexto vazio vira `.discard`; `.discard` esvazia tudo |
| `query(visible:)` | `nil` com a faixa oculta, com `word` contendo algo além de letras (RN-13), com `word` vazio e fronteira diferente de espaço ou palavra anterior que não seja só letras (RN-12), ou com contexto vazio; senão, o pedido do modo cabível |
| `filter(_ candidates: [String], for revision:)` | `nil` se a revisão mudou; senão, até três palavras conforme D-04 |
| `accept(_ word: String, revision:)` | `nil` se a revisão mudou ou a palavra não estende `word`; senão, o sufixo seguido de espaço, com `context` atualizado, `word` vazio, fronteira `space` e `accepted + 1` |

## 4. Tipos alterados

| Tipo | Mudança |
|------|---------|
| `RemoteKeyboardMessage.Client` | Casos `prefs(language: SuggestionLanguage, visible: Bool)` e `pick(revision: UInt64, index: Int)` |
| `RemoteKeyboardMessage.Server` | Caso `suggest(revision: UInt64, mode: SuggestionMode, words: [String])`, com até 3 palavras de até 48 caracteres |
| `LogEventCatalog` | `remoteDisconnected(reason:keys:suggestions:)` |
| `RemoteKeyboardMachine` | Sem mudança de estado; o app passa a consultar `modifierStates` para decidir ⇧, ⌥, ⌘ e ⌃ na tradução, no descarte e na aceitação |

## 5. Estado em memória no app

| Estado | Dono | Vida |
|--------|------|------|
| `SuggestionContext`, idioma e visibilidade da sessão | `RemoteKeyboardActions` (fila `input`) | Da conexão à queda; esvaziado a cada descarte |
| Estado de tecla morta | `KeyTextTranslator` (fila `input`) | Zerado a cada descarte e troca de fonte |
| Pedido em curso e pedido pendente | `WordSuggester` (main thread) | Da conexão à queda |
| Etiqueta de documento do motor | `WordSuggester` | Uma por sessão |

Nada desse estado é gravado em disco nem vai ao log (RN-07, RN-08).
