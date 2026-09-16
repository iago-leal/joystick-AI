# Roadmap: Teclado virtual chamado pelo controle

> Identificador: `006-teclado-virtual`
> Data: `2026-09-16`
> Requirements: `_reversa_forward/006-teclado-virtual/requirements.md`
> Confidência: 🟢 CONFIRMADO, 🟡 INFERIDO, 🔴 LACUNA

> **Nota de confidência:** recebem 🟢 as decisões apoiadas no código inspecionado em 2026-09-16 (`ShortcutMapper.swift`, `KeyCatalog.swift`, `KeyboardInjector.swift`, `ActionPanel.swift`, `ActionSummary.swift`, `ShortcutConfigValidation.swift`, `ShortcutConfigTests.swift`, `ShortcutMapperTests.swift`), na leitura das preferências desta máquina (macOS 26.6.2) ou na extração em `_reversa_sdd/`. Recebem 🟡 as que dependem da reação do macOS ao acorde e aos cliques injetados; as sondas P-01 a P-05 do portão PM-0 as confirmam antes de qualquer código. Não há 🔴: o `requirements.md` não tem `[DÚVIDA]` pendente.

## 1. Resumo da abordagem

O teclado virtual é o Teclado de Acessibilidade do macOS, alternado pelo Atalho de Acessibilidade do sistema, ⌥⌘F5. Com só o teclado marcado na lista do atalho, nos Ajustes do Sistema, o acorde o exibe e o oculta diretamente; com mais recursos marcados, abre o painel em que o usuário o escolhe com o ponteiro, que é o passo extra aceito no esclarecimento. O app não desenha teclado, não escreve preferências e não pede permissão.

O legado já envia ⌥⌘F5 como acorde comum; por isso a feature começa por um portão de sondas sem código (PM-0), com o app atual. O delta de código é pequeno e fica no núcleo: `SystemShortcut` ganha o sexto atalho de sistema, `accessibilityShortcut`, lido de `AppleSymbolicHotKeys` (ID 162) como os cinco existentes, de modo que o usuário o escolhe no editor pelo nome e o acorde segue um eventual remapeamento nos Ajustes. Só se a P-01 mostrar que o ⌥⌘F5 injetado é ignorado, as teclas F1 a F12 passam a sair com a máscara de função, como já ocorre com as setas. O mapeamento padrão, o log e o formato do arquivo não mudam, exceto pelo nome novo aceito em `systemShortcut`.

## 2. Princípios aplicados

Não existe `.reversa/principles.md`; não há princípio a respeitar nem conflito a registrar. As restrições equivalentes vêm da extração e das features anteriores:

| Restrição | Como a feature se relaciona | Status |
|-----------|------------------------------|--------|
| Núcleo funcional com casca imperativa; `JoystickCore` só importa `Foundation` (`architecture.md` §2 e §3) | O atalho novo e a leitura das preferências ficam em `SystemShortcut`, no núcleo, testados; o app só lista o que o núcleo expõe (D-02) | respeita |
| Atalhos de sistema lidos das preferências no instante do uso (003 RN-07; RN-AT-10) | O atalho de acessibilidade segue a mesma regra, inclusive a de entrada desativada (RN-AT-22) (D-02) | respeita |
| Sem permissão nova, sem rede, sem escrita fora dos arquivos do app (`permissions.md` §2) | O app só lê `com.apple.symbolichotkeys` e posta eventos; os ajustes do sistema ficam como pré-requisito do usuário (D-01, D-06) | respeita |
| Log sem teclas nem acordes (003 RN-14; RN-AT-17) | Nenhum evento novo; o acionamento aparece como `shortcut.triggered` com `type: systemShortcut` (D-05) | respeita |
| Integração com terceiros por atalho, com pré-requisito documentado (adendo `prd-l01-ditado-pelo-raycast`) | Mesmo desenho do ditado pelo Raycast (D-01, D-06) | respeita |
| Regra de escrita do Reversa (`CLAUDE.md`) | `.reversa/reversa-config.json` está com `allowLegacyEdits: true` e `allowedPaths` vazio, liberação irrestrita. O `/reversa-coding` deve avisar uma vez por sessão | observação |

## 3. Decisões técnicas

