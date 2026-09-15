# Domínio — joystick-AI

> Gerado pelo Detetive em 2026-09-15 · Nível: completo
> Escala: 🟢 CONFIRMADO (código, teste ou evidência de campo) · 🟡 INFERIDO · 🔴 LACUNA
> Fontes: código em `Sources/`, `code-analysis.md`, `data-dictionary.md`, histórico Git (19 commits), ciclos forward em `_reversa_forward/001…003`, adendos em `addenda/` e 43 logs locais em `~/Library/Logs/joystick-ai/` (somente leitura).

## 1. Propósito do domínio

O joystick-AI transforma o DualSense (PS5) em dispositivo de condução de sessões de programação com agentes no macOS: o controle aponta, clica e rola como mouse, dispara atalhos de teclado configuráveis e abre uma paleta que digita comandos no aplicativo em foco. O usuário-alvo é o "programador de sofá", que acompanha agentes na TV a cerca de 3 m e deseja passar a maior parte do tempo sem teclado (`prd.md`). 🟢

O código atual cobre três entregas do ciclo forward: a prova de conceito do ponteiro (001), a paleta de comandos (002) e o editor de atalhos com configuração em arquivo (003). O ditado por voz, previsto no PRD, não tem componente próprio (ver §7). 🟢

## 2. Glossário

| Termo | Definição | Onde vive | Confiança |
|-------|-----------|-----------|-----------|
| **Controle ativo** | O único DualSense cujas entradas produzem efeito: o primeiro conectado; os demais aguardam em fila | `ActiveControllerRegistry` | 🟢 |
| **Controle em fila** | DualSense conectado depois do ativo; assume quando o ativo desconecta | `ActiveControllerRegistry` | 🟢 |
| **Adoção no início** | Tratar como "já conectado" o controle enumerado ou chegado nos 2 primeiros segundos | `StartupAdoption` | 🟢 |
| **Soltura sintética** | `buttonUp` gerado pelo app para cada botão pressionado quando o controle ativo desconecta; marcado `synthetic` | `ControllerReader.disconnect` | 🟢 |
| **Zona morta** | Limite por eixo abaixo do qual o analógico conta como repouso (padrão 0,12) | `Normalization` | 🟢 |
| **Botões de apontamento** | R1, R2 e clique do touchpad: sempre cliques, nunca atalhos nem modificadores | `ShortcutConfig.pointerButtons` | 🟢 |
| **Precisão** | Redução da velocidade (padrão 30%) enquanto só L1 está pressionado | `PointerMotionEngine` | 🟢 |
| **Onset** | Primeira amostra do analógico fora da zona morta, emitida de imediato para medir latência | `PointerMotionEngine` | 🟢 |
| **União de telas** | Conjunto dos retângulos das telas ativas, sem o retângulo envolvente; o cursor não sai dele | `ScreenUnion` | 🟢 |
| **Injeção** | Postagem de eventos sintéticos de mouse, rolagem e teclado pelo `CGEvent` | `EventInjector`, `KeyboardInjector`, `ScrollInjector` | 🟢 |
| **Marca do injetor** | `eventSourceUserData = 0x4A4F5953` ("JOYS"), que distingue eventos do app dos físicos | `EventInjector.marker` | 🟢 |
| **Portão de injeção** | Componente que liga e desliga a injeção conforme a permissão de Acessibilidade, soltando e repetindo o que estiver mantido | `InjectionGate` | 🟢 |
| **Gatilho** | Botão que não é de apontamento nem modificador e recebe uma ação numa camada | `ShortcutConfig` | 🟢 |
| **Modificador** | Botão que, segurado, seleciona uma camada e pode manter teclas ⌃⌥⇧⌘; nunca recebe ação | `ShortcutConfig.modifiers` | 🟢 |
| **Camada** | Mapa gatilho → ação; a `base` vale sem modificador, e cada modificador tem a sua | `ShortcutConfig.layers` | 🟢 |
| **Herança** | Gatilho sem ação própria numa camada de modificador usa a da base; "nenhuma" explícita conta como ação própria | `ShortcutConfig.action(for:layer:)` | 🟢 |
| **Acorde** | Tecla do `KeyCatalog` com zero ou mais modificadores, opcionalmente com repetição | `KeyChord` | 🟢 |
| **Atalho de sistema** | Um dos cinco atalhos do macOS (mesas, Mission Control, janelas do app, próxima janela) cujo acorde é lido das preferências no instante do uso | `SystemShortcut` | 🟢 |
| **Paleta** | Lista flutuante de textos que o controle navega e confirma, digitando no app em foco sem tomar o foco | `PaletteMachine`, `PalettePanel` | 🟢 |
| **Entrada fixa** | Último item da paleta, "Editar atalhos", que abre o editor em vez de digitar | `PaletteMachine` | 🟢 |
| **Último confirmado** | Índice do item confirmado por último, onde a seleção começa na próxima abertura | `PaletteMachine.lastConfirmed` | 🟢 |
| **Configuração vigente** | Mapeamento e paleta em uso; só é substituída por uma leitura ou gravação válida | `ConfigStore.current` | 🟢 |
| **Rascunho** | Cópia editável da configuração no editor; "sujo" quando difere da base | `EditorDraft` | 🟢 |
| **Conflito** | Mudança externa válida do arquivo com rascunho sujo no editor | `EditorViewModel` | 🟢 |
| **Modo de identificação** | Estado do editor em que botões do controle selecionam o gatilho na figura em vez de executar ações | `InputRouter.setIdentifying` | 🟢 |
| **Escala de TV** | Métricas de interface legíveis a 3 m (32 pt de corpo, alvos de 60 pt) | `EditorMetrics` | 🟢 |
| **Tela de alvos** | Instrumento de 20 alvos para medir a taxa de acerto do apontamento, por ambiente (`mesa`, `sofa`) | `TargetSession` | 🟢 |
| **Portão manual (PM)** | Roteiro de verificação no hardware que libera a fase seguinte de uma feature | `_reversa_forward/*/onboarding.md` | 🟢 |
| **Sonda (P-nn)** | Pergunta técnica respondida por experimento no hardware | `_reversa_forward/*/investigation.md` | 🟢 |
| **Emenda (E00n)** | Mudança de escopo ou de solução aprovada durante a execução de uma feature | `_reversa_forward/*/actions.md` | 🟢 |

