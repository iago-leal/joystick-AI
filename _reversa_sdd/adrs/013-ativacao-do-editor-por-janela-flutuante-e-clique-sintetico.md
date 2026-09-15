# ADR-013: Ativação do editor por janela flutuante e clique sintético (E003)

- **Status:** Aceito (substitui E002)
- **Data:** 2026-09-15
- **Tipo:** retroativo (reconstruído pelo Detetive em 2026-09-15)

## Contexto

No macOS 26, `NSApp.activate()` pedido a partir de uma ação do controle é recusado, e o editor abria atrás do terminal (P-01 reprovada, 14 `editor.activation_failed` nos logs). A emenda E002, que armava o ícone da barra de menus e levava o ponteiro até ele, também falhou: o clique sintético não conta como interação que autoriza a ativação.

## Decisão

Ao abrir sem ativar, pôr a janela no nível `.floating`, chamar `orderFrontRegardless()` e, após 150 ms sem foco, clicar no centro da barra de título pelo injetor, devolvendo o cursor ao lugar; conferir após 500 ms e registrar `editor.activation_failed` se ainda falhar. Voltar ao nível normal ao ativar ou fechar e devolver o foco ao app anterior.

## Alternativas consideradas

Ativação direta (recusada pelo sistema); E002, ícone armado (revogada); instruir o usuário a clicar (quebra o uso só com o controle).

## Consequências

🟢 P-01 aprovada na rodada 6; nenhum `editor.activation_failed` nos logs após a E003. 🟡 A tela de alvos ainda usa `activate(ignoringOtherApps:)` e pode sofrer a mesma recusa.

## Evidências

- `EditorWindowController.swift:55-90,167-179`
- `EventInjector.swift:115-131`
- `actions.md` 003, rodadas 4 a 6
