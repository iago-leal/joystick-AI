# Adendo: Editor de atalhos e comandos

> Identificador: `003-editor-atalhos`
> Data: 2026-09-15
> Cenário: greenfield

## Vigência

Vigente desde 2026-09-15.
Superado pela re-extração de 2026-09-15.

## Resumo da entrega

A feature permite que o programador de sofá personalize, sem mexer em código, o que cada botão do DualSense faz e quais comandos a paleta oferece. Atalhos e paleta deixam de ser fixos no código e passam a viver nas seções `shortcuts` e `palette` de `~/.config/joystick-ai/config.json`, editáveis por uma janela gráfica ou por qualquer editor de texto, com aplicação em até 1 s e sem reiniciar o app. Sem arquivo ou sem essas seções, vale um padrão equivalente ao protótipo das features 001 e 002. O editor abre por um ícone novo na barra de menus ou por "Editar atalhos", item fixo no fim da paleta.

As 76 ações de `actions.md` estão concluídas, assim como as emendas E003 (janela do editor flutuante, com clique de ativação na barra de título), E004 e E005 (correções de achados do PM-2); a E002 foi revogada pela E003. Os três portões manuais foram aprovados: PM-1a (ativação, captura de teclado, ditado e legibilidade), PM-1b (observação do arquivo, com releitura em até 280 ms para gravação no lugar, `vim`, `mv` e *link* simbólico) e PM-2 (31 cenários). No passo 31 do PM-2, a revogação da Acessibilidade não deixou Control preso, mas o botão foi solto antes de a suspensão ser detectada, de modo que a soltura das teclas no instante da suspensão não foi exercitada.

## Impacto por artefato da extração

