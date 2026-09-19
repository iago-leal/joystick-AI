# Interface: ponte entre o editor e a página da figura (delta do controle ativo)

> Feature: `007-controle-ipega`
> Tipo: JSON em memória, entre o processo do app e o processo WebContent do WebKit; sem rede, sem arquivo
> Contrato base: `_reversa_forward/004-figura-controle-web/interfaces/figure-bridge.md`
> Origem: `requirements.md` RN-12, RN-13, RF-10, RF-11; `roadmap.md` D-08, D-09
> Confidência: 🟢 salvo indicação

## 1. O que muda

Carga, navegação, armazenamento, falhas e o canal página → app seguem o contrato base. Mudam o corpo de `figure.render(state)` e a página.

## 2. App → página: `figure.render(state)`

```json
{
  "layer": "base | <ButtonID.rawValue>",
  "controller": "dualSense | ipega",
  "buttons": [
    { "id": "share", "label": "Share", "summary": "nenhuma", "kind": "own", "problem": false, "selected": false }
  ]
}
```

Regras novas ou alteradas:

- `buttons` tem sempre **19** itens, um por `ButtonID`, na ordem de `ButtonID.allCases`, com `share` por último.
- `controller` vem de `EditorViewModel.activeModel`; sem controle ativo, `"dualSense"`.
- Com `controller: "ipega"`, o item `touchpadClick` mantém `kind: "fixed"` e traz `summary: "ausente neste controle"`.
- A página aplica `data-controller="<valor>"` ao elemento `.figure` a cada chamada. Valor desconhecido é tratado como `dualSense`.
- Com `dualSense`, o grupo e o balão `[data-button="share"]` ficam ocultos por CSS e não recebem clique. Com `ipega`, o grupo `[data-button="touchpadClick"]` recebe o estilo de ausente (traço e opacidade reduzidos) e continua clicável, e o Share aparece.
- Um app anterior à feature envia 18 itens sem `controller`; a página nova o trata como `dualSense` (não há convivência de versões, mas o comportamento é definido).

## 3. Página → app

Sem mudança: `{ button: id }`, agora também com `id: "share"` quando o Ipega está ativo.

## 4. Página

- `index.html`: grupo `[data-button="share"]` (linha-guia, área de acerto 60 × 60, desenho e rótulo) e balão correspondente. Posição conforme `roadmap.md` D-09, ajustada no PM-1.
- `figure.js`: `positions.share` na tabela; `render` grava `data-controller`. Nenhum temporizador, armazenamento ou rede, como no contrato base.
- `figure.css`: regras para `[data-controller="dualSense"] [data-button="share"]` e `[data-controller="ipega"] [data-button="touchpadClick"]`.
- `FigureAssetsTests` continua proibindo `innerHTML` e afins, e passa a conferir que os 19 identificadores têm grupo e balão.
