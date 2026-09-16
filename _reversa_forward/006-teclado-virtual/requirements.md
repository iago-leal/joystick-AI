# Requirements: Teclado virtual chamado pelo controle

> Identificador: `006-teclado-virtual`
> Data: `2026-09-16`
> Pasta da extração reversa: `_reversa_sdd/`
> Confidência: 🟢 CONFIRMADO, 🟡 INFERIDO, 🔴 LACUNA / DÚVIDA

## 1. Resumo executivo

A feature permite que o programador de sofá digite texto livre sem teclado físico: um botão do controle abre e fecha um teclado virtual na tela, e o usuário aciona as teclas com o ponteiro que o controle já oferece. Por decisão do usuário, o teclado é o que o próprio macOS fornece, e não um teclado desenhado pelo app. Hoje o controle só digita textos definidos de antemão (paleta e ação de texto) ou ditados pelo Raycast; um nome de arquivo, um termo de busca ou uma resposta curta ainda exigem o teclado físico.

## 2. Contexto a partir do legado

| Fonte | Trecho relevante | Confidência |
|-------|------------------|-------------|
| Pedido do usuário, 2026-09-16 | "Se houver a possibilidade de utilizarmos algum teclado virtual já nativo do próprio macOS, melhor ainda. Porque daí eu utilizaria apenas um atalho pra chamá-lo." | 🟢 |
| `_reversa_sdd/domain.md#1. Propósito do domínio` | O usuário-alvo acompanha agentes na TV a cerca de 3 m e deseja passar a maior parte do tempo sem teclado | 🟢 |
| `_reversa_sdd/personas.md#Persona 1: Programador de sofá` | As interações do fluxo são sobretudo discretas (comandos, `CONTINUAR`, menus); o apontamento é secundário, voltado a revisão e navegação | 🟡 |
| `_reversa_sdd/atalhos/requirements.md#Regras de Negócio` | RN-AT-07 e RN-AT-08: a ação `chord` pressiona tecla do catálogo com modificadores no pressionar e solta no soltar; RN-AT-18: o catálogo inclui F1 a F12; RN-AT-19: mapeamento padrão | 🟢 |
| `_reversa_sdd/injecao-de-eventos/requirements.md#Regras de Negócio` | RN-IN-10: as setas injetadas só acionaram Mission Control depois de receber as máscaras que o teclado físico envia; o sistema pode ignorar um acorde injetado que difira do físico | 🟢 |
| `_reversa_sdd/domain.md#3.3 Atalhos, configuração e editor (003)` | 003 RN-05: R1 e clique do touchpad fazem o clique esquerdo em qualquer camada; 003 RN-14: o log não registra textos nem acordes | 🟢 |
| `_reversa_sdd/domain.md#3.2 Paleta (002)` | 002 RN-02: a paleta digita no aplicativo em foco sem tomar o foco | 🟢 |
| `_reversa_sdd/atalhos/requirements.md#Regras de Negócio` | RN-AT-13: com a paleta aberta ou no modo de identificação do editor, os botões não chegam aos atalhos | 🟢 |
| `_reversa_sdd/permissions.md#2. Matriz de permissões do sistema operacional` | O app funciona só com a permissão de Acessibilidade, sem rede nem microfone | 🟢 |
| `_reversa_sdd/addenda/prd-l01-ditado-pelo-raycast.md#Pré-requisitos externos do ditado` | Precedente de integração por atalho: o app envia um acorde e a configuração do destino fica fora do app, como pré-requisito documentado | 🟢 |
| `_reversa_sdd/domain.md#3.1 Controle e entrada (001)` | 001 RN-04: nenhuma desconexão deixa entrada presa | 🟢 |

**Constatação.** O macOS oferece um teclado virtual de sistema, o Teclado de Acessibilidade, acionável por um atalho de teclado do próprio sistema. O app já sabe enviar acordes com teclas de função e modificadores, de modo que parte do pedido talvez se resolva por configuração, sem código novo. Não há evidência, porém, de que o sistema reconheça esse atalho quando injetado pelo app, nem de que o teclado virtual aceite os cliques sintéticos do ponteiro; ambos são pontos a sondar no hardware antes do plano. 🟡

## 3. Personas e cenários de uso

