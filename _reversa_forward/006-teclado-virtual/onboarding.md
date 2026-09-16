# Onboarding: Teclado virtual chamado pelo controle

> Identificador: `006-teclado-virtual`
> Data: `2026-09-16`
> Público: quem vai testar a feature pela primeira vez (o programador de sofá, no papel de avaliador)
> Roadmap: `_reversa_forward/006-teclado-virtual/roadmap.md`

O roteiro tem dois portões. O **PM-0** roda antes de qualquer código, com o app já instalado, e responde as sondas P-01 a P-05. O **PM-1** roda depois do `/reversa-coding`. Se a implementação alterar nomes, rótulos ou caminhos dos Ajustes, o `/reversa-coding` deve atualizar este arquivo. Cada passo indica o cenário da seção 7 do `requirements.md` ou a sonda que verifica.

## 0. Pré-requisitos

| Item | Como conferir |
|------|---------------|
| App das features 003 a 005 instalado, assinado com "JoystickAI Local Signing", Acessibilidade concedida | `./scripts/check-signature.sh`; log com `permissions.status` e `postEvent: true` |
| DualSense conectado, Mac ligado à TV, sofá a cerca de 3 m | O ponteiro se move com o analógico esquerdo |
| Terminal aberto, com um prompt vazio | Destino da digitação |
| Teclado físico ao alcance | Só para o passo de referência do PM-0 |

### Ajustes do sistema exigidos pela feature

Os nomes abaixo seguem o macOS em português. No PM-0 de 2026-09-16, no macOS 26.6.2, o estado de A-1 e A-2 foi conferido pelas preferências (comandos abaixo), mas o caminho textual dos menus não foi relatado pelo usuário: valem como indicação, e não como caminho confirmado.

| # | Ajuste | Onde | Por quê |
|---|--------|------|---------|
| A-1 | Atalho "Mostrar controles de acessibilidade" ativo, com ⌥⌘F5 | Ajustes do Sistema › Teclado › Atalhos de Teclado › Acessibilidade | É o acorde que o app envia (entrada 162, ativa nesta máquina em 2026-09-16) |
| A-2 | Só "Teclado de Acessibilidade" marcado na lista do atalho | Ajustes do Sistema › Acessibilidade › Atalho | Alternância direta, sem painel (RN-02). Com mais itens marcados, vale o passo extra |
| A-3 | Esmaecimento por inatividade desligado | Opções do Teclado de Acessibilidade (menu do canto do teclado, "Aparência" ou equivalente) | O teclado não parece sumir durante a leitura |
| A-4 | Teclado redimensionado para a TV | Arrastar o canto do teclado com R1 | RN-11: vale o tamanho que o sistema permite |

| # | Conferência em 2026-09-16 |
|---|---------------------------|
| A-1 | Confirmado: entrada `162` ativa, `(65535, 96, 1572864)`; ⌥⌘F5 no teclado físico abre o painel ou alterna o teclado |
| A-2 | Confirmado: `axShortcutExposedFeatures` só com `feature.virtualKeyboard = 1`, feito pelo usuário; caminho sugerido "Ajustes do Sistema › Acessibilidade › Atalho", sem correção relatada |
| A-3 e A-4 | Sem relato específico; o usuário avaliou o resultado como "ficou ótimo" |

Guarde a configuração atual antes de tudo:

```sh
cp ~/.config/joystick-ai/config.json ~/.config/joystick-ai/config.pre-006.json 2>/dev/null || echo "sem arquivo: vale o padrão"
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
# conferir o atalho do sistema (só leitura)
defaults read com.apple.symbolichotkeys AppleSymbolicHotKeys | grep -A10 '162 ='
# conferir a lista do Atalho de Acessibilidade (só leitura; A-2 cumprido com só feature.virtualKeyboard = 1)
defaults read com.apple.universalaccess axShortcutExposedFeatures
# restaurar a configuração guardada
cp ~/.config/joystick-ai/config.pre-006.json ~/.config/joystick-ai/config.json
```

## 1. Portão manual PM-0, sondas sem código

Usa o app atual. O botão de teste é L3 na camada base, que hoje não tem ação; ele só serve à sonda e é restaurado no fim.