## 3. Regras de negócio

A numeração RN-nn repete a das specs de origem, com o prefixo da feature. Cada regra traz a evidência no código.

### 3.1 Controle e entrada (001)

| ID | Regra | Evidência | Confiança |
|----|-------|-----------|-----------|
| 001 RN-01 | Há no máximo um controle ativo, o primeiro DualSense conectado; outros modelos são ignorados | `ActiveControllerRegistry.swift:39-68`, `ControllerReader.swift:59-92` | 🟢 |
| 001 RN-02 | Zona morta de 0,12 por eixo, configurável em `pointer.deadzone` | `Normalization.swift:8-11`, `PointerSettings.swift` | 🟢 |
| 001 RN-03 | L2 e R2 contam como pressionados a partir de 0,5, sem histerese | `Normalization.swift:5,18-40` | 🟢 |
| 001 RN-04 | Nenhuma desconexão deixa entrada presa: soltura sintética de botões e de botões de mouse | `ControllerReader.swift:94-116`, `ButtonActions` | 🟢 |
| 001 RN-05 | Touchpad relativo; pousar o dedo não move; só o primeiro dedo conta | `TouchpadTracker.swift:17-47` | 🟢 |
| 001 RN-06 | Touchpad e analógico esquerdo somam deslocamentos | `PointerMotionEngine.swift:89-97` | 🟢 |
| 001 RN-08 | Precisão de 30% com L1 **sem outro botão** | `PointerMotionEngine.swift:52-54` | 🟢 |
| 001 RN-09 | Duplo clique em até 400 ms e 4 pt | `ClickStateMachine.swift:21,83-89` | 🟢 |
| 001 RN-10 | Cursor dentro da união das telas, inclusive após desconectar uma | `ScreenUnion.swift`, `DisplayMonitor.swift:44-70` | 🟢 |
| 001 RN-11 | Mapeamento fixo do ponteiro. **Alterado no PM-3:** R1 e touchpad → esquerdo, R2 → direito (a spec dizia o inverso) | `ClickStateMachine.swift:18-19`; 003 RN-05 incorpora a mudança | 🟢 |
| 001 RN-12 | Sem rede; entradas só no log e nos resultados locais, sem coordenadas | Nenhum uso de rede em `Sources/`; `LogEventCatalog.swift:33-333` | 🟢 |

### 3.2 Paleta (002)

