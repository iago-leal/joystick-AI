# Onboarding: Controle DualShock 4 ao lado do DualSense e do Ipega

> Identificador: `012-controle-dualshock-4`
> Data: `2026-09-22`
> Público: quem vai testar a feature pela primeira vez (o programador de sofá, no papel de avaliador)
> Roadmap: `_reversa_forward/012-controle-dualshock-4/roadmap.md`

O roteiro tem dois portões. O **PM-0** roda **antes** do código: três sondas no aparelho que fixam a disposição dos relatórios e o comportamento do sistema de que as decisões D-02, D-04 e D-05 dependem. O **PM-1** roda depois do `/reversa-coding`, no mínimo pedido pelo usuário, todo por Bluetooth com o GameSir G8+ no modo PlayStation. Se a implementação alterar nomes, rótulos ou passos, o `/reversa-coding` deve atualizar este arquivo. Cada passo indica o cenário da seção 7 do `requirements.md` ou a sonda que verifica.

## 0. Pré-requisitos

| Item | Como conferir |
|------|---------------|
| App da feature 011 instalado, assinado com "JoystickAI Local Signing", Acessibilidade e Input Monitoring concedidas | `./scripts/check-signature.sh`; log com `permissions.status` |
| GameSir G8+ **no modo PlayStation**, casado por Bluetooth e conectado | `ioreg -r -c IOHIDDevice -l \| grep -B4 -A12 '"Product" = "DUALSHOCK 4'` mostra `VendorID = 1356` (0x054C), `ProductID = 1476` (0x05C4) e `Transport = "Bluetooth"`; se aparecer com outra identidade, o controle está em outro modo |
| Terminal com Input Monitoring concedido | Necessário só para as sondas do PM-0, que leem o relatório HID de um programa avulso; Ajustes do Sistema › Privacidade e Segurança › Monitoramento de Entrada |
| DualSense e Ipega disponíveis, carregados | Para os passos de fila e de regressão do PM-1 |
| Terminal aberto, com um prompt vazio | Destino da digitação |

**Modo do GameSir.** A combinação que troca o modo está no manual do GameSir G8+; em outro modo (Xbox, Switch), o controle se apresenta ao Mac com outra identidade, que o app ignora e registra uma vez (RN-01). Depois de trocar o modo, é comum ter de casar o controle de novo, porque cada modo aparece ao Mac como um aparelho diferente. Para desligar o controle, use o método do manual; muitos clones desligam com o PS mantido por dez segundos. Se preferir, desative o Bluetooth do Mac para simular a desconexão.

Guarde a configuração atual antes de tudo:

```sh
cp ~/.config/joystick-ai/config.json ~/.config/joystick-ai/config.pre-012.json 2>/dev/null || echo "sem arquivo: vale o padrão"
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
# eventos de controle
grep -E '"controller\.' "$LOG" | tail -10
# cobertura de botões do controle da sessão
swift run poc-tools buttons "$LOG"
# dispositivos Sony e GameSir no IORegistry
ioreg -r -c IOHIDDevice -l | grep -E '"(Product|VendorID|ProductID|Transport)"' | grep -B1 -A2 -E '1356|13623'
```

## 1. Portão manual PM-0, antes do código (sondas)

As sondas rodam de um programa Swift descartável, `sondas/probe-ds4.swift` nesta pasta, que o `/reversa-coding` escreve como primeira ação e que **não** faz parte do app. O programa: enumera `GCController.controllers()` com `shouldMonitorBackgroundEvents` ligado, imprime a classe do perfil, a categoria e os elementos, e a cada mudança de botão imprime o nome do elemento; abre um `IOHIDManager` casando 0x054C com 0x05C4 e 0x09CC, imprime o identificador e o tamanho dos relatórios de entrada que chegam e, quando um byte muda, o índice e o valor; sob comando, lê o relatório de recurso `0x05` e imprime o resultado; imprime `battery` do controle. Feche o app antes das sondas, para que os dois não disputem o controle.

```sh
pkill -x JoystickAIPoC 2>/dev/null
cd _reversa_forward/012-controle-dualshock-4
swift sondas/probe-ds4.swift
# se o compilador reclamar do SDK:
# SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk swift sondas/probe-ds4.swift
```