| Passo | Ação | Resultado esperado | Sonda ou cenário |
|-------|------|--------------------|------------------|
| 1 | Faça A-1 e A-2 nos Ajustes, anotando o caminho real de cada menu. | Os dois ajustes existem; o caminho anotado confirma ou corrige o quadro acima | D-06 |
| 2 | Com o terminal em foco, pressione ⌥⌘F5 no teclado físico (com fn, se o teclado usar as teclas F como mídia). Pressione de novo. | O teclado aparece e depois some, sem painel | Referência para P-01 e P-02 |
| 3 | Abra o editor pela paleta. Na camada base, selecione L3, escolha Acorde, ligue ⌥ e ⌘, abra o grupo de funções e acione F5. Salve e feche o editor. | "⌥⌘F5" no painel e no balão de L3; gravação sem faixa de erro | Preparação |
| 4 | Rode `grep -E 'shortcut.triggered' "$LOG" \| tail -3` depois de pressionar L3 uma vez. | Um `shortcut.triggered` com `button: l3` e `type: chord` | Preparação |
| 5 (P-01, P-02) | Com o terminal em foco e o teclado oculto, pressione L3; depois pressione L3 de novo. Anote o tempo aproximado de cada resposta. | O teclado aparece e some em até 1 s cada. **Se nada acontecer**, registre P-01 reprovada: o `/reversa-coding` executa D-03 e repete este passo | Digitar um nome no terminal; Ocultar o teclado pelo mesmo botão |
| 6 (P-03) | Com o teclado visível, olhe o nome do aplicativo na barra de menus. | Continua o terminal | Digitar um nome no terminal |
| 7 (P-04) | Aponte com o controle e acione `l`, `s` e Return no teclado com R1. | O terminal executa `ls`. **Se as teclas não responderem**, registre P-04 reprovada e pare: a continuidade volta ao usuário | Digitar um nome no terminal |
| 8 | Com o teclado visível, pressione L1 + ✕ e depois PS. Feche a paleta com ○. | "CONTINUAR" é digitado no terminal; a paleta abre e fecha; o teclado continua visível | Atalhos seguem ativos; Paleta aberta não oculta o teclado |
| 9 (P-02) | Nos Ajustes, marque um segundo recurso na lista do atalho. Pressione L3, escolha o Teclado de Acessibilidade no painel com R1. Desmarque o segundo recurso. | O painel aparece; a escolha exibe o teclado; o terminal continua em foco | Caminho com passo extra |
| 10 (P-05) | Faça A-3 e A-4. Do sofá, digite uma palavra de oito letras no terminal. | Palavra correta, sem tecla errada | Digitação a 3 m |
| 11 | Rode `grep -c '"ls"' "$LOG"` e `grep -v '"session.start"' "$LOG" \| grep -ci 'f5'`. | Contagens 0. O `session.start` fica de fora porque o hash do certificado de assinatura contém `f5` (auditoria A001) | Log sem texto digitado |
| 12 | Restaure a configuração guardada. | L3 volta a "nenhuma" | — |

Registre o resultado de cada sonda no `actions.md` da feature. A decisão sobre D-03 sai do passo 5.

## 2. Testes automatizados, depois do código

1. Rode `./scripts/test.sh`. Espere todos verdes, com os testes de D-07: seis atalhos de sistema, leitura da entrada 162, validação e ida e volta de `accessibilityShortcut`, resumo "atalho de acessibilidade", mapeamento padrão sem o atalho e, se D-03 foi executada, `isFunctionKey`.

## 3. Portão manual PM-1, depois do código

Com o app novo instalado e os ajustes A-1 a A-4 feitos.

| Passo | Ação | Resultado esperado | Cenário |
|-------|------|--------------------|---------|
| 1 | Mova o arquivo de configuração para longe (`mv ~/.config/joystick-ai/config.json /tmp/`), abra o app e pressione cada botão da base, fora do terminal. Devolva o arquivo. | Nenhum botão exibe o teclado; as ações são as de antes da feature | Mapeamento padrão inalterado |
| 2 | No editor, só com o controle, selecione L3 na base, escolha "Atalho de sistema" e acione "atalho de acessibilidade". Salve. | O painel e o balão de L3 mostram "atalho de acessibilidade" | Trocar o botão pelo editor |
| 3 | Rode `grep -n accessibilityShortcut ~/.config/joystick-ai/config.json`. | Uma linha com `"type": "systemShortcut"` e `"name": "accessibilityShortcut"` | Trocar o botão pelo editor |
| 4 | Com o terminal em foco, pressione L3, digite `ls` e Return com R1 e pressione L3 de novo. | O teclado aparece, `ls` é executado, o terminal segue em foco, o teclado some | Digitar um nome no terminal; Ocultar o teclado pelo mesmo botão |
| 5 | No editor, mova o atalho de L3 para ○ na camada Options e deixe L3 como "nenhuma". Salve e feche. Pressione L3, depois Options + ○. | L3 não faz nada; Options + ○ alterna o teclado | Trocar o botão pelo editor |
| 6 | Abra a paleta e pressione Options + ○. | O teclado não aparece; a paleta trata o botão pelas próprias regras | Paleta aberta retém o botão |
| 7 | No editor, ative o modo de identificação e pressione Options + ○. | O botão é selecionado na figura; o teclado não aparece | Modo de identificação do editor |
| 8 | Nos Ajustes, desative o atalho de A-1. Pressione Options + ○ com o terminal em foco. Reative o atalho. | O teclado não aparece; o app segue operando, sem tecla presa | Pré-requisito externo ausente |
| 9 | Com o teclado visível, segure Options + ○ e desligue o controle. Reconecte e digite no teclado físico. | Nenhum modificador preso: as letras saem sem ⌥ nem ⌘ | Desconexão com o teclado visível |
| 10 | Revogue a Acessibilidade do app, pressione Options + ○, restaure a permissão e digite no teclado físico. | Nada acontece durante a revogação; depois, nenhum modificador preso | Sem permissão de Acessibilidade |
| 11 | Siga o quadro de ajustes do §0 num estado sem A-2 (marque outro recurso) e confira o passo extra; depois volte a A-2. | O caminho documentado leva ao teclado | Pré-requisito documentado; Caminho com passo extra |
| 12 | Rode `grep -E 'shortcut.triggered' "$LOG" \| tail -5` e `grep -ci 'accessibility' "$LOG"`. | Eventos com `type: systemShortcut`, sem nome de atalho; contagem 0 | Log sem texto digitado |
| 13 | Decida se mantém o atalho no botão escolhido ou restaura a cópia `config.pre-006.json`. | Estado desejado pelo usuário | — |

