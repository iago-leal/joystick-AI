# Roadmap: Paleta de comandos pelo controle

> Identificador: `002-paleta-comandos`
> Data: `2026-09-14`
> Requirements: `_reversa_forward/002-paleta-comandos/requirements.md`
> Confidência: 🟢 CONFIRMADO, 🟡 INFERIDO, 🔴 LACUNA

> **Nota de confidência:** recebem 🟢 as decisões apoiadas no código entregue pela feature 001, inspecionado em 2026-09-14, ou em decisão do usuário na sessão de esclarecimentos. Recebem 🟡 as que dependem de comportamento do macOS ou do Claude Code ainda não observado neste projeto. Recebem 🔴 as que dependem de uma sonda da Fase 0.

## 1. Resumo da abordagem

A paleta é um delta pequeno sobre o protótipo de atalhos da feature 001. A lógica fica em `JoystickCore`, como máquina de estados pura e testável: a lista fixa de 17 itens, a seleção circular, a confirmação e o fechamento com motivo. O `ShortcutMapper` ganha a ação `openPalette` para PS na camada base, o que dá RN-01 de graça, porque L1 e L2 já repassam à base os botões sem ação e Options não repassa. No app, um `PaletteActions` na fila `input` executa a máquina, repete ↑ e ↓ com os mesmos tempos das setas, digita o texto pelo `KeyboardInjector` já existente e publica o estado na main thread. Lá, um painel sem borda e não ativador desenha a lista. O `InputRouter` desvia os botões para a paleta enquanto ela está aberta, mantendo cliques e movimento. Uma sonda inicial decide o intervalo entre o texto e o Enter no Claude Code.

## 2. Princípios aplicados

Não existe `.reversa/principles.md`; não há princípio a respeitar nem conflito a registrar. As restrições equivalentes vêm das specs e da feature 001:

| Restrição | Como a feature se relaciona | Status |
|-----------|------------------------------|--------|
| Lógica pura em `JoystickCore`, só `Foundation` (001 D-03) | Lista, seleção e transições da paleta ficam em `JoystickCore/Palette`, com testes. | respeita |
| `JoystickAIPoC` em modo Swift 5, isolamento por filas explícitas (001 D-22) | Estado da paleta só na fila `input`; painel só na main thread; a ponte é `DispatchQueue.main.async`. | respeita |
| Log sem teclas nem conteúdo (`action-mapping` §12, 001 RN-12) | Eventos da paleta levam índice e motivo, nunca texto. | respeita |
| Regra de escrita do Reversa (`CLAUDE.md`) | `.reversa/reversa-config.json` está com `allowLegacyEdits: true` e `allowedPaths` vazio, isto é, liberação irrestrita; a 001 (D-21) usava lista restrita. O `/reversa-coding` deve avisar. | observação |

## 3. Decisões técnicas

