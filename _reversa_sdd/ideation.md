# Ideation, joystick-AI

> Selo 🟡 PLANEJADO em todos os itens, sujeito a validação.

## Brief original
criar uma aplicação que permita, inicialmente no MacOS, conectar o joystick do ps5 e utilizá-lo como mouse e adicionar alguns botões para abrir o vs code, utilizar o microfone para escrever prompts para IA, etc.

## Problema
🟡 Programar com teclado e mouse o dia todo é desconfortável e prende o programador à mesa. O problema aparece em três frentes:

- **Ergonomia:** desconforto no uso contínuo de teclado e mouse; o controle é percebido como mais agradável de manusear.
- **Mobilidade:** desejo de programar longe da mesa, com o computador conectado à televisão, "com menos burocracia".
- **Acessibilidade:** reduzir a dependência de teclado e mouse para quem tem limitação no uso deles.

Quem sente: o próprio usuário (iago), programador, no dia a dia de trabalho. O DualSense já oferece um touchpad, o que torna plausível usá-lo como dispositivo de apontamento.

## Valor entregue
🟡 Programar com agentes de IA do sofá, sem teclado nem mouse.

## Alternativas existentes
🟡 Nenhuma foi testada pelo usuário. A justificativa declarada é que **nenhuma junta controle e voz para IA num fluxo único**. Referências levantadas no brainstorm, não avaliadas:

- **Mapeadores de controle** (Enjoyable, Joystick Mapper, ControllerMate): convertem botões em teclas e cliques, sem integração com ditado ou agentes.
- **Steam Input (modo desktop)**: controle como mouse, mas dependente da Steam e pouco flexível fora de jogos.
- **Ditado nativo e Controle por Voz do macOS**: voz para texto sem integração com o controle.
- **Ferramentas de voz para IA** (Superwhisper, Wispr Flow, MacWhisper, Raycast): transcrevem, mas são acionadas por atalho de teclado.

Observação: a lacuna é hipótese, não fato verificado. Uma combinação de ferramentas existentes (mapeador disparando o atalho de uma ferramenta de voz) pode cobrir parte do problema; convém confirmar antes de investir em escopo que já existe pronto.

## Público-alvo (bruto)
🟡 Programadores que querem trabalhar do sofá, começando pelo próprio usuário, que é o primeiro usuário e a referência de design. A acessibilidade é motivação, não requisito de primeira ordem no início.

## Métricas de sucesso
🟡 **Horas por semana programando só com o controle** (sem tocar em teclado ou mouse). Alvo: **10 h/semana** em 3 meses.

## Premissas a validar
🟡 Todas as três confirmadas pelo usuário como críticas:

1. **Precisão do apontamento:** o analógico ou o touchpad do DualSense são precisos o bastante para clicar em alvos pequenos de uma IDE (abas, linhas, ícones) sem frustração.
2. **Acesso ao hardware no macOS:** é possível ler todos os controles do DualSense (touchpad, gatilhos, botões) e injetar movimento de mouse e teclas, sob as permissões de Acessibilidade e Input Monitoring.
3. **Microfone do DualSense como entrada de áudio no Mac:** o microfone do controle pode ser usado como dispositivo de entrada pelo macOS. A transcrição em si **não** é premissa a validar: a do Raycast atende bem e será reaproveitada. Ponto de atenção a verificar: a disponibilidade do microfone pode depender do modo de conexão (USB versus Bluetooth).

## Notas
🟡 Detalhes do brainstorm que não couberam acima:

- **Plataforma inicial:** macOS; outras plataformas ficam para depois.
- **Transcrição delegada ao Raycast:** o app não precisa implementar reconhecimento de voz no início, apenas captar o áudio pelo microfone do controle e acionar o fluxo de ditado do Raycast.
- **Ações por botão citadas no brief:** abrir o VS Code, acionar o microfone para ditar prompts para IA, "etc." (conjunto completo de ações a definir).
- **Cenário de uso de referência:** computador conectado à televisão, usuário no sofá, sessão de programação conduzida por agentes de IA.

---
Gerado por reversa-ideator em 2026-09-14T18:04:00Z
Fonte: newproject-brief.md
