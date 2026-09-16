# Impacto no legado: Teclado virtual chamado pelo controle

> Identificador: `006-teclado-virtual`
> Data: `2026-09-16`
> Âncora: legado (`_reversa_sdd/architecture.md` + `_reversa_sdd/domain.md`, extração de 2026-09-15, com os adendos das features 001 a 005), com as specs SDD de `_reversa_sdd/sdd/` como complemento.
> Política de edição no momento da execução: `allowLegacyEdits: true`, `allowedPaths` vazio (liberação irrestrita do projeto), relida na ativação do `/reversa-coding`.
> Execução: completa; 15 de 15 ações fechadas em quatro rodadas. A sonda P-01 foi reprovada com o app anterior, o que levou à execução da D-03 (máscara de função nas teclas F); o PM-0B e o PM-1 foram aprovados.

A feature não desenha teclado: usa o Teclado de Acessibilidade do macOS, alternado pelo Atalho de Acessibilidade (⌥⌘F5, entrada 162 de `AppleSymbolicHotKeys`). O núcleo ganha um sexto atalho de sistema, `accessibilityShortcut`, lido das preferências como os cinco existentes e escolhido no editor pelo rótulo "atalho de acessibilidade". A sonda no hardware mostrou que o sistema ignora o ⌥⌘F5 injetado sem a máscara de função. Por isso, o injetor de teclado passa a acrescentar `maskSecondaryFn` às teclas F1 a F12, como já fazia com as setas.

## Arquivos afetados

| Arquivo afetado | Componente | Tipo | Severidade | Justificativa |
|-----------------|------------|------|------------|---------------|
| `Sources/JoystickCore/Shortcuts/ShortcutMapper.swift` | `shortcuts` (architecture.md §3, camada Core; `atalhos/design.md`, `KeyChord` e `SystemShortcut`) | regra-alterada | MEDIUM | `SystemShortcut` passa de 5 para 6 casos com `accessibilityShortcut = 162` (nome `accessibilityShortcut`, rótulo "atalho de acessibilidade", padrão ⌥⌘F5). `KeyChord` ganha `f5 = 96`, `functionKeys` (os 12 códigos de F1 a F12) e `isFunctionKey`. `chords(fromSymbolicHotKeys:)` não muda e passa a ler a entrada `"162"`. O nome novo passa a valer, sem outra mudança de código, em `ShortcutConfigValidation`, `ConfigDocument`, `ActionSummary` e na lista de `ActionPanel`. |
| `Sources/JoystickAIPoC/Injection/KeyboardInjector.swift` | `injection` (architecture.md §3, camada App; `injecao-de-eventos/requirements.md`, RN-IN-10) | regra-alterada | MEDIUM | `postKey` acrescenta `.maskSecondaryFn` às `flags` de F1 a F12, sem `.maskNumericPad`. Todo acorde com tecla F configurado pelo usuário passa a sair com a máscara, como no teclado físico da Apple. Sem teste automatizado (TD-01); coberto pelo PM-0B. |
| `Tests/JoystickCoreTests/ShortcutConfigTests.swift` | testes | regra-alterada | LOW | `atalhoDeSistemaIdaEVoltaPeloNome` espera seis nomes e o rótulo "atalho de acessibilidade". |
| `Tests/JoystickCoreTests/ShortcutMapperTests.swift` | testes | regra-nova | LOW | `atalhosDeSistemaLidosDasPreferencias` lê a entrada 162; testes novos `atalhoDeAcessibilidadeRemapeadoOuDesativado` e `teclasDeFuncao`. A suíte tem 20 testes. |
| `Tests/JoystickCoreTests/ShortcutConfigValidationTests.swift` | testes | regra-nova | LOW | Teste novo `atalhoDeAcessibilidadeAceito`. A suíte tem 21 testes. |
| `Tests/JoystickCoreTests/ConfigDocumentTests.swift` | testes | regra-nova | LOW | Teste novo `idaEVoltaComAtalhoDeAcessibilidade`. A suíte tem 9 testes. |
| `Tests/JoystickCoreTests/ActionSummaryTests.swift` | testes | regra-nova | LOW | Teste novo `atalhoDeAcessibilidade`. A suíte tem 7 testes. |
| `Tests/JoystickCoreTests/ShortcutDefaultsTests.swift` | testes | regra-nova | LOW | Teste novo `padraoSemAtalhoDeAcessibilidade`. A suíte tem 2 testes. |
| Integração com o macOS (sem arquivo de código) | integrações externas (architecture.md §4, nova I-13) | delta-de-contrato-externo | MEDIUM | Atalho e Teclado de Acessibilidade: preferência lida (entrada 162), acorde postado e cliques do ponteiro. Pré-requisito do usuário: só o Teclado de Acessibilidade na lista do atalho. Contrato em `interfaces/atalho-de-acessibilidade.md`. |
| `~/.config/joystick-ai/config.json` (formato) | `config` (architecture.md §5) | delta-de-dados | LOW | `systemShortcut.name` aceita `accessibilityShortcut`; nenhum campo, tipo ou versão novos. Versões anteriores recusariam o nome com `unknownSystemShortcut`. |