| ID | Regra | Evidência | Confiança |
|----|-------|-----------|-----------|
| 002 RN-01 | PS abre a paleta na base; com modificador, vale a herança da camada. Na 003, PS vira ação `openPalette` configurável | `ShortcutDefaults.swift`, `ShortcutMapper.swift:175-188` | 🟢 |
| 002 RN-02 | A paleta nunca toma o foco; o texto vai ao app em foco na confirmação | `PalettePanel.swift:12-30` | 🟢 |
| 002 RN-03 | Paleta aberta: ↑/↓ navegam, ✕ confirma, ○/PS fecham; atalhos suspensos, ponteiro e cliques seguem | `InputRouter.swift:38-69`, `CommandPalette.swift:86-178` | 🟢 |
| 002 RN-04 | Abrir a paleta solta teclas e modificadores mantidos e para a repetição | `ShortcutActions.swift:98-100` | 🟢 |
| 002 RN-06 | A paleta só digita; nenhum item executa programa | `PaletteActions.swift:99-126` | 🟢 |
| 002 RN-07 | Log com índice e motivo, nunca o texto | `LogEventCatalog` (`palette.*`) | 🟢 |
| 002 E001 | Nenhum item padrão envia Enter, para permitir argumentos | `CommandPalette.swift:37-57` | 🟢 |

### 3.3 Atalhos, configuração e editor (003)

| ID | Regra | Evidência | Confiança |
|----|-------|-----------|-----------|
| 003 RN-01 | Ação decidida no pressionar e mantida até soltar, mesmo que o modificador solte antes | `ShortcutMapper.swift:175-202` | 🟢 |
| 003 RN-02 | Herança da base; "nenhuma" é ação própria; botões de apontamento não são modificadores | `ShortcutConfig.swift:60-65`, `ShortcutConfigValidation.swift:12-62` | 🟢 |
| 003 RN-03 | Vários modificadores: vale a camada do segurado há mais tempo, com herança só da base | `ShortcutMapper.swift:161` | 🟢 |
| 003 RN-04 | Modificador não recebe ação; pode manter teclas ⌃⌥⇧⌘ | `ShortcutConfigValidation` (`modifierHasAction`), `ShortcutMapper.swift:167-170` | 🟢 |
| 003 RN-05 | R1 e touchpad → esquerdo, R2 → direito em qualquer camada; L1 reduz a velocidade mesmo como modificador | `ClickStateMachine.swift:18-19`, `PointerMotionEngine.swift:52-54` | 🟢 |
| 003 RN-06 | Seis tipos de ação: acorde (repetição opcional 400/50 ms), atalho de sistema, texto, abrir paleta, nenhuma, herdar | `TriggerAction`, `KeyRepeat.swift:7-8`, `ActionPanel.swift` | 🟢 |
| 003 RN-07 | Cinco atalhos de sistema; o acorde vem de `AppleSymbolicHotKeys` no momento do uso | `ShortcutMapper.swift:38-103`, `ShortcutActions.swift:101-107` | 🟢 |
| 003 RN-08 | Configuração inválida nunca substitui a vigente; mapeamento e paleta validados juntos | `ConfigLoader.swift:97-110`, `ConfigStore.swift:67-94` | 🟢 |
| 003 RN-09 | Aplicar configuração solta teclas e para a repetição | `ShortcutActions.swift:50-55` | 🟢 |
| 003 RN-10 | Arquivo só é criado ao salvar; a gravação preserva `pointer`; `pointer` só é lido no início; remoção mantém a vigente | `ConfigLoader.swift:52-55`, `ConfigWriter.swift:24-61`, `AppDelegate.swift:50`, `ConfigStore.swift` | 🟢 |
| 003 RN-11 | Padrão reproduz o protótipo, com PS abrindo a paleta e 17 itens sem Enter | `ShortcutDefaults.swift:8-52` | 🟢 |
| 003 RN-12 | Paleta com 1 a 50 itens; texto de 1 a 1.000 caracteres em uma linha; rótulo até 80 | `ShortcutConfigValidation.swift:12-62`, `EditorDraft.swift:29-41` | 🟢 |
| 003 RN-13 | Ações de texto só digitam | `KeyboardInjector.swift:79-94` | 🟢 |
| 003 RN-14 | Log sem textos, rótulos nem acordes | `LogEventCatalog.swift`; problemas citam caminho e regra, nunca o valor | 🟢 |
| 003 RN-15 | Gravação de acorde só com o campo ativo e a janela em foco, descartando eventos do injetor | `KeyCaptureField.swift:12-89` | 🟢 |
| 003 RN-16 | Com o editor aberto, a configuração vigente continua ativa; no modo de identificação, botões não de apontamento só identificam | `InputRouter.swift:38-69` | 🟢 |