| ID | Decisão | Justificativa | Alternativas descartadas | Confidência |
|----|---------|----------------|--------------------------|-------------|
| D-01 | Nova máquina `PaletteMachine` em `Sources/JoystickCore/Palette/CommandPalette.swift`, com `items` fixos (`PaletteItem { text, pressEnter }`), `isOpen`, `selection`, `lastConfirmed`; entradas `open()`, `press(ButtonID)`, `release(ButtonID)`, `repeatTick()`, `close(reason)`; saídas como lista de `PaletteEffect` (`render`, `startRepeat`, `stopRepeat`, `confirm(index, item)`, `closed(reason)`). | Mesmo padrão do `ShortcutMapper` e do `ClickStateMachine`: estado puro que devolve ações, testável sem AppKit. | Estado dentro do painel AppKit (não testável); estado na main thread (exigiria sincronizar com a fila `input`). | 🟢 |
| D-02 | `ShortcutAction` ganha `.openPalette`; `ShortcutMapper.press(.ps)` na camada base devolve `[.openPalette]`, sem entrada em `activeChords`. | Com L1 ou L2 segurados o `switch` já cai na camada base; com Options há `default: return []`. RN-01 sai sem regra nova. | Tratar PS no `InputRouter` antes do mapeador (duplicaria a lógica de camadas). | 🟢 |
| D-03 | `InputRouter.handle`: botões vão sempre a `ButtonActions` (cliques); se a paleta estiver aberta, vão a `PaletteActions` e não a `ShortcutActions`; senão, a `ShortcutActions`. Eixos e toque seguem para `MotionLoop` e marcam atividade na paleta. `controllerDisconnected` fecha a paleta. | Cumpre RN-03 e RF-06 com um único ponto de decisão, na fila `input`, onde a ordem dos eventos é garantida. | Filtrar dentro do `ShortcutMapper` (misturaria dois estados); monitor global de teclado (a paleta não recebe teclado). | 🟢 |
| D-04 | Ao executar `.openPalette`, `ShortcutActions` chama `releaseAll()` antes de abrir (RN-04). Botões soltos com a paleta aberta são ignorados pela paleta, exceto ↑ e ↓, que param a repetição. Um modificador pressionado com a paleta aberta e ainda segurado após o fechamento não ativa a camada até ser pressionado de novo. | O `releaseAll` já limpa `held`, `activeChords` e o Command de Options, e o `release` do mapeador ignora botões fora de `held`; nenhuma tecla fica presa. | Reinjetar o estado dos botões segurados no mapeador ao fechar (complexidade sem ganho perceptível). | 🟢 |
| D-05 | Um único `KeyboardInjector`, criado no `AppDelegate` e compartilhado por `ShortcutActions` e `PaletteActions`. | A contagem de modificadores (`modifierCounts`) precisa ser uma só; hoje o injetor nasce dentro da chamada que cria `ShortcutActions`. | Dois injetores (contagens divergentes, risco de Command preso). | 🟢 |
| D-06 | Confirmação: `keyboard.type(text, pressEnter: false)` e, se o item tiver Enter, `chordDown`/`chordUp` de Return agendados na fila `input` após `enterDelayMs`. Padrão definido pela sonda P-01; ajustável sem recompilar por `--palette-enter-delay-ms <0 a 500>` em `LaunchArguments`. | O Claude Code mostra sugestões ao digitar `/`; um Enter imediato pode ser tratado de outra forma. A sonda e o argumento evitam recompilar para calibrar. | Enter imediato fixo (já funciona com `CONTINUAR`, mas não foi observado com comandos com barra); atraso fixo sem medição. | 🔴 |
| D-07 | Repetição de ↑ e ↓ com 400 ms e depois a cada 50 ms, por `DispatchSourceTimer` na fila `input`. As constantes saem de `ShortcutActions` para `KeyRepeat` em `Sources/JoystickCore/Shortcuts/KeyRepeat.swift`, usadas pelos dois. | Mesmo tempo das setas (`action-mapping` RF-10), com uma única fonte. | Constantes duplicadas. | 🟢 |
| D-08 | Painel `PalettePanel: NSPanel` em `Sources/JoystickAIPoC/Palette/PalettePanel.swift`: `styleMask [.borderless, .nonactivatingPanel]`, `canBecomeKey`/`canBecomeMain` falsos, `level = .statusBar`, `collectionBehavior [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]`, `ignoresMouseEvents = true`, `hidesOnDeactivate = false`; exibido com `orderFrontRegardless()` e oculto com `orderOut`. Criado uma vez no início, oculto. | Não ativador e sem `key`, não tira o foco (RN-02); ignorar o mouse deixa os cliques passarem (RF-06); criado antecipadamente, aparece dentro de 150 ms. `level` e `collectionBehavior` repetem a `TargetWindow`, que já aparece sobre outras mesas. | Janela comum ativando o app (rouba o foco); SwiftUI com `NSHostingView` (sem ganho para uma lista fixa desenhada). | 🟡 |
| D-09 | Desenho em AppKit puro (`PaletteView: NSView`, `isFlipped`), no padrão de `TargetView`: fundo escuro fixo quase opaco, cantos arredondados, texto de 26 pt em fonte monoespaçada, linha de 40 pt, item selecionado com faixa de cor de destaque e marcador "▶" à esquerda. Até 17 linhas; se a área visível da tela não comportar, mostra o máximo de linhas e desloca a janela de itens para manter a seleção visível. | Legível a 3 m com cor e forma distintas (RNF de legibilidade); 17 × 40 pt + margens ≈ 740 pt, abaixo de 900 pt. Tema fixo escuro porque a paleta aparece sobre qualquer fundo. | Seguir o tema do sistema (contraste imprevisível sobre o terminal); fonte proporcional (os comandos alinham melhor em monoespaçada). | 🟡 |
| D-10 | Posição: centro da `visibleFrame` da `NSScreen` que contém `NSEvent.mouseLocation`, calculada a cada abertura. | RF-01 pede a tela do cursor; a `visibleFrame` evita a barra de menus e o Dock. | Tela principal fixa (errada com a TV como segunda tela). | 🟢 |
| D-11 | Estado publicado da fila `input` para a main thread como `PaletteSnapshot { isOpen, selection }` imutável; o painel só redesenha a partir dele. | Mantém o isolamento de 001 D-22, sem acesso cruzado. | Painel lendo a máquina diretamente (corrida entre filas). | 🟢 |
| D-12 | Fechamento automático: `InjectionGate`, na suspensão e já na fila `input`, chama `palette.close(.injectionSuspended)`; `controllerDisconnected` fecha com `.disconnected`; um temporizador de 1 s, ativo só com a paleta aberta, fecha com `.idle` quando `now − lastInputNs ≥ 60 s`, sendo `lastInputNs` atualizado por qualquer evento de botão, eixo ou toque. | `InjectionGate.onSuspended` já é usado pela tela de alvos e aceita um só observador; a chamada direta evita disputa. Guardar o instante evita reprogramar o temporizador a cada amostra de eixo. | Reprogramar o temporizador a cada evento (custo nas amostras de 120 Hz); vários observadores em `onSuspended` (mudança maior). | 🟢 |
| D-13 | Durante uma sessão da tela de alvos (`--targets`), `openPalette` é ignorado. | ○ também encerra a tela de alvos pelo `onButtonDown`; a paleta aberta sobre a medição comprometeria a rodada. | Permitir e documentar (risco de rodada inválida). | 🟢 |
| D-14 | Eventos de log novos em `LogEventCatalog`, nível `info`: `palette.opened { selection }`, `palette.confirmed { index, enter }`, `palette.closed { reason: circle \| ps \| disconnected \| injection_suspended \| idle }`; índices a partir de 1. `palette.blocked { reason: targets }` quando D-13 atuar; `palette.invalid_args { message }`, nível `warn`, para argumento inválido. Contratos em `interfaces/diagnostic-log.md` e `interfaces/launch-arguments.md`. | Observabilidade pedida no RNF, com privacidade de RN-07; `enter` é booleano e não revela conteúdo. | Registrar o rótulo (viola RN-07). | 🟢 |
| D-15 | Testes em `JoystickCoreTests`: `CommandPaletteTests` (lista, ordem, uma linha, Enter só nos itens sem espaço final; abertura na última confirmada; circularidade; repetição; confirmação; motivos de fechamento; botões ignorados), acréscimos em `ShortcutMapperTests` (PS na base, com L1, com L2 e sem efeito com Options; o teste `botoesDoPonteiroNaoGeramTeclas` perde `.ps`), `LogEventCatalogTests` (novos eventos sem texto) e `LaunchArgumentsTests` (`--palette-enter-delay-ms`). O comportamento do painel é verificado no portão manual. | Cobre RF-02 a RF-05, RF-08 e RN-01 automaticamente; foco, legibilidade e sobreposição só se verificam na tela. | Testes de interface automatizados (sem Xcode na máquina, 001 D-02). | 🟢 |