Resultado da verificação (T014): `swift build -c release` verde; `./scripts/test.sh` com 280 testes em 31 suítes, todos verdes (274 antes da feature).

## Diff conceitual por componente

**Atalhos, atalhos de sistema.** Antes, o app conhecia cinco atalhos do macOS, todos de janelas e mesas. Agora conhece seis: o Atalho de Acessibilidade entra com o mesmo tratamento, isto é, acorde lido das preferências no pressionar, padrão ⌥⌘F5 quando a entrada está ausente, desativada ou malformada, pressionar e soltar como acorde e soltura forçada na desconexão e na suspensão. Como nenhum consumidor enumera os casos à mão, o editor passa a listar o sexto atalho, o resumo e a figura mostram "atalho de acessibilidade", e o arquivo grava e valida o nome, sem mudança nesses arquivos.

**Atalhos, `KeyChord`.** Ganha a constante `f5` e a classificação `isFunctionKey`, paralela a `isArrow`, com a lista pública `functionKeys`, que um teste compara ao grupo `function` de `KeyCatalog`.

**Injeção de eventos, teclado.** Antes, só as setas recebiam máscaras além dos modificadores. Agora as teclas F1 a F12 recebem `maskSecondaryFn`. A mudança foi motivada por evidência no hardware: com o app anterior, o ⌥⌘F5 injetado chegava ao aplicativo em foco como tecla comum, enquanto o físico abria o painel; com a máscara, o controle abriu o painel e alternou o teclado. O efeito alcança qualquer acorde com tecla F, não só o atalho novo.

**Mapeamento padrão, log, paleta, roteador e editor.** Sem mudança de código (D-04, D-05). O acionamento aparece como `shortcut.triggered { button, layer, type: "systemShortcut" }`, sem o nome do atalho.

## Preservadas

Regras 🟢 do `domain.md` e da extração que continuam intactas, com a evidência conferida nesta rodada:

- **001 RN-04** (nenhuma desconexão deixa entrada presa) e **RN-AT-14, RN-AT-15** (soltar tudo e solturas na suspensão): `ShortcutActions` inalterado; o atalho novo segue o caminho dos atalhos de sistema existentes. Sem verificação em hardware nesta rodada (PM-1, passos 9 e 10, não relatados).
- **001 RN-12** e **003 RN-14** (log sem textos, rótulos nem acordes): nenhum evento novo; nos logs dos portões, as contagens de `"ls"`, `f5` (fora de `session.start`), `accessibility` e `CONTINUAR` são 0.
- **002 RN-02** (a paleta nunca toma o foco): `PaletteActions` inalterado; com o teclado visível, a paleta abriu e fechou (PM-0, passo 8).
- **003 RN-05** (R1 e touchpad fazem o clique esquerdo em qualquer camada): os cliques de R1 digitaram no Teclado de Acessibilidade (P-04).
- **003 RN-08** (configuração inválida nunca substitui a vigente): `ConfigLoader` e `ConfigStore` inalterados.
- **003 RN-11** e **RN-AT-19** (mapeamento padrão idêntico ao protótipo): `ShortcutDefaults` inalterado; `ShortcutDefaultsTests` verde, com o teste novo que exclui o atalho de acessibilidade.
- **003 RN-16** e **RN-AT-13** (paleta aberta e modo de identificação retêm os botões): `InputRouter` inalterado.
- **RN-AT-05, RN-AT-06, RN-AT-08** (ação decidida no pressionar, botão já pressionado sem efeito, atalho de sistema pressiona e solta): `ShortcutMapper` só ganhou um caso; o mapeador não mudou.
- **RN-AT-11** (conversão da máscara das preferências): `chords(fromSymbolicHotKeys:)` inalterado; testes com a entrada 162 real e remapeada.
- **RN-AT-17** (`shortcut.triggered` com `button`, `layer` e `type`): o acionamento do atalho novo gerou `type: systemShortcut` sem nome.
- **RN-AT-18** (73 teclas no catálogo): `KeyCatalog` inalterado; `functionKeys` coincide com o grupo `function`.
- **RN-AT-22** (atalho desativado posta o padrão): coberto por `atalhoDeAcessibilidadeRemapeadoOuDesativado`.
- **RN-IN-01** e **RN-IN-09** (marca do evento, ponto de injeção e ordem dos modificadores): `EventInjector` e a sequência de `chordDown`/`chordUp` inalterados.
- **ADR-011** e **architecture.md §5** (configuração em JSON sem migração): `shortcuts.version` segue 1.
- **architecture.md §3** (`JoystickCore` só importa `Foundation`): nenhum `import` novo.
- **permissions.md §2** (só Acessibilidade, sem rede): nenhuma permissão nova; o app só lê `com.apple.symbolichotkeys`.

## Modificadas

Regras 🟢 alteradas ou cuja descrição na extração deixa de ser completa; cada uma gera um item no `regression-watch.md`:

- **`_reversa_sdd/domain.md` §3.3, 003 RN-07** ("Cinco atalhos de sistema"): passam a ser seis, com o Atalho de Acessibilidade.
- **`_reversa_sdd/domain.md` §2, glossário, "Atalho de sistema"** ("Um dos cinco atalhos do macOS"): inclui o Atalho de Acessibilidade.
- **`_reversa_sdd/atalhos/requirements.md`, RN-AT-07** ("`systemShortcut` (5 atalhos)") e **RN-AT-10** ("IDs 27, 32, 33, 79 e 81"): seis atalhos, com o ID 162.
- **`_reversa_sdd/atalhos/requirements.md`, RN-AT-20** (acordes padrão dos atalhos de sistema): acrescenta atalho de acessibilidade ⌥⌘F5.
- **`_reversa_sdd/injecao-de-eventos/requirements.md`, RN-IN-10** ("Setas recebem também `maskNumericPad` e `maskSecondaryFn`"): as teclas F1 a F12 recebem `maskSecondaryFn`.
- **`_reversa_sdd/atalhos/design.md`, tabela de tipos, `KeyChord` e `SystemShortcut`**; **`_reversa_sdd/data-dictionary.md` §3.2 e §3.4**; **`_reversa_sdd/code-analysis.md` §5.3**: constantes com `f5` 96, `functionKeys` e `isFunctionKey`; enumeração com `accessibilityShortcut` 162.
- **`_reversa_sdd/architecture.md` §4** (integrações I-01 a I-12): nova I-13, Atalho e Teclado de Acessibilidade do macOS.
- **`_reversa_sdd/traceability/code-spec-matrix.md`** (contagem de testes por arquivo): `ActionSummaryTests` 7, `ConfigDocumentTests` 9, `ShortcutConfigValidationTests` 21, `ShortcutDefaultsTests` 2 e `ShortcutMapperTests` 20; a matriz já estava defasada em relação a algumas features anteriores.
