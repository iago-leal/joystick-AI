# Onboarding: Prova de conceito de entrada do controle e apontamento

> Identificador: `001-poc-entrada-ponteiro`
> Data: `2026-09-14`
> Público: quem vai compilar, instalar e testar a PoC pela primeira vez (o programador de sofá, no papel de avaliador)
> Roadmap: `_reversa_forward/001-poc-entrada-ponteiro/roadmap.md`

Este roteiro pressupõe o código entregue pelo `/reversa-coding`. Os nomes de scripts e comandos seguem o roadmap; se a implementação os alterar, o `/reversa-coding` deve atualizar este arquivo. Cada passo indica o requisito que verifica e o que anotar no `validation-report.md`.

## 0. Pré-requisitos

| Item | Como conferir |
|------|---------------|
| macOS 13 ou superior | `sw_vers` |
| Swift 6 ou superior | `swift --version` |
| DualSense pareado por Bluetooth e um cabo USB-C de dados | Ajustes do Sistema > Bluetooth |
| Botão PS sem ação do sistema (necessário para o PS chegar sem abrir o Game Center; achado do PM-2) | Ajustes do Sistema > Controles de jogo > DualSense > "Pressione o Botão de Início para abrir": **Nenhum** |
| Monitor à mesa e TV (ou monitor grande) a cerca de 2 m, configurados como telas estendidas | Ajustes do Sistema > Telas |
| VS Code instalado, com um arquivo de 1.000 linhas à mão | `seq 1 1000 > /tmp/mil-linhas.txt` |
| Liberação de escrita do Reversa feita pelo usuário (D-21) | `.reversa/reversa-config.json` |

Para encerrar a PoC em qualquer momento, já que ela não tem menu nem ícone no Dock:

```sh
osascript -e 'quit app "JoystickAIPoC"'
```

Para conferir um log sem o Xcode, os subcomandos de `poc-tools` rodam com `swift run -q poc-tools <subcomando> <log>`.

Se algum botão do mouse parecer preso (casos R-08 e R-09 do roadmap), um clique no mouse físico ou no trackpad o libera.

## 1. Fase 0: assinatura estável (antes de qualquer calibração)

1. **Caminho A, certificado da conta Apple gratuita.** Instale o Xcode pela App Store, abra Xcode > Settings > Accounts, entre com o Apple ID e, em Manage Certificates, crie um certificado *Apple Development*. Confira:
   ```sh
   security find-identity -v -p codesigning
   ```
   Deve aparecer uma linha `Apple Development: ...`.
2. **Caminho B, se o A falhar no passo 6 ou se o Xcode não estiver instalado** (caminho adotado nesta PoC). Crie a identidade local:
   ```sh
   ./scripts/create-local-signing-identity.sh "JoystickAI Local Signing"
   ```
   O macOS pedirá a senha de administrador para confiar no certificado para assinatura de código.
3. Compile, monte, assine e instale:
   ```sh
   JOYSTICK_SIGN_IDENTITY="Apple Development: <nome>" ./scripts/build-app.sh
   ```
   O app vai para `~/Applications/JoystickAIPoC.app`.
4. Abra sempre por LaunchServices, nunca executando o binário pelo terminal:
   ```sh
   open ~/Applications/JoystickAIPoC.app
   ```
5. Antes de conceder, encerre e reabra a PoC uma vez e anote se o diálogo de Acessibilidade do sistema reaparece (P-10). Depois, em Ajustes do Sistema > Privacidade e Segurança > Acessibilidade, ative **JoystickAIPoC**. Não conceda Input Monitoring ainda: a Fase 1 precisa testar sem ele.
6. Registre o requisito designado, recompile e compare:
   ```sh
   ./scripts/check-signature.sh > /tmp/assinatura-antes.txt
   osascript -e 'quit app "JoystickAIPoC"'
   JOYSTICK_SIGN_IDENTITY="..." ./scripts/build-app.sh
   ./scripts/check-signature.sh > /tmp/assinatura-depois.txt
   diff /tmp/assinatura-antes.txt /tmp/assinatura-depois.txt && echo "requisito estável"
   open ~/Applications/JoystickAIPoC.app
   ```
7. Abra o log mais recente e procure `permissions.status` com `postEvent: true`:
   ```sh
   tail -n 20 "$(ls -t ~/Library/Logs/joystick-ai/poc-*.jsonl | head -1)"
   ```
   - `postEvent: true` sem nova concessão: assinatura aprovada. **Anote no bloco (e)** o caminho usado.
   - `postEvent: false`: remova a entrada antiga da lista de Acessibilidade, passe ao caminho B e repita os passos 3 a 7.