## 4. Premissas

Não há `[DÚVIDA]` pendente no `requirements.md`. As incertezas técnicas viram sondas da Fase 0, e não premissas:

| Sonda | Pergunta | Decisão que depende dela |
|-------|----------|--------------------------|
| P-01 | Com `/reversa-forward` digitado caractere a caractere e Enter a 0, 50 e 150 ms, o Claude Code executa o comando digitado, no Terminal e no terminal integrado do VS Code? E `/clear`, `/compact` e `/resume`? | D-06: valor padrão de `enterDelayMs`. |
| P-02 | Um painel não ativador em `.statusBar` aparece sobre um app em tela cheia e na mesa ativa, sem tirar o foco do terminal? | D-08: `level` e `collectionBehavior`. |

## 5. Delta arquitetural

Não existe `_reversa_sdd/architecture.md`; os componentes são citados pela spec SDD e pelo código entregue na 001.

| Componente | Arquivo de origem no legado | Tipo de mudança | Resumo |
|------------|------------------------------|-----------------|--------|
| Paleta de comandos (`PaletteMachine`, `PaletteItem`) | `_reversa_sdd/sdd/action-mapping.md#8. Design e Interface` | componente-novo | Lista fixa de 17 itens e máquina de estados em `JoystickCore/Palette`. |
| `ShortcutMapper` | `_reversa_sdd/addenda/001-poc-entrada-ponteiro.md#Impacto por artefato da extração` (protótipo EXP-01) | regra-alterada | PS na camada base devolve `.openPalette`. |
| `ShortcutActions` | idem | regra-alterada | Executa `.openPalette` soltando antes as teclas; usa `KeyRepeat` e o injetor compartilhado. |
| `InputRouter` | idem | regra-alterada | Desvia botões para a paleta aberta; marca atividade; fecha na desconexão. |
| `PaletteActions`, `PalettePanel`, `PaletteView` | `_reversa_sdd/sdd/app-shell.md#8. Design e Interface` | componente-novo | Execução na fila `input` e painel não ativador na main thread. |
| `InjectionGate` | `_reversa_sdd/sdd/app-shell.md#11. Edge Cases e Tratamento de Erros` | regra-alterada | Fecha a paleta ao suspender a injeção. |
| `AppDelegate` | `_reversa_sdd/sdd/app-shell.md#6.1 Requisitos Principais` | regra-alterada | Cria o injetor compartilhado, a paleta e o painel; bloqueia a paleta com a tela de alvos aberta. |
| `LaunchArguments` | `_reversa_forward/001-poc-entrada-ponteiro/interfaces/target-run-result.md` (argumentos de abertura) | contrato-alterado | Novo `--palette-enter-delay-ms`. |
| Log de diagnóstico (`LogEventCatalog`) | `_reversa_forward/001-poc-entrada-ponteiro/interfaces/diagnostic-log.md` | contrato-alterado | Eventos `palette.*`. |