| Persona | Objetivo | Cenário-chave |
|---------|----------|---------------|
| Programador de sofá (`_reversa_sdd/personas.md#Persona 1: Programador de sofá`) | Digitar um texto curto e imprevisto sem levantar para o teclado | No terminal da TV, o agente pede o nome de uma pasta; o usuário pressiona o botão do teclado, aponta e aciona as letras com R1, confirma com Return e fecha o teclado pelo mesmo botão |
| Programador de sofá | Buscar um arquivo ou símbolo no editor de código | Abre a busca por um atalho já configurado, abre o teclado virtual, digita o termo e fecha o teclado |

O uso é ocasional ao longo da sessão: textos longos continuam com o ditado, e comandos recorrentes, com a paleta. 🟡

## 4. Regras de negócio novas ou alteradas

1. **RN-01:** O teclado virtual é o fornecido pelo sistema operacional; o app não desenha teclado próprio, nem como alternativa caso o do sistema se mostre limitado. 🟢
   - Origem no legado: nenhuma (pedido do usuário, confirmado no esclarecimento de 2026-09-16)
   - Tipo: nova
2. **RN-02:** Um único botão alterna o teclado: pressioná-lo com o teclado oculto o exibe, e pressioná-lo com o teclado visível o oculta. Se o sistema não permitir alternar o teclado diretamente, aceita-se um passo extra: o botão abre o painel do sistema em que o teclado é escolhido, e o usuário faz a escolha com o ponteiro. 🟢
   - Origem no legado: `_reversa_sdd/atalhos/requirements.md#Regras de Negócio` (RN-AT-07, RN-AT-08)
   - Tipo: nova
3. **RN-03:** O botão e a camada que alternam o teclado são configuráveis pelo editor de atalhos e pelo arquivo de configuração, com a mesma validação, herança e gravação das demais ações. 🟢
   - Origem no legado: `_reversa_sdd/domain.md#3.3 Atalhos, configuração e editor (003)` (003 RN-02, RN-08)
   - Tipo: alterada (a configuração passa a cobrir o acionamento do teclado)
4. **RN-04:** As teclas do teclado virtual são acionadas pelo ponteiro existente, com o clique esquerdo de R1 ou do touchpad; a feature não cria mapeamento de botão para tecla. 🟢
   - Origem no legado: `_reversa_sdd/domain.md#3.3 Atalhos, configuração e editor (003)` (003 RN-05)
   - Tipo: alterada (o ponteiro ganha um destino novo, sem regra nova)
5. **RN-05:** Exibir ou ocultar o teclado não muda o aplicativo em foco; o texto digitado vai ao aplicativo que estava à frente, como na paleta. 🟡
   - Origem no legado: `_reversa_sdd/domain.md#3.2 Paleta (002)` (002 RN-02)
   - Tipo: nova
6. **RN-06:** Com o teclado visível, atalhos, paleta, ditado e ponteiro continuam operando como antes; o teclado não cria modo exclusivo do controle. As exceções já existentes permanecem: com a paleta aberta ou no modo de identificação do editor, o botão do teclado não chega aos atalhos. 🟡
   - Origem no legado: `_reversa_sdd/atalhos/requirements.md#Regras de Negócio` (RN-AT-13)
   - Tipo: alterada
7. **RN-07:** O log não registra as teclas acionadas no teclado virtual nem o texto produzido; o acionamento do botão só pode aparecer nos eventos já existentes, que não contêm tecla nem acorde. 🟢
   - Origem no legado: `_reversa_sdd/atalhos/requirements.md#Regras de Negócio` (RN-AT-17); `_reversa_sdd/domain.md#3.3 Atalhos, configuração e editor (003)` (003 RN-14)
   - Tipo: alterada (a restrição passa a cobrir o teclado virtual)
8. **RN-08:** O app não altera preferências do sistema nem pede permissão nova. Se exibir o teclado depender de um ajuste nos Ajustes do Sistema, esse ajuste é pré-requisito do usuário, descrito na documentação da feature, como no ditado pelo Raycast. 🟡
   - Origem no legado: `_reversa_sdd/permissions.md#2. Matriz de permissões do sistema operacional`; `_reversa_sdd/addenda/prd-l01-ditado-pelo-raycast.md#Pré-requisitos externos do ditado`
   - Tipo: nova
9. **RN-09:** O teclado só é ocultado pelo mesmo acionamento que o exibe ou pelo controle de fechar do próprio teclado; o app não o oculta ao acionar Return, ao abrir a paleta ou o editor, nem por inatividade. 🟢
   - Origem no legado: nenhuma (esclarecimento de 2026-09-16)
   - Tipo: nova