| Artefato | Seção | Tipo de impacto | Delta |
|----------|-------|-----------------|-------|
| `_reversa_sdd/prd.md` | `#4. Escopo (in)` | componente-novo | "Configuração dos mapeamentos" está entregue: JSON com as seções `shortcuts` e `palette` e editor gráfico operável pelo controle; o formato deixa de ser indefinido e está em `interfaces/config-file.md` da feature. |
| `_reversa_sdd/sdd/action-mapping.md` | `#4. Non-Goals (Fora do Escopo)` | regra-removida | NG-01 deixou de valer: existe tela gráfica de configuração, e editar o JSON à mão continua possível. |
| `_reversa_sdd/sdd/action-mapping.md` | `#6. Requisitos Funcionais` | componente-novo | RF-01, RF-03 e RF-04 estão implementados: carga ao iniciar, observação do arquivo e do destino do *link* com releitura 150 ms após o último evento, e leitura inválida que mantém a configuração vigente e informa regra e linha. Mapeamento e paleta são validados em conjunto. |
| `_reversa_sdd/sdd/action-mapping.md` | `#6. Requisitos Funcionais` | regra-alterada | O modelo de ações difere do planejado: os tipos são `chord` (com `repeat` opcional), `systemShortcut`, `text` (com `pressEnter`), `openPalette` e `none`, em camadas por modificador com herança da base; não há `press`, `tap` nem `longPress`. RF-14 vale como "modificador não tem ação em nenhuma camada, nem `none`". |
| `_reversa_sdd/sdd/action-mapping.md` | `#8. Design e Interface` | regra-alterada | O mapeamento do protótipo virou dados (`ShortcutDefaults`), com o mesmo comportamento sem arquivo. Com dois modificadores segurados, vale a camada do segurado há mais tempo; R1, R2 e o clique do touchpad seguem fixos; uma troca de configuração interrompe a repetição e solta as teclas mantidas antes de valer. |
| `_reversa_sdd/sdd/action-mapping.md` | `#8. Design e Interface` | regra-alterada | A lista da paleta vem do arquivo, com 1 a 50 itens, rótulo opcional e Enter por item; o padrão são os 17 itens da feature 002, sem Enter. "Editar atalhos" fica fixo no fim, fora da contagem e do arquivo. Uma troca de configuração fecha a paleta aberta sem digitar. |
| `_reversa_sdd/sdd/action-mapping.md` | `#9. Modelo de Dados` | delta-de-dados | Surgem `shortcuts { version, modifiers, layers }` e `palette { version, items[{ label, text, pressEnter }] }`, com texto de até 1.000 caracteres numa linha, rótulo de até 80 e seção ausente valendo o padrão; contrato em `interfaces/config-file.md` da feature. |
| `_reversa_sdd/sdd/action-mapping.md` | `#11. Edge Cases e Tratamento de Erros` | regra-nova | Erro de sintaxe invalida o arquivo inteiro; remover o arquivo mantém a vigente até o próximo início; gravar pelo editor sobre arquivo com erro de sintaxe exige confirmar a cópia para `config.json.bak`. |
| `_reversa_sdd/sdd/action-mapping.md` | `#12. Segurança e Privacidade` | regra-nova | Os eventos de configuração, gatilho e editor registram caminho, linha, regra, botão, camada e tipo, nunca texto, rótulo, nome de tecla nem acorde. O teclado físico só é lido com a gravação de acorde ativa e a janela do editor em foco, e as teclas injetadas pelo app são descartadas. |
| `_reversa_sdd/sdd/app-shell.md` | `#4. Non-Goals (Fora do Escopo)` | regra-removida | NG-03 deixou de valer: existe tela de mapeamentos. |
| `_reversa_sdd/sdd/app-shell.md` | `#6. Requisitos Funcionais` | regra-alterada | O menu de RF-08 tem "Editar atalhos" e "Sair", e não "Abrir configuração" nem "Recarregar configuração", porque a recarga é automática; com arquivo inválido, o ícone mostra um alerta e o menu, "Configuração inválida: linha N", que abre o editor. |
| `_reversa_sdd/sdd/app-shell.md` | `#6. Requisitos Funcionais` | delta-de-contrato-externo | O log de RF-12 ganha `shortcuts.loaded`, `shortcuts.unchanged`, `shortcuts.invalid`, `shortcuts.file_removed`, `shortcuts.saved`, `shortcuts.save_failed`, `shortcuts.restored`, `shortcut.triggered` e `editor.*`, além dos motivos `config_changed` e `identify` em `palette.closed`; `logSchema` segue em 1. Contrato em `interfaces/diagnostic-log.md` da feature. |
| `_reversa_sdd/sdd/app-shell.md` | `#8. Design e Interface` | componente-novo | Há um ícone na barra de menus e uma janela SwiftUI em escala de TV (texto de 32 pt, alvos de 60 pt, mínimo de 1.400 × 800 pt), com abas Atalhos e Paleta, figura do controle, camadas, modo de identificação, faixas de conflito e erro e pergunta ao fechar com alterações. A janela ativa o app, abrindo no nível flutuante com clique de ativação, instala um menu Editar para colar e ditar e devolve o foco ao aplicativo anterior ao fechar. |
| `_reversa_sdd/sdd/app-shell.md` | `#9. Modelo de Dados` | delta-de-dados | O app passa a gravar `config.json`, só ao salvar pelo editor: substitui `shortcuts` e `palette`, preserva `pointer` e as demais chaves, escreve de forma atômica no destino do *link* e com chaves ordenadas. `pointer` continua lido só na abertura. |
| `_reversa_sdd/sdd/controller-input.md` | `#8. Design e Interface` | regra-alterada | Com o modo de identificação do editor ligado, os botões que não são R1, R2 nem o clique do touchpad vão só ao editor, para selecionar o cartão, e não executam atalhos; o modo desliga ao fechar a janela ou quando ela perde o foco. |

## Regras sob vigilância

W001 a W017, em [`_reversa_forward/003-editor-atalhos/regression-watch.md`](../../_reversa_forward/003-editor-atalhos/regression-watch.md), todos na seção "Observações", sem peso de regressão até uma re-extração confirmá-los. Os limites de W007 (24 pt e 44 pt) são pisos; o entregue é 32 pt e 60 pt, conforme o PM-1a.

## Fontes

- `_reversa_forward/003-editor-atalhos/legacy-impact.md`
- `_reversa_forward/003-editor-atalhos/regression-watch.md`
- `_reversa_forward/003-editor-atalhos/requirements.md`
- `_reversa_forward/003-editor-atalhos/progress.jsonl`
- `_reversa_forward/003-editor-atalhos/actions.md` (notas das rodadas 1 a 11 e emendas E002 a E005)
- `_reversa_forward/003-editor-atalhos/onboarding.md`
- `_reversa_forward/003-editor-atalhos/interfaces/config-file.md`
- `_reversa_forward/003-editor-atalhos/interfaces/diagnostic-log.md`
