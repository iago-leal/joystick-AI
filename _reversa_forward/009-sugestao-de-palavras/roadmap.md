# Roadmap: Sugestão de palavras no teclado remoto

> Identificador: `009-sugestao-de-palavras`
> Data: `2026-09-19`
> Requirements: `_reversa_forward/009-sugestao-de-palavras/requirements.md`
> Confidência: 🟢 CONFIRMADO, 🟡 INFERIDO, 🔴 LACUNA

## 1. Resumo da abordagem

O Mac passa a saber o texto que as teclas do iPhone produzem. Um tradutor no app converte cada tecla injetada no caractere que a fonte de entrada ativa gera, com as teclas mortas, e alimenta uma máquina pura do `JoystickCore`, o `SuggestionContext`, que guarda o contexto recente em memória, aplica as regras de descarte, de caixa e de palavra com cara de código e decide o que pedir. O pedido vai ao motor de previsão de texto do macOS, verificado por sonda na sessão do `/reversa-clarify`. A resposta volta filtrada: só entram palavras que estendem exatamente a palavra em composição, o que faz a aceitação de uma sugestão ser sempre um acréscimo de texto, nunca uma troca. A página recebe as sugestões pelo canal da 008 e as desenha na barra superior, ampliada; o toque volta ao Mac com a revisão do contexto, e o Mac digita o sufixo e o espaço pelo `KeyboardInjector.type`, que já serve às ações de texto. Nada entra no `config.json`: idioma e visibilidade da faixa ficam no navegador do iPhone.

A execução tem dois portões. O PM-0 responde às sondas de entrada segura, tradução de teclas mortas, inserção no terminal e altura da faixa; o PM-1 percorre os cenários do `requirements.md` §7.

## 2. Princípios aplicados

`.reversa/principles.md` não existe neste projeto. Como na 008, a tabela confronta a feature com as restrições equivalentes fixadas pelos ADRs e pelo domínio.

| Princípio | Como a feature se relaciona | Status |
|-----------|------------------------------|--------|
| ADR-001, SwiftPM sem Xcode, núcleo puro e sem dependências de terceiros | Motor de previsão do `AppKit` e tradução por `Carbon.HIToolbox`, ambos do sistema; regras no `JoystickCore`, que segue só com `Foundation` | respeita |
| ADR-005, injeção por `CGEvent` com marca | A sugestão aceita sai por `KeyboardInjector.type`, com a marca `0x4A4F5953` | respeita |
| ADR-008, log JSONL tipado sem dados sensíveis | Só a contagem de sugestões aceitas entra no log | respeita |
| 001 RN-12, sem rede (`_reversa_sdd/domain.md#3.1 Controle e entrada (001)`) | Nenhuma porta nova; o canal da 008 passa a transportar sugestões | respeita a exceção já aberta pela 008 |
| 002 D-05, um único injetor de teclado | O tradutor e a inserção usam a instância criada em `AppDelegate` | respeita |
| 008 D-15, página sem HTML montado a partir de texto | Sugestões desenhadas por `textContent`; `RemoteKeyboardAssetsTests` continua valendo | respeita |

## 3. Decisões técnicas

