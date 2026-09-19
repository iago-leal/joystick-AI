# Investigação: Sugestão de palavras no teclado remoto

> Identificador: `009-sugestao-de-palavras`
> Data: `2026-09-19`
> Confidência: 🟢 CONFIRMADO, 🟡 INFERIDO, 🔴 LACUNA

As afirmações sobre o motor de previsão vêm da sonda executada no Mac do usuário em 2026-09-19 e são 🟢. As demais afirmações sobre a plataforma vêm de conhecimento prévio, aparecem como 🟡 e são confirmadas pelas sondas da §5.

## 1. Pergunta

Como mostrar no iPhone sugestões de palavras para o que está sendo digitado no teclado remoto, em português e em inglês, sem ler o conteúdo de outros aplicativos, sem rede e sem atrasar as teclas?

## 2. Motor de sugestões

Sonda com dois programas Swift compilados pelas Command Line Tools, em 2026-09-19, com as fontes de entrada do usuário (Português e EUA Internacional) ativas.

| Opção | Resultado da sonda | Veredito |
|-------|--------------------|----------|
| `NSSpellChecker.completions(forPartialWordRange:in:language:inSpellDocumentWithTag:)` | `pt_BR`: nenhuma sugestão para nenhuma entrada. `pt_PT` e `en`: sugestões por prefixo sem acento ("funç" → "funciona", sem "função"), ordem fraca, primeira chamada de 97 a 435 ms 🟢 | descartada |
| `NSSpellChecker.requestCandidates(forSelectedRange:in:types:options:inSpellDocumentWithTag:)` com ortografia fixada | `pt_BR`: "funç" → "Função"; "o reposit" → "repositório"; "vamos impl" → "implementar"; "Olá, tudo " → "bem"; "Eu quero " → "que", "ver", "saber". `en`: "Please refac" → "refactor". De 2 a 17 ms por consulta; primeira consulta de 85 a 90 ms 🟢 | escolhida (D-01) |
| O mesmo motor em detecção automática de idioma | "vamos impl" → "implementation"; trechos curtos são classificados como inglês 🟢 | descartada; seletor PT / EN (RN-05) |
| Dicionário e frequências próprios | Exigiria empacotar e manter listas por idioma; sem previsão da palavra seguinte | descartada |
| Modelo de linguagem local ou remoto | Contraria RN-07; custo de memória ou rede | descartada |

Observações da sonda que orientam o filtro (D-04) 🟢:

- a primeira sugestão é sempre a própria palavra digitada, com a primeira letra maiúscula quando não há contexto;
- todas as sugestões chegam com um espaço no fim;
- sem contexto anterior, o motor supõe início de frase e põe maiúscula ("impl" → "Implorando", "Implica");
- em caminhos e opções, o motor sugere palavras comuns ("cd ~/dev/joy" → "joystick "; "ls -la" → "lado").

## 3. De onde vem o texto digitado

| Opção | Avaliação | Veredito |
|-------|-----------|----------|
| Ler o campo em foco pela Acessibilidade (`AXValue`, `AXSelectedTextRange`) | Contexto perfeito em aplicativos Cocoa, mas lê conteúdo de outros aplicativos e falha em terminais, que expõem mal o texto 🟡 | descartada na sessão do `/reversa-clarify` |
| Montar o texto a partir da `KeyLabelTable` da 008 | Não compõe teclas mortas e não acompanha o estado real de ⇧, ⌥ e Caps Lock | descartada |
| Traduzir cada tecla injetada com `UCKeyTranslate`, guardando o estado de tecla morta | Mesmo cálculo que o sistema faz; o acesso ao layout já existe em `KeyboardLayoutReader` (008 D-12) 🟡 | escolhida (D-02), confirmada por P-02 |

## 4. Como aceitar uma sugestão

| Opção | Avaliação | Veredito |
|-------|-----------|----------|
| Apagar a palavra em composição e digitar a sugestão inteira | Permite corrigir acentos, mas apaga texto errado se o contexto estiver dessincronizado, e o apagar com ⌥ preso apagaria a palavra anterior | descartada |
| Digitar só o sufixo que falta, oferecendo apenas sugestões que estendem exatamente o que foi digitado | Nunca apaga; o pior caso de dessincronia é um sufixo fora de lugar | escolhida (D-04, D-05) |
| Digitar o sufixo por teclas com código | Dependeria da fonte de entrada e das teclas mortas | descartada |
| Digitar o sufixo por `keyboardSetUnicodeString` (`KeyboardInjector.type`, RN-IN-12) | Já usado pelas ações de texto da paleta e dos atalhos, inclusive em terminais 🟢 | escolhida |

## 5. Sondas do PM-0

| Sonda | Método | Critério de aprovação |
|-------|--------|-----------------------|
| P-01 entrada segura | Com o app em modo de depuração, registrar em arquivo à parte (apagado ao fim) o valor de `IsSecureEventInputEnabled()` a cada tecla, digitando num campo de senha do Safari, no Terminal com "Entrada de Teclado Segura" ligada e num campo comum | Verdadeiro nos dois primeiros casos e falso no terceiro |
| P-02 tradução | Com as fontes Português e EUA Internacional, digitar pelo iPhone "ação", "´a", "⇧a" com ⇧ preso e uma letra com o Caps Lock ligado; comparar o texto do tradutor, no mesmo arquivo de depuração, com o que o TextEdit recebeu | Textos iguais nos quatro casos |
| P-03 inserção nos terminais | Com uma sugestão aceita no Terminal, no iTerm e no terminal integrado do VS Code, com o Claude Code aberto em um deles | O sufixo e o espaço aparecem nos três, sem caractere a mais |
| P-04 altura da barra | Abrir a página nova no iPhone do usuário, pela Tela de Início, na horizontal | Barra com três sugestões legíveis e todas as teclas visíveis sem rolar |

## 6. Padrões aplicáveis

- Núcleo funcional com casca imperativa (`_reversa_sdd/architecture.md#2. Estilo arquitetural`): `SuggestionContext` puro, testado sem sistema, como a `RemoteKeyboardMachine` da 008.
- Revisão monotônica para descartar respostas assíncronas velhas, padrão comum em autocompletar de editores.
- Pedido único em curso com substituição do pendente, para não enfileirar consultas durante rajadas de digitação.