Registre o resultado de cada passo no `actions.md` da feature.

## 4. Resultado dos portões (2026-09-16)

Log das sessões: `poc-20260916-184700.jsonl` (PM-0, app anterior) e `poc-20260916-193645.jsonl` (PM-0B e PM-1, app da feature). Configuração anterior guardada em `~/.config/joystick-ai/config.pre-006.json`.

**Adaptação do roteiro.** A configuração do usuário não é a padrão: L3 na base envia Tab, a paleta abre por Create e "CONTINUAR" sai por △. O botão de teste foi **Options + ○**, e não L3; o passo 8 usou △ e Create. O acorde ⌥⌘F5 do passo 3 foi gravado direto no arquivo, a pedido do usuário, porque o primeiro salvamento pelo editor não chegou ao arquivo.

### PM-0 e PM-0B

| Passo | Resultado | Evidência |
|-------|-----------|-----------|
| 1 | Aprovado, caminho não relatado | A-2 conferido pelas preferências (§0) |
| 2 | Aprovado | ⌥⌘F5 físico abriu o painel de atalhos de acessibilidade, com locução |
| 3 e 4 | Aprovado, pelo arquivo | `options.circle` = ⌥⌘F5; `shortcuts.loaded` com `trigger: external`; `shortcut.triggered` de `circle`/`options` com `type: chord` |
| 5 (P-01), app anterior | **Reprovado** | Cinco acionamentos no log; o cursor se ocultou como em digitação comum e nada apareceu. D-03 executada |
| 5 (P-01), PM-0B | Aprovado | Com D-03, o controle abriu o painel; com A-2 feito, o usuário relatou que "funcionou". Tempo não medido |
| 6 (P-03) | Aprovado | O teclado flutua à frente, mas o terminal continua em foco e recebe o texto |
| 7 (P-04) | Aprovado | `l`, `s` e Return com R1 digitaram `ls` no terminal, confirmado como digitação no teclado, e não ditado |
| 8 | Aprovado, pelo log | Às 19:46, △ (`text`), Create (`palette.opened`) e ○ (`palette.closed`, `reason: circle`) com o teclado em uso |
| 9 (P-02) | Aprovado | Caminho com passo extra: painel aberto pelo controle e teclado escolhido com R1 |
| 10 (P-05) | Aprovado pelo relato geral | "Ficou ótimo"; palavra de oito letras não relatada |
| 11 | Aprovado | Contagens de `"ls"`, `f5` (fora de `session.start`), `accessibility` e `CONTINUAR` iguais a 0 |
| 12 | Não executado | O usuário manteve a configuração nova; a cópia `config.pre-006.json` continua disponível |

### PM-1

| Passo | Resultado | Evidência |
|-------|-----------|-----------|
| 1 | Não executado | Coberto por `ShortcutDefaultsTests.padraoSemAtalhoDeAcessibilidade` e pela equivalência do padrão |
| 2 e 3 | Aprovado | Pelo editor, às 19:48:00 (`shortcuts.saved`), o usuário pôs "atalho de acessibilidade" em **Options + →**; o arquivo grava `{"name": "accessibilityShortcut", "type": "systemShortcut"}` |
| 4 | Aprovado | `shortcut.triggered` de `dpadRight`/`options` com `type: systemShortcut` às 19:48:02; relato "funcionou" |
| 5 | Aprovado, com outro botão | O acionamento saiu de Options + ○, que ficou com a ação "nenhuma", para Options + → |
| 6 a 11 | Não relatados | Paleta retendo o botão, modo de identificação, atalho desativado, desconexão, revogação e pré-requisito documentado: regras do legado sem mudança de código (D-05), sem verificação em hardware nesta rodada |
| 12 | Aprovado | `shortcut.triggered` sem nome de atalho; contagem de `accessibility` igual a 0 |
| 13 | Decidido | O usuário manteve o atalho em Options + → |

**Sondas:** P-01 aprovada com D-03; P-02, P-03 e P-04 aprovadas; P-05 aprovada pelo relato geral. Nenhum plano de contingência foi necessário.