| ID | Decisão | Justificativa | Alternativas descartadas | Confidência |
|----|---------|----------------|--------------------------|-------------|
| D-01 | Motor: `NSSpellChecker.requestCandidates(forSelectedRange:in:types:options:inSpellDocumentWithTag:)`, com o cursor no fim do contexto recente, `NSOrthography.defaultOrthography(forLanguage:)` para `pt_BR` ou `en` conforme o seletor, e uma etiqueta de documento por sessão. Uma consulta vazia aquece o motor no início da sessão | A sonda mostrou completamento e previsão da palavra seguinte em português, com 2 a 17 ms por consulta e cerca de 90 ms na primeira (`investigation.md` §2) | `completions(forPartialWordRange:)`, que não devolveu nada em `pt_BR`; dicionário próprio; modelo de linguagem, vedado por RN-07 | 🟢 |
| D-02 | Tradução tecla → texto no app, em `KeyTextTranslator`: `UCKeyTranslate` com estado de tecla morta próprio, sobre a fonte de entrada ativa, com ⇧ e ⌥ tirados do estado da `RemoteKeyboardMachine` e o Caps Lock da trava do sistema. Recebe cada `keyDown` e cada repetição depois de injetados; zera o estado de tecla morta a cada descarte | É o mesmo cálculo que o sistema faz ao receber a tecla; reaproveita o acesso ao layout de `KeyboardLayoutReader` (008 D-12) | Ler o texto do campo pela Acessibilidade, recusado na sessão de 2026-09-19; montar o texto a partir da `KeyLabelTable`, que não compõe teclas mortas | 🟡 |
| D-03 | Núcleo `SuggestionContext` no `JoystickCore`: recebe `.text(String)`, `.backspace`, `.boundary(.space \| .return \| .tab)` e `.discard`; mantém o contexto recente (até 200 caracteres), a palavra em composição e uma revisão que sobe a cada mudança; `query()` devolve o texto e o modo (`complete` ou `next`), ou nada quando RN-12, RN-13 ou a faixa oculta o impedem; `filter(_:)` reduz os candidatos do motor a até três palavras; `accept(_:)` devolve o sufixo a digitar | RNF de arquitetura; permite testar RN-02, RN-03, RN-04, RN-12 e RN-13 sem sistema | Regras espalhadas entre app e página | 🟢 |
| D-04 | Filtro dos candidatos: tira o espaço final, aplica a regra de caixa de RN-04 à primeira letra, descarta a própria palavra digitada, palavras que não sejam só letras e repetidas, e **mantém só as que começam exatamente pela palavra em composição**. No modo `next`, mantém a caixa do motor | Faz toda aceitação ser acréscimo: nada é apagado no Mac, e um contexto dessincronizado (tecla física, clique do mouse) não apaga texto alheio | Apagar a palavra e digitar a sugestão inteira, que permitiria corrigir acento ("funcao" → "função"), mas apagaria texto errado se o contexto estiver dessincronizado | 🟢 |
| D-05 | Aceitação: a página envia `pick` com a revisão e o índice; o Mac confere a revisão, a injeção ligada e a ausência de modificador mantido ou preso na máquina, e digita `sufixo + " "` por `KeyboardInjector.type`. Recusado, nada acontece e o contexto não muda | RN-04, RN-10, RN-11; `type` já ignora a fonte de entrada e é usado pelas ações de texto no terminal (002, 003) | Enviar a palavra como teclas por código, que dependeria da fonte de entrada e das teclas mortas | 🟢 |
| D-06 | Descarte (RN-03) nos pontos: `RemoteKeyboardActions` para setas, Esc, tecla comum com ⌘ ou ⌃ mantido ou preso, ⌥⌫ e apagar com contexto vazio; `InputRouter` ganha `onControllerButtonDown`, chamado a cada botão pressionado do controle; `NSWorkspace.didActivateApplicationNotification`; `KeyboardLayoutReader.onChange`; fim de sessão e recurso desligado | Cobre todos os caminhos pelos quais o app sabe que o ponto de escrita pode ter mudado; movimento do ponteiro sem clique não muda o ponto de escrita | Descartar também em movimento do ponteiro, que esvaziaria a faixa sem necessidade | 🟡 |
| D-07 | Entrada segura: `IsSecureEventInputEnabled()` consultado antes de alimentar o contexto com cada tecla; verdadeiro, descarta tudo e envia faixa vazia | RN-06; o sistema liga a entrada segura em campos de senha e no modo de entrada segura do Terminal | Detectar campos de senha pela Acessibilidade, que exigiria ler a interface de outros aplicativos | 🟡 |
| D-08 | Filas: a tecla é injetada e só depois alimenta o contexto, na fila `input`; o pedido ao motor sai da main thread, com no máximo um pedido em curso e o último pedido pendente substituindo os anteriores; a resposta volta à fila `input`, onde só segue para a página se a revisão ainda for a atual | RN-09: nenhuma consulta atrasa a tecla, e respostas velhas nunca chegam à página | Consultar o motor na fila `input`, que atrasaria as teclas na primeira consulta | 🟡 |
| D-09 | Página: a barra superior da 008 passa a abrigar a faixa. À esquerda, um indicador de estado curto; ao centro, três botões de sugestão; à direita, o seletor PT / EN, o botão de ocultar e "Sair". Com estado diferente de "Conectado", o texto do estado ocupa o centro no lugar das sugestões. A barra cresce da altura atual para a de uma linha de teclas; oculta a faixa, volta à altura atual | Uma linha a mais custaria altura das teclas; a barra já existe e hoje fica quase vazia | Linha própria entre a barra e as teclas | 🟡 |
| D-10 | Faixa esmaecida: ao enviar `down` de uma tecla comum, a página esmaece as sugestões e ignora toques nelas até chegar a próxima `suggest`; com modificador mantido ou preso na página, a faixa também fica inativa | Complementa D-08 do lado da página: o usuário nunca toca numa lista que não corresponde ao que digitou (RN-09) | Apagar a faixa a cada tecla, que piscaria a cada letra | 🟡 |
| D-11 | Preferências no iPhone: `localStorage` com a chave `remoteKeyboardPrefs` (`lang`, `visible`); a página envia `prefs` logo após `welcome` e a cada mudança; o Mac as guarda só na sessão. Faixa oculta: o Mac continua montando o contexto, mas não consulta o motor nem envia `suggest` | RN-05, RN-14; mantém o `config.json` intocado e as preferências fora do conteúdo digitado | Preferências no `config.json`, que obrigaria o editor e a migração a conhecê-las | 🟢 |
| D-12 | Protocolo aditivo no canal da 008: cliente ganha `prefs` e `pick`; servidor ganha `suggest` (`rev`, `mode`, `words`). A versão do `hello` segue 1; mensagem `pick` com revisão velha é ignorada sem contar como inválida | Página e app vêm no mesmo bundle; não há cliente antigo a manter | Versão 2 do protocolo | 🟢 |
| D-13 | Log: `remote.disconnected` ganha o campo `suggestions` (sugestões aceitas na sessão); `logSchema` segue 1 | RN-08, RF-09 | Evento por sugestão aceita, que exporia o ritmo da escrita | 🟢 |

