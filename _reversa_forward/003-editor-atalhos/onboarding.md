# Onboarding: Editor de atalhos e comandos

> Identificador: `003-editor-atalhos`
> Data: `2026-09-14`
> Público: quem vai testar o editor pela primeira vez (o programador de sofá, no papel de avaliador)
> Roadmap: `_reversa_forward/003-editor-atalhos/roadmap.md`

Este roteiro pressupõe o código entregue pelo `/reversa-coding`. Se a implementação alterar nomes de arquivo, eventos ou textos da interface, o `/reversa-coding` deve atualizar este arquivo. Cada passo indica o cenário da seção 7 do `requirements.md` que verifica.

## 0. Pré-requisitos

| Item | Como conferir |
|------|---------------|
| App das features 001 e 002 instalado, assinado com "JoystickAI Local Signing" e com Acessibilidade concedida | `./scripts/check-signature.sh`; log com `permissions.status` e `postEvent: true` |
| Botão PS sem ação do sistema | Ajustes do Sistema > Controles de jogo > DualSense > "Pressione o Botão de Início para abrir": **Nenhum** |
| Raycast com o ditado em Command+M | Pressionar R3 num campo de texto qualquer e ditar |
| Terminal com o Claude Code e VS Code | abrir ambos |
| Mac ligado à TV, sofá a cerca de 3 m | para P-05 e para o passo de legibilidade |
| Teclado físico ao alcance | só para P-02 e para o cenário de gravação de acorde |

Antes de tudo, guarde a configuração atual, que tem a seção `pointer` calibrada:

```sh
cp ~/.config/joystick-ai/config.json ~/.config/joystick-ai/config.pre-003.json
```

Comandos úteis:

```sh
# compilar, assinar e instalar
JOYSTICK_SIGN_IDENTITY="JoystickAI Local Signing" ./scripts/build-app.sh
# abrir com depuração
open ~/Applications/JoystickAIPoC.app --args --debug
# encerrar
osascript -e 'quit app "JoystickAIPoC"'
# log mais recente
LOG="$(ls -t ~/Library/Logs/joystick-ai/poc-*.jsonl | head -1)"
grep -E '"(shortcuts?|editor|palette\.closed|pointer\.injection)' "$LOG"
# restaurar a configuração guardada
cp ~/.config/joystick-ai/config.pre-003.json ~/.config/joystick-ai/config.json
```

## 1. Portões PM-1a e PM-1b: sondas

As sondas se dividem em dois portões (`actions.md`, ajustes de ordem 1 e 2):

- **PM-1a**, logo após as ações T001 a T014 e T076: P-01, P-02, P-03 e P-05, com o editor mínimo da Fase 0. Esse editor tem o item "Editar atalhos" no ícone e na paleta e uma janela com um campo de texto, um botão "Gravar pelo teclado", botões de 44 pt e o texto de exemplo nas métricas de TV.
- **PM-1b**, depois de T060: P-04, com a recarga externa já ligada, para que a releitura apareça no log como `shortcuts.loaded`, `shortcuts.invalid` ou `shortcuts.unchanged` com `trigger: external`. Não execute P-04 no PM-1a: o editor mínimo ainda não observa o arquivo.

### P-01, ativação e devolução do foco (PM-1a)

1. Abra o app com `--debug`, deixe o Terminal em foco e, só pelo controle, pressione PS, vá a "Editar atalhos" e confirme com ✕.
2. Anote se a janela veio para a frente, se o nome do app aparece na barra de menus e se o campo de texto recebe o cursor.
3. Feche a janela com um clique do controle e confira se o Terminal voltou a ficar em foco.
4. Repita abrindo pelo ícone da barra de menus com o ponteiro do controle.
5. Se a janela não vier para a frente pela paleta, registre também se `editor.activation_failed` apareceu no log.

### P-02, captura de teclado (PM-1a)

