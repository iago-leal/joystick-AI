# Impacto no legado: Editor de atalhos e comandos

> Identificador: `003-editor-atalhos`
> Data: `2026-09-14`
> Feature greenfield, sem legado extraído por `/reversa`. Âncora: prd.md + specs SDD, mais o código entregue pelas features 001 e 002 (`_reversa_sdd/addenda/001-poc-entrada-ponteiro.md`, `_reversa_sdd/addenda/002-paleta-comandos.md`).
> Política de edição no momento da execução: `allowLegacyEdits: true`, `allowedPaths` vazio (liberação irrestrita do projeto)
> Execução: parcial; rodada 1 (16 de 76 ações: T001 a T014, T019 e T076) até o portão manual PM-1a

Não há `architecture.md` nem `domain.md`; os componentes citam as specs em `_reversa_sdd/sdd/`, e os tipos de impacto refletem a mudança sobre o código das features 001 e 002. Esta rodada entrega só a preparação: tipos de configuração ainda sem uso pelo mapeador, eventos de log ainda não emitidos (exceto `editor.*`), e o editor mínimo das sondas.

## Arquivos afetados

| Arquivo afetado | Componente | Tipo | Severidade | Justificativa |
|-----------------|------------|------|------------|---------------|
| `Sources/JoystickCore/Shortcuts/KeyCatalog.swift` | `action-mapping` §9 (modelo de dados) | componente-novo | LOW | Tabela nome ↔ tecla virtual para arquivo e editor; ainda usada só na exibição do acorde gravado. |
| `Sources/JoystickCore/Shortcuts/ShortcutMapper.swift` | `action-mapping` §8 | regra-nova | LOW | `SystemShortcut` ganha nome estável e rótulo; o mapeamento fixo não muda nesta rodada. |
| `Sources/JoystickCore/Config/ShortcutConfig.swift` | `action-mapping` §9 | componente-novo | LOW | `TriggerAction`, `ShortcutConfig`, `ShortcutsDocument` e `ShortcutIssue`, sem uso em execução ainda. |
| `Sources/JoystickCore/Palette/CommandPalette.swift` | `action-mapping` §8 (paleta) | regra-alterada | MEDIUM | `PaletteItem` ganha rótulo; `CommandPalette` passa a `PaletteDefaults`; a máquina acrescenta a entrada fixa "Editar atalhos", que produz `openEditor` sem digitar; motivo `config_changed` declarado. |
| `Sources/JoystickCore/Log/LogEventCatalog.swift` | `app-shell` RF-12 (log) | delta-de-contrato-externo | LOW | Fábricas `shortcuts.*`, `shortcut.triggered` e `editor.*`; nesta rodada só `editor.opened`, `editor.closed` e `editor.activation_failed` são emitidos. `logSchema` mantido em 1. |
| `Sources/JoystickAIPoC/Palette/PaletteActions.swift` | `action-mapping` §8 (paleta) | regra-alterada | MEDIUM | Confirmar "Editar atalhos" chama `onOpenEditor` na main thread e não registra `palette.confirmed`. |
| `Sources/JoystickAIPoC/Palette/PalettePanel.swift` | `app-shell` §8 | regra-alterada | MEDIUM | O painel desenha a entrada fixa separada por uma linha, usa o rótulo quando houver e trunca textos mais largos que a tela. |
| `Sources/JoystickAIPoC/Editor/EditorWindowController.swift` | `app-shell` §8, NG-03 (revogado) | componente-novo | HIGH | Primeira janela que ativa o app: rouba o foco de propósito ao abrir e o devolve ao fechar; se a ativação falhar, o editor abre atrás do terminal (sonda P-01). |
| `Sources/JoystickAIPoC/Editor/KeyCaptureField.swift` | `app-shell` §12 (privacidade) | componente-novo | HIGH | Primeiro ponto do app que lê o teclado físico; restrito à janela em foco e à gravação ativa, com descarte das teclas injetadas (RN-15, sonda P-02). |
| `Sources/JoystickAIPoC/Editor/EditorMetrics.swift` | `app-shell` §8 | componente-novo | LOW | Métricas e estilos de TV do editor. |
| `Sources/JoystickAIPoC/Editor/EditorProbeView.swift` | sondas do PM-1a | componente-novo | LOW | Conteúdo provisório da janela, removido em T073. |
| `Sources/JoystickAIPoC/App/StatusMenu.swift` | `app-shell` RF-01, RF-08 | componente-novo | MEDIUM | Primeiro ícone na barra de menus, com "Editar atalhos" e "Sair". |
| `Sources/JoystickAIPoC/App/AppDelegate.swift` | `app-shell` RF-01 (composição) | regra-alterada | MEDIUM | Cria o ícone e a janela do editor e liga a entrada fixa da paleta à abertura; usa `PaletteDefaults`. |
| `Tests/JoystickCoreTests/CommandPaletteTests.swift` | testes | regra-alterada | LOW | Volta circular passa pela entrada fixa; testes de rótulo, `config_changed`, `openEditor` e lista configurada. |
| `Tests/JoystickCoreTests/LogEventCatalogTests.swift` | testes | regra-alterada | LOW | Só a troca de `CommandPalette` por `PaletteDefaults`. |

## Diff conceitual por componente

**Paleta.** A lista padrão é a mesma, agora chamada `PaletteDefaults`, e cada item aceita um rótulo, vazio por padrão. Depois dos 17 itens vem a entrada fixa "Editar atalhos": ↑ no primeiro item leva a ela, e ↓ nela volta ao primeiro. Confirmá-la fecha a paleta e abre o editor, sem digitar nada e sem mudar o último item confirmado. Os eventos `palette.*` seguem iguais; a abertura do editor é registrada como `editor.opened { source: palette }`.

**Interface do app.** Antes, a única superfície permanente era o painel não ativador da paleta. Agora há um ícone na barra de menus e uma janela SwiftUI que, ao contrário do painel, ativa o app para receber teclado e ditado e devolve o foco ao aplicativo anterior ao fechar. Nesta rodada a janela mostra só o editor mínimo das sondas.

**Teclado físico.** O app passa a ler teclas do teclado físico, mas só com a janela do editor em foco e a gravação ligada, por monitor local; teclas injetadas pelo controle são descartadas. Nenhuma tecla capturada é registrada no log.

**Modelo de configuração.** Os tipos de mapeamento em camadas, o catálogo de teclas e os eventos de configuração existem, mas o `ShortcutMapper` ainda usa o mapeamento fixo e o arquivo continua lido só para `pointer`. Nada muda no comportamento dos atalhos.

## Preservadas

Não há regras 🟢 extraídas por `/reversa` para listar. Por observação das features 001 e 002, permanecem sem alteração nesta rodada: leitura do controle, cinemática do ponteiro, cliques, rolagem, configuração `pointer`, tela de alvos, todos os atalhos do protótipo (`ShortcutMapperTests` inalterado e verde), abertura da paleta por PS, painel sem roubo de foco, fechamento da paleta por ○, PS, desconexão, suspensão e inatividade, e o log sem texto de item.

## Modificadas

Não há regras 🟢 extraídas. Mudam, por decisão registrada no `requirements.md` da feature, duas regras observadas no adendo da 002: a seleção circular da paleta passa a incluir a entrada fixa "Editar atalhos" (RN-12, RF-07), e `app-shell` NG-03 (sem tela de mapeamentos) deixa de valer com a janela do editor.