## 6. Delta no modelo de dados

- Resumo das mudanças: nenhum dado persistido. Entram em memória a lista fixa de itens, o estado da paleta e o último item confirmado, que se perde ao encerrar o app; `ShortcutAction` ganha um caso; o arquivo de configuração não muda.
- Detalhe completo em: `_reversa_forward/002-paleta-comandos/data-delta.md`

## 7. Delta de contratos externos

| Contrato | Tipo | Arquivo de detalhe |
|----------|------|--------------------|
| Log de diagnóstico | arquivo (JSON Lines) | `_reversa_forward/002-paleta-comandos/interfaces/diagnostic-log.md` |
| Argumentos de abertura do app | linha de comando | `_reversa_forward/002-paleta-comandos/interfaces/launch-arguments.md` |

## 8. Plano de migração

Sem migração de dados. A execução segue em fases que falham cedo:

1. **Fase 0, sondas.** P-01 com um utilitário descartável na pasta de rascunho da sessão, fora do repositório, que digita pelo mesmo método do `KeyboardInjector` após 5 s, com o terminal em foco; P-02 com um painel mínimo pelo mesmo caminho. Resultados registrados em `actions.md`. Se P-01 mostrar que nenhum atraso de até 500 ms funciona, parar e voltar ao `/reversa-clarify`.
2. **Fase 1, núcleo.** `KeyRepeat`, `PaletteItem` e `PaletteMachine`, `.openPalette` no `ShortcutMapper`, eventos no `LogEventCatalog` e `--palette-enter-delay-ms`, com os testes de D-15. `scripts/test.sh` verde.
3. **Fase 2, integração.** Injetor compartilhado, `PaletteActions`, desvio no `InputRouter`, fechamento pelo `InjectionGate` e pela desconexão, bloqueio com a tela de alvos e `PalettePanel`/`PaletteView`.
4. **Portão manual PM-1.** Roteiro do `onboarding.md`, com os cenários da seção 7 do `requirements.md` e a verificação de que os atalhos do protótipo não mudaram (RF-07).

Reversão: a entrega é um conjunto de commits; voltar ao commit anterior restaura o protótipo sem paleta.

## 9. Riscos e mitigações

| Risco | Impacto | Probabilidade | Mitigação |
|-------|---------|---------------|-----------|
| O Claude Code trata o Enter logo após `/comando` como escolha de outra sugestão ou trata a digitação rápida como colagem | alto | média | Sonda P-01 antes do código; `enterDelayMs` ajustável sem recompilar (D-06). |
| O painel não aparece sobre apps em tela cheia ou em outra mesa | médio | baixa | `collectionBehavior` da `TargetWindow`, que já funciona; sonda P-02. |
| O painel rouba o foco em alguma versão do macOS | alto | baixa | `.nonactivatingPanel`, `canBecomeKey` falso e política `.accessory`; verificado em P-02 e no PM-1. |
| O botão PS abre o Launchpad ou o app de jogos em vez da paleta | médio | baixa | Pré-requisito da 001 no `onboarding.md` ("Pressione o Botão de Início para abrir" em "Nenhum"). |
| Confirmação acidental de `/clear` | médio | baixa | Item perto do fim da lista; observar no uso real (`requirements.md` §10). |
| Modificador pressionado com a paleta aberta não vale após o fechamento | baixo | média | Comportamento aceito e documentado (D-04); pressionar de novo resolve. |
| Latência de abertura acima de 150 ms na main thread ocupada | baixo | baixa | Painel criado no início (D-08); medição pelo `palette.opened` contra o `input.button` de PS com `--debug`. |

## 10. Critério de pronto

- [ ] Sondas P-01 e P-02 registradas, com o valor padrão de `enterDelayMs` fixado
- [ ] Todas as ações do `actions.md` marcadas `[X]`
- [ ] `scripts/test.sh` verde, incluindo os testes novos de D-15
- [ ] Portão PM-1 executado: cenários da seção 7 do `requirements.md` aprovados no Terminal e no terminal integrado do VS Code
- [ ] Atalhos do protótipo sem regressão (RF-07)
- [ ] `cross-check.md` (se executado) sem CRITICAL nem HIGH
- [ ] `regression-watch.md` gerado
- [ ] Re-extração reversa executada e sem regressão vermelha (recomendado, não obrigatório)

## 11. Histórico de alterações

| Data | Alteração | Autor |
|------|-----------|-------|
| 2026-09-14 | Versão inicial gerada por `/reversa-plan` | reversa |
