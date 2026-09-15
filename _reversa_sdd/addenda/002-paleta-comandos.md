# Adendo: Paleta de comandos pelo controle

> Identificador: `002-paleta-comandos`
> Data: 2026-09-15
> Cenário: greenfield

## Vigência

Vigente desde 2026-09-15.
Superado pela re-extração de 2026-09-15.

## Resumo da entrega

A feature acrescenta ao app uma paleta de comandos: uma lista sobreposta à tela, aberta pelo botão PS do DualSense, da qual o programador de sofá escolhe com o direcional um comando do Reversa ou do Claude Code para digitá-lo no aplicativo em foco. Resolve a principal limitação de condução pelo controle, pois os comandos do Reversa só são acionados quando digitados literalmente com a barra. A lista é fixa, com 17 itens: `CONTINUAR`, os 13 comandos do Reversa e `/clear`, `/compact` e `/resume`. O editor visual de atalhos, a configuração persistida e a paleta editável ficaram para a feature seguinte, com o material preservado em `backlog-editor.md`.

As 22 ações de `actions.md` estão concluídas, assim como a emenda E001. Por essa emenda, pedida pelo usuário depois de testar a paleta, nenhum item envia Enter: confirmar só digita o texto, e o envio é um ✕ seguinte, o que permite acrescentar argumentos. O portão PM-1 ficou parcial: a sonda P-01 foi aprovada no Terminal com intervalo de 0 ms, e a P-02 (foco mantido, tela cheia e outra mesa) aguarda resultado. O roteiro de 18 passos do PM-2 ainda não foi executado.

## Impacto por artefato da extração

| Artefato | Seção | Tipo de impacto | Delta |
|----------|-------|-----------------|-------|
| `_reversa_sdd/prd.md` | `#4. Escopo (in)` | componente-novo | "Atalhos para o fluxo com agentes" existe também como paleta de comandos com lista fixa de 17 itens, digitados sem Enter; "Configuração dos mapeamentos" continua não entregue. |
| `_reversa_sdd/sdd/action-mapping.md` | `#6. Requisitos Funcionais` | regra-alterada | RF-09 vale para o atalho L1+✕, que envia `CONTINUAR` com Enter; na paleta, a ação de texto nunca envia Enter, e o argumento `--palette-enter-delay-ms` fica sem uso na lista fixa (emenda E001). |
| `_reversa_sdd/sdd/action-mapping.md` | `#6. Requisitos Funcionais` | componente-novo | RF-10 implementado em `KeyRepeat` (400 ms, depois a cada 50 ms), compartilhado pelas setas do protótipo e pela navegação circular da paleta. |
| `_reversa_sdd/sdd/action-mapping.md` | `#8. Design e Interface` | componente-novo | A paleta substitui a associação planejada de L1+↑ a `/reversa-forward`: PS a abre sem modificador ou com L1 ou L2 segurados, e não faz nada com Options; com ela aberta, só ↑, ↓, ✕, ○ e PS agem, os demais atalhos ficam suspensos e cliques e movimento continuam. |
| `_reversa_sdd/sdd/action-mapping.md` | `#11. Edge Cases e Tratamento de Erros` | regra-nova | Abrir a paleta solta antes as teclas e o Command mantidos (EC-05); ela fecha sem digitar na desconexão, na suspensão da injeção e após 60 s sem entrada. Um modificador segurado durante a paleta só ativa a camada ao ser pressionado de novo. |
| `_reversa_sdd/sdd/action-mapping.md` | `#12. Segurança e Privacidade` | regra-nova | A paleta só digita texto, sem executar programa nem shell, e seus eventos de log registram índice ou motivo, nunca o texto do item. |
| `_reversa_sdd/sdd/action-mapping.md` | `#14. Open Questions` | componente-novo | OQ-02 parcialmente respondida: o texto Unicode seguido de Enter imediato executou `/reversa-forward` no Claude Code, no Terminal; iTerm2 e o terminal integrado do VS Code não foram verificados. |
| `_reversa_sdd/sdd/app-shell.md` | `#6. Requisitos Funcionais` | delta-de-contrato-externo | O log de RF-12 ganha `palette.opened`, `palette.confirmed`, `palette.closed`, `palette.blocked` e `palette.invalid_args`, com `logSchema` mantido em 1; contrato em `interfaces/diagnostic-log.md` da feature. |
| `_reversa_sdd/sdd/app-shell.md` | `#8. Design e Interface` | componente-novo | Existe um painel sem borda e não ativador, em nível de barra de status, visível em todas as mesas, transparente ao mouse e centralizado na tela do cursor, com texto monoespaçado de 26 pt; não abre enquanto a tela de alvos está aberta. |
| `_reversa_sdd/sdd/app-shell.md` | `#9. Modelo de Dados` | delta-de-contrato-externo | `~/.config/joystick-ai/config.json` não muda; surge só o argumento de abertura `--palette-enter-delay-ms` (inteiro de 0 a 500, padrão 0), cujo erro não impede a tela de alvos. |
| `_reversa_sdd/sdd/controller-input.md` | `#8. Design e Interface` | regra-alterada | Os botões passam a ter dois destinos: com a paleta aberta vão a ela, e não aos atalhos, enquanto cliques e movimento seguem recebendo tudo; a desconexão fecha a paleta antes de soltar botões e teclas. |

## Regras sob vigilância

W001 a W012, em [`_reversa_forward/002-paleta-comandos/regression-watch.md`](../../_reversa_forward/002-paleta-comandos/regression-watch.md), todos na seção "Observações", sem peso de regressão até uma re-extração confirmá-los. W006 e W007 já refletem a emenda E001.

## Fontes

- `_reversa_forward/002-paleta-comandos/legacy-impact.md`
- `_reversa_forward/002-paleta-comandos/regression-watch.md`
- `_reversa_forward/002-paleta-comandos/requirements.md` (incluindo a emenda E001)
- `_reversa_forward/002-paleta-comandos/progress.jsonl`
- `_reversa_forward/002-paleta-comandos/actions.md` (notas da rodada 1 e do PM-1)
- `_reversa_forward/002-paleta-comandos/data-delta.md`
- `_reversa_forward/002-paleta-comandos/interfaces/diagnostic-log.md`
- `_reversa_forward/002-paleta-comandos/interfaces/launch-arguments.md`