## 2. Fase 1: leitura do controle

Abra com depuração: `open ~/Applications/JoystickAIPoC.app --args --debug`. Nos passos abaixo, `LOG` é o arquivo mais recente em `~/Library/Logs/joystick-ai/`.

| # | Ação | Resultado esperado no log | Verifica |
|---|------|---------------------------|----------|
| 1 | Com a PoC fechada, ligue o controle por Bluetooth; depois abra a PoC. Repita com o controle ligado por USB. | `controller.connected` com `atStartup: true`, sem desligar o controle, e um único registro por controle. Anote o intervalo desde `session.start`. | RF-03, P-09 |
| 2 | Desligue o controle segurando PS por 10 s. | `controller.disconnected` em até 2 s. | RF-02 |
| 3 | Conecte por USB; desconecte; religue por Bluetooth. | Dois `controller.connected`, `connection` `usb` e `bluetooth` (ou `unknown`, anotar). | RF-01, P-06 |
| 4 | Traga o Terminal para frente. Pressione e solte, na ordem, ✕ ○ □ △ L1 R1 L2 R2 L3 R3 Options Create PS, clique do touchpad, ↑ ↓ ← →. | `poc-tools buttons LOG` mostra 18 de 18. | RF-04, RF-05, P-05, bloco (a) |
| 5 | Ainda com Input Monitoring não concedido, repita o item 4. | Se os eventos chegaram, Input Monitoring não é necessário; anote e pule o item 5a. Se não, conceda-o, repita sem relançar e depois relançando. | P-04, bloco (f) |
| 5a | Só se o item 5 concluir que Input Monitoring é necessário: `JOYSTICK_SIGN_IDENTITY="..." ./scripts/build-app.sh`, reabra e repita o item 4 sem nova concessão. | 18 de 18 de novo, sem voltar a Ajustes do Sistema. Se falhar, a assinatura não serve: volte à Fase 0. | RNF de operação, P-11, bloco (e) |
| 6 | Pouse um dedo no touchpad, deslize, pouse o segundo, retire os dois. | Por Bluetooth, `controller.extended_report` com `result: "ok"` antes de `controller.connected` (sem ele o touchpad não envia nada); `controller.touch_source` na conexão; `input.touch` com `began` e `ended` para os dedos 0 e 1; `touch.raw_transition` coerente. Nenhuma posição aparece no log: a direção do movimento se confere na Fase 2. | RF-08, P-01, P-02 |
| 7 | Pressione R2 devagar até a metade e solte devagar. | Um único par `r2` down/up; pares repetidos indicam oscilação (R-07). | RF-07 |
| 8 | Pressione e solte Create. | Só o par `create` down/up; se o sistema abrir captura de tela ou gravação, anote. | R-15, bloco (f) |
| 9 | Procure `controller.elements`. | Lista de nomes; anote se há elemento de mudo. | P-03, bloco (f) |
| 10 | Confira `controller.gesture_suppression` (nível `info`) na conexão; depois pressione PS. | O evento está presente em toda conexão. Com o ajuste do §0, o Game Center não abre e `input.button` de `ps` aparece, lido do relatório HID bruto; sem o ajuste, o Game Center abre a cada PS, pois a supressão pedida não tem efeito (PM-2). | RF-24, P-07 |
| 11 | Com um segundo DualSense (se houver), ligue os dois e desligue o primeiro. | `controller.queued`; após a desconexão, o segundo move o cursor. | RF-09 |
| 12 | Conecte um controle de outro modelo (se houver). | `controller.ignored`. | RF-09 |

**Portão PM-2:** item 4 com 18 de 18, item 6 com toque confiável e, se o item 5 exigiu Input Monitoring, item 5a aprovado. Sem isso, pare e registre antes da Fase 2.

## 3. Fase 2: ponteiro

Antes de começar, rode `./scripts/test.sh` (só com as Command Line Tools, `swift test` termina sem executar teste algum): os testes de `JoystickCore` são a evidência dos valores normalizados de RF-06 (0,0 em repouso, 1,0 no curso máximo) e de RF-08 (posição do toque), que o log não registra (esclarecimento 6).

