# Adendo: Prova de conceito de entrada do controle e apontamento

> Identificador: `001-poc-entrada-ponteiro`
> Data: 2026-09-14
> Cenário: greenfield

## Vigência

Vigente desde 2026-09-14.

## Resumo da entrega

A feature entrega uma prova de conceito para macOS que lê o DualSense com outro aplicativo em primeiro plano e o converte em mouse. O touchpad e o analógico esquerdo movem o cursor, o analógico direito rola e os botões clicam e arrastam. O objetivo é validar, antes do restante do MVP, as premissas de precisão do apontamento e de acesso ao hardware com injeção de eventos. Acompanham a PoC uma tela de alvos, um log de diagnóstico sem coordenadas e o `poc-tools`, que produz os números do relatório de validação.

As 79 ações de `actions.md` estão concluídas. O portão manual PM-3 ficou parcial: o roteiro do ponteiro, os parâmetros sem recompilar, a CPU em repouso e a privacidade do log foram verificados, e faltam a tela de alvos, a confirmação no VS Code, a latência, a CPU em movimento e os 100 ciclos. Durante o PM-3, a pedido do usuário, entraram também um protótipo de atalhos de teclado (EXP-01, fora do escopo), a inversão de R1 e R2 e a correção da detecção de revogação da Acessibilidade.

## Impacto por artefato da extração

| Artefato | Seção | Tipo de impacto | Delta |
|----------|-------|-----------------|-------|
| `_reversa_sdd/prd.md` | `#4. Escopo (in)` | componente-novo | Conexão do DualSense e controle como mouse existem como PoC (`Sources/JoystickCore`, `Sources/JoystickAIPoC`), ainda sem menu, ícone, ditado nem mapeamento configurável. |
| `_reversa_sdd/prd.md` | `#8. Riscos` | componente-novo | Os riscos de precisão e de acesso ao hardware passam a ter medições no `validation-report.md` da feature; a premissa de acesso ao hardware tem evidência ampla, e a de precisão ainda depende da tela de alvos. |
| `_reversa_sdd/sdd/controller-input.md` | `#6. Requisitos Funcionais` | componente-novo | RF-01 a RF-09 implementados, com 18 de 18 botões lidos em segundo plano por Bluetooth, controle ativo único, adoção ao iniciar e soltura sintética na desconexão. |
| `_reversa_sdd/sdd/controller-input.md` | `#10. Integrações e Dependências` | regra-alterada | O dispositivo HID passa a ser aberto pelo `IOHIDManager`: por Bluetooth o touchpad só chega depois de ler o relatório de recurso `0x05`, e o PS vem do relatório bruto, pois o macOS o retém antes do GameController (diverge de D-07). |
| `_reversa_sdd/sdd/controller-input.md` | `#14. Open Questions` | componente-novo | OQ-01 respondida: o botão de mudo não é exposto; além disso, `touchpads` vem vazio, o estado de toque é inferido pela volta a (0, 0), e o PS exige "Pressione o Botão de Início para abrir" em "Nenhum" nos Ajustes do Sistema. |
| `_reversa_sdd/sdd/pointer-control.md` | `#6. Requisitos Funcionais` | componente-novo | RF-01 a RF-09 e RF-12 implementados e verificados no hardware: 1.500 pt/s na inclinação máxima, precisão de 29,7% com L1, duplo clique, arraste, rolagem e limite nas bordas. |
| `_reversa_sdd/sdd/pointer-control.md` | `#8. Design e Interface` | regra-alterada | R1 e o clique do touchpad fazem o botão esquerdo, e R2 o direito, invertendo o mapeamento previsto, por pedido do usuário no PM-3. |
| `_reversa_sdd/sdd/pointer-control.md` | `#9. Modelo de Dados` | delta-de-dados | Os parâmetros ganharam as faixas de validação da feature; `scrollSpeed` padrão de 40 linhas/s não alcança o fim de 1.000 linhas em 10 s, e o valor calibrado de 100 está só na configuração local do avaliador. |
| `_reversa_sdd/sdd/pointer-control.md` | `#10. Integrações e Dependências` | regra-nova | O GameController entrega os eixos do touchpad um de cada vez e `CGEvent(source: nil).location` não reflete o evento recém-postado; o ponteiro descarta as amostras intermediárias e acompanha a própria posição postada. |
| `_reversa_sdd/sdd/pointer-control.md` | `#11. Edge Cases e Tratamento de Erros` | regra-alterada | EC-01 depende de `AXIsProcessTrusted()`, pois `CGPreflightPostEventAccess()` continua verdadeiro após a revogação com o app aberto; na retomada, as solturas de mouse e teclas são repetidas. |
| `_reversa_sdd/sdd/action-mapping.md` | `#8. Design e Interface` | componente-novo | Existe um protótipo de mapeamento fixo (setas, Enter, Esc, Backspace, Tab, L1+✕ `CONTINUAR`, L1+△ Shift+Tab), com divergências: Create abre o Mission Control, L2 é modificador de mesas e janelas, Options segurado alterna aplicativos e R3 envia Command+M. |
| `_reversa_sdd/sdd/action-mapping.md` | `#9. Modelo de Dados` | delta-de-contrato-externo | A PoC lê só a seção `pointer` de `~/.config/joystick-ai/config.json` e nunca cria o arquivo, ao contrário de RF-02 da spec; os atalhos de sistema vêm de `com.apple.symbolichotkeys`, e não do JSON. |
| `_reversa_sdd/sdd/voice-dictation.md` | `#6. Requisitos Funcionais` | regra-alterada | Não há ditado implementado; no protótipo, R3 aciona por Command+M o transcritor do Raycast configurado pelo usuário, e não L2 com `dictation.shortcut`. |
| `_reversa_sdd/sdd/app-shell.md` | `#6. Requisitos Funcionais` | delta-de-contrato-externo | RF-12 existe como log JSON Lines em `~/Library/Logs/joystick-ai/`, sem coordenadas nem teclas, com o evento `controller.extended_report` fora do contrato `interfaces/diagnostic-log.md` e `position` ordinal só em `controller.queued`. |
| `_reversa_sdd/sdd/app-shell.md` | `#11. Edge Cases e Tratamento de Erros` | regra-nova | EC-01 fica mitigado pela identidade local autoassinada "JoystickAI Local Signing", que mantém a Acessibilidade entre recompilações. |
| `_reversa_sdd/sdd/app-shell.md` | `#14. Open Questions` | componente-novo | OQ-01 respondida: Input Monitoring não é necessário, bastando a Acessibilidade para ler o controle em segundo plano; OQ-03 resolvida pelo certificado autoassinado, sem conta de desenvolvedor. |

## Regras sob vigilância

W001 a W034, em [`_reversa_forward/001-poc-entrada-ponteiro/regression-watch.md`](../../_reversa_forward/001-poc-entrada-ponteiro/regression-watch.md), todos na seção "Observações", sem peso de regressão até uma re-extração confirmá-los.

## Fontes

- `_reversa_forward/001-poc-entrada-ponteiro/legacy-impact.md`
- `_reversa_forward/001-poc-entrada-ponteiro/regression-watch.md`
- `_reversa_forward/001-poc-entrada-ponteiro/requirements.md`
- `_reversa_forward/001-poc-entrada-ponteiro/progress.jsonl`
- `_reversa_forward/001-poc-entrada-ponteiro/actions.md` (notas do PM-2, da rodada 3 e do PM-3)
- `_reversa_forward/001-poc-entrada-ponteiro/validation-report.md`