10. **RN-10:** O mapeamento padrão não muda: sem arquivo de configuração, nenhum botão alterna o teclado, e o usuário escolhe o botão pelo editor. 🟢
    - Origem no legado: `_reversa_sdd/atalhos/requirements.md#Regras de Negócio` (RN-AT-19)
    - Tipo: nova (preserva a regra do legado)
11. **RN-11:** O tamanho das teclas é o que o teclado do sistema permite ajustar; o alvo mínimo de 60 pontos (pt) do editor (RN-ED-13) não se aplica, e a adequação a 3 m é conferida no teste de sofá. 🟢
    - Origem no legado: `_reversa_sdd/editor/requirements.md#Regras de Negócio` (RN-ED-13)
    - Tipo: nova

## 5. Requisitos Funcionais

| ID | Requisito | Prioridade | Critério de aceite | Confidência |
|----|-----------|------------|--------------------|-------------|
| RF-01 | Alternar o teclado virtual por um botão do controle (RN-01, RN-02) | Must | Com o pré-requisito cumprido, pressionar o botão exibe o teclado em até 1 s, ou, no caminho com passo extra, exibe o painel do sistema em que o teclado é escolhido; pressionar de novo o oculta em até 1 s | 🟡 |
| RF-02 | Digitar no aplicativo em foco acionando as teclas com o ponteiro (RN-04, RN-05) | Must | Com o terminal em foco, acionar `l`, `s` e Return no teclado virtual com R1 faz o terminal executar `ls` | 🟡 |
| RF-03 | Preservar o aplicativo em foco ao exibir e ocultar o teclado (RN-05) | Must | Antes e depois de exibir o teclado, o mesmo aplicativo está à frente e recebe as teclas | 🟡 |
| RF-04 | Configurar o botão e a camada do teclado pelo editor e pelo arquivo (RN-03) | Must | Mover o acionamento para outro botão pelo editor, só com o controle, e salvar faz o novo botão alternar o teclado e o anterior deixar de fazê-lo | 🟢 |
| RF-05 | Manter atalhos, paleta e ditado operando com o teclado visível (RN-06, RN-09) | Must | Com o teclado visível, L1 + ✕ envia "CONTINUAR", PS abre a paleta e o teclado continua visível | 🟡 |
| RF-06 | Manter o mapeamento padrão sem o botão do teclado (RN-10) | Must | Sem arquivo de configuração, nenhum botão exibe o teclado, e o mapeamento padrão é idêntico ao anterior à feature | 🟢 |
| RF-07 | Teclas acionáveis pelo ponteiro a 3 m, no tamanho ajustado no sistema (RN-11) | Should | No sofá, com o teclado no tamanho ajustado pelo usuário, uma palavra de oito letras é digitada sem tecla errada | 🟡 |
| RF-08 | Documentar os pré-requisitos externos e o roteiro de verificação (RN-08, RN-11) | Must | A documentação da feature lista cada ajuste do sistema necessário, inclusive o do tamanho do teclado, e como conferi-lo | 🟡 |
| RF-09 | Não registrar no log teclas nem texto do teclado virtual (RN-07) | Must | Após digitar e usar o teclado numa sessão com log ativo, nenhuma linha contém as teclas, o texto ou o acorde de acionamento | 🟢 |
| RF-10 | Não deixar tecla presa ao desconectar o controle ou perder a permissão com o teclado visível (001 RN-04) | Must | Desconectar o controle com o teclado visível não deixa tecla nem modificador pressionado no sistema | 🟢 |

## 6. Requisitos Não Funcionais

