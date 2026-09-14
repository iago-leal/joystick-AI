# PRD: joystick-AI

> Selo 🟡 PLANEJADO nos itens sem outra marca; 🟢 CONFIRMADO nos fatos verificados no hardware. Documento gerado a partir de ideation + personas.

**Versão:** 1.0
**Data:** 2026-09-14T18:11:44Z
**Autor:** reversa-drafter
**Status:** rascunho

---

## 1. Problema

🟡 Programar com teclado e mouse o dia todo é desconfortável e prende o programador à mesa. Para quem já trabalha orquestrando agentes de IA, a dependência é desproporcional: o código é escrito pelos agentes, mas conduzir a sessão (comandos com barra, `CONTINUAR`, escolhas em menus, aprovação de permissões, prompts) ainda exige teclado e mouse. Não há, segundo o levantamento do usuário, ferramenta que junte controle de videogame e voz para IA num fluxo único; essa lacuna é hipótese não verificada (ver Riscos).

O produto é um app para macOS que transforma o controle DualSense (PS5) em dispositivo de condução de sessões de programação com agentes: apontamento pelo touchpad ou analógico, ações por botão e ditado de prompts pelo microfone do próprio controle.

### Quem sente
- 🟡 **Programador de sofá**: à noite, depois do expediente, em projetos pessoais, trabalhando sozinho, com o computador ligado ou não à televisão. Sente desconforto no uso contínuo de teclado e mouse e a limitação de só conseguir trabalhar à mesa.
- 🟡 **Programadores com limitação no uso de teclado e mouse** (acessibilidade): motivação declarada, não público prioritário do MVP.

---

## 2. Personas-alvo

🟡 Referência completa em [`personas.md`](./personas.md). Resumo:

- **Programador de sofá**: 🟡 orquestrador de agentes de IA (avançado em Claude Code e Reversa, intermediário em Python) que quer trabalhar do sofá; dor principal: desconforto com teclado e mouse, que ainda prendem à mesa um fluxo em que o código é escrito por agentes.

---

## 3. Métricas de sucesso

🟡 Métrica única, com unidade e alvo definidos pelo usuário.

| Métrica | Unidade | Alvo | Prazo |
|---|---|---|---|
| 🟡 Tempo programando só com o controle, sem tocar em teclado ou mouse | 🟡 horas por semana | 🟡 10 h/semana | 🟡 3 meses após o início do uso |

🟡 Forma de apuração: [INDEFINIDO, validar com usuário]. Opções: registro local de sessões pelo próprio app ou apontamento manual pelo usuário.

---

## 4. Escopo (in)

🟡 Derivado do brief, do problema e da jornada principal da persona.

- 🟡 **Conexão do DualSense no macOS**: detectar conexão e desconexão do controle.
- 🟡 **Controle como mouse**: mover o cursor pelo touchpad e/ou analógico, clicar (esquerdo e direito), arrastar e rolar. Jornada, passo 6.
- 🟡 **Ações por botão**: associar botões ou combinações a ações; no mínimo, abrir o VS Code (ou terminal com Claude Code). Jornada, passo 2.
- 🟡 **Atalhos para o fluxo com agentes**: botões que enviam comandos e textos pré-definidos, como `/reversa-forward` e `CONTINUAR`, seguidos de Enter. Jornada, passo 4.
- 🟡 **Navegação em menus e aprovações**: direcional e botões mapeados para setas, Enter e Esc, suficientes para operar menus de escolha e pedidos de permissão do Claude Code. Jornada, passo 5.
- 🟡 **Ditado de prompts**: um botão aciona o ditado do Raycast, com o microfone do DualSense como entrada de áudio. Jornada, passos 3 e 7.
- 🟡 **Permissões do macOS**: verificar e orientar a concessão das permissões necessárias para ler o controle e injetar eventos de mouse e teclado (Acessibilidade, Input Monitoring).
- 🟡 **Configuração dos mapeamentos**: associações entre botões e ações editáveis pelo usuário. Formato e interface: [INDEFINIDO, decidir nas specs SDD].

---

## 5. Não-objetivos (out)

🟡 Confirmados pelo usuário para o MVP.

- 🟡 **Windows e Linux**: o MVP é exclusivo para macOS.
- 🟡 **Transcrição própria**: o app não implementa reconhecimento de voz; a transcrição é do Raycast.
- 🟡 **Distribuição pública**: sem App Store, assinatura de código, notarização ou instalador para terceiros.

🟡 Não excluído, mas também não incluído: **teclado virtual na tela** para digitação caractere a caractere. [INDEFINIDO, validar com usuário]

---

## 6. Restrições

| Tipo | Descrição |
|---|---|
| 🟡 Técnica | 🟡 App nativo em **Swift** para **macOS**. O suporte ao DualSense no framework GameController existe a partir do macOS 11.3; versão mínima alvo [INDEFINIDO]. A injeção de eventos exige permissões de Acessibilidade e Input Monitoring. |
| 🟡 Prazo | 🟡 [INDEFINIDO, validar com usuário] |
| 🟡 Compliance | 🟡 Nenhuma exigência regulatória identificada nas fontes. O app não transcreve nem armazena áudio; o processamento de voz fica a cargo do Raycast. |
| 🟡 Orçamento | 🟡 [INDEFINIDO, validar com usuário] |

---

## 7. Dependências externas