Teclas do programa, seguidas de Enter: `f` lê o recurso `0x05`; `b` imprime a bateria; `e` reimprime os elementos; `s` imprime o resumo dos relatórios e do ruído de repouso; `q` sai. Ao iniciar, e a cada formato novo de relatório, o programa aprende por 3 s os bits que mudam em repouso (contador, analógicos) e depois só imprime o que muda fora desse ruído: **não toque em nada nesses 3 s**. Cada botão pressionado aparece com o nome do elemento e, entre colchetes, a propriedade do perfil que aponta para ele (`buttonOptions`, `buttonMenu`, `buttonHome`, `touchpadButton`); é esse nome entre colchetes que decide D-02. Copie a saída inteira do terminal para o relato, ou ao menos as linhas marcadas `P-01`, `P-02` e `P-03`.

| Sonda | Ação | O que registrar no `actions.md` | Decide |
|-------|------|----------------------------------|--------|
| P-01 | Com o programa rodando, pressione um por vez: ✕, ○, □, △, L1, R1, L2, R2, L3, R3, Share, Options, PS, o clique do touchpad (se o GameSir tiver tecla para isso) e as quatro direções. | A classe do perfil (`GCDualShockGamepad` esperado), a categoria, o nome do elemento de cada botão; em especial, por qual elemento chega o Share (`buttonOptions` esperado) e se o PS chega pela interface de controles ou não; se o dicionário `touchpads` do perfil físico vem vazio ou com entradas | D-02 (elemento do Share), D-04 (PS retido ou não), D-03 (fonte da fase do toque) |
| P-02 | Ainda com o programa rodando: anote o identificador e o tamanho dos relatórios que chegam em repouso; pressione e solte o PS três vezes e anote o índice e o bit que mudam; peça ao programa a leitura do recurso `0x05` e anote o resultado; anote o identificador e o tamanho dos relatórios depois do pedido; pressione o PS de novo e anote o índice. | Formato inicial (`0x01` com 10 bytes esperado, ou `0x11` com 78 se o sistema já ativou o modo completo); índice do PS em cada formato (7 no `0x01`, 9 no `0x11` esperados); resultado do `0x05` (`ok` ou código); se o formato mudou depois do pedido | D-04 (índices), D-05 (ativação) |
| P-03 | Leia `battery` do controle no programa e o `Transport` no `ioreg`. | Nível, estado (`discharging` esperado) e `Bluetooth` | D-06, D-09 |

Com os três resultados registrados, o `/reversa-coding` confirma ou revisa D-02, D-04 e D-05 antes de tocar o código do app. Se a P-02 não mostrar nenhum bit mudando com o PS **e** a P-01 mostrar que o PS não chega pela interface de controles, pare e leve a decisão ao usuário: o PS ficaria sem função no clone.

### Resultados do PM-0 (2026-09-22, 14:22 a 14:26, GameSir G8+ no modo PlayStation, Bluetooth)

Sonda executada pelo próprio `/reversa-coding` a pedido do usuário, com o usuário ao controle; saída íntegra em `sondas/probe-ds4-2026-09-22.log` (5 759 linhas). O terminal tinha Input Monitoring: `IOHIDManagerOpen: ok`.

