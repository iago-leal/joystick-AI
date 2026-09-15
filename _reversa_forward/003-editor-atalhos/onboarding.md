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
grep -E '"(shortcuts?|editor)\.' "$LOG"
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

## 2. Portão PM-2: cenários do editor

Abra o app com `--debug`. Entre um grupo de passos e outro, restaure a configuração guardada quando o passo pedir arquivo em estado conhecido.

| # | Passo | Resultado esperado | Cenário |
|---|-------|--------------------|---------|
| 1 | `mv ~/.config/joystick-ai/config.json ~/.config/joystick-ai/config.off.json`; abrir o app; ✕, L1+✕, L2+← e PS | Enter, `CONTINUAR` com Enter, troca de mesa, paleta com 17 itens e "Editar atalhos"; arquivo continua ausente. Depois, desfazer o `mv` | Padrão sem arquivo |
| 2 | No JSON, associar △ na base a `z` com `command`; salvar; △ no VS Code | Desfaz em até 1 s | Ação carregada do arquivo |
| 3 | No editor, marcar L3 como modificador e associar L3+○ a Mission Control; salvar; L3+○ e depois L3+✕ | Mission Control; Enter herdado | Camada nova com herança; Marcar modificador |
| 4 | Segurar L1, depois L2, e pressionar ✕; soltar; segurar L2, depois L1, e pressionar ✕ | `CONTINUAR` com Enter; depois Enter | Precedência entre modificadores |
| 5 | No JSON, pôr `r1` numa camada; salvar | Alerta no ícone citando a linha; R1 continua clicando | Botões de apontamento fixos; Alerta de configuração inválida |
| 6 | Segurar □ num campo com texto e salvar por fora uma troca da ação de ○ | Repetição para, nada preso; ○ faz a nova ação em até 1 s | Alteração externa aplicada |
| 7 | Salvar por fora um arquivo com vírgula faltando na linha 12 e ○ trocado para Tab | ○ segue em Esc; log e menu citam a linha 12; corrigir remove o alerta | Arquivo inválido; Alerta de configuração inválida |
| 8 | Com `pointer` calibrado e sem seções novas, alterar um atalho no editor e salvar; `diff` contra `config.pre-003.json` | `pointer` com os mesmos campos e valores; atalho novo vale | Seções preservadas ao salvar |
| 9 | `chmod a-w ~/.config/joystick-ai`; salvar no editor; `chmod u+w ~/.config/joystick-ai` | Erro com o caminho; vigente e rascunho mantidos | Pasta sem permissão de escrita |
| 10 | Ícone da barra de menus: "Editar atalhos"; depois "Sair" com □ segurado | Editor em primeiro plano; app encerra sem Backspace preso | Ícone na barra de menus |
| 11 | Terminal em foco; PS, "Editar atalhos", ✕ | Editor acima do Terminal e em foco, sem `editor.activation_failed`; o ponteiro volta ao lugar depois do clique automático; nada digitado no Terminal (E003) | Editor aberto pela paleta |
| 12 | Camada L2 no editor | ← "mesa à esquerda"; ✕ "Enter (herdado)"; R1 "clique esquerdo, fixo" | Visão de uma camada |
| 13 | Atribuir Command+Z a L1+○ gravando pelo teclado; salvar; L1+○ | Desfaz em até 1 s | Atribuir e salvar; Gravação de acorde |
| 14 | Gravação ativa: Command+Shift+Z no teclado e ✕ no controle | Capturado Command+Shift+Z; nenhum Enter | Gravação de acorde |
| 15 | Sem teclado: montar Tab com Command para um gatilho; salvar; acionar | Command+Tab executado | Acorde montado pelo controle |
| 16 | Gravação inativa; digitar no Terminal; conferir o log | Nada capturado; nenhuma tecla no log | Captura restrita ao campo |
| 17 | Marcar L3 como modificador mantendo Control, sem ação própria para ←; salvar; segurar L3 e pressionar ← | ← herdado com Control mantido: troca para a mesa à esquerda | Marcar modificador |
| 18 | Marcar ✕ como modificador sem remover Enter da base | "Salvar" desabilitado; ✕ destacado com o motivo | Salvar bloqueado |
| 19 | Alterar algo, fechar, Cancelar; fechar de novo, Descartar | Janela segue aberta com a alteração; depois, vigente sem mudança | Fechar com alteração pendente |
| 20 | Incluir `/reversa-docs` no topo com Enter; salvar; PS; confirmar | Topo da paleta; "Editar atalhos" no fim; comando digitado e enviado | Editar a paleta |
| 21 | Tentar remover o único item; incluir o 51.º; ditar texto com quebra de linha | Operações impedidas com o limite | Limites da paleta |
| 22 | Restaurar padrão, Cancelar; Restaurar padrão, Confirmar | Nada muda; depois, padrões gravados | Restaurar padrão |
| 23 | Ligar a identificação; pressionar △; clicar com R1 num controle do editor | △ selecionado sem Tab; clique funciona | Modo de identificação |
| 24 | Observar a figura | □ à esquerda do grupo de ação; L1 acima de L2 | Figura do controle |
| 25 | Alterar algo sem salvar; gravar o arquivo pelo VS Code | Faixa com Recarregar e Manter; nada sobrescrito | Conflito com alteração externa |
| 26 | Terminal em foco; editor pela paleta; fechar | Terminal em foco | Foco devolvido |
| 27 | Item `/reversa-docs` e L1+✕; salvar; L1+✕; `grep -c -e CONTINUAR -e reversa-docs "$LOG"` | `shortcuts.saved` e `shortcut.triggered` presentes; contagem 0 | Privacidade do log |
| 28 | Operar o editor a 3 m da TV durante os passos 12, 15 e 20 | Texto legível e alvos acertados com o ponteiro | RNF de legibilidade |
| 29 | Com a paleta aberta, salvar por fora uma paleta nova | Paleta fecha com `reason: config_changed`; reabre com a lista nova | `roadmap.md` D-12 |

Anote em `actions.md`, na seção de notas do PM-2, o resultado de cada linha e a impressão de latência na aplicação (limite de 1 s) e na abertura do editor (limite de 1 s).

## 3. Se algo der errado

- **Tecla ou modificador presos:** pressione e solte a tecla no teclado físico; registre o passo.
- **Atalhos mudaram sem arquivo:** falha do teste de equivalência (`roadmap.md` D-04); restaure a configuração e anote o botão e a camada.
- **A janela abre atrás do terminal:** falha de D-23; use o ícone da barra de menus e registre a versão do macOS.
- **O arquivo perdeu `pointer` ou virou arquivo comum no lugar do *link*:** restaure `config.pre-003.json` e registre o passo; é falha de D-07 ou D-17.
- **Alteração externa não aplicada:** confira no log se houve `shortcuts.invalid` ou `shortcuts.unchanged`; se não houver nada, é falha de D-16.
