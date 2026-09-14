# Regression watch: Prova de conceito de entrada do controle e apontamento

> Identificador: `001-poc-entrada-ponteiro`
> Feature greenfield: não há regras 🟢 extraídas de código para vigiar. O watch principal fica vazio; os requisitos implementados estão em "Observações", sem peso de regressão, até que uma futura extração `/reversa` sobre o código novo os confirme como 🟢.

## Watch principal

| ID | Origem (arquivo, seção) | Regra esperada após mudança | Tipo de verificação | Sinal de violação |
|----|--------------------------|------------------------------|---------------------|-------------------|

## Observações

Itens implementados na rodada 1 (2026-09-14). Todos vêm de specs 🟡 PLANEJADO ou de decisões do usuário registradas no `requirements.md`; nenhum tem peso de regressão.

| ID | Origem (arquivo, seção) | Regra esperada | Tipo de verificação | Sinal de violação |
|----|--------------------------|----------------|---------------------|-------------------|
| W001 | `requirements.md` RN-02, RF-06; `controller-input.md` RF-05 | Valores absolutos abaixo da zona morta (padrão 0,12) valem 0,0; o curso máximo resulta em 1,0. | presença | `Normalization.applyDeadzone` reescalonando ou zona morta radial. |
| W002 | `requirements.md` RN-03, RF-07; `controller-input.md` RF-06 | L2 e R2 pressionados a partir de 0,5, sem histerese. | presença | Limiar diferente de 0,5 ou histerese sem decisão registrada (R-07). |
| W003 | `requirements.md` RN-01, RF-09; `controller-input.md` RF-08 | Um único controle ativo, o primeiro DualSense; outros modelos ignorados; conexão repetida do mesmo controle descartada (D-25). | presença | Dois controles ativos ou o mesmo controle registrado duas vezes. |
| W004 | `requirements.md` RN-04, RF-10; `controller-input.md` EC-01 | Na desconexão do ativo, `buttonUp` sintético para cada botão pressionado antes de `controllerDisconnected`. | presença | Desconexão sem soltura sintética ou fora dessa ordem. |
| W005 | `requirements.md` RF-03; `roadmap.md` D-25 | `atStartup` verdadeiro para a enumeração inicial ou notificação nos primeiros 2 s do processo. | presença | Janela diferente de 2 s ou enumeração classificada como posterior. |
| W006 | `requirements.md` RN-07, RF-13; `pointer-control.md` RF-03 | Velocidade `stickMaxSpeed · m^stickExponent`, com `m` limitado a 1 e Y invertido para a tela. | presença | Velocidade linear, sem limite na diagonal ou eixo Y sem inversão. |
| W007 | `requirements.md` RN-05, RF-08, RF-12; `pointer-control.md` RF-01, EC-03 | Touchpad relativo, só pelo primeiro dedo, com a primeira amostra de cada toque descartada; `Δpt = Δnorm · 400 · touchpadSensitivity`. | presença | Cursor saltando ao pousar o dedo ou segundo dedo movendo junto com o primeiro. |
| W008 | `requirements.md` RN-06, RF-20; `roadmap.md` D-11 | Um único temporizador de 120 Hz, ligado por qualquer dos dois analógicos e parado só com ambos em repouso; deltas de toque somados no tick. | presença | Dois laços concorrentes ou ticks com os analógicos em repouso. |
| W009 | `requirements.md` RN-08, RF-19; `pointer-control.md` RF-09 | Precisão (0,3) só com L1 pressionado e nenhum outro botão. | redação | Precisão ativa com L1 somado a outro botão, sem decisão do `/reversa-sync` sobre R-06. |
| W010 | `requirements.md` RN-09, RF-18; `pointer-control.md` RF-08 | Duplo clique em até `doubleClickIntervalMs` e a no máximo 4 pt. | presença | `clickState` 2 fora do intervalo ou da distância. |
| W011 | `requirements.md` RN-11, RF-15, RF-16 | R2 e clique do touchpad compartilham o botão esquerdo; R1 é o direito; `mouseUp` esquerdo só quando ambos soltam. | presença | Clique esquerdo liberado com um dos dois ainda pressionado. |
| W012 | `requirements.md` RN-10, RF-21; `pointer-control.md` RF-12 | Cursor limitado à união dos retângulos das telas, não ao retângulo envolvente. | presença | Cursor parado num vão sem tela em arranjo em L. |
| W013 | `requirements.md` RF-14; `roadmap.md` D-13 | Rolagem proporcional à inclinação, a `scrollSpeed` linhas/s, 20 px por linha na unidade pixel. | presença | Conversão diferente de 20 px por linha ou rolagem não proporcional. |
| W014 | `requirements.md` RF-26; `interfaces/config-pointer.md` | Seção `pointer` lida ao iniciar, arquivo nunca criado, faixas de RF-26, JSON inválido com linha e padrões. | presença | Arquivo criado pela PoC, faixa divergente ou erro sem linha quando o Foundation a fornece. |
| W015 | `requirements.md` RN-12, RF-11; `interfaces/diagnostic-log.md` §3 | Nenhum evento do log contém coordenadas do cursor, deltas, posições do toque ou valores de eixo; `position` só em `controller.queued`, como ordinal. | ausência | Chaves `x`, `y`, `dx`, `dy`, `location` ou `value` em qualquer evento. |
| W016 | `requirements.md` RF-27; `interfaces/target-run-result.md` §3 | Resultado com `schemaVersion` 1, as chaves do contrato, 20 alvos de 16 × 16 pt com margem de 40 pt e posições reproduzíveis pela semente. | presença | Chave ausente ou renomeada, ou mesma semente gerando posições diferentes. |
| W017 | `requirements.md` RF-25; `interfaces/diagnostic-log.md` §4 | `poc-tools` calcula cobertura "N de 18" sem sintéticos, p50 e p95 por posição mais próxima e ciclos completos. | presença | Eventos sintéticos contados na cobertura ou percentil por interpolação sem registro. |
| W018 | `requirements.md` RNF de empacotamento e de operação; `roadmap.md` D-01, D-02 | O app é assinado com identidade fixa e instalado em `~/Applications/JoystickAIPoC.app`; assinatura *ad hoc* é recusada. | presença | `build-app.sh` aceitando `-` ou instalando em outro caminho. |