Mapeamento de cliques invertido a pedido do usuário no PM-3, em divergência de RN-11 e D-06: R1 e o clique do touchpad fazem o botão esquerdo, e R2 faz o direito. Os itens abaixo já usam o mapeamento novo.

| # | Ação | Resultado esperado | Verifica |
|---|------|--------------------|----------|
| 1 | Pouse o dedo num canto do touchpad sem deslizar; depois deixe o analógico esquerdo parado por 10 s. | Cursor parado nos dois casos. | RF-12, RF-06 |
| 2 | Deslize o dedo para a direita; pouse um segundo dedo e deslize-o. | Cursor vai para a direita e segue só o primeiro dedo. | RF-12, RF-08 |
| 3 | Com o cursor na borda esquerda de uma tela de 1.920 pt, incline o analógico todo para a direita e cronometre. | Borda direita em até 1,5 s. | RF-13, RF-06 |
| 4 | Incline o analógico cerca de 30%. | Movimento lento, bem abaixo de um décimo da velocidade máxima. | RF-13 |
| 5 | Incline o analógico para a direita e deslize o dedo para a direita, depois para a esquerda. | Acelera e depois desacelera. | RF-20 |
| 6 | Segure L1 e repita a inclinação por 1 s. | Deslocamento entre 25% e 35% do obtido sem L1. | RF-19 |
| 7 | R1 sobre uma aba do VS Code; clique do touchpad sobre outra. | Ambas selecionam a aba. | RF-15 |
| 8 | R2 sobre um arquivo do explorador. | Menu de contexto abre. | RF-16 |
| 9 | Dois toques rápidos em R1 sobre uma palavra. | Palavra selecionada. | RF-18 |
| 10 | Segure R1, mova o analógico, solte; repita arrastando pelo touchpad. | Trecho selecionado nos dois casos. | RF-17 |
| 11 | Abra `/tmp/mil-linhas.txt` no VS Code e incline o analógico direito todo para baixo. | Fim do arquivo em até 10 s (com `scrollSpeed` calibrado, R-10). Incline para a direita numa linha longa: rolagem horizontal. | RF-14 |
| 12 | Leve o cursor da tela do Mac à TV e à borda externa; com o cursor na TV, desligue-a. | Para na borda externa; reaparece na tela do Mac. | RF-21 |
| 13 | Segure R1 arrastando e desligue o controle. | Botão esquerdo solto; mover o mouse físico não estende a seleção. | RF-10 |
| 14 | Segure R1 sobre o editor e encerre com `osascript -e 'quit app "JoystickAIPoC"'`. | Botão esquerdo solto; `app.terminating` com `releasedButtons`. | RF-23 |
| 15 | Com a PoC aberta, remova-a da lista de Acessibilidade. | Cursor para de responder; `permissions.guidance` e `pointer.injection_suspended` no log; processo continua (`pgrep JoystickAIPoC`). Reconceda depois e confira `pointer.injection_resumed`. Na Fase 0, a concessão só apareceu após reabrir: se o log não mudar, anote como resposta a P-08. | RF-22, P-08 |
| 16 | Rolagem em linhas: reabra com `--scroll-unit line` e repita o item 11 no VS Code e no Terminal. | Compare com pixels; anote a preferência. | `pointer-control` OQ-02, bloco (f) |

## 4. Fase 3: parâmetros sem recompilar

1. Crie o arquivo mínimo:
   ```sh
   mkdir -p ~/.config/joystick-ai
   printf '{\n  "pointer": {\n    "stickMaxSpeed": 1800,\n    "scrollSpeed": 100\n  }\n}\n' > ~/.config/joystick-ai/config.json
   ```
2. Reabra a PoC e confira `config.loaded` com `status: "loaded"`; repita o item 3 da Fase 2 e observe a travessia mais rápida. (RF-26)
3. Remova uma vírgula de propósito, reabra e confira `config.invalid_json` com `line`. Corrija.
4. Ponha `"touchpadSensitivity": 9.0`, reabra e confira `config.value_rejected` com a faixa 0,1 a 5,0.
5. Apague o arquivo, reabra e confira `config.loaded` com `reason: "file_missing"` e que o arquivo continua inexistente.

## 5. Fase 4 e 5: protocolo de validação

### 5.1 Rodadas de calibração na tela de alvos (bloco b)

Para descobrir o número de cada tela, abra a PoC uma vez sem argumentos e procure `targets.screens` no log mais recente; o evento sai a cada início.