## 4. Regras implícitas (só no código)

Regras que não constam como RN nas specs, mas o código impõe.

| # | Regra | Evidência | Confiança |
|---|-------|-----------|-----------|
| RI-01 | Instância única por `bundleIdentifier`; a segunda abertura encerra-se | `AppDelegate.swift:32-35,192-198` | 🟢 |
| RI-02 | O leitor do controle só inicia depois de todos os consumidores, para nenhum evento chegar a um destino inexistente | `AppDelegate.swift:133-134` | 🟢 |
| RI-03 | A permissão de Acessibilidade é consultada por `AXIsProcessTrusted()`, porque `CGPreflightPostEventAccess()` não reflete revogação no processo vivo (P-08) | `PermissionMonitor.swift:39-48`; `validation-report.md` 001:139 | 🟢 |
| RI-04 | Suspender a injeção solta tudo **antes** de desligar o injetor e guarda as solturas para repeti-las ao retomar | `InjectionGate.swift:41-62` | 🟢 |
| RI-05 | Posição do cursor: a posição sintética vale enquanto a leitura do sistema for uma das 32 últimas postadas e houver menos de 100 ms; o mouse físico retoma o controle em qualquer outro caso | `EventInjector.swift:16-62` | 🟢 |
| RI-06 | Setas injetadas levam `maskNumericPad` e `maskSecondaryFn`, como as físicas, senão Mission Control e mesas não respondem | `KeyboardInjector.swift:110-111` | 🟢 |
| RI-07 | Texto é injetado por unidade UTF-16 com `unicodeString`, independente do layout do teclado | `KeyboardInjector.swift:79-94` | 🟢 |
| RI-08 | O PS é lido do relatório HID bruto, porque o macOS o retém antes do `GameController` | `DualSenseReport.swift:7-16`, `ExtendedReportActivator` | 🟢 |
| RI-09 | Por Bluetooth, ler o relatório de recurso `0x05` é o que libera o touchpad (modo estendido) | `ExtendedReportActivator.swift:57-65` | 🟢 |
| RI-10 | A fase do toque é inferida pela transição de e para (0, 0), porque `touchpads` vem vazio no DualSense (P-01 da 001) | `AxisTouchReader.swift:22-54`; `validation-report.md` 001:132 | 🟢 |
| RI-11 | Amostras do touchpad em que só um eixo muda para ou de zero exato são descartadas, por serem estado intermediário do framework | `TouchpadTracker.swift:55-57` | 🟢 |
| RI-12 | O `dt` do temporizador de 120 Hz é limitado a 50 ms para evitar saltos após travamentos | `MotionLoop.swift:72-84` | 🟢 |
| RI-13 | Reconfigurações de tela são agregadas em 200 ms, e o cursor fora da nova união é reposicionado | `DisplayMonitor.swift:44-70` | 🟢 |
| RI-14 | Releitura do arquivo agregada em 150 ms; bytes idênticos aos últimos lidos ou gravados não reaplicam | `ConfigWatcher.swift`, `ConfigStore.swift:67-94` | 🟢 |
| RI-15 | Arquivo acima de 1 MiB é recusado na leitura | `ConfigLoader.swift:56-70` | 🟢 |
| RI-16 | Gravação atravessa até 16 níveis de link simbólico e grava no destino, por troca atômica | `ConfigWriter.swift:24-61` | 🟢 |
| RI-17 | Codificação determinística: o mesmo documento gera os mesmos bytes (chaves ordenadas, campos opcionais estáveis) | `ConfigDocument.swift:3-79` | 🟢 |
| RI-18 | Aplicar configuração nova: primeiro a paleta, depois os atalhos; botões segurados na troca ficam ignorados até soltar | `AppDelegate.swift:80-86`, `ShortcutActions.swift:50-55` | 🟢 |
| RI-19 | Configuração nova zera o último confirmado da paleta | `PaletteActions.swift:59-65` | 🟢 |
| RI-20 | A paleta fecha sozinha após 60 s sem entrada do controle | `PaletteActions.swift:11-12,145-157` | 🟢 |
| RI-21 | Com a tela de alvos aberta, a paleta não abre | `PaletteActions.swift:43-48` | 🟢 |
| RI-22 | Só cliques com a marca do injetor contam na tela de alvos | `TargetSession.swift:72-79` | 🟢 |
| RI-23 | No macOS 26 o editor abre em nível flutuante e recebe clique sintético na barra de título, porque a ativação pedida a partir do controle é recusada (E003) | `EditorWindowController.swift:55-90` | 🟢 |
| RI-24 | Ao fechar o editor, o foco volta ao aplicativo que estava à frente | `EditorWindowController.swift:167-179` | 🟢 |
| RI-25 | O menu principal oculto só tem "Editar", para colar e o ditado do Raycast chegarem aos campos | `EditMenu.swift:3-37` | 🟢 |
| RI-26 | Ao mudar o tipo de ação, o acorde aproveitado começa sem repetição (E005) | `ActionPanel.swift:181-199` | 🟢 |
| RI-27 | Desmarcar um modificador devolve as "nenhuma" que a marcação retirou (E004) | `EditorDraft.swift:117-143` | 🟢 |
| RI-28 | Acima de 50 MiB escritos no log, eventos `debug` são suspensos | `DiagnosticLog.swift:10,102-106` | 🟢 |
| RI-29 | Latências aprovadas se p95 de processamento ≤ 5 ms e de entrada ao movimento ≤ 20 ms | `LatencyCommand.swift:6-39` | 🟢 |