| Sonda | Observado | Decide |
|-------|-----------|--------|
| P-01 | Perfil `GCDualShockGamepad` (`is GCDualSenseGamepad = false`), categoria "DualShock 4", 49 elementos, 34 botões. **Share físico → `buttonOptions`; Options → `buttonMenu`**; faces em `buttonA/B/X/Y`; ombros, gatilhos, cliques dos analógicos e direcional nas propriedades homônimas. **O PS não chega pela interface de controles**: nenhuma mudança em `buttonHome` em seis pressões, com `preferredSystemGestureState = disabled` como no app. Dicionário `touchpads` vazio (fase por `zeroTransition`, como o DualSense nos logs). `touchpadPrimary` e `touchpadSecondary` presentes (opcionais no SDK). **O GameSir tem tecla para o clique do touchpad**: chega por `touchpadButton` do `GCDualShockGamepad`, e o clone a acompanha de um ponto de toque fixo em (127, 173) na superfície `touchpadPrimary`, que entra e sai com o clique | D-02 confirmada; D-04 (PS retido) confirmada; D-03 confirmada com uma premissa corrigida (ver T004) |
| P-02 | Desde o primeiro relatório, **`0x11` com 78 bytes**: o sistema já põe o controle no modo completo por Bluetooth; nenhum `0x01` chegou na sessão. Em repouso: `11 C0 00 80 80 80 80 08 00 18 …`. Ruído de repouso: byte 9 bits 3 a 7 (contador), bytes 13 a 26 (carimbo, bateria, sensores de movimento), 74 a 77 (CRC). **PS = bit 0 do byte 9**, alternando a cada pressão (nove transições registradas, mais as que o limite de linhas por segundo da sonda suprimiu durante o ruído dos sensores). Clique do touchpad = bit 1 do byte 9; toque nos bytes 35 a 40. Byte 7: direcional no nibble baixo (repouso 8), □ bit 4, ✕ bit 5, ○ bit 6, △ bit 7. Byte 8: L1 0, R1 1, L2 2, R2 3, Share 4, Options 5, L3 6, R3 7. Gatilhos analógicos nos bytes 10 e 11. **Recurso `0x05`: `ok`, 41 bytes** (`05 00 … 22 00 22 … DE … 1C 02 …`), formato inalterado depois do pedido; PS pressionado de novo depois dele, no mesmo bit 0 do byte 9 | D-04 (índice 9 em `0x11`) confirmada; byte 7 em `0x01` fica da literatura; D-05 mantida (pedido inócuo) |
| P-03 | `battery = 45 % discharging` pela propriedade do sistema (na conexão e sob a tecla `b`, 4 min depois, o mesmo valor); dispositivo HID casado 0x054C/0x05C4, `Transport = "Bluetooth"`, `maxInputReport = 547`, `maxFeatureReport = 64` | D-06, D-09 confirmadas |

Achado fora do previsto: a premissa "os elementos do touchpad existem e nunca mudam de valor" (roadmap §4) é falsa para o clique: o GameSir emite um toque sintético com cada clique do touchpad. O app trata isso sem código novo, porque `TouchpadTracker.isAxisSplit` descarta as amostras de eixo dividido (x, 0) → (x, y) → (0, y) → (0, 0) que o toque fixo produz, então o cursor não se move; o log registra um `input.touch` de início e um de fim por clique. O passo 13 do PM-1 foi ajustado para esse resultado.

## 2. Testes automatizados, depois do código

1. Rode `./scripts/test.sh`. Espere todos verdes, com os testes de D-10: classificação com os três perfis, PS nas duas formas do DualShock 4, fila com três modelos, log com `model: dualShock4` e carga, cobertura de 18 sem `share`, figura com `controller: dualShock4` e recursos da página que conhecem o valor.

## 3. Portão manual PM-1, depois do código

Com o app novo instalado, aberto com `--debug`, e **só o GameSir G8+** conectado no início. Afaste o arquivo de configuração antes dos passos 1 a 5 (`mv ~/.config/joystick-ai/config.json /tmp/`) e devolva-o no passo 6.