| ID | Decisão | Justificativa | Alternativas descartadas | Confidência |
|----|---------|----------------|--------------------------|-------------|
| D-01 | O teclado virtual é o Teclado de Acessibilidade, alternado pelo Atalho de Acessibilidade do macOS (⌥⌘F5). Pré-requisito do usuário: marcar só o Teclado de Acessibilidade na lista do atalho, para a alternância direta (RN-02); com outros recursos marcados, o acorde abre o painel de escolha, que é o passo extra aceito. | É o teclado nativo pedido (RN-01), alternável por um único acorde que o app já sabe postar (RN-AT-07). A entrada 162 de `AppleSymbolicHotKeys` foi lida nesta máquina: ativa, F5 (`96`) com máscara `0x180000` (⌥⌘). | Automação da interface dos Ajustes do Sistema (exige permissão de Automação e quebra a cada versão, contra RN-08); `defaults write com.apple.universalaccess` (escreve preferência do sistema, contra RN-08, e o efeito no processo vivo é incerto); Visualizador de Teclado pelo menu de entrada (vários cliques na barra de menus a cada uso); teclado próprio do app (RN-01) | 🟡 (P-01, P-02) |
| D-02 | Em `Sources/JoystickCore/Shortcuts/ShortcutMapper.swift`, `SystemShortcut` ganha `case accessibilityShortcut = 162`, com `name` `"accessibilityShortcut"`, `displayName` `"atalho de acessibilidade"` e `defaultChord` `KeyChord(KeyChord.f5, [.option, .command])`; `KeyChord` ganha a constante `f5 = 96`. `chords(fromSymbolicHotKeys:)` não muda: já percorre `allCases`. | Escolher "Atalho de sistema › atalho de acessibilidade" no editor dispensa montar F5 com ⌥⌘ e acompanha um remapeamento do atalho nos Ajustes, como nos cinco existentes (RF-04). Sem outra mudança, o nome passa a valer em `ShortcutConfigValidation`, `ConfigDocument`, `ActionSummary` e na lista de `ActionPanel`, que percorre `SystemShortcut.allCases`. | Só o acorde ⌥⌘F5, sem código (funciona, mas não segue remapeamento e obriga a montar F5 e dois modificadores); tipo de ação novo `toggleVirtualKeyboard` (novo tipo no arquivo, no editor e em `shortcut.triggered`, sem ganho sobre o atalho de sistema); rótulo "teclado virtual" (enganoso quando o atalho abre o painel com outros recursos) | 🟢 |
| D-03 | **Condicional à P-01.** Se o ⌥⌘F5 injetado não alternar o teclado e o físico alternar, `KeyChord` ganha `isFunctionKey` (F1 a F12, os 12 códigos de `KeyCatalog.function`) e `KeyboardInjector.postKey` acrescenta `.maskSecondaryFn` às `flags` dessas teclas, sem `.maskNumericPad`. Se a P-01 passar sem a máscara, D-03 não é executada. | O teclado físico da Apple envia as teclas F com a máscara de função; RN-IN-10 mostra que o sistema já ignorou setas injetadas sem as máscaras do físico. Aplicar só sob evidência evita mudar acordes com F já configurados. | Aplicar a máscara incondicionalmente (muda comportamento sem evidência); postar o evento de tecla de sistema (`NSSystemDefined`) (não é o caminho dos atalhos simbólicos) | 🟡 (P-01) |
| D-04 | O mapeamento padrão não muda: `ShortcutDefaults` fica intacto e nenhum botão de fábrica aciona o atalho de acessibilidade. | RN-10 e RF-06, decisão do usuário. | L3 na base (descartada no esclarecimento) | 🟢 |
| D-05 | Nada muda em `LogEventCatalog`, `ShortcutActions`, `InputRouter`, `PaletteActions` e `EditorViewModel`. O acionamento gera `shortcut.triggered { button, layer, type: "systemShortcut" }`, sem nome do atalho; pressionar e soltar seguem RN-AT-08, e as solturas na desconexão e na suspensão seguem RN-AT-14 e RN-AT-15. | Cobre RF-05, RF-09 e RF-10 com regras do legado. O app não sabe se o teclado está visível e não precisa saber, porque RN-09 dispensa fechamento automático. | Registrar o nome do atalho no log (fere 003 RN-14 por analogia e não ajuda o diagnóstico); acompanhar o estado do teclado pela API de acessibilidade (exigiria observar outra aplicação, sem requisito que o peça) | 🟢 |
| D-06 | A documentação dos pré-requisitos fica no `onboarding.md` da feature, §0 e §2: lista do Atalho de Acessibilidade, entrada "controles de acessibilidade" ativa nos atalhos de teclado, tamanho e esmaecimento do teclado. O caminho exato dos menus em português no macOS 26 é conferido no PM-0 e corrigido no arquivo. | RF-08, RN-08, RN-11; mesmo desenho dos pré-requisitos do ditado. | Documentar no app, com tela de ajuda (superfície nova sem requisito) | 🟡 (PM-0) |
| D-07 | Testes em `Tests/JoystickCoreTests/`: `ShortcutConfigTests.atalhoDeSistemaIdaEVoltaPeloNome` passa a esperar seis nomes, com `accessibilityShortcut` e o rótulo "atalho de acessibilidade"; `ShortcutMapperTests.atalhosDeSistemaLidosDasPreferencias` ganha a entrada `"162"` com `[65535, 96, 1572864]` → ⌥⌘F5 e um caso remapeado; `ShortcutConfigValidationTests` aceita `{"type": "systemShortcut", "name": "accessibilityShortcut"}`; `ConfigDocumentTests` faz ida e volta com o atalho novo; `ActionSummaryTests` resume "atalho de acessibilidade"; `ShortcutDefaults` continua sem o atalho. Se D-03 for executada, um teste de `isFunctionKey` para F1, F5 e F12 e contra `0x18` e as setas. | Cobre RF-04, RF-06 e a leitura das preferências sem hardware; TD-01 deixa o injetor sem teste, coberto pelo PM-1. | Teste do app (não há alvo de teste do app, TD-01) | 🟢 |
| D-08 | Dois portões manuais: **PM-0**, antes do código, com o app atual e um acorde ⌥⌘F5 montado num botão de teste, responde P-01 a P-05; **PM-1**, depois do código, verifica o atalho de sistema escolhido pelo editor e os cenários restantes do `requirements.md` §7. | O que decide a feature (reconhecimento do acorde, foco, cliques no teclado) só se observa no hardware; responder antes evita código inútil. | Um só portão ao fim (D-03 poderia ser implementada sem necessidade, ou a feature seguir até o fim com P-04 reprovada) | 🟢 |