Itens implementados na rodada 2 (2026-09-14), mesma condição: sem peso de regressão.

| ID | Origem (arquivo, seção) | Regra esperada | Tipo de verificação | Sinal de violação |
|----|--------------------------|----------------|---------------------|-------------------|
| W019 | `requirements.md` RF-01 a RF-04; `roadmap.md` D-04, D-25 | `shouldMonitorBackgroundEvents` ligado antes dos observadores, e observadores registrados antes de percorrer `GCController.controllers()`, com todo acesso ao registro na fila `input`. | presença | Enumeração antes dos observadores ou *handlers* fora da fila `input`. |
| W020 | `requirements.md` RF-01; `roadmap.md` D-07 | O transporte vem do IORegistry sem abrir o dispositivo HID; ambiguidade resulta em `unknown`. | ausência | `IOHIDDeviceOpen` ou `IOHIDManagerOpen` no `TransportResolver`. |
| W021 | `requirements.md` RF-05, RF-07; `roadmap.md` D-06 | Os 18 botões seguem o mapeamento de D-06, e só as entradas do controle ativo geram `input.button` e entrega. | presença | Botão sem *handler* ou evento de um controle na fila. |
| W022 | `requirements.md` RN-12, RF-08; `roadmap.md` D-05 | Leitura de analógicos e toque não escreve valores de eixo nem posições no log; a via do toque é registrada uma vez por conexão. | ausência | `valueChangedHandler` de analógico ou touchpad chamando o log com valores. |
| W023 | `requirements.md` RF-24; `roadmap.md` D-23 | Supressão de gestos pedida só em `buttonHome`, com `controller.gesture_suppression` em nível `info` em toda conexão. | presença | `preferredSystemGestureState` alterado em outro elemento ou evento só com `--debug`. |
| W024 | `actions.md`, notas do PM-2; `roadmap.md` D-05, D-07 | Toda conexão Bluetooth de DualSense lê o relatório de recurso `0x05` e registra `controller.extended_report`; sem isso o touchpad não chega. | presença | Conexão Bluetooth sem `controller.extended_report` ou `input.touch` ausente com toque no touchpad. |
| W025 | `actions.md`, notas do PM-2; `roadmap.md` D-06 | O PS vem do relatório HID bruto, e dos relatórios só o bit do PS é examinado. | presença | `ps` ausente em `poc-tools buttons` ou leitura de outros campos do relatório bruto sem decisão registrada. |

