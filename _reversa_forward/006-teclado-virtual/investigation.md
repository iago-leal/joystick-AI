# Investigation: Teclado virtual chamado pelo controle

> Identificador: `006-teclado-virtual`
> Data: `2026-09-16`
> Roadmap: `_reversa_forward/006-teclado-virtual/roadmap.md`

## 1. Pergunta de fundo

Como exibir e ocultar, com um botão do DualSense, um teclado virtual fornecido pelo macOS, digitando nele com o ponteiro do controle, sem que o app desenhe teclado, escreva preferências do sistema ou peça permissão nova?

## 2. Estado de partida, observado em 2026-09-16

- **Sistema:** macOS 26.6.2 (build 25G83).
- **Preferências de atalhos** (`defaults read com.apple.symbolichotkeys AppleSymbolicHotKeys`, só leitura): a entrada `162` está ativa, com `parameters = (65535, 96, 1572864)`. `96` é `0x60`, a tecla F5 em `KeyCatalog.function`; `1572864` é `0x180000`, soma de `0x100000` (⌘) e `0x80000` (⌥) na conversão de `SystemShortcut.chords(fromSymbolicHotKeys:)`. É o atalho ⌥⌘F5, "mostrar controles de acessibilidade". A máscara gravada não traz o bit de função, como as das setas (entradas 32 e 79, `0x40000`), que ainda assim precisaram de `maskSecondaryFn` na injeção (RN-IN-10). A entrada 27 (próxima janela) está remapeada pelo usuário para ⌥Tab, o que confirma que os atalhos de sistema são de fato personalizados nesta máquina.
- **Preferências de acessibilidade:** `com.apple.universalaccess` não tem `axShortcutExposedFeatures` definida; a lista de recursos do Atalho de Acessibilidade está no padrão, com mais de um recurso, e portanto ⌥⌘F5 hoje abre o painel de escolha em vez de alternar o teclado diretamente. 🟡 (inferência pela ausência da chave; conferida no PM-0)
- **`SystemShortcut`** (`Sources/JoystickCore/Shortcuts/ShortcutMapper.swift`): enum `Int` com cinco casos (27, 32, 33, 79, 81), `name`, `displayName`, `defaultChord` e `chords(fromSymbolicHotKeys:)`, que percorre `allCases`. Entrada ausente, desativada ou malformada usa o padrão.
- **Consumidores de `SystemShortcut`:** `ShortcutActions.currentChord(for:)` lê as preferências no pressionar; `ActionPanel` lista `SystemShortcut.allCases`; `ShortcutConfigValidation` aceita `SystemShortcut(name:)`; `ConfigDocument` grava `name`; `ActionSummary` exibe `displayName`. Nenhum deles enumera os casos à mão.
- **Testes que fixam os cinco casos:** `ShortcutConfigTests.atalhoDeSistemaIdaEVoltaPeloNome` compara o conjunto de nomes; `ShortcutMapperTests.atalhosDeSistemaLidosDasPreferencias` usa entradas 27, 32 e 79.
- **`KeyboardInjector.postKey`:** acrescenta `.maskNumericPad` e `.maskSecondaryFn` só quando `chord.isArrow`; teclas F saem com as `flags` dos modificadores mantidos.
- **`KeyCatalog`:** F1 a F12 no grupo `function`, com F5 em `0x60`; o editor já monta ⌥⌘F5.
- **Testes:** 274, todos verdes após a feature 005 (`_reversa_sdd/addenda/005-sinais-matematicos.md`).

Conclusão: o legado já consegue postar ⌥⌘F5 num botão, sem código. O que falta saber é se o sistema e o Teclado de Acessibilidade reagem como ao teclado e ao mouse físicos; o que falta fazer é dar ao acionamento o mesmo tratamento dos atalhos de sistema e documentar os pré-requisitos.

## 3. Alternativas avaliadas

### 3.1 Como exibir o teclado nativo

| Alternativa | Prós | Contras | Veredito |
|-------------|------|---------|----------|
| Atalho de Acessibilidade (⌥⌘F5) com só o teclado marcado | Um acorde, que o app já posta; alternância nos dois sentidos; configuração feita uma vez pelo usuário | Depende de pré-requisito nos Ajustes; reconhecimento do acorde injetado a confirmar | **Escolhida** (D-01) |
| Atalho de Acessibilidade com vários recursos marcados | Nenhum ajuste de lista | Passo extra a cada uso, no painel | Aceita como passo extra (RN-02) |
| Módulo "Atalhos de Acessibilidade" na barra de menus ou na Central de Controle, clicado com o ponteiro | Sem acorde; independe da injeção de teclado | Dois ou três cliques pequenos no topo da tela a cada uso | Plano de contingência se P-01 falhar mesmo com D-03 |
| Visualizador de Teclado pelo menu de entrada | Nativo | Exige mostrar o menu de entrada e vários cliques | Descartada |
| Automação da interface dos Ajustes do Sistema | Não depende da lista do atalho | Permissão de Automação, frágil entre versões, abre a janela dos Ajustes | Descartada (RN-08) |
| Gravar `com.apple.universalaccess` | Nenhum clique | Escreve preferência do sistema; efeito no processo vivo incerto | Descartada (RN-08) |
| Teclado próprio do app | Controle total do tamanho | Contraria a decisão do usuário | Descartada (RN-01) |