## 4. Premissas

Nenhuma premissa vem de `[DÚVIDA]`: o `requirements.md` não tem marcador pendente. As premissas abaixo vêm das sondas e são respondidas no PM-0.

| Premissa | Origem (`requirements.md` seção) | Risco se errada |
|----------|----------------------------------|-----------------|
| Com só o Teclado de Acessibilidade marcado, ⌥⌘F5 alterna o teclado sem painel (P-02) | §4 RN-02; §9, D-01 | O caminho vira sempre o do passo extra, ainda aceito pelo usuário |
| O Teclado de Acessibilidade aceita os cliques sintéticos do ponteiro (P-04) | §10, risco residual | RF-02 sem caminho de entrega; a continuidade volta ao usuário no PM-0, antes de qualquer código |
| Exibir o teclado não muda o aplicativo em foco (P-03) | §4 RN-05; RF-03 | O texto iria ao teclado ou a outro app; sem mitigação no escopo, a decisão volta ao usuário |

## 5. Delta arquitetural

| Componente | Arquivo de origem no legado | Tipo de mudança | Resumo |
|------------|------------------------------|-----------------|--------|
| `shortcuts` (atalhos de sistema) | `_reversa_sdd/code-analysis.md#5.3 Catálogos`; `_reversa_sdd/atalhos/requirements.md#Regras de Negócio` (RN-AT-10, RN-AT-20) | regra-alterada | `SystemShortcut` passa de 5 para 6 atalhos, com `accessibilityShortcut` (ID 162, padrão ⌥⌘F5); `KeyChord` ganha `f5` |
| `injection` (teclado) | `_reversa_sdd/injecao-de-eventos/requirements.md#Regras de Negócio` (RN-IN-10) | regra-alterada, condicional | Só com D-03: F1 a F12 postadas com `maskSecondaryFn` |
| Integrações externas | `_reversa_sdd/architecture.md#4. Integrações externas` | contrato-novo | I-13: Atalho e Teclado de Acessibilidade do macOS, saída indireta por acorde e por cliques do ponteiro; ver `interfaces/atalho-de-acessibilidade.md` |

