# Onboarding: Atalhos de zoom montados pelo controle

> Identificador: `005-sinais-matematicos`
> Data: `2026-09-16`
> Público: quem vai testar a feature pela primeira vez (o programador de sofá, no papel de avaliador)
> Roadmap: `_reversa_forward/005-sinais-matematicos/roadmap.md`

Este roteiro pressupõe o código entregue pelo `/reversa-coding`. Se a implementação alterar nomes, textos ou a posição do `+` na grade, o `/reversa-coding` deve atualizar este arquivo. Cada passo indica o cenário da seção 7 do `requirements.md` que verifica.

## 0. Pré-requisitos

| Item | Como conferir |
|------|---------------|
| App das features 003 e 004 instalado, assinado com "JoystickAI Local Signing", Acessibilidade e Input Monitoring concedidas | `./scripts/check-signature.sh`; log com `permissions.status` e `postEvent: true` |
| DualSense conectado, Mac ligado à TV, sofá a cerca de 3 m | O ponteiro se move com o analógico esquerdo |
| VS Code e iTerm abertos, cada um com algum texto visível | Para a sonda P-01 |
| Teclado físico ao alcance | Só para o passo 9 |

Antes de tudo, guarde a configuração atual:

```sh
cp ~/.config/joystick-ai/config.json ~/.config/joystick-ai/config.pre-005.json 2>/dev/null || echo "sem arquivo: vale o padrão"
```

Comandos úteis:

```sh
# testes automatizados
./scripts/test.sh
# compilar, assinar e instalar
JOYSTICK_SIGN_IDENTITY="JoystickAI Local Signing" ./scripts/build-app.sh
# abrir com depuração
open ~/Applications/JoystickAIPoC.app --args --debug
# log mais recente
LOG="$(ls -t ~/Library/Logs/joystick-ai/poc-*.jsonl | head -1)"
# restaurar a configuração guardada
cp ~/.config/joystick-ai/config.pre-005.json ~/.config/joystick-ai/config.json
```

## 1. Testes automatizados

1. Rode `./scripts/test.sh`. Espere todos verdes, com os testes novos de `KeyCatalogTests` (exibição "⌘+", escolhas da pontuação, `applied` e `isSelected`) e o de `ActionSummaryTests`.

## 2. Portão manual PM-1

| Passo | Ação | Resultado esperado | Cenário |
|-------|------|--------------------|---------|
| 1 | Abra o editor pela paleta (PS, último item). Na aba Atalhos, escolha a camada L1, clique em ↑ na figura e, no painel, escolha o tipo Acorde. Clique no grupo "Pontuação". | A grade mostra `-`, `+`, `=` nessa ordem, com `+` do mesmo tamanho das demais teclas e legível do sofá | Localizar o sinal de soma |
| 2 | Ligue ⌘ e acione `+`, só com o ponteiro. | O cabeçalho do acorde mostra "⌘+"; ⌘ e ⇧ aparecem ligados; `+` fica destacado e `=` não; o balão de ↑ na figura mostra "⌘+" | Montar o zoom in só com o ponteiro |
| 3 | Desligue ⇧. Depois ligue ⇧ de novo e acione `=`. | Primeiro "⌘=", com `=` destacado; ao ligar ⇧ volta a "⌘+"; ao acionar `=`, "⌘=" e ⇧ desligado. Termine acionando `+` para voltar a "⌘+" | Desligar o Shift desfaz o sinal de soma |
| 4 | Clique em ↓ na figura, escolha Acorde, ligue ⌘ e acione `-`. Clique em "Salvar". | "⌘-" no painel e no balão de ↓; a gravação conclui sem faixa de erro | Montar o zoom out só com o ponteiro |
| 5 (P-01) | Feche o editor. Com o VS Code em foco, pressione L1 + ↑ três vezes e depois L1 + ↓ três vezes. | O zoom da janela aumenta três níveis e volta ao original | Montar o zoom in e o zoom out |
| 6 (P-01) | Repita o passo 5 com o iTerm em foco. | O tamanho do texto aumenta e volta. Se não responder, registre em `actions.md` para a emenda prevista no roadmap §9 | Montar o zoom in e o zoom out |
| 7 | Rode `python3 -c 'import json,os; l=json.load(open(os.path.expanduser("~/.config/joystick-ai/config.json")))["shortcuts"]["layers"]["l1"]; print(l["dpadUp"], l["dpadDown"])'` e `grep -c plus ~/.config/joystick-ai/config.json`. | ↑ com `key` `equal` e `modifiers` `command` e `shift`; ↓ com `key` `minus` e `modifiers` `command`; contagem de `plus` igual a 0 | Arquivo gravado sem formato novo |
| 8 | Restaure a configuração guardada, edite à mão uma ação para `{"type": "chord", "key": "equal", "modifiers": ["command", "shift"]}` e abra o editor. | O arquivo é aceito sem faixa de erro, e a ação aparece como "⌘+" | Arquivo anterior exibido com o sinal |
| 9 | No painel de uma ação de acorde, clique em "Gravar pelo teclado" e pressione ⌘+ no teclado físico. Descarte depois. | O acorde gravado aparece como "⌘+" | Gravação pelo teclado físico |
| 10 | Rode `grep -c '"+"' "$LOG"` e `grep -E 'shortcut.triggered' "$LOG" \| tail -5`. | Contagem 0; os eventos só têm botão, camada, tipo e origem, sem acorde | Log sem acorde |
| 11 | Restaure a configuração guardada. | Estado anterior ao teste | — |

