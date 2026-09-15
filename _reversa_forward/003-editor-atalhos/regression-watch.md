# Regression watch: Editor de atalhos e comandos

> Identificador: `003-editor-atalhos`
> Feature greenfield: não há regras 🟢 extraídas de código para vigiar. O watch principal fica vazio; os requisitos implementados estão em "Observações", sem peso de regressão, até que uma futura extração `/reversa` sobre o código os confirme como 🟢.

## Watch principal

| ID | Origem (arquivo, seção) | Regra esperada após mudança | Tipo de verificação | Sinal de violação |
|----|--------------------------|------------------------------|---------------------|-------------------|

## Observações

Itens implementados na rodada 1 (2026-09-14), com testes automatizados verdes e verificação no hardware pendente dos portões PM-1a e PM-2.

| ID | Origem (arquivo, seção) | Regra esperada | Tipo de verificação | Sinal de violação |
|----|--------------------------|----------------|---------------------|-------------------|
| W001 | `requirements.md` RF-07, RN-12; `roadmap.md` D-13 | A paleta termina na entrada fixa "Editar atalhos", separada dos itens, fora da contagem de 1 a 50 e não gravada no arquivo. | presença | Entrada ausente, fora do fim da lista ou gravada em `palette.items`. |
| W002 | `requirements.md` RF-07; `roadmap.md` D-13 | Confirmar "Editar atalhos" abre o editor sem digitar nada, sem `palette.confirmed` e sem mudar o último item confirmado. | presença | Texto digitado no aplicativo anterior, ou `palette.confirmed` com índice 18. |
| W003 | `requirements.md` RF-06; `roadmap.md` D-18 | Ícone na barra de menus com "Editar atalhos" e "Sair"; "Sair" solta teclas e botões mantidos. | presença | Ícone ausente, ou tecla presa depois de "Sair". |
| W004 | `requirements.md` RF-19; `roadmap.md` D-23 | O editor abre em primeiro plano e, ao fechar, devolve o foco ao aplicativo que estava em foco na abertura. | presença | Janela atrás do terminal, `editor.activation_failed` recorrente, ou terminal sem foco depois de fechar. |
| W005 | `requirements.md` RN-15; `roadmap.md` D-22 | A gravação de acorde só captura com a gravação ligada e a janela do editor em foco, por monitor local, e descarta teclas injetadas pelo app. | presença | `addGlobalMonitorForEvents` no código, captura com a janela sem foco, ou Enter do controle gravado. |
| W006 | `requirements.md` RN-14; `interfaces/diagnostic-log.md` §2, §4 | Eventos `shortcuts.*`, `shortcut.triggered` e `editor.*` sem texto, rótulo, nome de tecla nem acorde. | presença | Qualquer desses valores numa linha do log. |
| W007 | `requirements.md` RNF de legibilidade; `roadmap.md` D-19 | Editor com texto de pelo menos 24 pt e alvos de clique com pelo menos 44 pt no menor lado. | presença | Constantes de `EditorMetrics` abaixo desses valores sem decisão registrada no PM-1a. |
| W008 | `requirements.md` RN-12; `data-delta.md` §3 | `PaletteItem` tem rótulo opcional; vazio exibe o texto. | presença | Rótulo vazio exibido em branco, ou texto exibido com rótulo preenchido. |

## Histórico de re-extrações

## Arquivadas
