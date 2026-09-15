# Adendo ao PRD: Ditado de prompts pelo atalho do Raycast

> Identificador: `prd-l01-ditado-pelo-raycast`
> Data: 2026-09-15
> Cenário: decisão de produto sobre lacuna da extração (L-01)

## Vigência

Vigente desde 2026-09-15.

## Resumo da decisão

O PRD previa o ditado de prompts como capacidade do próprio app, e a spec `sdd/voice-dictation.md` a detalhava como componente dedicado, no modo segurar L2 para falar. Na revisão da extração, o usuário decidiu que esse componente não será implementado: o ditado passa a ser uma ação comum de atalho, em que R3 envia ⌘M, e o transcritor do Raycast, configurado fora do app, capta e transcreve a fala. A spec `sdd/voice-dictation.md` fica superada, e o ADR-015 passa a Aceito.

A decisão mantém o objetivo do PRD, que é ditar prompts sem teclado, e muda apenas o meio. O app não ganha código de áudio, não pede permissão de microfone e não escolhe a entrada; em troca, o ditado passa a depender de dois pré-requisitos externos, listados a seguir.

## Pré-requisitos externos do ditado

1. **Atalho do transcritor no Raycast:** o comando de ditado do Raycast deve responder ao mesmo acorde que o botão envia, por padrão ⌘M. Como `chord` pressiona no pressionar e solta no soltar (`atalhos/requirements.md`, RN-AT-08), o acorde fica mantido enquanto R3 estiver segurado; se o Raycast alterna ou exige segurar é definido na configuração dele, e o modo em uso não foi verificado na extração.
2. **Microfone escolhido pelo Raycast:** em Settings › Dictation › Microphone, com "Use System Default" desligado e o DualSense no topo da lista, o Raycast grava pelo controle quando ele está ligado por USB; sem cabo, recorre sozinho ao próximo microfone disponível. Esse arranjo foi verificado no teste de 2026-09-14 (`sdd/voice-dictation.md`, seção 2).

## Delta por seção do PRD

Os trechos abaixo continuam no `prd.md`, que não é editado; leia-os com a correção indicada.

| Seção | Como está no PRD | Como deve ser lido agora | Tipo de impacto |
|-------|------------------|--------------------------|-----------------|
| `#1. Problema` | O app oferece "ditado de prompts pelo microfone do próprio controle". | O app aciona, por botão, o ditado do Raycast; o microfone do controle só é usado por USB, e por escolha do Raycast. | regra-alterada |
| `#4. Escopo (in)`, Ditado de prompts | "Um botão aciona o ditado do Raycast, com o microfone do DualSense como entrada de áudio." | Um botão configurável, R3 por padrão, envia o acorde do transcritor do Raycast, ⌘M por padrão; a entrada de áudio é a que o Raycast escolher pela lista de prioridade dele. Botão e acorde são editáveis no editor de atalhos e em `config.json`, como qualquer `chord`. O texto ditado também pode ser colado nos campos do editor, pelo menu Editar. | regra-alterada |
| `#5. Não-objetivos (out)`, Transcrição própria | O app não implementa reconhecimento de voz. | Mantido e ampliado: o app também não captura áudio, não detecta microfone nem controla o ditado além de enviar o acorde. | regra-alterada |
| `#6. Restrições`, Compliance | O app não transcreve nem armazena áudio. | Mantido, sem ressalva: nenhuma permissão de microfone é pedida. | regra-alterada |
| `#7. Dependências externas`, Raycast | Forma estável de acionar o ditado "[INDEFINIDO, investigar nas specs]". | Resolvido: o acionamento é o atalho de teclado do transcritor, ⌘M por padrão; deeplink não é usado. A configuração do atalho e da lista de microfones é pré-requisito do usuário, fora do app. | delta-de-contrato-externo |
| `#7. Dependências externas`, APIs do macOS | Inclui "áudio do sistema (dispositivo de entrada)". | Não há dependência de áudio do sistema; restam GameController, HID e injeção de eventos. | delta-de-contrato-externo |
| `#8. Riscos`, microfone do DualSense | Plano B: microfone do Mac ou fone Bluetooth, mantendo o acionamento pelo controle. | O plano B é executado pelo próprio Raycast, sem ação do app, e o risco fica inteiramente fora do código. | regra-alterada |
| `#8. Riscos`, acionamento frágil do Raycast | Mitigação: "isolar a integração num componente próprio e tornar o atalho configurável". | O componente próprio é descartado; a mitigação que resta é o acorde configurável pelo editor. O risco continua aberto: se o atalho mudar no Raycast, o acorde chega ao aplicativo em foco sem aviso do app, e ⌘M costuma minimizar a janela nos aplicativos do macOS. | regra-alterada |
| `#9. Critérios de aceite`, ditado | "Quando o usuário pressiona o botão de ditado e fala um prompt, então o texto transcrito pelo Raycast é inserido no campo em foco." | Acrescenta-se à condição "Dado" que o transcritor do Raycast esteja configurado com o acorde do botão. O critério é atendido pela US-AG-04 (`user-stories/conduzir-agentes-pelo-controle.md`). | regra-alterada |
| `Pendências de cobertura`, item 7 | Mecanismo de acionamento do ditado do Raycast indefinido. | Resolvido pelo atalho de teclado; ver seção 7 acima. | regra-nova |

## Artefatos da extração afetados

| Artefato | Efeito |
|----------|--------|
| `_reversa_sdd/sdd/voice-dictation.md` | Superada na versão 1.4; a OQ-01 dela (atalho e modo do ditado) deixa de bloquear plano, pois o modo passa a ser configuração do Raycast. |
| `_reversa_sdd/sdd/action-mapping.md` | O RF-12 (ação `dictation` com semântica `hold` em L2) não se aplica; o ditado é um `chord` comum. |
| `_reversa_sdd/sdd/app-shell.md` | As menções a `voice-dictation` (RF-09 ao encerrar o ditado, inicialização e EC-04 "Ditado indisponível") não se aplicam. |
| `_reversa_sdd/atalhos/requirements.md` | RN-AT-21 registra a decisão. |
| `_reversa_sdd/adrs/015-ditado-delegado-ao-raycast.md` | Aceito. |

## Aprovação

Decisão do usuário (iago) em 2026-09-15, na resposta à Pergunta 1 de `questions.md`: "Superado pelo atalho R3".

## Fontes

- `_reversa_sdd/prd.md`, seções 1, 4 a 9 e Pendências de cobertura
- `_reversa_sdd/questions.md`, Pergunta 1
- `_reversa_sdd/gaps.md`, L-01
- `_reversa_sdd/adrs/015-ditado-delegado-ao-raycast.md`
- `_reversa_sdd/sdd/voice-dictation.md`, seção 2 (testes de microfone e ditado de 2026-09-14)
- `_reversa_sdd/atalhos/requirements.md`, RN-AT-07, RN-AT-08, RN-AT-19 e RN-AT-21
- `_reversa_sdd/addenda/001-poc-entrada-ponteiro.md`, linha de `sdd/voice-dictation.md`
