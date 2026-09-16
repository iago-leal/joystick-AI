# Interface: ponte entre o editor e a página da figura

> Feature: `004-figura-controle-web`
> Tipo: JSON em memória, entre o processo do app e o processo WebContent do WebKit; sem rede, sem arquivo
> Origem: `requirements.md` RN-04, RN-07, RN-09, RF-05, RF-06, RF-09 e RNF de segurança; `roadmap.md` D-06, D-07, D-08, D-10
> Confidência: 🟢 salvo indicação

## 1. Partes

| Parte | Onde | Responsabilidade |
|-------|------|------------------|
| `FigureBridge` | `Sources/JoystickAIPoC/Editor/FigureBridge.swift`, main thread | Carrega a página, envia o estado, recebe o clique, trata falhas |
| `figure` (objeto global do script) | `Resources/ControllerFigure/figure.js` | Desenha o estado recebido e envia o identificador do botão clicado |

A página não tem outro canal: não navega, não abre janelas, não usa `fetch`, `XMLHttpRequest`, `WebSocket`, `localStorage`, `sessionStorage`, `indexedDB` nem `cookies` (RN-09).

## 2. Carga

| Passo | Detalhe |
|-------|---------|
| Localização | `Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "ControllerFigure")` |
| Carga | `webView.loadFileURL(index, allowingReadAccessTo: index.deletingLastPathComponent())` |
| Navegação permitida | Só o URL de `index.html`; qualquer outro `navigationAction` recebe `.cancel` |
| Armazenamento | `WKWebsiteDataStore.nonPersistent()` |
| Pronto | `webView(_:didFinish:)`: o bridge envia o último estado guardado |
| Ausente | `url == nil` → `FigureFailure.resourceMissing`, sem criar o `WKWebView` |
| Falha de carga | `didFailProvisionalNavigation` / `didFail` → `.loadFailed` |
| Queda do processo | `webViewWebContentProcessDidTerminate` → uma recarga; segunda queda em 60 s → `.processTerminated` 🟡 |

## 3. App → página: `figure.render(state)`

Chamada: `webView.callAsyncJavaScript("figure.render(state)", arguments: ["state": object], in: nil, in: .page)`, em que `object` é o resultado de `JSONSerialization.jsonObject(with: JSONEncoder().encode(figureState))`.

Corpo de `state` (ver `data-delta.md` §2):

```json
{
  "layer": "base | <ButtonID.rawValue>",
  "buttons": [
    {
      "id": "cross",
      "label": "✕",
      "summary": "Return",
      "kind": "fixed | modifier | own | inherited",
      "problem": false,
      "selected": true
    }
  ]
}
```

Regras:

- `buttons` tem sempre 18 itens, um por `ButtonID`, na ordem de `ButtonID.allCases`. A página desenha pelos `id` e ignora itens com `id` desconhecido; um `id` esperado ausente deixa o botão como estava.
- `label` e `summary` são escritos com `textContent`. A página nunca usa `innerHTML`, `outerHTML`, `insertAdjacentHTML`, `document.write` nem `eval` (verificado por `FigureAssetsTests`, D-03).
- `kind`, `problem` e `selected` viram classes `is-fixed`, `is-modifier`, `is-inherited`, `is-problem`, `is-selected` no grupo `[data-button="<id>"]`; `own` não adiciona classe.
- A chamada é idempotente: enviar o mesmo estado duas vezes não muda nada. O bridge só envia quando `figureState` difere do último enviado (D-14).
- Antes de `didFinish`, o bridge guarda o estado e não chama o script. Depois, cada mudança gera uma chamada; sem coalescência.
- Tempo esperado da chamada à pintura: ≤ 100 ms (RNF de desempenho), medido no PM-2.
- Erro devolvido por `callAsyncJavaScript` (exceção no script) é registrado como `editor.figure_unavailable { reason: load_failed }` uma vez por abertura e não interrompe o editor 🟡.

## 4. Página → app: `messageHandlers.figure`

Chamada no script: `window.webkit.messageHandlers.figure.postMessage({ button: "<id>" })`, disparada por um `click` em qualquer parte de um grupo `[data-button]` (desenho, balão ou área de acerto).

Tratamento no bridge (`userContentController(_:didReceive:)`):

| Corpo recebido | Ação |
|----------------|------|
| `{ "button": "<rawValue válido>" }` | `model.select(ButtonID(rawValue:)!)` na main thread |
| `button` ausente, não string ou fora do catálogo | ignorado, sem log, sem erro |
| Corpo que não é dicionário | ignorado |
| Qualquer outro handler | não existe; `postMessage` para outro nome lança erro dentro da página e não chega ao app |

O app não responde à mensagem; a confirmação visual vem do próximo `figure.render` com `selected` atualizado.

## 5. Página → app: nada mais

Não há evento de `hover`, de carga, de tamanho nem de tema vindo da página. O realce sob o ponteiro (RF-14) e as transições (RF-15) são só CSS.

## 6. Isolamento

| Mecanismo | Onde | Cobre |
|-----------|------|-------|
| `<meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'self'; style-src 'self'">` | `index.html` | Subrecursos: scripts, estilos, imagens, fontes, `fetch`, frames 🟡 (sonda P-03; reserva inline em D-06) |
| `decidePolicyFor(navigationAction:)` | bridge | Navegação de nível superior e frames |
| `javaScriptCanOpenWindowsAutomatically = false`; sem `WKUIDelegate` | bridge | `window.open`, alertas e diálogos (não há `WKUIDelegate`, logo `alert`, `confirm` e `prompt` não exibem nada) |
| `FigureAssetsTests` | testes | Regressão no repositório: referências externas e uso de marcação no script |
| `allowingReadAccessTo` restrito à pasta | bridge | Leitura de outros arquivos do disco pela página |

## 7. Compatibilidade

- `callAsyncJavaScript`: macOS 11+; `underPageBackgroundColor`: macOS 12+; mínimo do app: macOS 13.
- A mudança de campos em `FigureState` é compatível para a página enquanto `id`, `label`, `summary`, `kind`, `problem` e `selected` existirem; a página ignora campos desconhecidos.