## 5. Divergências entre specs e código

| # | Spec | Código | Situação | Confiança |
|---|------|--------|----------|-----------|
| DV-01 | 001 RN-11 e D-06: R2 e touchpad → esquerdo, R1 → direito | R1 e touchpad → esquerdo, R2 → direito | Mudança pedida pelo usuário no PM-3 e incorporada em 003 RN-05; a 001 não foi reescrita | 🟢 |
| DV-02 | 001 D-15: consulta por `CGPreflightPostEventAccess()` | `AXIsProcessTrusted()` | Corrigido após a P-08 | 🟢 |
| DV-03 | 001 RN-08: precisão "com L1 sem outro botão" | `pressed == [.l1]` | Coerente, mas desliga a precisão durante arraste com L1+R1; a spec não trata o caso | 🟡 |
| DV-04 | 001 RN-01: só o controle ativo produz efeito | PS do HID vai ao ativo, venha de qual controle vier | Violação em cenário com dois controles | 🟡 |
| DV-05 | 003 RN-08: configuração inválida nunca é aplicada | "Copiar e gravar" grava sem reverificar `canSave` | Violação possível se o rascunho mudar enquanto a faixa está visível | 🟡 |
| DV-06 | 003 RN-07: acorde do atalho de sistema lido das preferências | Atalho **desativado** nas preferências posta o acorde padrão | A spec não trata desativação | 🟡 |
| DV-07 | 002 D-14 e 003 D-27: `palette.closed` cobre todos os fechamentos | Confirmação e entrada fixa fecham sem `palette.closed`; nos logs, 74 aberturas para 19 fechamentos e 24 confirmações | Coerente com o desenho (confirmação tem evento próprio), mas a abertura do editor pela paleta não deixa rastro de fechamento | 🟡 |
| DV-08 | `ButtonReader.swift:7`: options/create "a confirmar" | Confirmado no hardware (P-05) | Comentário desatualizado | 🟢 |
| DV-09 | `prd.md`: ditado de prompts por botão do controle | Nenhum componente; R3 dispara ⌘M do transcritor do Raycast | Registrado no adendo 001; destino do componente não decidido | 🔴 |
| DV-10 | 003 D-19: janela mínima 1.100 × 720 pt, texto 24/30 pt | 1.400 × 800 pt, 32/40/60 pt | Ajuste do PM-1a, registrado nas rodadas da 003 | 🟢 |

## 6. Arqueologia Git

O repositório tem 19 commits entre 2026-09-14 e 2026-09-15, todos do mesmo autor, sem branches, merges nem reverts. A história segue o ciclo do Reversa: specs greenfield, então para cada feature um commit `feat` com o código e um ou mais commits `docs` com o ciclo forward e o adendo. 🟢

