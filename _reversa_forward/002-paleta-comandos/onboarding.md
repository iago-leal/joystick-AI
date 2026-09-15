# Onboarding: Paleta de comandos pelo controle

> Identificador: `002-paleta-comandos`
> Data: `2026-09-14`
> Público: quem vai testar a paleta pela primeira vez (o programador de sofá, no papel de avaliador)
> Roadmap: `_reversa_forward/002-paleta-comandos/roadmap.md`

Este roteiro pressupõe o código entregue pelo `/reversa-coding`. Se a implementação alterar nomes de arquivo, argumentos ou eventos, o `/reversa-coding` deve atualizar este arquivo. Cada passo indica o cenário da seção 7 do `requirements.md` que verifica.

## 0. Pré-requisitos

| Item | Como conferir |
|------|---------------|
| App da feature 001 instalado, assinado com "JoystickAI Local Signing" e com Acessibilidade concedida | `./scripts/check-signature.sh`; log com `permissions.status` e `postEvent: true` |
| Botão PS sem ação do sistema | Ajustes do Sistema > Controles de jogo > DualSense > "Pressione o Botão de Início para abrir": **Nenhum** |
| Claude Code instalado, com o Reversa neste projeto | `claude --version`; `ls .claude/skills/reversa-forward` |
| Terminal e VS Code com terminal integrado | abrir ambos |
| Um app em tela cheia e uma segunda mesa | Mission Control |

Comandos úteis:

```sh
# compilar, assinar e instalar
JOYSTICK_SIGN_IDENTITY="JoystickAI Local Signing" ./scripts/build-app.sh
# abrir com depuração e um intervalo de Enter explícito
open ~/Applications/JoystickAIPoC.app --args --debug --palette-enter-delay-ms 0
# encerrar
osascript -e 'quit app "JoystickAIPoC"'
# eventos da paleta no log mais recente
grep '"palette\.' "$(ls -t ~/Library/Logs/joystick-ai/poc-*.jsonl | head -1)"
```

Para os testes com o Claude Code, use uma sessão descartável num diretório de rascunho, pois `/clear` e os comandos do Reversa agem de verdade.

## 1. Portão PM-1: sondas com o próprio app

As sondas usam o app já com a paleta, sem utilitário descartável (`actions.md`, "Ajuste de ordem em relação ao roadmap §8").

### P-01, intervalo do Enter

1. Compile e instale; o script encerra a instância aberta:
   ```sh
   JOYSTICK_SIGN_IDENTITY="JoystickAI Local Signing" ./scripts/build-app.sh
   ```
2. Abra com o intervalo 0 e o Claude Code em foco no Terminal, numa sessão descartável:
   ```sh
   open ~/Applications/JoystickAIPoC.app --args --debug --palette-enter-delay-ms 0
   ```
3. Pela paleta, confirme `/reversa-forward` e depois `/compact`. Anote se o comando executou, se outra sugestão foi escolhida ou se o texto ficou como colagem. Deixe `/clear` e `/resume` para o fim da sessão descartável, pois agem sobre a conversa.
4. Encerre (`osascript -e 'quit app "JoystickAIPoC"'`), reabra com `--palette-enter-delay-ms 50` e depois com `150`, repetindo o passo 3 enquanto o anterior falhar.
5. Repita o menor intervalo aprovado no terminal integrado do VS Code.
6. Informe o menor intervalo que funcionou em todos os casos: ele vira `PaletteActions.defaultEnterDelayMs` (T021). Se nenhum valor até 500 ms funcionar, pare e volte ao `/reversa-clarify`.

### P-02, painel sobre tela cheia e outra mesa

1. Com o Terminal em foco, pressione PS. Confira que o Terminal continua ativo: o nome dele segue na barra de menus e o cursor de texto continua piscando.
2. Repita com um app em tela cheia e numa segunda mesa.
3. Informe o resultado; ele vai para as notas de execução do `actions.md`.

## 2. Portão PM-2: cenários da paleta

Abra o app com `--debug`, já com o padrão definido na P-01.

| # | Passo | Resultado esperado | Cenário |
|---|-------|--------------------|---------|
| 1 | Terminal com Claude Code em foco; PS; ↓ até `/reversa-forward`; ✕ | Paleta some; comando executa; Terminal nunca perde o foco | Comando do Reversa pela paleta |
| 2 | Segurar L1 e pressionar PS; fechar; segurar Options e pressionar PS | Com L1, abre; com Options, nada | PS com modificador segurado |
| 3 | Paleta aberta no 1.º item; ↑; segurar ↓ por 1 s | ↑ seleciona `/resume`; ↓ avança ao menos 10 posições | Navegação circular e repetição |
| 4 | Selecionar `/clear`; ○; reabrir e pressionar PS | Fecha as duas vezes sem digitar | Fechar sem digitar |
| 5 | Confirmar `/reversa-requirements ` | Texto na linha, com espaço final, sem envio | Comando que espera descrição |
| 6 | Campo de senha em foco (por exemplo, `sudo -v` no Terminal); confirmar `CONTINUAR` | Nada visível é digitado; log sem o texto | Campo seguro em foco |
| 7 | Abrir a paleta e contar os itens | 17 itens, de `CONTINUAR` a `/resume`, legíveis a 3 m da TV | Conteúdo da lista; RNF de legibilidade |
| 8 | Paleta aberta; □; mover o analógico esquerdo; R1 | Sem Backspace; cursor se move; clique acontece | Atalhos suspensos e ponteiro ativo |
| 9 | Segurar □ num campo com texto; PS | A repetição para antes da paleta; nada preso | Repetição em curso ao abrir |
| 10 | Paleta fechada: ✕, L1+✕, L2+← | Enter, `CONTINUAR` com Enter, troca de mesa | Atalhos do protótipo preservados |
| 11 | Confirmar `/reversa-plan`; reabrir | `/reversa-plan` selecionado | Último item lembrado |
| 12 | Paleta aberta; desligar o controle | Fecha; log com `palette.closed` e `reason: disconnected` | Desconexão com a paleta aberta |
| 13 | Paleta aberta; revogar a Acessibilidade | Fecha; nada digitado; conceder de novo depois | Permissão revogada com a paleta aberta |
| 14 | Paleta aberta; esperar 60 s sem tocar no controle | Fecha; `reason: idle` | Inatividade |
| 15 | Confirmar `CONTINUAR`; conferir o log | `palette.confirmed` com `index: 1`; `grep -c CONTINUAR` no log igual a 0 | Privacidade do log |
| 16 | Repetir os passos 1, 5 e 10 no terminal integrado do VS Code | Mesmos resultados | RNF de compatibilidade |
| 17 | Repetir o passo 1 com um app em tela cheia e noutra mesa | Paleta visível; foco mantido | Risco P-02 |
| 18 | `open ... --args --targets --env mesa`; PS | Paleta não abre; log com `palette.blocked` | D-13 |

Anote em `actions.md`, na seção de notas do PM-2, o resultado de cada linha e a impressão de latência na abertura (limite de 150 ms).

## 3. Se algo der errado

- **Tecla ou Command presos:** pressione e solte a tecla no teclado físico; registre o passo em que ocorreu.
- **A paleta rouba o foco:** anote o app em foco e a versão do macOS; é falha de D-08.
- **O comando não executa com Enter:** reabra com `--palette-enter-delay-ms` maior (100, 200) e registre o menor valor que funciona.