1. Clique em "Gravar pelo teclado" e pressione Command+Shift+Z no teclado físico; anote o que foi capturado.
2. Clique de novo em "Gravar pelo teclado" e, com a gravação ativa, pressione ✕ no controle; nada deve ser capturado.
3. Tente Command+Tab, Command+Space e Command+Q no teclado físico; anote quais chegam ao campo e se algum encerra o app.
4. Com o campo inativo, digite no Terminal e confira que nada muda no editor.

### P-03, ditado nos campos (PM-1a)

1. Clique no campo de texto do editor com o controle e pressione R3.
2. Dite "barra reversa docs" e anote se o texto entrou no campo do editor, e não no aplicativo anterior.

### P-04, observação do arquivo (PM-1b)

1. Com o app aberto e `--debug`, grave o arquivo pelo VS Code, pelo `vim` e por `echo '{}' > ~/.config/joystick-ai/config.json`; restaure a cópia depois de cada teste.
2. Mova um arquivo por cima: `cp ~/.config/joystick-ai/config.pre-003.json /tmp/c.json && mv /tmp/c.json ~/.config/joystick-ai/config.json`.
3. Troque o arquivo por *link* simbólico para uma cópia em outro diretório e grave a cópia.
4. Em cada caso, confira no log se houve `shortcuts.loaded`, `shortcuts.invalid` ou `shortcuts.unchanged` com `trigger: external` em até 1 s após a gravação.

### P-05, legibilidade (PM-1a)

1. Com a janela mínima na TV, sente-se a 3 m e leia o texto de exemplo.
2. Clique três vezes seguidas no botão "Clique aqui" usando o analógico e R1; o contador deve chegar a 3. Anote os erros.
3. Numa tela de 900 pt de altura, confira se a janela cabe com rolagem.

No PM-1a, registre os quatro resultados (P-01, P-02, P-03 e P-05) nas notas de execução do `actions.md`; eles alimentam T015 e T016. No PM-1b, registre o resultado de P-04, que alimenta T061.

**Resultados.** O PM-1a foi aprovado na rodada 6: P-01 pela emenda E003 (janela flutuante com clique de ativação), P-02, P-03 e P-05 com texto de 32 pt e alvos de 60 pt. P-03 só passou depois do menu Editar, porque o ditado do Raycast insere o texto colando; sem limitação a registrar. O PM-1b foi aprovado na rodada 8, sem ajuste no `ConfigWatcher`: cada gravação gerou um evento `trigger: external` em até 280 ms, inclusive `mv` por cima, *link* simbólico e erro de sintaxe. A gravação pela interface do VS Code e o `vim` com o `vimrc` do usuário não foram exercitados na P-04 e ficam nos passos 2 e 26 do PM-2.

## 2. Portão PM-2: cenários do editor

Abra o app com `--debug`. Entre um grupo de passos e outro, restaure a configuração guardada quando o passo pedir arquivo em estado conhecido.

**Amostras.** `scripts/config-samples/` traz quatro arquivos gerados pelo próprio código de gravação, todos com a seção `pointer` de `stick-1800.json` (`stickMaxSpeed` 1800, lida só ao abrir o app):

| Amostra | Conteúdo | Leitura esperada |
|---------|----------|------------------|
| `l3-modifier.json` | Padrão com L3 modificador e L3+○ em Mission Control | válida, 17 itens, modificadores L1, L2, L3 e Options |
| `palette-reversa-docs.json` | Padrão com `/reversa-docs`, Enter ao final, no topo da paleta | válida, 18 itens |
| `r1-in-layer.json` | Padrão com R1 na camada L1 | `shortcuts.invalid { rule: pointerButtonNotAllowed, line: 159 }` |
| `invalid-line12.json` | Padrão com vírgula faltando na linha 12 | `shortcuts.invalid { rule: syntax, line: 12 }` |