- 🟡 **Controle DualSense (PS5)**: hardware de entrada (botões, analógicos, gatilhos, touchpad, microfone).
- 🟡 **Raycast**: transcrição do ditado; o app depende de uma forma estável de acionar o ditado (atalho ou deeplink) [INDEFINIDO, investigar nas specs]. 🟢 O microfone do ditado é escolhido pela lista de prioridade do próprio Raycast (Settings › Dictation › Microphone), e não pela entrada padrão do macOS.
- 🟡 **VS Code**: aplicativo aberto por botão.
- 🟡 **Claude Code e framework Reversa**: destino dos comandos, textos e navegação em menus.
- 🟡 **APIs do macOS**: GameController (leitura do controle), eventos de entrada do sistema (injeção de mouse e teclado), áudio do sistema (dispositivo de entrada).

---

## 8. Riscos

| Risco | Impacto | Probabilidade | Mitigação proposta |
|---|---|---|---|
| 🟡 Apontamento pelo touchpad ou analógico impreciso para alvos pequenos da IDE | 🟡 alto | 🟡 média | 🟡 Prova de conceito de apontamento antes do restante; sensibilidade e aceleração ajustáveis; privilegiar ações por botão e navegação por teclado sobre o clique fino. |
| 🟡 macOS não expõe todos os controles do DualSense ou bloqueia a injeção de eventos | 🟡 alto | 🟡 baixa | 🟡 Validar cedo leitura de touchpad, gatilhos e botões via GameController e a injeção sob as permissões; fluxo guiado de concessão de permissões. |
| 🟡 Microfone do DualSense não disponível como entrada no macOS, sobretudo via Bluetooth | 🟡 alto | 🟡 média | 🟡 Testar microfone por USB e por Bluetooth antes de especificar o ditado; plano B: microfone do Mac ou fone Bluetooth, mantendo o acionamento pelo controle. 🟢 Testado em 2026-09-14: o risco se confirma por Bluetooth (só serviço HID, nenhum dispositivo de áudio) e não se materializa por USB (entrada "DualSense Wireless Controller", 2 canais a 48 kHz, captura com média de −38,7 dBFS e pico de −18,8 dBFS). O plano B vale para o uso sem cabo; detalhes em `sdd/voice-dictation.md`, OQ-02. 🟢 No teste do ditado, com o DualSense no topo da lista de microfones do Raycast, a transcrição pelo controle saiu fiel, e sem o cabo o Raycast recorreu sozinho ao microfone do Mac, cumprindo o plano B sem ação do app (OQ-03). 🟢 Uma sonda HID por Bluetooth, com o microfone do controle ligado por comando, não recebeu áudio algum; o microfone do controle fica restrito ao USB, e o uso sem cabo depende de outro microfone (Mac, fone Bluetooth). |
| 🟡 Acionamento do ditado do Raycast frágil (atalho alterado, mudança de versão) | 🟡 médio | 🟡 média | 🟡 Isolar a integração num componente próprio e tornar o atalho configurável. |
| 🟡 Correções pequenas de texto inviáveis só com voz, forçando o retorno ao teclado | 🟡 médio | 🟡 média | 🟡 Mapear edição básica (apagar palavra, desfazer, Enter, Esc) em botões; reavaliar teclado virtual após uso real. |
| 🟡 Ferramentas existentes combinadas já resolverem o problema | 🟡 médio | 🟡 baixa | 🟡 Teste rápido de um mapeador de controle acionando o atalho do Raycast antes de investir além da prova de conceito. |
| 🟡 Conflito com jogos ou apps que também usam o controle | 🟡 baixo | 🟡 média | 🟡 Permitir ativar e desativar o modo de condução rapidamente. |

---

## 9. Critérios de aceite (alto nível)

- 🟡 **Dado** o app em execução com as permissões concedidas, **Quando** o DualSense é conectado ao Mac, **Então** o app reconhece o controle e passa a responder aos seus comandos sem configuração adicional.
- 🟡 **Dado** o controle conectado, **Quando** o usuário desliza o dedo no touchpad ou move o analógico, **Então** o cursor se move e é possível clicar, arrastar e rolar sem teclado ou mouse.
- 🟡 **Dado** o controle conectado, **Quando** o usuário pressiona o botão associado ao VS Code, **Então** o VS Code é aberto ou trazido para frente.
- 🟡 **Dado** um terminal com Claude Code em foco, **Quando** o usuário pressiona o botão de ditado e fala um prompt, **Então** o texto transcrito pelo Raycast é inserido no campo em foco.
- 🟡 **Dado** um menu de escolha ou pedido de permissão do Claude Code na tela, **Quando** o usuário usa o direcional e os botões de confirmar e cancelar, **Então** consegue escolher e confirmar a opção.
- 🟡 **Dado** um fluxo do Reversa aguardando `CONTINUAR`, **Quando** o usuário pressiona o botão associado, **Então** o comando é enviado ao terminal.
- 🟡 **Dado** uma sessão completa da jornada principal, **Quando** o usuário a conduz do início ao fim, **Então** não precisa tocar em teclado ou mouse.

---

## Pendências de cobertura

🟡 Itens `[INDEFINIDO]` a validar antes ou durante as specs SDD:

1. Forma de apuração da métrica de horas por semana (seção 3).
2. Formato e interface da configuração dos mapeamentos (seção 4).
3. Inclusão ou não de teclado virtual na tela (seção 5).
4. Versão mínima do macOS (seção 6).
5. Prazo (seção 6).
6. Orçamento (seção 6).
7. Mecanismo de acionamento do ditado do Raycast (seção 7).

---

Gerado por reversa-drafter em 2026-09-14T18:11:44Z
Fontes: ideation.md, personas.md