`editor`, `config`, `palette`, `diagnostics-log` e a figura não mudam de código: recebem o atalho novo pelas listas e resumos do núcleo.

## 6. Delta no modelo de dados

- Resumo das mudanças: o arquivo de configuração passa a aceitar `"name": "accessibilityShortcut"` em ações `systemShortcut`; nada mais muda em disco. No núcleo, um caso novo em `SystemShortcut`, a constante `KeyChord.f5` e, só com D-03, a propriedade `KeyChord.isFunctionKey`.
- Detalhe completo em: `_reversa_forward/006-teclado-virtual/data-delta.md`

## 7. Delta de contratos externos

| Contrato | Tipo | Arquivo de detalhe |
|----------|------|--------------------|
| Atalho e Teclado de Acessibilidade do macOS | sistema operacional (preferência lida, acorde e cliques postados) | `_reversa_forward/006-teclado-virtual/interfaces/atalho-de-acessibilidade.md` |
| Arquivo de configuração | arquivo | nome novo em `systemShortcut`; o contrato de `_reversa_forward/003-editor-atalhos/interfaces/config-file.md` segue vigente, com o acréscimo descrito em `data-delta.md` §1 |
| Log de diagnóstico | arquivo | sem mudança; `_reversa_forward/004-figura-controle-web/interfaces/diagnostic-log.md` segue vigente |

## 8. Plano de migração

n/a. Arquivos existentes continuam válidos e nenhum é reescrito. Um arquivo que use `accessibilityShortcut` é recusado por versões do app anteriores à feature com `unknownSystemShortcut`; como a instalação é única e local, não há convivência de versões a tratar.

## 9. Riscos e mitigações

| Risco | Impacto | Probabilidade | Mitigação |
|-------|---------|---------------|-----------|
| O ⌥⌘F5 injetado não é reconhecido pelo sistema | alto | médio | P-01 no PM-0; D-03 (máscara de função); se ainda falhar, passo extra sem código pelo módulo de Atalhos de Acessibilidade na barra de menus, clicado com o ponteiro |
| O teclado recusa os cliques sintéticos | alto | baixo | P-04 no PM-0, antes do código; reprovada, a feature para e volta ao usuário (risco residual do `requirements.md` §10) |
| Exibir o teclado tira o foco do aplicativo | alto | baixo | P-03 no PM-0; reprovada, a feature para e volta ao usuário |
| Teclas pequenas demais a 3 m | médio | médio | P-05: redimensionar o teclado pelo canto e ajustar a aparência nos Ajustes; RN-11 aceita o limite do sistema |
| O teclado esmaece após inatividade e parece ter sumido | baixo | médio | Pré-requisito documentado: desligar o esmaecimento nas opções do teclado (D-06) |
| Atalho desativado nos Ajustes: o app posta ⌥⌘F5 mesmo assim | baixo | baixo | Comportamento aceito (RN-AT-22); o cenário "Pré-requisito externo ausente" confirma que nada fica preso |
| Caminho dos menus nos Ajustes diferente do documentado no macOS 26 | baixo | médio | Conferido e corrigido no PM-0 (D-06) |

## 10. Critério de pronto

- [ ] Todas as ações do `actions.md` marcadas `[X]`
- [ ] `cross-check.md` (se executado) sem CRITICAL nem HIGH
- [ ] `regression-watch.md` gerado
- [ ] PM-0 aprovado, com P-01 a P-05 registradas em `onboarding.md` e a decisão sobre D-03 anotada
- [ ] `swift build -c release` e `./scripts/test.sh` verdes, com os testes de D-07 (274 antes da feature)
- [ ] PM-1 aprovado, com os pré-requisitos do `onboarding.md` conferidos no macOS 26
- [ ] Re-extração reversa executada e sem regressão vermelha (recomendado, não obrigatório)

## 11. Histórico de alterações

| Data | Alteração | Autor |
|------|-----------|-------|
| 2026-09-16 | Versão inicial gerada por `/reversa-plan` | reversa |