Uma seção `shortcuts` ou `palette` presente no arquivo substitui o padrão por inteiro. Para editar o JSON à mão, parta de uma amostra ou de um arquivo salvo pelo editor, nunca de um arquivo só com `pointer`. Nos exemplos, `CFG=~/.config/joystick-ai/config.json` e `S=scripts/config-samples`, a partir da raiz do repositório.

| # | Passo | Resultado esperado | Cenário |
|---|-------|--------------------|---------|
| 1 | Encerrar o app; `mv $CFG ~/.config/joystick-ai/config.off.json`; abrir o app; ✕, L1+✕, L2+← e PS | Log com `shortcuts.loaded { trigger: startup, source: defaults, reason: file_missing }`; Enter, `CONTINUAR` com Enter, troca de mesa, paleta com 17 itens e "Editar atalhos"; arquivo continua ausente. Depois, desfazer o `mv` | Padrão sem arquivo |
| 2 | `cp $S/l3-modifier.json $CFG`; no VS Code, em `shortcuts.layers.base`, trocar `triangle` por `{ "key": "z", "modifiers": ["command"], "type": "chord" }`; salvar pela interface do VS Code; △ no VS Code | `shortcuts.loaded { trigger: external, source: file }`; desfaz em até 1 s | Ação carregada do arquivo |
| 3 | No editor, L3: desmarcar "Este botão é modificador" e confirmar "Remover a camada L3 e as ações dela"; salvar. Marcar de novo, escolher a camada L3, ○, "Atalho de sistema", "Mission Control"; salvar; L3+○ e depois L3+✕ | Depois da primeira gravação, L3+○ faz Esc; depois da segunda, Mission Control; L3+✕ faz Enter herdado; `shortcuts.saved` a cada gravação | Camada nova com herança; Marcar modificador |
| 4 | Segurar L1, depois L2, e pressionar ✕; soltar; segurar L2, depois L1, e pressionar ✕ | `CONTINUAR` com Enter; depois Enter | Precedência entre modificadores |
| 5 | `cp $S/r1-in-layer.json $CFG`; R1 num botão qualquer | Ícone com alerta; no menu, "Configuração inválida: linha 159"; `shortcuts.invalid { rule: pointerButtonNotAllowed, line: 159 }`; R1 continua clicando. Escolher o item do alerta abre o editor com a faixa "O arquivo de configuração tem erro na linha 159: …" | Botões de apontamento fixos; Alerta de configuração inválida |
| 6 | `cp $S/l3-modifier.json $CFG`; segurar □ num campo com texto e, com □ segurado, trocar no VS Code `shortcuts.layers.base.circle` por `{ "key": "tab", "type": "chord" }` e salvar | Alerta some; repetição de □ para, nada preso; ○ faz Tab em até 1 s | Alteração externa aplicada |
| 7 | `cp $S/invalid-line12.json $CFG`; ○; depois `cp $S/l3-modifier.json $CFG` e ○ | ○ segue em Tab; log e menu citam a linha 12 (`rule: syntax`); depois da cópia válida, alerta some e ○ volta a Esc | Arquivo inválido; Alerta de configuração inválida |
| 8 | `cp ~/.config/joystick-ai/config.pre-003.json $CFG`; alterar um atalho no editor e salvar; comparar `pointer` com a cópia guardada | `pointer` com os mesmos campos e valores; atalho novo vale | Seções preservadas ao salvar |
| 9 | `chmod a-w ~/.config/joystick-ai`; alterar e salvar no editor; `chmod u+w ~/.config/joystick-ai` | Faixa "Não foi possível gravar." com o caminho e o erro do sistema; `shortcuts.save_failed`; vigente e rascunho mantidos; salvar de novo depois do `chmod` grava | Pasta sem permissão de escrita |
| 10 | Pôr uma cópia do arquivo em outro diretório e trocar `$CFG` por *link* simbólico para ela (`mkdir -p ~/joystick-link && cp $CFG ~/joystick-link/config.json && ln -sf ~/joystick-link/config.json $CFG`); alterar e salvar no editor; `ls -l $CFG`; conferir a cópia. Depois, `rm $CFG && cp ~/.config/joystick-ai/config.pre-003.json $CFG` | `$CFG` continua *link*; a cópia tem a alteração e o mesmo `pointer`; `shortcuts.saved` e, pela observação do arquivo, no máximo `shortcuts.unchanged { trigger: external }` | Gravação através de *link* simbólico (D-17) |
| 11 | Ícone da barra de menus: "Editar atalhos"; depois "Sair" com □ segurado | Editor em primeiro plano; app encerra sem Backspace preso | Ícone na barra de menus |
| 12 | Terminal em foco; PS, "Editar atalhos", ✕ | Editor acima do Terminal e em foco, sem `editor.activation_failed`; o ponteiro volta ao lugar depois do clique automático; nada digitado no Terminal (E003) | Editor aberto pela paleta |
| 13 | Camada L2 no editor | ← "mesa à esquerda"; ✕ "Enter (herdado)"; R1 "clique esquerdo, fixo" | Visão de uma camada |
| 14 | Atribuir Command+Z a L1+○ por "Gravar pelo teclado"; salvar; L1+○ | Desfaz em até 1 s | Atribuir e salvar; Gravação de acorde |
| 15 | Gravação ativa: Command+Shift+Z no teclado e ✕ no controle | Capturado Command+Shift+Z; nenhum Enter | Gravação de acorde |
| 16 | Sem teclado: montar Tab com Command para um gatilho pela grade de teclas e pelo alternador Command; salvar; acionar | Command+Tab executado | Acorde montado pelo controle |
| 17 | Gravação inativa; digitar no Terminal; conferir o log | Nada capturado; nenhuma tecla no log | Captura restrita ao campo |
| 18 | Marcar L3 como modificador mantendo Control, sem ação própria para ←; salvar; segurar L3 e pressionar ← | ← herdado com Control mantido: troca para a mesa à esquerda | Marcar modificador |
| 19 | Marcar ✕ como modificador sem remover Enter da base | "Salvar" desabilitado; ✕ destacado na figura; no painel, "botão modificador não pode ter ação; escolha Herdar ou remova a ação"; rodapé com a contagem de problemas | Salvar bloqueado |
| 20 | Alterar algo, fechar a janela, Cancelar; fechar de novo, Descartar | Folha "Salvar as alterações dos atalhos?"; com Cancelar, janela aberta com a alteração; com Descartar, vigente sem mudança e `editor.closed { outcome: discarded }` | Fechar com alteração pendente |
| 21 | Aba Paleta: "Incluir no topo", texto `/reversa-docs`, Enter ligado; salvar; PS; confirmar. Conferir `palette` contra a amostra: `python3 -c 'import json,os; a=json.load(open(os.path.expanduser("~/.config/joystick-ai/config.json"))); b=json.load(open("scripts/config-samples/palette-reversa-docs.json")); print(a["palette"] == b["palette"])'` | Topo da paleta; "Editar atalhos" no fim; comando digitado e enviado; `True` | Editar a paleta |
| 22 | Tentar remover o único item; incluir o 51.º; colar ou ditar texto com quebra de linha | Operações impedidas: "A paleta precisa de ao menos um item.", "A paleta aceita no máximo 50 itens.", "O texto deve ter uma única linha." Se o campo descartar a quebra de linha antes de chegar ao rascunho, anote | Limites da paleta |
| 23 | "Restaurar padrão", Cancelar; "Restaurar padrão", "Restaurar e gravar" | Nada muda; depois, padrões gravados e `shortcuts.restored` | Restaurar padrão |
| 24 | Ligar "Identificar pelo controle"; pressionar △; clicar com R1 num controle do editor; trocar para outro aplicativo | △ selecionado sem Tab; clique funciona; `editor.identify { on: true }`; ao perder o foco, `editor.identify { on: false }` | Modo de identificação |
| 25 | Observar a figura | □ à esquerda do grupo de ação; L1 acima de L2 | Figura do controle |
| 26 | Com uma alteração sem salvar, gravar o arquivo pela interface do VS Code; repetir com `vim` usando o `vimrc` habitual; escolher "Recarregar do arquivo" numa vez e "Manter minhas alterações" na outra | Faixa "O arquivo de configuração foi alterado por outro programa enquanto você editava."; nada sobrescrito até a escolha; `editor.conflict` com `reload` e `keep` | Conflito com alteração externa |
| 27 | Terminal em foco; editor pela paleta; fechar | Terminal em foco | Foco devolvido |
| 28 | Item `/reversa-docs` e L1+✕; salvar; L1+✕; `grep -c -e CONTINUAR -e reversa-docs "$LOG"` | `shortcuts.saved` e `shortcut.triggered` presentes; contagem 0 | Privacidade do log |
| 29 | Operar o editor a 3 m da TV durante os passos 13, 16 e 21 | Texto legível e alvos acertados com o ponteiro | RNF de legibilidade |
| 30 | Com a paleta aberta, `cp $S/palette-reversa-docs.json $CFG` | Paleta fecha com `palette.closed { reason: config_changed }`; reabre com `/reversa-docs` no topo | `roadmap.md` D-12 |
| 31 | Segurar L2+← e, com ele segurado, desligar o JoystickAIPoC em Ajustes do Sistema > Privacidade e Segurança > Acessibilidade usando o trackpad; soltar o controle; ligar de novo; num campo de texto, pressionar ← no teclado físico | `pointer.injection_suspended` e depois `pointer.injection_resumed`; ← move o cursor sem trocar de mesa, isto é, Control não ficou preso | Tecla solta ao perder a permissão |

