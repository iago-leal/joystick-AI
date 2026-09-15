# Regression watch: Paleta de comandos pelo controle

> Identificador: `002-paleta-comandos`
> Feature greenfield: não há regras 🟢 extraídas de código para vigiar. O watch principal fica vazio; os requisitos implementados estão em "Observações", sem peso de regressão, até que uma futura extração `/reversa` sobre o código os confirme como 🟢.

## Watch principal

| ID | Origem (arquivo, seção) | Regra esperada após mudança | Tipo de verificação | Sinal de violação |
|----|--------------------------|------------------------------|---------------------|-------------------|

## Observações

Itens implementados na rodada 1 (2026-09-14), com testes automatizados verdes e verificação no hardware pendente dos portões PM-1 e PM-2.

| ID | Origem (arquivo, seção) | Regra esperada | Tipo de verificação | Sinal de violação |
|----|--------------------------|----------------|---------------------|-------------------|
| W001 | `requirements.md` RN-01, RF-01; `roadmap.md` D-02 | PS abre a paleta sem modificador e com L1 ou L2 segurados; com Options, nada. | presença | PS sem efeito na camada base, ou abrindo a paleta com Options segurado. |
| W002 | `requirements.md` RN-02; `roadmap.md` D-08 | O painel é não ativador, não se torna `key` nem `main` e ignora o mouse; o aplicativo em foco não muda ao abrir. | presença | Terminal perdendo o foco ao pressionar PS, ou cliques bloqueados sobre a área da paleta. |
| W003 | `requirements.md` RN-03, RF-06; `roadmap.md` D-03 | Com a paleta aberta, só ↑, ↓, ✕, ○ e PS agem sobre ela; os demais atalhos ficam suspensos e cliques e movimento continuam. | presença | □ enviando Backspace com a paleta aberta, ou cursor parado. |
| W004 | `requirements.md` RN-04; `roadmap.md` D-04 | A abertura solta antes as teclas e o Command mantidos e interrompe a repetição. | presença | Tecla em repetição ou Command preso depois de abrir a paleta. |
| W005 | `requirements.md` RF-02; `roadmap.md` D-07 | Seleção circular, com repetição de ↑ e ↓ em 400 ms e depois a cada 50 ms, pela mesma `KeyRepeat` das setas. | presença | Seleção parando no fim da lista ou tempos diferentes dos das setas. |
| W006 | `requirements.md` RF-04, RN-05; `roadmap.md` D-06 | A confirmação digita o texto do item sem Enter; o envio fica para um ✕ seguinte (E001). | presença | Qualquer item da paleta enviado ao confirmar. |
| W007 | `requirements.md` RF-05, §4 | Lista fixa de 17 itens, de `CONTINUAR` a `/resume`, nenhum com Enter (E001) e três terminados em espaço. | redação | Item a mais, a menos, fora de ordem ou com Enter sem nova decisão. |
| W008 | `requirements.md` RF-07, RN-08 | Atalhos do protótipo diferentes de PS continuam iguais. | presença | Qualquer teste de `ShortcutMapperTests` anterior à 002 alterado sem decisão registrada. |
| W009 | `requirements.md` RF-09; `roadmap.md` D-12 | A paleta fecha sem digitar na desconexão, na suspensão da injeção e após 60 s sem entrada. | presença | Paleta visível após desligar o controle, ou texto digitado depois de revogar a permissão. |
| W010 | `requirements.md` RN-07; `interfaces/diagnostic-log.md` §3 | Eventos `palette.*` sem texto, rótulo nem comprimento de item. | presença | Texto de um item presente em qualquer linha do log. |
| W011 | `roadmap.md` D-13 | Com a tela de alvos aberta, PS não abre a paleta e registra `palette.blocked`. | presença | Paleta abrindo sobre a tela de alvos. |
| W012 | `roadmap.md` D-05 | Um único `KeyboardInjector` compartilhado por atalhos e paleta. | presença | Dois injetores de teclado criados no `AppDelegate`. |

## Histórico de re-extrações

## Arquivadas