Itens implementados na rodada 3 (2026-09-14), mesma condição: sem peso de regressão.

| ID | Origem (arquivo, seção) | Regra esperada | Tipo de verificação | Sinal de violação |
|----|--------------------------|----------------|---------------------|-------------------|
| W026 | `requirements.md` RF-15 a RF-18; `roadmap.md` D-10 | Todo evento postado pela PoC leva a marca `EventInjector.sourceMark` em `eventSourceUserData` e sai em `.cghidEventTap`. | presença | `CGEvent.post` fora de `EventInjector.deliver` ou sem a marca. |
| W027 | `actions.md`, notas da rodada 3; `roadmap.md` D-10 | A posição de partida das emissões consecutivas vem da posição acompanhada enquanto o sistema não refletir o evento anterior. | presença | Touchpad movendo só num eixo ou movimento horizontal desfeito ao retirar o dedo. |
| W028 | `actions.md`, notas da rodada 3; `roadmap.md` D-05, D-12 | Amostra do touchpad em que um eixo entra ou sai do zero exato com o outro igual não gera deslocamento. | presença | Salto vertical ao pousar o dedo ou horizontal ao retirá-lo. |
| W029 | `requirements.md` RF-22; `roadmap.md` D-15 | Ao perder a Acessibilidade, os botões de mouse são soltos antes de desativar a injeção, com `pointer.injection_suspended`. | presença | Botão preso após reconceder a permissão. |
| W030 | `requirements.md` RF-23; `roadmap.md` D-16 | Sair e os sinais `SIGTERM`, `SIGINT` e `SIGHUP` soltam os botões, registram `app.terminating` uma única vez e descarregam o log. | presença | Encerramento sem `app.terminating` ou com dois registros. |
| W031 | `requirements.md` RF-27; `interfaces/target-run-result.md` §2 | Só cliques com a marca da PoC encerram uma tentativa; os físicos entram em `ignoredPhysicalClicks`. | presença | Clique do mouse físico contado como tentativa. |

Itens do PM-3 (2026-09-14), mesma condição: sem peso de regressão. W011 continua como registro histórico; W032 descreve o mapeamento em vigor.

| ID | Origem (arquivo, seção) | Regra esperada | Tipo de verificação | Sinal de violação |
|----|--------------------------|----------------|---------------------|-------------------|
| W032 | `actions.md`, notas do PM-3; pedido do usuário sobre RN-11 e D-06 | R1 e o clique do touchpad compartilham o botão esquerdo; R2 é o direito. | presença | R2 gerando clique esquerdo ou R1 abrindo menu de contexto. |
| W033 | `actions.md`, notas do PM-3 (EXP-01); `action-mapping` §8, EC-04, EC-05 | Atalhos do protótipo decididos no pressionar, teclas e Command soltos na desconexão, no encerramento e na suspensão, e nenhuma tecla ou texto no log. | presença | Tecla ou Command preso após desconectar ou encerrar, ou texto digitado aparecendo no log. |
| W034 | `validation-report.md` P-08; `requirements.md` RF-22; `roadmap.md` D-15 | A Acessibilidade é consultada por `AXIsProcessTrusted()`, e a retomada repete as solturas de mouse e teclas feitas na suspensão. | presença | Volta a `CGPreflightPostEventAccess()` ou revogação com o app aberto sem `pointer.injection_suspended`. |

## Histórico de re-extrações

## Arquivadas