## 4. Premissas

O `requirements.md` não tem `[DÚVIDA]` pendente. As premissas abaixo vêm das lacunas 🟡 da seção 10 e são respondidas pelas sondas do PM-0 (`investigation.md` §5).

| Premissa | Origem (`requirements.md` seção) | Risco se errada |
|----------|----------------------------------|-----------------|
| `IsSecureEventInputEnabled()` fica verdadeiro com o foco num campo de senha do Safari e com a entrada segura do Terminal (P-01) | §10, primeira lacuna; RN-06 | Contexto montado sobre senha; a faixa teria de ser desligada por aplicativo |
| O tradutor reproduz o texto que o sistema produz, inclusive "´" + "a" → "á" e ⇧ preso (P-02) | §4, termos; RF-06 | Sugestões para uma palavra diferente da digitada, sem risco de apagar texto (D-04) |
| A inserção por `type` funciona no Terminal, no iTerm e no terminal integrado do VS Code, com o Claude Code em foco (P-03) | §3, cenário principal | Sugestão aceita sem efeito no uso principal |
| A barra ampliada cabe no iPhone do usuário sem tirar teclas da tela (P-04) | §10, segunda lacuna; RF-01 | Faixa estreita demais ou teclas menores que o usável |

## 5. Delta arquitetural

| Componente | Arquivo de origem no legado | Tipo de mudança | Resumo |
|------------|------------------------------|-----------------|--------|
| `JoystickCore` / remote (008) | `_reversa_forward/008-iphone-teclado-remoto/roadmap.md#5. Delta arquitetural` | componente-novo | `SuggestionContext`, `SuggestionQuery`, `SuggestionMode`; `RemoteKeyboardMessage` ganha `prefs`, `pick` e `suggest` |
| app / remote-keyboard (008) | `_reversa_forward/008-iphone-teclado-remoto/roadmap.md#5. Delta arquitetural` | componente-novo | `KeyTextTranslator` (tradução com tecla morta) e `WordSuggester` (motor, fila de pedidos, revisão) |
| app / remote-keyboard (008) | `_reversa_forward/008-iphone-teclado-remoto/roadmap.md#5. Delta arquitetural` | regra-alterada | `RemoteKeyboardActions` alimenta o contexto após cada tecla e aplica `pick`; `RemoteKeyboardService` liga o sugeridor, envia `suggest` e recebe `prefs` |
| `app-shell` | `_reversa_sdd/architecture.md#3. Camadas e dependências` | regra-alterada | `AppDelegate` monta o sugeridor e liga os gatilhos de descarte; `InputRouter` ganha `onControllerButtonDown` |
| Integração nova I-16, motor de previsão de texto | `_reversa_sdd/architecture.md#4. Integrações externas` | contrato-novo | Consulta local de candidatos por idioma, sem rede |
| I-07 AppKit / WindowServer | `_reversa_sdd/architecture.md#4. Integrações externas` | regra-alterada | Observa a troca de aplicativo em foco e consulta a entrada segura |
| Página do teclado remoto (008) | `_reversa_forward/008-iphone-teclado-remoto/roadmap.md#3. Decisões técnicas` (D-15) | regra-alterada | Barra com faixa, seletor e botão de ocultar; preferências em `localStorage` |
| `diagnostics-log` | `_reversa_sdd/architecture.md#5. Modelo de dados em arquivo` | contrato-alterado | Campo `suggestions` em `remote.disconnected` (`interfaces/diagnostic-log.md`) |