Anote em `actions.md`, na seção de notas do PM-2, o resultado de cada linha e a impressão de latência na aplicação (limite de 1 s) e na abertura do editor (limite de 1 s). No fim, restaure a configuração guardada e apague `~/joystick-link` e `~/.config/joystick-ai/config.off.json`, se sobrarem.

## 3. Se algo der errado

- **Tecla ou modificador presos:** pressione e solte a tecla no teclado físico; registre o passo.
- **Atalhos mudaram sem arquivo:** falha do teste de equivalência (`roadmap.md` D-04); restaure a configuração e anote o botão e a camada.
- **A janela abre atrás do terminal:** falha de D-23 e da E003; use o ícone da barra de menus, registre se houve `editor.activation_failed` e a versão do macOS.
- **Colar ou ditar não funciona num campo do editor:** confira se o menu Editar aparece na barra de menus com a janela em foco; sem ele, ⌘V não chega ao campo e o ditado do Raycast falha.
- **O arquivo perdeu `pointer` ou virou arquivo comum no lugar do *link*:** restaure `config.pre-003.json` e registre o passo; é falha de D-07 ou D-17.
- **"Salvar" pede cópia para `config.json.bak`:** o arquivo atual tem erro de sintaxe; "Copiar e gravar" guarda o conteúdo antigo ao lado e grava o novo, "Cancelar" não grava nada.
- **Alteração externa não aplicada:** confira no log se houve `shortcuts.invalid` ou `shortcuts.unchanged` com `trigger: external`; se não houver nada, é falha de D-16. A P-04 aprovou gravações no lugar, por `mv`, por `vim` e através de *link*; registre o programa usado.
- **O ícone continua com alerta depois de corrigir o arquivo:** o alerta só sai com `shortcuts.loaded`. `shortcuts.unchanged` significa que os *bytes* lidos são iguais aos da última leitura, a inválida; confira se a correção chegou ao arquivo, e não a outra cópia.