Para cada ambiente, repita até estabilizar, ajustando `~/.config/joystick-ai/config.json` entre as rodadas. O argumento de ambiente é `mesa` ou `sofa`, sem acento:

```sh
osascript -e 'quit app "JoystickAIPoC"'
open ~/Applications/JoystickAIPoC.app --args --targets --env mesa --screen 1
# ... 20 tentativas; metade delas segurando L1 ...
osascript -e 'quit app "JoystickAIPoC"'
open ~/Applications/JoystickAIPoC.app --args --targets --env sofa --screen 2
```

- À mesa: monitor a cerca de 60 cm. No sofá: TV a cerca de 2 m.
- Use apenas o controle; cliques do mouse físico são ignorados.
- Para comparar parâmetros sobre as mesmas posições, repita a `--seed` registrada no resultado anterior.
- Ao terminar, gere a tabela e cole-a no bloco (b):
  ```sh
  swift run poc-tools runs
  ```

### 5.2 Confirmação no VS Code, no sofá (bloco c)

Com os parâmetros finais, tente 20 alvos pequenos reais: fechar aba, ícones da barra de atividades, setas do explorador, margem de breakpoint. Anote acerto ou erro no primeiro clique numa tabela de 20 linhas no relatório.

### 5.3 Latência (bloco d)

```sh
osascript -e 'quit app "JoystickAIPoC"'
open ~/Applications/JoystickAIPoC.app --args --debug
# 60 s de uso misto: toques no touchpad, arrancadas do analógico, cliques
swift run poc-tools latency "$(ls -t ~/Library/Logs/joystick-ai/poc-*.jsonl | head -1)"
```

Metas: processamento p95 ≤ 5 ms; entrada ao movimento p95 ≤ 20 ms. Registre a limitação de medir até o `post` (R-12). Confira no mesmo log que não há coordenadas:

```sh
grep -E '"(x|y|dx|dy|location)"' "$(ls -t ~/Library/Logs/joystick-ai/poc-*.jsonl | head -1)" || echo "sem coordenadas"
```

### 5.4 Consumo e robustez

- CPU, 60 s com o controle parado e 60 s com o analógico inclinado:
  ```sh
  top -l 61 -s 1 -pid "$(pgrep -x JoystickAIPoC)" -stats cpu | awk '/^[0-9.]+ *$/ {n++; if (n>1) {s+=$1; m++}} END {print s/m "%"}'
  ```
  Metas: até 2% parado, até 5% em movimento.
- 100 ciclos de conectar e desconectar (alternando cabo e desligamento pelo PS), depois:
  ```sh
  swift run poc-tools cycles "$(ls -t ~/Library/Logs/joystick-ai/poc-*.jsonl | head -1)"
  ```
  Meta: 100 ciclos, uma única sessão no arquivo (nenhum reinício).

### 5.5 Fechamento

Preencha no `validation-report.md` os blocos (e) método de assinatura, (f) respostas às questões abertas (P-01 a P-11 e `pointer-control` OQ-01 e OQ-02) e (g) veredito de cada premissa, citando as medições; o da premissa 1 deve se basear no sofá.

## 6. Problemas comuns

| Sintoma | Causa provável | Ação |
|---------|----------------|------|
| Nada no log de botões com o Terminal em foco | Input Monitoring necessário ou pendente de relançamento (P-04) | Conceder e relançar; anotar. |
| Cursor não se move, mas os botões aparecem no log | Acessibilidade ausente ou perdida após recompilação | Conferir `permissions.status`; repetir a Fase 0. |
| Duas entradas "JoystickAIPoC" na lista de Acessibilidade | App aberto de caminhos diferentes ou assinaturas diferentes | Remover as duas, instalar só em `~/Applications` e conceder de novo. |
| Argumentos de `--args` sem efeito | A PoC já estava aberta | Encerrar com `osascript` antes do `open`. |
| Game Center ou Launchpad abre ao pressionar PS | O botão Início do controle tem ação no sistema; a supressão pedida pela PoC não tem efeito (PM-2) | Ajustes do Sistema > Controles de jogo > "Pressione o Botão de Início para abrir": Nenhum. |
| Touchpad sem `input.touch` por Bluetooth | Controle no relatório simplificado, sem touchpad | Conferir `controller.extended_report` com `result: "ok"`; outro valor indica falha ao abrir o dispositivo HID. Reconectar o controle com a PoC aberta repete o pedido. |