## 6. Delta no modelo de dados

- Resumo das mudanças: nenhum campo novo em `config.json` nem arquivo novo no Mac. No iPhone, a página grava as preferências da faixa em `localStorage`. Em memória, o núcleo ganha o contexto recente e a revisão; o protocolo ganha três mensagens; o log ganha um campo.
- Detalhe completo em: `_reversa_forward/009-sugestao-de-palavras/data-delta.md`

## 7. Delta de contratos externos

| Contrato | Tipo | Arquivo de detalhe |
|----------|------|--------------------|
| Canal do teclado remoto (delta sobre a 008) | WebSocket sobre TLS | `_reversa_forward/009-sugestao-de-palavras/interfaces/remote-keyboard-protocol.md` |
| Log de diagnóstico | arquivo JSONL | `_reversa_forward/009-sugestao-de-palavras/interfaces/diagnostic-log.md` |

## 8. Plano de migração

n/a. Não há dado persistido no Mac a migrar. A página nova chega com o app reinstalado; uma aba aberta com a página antiga continua funcionando sem a faixa, porque o Mac só envia `suggest` depois de receber `prefs`.

## 9. Riscos e mitigações

| Risco | Impacto | Probabilidade | Mitigação |
|-------|---------|---------------|-----------|
| Contexto dessincronizado por tecla física ou clique do mouse do Mac, que o app não vê | médio | médio | Aceitação só por acréscimo (D-04): o pior caso é um sufixo fora de lugar, sem apagar texto; descarte nos gatilhos conhecidos (D-06) |
| Contexto montado sobre senha num campo que não liga a entrada segura | alto | baixo | Sonda P-01; contexto só em memória, nunca no log nem em disco, e limitado a 200 caracteres |
| Sugestão velha aceita depois de nova tecla | médio | médio | Revisão no `pick` e esmaecimento na página (D-05, D-10) |
| Primeira consulta lenta ao motor | baixo | alto | Aquecimento no início da sessão (D-01) |
| Tradutor diverge do sistema em fontes de entrada incomuns | baixo | baixo | Sonda P-02 com as duas fontes do usuário; divergência só piora as sugestões (D-04) |
| Barra ampliada rouba altura das teclas | médio | médio | Sonda P-04; faixa ocultável (RN-14) |
| Mudança na 008 ainda não sincronizada | médio | baixo | Plano sobre o código atual; a 009 não altera o comportamento das teclas nem fecha a T036 |

## 10. Critério de pronto

- [ ] Todas as ações do `actions.md` marcadas `[X]`
- [ ] `cross-check.md` (se executado) sem CRITICAL nem HIGH
- [ ] `regression-watch.md` gerado
- [ ] Re-extração reversa executada e sem regressão vermelha (recomendado, não obrigatório)
- [ ] PM-0 com P-01 a P-04 respondidas e registradas no `onboarding.md`
- [ ] PM-1 com os cenários do `requirements.md` §7 aprovados no iPhone e no Mac
- [ ] `./scripts/test.sh` verde, com a suíte nova do núcleo, e `swift build -c release` sem avisos novos

## 11. Histórico de alterações

| Data | Alteração | Autor |
|------|-----------|-------|
| 2026-09-19 | Versão inicial gerada por `/reversa-plan` | reversa |
