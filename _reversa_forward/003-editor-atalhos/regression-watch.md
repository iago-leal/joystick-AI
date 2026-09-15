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
| W002 | `requirements.md` RF-07; `roadmap.md` D-13 | Confirmar "Editar atalhos" abre o editor acima das demais janelas (E003), sem digitar nada, sem `palette.confirmed` e sem mudar o último item confirmado. | presença | Texto digitado no aplicativo anterior, ou `palette.confirmed` com índice 18. |
| W003 | `requirements.md` RF-06; `roadmap.md` D-18 | Ícone na barra de menus com "Editar atalhos" e "Sair"; "Sair" solta teclas e botões mantidos. | presença | Ícone ausente, ou tecla presa depois de "Sair". |
| W004 | `requirements.md` RF-19; `roadmap.md` D-23 | O editor abre em primeiro plano e, ao fechar, devolve o foco ao aplicativo que estava em foco na abertura. | presença | Janela atrás do terminal, `editor.activation_failed` recorrente, ou terminal sem foco depois de fechar. |
| W005 | `requirements.md` RN-15; `roadmap.md` D-22 | A gravação de acorde só captura com a gravação ligada e a janela do editor em foco, por monitor local, e descarta teclas injetadas pelo app. | presença | `addGlobalMonitorForEvents` no código, captura com a janela sem foco, ou Enter do controle gravado. |
| W006 | `requirements.md` RN-14; `interfaces/diagnostic-log.md` §2, §4 | Eventos `shortcuts.*`, `shortcut.triggered` e `editor.*` sem texto, rótulo, nome de tecla nem acorde. | presença | Qualquer desses valores numa linha do log. |
| W007 | `requirements.md` RNF de legibilidade; `roadmap.md` D-19 | Editor com texto de pelo menos 24 pt e alvos de clique com pelo menos 44 pt no menor lado. | presença | Constantes de `EditorMetrics` abaixo desses valores sem decisão registrada no PM-1a. |
| W008 | `requirements.md` RN-12; `data-delta.md` §3 | `PaletteItem` tem rótulo opcional; vazio exibe o texto. | presença | Rótulo vazio exibido em branco, ou texto exibido com rótulo preenchido. |

Itens implementados na rodada 7 (2026-09-15), com testes automatizados verdes onde a regra está em `JoystickCore`; a observação do arquivo aguarda P-04 (PM-1b), e os cenários do editor, o PM-2.

| ID | Origem (arquivo, seção) | Regra esperada | Tipo de verificação | Sinal de violação |
|----|--------------------------|----------------|---------------------|-------------------|
| W009 | `requirements.md` RF-01, RN-11 | Sem arquivo ou sem as seções, vale o padrão: ✕ Enter, L1+✕ `CONTINUAR` com Enter, L2+← mesa à esquerda, PS abre a paleta de 17 itens; o arquivo não é criado. | presença | Atalho do protótipo diferente sem arquivo, ou `config.json` criado sem salvar pelo editor. |
| W010 | `requirements.md` RN-01 a RN-05; `roadmap.md` D-09 | Herança da base nas camadas; vale a camada do modificador segurado há mais tempo; a ação acompanha o botão até ele ser solto; R1, R2 e o clique do touchpad não mudam. | presença | `ShortcutMapperTests` vermelho, tecla presa ao soltar o modificador antes do botão, ou R1 sem clicar com arquivo que o cite. |
| W011 | `requirements.md` RF-03, RF-04, RN-08; `roadmap.md` D-15, D-16 | Alteração externa válida aplicada em até 1 s sem reiniciar; inválida mantém a vigente, registra `shortcuts.invalid` com a linha e põe o alerta no menu (RF-20). | presença | Falta de `shortcuts.loaded { external }` após gravar, atalhos trocados por leitura inválida, ou alerta que não some depois de corrigir. |
| W012 | `requirements.md` RF-05, RN-10; `roadmap.md` D-17 | Gravar pelo editor substitui só `shortcuts` e `palette`, preserva `pointer` e as demais chaves, escreve de forma atômica através de *link* simbólico e só copia para `.bak` com confirmação. | presença | `pointer` alterado ou perdido, *link* trocado por arquivo comum, ou `.bak` sem confirmação. |
| W013 | `requirements.md` RF-12, RN-08 | O editor não salva configuração com problemas e aponta cada gatilho ou item com problema. | presença | "Salvar" habilitado com problema listado, ou arquivo gravado recusado na releitura. |
| W014 | `requirements.md` RF-13; `roadmap.md` D-23 | Fechar com rascunho sujo pergunta Salvar, Descartar ou Cancelar; Cancelar mantém a janela e a alteração; `editor.closed` registra `saved`, `discarded` ou `clean`. | presença | Janela fechada sem pergunta, alteração perdida ao cancelar, ou `editor.closed { clean }` depois de descartar. |
| W015 | `requirements.md` RF-16, RN-16; `roadmap.md` D-24 | Com a identificação ligada, só R1, R2 e o clique do touchpad agem; ela desliga ao fechar a janela e ao perder o foco. | presença | Botão do controle executando atalho com o modo ligado, ou modo que continua ligado com a janela fechada. |
| W016 | `requirements.md` RF-18; `roadmap.md` D-25 | Alteração externa com rascunho sujo abre o aviso Recarregar ou Manter e não sobrescreve nada sem escolha. | presença | Rascunho substituído em silêncio, ou arquivo externo sobrescrito sem escolha. |
| W017 | `requirements.md` RN-14; `interfaces/diagnostic-log.md` §3 | Troca de configuração fecha a paleta com `config_changed` e a identificação com `identify`, sem texto de item no log. | presença | Paleta aberta com a lista antiga depois da troca, ou texto de item no log. |

## Histórico de re-extrações

## Arquivadas