| Passo | Ação | Resultado esperado | Cenário ou requisito |
|-------|------|--------------------|----------------------|
| 1 | Rode `grep -E '"controller\.(connected\|ignored)"' "$LOG"`. | Uma linha `controller.connected` com `model: "dualShock4"`, `connection: "bluetooth"`, `atStartup: true` e a carga; nenhuma linha `controller.ignored` para o GameSir | Adoção na abertura; RF-01, RF-13 |
| 2 | Mova o analógico esquerdo; segure L1 e mova de novo; pressione R1 e R2; incline o analógico direito sobre uma página. | O cursor se move, fica lento com L1, faz clique esquerdo e direito, e a página rola | Usar o DualShock 4 sozinho; RF-05 |
| 3 | Pressione, um por vez, os 18 botões: ✕, ○, □, △, L1, R1, L2, R2, L3, R3, Share, Options, PS, clique do touchpad e as quatro direções. Rode `swift run poc-tools buttons "$LOG"`. | `Modelo: dualShock4`; **18 de 18**, sem `share`, com o Share físico contado como `create`. O GameSir tem tecla para o clique do touchpad (P-01), então `touchpadClick` deve aparecer | Correspondência por posição; RF-02 |
| 4 | Pressione PS uma vez. Feche a paleta com ○. | A paleta abre uma única vez; nenhum Launchpad, sobreposição de jogos ou outra tela do sistema aparece | PS abre a paleta; RF-03 |
| 5 | Com o terminal em foco, segure L1 e pressione ✕. | "CONTINUAR" é digitado, como no DualSense e no Ipega | Correspondência por posição; RF-08 |
| 6 | Devolva o arquivo (`mv /tmp/config.json ~/.config/joystick-ai/`). Abra o editor, aba Atalhos. | A figura é idêntica à do DualSense: touchpad presente, sem o botão de captura do Ipega, nomes ✕, ○, L1, Options, Create, PS | Figura com o DualShock 4 ativo; RF-11 |
| 7 | No modo de identificação, pressione Share, depois Options, depois △. | Selecionam Create, Options e △ na figura | Share age como Create; RF-10 |
| 8 | Atribua pelo editor um texto qualquer a L1 + ○ e salve, com o GameSir ativo. Conecte o DualSense, desligue o GameSir e pressione L1 + ○ no DualSense. | O DualSense digita o texto atribuído com o GameSir | Configuração compartilhada; RF-08 |
| 9 | Com o DualSense ligado primeiro, conecte o Ipega e depois o GameSir. Mova o analógico do GameSir. Desligue o DualSense e o Ipega, nessa ordem, e mova de novo. | O cursor só se move depois das duas desconexões; o log mostra `controller.queued` com posições 1 e 2 e as promoções em cadeia | Três controles conectados; RF-06 |
| 10 | No editor, marque Options como modificador ⌘ e salve. Segure Options no GameSir e desligue o controle (ou o Bluetooth do Mac). Digite no teclado físico. | As letras saem sem ⌘; o log mostra `input.button` sintético de `options` com `phase: up` | Desconexão com botão pressionado; RF-07 |
| 11 | Restaure `config.pre-012.json` se tiver mudado a configuração. Com o DualSense ativo, use cada botão e o touchpad; depois, com o Ipega ativo, use cada botão e os analógicos. | Cada botão produz a mesma ação de antes da feature; o touchpad do DualSense move e clica | DualSense e Ipega inalterados; RF-09 |
| 12 | Troque o GameSir para o modo Xbox (ou Switch) e deixe-o reconectar. Rode `grep -E '"controller\.ignored"' "$LOG"`. Volte ao modo PlayStation. | Uma única linha `controller.ignored` para a identidade nova, com `reason: "unsupported_model"`; o app segue com o controle que estiver ativo | GameSir em outro modo; Controle de outro modelo; RN-01 |
| 13 | Ao fim de toda a sessão, rode `grep -c '"input.touch"' "$LOG"` e `grep -E '"controller\.error"\|GameSir' "$LOG"`. | Eventos de toque **só aos pares e só nos cliques do touchpad** (a P-01 mostrou que o GameSir emite um toque fixo com cada clique): a contagem deve ser o dobro dos cliques dados nos passos 3 e 11, e nenhum toque fora deles; o cursor não se moveu em nenhum clique (passo 3). Nenhum `controller.error`; nenhuma linha que cite o GameSir-G8+ (o canal Bluetooth Low Energy) além do que já havia antes da feature | Touchpad num clone sem touchpad; Canal anexo do clone; RF-04, RF-14 |
| 14 | Decida entre manter a configuração nova ou restaurar `config.pre-012.json`. | Estado desejado pelo usuário | — |

Os cenários "Touchpad num controle com touchpad físico" e "Carga nas interfaces" não têm passo aqui: são verificados só por teste automatizado (RN-04, RN-09). O tipo de conexão `usb` também fica só nos testes (RN-08).

Registre o resultado de cada passo e de cada sonda no `actions.md` da feature.