| Data | Commit | Marco | Decisões reveladas |
|------|--------|-------|--------------------|
| 09-14 | `330c1a0`, `baa7b42` | Instalação do Reversa | Configuração pessoal fora do Git |
| 09-14 | `8fab576` | Specs greenfield (`/reversa-new`) | Cinco componentes: app-shell, controller-input, pointer-control, action-mapping, voice-dictation |
| 09-14 | `885ff79` | **feat 001** PoC do ponteiro | GameController em segundo plano, PS e touchpad por HID bruto, 120 Hz, log sem coordenadas; no PM-3: inversão R1/R2, `AXIsProcessTrusted`, protótipo de atalhos (EXP-01) |
| 09-14 | `9244353`, `27c66fe` | Ciclo forward e adendo 001 | Assinatura local autoassinada (caminho B) |
| 09-14 | `6b40614`, `717608b` | Testes do microfone e do ditado | Microfone do DualSense só por USB; o Raycast escolhe o microfone pela própria lista |
| 09-14 | `181f3fa` | **feat 002** paleta | Painel não ativador, 17 comandos, fechamento automático |
| 09-14 | `b525aca`, `515b7dc`, `996556f` | Emenda E001 e adendo 002 | Paleta sem Enter |
| 09-14 | `d80e14e` | Preparação da 003 | Ícone na barra de menus, entrada fixa na paleta, catálogo de teclas |
| 09-15 | `3ecda0d`, `4f40c1a`, `6c4be66` | PM-1a da 003 | E002 revogada, E003 (janela flutuante e clique de ativação), menu Editar, escala de TV maior |
| 09-15 | `e4b65f2` | **feat 003** configuração e editor completo | Arquivo com camadas, validação conjunta, releitura automática, fusão preservando seções; E004 e E005 |
| 09-15 | `29b7ac5` | Adendo 003 | Portões aprovados |

**Padrões observados:**

- 🟢 As correções nascem dos portões manuais, não de commits `fix`: P-08, inversão R1/R2, E002→E003, E004 e E005 entraram dentro dos commits `feat`, com a justificativa nos `actions.md`.
- 🟢 Uma única revogação de solução (E002) está documentada, mas não aparece como `revert` no Git, porque ocorreu antes do commit.
- 🟡 O ritmo de dois dias para três features, com portões no hardware, indica PoC de uso pessoal e não produto distribuído; isso explica a assinatura local e a ausência de CI.

## 7. Análise dos logs locais

Leitura, sem alteração, de 43 sessões (5,8 MB) em `~/Library/Logs/joystick-ai/`. 🟢

| Indicador | Valor | Leitura |
|-----------|-------|---------|
| Níveis | 27.739 `debug`, 940 `info`, 25 `warn`, 9 `error` | Uso intenso com `--debug` durante os portões |
| Eventos mais frequentes | `pointer.posted` 20.287, `input.button` 6.290, `input.touch` 551, `shortcut.triggered` 287 | Ponteiro e atalhos em uso real |
| Paleta | 74 aberturas, 24 confirmações, 19 fechamentos | Parte das aberturas termina no editor ou no encerramento do app (DV-07) |
| `editor.activation_failed` | 14, todas em sessões até `poc-20260915-100331` | Nenhuma após a E003 (rodada 6, 10:10): a emenda resolveu 🟢 |
| `shortcuts.invalid` | 5 `syntax`, 2 `pointerButtonNotAllowed` | Amostras de teste de `scripts/config-samples/` 🟡 |
| `shortcuts.save_failed` | 1, "Permission denied" em `~/.config/joystick-ai/config.json` | Provável teste de arquivo sem permissão; a mensagem inclui o caminho com o nome do usuário 🟡 |
| `permissions.guidance` / `injection_suspended` | 3 / 2 | Revogação testada no PM-3 |
| `targets.*` | 1 `invalid_args` (`--env praia`); nenhum arquivo em `target-runs/` | A tela de alvos nunca completou uma rodada; o bloco de precisão da 001 segue pendente 🟢 |

## 8. Lacunas

| # | Lacuna | Por que importa |
|---|--------|-----------------|
| 🟢 L-01 | O componente `voice-dictation` segue planejado ou foi substituído pelo atalho do Raycast em R3? Resposta: substituído. | Define se a spec `sdd/voice-dictation.md` continua viva e se o PRD precisa de adendo |
| 🔴 L-02 | As divergências DV-04 (PS de controle em fila), DV-05 (gravação sem revalidar) e DV-06 (atalho de sistema desativado) são aceitas ou são defeitos a corrigir? | Decide se entram nas specs como comportamento ou como débito |
| 🔴 L-03 | A tela de alvos e as medições pendentes do PM-3 (latência, CPU em movimento, 100 ciclos) ainda serão feitas? | O risco de precisão do PRD continua sem número |

> Resoluções do Revisor em 2026-09-15 (`questions.md`): L-01 fechada, com o componente `voice-dictation` superado pelo atalho R3 → ⌘M do Raycast; L-02 decidida, com DV-04 e DV-06 aceitas como comportamento e DV-05 classificada como defeito a corrigir; L-03 respondida, com as medições do PM-3 ainda planejadas.