### 3.2 Como representar o acionamento na configuração

| Alternativa | Prós | Contras | Veredito |
|-------------|------|---------|----------|
| Sexto atalho de sistema, `accessibilityShortcut` (ID 162) | Nome legível no editor; segue remapeamento; reaproveita validação, gravação, resumo e log | Nome novo no arquivo; dois testes fixos precisam de acréscimo | **Escolhida** (D-02) |
| Acorde ⌥⌘F5 comum | Zero código | Não segue remapeamento; montar F5 e dois modificadores pelo controle | Usada só no PM-0, para sondar |
| Tipo de ação novo | Semântica explícita | Tipo novo no arquivo, no editor e no log, sem ganho funcional | Descartada |

### 3.3 Máscara de função nas teclas F

| Alternativa | Prós | Contras | Veredito |
|-------------|------|---------|----------|
| Aplicar só se a P-01 reprovar sem ela | Mudança sob evidência, como na RN-IN-10 | Um ciclo de sonda a mais | **Escolhida** (D-03) |
| Aplicar sempre | Mais fiel ao teclado físico | Altera acordes com F já em uso sem evidência de necessidade | Descartada |

## 4. Compatibilidade e comportamento esperado do sistema

- **Atalho de Acessibilidade:** a Apple descreve ⌥⌘F5 como atalho que exibe o painel de atalhos de acessibilidade; com um único recurso selecionado na lista, o atalho liga e desliga esse recurso diretamente. 🟡 (conhecimento documental, conferido na P-02)
- **Teclado de Acessibilidade:** painel flutuante que digita no aplicativo em foco sem ativá-lo, redimensionável pelo canto e com opções de aparência, entre elas esmaecer após inatividade. 🟡 (P-03, P-05)
- **Cliques sintéticos:** `EventInjector` posta em `.cghidEventTap` com origem `hidSystemState` (RN-IN-01), o mesmo ponto de entrada do mouse físico; não há registro, no legado, de janela do sistema que recuse esses cliques, mas o teclado nunca foi testado. 🟡 (P-04)
- **Paleta e teclado juntos:** os dois são painéis não ativadores; a paleta deve abrir por cima sem ocultar o teclado. 🟡 (PM-1)
- **macOS 13:** a entrada 162 e o Teclado de Acessibilidade existem desde versões anteriores ao mínimo do app; só o macOS 26 é verificado. 🟡

## 5. Sondas

| ID | Pergunta | Como responder | Decisão afetada |
|----|----------|----------------|-----------------|
| P-01 | O ⌥⌘F5 injetado pelo app alterna o teclado, como o físico? | PM-0, passos 3 a 5 do `onboarding.md` | D-01; executa ou dispensa D-03 |
| P-02 | Com só o Teclado de Acessibilidade marcado, o acorde alterna sem painel; com mais recursos, abre o painel, e escolher o teclado nele com o ponteiro funciona? | PM-0, passos 5 e 9 | D-01, D-06 |
| P-03 | Exibir e ocultar o teclado preserva o aplicativo em foco? | PM-0, passo 6 | RN-05; continuidade da feature |
| P-04 | Os cliques de R1 nas teclas do teclado digitam no aplicativo em foco? | PM-0, passo 7 | RF-02; continuidade da feature |
| P-05 | Redimensionado, o teclado permite digitar a 3 m sem erro? | PM-0, passo 10 | RN-11, RF-07, D-06 |

## 6. Padrões aplicáveis

- Atalho de sistema lido das preferências no instante do uso (003 D-12 e RN-07; `_reversa_sdd/atalhos/requirements.md#Regras de Negócio`, RN-AT-10).
- Injeção fiel ao teclado físico (RN-IN-10): máscaras acrescentadas só quando o sistema as exige.
- Integração com terceiros por atalho e pré-requisito documentado (`_reversa_sdd/addenda/prd-l01-ditado-pelo-raycast.md`).
- Portão manual no hardware antes do código, quando o comportamento depende do sistema (`_reversa_sdd/domain.md#2. Glossário`, "Portão manual" e "Sonda").
