# Regression watch: Sugestão de palavras no teclado remoto

> Identificador: `009-sugestao-de-palavras`
> Âncora: legado (`_reversa_sdd/architecture.md`, `_reversa_sdd/domain.md`, extração de 2026-09-15). Os itens do watch principal nascem da seção "Modificadas" do `legacy-impact.md`; só regras originalmente 🟢 entram nele. As regras da 008, ainda sem adendo, e os requisitos e decisões 🟡 desta feature, que dependem do PM-0 e do PM-1, ficam em "Observações", sem peso de regressão.

## Watch principal

| ID | Origem (arquivo, seção) | Regra esperada após mudança | Tipo de verificação | Sinal de violação |
|----|--------------------------|------------------------------|---------------------|-------------------|
| W001 | `_reversa_sdd/domain.md` §3.1, 001 RN-12; `_reversa_sdd/permissions.md` §4 | O contexto recente do teclado remoto vive só em memória, em `SuggestionContext` dentro de `RemoteKeyboardActions`, limitado a 200 caracteres e apagado a cada descarte e no fim da sessão; só as palavras sugeridas saem do Mac, pelo canal da 008. | redação | Re-extração sem a exceção do contexto em memória, `SuggestionContext.maxContext` acima de 200, ou contexto gravado em arquivo, `UserDefaults` ou `config.json`. |
| W002 | `_reversa_sdd/domain.md` §3.1, 001 RN-12 | Em entrada segura (`IsSecureEventInputEnabled()`), nenhuma tecla alimenta o contexto; o que havia é descartado e a faixa esvazia. | presença | `RemoteKeyboardActions.feed` sem a consulta à entrada segura antes de `suggestions.apply(.text…)`, ou P-01 reprovada sem decisão registrada. |
| W003 | `_reversa_sdd/injecao-de-eventos/requirements.md`, RN-IN-16; `_reversa_sdd/domain.md` §3.3, 003 RN-14 | Nenhum evento leva palavra, contexto, sugestão, revisão, índice, idioma ou visibilidade; `remote.disconnected` traz só `reason`, `keys` e `suggestions`. | ausência | `LogEventCatalogTests.eventosDoTecladoRemotoSemConteudo` vermelho, ou chave `word`, `words`, `text`, `context`, `rev` ou `lang` num evento. |
| W004 | `_reversa_sdd/injecao-de-eventos/requirements.md`, RN-IN-02 | A aceitação de sugestão só digita com o portão aberto, na revisão da lista enviada e sem modificador do iPhone mantido ou preso; recusada, o contexto não muda. | presença | `RemoteKeyboardActions.pick` sem `keyboard.enabled`, ou `SuggestionContextTests.revisaoVelhaDevolveNil` vermelho. |
| W005 | `_reversa_sdd/traceability/code-spec-matrix.md` | Contagens: `SuggestionContextTests` 23, `RemoteKeyboardMessageTests` 11, `RemoteKeyboardAssetsTests` 6, `LogEventCatalogTests` 11; total de 379 testes em 40 suítes. | redação | Matriz com as contagens da 008 sem feature que as reduza, ou alguma das suítes removida. |

## Observações

Regras da 008 (sem adendo) e requisitos e decisões 🟡 desta feature, conferidos no PM-0 (sondas P-01 a P-04) e no PM-1; sem peso de regressão até uma re-extração os confirmar como 🟢. Os RF implementados entram aqui pelo mesmo motivo.

| ID | Origem (arquivo, seção) | Regra esperada | Tipo de verificação | Sinal de violação |
|----|--------------------------|----------------|---------------------|-------------------|
| O001 | `investigation.md` §5, P-01; roadmap D-07 | `IsSecureEventInputEnabled()` fica verdadeiro num campo de senha do Safari e com a entrada segura do Terminal, e falso num campo comum. | presença | Sonda com `secure: false` no campo de senha; reprovada, RN-06 volta ao usuário. |
| O002 | `investigation.md` §5, P-02; roadmap D-02; RF-06 | O tradutor reproduz o texto do sistema: "ação", "´" + "a", ⇧ preso e Caps Lock, com as fontes Português e EUA Internacional. | presença | Texto da sonda diferente do recebido pelo TextEdit. |
| O003 | `investigation.md` §5, P-03 | O sufixo e o espaço aparecem no Terminal, no iTerm e no terminal integrado do VS Code, sem caractere a mais. | presença | Sufixo ausente ou duplicado num dos três. |
| O004 | `investigation.md` §5, P-04; roadmap D-09; RF-01 | A barra ampliada mostra três sugestões legíveis e todas as teclas sem rolar, no iPhone do usuário. | presença | Tecla cortada ou sugestão ilegível; reprovada, T027 ajusta a altura. |
| O005 | `requirements.md` RN-03; roadmap D-06; RF-04 | Setas, Esc, ⌘ ou ⌃, ⌥⌫, botão do controle, troca de aplicativo, troca de fonte, fim da sessão e recurso desligado descartam o contexto. | presença | Faixa com sugestões depois de ← ou de trocar de aplicativo (passos 10 e 11 do PM-1). |
| O006 | `requirements.md` RN-04; roadmap D-04; RF-03, RF-10 | Só palavras que estendem exatamente a digitada; a primeira letra segue a caixa digitada, e a aceitação acrescenta sufixo e espaço. | presença | Letra duplicada, texto apagado ou caixa trocada nos passos 3 a 5. |
| O007 | `requirements.md` RN-09; roadmap D-08, D-10; RNF de desempenho | A tecla é injetada antes da consulta; lista velha nunca aparece nem é aceita; sugestões em até 150 ms no p95. | presença | Passo 15 do PM-1 com lista de prefixo ultrapassado, ou tecla mais lenta com a faixa ativa. |
| O008 | `requirements.md` RN-12, RN-13; RF-08, RF-11 | Previsão só após espaço que encerrou palavra só de letras; palavra com caractere que não seja letra fica sem sugestão. | presença | Sugestão em `cd ~/dev/joy` ou `-la`, ou previsão após Return. |
| O009 | `requirements.md` RN-05, RN-14; roadmap D-11; RF-07, RF-12 | Idioma e visibilidade em `localStorage` (`remoteKeyboardPrefs`), enviados em `prefs` após `welcome`; com a faixa oculta, nenhuma consulta. | presença | Seletor volta a PT ao reabrir a página, ou `suggest` com palavras com a faixa oculta. |
| O010 | `requirements.md` RN-11; RF-13 | Toque numa sugestão não envia `down` nem `up`, não solta modificadores presos e marca a sugestão até o dedo sair; faixa vazia não faz nada. | presença | `keys` de `remote.disconnected` contando as aceitações, ou `pick` enviado de faixa vazia. |
| O011 | `requirements.md` RF-09; roadmap D-13 | Três sugestões aceitas geram `remote.disconnected` com `suggestions: 3`. | presença | Contagem diferente das aceitações no passo 18 do PM-1. |

## Histórico de re-extrações

_(vazio; preenchido pelo agente reverso quando `/reversa` rodar de novo)_

## Arquivadas

_(vazio)_
