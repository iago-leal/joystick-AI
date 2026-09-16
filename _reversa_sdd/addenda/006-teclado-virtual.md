# Adendo: Teclado virtual chamado pelo controle

> Identificador: `006-teclado-virtual`
> Data: 2026-09-16
> Cenário: legado

## Vigência

Vigente desde 2026-09-16.

## Resumo da entrega

A feature permite digitar texto livre sem teclado físico: um botão do controle, escolhido pelo usuário no editor, exibe e oculta o Teclado de Acessibilidade do macOS, e as teclas são acionadas com os cliques do ponteiro. O app não desenha teclado, não escreve preferências do sistema e não pede permissão nova. O acionamento é um sexto atalho de sistema, `accessibilityShortcut` (entrada 162 de `AppleSymbolicHotKeys`, padrão ⌥⌘F5), lido das preferências como os cinco existentes. A sonda no hardware mostrou que o sistema ignora o ⌥⌘F5 injetado sem a máscara de função; por isso, as teclas F1 a F12 passaram a sair com `maskSecondaryFn`. O pré-requisito do usuário é deixar só o Teclado de Acessibilidade na lista do Atalho de Acessibilidade, para a alternância direta. O mapeamento padrão, o log e o formato do arquivo não mudam, exceto pelo nome novo aceito em `systemShortcut`.

Sincronização completa: as 15 ações de `actions.md` estão fechadas, em quatro rodadas, incluindo as três condicionais da D-03. `swift build -c release` e `./scripts/test.sh` estão verdes, com 280 testes (274 antes da feature). A sonda P-01 foi reprovada com o app anterior e aprovada no PM-0B; P-02 a P-05 e o PM-1 foram aprovados pelo relato do usuário e pelo log. O usuário manteve o atalho em Options + →. Os passos do PM-1 sobre paleta aberta, modo de identificação, atalho desativado, desconexão e revogação da permissão não foram relatados.

## Impacto por artefato da extração

| Artefato | Seção | Tipo de impacto | Delta |
|----------|-------|-----------------|-------|
| `_reversa_sdd/architecture.md` | `#3. Camadas e dependências` | regra-alterada | O componente `shortcuts` do `JoystickCore` tem seis atalhos de sistema e, em `KeyChord`, `f5`, `functionKeys` e `isFunctionKey`; o componente `injection` do app acrescenta `maskSecondaryFn` às teclas F1 a F12. O núcleo continua importando só `Foundation`. |
| `_reversa_sdd/architecture.md` | `#4. Integrações externas` | delta-de-contrato-externo | Leia uma integração I-13, Atalho e Teclado de Acessibilidade do macOS: leitura da entrada 162 (via I-06), acorde postado (via I-03) e cliques do ponteiro sobre o teclado, sem retorno do sistema; contrato em `_reversa_forward/006-teclado-virtual/interfaces/atalho-de-acessibilidade.md`. |
| `_reversa_sdd/architecture.md` | `#5. Modelo de dados em arquivo` | delta-de-dados | `systemShortcut.name` aceita também `accessibilityShortcut`; nenhum campo, tipo ou versão novos, e arquivos anteriores são lidos sem migração. |
| `_reversa_sdd/domain.md` | `#2. Glossário` | regra-alterada | "Atalho de sistema" passa a designar um dos seis atalhos do macOS, incluindo o Atalho de Acessibilidade. |
| `_reversa_sdd/domain.md` | `#3.3 Atalhos, configuração e editor (003)` | regra-alterada | 003 RN-07 deve ser lida com seis atalhos de sistema; 003 RN-05, RN-08, RN-11, RN-14 e RN-16 continuam intactas, e o mapeamento padrão não aciona o atalho novo. |
| `_reversa_sdd/atalhos/requirements.md` | `#Regras de Negócio` (RN-AT-07, RN-AT-10, RN-AT-20) | regra-alterada | `systemShortcut` tem 6 atalhos; a leitura das preferências inclui o ID 162; o acorde padrão do atalho de acessibilidade é ⌥⌘F5. RN-AT-11, RN-AT-17, RN-AT-19 e RN-AT-22 seguem válidas para ele. |
| `_reversa_sdd/atalhos/design.md` | `#Tipos do núcleo` (`KeyChord`, `SystemShortcut`) | regra-alterada | `KeyChord` ganha a constante `f5` 96, a lista `functionKeys` e `isFunctionKey`; `SystemShortcut` ganha `accessibilityShortcut` 162, nome `accessibilityShortcut`, rótulo "atalho de acessibilidade". |
| `_reversa_sdd/injecao-de-eventos/requirements.md` | `#Regras de Negócio` (RN-IN-10) | regra-alterada | Além das setas, com `maskNumericPad` e `maskSecondaryFn`, as teclas F1 a F12 recebem `maskSecondaryFn`, o que vale para qualquer acorde com tecla F. |
| `_reversa_sdd/data-dictionary.md` | `#3.2 KeyChord`; `#3.4 SystemShortcut` | regra-alterada | Constantes com `f5` 96, `functionKeys` e `isFunctionKey`; enumeração com o sexto caso, `accessibilityShortcut` = 162. |
| `_reversa_sdd/code-analysis.md` | `#5.3 Catálogos` | regra-alterada | `SystemShortcut` lista também `accessibilityShortcut` (162, ⌥⌘F5). |
| `_reversa_sdd/traceability/code-spec-matrix.md` | `#Testes` | regra-alterada | Contagens atuais: `ActionSummaryTests` 7, `ConfigDocumentTests` 9, `ShortcutConfigTests` 7, `ShortcutConfigValidationTests` 21, `ShortcutDefaultsTests` 2 e `ShortcutMapperTests` 20; o total do projeto passa a 280. |

## Regras sob vigilância

W001 a W008 no watch principal e O001 a O006 em "Observações", em [`_reversa_forward/006-teclado-virtual/regression-watch.md`](../../_reversa_forward/006-teclado-virtual/regression-watch.md). O desfecho dos portões para as observações está registrado no próprio arquivo.

## Fontes

- `_reversa_forward/006-teclado-virtual/legacy-impact.md`
- `_reversa_forward/006-teclado-virtual/regression-watch.md`
- `_reversa_forward/006-teclado-virtual/requirements.md`
- `_reversa_forward/006-teclado-virtual/progress.jsonl`
- `_reversa_forward/006-teclado-virtual/actions.md` (notas das rodadas 1 a 4)
- `_reversa_forward/006-teclado-virtual/data-delta.md`
- `_reversa_forward/006-teclado-virtual/interfaces/atalho-de-acessibilidade.md`
- `_reversa_forward/006-teclado-virtual/onboarding.md` (resultado dos portões, §4)
