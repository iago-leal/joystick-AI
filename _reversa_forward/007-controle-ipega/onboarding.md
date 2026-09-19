# Onboarding: Controle Ipega ao lado do DualSense

> Identificador: `007-controle-ipega`
> Data: `2026-09-19`
> Público: quem vai testar a feature pela primeira vez (o programador de sofá, no papel de avaliador)
> Roadmap: `_reversa_forward/007-controle-ipega/roadmap.md`

O roteiro tem um portão, o **PM-1**, que roda depois do `/reversa-coding`. As sondas que decidiam o desenho já foram feitas em 2026-09-19 (ver `investigation.md` §2). Se a implementação alterar nomes, rótulos ou posições, o `/reversa-coding` deve atualizar este arquivo. Cada passo indica o cenário da seção 7 do `requirements.md` ou a sonda que verifica.

## 0. Pré-requisitos

| Item | Como conferir |
|------|---------------|
| App das features 003 a 006 instalado, assinado com "JoystickAI Local Signing", Acessibilidade e Input Monitoring concedidas | `./scripts/check-signature.sh`; log com `permissions.status` |
| Ipega **no modo Switch** e ligado por cabo USB | `ioreg -r -c IOHIDDevice -l \| grep -A2 '"Product" = "Pro Controller"'` mostra o dispositivo; se aparecer com outra identidade, o controle está em outro modo |
| DualSense disponível, carregado | Para os passos de fila e de regressão |
| Terminal aberto, com um prompt vazio | Destino da digitação |

**Modo do Ipega.** Os botões Android e iOS trocam o modo do controle, e em outro modo ele se apresenta ao Mac com outra identidade, que o app ignora (RN-01). Se isso acontecer, volte ao modo em que o `ioreg` o mostra como "Pro Controller"; a combinação exata de botões depende do modelo e está no manual do Ipega.

Guarde a configuração atual antes de tudo:

```sh
cp ~/.config/joystick-ai/config.json ~/.config/joystick-ai/config.pre-007.json 2>/dev/null || echo "sem arquivo: vale o padrão"
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
# restaurar a configuração guardada
cp ~/.config/joystick-ai/config.pre-007.json ~/.config/joystick-ai/config.json
```

## 1. Testes automatizados, depois do código

1. Rode `./scripts/test.sh`. Espere todos verdes, com os testes de D-11: classificação dos modelos, bit do Home, fila mista, `share` válido como gatilho e modificador, documento padrão idêntico, figura com 19 itens e `controller`, log com `model` e cobertura por modelo.

## 2. Portão manual PM-1, depois do código

Com o app novo instalado, aberto com `--debug`, e **só o Ipega** conectado no início.

| Passo | Ação | Resultado esperado | Cenário ou sonda |
|-------|------|--------------------|------------------|
| 1 | Rode `grep -E '"controller\.connected"' "$LOG" \| tail -1`. | `model: "ipega"` e `connection: "usb"` | RF-12 |
| 2 | Mova o analógico esquerdo; segure L e mova de novo; pressione R e ZR; incline o analógico direito. | O cursor se move, fica lento com L, faz clique esquerdo e direito, e a página rola | Usar o Ipega sozinho; RF-05 |
| 3 | Pressione, um por vez, os 18 botões do Ipega: A, B, X, Y, L, R, ZL, ZR, L3, R3, Select, Start, Home, Share e as quatro direções. Rode `swift run poc-tools buttons "$LOG"`. | 18 de 18, com `share` e sem `touchpadClick` | RF-02 |
| 4 (P-01) | Com o arquivo de configuração afastado (`mv ~/.config/joystick-ai/config.json /tmp/`), pressione Home uma vez. Feche a paleta com B. | A paleta abre uma única vez; nenhum Launchpad, sobreposição de jogos ou outro gesto do sistema aparece | Home abre a paleta; risco residual |
| 5 | Ainda sem arquivo, com o terminal em foco, segure L e pressione A. Pressione Share. Devolva o arquivo. | "CONTINUAR" é digitado (ou a ação que o padrão der a L1 + ✕); Share não faz nada | Correspondência por posição; Share sem ação por padrão |
| 6 | Abra o editor e observe a aba Atalhos. | A figura é a do DualSense, com o Share visível, o touchpad marcado como ausente e os nomes ✕, ○, L1, Options, PS | Figura com o Ipega ativo |
| 7 | Ajuste visual do balão do Share (D-09): confira se ele cruza a linha-guia de outro botão ou se sobrepõe a outro balão. | Nenhum cruzamento nem sobreposição; se houver, o `/reversa-coding` ajusta a posição e repete | D-09 |
| 8 | No modo de identificação, pressione Select, depois Share, depois Start. | Selecionam Create, Share e Options na figura | Identificação no editor |
| 9 | Selecione o Share na figura. | O painel oferece os tipos de ação dos botões livres, sem a mensagem de clique fixo | Share recusa papel de clique |
| 10 | Atribua ao Share o texto "teste share", sem Enter. Salve. Com o terminal em foco, pressione Share. | "teste share" aparece no terminal; nenhum clique | Share como atalho livre |
| 11 | No editor, atribua a L1 + ✕ um texto qualquer e salve, com o Ipega ativo. Conecte o DualSense, desligue o Ipega e pressione L1 + ✕ no DualSense. | O DualSense digita o texto atribuído com o Ipega | Configuração compartilhada |
| 12 | Com o DualSense ativo, abra o editor. | A figura é a de antes da feature: sem Share e com o touchpad normal | RF-11 |
| 13 | Com o DualSense ligado primeiro, conecte o Ipega. Mova o analógico do Ipega. Desligue o DualSense e mova de novo. | O cursor só se move na segunda vez; o log mostra `controller.queued` e a promoção | Dois controles conectados |
| 14 | Marque o Share como modificador ⌘ e salve. Segure Share e desconecte o cabo do Ipega. Digite no teclado físico. | As letras saem sem ⌘ | Desconexão com botão pressionado |
| 15 | Pressione Turbo e Clear (sem trocar de modo). Rode `grep -c '"input.button"' "$LOG"` antes e depois. | Contagem igual | Botões de firmware |
| 16 | Com o DualSense ativo, pressione cada botão e use o touchpad. | Cada botão faz o mesmo que antes da feature; o touchpad move e clica | DualSense inalterado |
| 17 (P-02, informativa) | Se o Ipega tiver modo sem fio no modo Switch, pareie-o pelo Bluetooth e repita os passos 1, 3 e 4. | Registrar o transporte, a cobertura e se o Home chega; falha aqui não reprova a feature | P-02 |
| 18 | Rode `grep -E '"controller\.ignored"' "$LOG"`. Se outro controle (o `GamePad-1`, por exemplo) estiver presente, ele aparece uma vez com `reason: "unsupported_model"`. | No máximo uma linha por controle ignorado | Outro controle do tipo Switch Pro; Ipega em outro modo |
| 19 | Decida entre manter a configuração nova ou restaurar `config.pre-007.json`. | Estado desejado pelo usuário | — |

Registre o resultado de cada passo e das sondas no `actions.md` da feature.
