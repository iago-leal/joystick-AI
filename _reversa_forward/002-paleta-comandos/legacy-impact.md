# Impacto no legado: Paleta de comandos pelo controle

> Identificador: `002-paleta-comandos`
> Data: `2026-09-14`
> Feature greenfield, sem legado extraído por `/reversa`. Âncora: prd.md + specs SDD, mais o código entregue pela feature 001 (`_reversa_sdd/addenda/001-poc-entrada-ponteiro.md`).
> Política de edição no momento da execução: `allowLegacyEdits: true`, `allowedPaths` vazio (liberação irrestrita do projeto)
> Execução: parcial; rodada 1 (21 de 22 ações) até o portão manual PM-1

Diferentemente da 001, esta feature altera arquivos já existentes, criados pela própria 001. Não há `architecture.md` nem `domain.md`; os componentes citam as specs em `_reversa_sdd/sdd/` e os tipos de impacto refletem a mudança sobre o código da 001.

## Arquivos afetados

| Arquivo afetado | Componente | Tipo | Severidade | Justificativa |
|-----------------|------------|------|------------|---------------|
| `Sources/JoystickCore/Palette/CommandPalette.swift` | `action-mapping` §8 (paleta, novo) | componente-novo | MEDIUM | Lista fixa de 17 itens e `PaletteMachine`; define o que é digitado no aplicativo em foco. |
| `Sources/JoystickCore/Shortcuts/KeyRepeat.swift` | `action-mapping` RF-10 | componente-novo | LOW | Constantes de repetição antes locais a `ShortcutActions`, sem mudança de valor. |
| `Sources/JoystickCore/Shortcuts/ShortcutMapper.swift` | `action-mapping` §8 (protótipo EXP-01) | regra-alterada | MEDIUM | PS passa de "sem ação" a `.openPalette` na camada base e, por repasse, com L1 e L2. Demais atalhos inalterados. |
| `Sources/JoystickCore/App/LaunchArguments.swift` | argumentos de abertura (001 `target-run-result.md`) | delta-de-contrato-externo | LOW | `--palette-enter-delay-ms` e `concernsPalette`; argumentos existentes inalterados. |
| `Sources/JoystickCore/Log/LogEventCatalog.swift` | `app-shell` RF-12 (log) | delta-de-contrato-externo | MEDIUM | Cinco eventos `palette.*`, sem texto de item; `logSchema` mantido em 1. |
| `Sources/JoystickAIPoC/Palette/PalettePanel.swift` | `app-shell` §8 (superfície nova) | componente-novo | HIGH | Primeira janela fora da tela de alvos; se roubar o foco, o texto vai para lugar errado (D-08, risco P-02). |
| `Sources/JoystickAIPoC/Palette/PaletteActions.swift` | `action-mapping` RF-09 (texto) | componente-novo | HIGH | Digita no aplicativo em foco e agenda o Enter; intervalo padrão ainda pendente da sonda P-01 (T021). |
| `Sources/JoystickAIPoC/Pointer/ShortcutActions.swift` | `action-mapping` §8, EC-05 | regra-alterada | MEDIUM | Executa `.openPalette` soltando antes as teclas mantidas; usa `KeyRepeat`. |
| `Sources/JoystickAIPoC/Pointer/InputRouter.swift` | `controller-input` §8 (destino das entradas) | regra-alterada | HIGH | Com a paleta aberta, os botões deixam de chegar a `ShortcutActions`; cliques e movimento continuam. Erro aqui suspenderia atalhos ou cliques. |
| `Sources/JoystickAIPoC/App/InjectionGate.swift` | `app-shell` EC (permissão revogada) | regra-alterada | MEDIUM | Fecha a paleta antes de suspender a injeção. |
| `Sources/JoystickAIPoC/App/AppDelegate.swift` | `app-shell` RF-01 (composição) | regra-alterada | MEDIUM | Injetor de teclado único, criação do painel e da paleta, erros de argumento da paleta separados dos da tela de alvos, bloqueio durante a tela de alvos. |
| `Tests/JoystickCoreTests/CommandPaletteTests.swift` | testes | componente-novo | LOW | Lista e transições da máquina. |
| `Tests/JoystickCoreTests/ShortcutMapperTests.swift` | testes | regra-alterada | LOW | PS retirado dos botões sem tecla; teste de RN-01. |
| `Tests/JoystickCoreTests/LaunchArgumentsTests.swift`, `LogEventCatalogTests.swift` | testes | regra-nova | LOW | Argumento novo e privacidade dos eventos da paleta. |

## Diff conceitual por componente

**Protótipo de atalhos (`action-mapping` §8).** Antes, PS não produzia nada em nenhuma camada. Agora abre a paleta na camada base e com L1 ou L2 segurados; com Options segurado continua sem efeito. A abertura solta teclas e o Command de Options antes de a paleta assumir os botões, de modo que nenhuma tecla fica presa na troca de destino.

**Destino das entradas.** O `InputRouter` passou a ter dois modos. Com a paleta fechada, nada muda. Com a paleta aberta, os botões vão à `PaletteActions`, que reage só a ↑, ↓, ✕, ○ e PS, enquanto `ButtonActions` e `MotionLoop` seguem recebendo tudo. A desconexão fecha a paleta antes de soltar botões e teclas.

**Digitação.** A paleta reutiliza `KeyboardInjector.type`, com o mesmo método de caracteres Unicode do `CONTINUAR`, e o mesmo injetor de `ShortcutActions`, para que a contagem de modificadores seja única. O Enter pode ser adiado por `--palette-enter-delay-ms`; o padrão provisório é 0.

**Interface.** Surge um painel não ativador em `.statusBar`, oculto por padrão, que ignora o mouse. É a primeira superfície visual do app fora da tela de alvos.

**Log.** Acréscimo de `palette.opened`, `palette.confirmed`, `palette.closed`, `palette.blocked` e `palette.invalid_args`, todos com índice ou motivo, nunca com texto.

## Preservadas

Não há regras 🟢 extraídas por `/reversa` para listar. Por observação da feature 001, permanecem sem alteração: leitura do controle, controle ativo, cinemática do ponteiro, cliques, rolagem, configuração `pointer`, tela de alvos e os atalhos do protótipo diferentes de PS (verificado pelos testes existentes de `ShortcutMapperTests`, todos verdes).

## Modificadas

Não há regras 🟢 extraídas. A única regra observada que muda é a do protótipo EXP-01 registrada no adendo da 001: "PS não gera tecla" passa a "PS abre a paleta".
