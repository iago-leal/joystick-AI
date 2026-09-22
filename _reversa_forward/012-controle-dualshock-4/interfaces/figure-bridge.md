# Interface: ponte entre o editor e a página da figura (delta do DualShock 4)

> Feature: `012-controle-dualshock-4`
> Tipo: JSON em memória, entre o processo do app e o processo WebContent do WebKit; sem rede, sem arquivo
> Contrato base: `_reversa_forward/004-figura-controle-web/interfaces/figure-bridge.md`, com a emenda de `_reversa_forward/007-controle-ipega/interfaces/figure-bridge.md`
> Origem: `requirements.md` RN-10, RF-10, RF-11; `roadmap.md` D-08
> Confidência: 🟢

## 1. O que muda

Carga, navegação, armazenamento, falhas, o canal página → app e a forma dos 19 itens seguem os contratos anteriores. Muda só o domínio do campo `controller`.

## 2. App → página: `figure.render(state)`

```json
{
  "layer": "base | <ButtonID.rawValue>",
  "controller": "dualSense | ipega | dualShock4",
  "buttons": [ "… 19 itens, como na 007 …" ]
}
```

Regras novas ou alteradas:

- `controller` passa a poder valer `"dualShock4"`, o `rawValue` real do modelo; vem de `EditorViewModel.activeModel` sem mudança de código no editor.
- Com `controller: "dualShock4"`, os 19 itens são derivados exatamente como com `"dualSense"`: `touchpadClick` continua `kind: "fixed"` com o resumo normal ("clique esquerdo"), e `share` continua com seu resumo, embora oculto.
- A página aplica `data-controller="dualShock4"` ao elemento `.figure`. Com esse valor, o grupo e o balão `[data-button="share"]` ficam ocultos por CSS e não recebem clique, como com `dualSense`; o touchpad tem o estilo normal.
- O rótulo do botão à esquerda do touchpad continua "Create" (`ButtonID.create.displayName`); a página não conhece o nome "Share" do DualShock 4.
- Valor desconhecido continua tratado como `dualSense`, mas o valor `dualShock4` deixa de depender desse padrão.

## 3. Página → app

Sem mudança: `{ button: id }`, com os 18 identificadores do DualSense quando o DualShock 4 está ativo.

## 4. Página

- `index.html`: sem mudança.
- `figure.js`: `CONTROLLERS` ganha `dualShock4: true`.
- `figure.css`: a regra `[data-controller="dualSense"] [data-button="share"]` passa a uma lista de seletores que inclui `[data-controller="dualShock4"] [data-button="share"]`.
- `FigureAssetsTests`: passa a conferir que o script e o estilo citam `dualShock4`.
