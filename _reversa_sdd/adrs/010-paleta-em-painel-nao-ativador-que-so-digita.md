# ADR-010: Paleta em painel não ativador, que só digita e sem Enter por padrão

- **Status:** Aceito
- **Data:** 2026-09-14
- **Tipo:** retroativo (reconstruído pelo Detetive em 2026-09-15)

## Contexto

Comandos longos do Reversa e do Claude Code são impraticáveis com poucos botões. A lista precisa ficar legível na TV e digitar no terminal em foco, sem roubar o foco, e o usuário quer poder completar argumentos antes de enviar.

## Decisão

`NSPanel` sem borda, `nonactivatingPanel`, que nunca é chave nem principal, no nível `statusBar` e em todas as mesas, posicionado na tela do cursor. A máquina `PaletteMachine` recebe os botões enquanto aberta, e os atalhos ficam suspensos. A confirmação só digita (nenhum item executa programa). Pela emenda E001, os itens padrão não enviam Enter; na 003 cada item ganhou a opção.

## Alternativas consideradas

Janela comum (tomaria o foco do terminal); executar comandos por shell (risco e acoplamento); Enter automático (impede argumentos).

## Consequências

🟢 Digita no app em foco sem trocar o foco. 🟡 A paleta abre mesmo sem Acessibilidade, e a confirmação então não produz efeito visível.

## Evidências

- `PalettePanel.swift:12-58`
- `CommandPalette.swift`
- 002 D-01, D-06, D-08, E001