| Tipo | Requisito | Evidência ou justificativa | Confidência |
|------|-----------|----------------------------|-------------|
| Desempenho | Exibir ou ocultar o teclado em até 1 s após pressionar o botão | Uso interativo; o próprio app aplica mudanças de permissão em cerca de 2 s (`_reversa_sdd/permissions.md#3. Pedido e concessão`), e a alternância deve ser mais rápida que isso | 🟡 |
| Usabilidade | Digitar um texto curto, da abertura ao fechamento do teclado, sem teclado físico nem mouse | `_reversa_sdd/domain.md#1. Propósito do domínio` | 🟢 |
| Compatibilidade | Funcionar no macOS em uso pelo usuário (26) sem quebrar o mínimo declarado do app (13) | `_reversa_sdd/inventory.md#1. Visão geral`; `_reversa_sdd/domain.md#4. Regras implícitas (só no código)` (RI-23) | 🟡 |
| Compatibilidade | Configurações existentes continuam válidas sem migração, e o mapeamento padrão não muda | `_reversa_sdd/architecture.md#5. Modelo de dados em arquivo`; RN-10 | 🟢 |
| Segurança | Nenhuma permissão nova, nenhuma escrita em preferências do sistema, nenhuma rede | `_reversa_sdd/permissions.md#2. Matriz de permissões do sistema operacional` | 🟢 |
| Privacidade | Teclas e textos do teclado virtual fora do log | `_reversa_sdd/domain.md#3.3 Atalhos, configuração e editor (003)` (003 RN-14) | 🟢 |
| Testabilidade | Regras de configuração e de mapeamento verificáveis por testes automatizados; exibição, foco e digitação verificadas por portão manual no hardware | `_reversa_sdd/architecture.md#6. Qualidade e verificação` | 🟢 |
| Observabilidade | Nenhum evento de log novo é exigido; o acionamento aparece em `shortcut.triggered` sem tecla | `_reversa_sdd/atalhos/requirements.md#Regras de Negócio` (RN-AT-17) | 🟢 |

## 7. Critérios de Aceitação

```gherkin
Cenário: Digitar um nome no terminal
  Dado o terminal em foco, o pré-requisito cumprido e o teclado virtual oculto
  Quando o usuário pressiona o botão do teclado
  E aciona "l", "s" e Return no teclado virtual com R1
  Então o terminal executa "ls"
  E o terminal continua sendo o aplicativo em foco
  E o teclado continua visível

Cenário: Ocultar o teclado pelo mesmo botão
  Dado o teclado virtual visível
  Quando o usuário pressiona o botão do teclado
  Então o teclado é ocultado em até 1 s
  E o aplicativo em foco não muda

Cenário: Caminho com passo extra
  Dado um sistema que não permite alternar o teclado diretamente
  Quando o usuário pressiona o botão do teclado
  Então o painel do sistema em que o teclado é escolhido é exibido
  E escolher o teclado com o ponteiro o exibe sem mudar o aplicativo em foco

Cenário: Atalhos seguem ativos com o teclado visível
  Dado o teclado virtual visível
  Quando o usuário pressiona L1 + ✕
  Então "CONTINUAR" é digitado no aplicativo em foco

Cenário: Paleta aberta não oculta o teclado
  Dado o teclado virtual visível
  Quando o usuário abre a paleta pelo PS
  Então a paleta é exibida
  E o teclado continua visível

Cenário: Trocar o botão pelo editor
  Dado o acionamento do teclado em um botão
  Quando o usuário o move para outro botão no editor, só com o controle, e salva
  Então o novo botão alterna o teclado
  E o botão anterior deixa de alterná-lo

Cenário: Mapeamento padrão inalterado
  Dado nenhum arquivo de configuração
  Quando o usuário pressiona cada botão do controle na camada base
  Então nenhum deles exibe o teclado virtual
  E cada um executa a mesma ação de antes da feature

Cenário: Paleta aberta retém o botão
  Dado a paleta aberta
  Quando o usuário pressiona o botão do teclado
  Então o teclado virtual não é exibido
  E a paleta trata o botão conforme as próprias regras

Cenário: Modo de identificação do editor
  Dado o editor no modo de identificação
  Quando o usuário pressiona o botão do teclado
  Então o botão é selecionado na figura
  E o teclado virtual não é exibido

Cenário: Pré-requisito externo ausente
  Dado o ajuste do sistema exigido pela feature desfeito
  Quando o usuário pressiona o botão do teclado
  Então o teclado virtual não é exibido
  E o app segue operando, sem erro nem tecla presa

Cenário: Sem permissão de Acessibilidade
  Dado a permissão de Acessibilidade revogada
  Quando o usuário pressiona o botão do teclado
  Então nada é enviado ao sistema
  E, restaurada a permissão, nenhum modificador fica pressionado

Cenário: Desconexão com o teclado visível
  Dado o teclado virtual visível e o botão do teclado pressionado
  Quando o controle é desconectado
  Então nenhuma tecla nem modificador fica pressionado no sistema

Cenário: Digitação a 3 m
  Dado o usuário no sofá, a cerca de 3 m da TV, com o teclado virtual visível no tamanho ajustado no sistema
  Quando digita uma palavra de oito letras apontando com o controle
  Então a palavra chega ao aplicativo em foco sem letra errada

Cenário: Pré-requisito documentado
  Dado um Mac em que os ajustes do sistema exigidos pela feature nunca foram feitos
  Quando o usuário segue a documentação da feature
  Então o botão do teclado passa a exibir o teclado virtual

Cenário: Log sem texto digitado
  Dado o log de diagnóstico ativo
  Quando o usuário exibe o teclado, digita uma palavra e o oculta
  Então nenhuma linha do log contém a palavra, as teclas ou o acorde de acionamento
```