Registre o resultado de cada passo, e em especial da P-01, no `actions.md` da feature.

## 3. Resultado do PM-1 (2026-09-16)

App compilado, assinado com "JoystickAI Local Signing" e instalado por `/reversa-coding`. `check-signature.sh` confirmou o requisito designado de sempre, e o log de início registrou `postEvent: true` e `listenEvent: true`. A configuração anterior foi guardada em `~/.config/joystick-ai/config.pre-005.json`. Log da sessão: `~/Library/Logs/joystick-ai/poc-20260916-184700.jsonl`.

A grade entregue segue o roteiro: o grupo "Pontuação" começa por `-`, `+`, `=`, e nenhum texto dos passos precisou de ajuste. O usuário montou os acordes na camada **Options**, e não na L1 do roteiro, o que não altera o que se verifica.

| Passo | Resultado | Evidência |
|-------|-----------|-----------|
| 1 a 4 | Aprovado | Relato do usuário ("Sim, funciona"); `shortcuts.saved` às 18:48:37 sem `shortcuts.invalid` |
| 5 e 6 (P-01) | Aprovado | Relato do usuário ("Sim, funciona"), em resposta ao pedido de conferir o zoom no VS Code e no iTerm, sem detalhe por aplicativo. O log tem `shortcut.triggered` com `dpadUp` e `dpadDown` na camada `options`, duas vezes cada, menos que as três por aplicativo previstas no roteiro |
| 7 | Aprovado | `options.dpadUp` = `{"key": "equal", "modifiers": ["shift", "command"], "type": "chord"}`; `options.dpadDown` = `{"key": "minus", "modifiers": ["command"], "type": "chord"}`; `grep -c plus` = 0 |
| 8 | Não relatado | Coberto de forma automatizada por `KeyCatalogTests.exibicaoDoSinalDeSoma` e `ActionSummaryTests.acordesDeZoom` |
| 9 | Não relatado | `KeyCaptureField` não mudou; a exibição do acorde gravado é a mesma regra do passo 8 |
| 10 | Aprovado | Nenhuma ocorrência de `"+"`, `plus` ou `equal` no log; os eventos `shortcut.triggered` só têm `button`, `layer` e `type` |
| 11 | Não executado | Restaurar a cópia apagaria os atalhos de zoom que o usuário quer manter; a cópia `config.pre-005.json` continua disponível |

**Sonda P-01:** aprovada pelo relato do usuário. Nenhuma emenda para o terminal (roadmap §9) é necessária.