## 8. Prioridade MoSCoW

| Item | MoSCoW | Justificativa |
|------|--------|---------------|
| RF-01 | Must | É o pedido: chamar o teclado por um atalho |
| RF-02 | Must | Sem digitação no aplicativo em foco, o teclado não serve |
| RF-03 | Must | Tomar o foco desviaria o texto do destino |
| RF-04 | Must | É o único meio de ligar o teclado a um botão, já que o padrão não muda |
| RF-05 | Must | O teclado não pode desligar o restante do controle |
| RF-06 | Must | Decisão do usuário: o botão é escolhido por ele |
| RF-07 | Should | Uso do sofá; limitado ao que o teclado do sistema permite |
| RF-08 | Must | Sem documentação do pré-requisito, a feature falha em silêncio |
| RF-09 | Must | Privacidade já garantida pelo legado |
| RF-10 | Must | Regra de segurança do legado (001 RN-04) |
| RNF de desempenho | Should | Afeta conforto, não a função |
| Teclado próprio desenhado pelo app | Won't | Decisão do usuário, inclusive como plano B (RN-01) |
| Ocultar o teclado automaticamente | Won't | Decisão do usuário (RN-09) |
| Botão do teclado no mapeamento padrão | Won't | Decisão do usuário (RN-10) |
| Navegar pelas teclas com o direcional, sem ponteiro | Won't | Fora do pedido; o ponteiro já cobre o acionamento |
| Personalizar o conteúdo ou o leiaute do teclado do sistema pelo app | Won't | O app não altera preferências do sistema (RN-08) |
| Sugestões de palavras e autocompletar | Won't | Fora do pedido |

## 9. Esclarecimentos

### Sessão 2026-09-16

- **Q:** Se os testes no hardware mostrarem que o teclado do macOS não pode ser aberto e fechado por um único botão, ou que não aceita os cliques simulados pelo controle, qual caminho seguimos?
  **R:** (a) Aceitar um passo extra: o botão abre um painel do sistema e o usuário escolhe o teclado nele. Integrado em RN-01, RN-02 e RF-01; o teclado próprio do app fica fora, inclusive como plano B.
- **Q:** O botão do teclado deve vir configurado de fábrica?
  **R:** (c) Não; o usuário configura pelo editor. Integrado em RN-10 e RF-06.
- **Q:** Qual critério de tamanho vale para as teclas do teclado virtual a 3 m?
  **R:** (a) Basta o tamanho que o próprio macOS permite ajustar, conferido no teste de sofá. Integrado em RN-11, RF-07 e RF-08.
- **Q:** Além do botão, o teclado deve se ocultar sozinho em alguma situação?
  **R:** (a) Não, só pelo botão. Integrado em RN-09 e RF-05.

## 10. Lacunas

- n/a: nenhuma dúvida pendente.
- 🟡 Risco residual, sem decisão pendente: o passo extra escolhido em D-01 resolve o acionamento, mas não o caso de o teclado do sistema recusar os cliques simulados pelo ponteiro. Se a sonda confirmar essa recusa, RF-02 não tem caminho de entrega, e a continuidade da feature volta ao usuário no portão manual.

## Pendências de Qualidade

- Q-018 (nome de produto): o documento cita o macOS, o Teclado de Acessibilidade e o Raycast. As citações foram mantidas porque o teclado do sistema é restrição declarada pelo usuário e o Raycast é precedente do legado, não escolha de implementação.

## 11. Histórico de alterações

| Data | Alteração | Autor |
|------|-----------|-------|
| 2026-09-16 | Versão inicial gerada por `/reversa-requirements` | reversa |
| 2026-09-16 | Sessão do `/reversa-clarify`: D-01 a D-03 resolvidas e fechamento automático descartado (RN-09 a RN-11) | reversa |
