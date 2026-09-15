# Requirements: Paleta de comandos pelo controle

> Identificador: `002-paleta-comandos`
> Data: `2026-09-14`
> Pasta da extração reversa: `_reversa_sdd/`
> Confidência: 🟢 CONFIRMADO, 🟡 INFERIDO ou PLANEJADO, 🔴 LACUNA / DÚVIDA

> **Nota de confidência:** as specs em `_reversa_sdd/sdd/` nasceram do `/reversa-new` com selo 🟡 PLANEJADO. Recebem 🟢 os fatos observados na entrega da feature 001, registrados em `_reversa_sdd/addenda/001-poc-entrada-ponteiro.md`, as necessidades declaradas pelo usuário ao pedir esta feature e as decisões da sessão de esclarecimentos (seção 9).

> **Recorte:** a ideia original reunia um editor visual de atalhos e uma paleta de comandos. Por decisão do usuário (seção 9, pergunta 1), esta feature entrega só a paleta, com lista fixa. O editor, a configuração persistida e a paleta editável ficam para a feature seguinte, com o material já levantado preservado em [`backlog-editor.md`](./backlog-editor.md).

## 1. Resumo executivo

A feature acrescenta ao app uma **paleta de comandos**: uma lista sobreposta à tela, aberta pelo botão PS do DualSense, da qual o programador de sofá escolhe com o direcional um comando do Reversa ou do Claude Code para ser digitado no aplicativo em foco. Resolve a principal limitação de condução pelo controle: os comandos do Reversa só são acionados quando digitados literalmente com a barra, e sobram poucos botões para associá-los um a um. A lista é fixa nesta entrega; os demais atalhos do protótipo não mudam.

## 2. Contexto a partir do legado

Não existem `architecture.md`, `domain.md`, `inventory.md`, `code-analysis.md` nem `.reversa/principles.md`. O contexto vem das specs do `/reversa-new` e do adendo vigente da feature 001, que corrige a leitura das specs para o que foi de fato entregue.

| Fonte | Trecho relevante | Confidência |
|-------|------------------|-------------|
| `_reversa_sdd/addenda/001-poc-entrada-ponteiro.md#Impacto por artefato da extração` | Existe um protótipo de atalhos com mapeamento fixo no código (setas, Enter, Esc, Backspace, Tab, L1+✕ `CONTINUAR`, L1+△ Shift+Tab, Create para Mission Control, L2 como camada de mesas e janelas, Options segurando Command, R3 com Command+M); PS não tem ação. | 🟢 |
| `_reversa_sdd/addenda/001-poc-entrada-ponteiro.md#Impacto por artefato da extração` | O botão PS só chega ao app com "Pressione o Botão de Início para abrir" em "Nenhum" nos Ajustes do Sistema; o log não registra coordenadas nem teclas; na retomada após perda de permissão, as solturas de teclas são repetidas. | 🟢 |
| `_reversa_sdd/sdd/action-mapping.md#6.1 Requisitos Principais` | RF-09 (ação de texto com Enter opcional) e RF-10 (repetição após 400 ms, a cada 50 ms). | 🟡 |
| `_reversa_sdd/sdd/action-mapping.md#8. Design e Interface` | O mapeamento planejado reservava L1+↑ para digitar `/reversa-forward`; a paleta substitui a associação de comandos um a um. | 🟡 |
| `_reversa_sdd/sdd/action-mapping.md#11. Edge Cases e Tratamento de Erros` | EC-05 (desconexão sem tecla presa) e EC-06 (texto descartado por campo seguro, sem registro em log). | 🟡 |
| `_reversa_sdd/sdd/action-mapping.md#12. Segurança e Privacidade` | O log não registra o conteúdo das ações de texto nem as teclas injetadas. | 🟡 |
| `_reversa_sdd/sdd/action-mapping.md#4. Non-Goals (Fora do Escopo)` | NG-04: sem execução de scripts de shell. | 🟡 |
| `_reversa_sdd/sdd/action-mapping.md#14. Open Questions` | OQ-02: o texto digitado funciona em todos os terminais usados? | 🟡 |
| `_reversa_sdd/sdd/action-mapping.md#7. Requisitos Não-Funcionais` | RNF-01 (30 ms no percentil 95 até a ação) e RNF-03 (texto independente do layout do teclado). | 🟡 |
| `_reversa_sdd/personas.md#Jornada principal` | Passo 4: acionar comandos do Reversa (`/reversa-forward`, `CONTINUAR`) por botões ou combinações. | 🟡 |
| `_reversa_sdd/personas.md#Persona 1: Programador de sofá` | Uso no sofá, com o Mac ligado ou não à TV. | 🟡 |

## 3. Personas e cenários de uso

| Persona | Objetivo | Cenário-chave |
|---------|----------|---------------|
| Programador de sofá (`_reversa_sdd/personas.md#Persona 1: Programador de sofá`) | Disparar comandos do Reversa sem teclado. | Com o Claude Code em foco no terminal, pressiona PS, desce até `/reversa-plan` e confirma com ✕; o comando é digitado e enviado. Várias vezes por sessão. |
| Programador de sofá | Iniciar um comando que espera descrição. | Confirma `/reversa-requirements ` na paleta; o texto fica na linha sem ser enviado, e ele completa a descrição pelo ditado em R3. |
| Programador de sofá | Gerenciar a conversa do Claude Code. | Ao fim de uma etapa, confirma `/compact` ou `/clear` na paleta sem sair do sofá. |

## 4. Regras de negócio novas ou alteradas

Termo usado nesta seção e nas seguintes:

- **Paleta de comandos:** lista sobreposta à tela, operada pelo controle, cujos itens digitam um texto no aplicativo em foco.

1. **RN-01:** PS abre a paleta quando pressionado sem modificador ou com L1 ou L2 segurados, que no protótipo repassam à camada base os botões sem ação própria. Com Options segurado, PS não faz nada, como os demais botões sem ação nessa camada. 🟢
   - Origem no legado: `_reversa_sdd/addenda/001-poc-entrada-ponteiro.md#Impacto por artefato da extração`
   - Tipo: nova
2. **RN-02:** A paleta nunca se torna o aplicativo em foco. O texto confirmado é digitado no aplicativo em foco no momento da confirmação. 🟢
   - Tipo: nova
3. **RN-03:** Enquanto a paleta está aberta, ↑ e ↓ movem a seleção, ✕ confirma e ○ ou PS fecham; nenhum desses botões gera tecla. Os demais atalhos ficam suspensos, e o movimento do cursor, a rolagem e os cliques continuam funcionando. 🟢
   - Tipo: nova
4. **RN-04:** Abrir a paleta solta antes as teclas e as teclas modificadoras mantidas pelo controle e interrompe a repetição em curso. 🟡
   - Origem no legado: `_reversa_sdd/sdd/action-mapping.md#11. Edge Cases e Tratamento de Erros` (EC-05)
   - Tipo: nova
5. **RN-05:** Cada item tem um texto de uma única linha e a indicação de Enter ao final. Itens que esperam complemento terminam com espaço e não têm Enter. 🟡
   - Tipo: nova
6. **RN-06:** A paleta apenas digita texto; nenhum item executa programa ou comando de shell. 🟡
   - Origem no legado: `_reversa_sdd/sdd/action-mapping.md#4. Non-Goals (Fora do Escopo)` (NG-04)
   - Tipo: nova
7. **RN-07:** O log registra abertura, confirmação com o índice do item e fechamento com o motivo, mas nunca o texto dos itens nem as teclas injetadas. 🟢
   - Origem no legado: `_reversa_sdd/sdd/action-mapping.md#12. Segurança e Privacidade`, `_reversa_sdd/addenda/001-poc-entrada-ponteiro.md#Impacto por artefato da extração`
   - Tipo: nova
8. **RN-08:** Todos os atalhos do protótipo, exceto o de PS, mantêm o comportamento atual. 🟢
   - Origem no legado: `_reversa_sdd/addenda/001-poc-entrada-ponteiro.md#Impacto por artefato da extração`
   - Tipo: nova

### Lista fixa da paleta

Dezessete itens, na ordem, com o próprio texto como rótulo: 🟢

| # | Texto | Enter ao final |
|---|-------|----------------|
| 1 | `CONTINUAR` | sim |
| 2 | `/reversa-forward` | sim |
| 3 | `/reversa-requirements ` | não |
| 4 | `/reversa-clarify` | sim |
| 5 | `/reversa-plan` | sim |
| 6 | `/reversa-to-do` | sim |
| 7 | `/reversa-coding` | sim |
| 8 | `/reversa-add ` | não |
| 9 | `/reversa-audit` | sim |
| 10 | `/reversa-quality` | sim |
| 11 | `/reversa-sync` | sim |
| 12 | `/reversa-resume` | sim |
| 13 | `/reversa-debugger ` | não |
| 14 | `/reversa` | sim |
| 15 | `/clear` | sim |
| 16 | `/compact` | sim |
| 17 | `/resume` | sim |

## 5. Requisitos Funcionais

| ID | Requisito | Prioridade | Critério de aceite | Confidência |
|----|-----------|------------|--------------------|-------------|
| RF-01 | O sistema deve exibir a paleta quando PS for pressionado nas condições de RN-01, sobre a tela onde está o cursor e sem tirar o foco do aplicativo em uso. | Must | Com o terminal em foco, pressionar PS exibe a paleta e o terminal continua sendo o aplicativo em foco. | 🟢 |
| RF-02 | A paleta deve mover a seleção com ↑ e ↓, com repetição após 400 ms a cada 50 ms enquanto o botão estiver pressionado e com passagem do último para o primeiro item e vice-versa. | Must | Com o primeiro item selecionado, ↑ seleciona o 17.º; segurar ↓ por 1 s avança ao menos 10 posições. | 🟢 |
| RF-03 | A paleta deve fechar sem digitar quando o usuário pressionar ○ ou PS. | Must | Com a paleta aberta, ○ a fecha e nenhum texto chega ao aplicativo em foco. | 🟢 |
| RF-04 | Ao confirmar um item com ✕, o sistema deve fechar a paleta e digitar o texto do item no aplicativo em foco, com Enter ao final se o item assim estiver definido. | Must | Com o Claude Code em foco, confirmar `/reversa-forward` executa o comando; confirmar `/reversa-requirements ` deixa o texto na linha, sem enviar. | 🟢 |
| RF-05 | A paleta deve oferecer os 17 itens da lista fixa da seção 4, na ordem definida. | Must | Ao abrir, a paleta mostra `CONTINUAR` no topo e `/resume` no fim, com os 17 itens. | 🟢 |
| RF-06 | Enquanto a paleta estiver aberta, o sistema deve suspender os atalhos, exceto os botões de RN-03, mantendo movimento do cursor, rolagem e cliques. | Must | Com a paleta aberta, □ não envia Backspace e o analógico esquerdo move o cursor. | 🟢 |
| RF-07 | O sistema deve manter inalterados todos os atalhos do protótipo, exceto o de PS. | Must | Após a entrega, ✕ envia Enter, L1+✕ envia `CONTINUAR` e L2+← troca de mesa, como antes. | 🟢 |
| RF-08 | A paleta deve abrir com o último item confirmado selecionado, enquanto o app estiver em execução; na primeira abertura, com o primeiro item. | Should | Confirmar `/reversa-plan` e reabrir a paleta seleciona `/reversa-plan`. | 🟡 |
| RF-09 | A paleta deve fechar sem digitar quando o controle desconectar, quando a permissão de Acessibilidade for revogada ou após 60 s sem entrada do controle. | Should | Abrir a paleta e desligar o controle fecha a paleta; nada é digitado. | 🟡 |

## 6. Requisitos Não Funcionais

| Tipo | Requisito | Evidência ou justificativa | Confidência |
|------|-----------|----------------------------|-------------|
| Desempenho | A paleta fica visível em até 150 ms após o pressionar de PS. | Abaixo desse tempo, a resposta é percebida como imediata; a paleta substitui uma ação que hoje seria um toque de botão. | 🟡 |
| Desempenho | A digitação do texto começa em até 30 ms (percentil 95) após a confirmação. | `_reversa_sdd/sdd/action-mapping.md#7. Requisitos Não-Funcionais` (RNF-01). | 🟡 |
| Legibilidade | A paleta é legível a 3 m de uma TV: texto dos itens com pelo menos 24 pt e item selecionado destacado por cor e por forma. Em telas com 900 pt de altura ou mais, os 17 itens ficam visíveis sem rolar; em telas menores, a lista rola acompanhando a seleção. | Contexto do sofá em `_reversa_sdd/personas.md#Persona 1: Programador de sofá`. | 🟡 |
| Compatibilidade | O texto digitado independe do layout do teclado (ABNT2 ou US). | `_reversa_sdd/sdd/action-mapping.md#7. Requisitos Não-Funcionais` (RNF-03). | 🟡 |
| Compatibilidade | Os comandos da paleta funcionam no Terminal e no terminal integrado do VS Code. | `_reversa_sdd/sdd/action-mapping.md#14. Open Questions` (OQ-02). | 🟡 |
| Privacidade | Log sem texto de itens nem teclas injetadas. | RN-07. | 🟢 |
| Observabilidade | O log registra abertura da paleta, confirmação com o índice do item e fechamento com o motivo (○, PS, desconexão, permissão, inatividade). | Log JSON Lines existente desde a feature 001. | 🟡 |
| Recursos | Com a paleta fechada, o app não consome CPU acima do medido em repouso na feature 001. | Validação de CPU em repouso registrada no adendo da feature 001. | 🟡 |
| Robustez | Nenhuma abertura, confirmação ou fechamento da paleta deixa tecla ou modificador presos. | RN-04. | 🟡 |

## 7. Critérios de Aceitação

```gherkin
# Cobre: RF-01, RF-04, RF-05
Cenário: Comando do Reversa pela paleta
  Dado o Claude Code em foco no terminal
  Quando o usuário pressiona PS, desce até /reversa-forward e pressiona ✕
  Então a paleta fecha e /reversa-forward é digitado e enviado com Enter
  E o terminal permaneceu em foco durante toda a operação

# Cobre: RF-01
Cenário: PS com modificador segurado
  Dado o terminal em foco
  Quando o usuário segura L1 e pressiona PS
  Então a paleta abre
  E, segurando Options e pressionando PS, nada acontece

# Cobre: RF-02
Cenário: Navegação circular e repetição
  Dado a paleta aberta com o primeiro item selecionado
  Quando o usuário pressiona ↑
  Então o 17.º item, /resume, fica selecionado
  E segurar ↓ por 1 s avança ao menos 10 posições

# Cobre: RF-03
Cenário: Fechar sem digitar
  Dado a paleta aberta com /clear selecionado
  Quando o usuário pressiona ○
  Então a paleta fecha e nada é digitado
  E, reaberta e fechada com PS, também nada é digitado

# Cobre: RF-04
Cenário: Comando que espera descrição
  Dado o Claude Code em foco no terminal
  Quando o usuário confirma /reversa-requirements na paleta
  Então o texto fica na linha de comando, com o espaço final, sem ser enviado

# Cobre: RF-04
Cenário: Campo seguro em foco
  Dado um campo de senha em foco
  Quando o usuário confirma CONTINUAR na paleta
  Então a paleta fecha, o macOS descarta o texto, o app não repete a tentativa e o log não contém o texto

# Cobre: RF-05
Cenário: Conteúdo da lista
  Dado o app em execução
  Quando o usuário abre a paleta
  Então os 17 itens aparecem na ordem da seção 4, de CONTINUAR a /resume

# Cobre: RF-06
Cenário: Atalhos suspensos e ponteiro ativo
  Dado a paleta aberta
  Quando o usuário pressiona □, move o analógico esquerdo e pressiona R1
  Então nenhum Backspace é enviado, o cursor se move e o clique esquerdo acontece

# Cobre: RF-06, RN-04
Cenário: Repetição em curso ao abrir
  Dado □ segurado, apagando em repetição no aplicativo em foco
  Quando o usuário pressiona PS
  Então a repetição para antes de a paleta aparecer e nenhum Backspace fica preso

# Cobre: RF-07
Cenário: Atalhos do protótipo preservados
  Dado o app com a feature entregue e a paleta fechada
  Quando o usuário pressiona ✕, depois L1+✕ e depois L2+←
  Então ✕ envia Enter, L1+✕ digita CONTINUAR com Enter e L2+← troca para a mesa à esquerda

# Cobre: RF-08
Cenário: Último item lembrado
  Dado que o usuário confirmou /reversa-plan na paleta
  Quando reabre a paleta
  Então /reversa-plan está selecionado

# Cobre: RF-09
Cenário: Desconexão com a paleta aberta
  Dado a paleta aberta
  Quando o controle é desligado
  Então a paleta fecha, nada é digitado e o log registra o fechamento por desconexão

# Cobre: RF-09
Cenário: Permissão revogada com a paleta aberta
  Dado a paleta aberta
  Quando a permissão de Acessibilidade é revogada
  Então a paleta fecha e nada é digitado

# Cobre: RF-09
Cenário: Inatividade
  Dado a paleta aberta
  Quando passam 60 s sem entrada do controle
  Então a paleta fecha e nada é digitado

# Cobre: RN-07
Cenário: Privacidade do log
  Dado a depuração ligada
  Quando o usuário confirma o item CONTINUAR
  Então o log registra a confirmação com o índice 1
  E nenhuma linha do log contém "CONTINUAR"
```

## 8. Prioridade MoSCoW

| Item | MoSCoW | Justificativa |
|------|--------|---------------|
| RF-01 a RF-06 | Must | Acionar os comandos do Reversa sem digitar é a necessidade declarada e o passo 4 da jornada. |
| RF-07 | Must | A paleta não pode quebrar o fluxo de atalhos que o usuário já usa. |
| RNF de desempenho, legibilidade e privacidade | Must | A paleta só substitui a digitação se for rápida e legível do sofá; a privacidade do log é regra vigente. |
| RF-08, RF-09 | Should | Conforto e segurança; RN-04 já garante que nada fica preso. |
| Editor visual de atalhos, configuração persistida e paleta editável | Won't | Decisão do usuário: feature seguinte, a partir de [`backlog-editor.md`](./backlog-editor.md). |
| Item "Editar atalhos" na paleta e ícone na barra de menus | Won't | Pontos de entrada do editor (seção 9, pergunta 4); chegam com o editor. |
| Abrir aplicativo, toque curto e longo, troca dos botões de clique | Won't | Decisão do usuário (seção 9, pergunta 2). |
| Grupos na paleta trocados com ← e → | Won't | Opção não escolhida na pergunta 5; a lista única atende. |

## 9. Esclarecimentos

### Sessão 2026-09-14

- **Q:** Como dividir a entrega: uma feature única com editor, configuração e paleta, ou duas?
  **R:** Duas features: primeiro a paleta com lista fixa; depois o editor com a configuração persistida e a paleta editável. Integrado no recorte do topo, na seção 1, em RF-05 e na seção 8; o material do editor foi preservado em `backlog-editor.md`, e a pasta da feature passou a se chamar `002-paleta-comandos`.
- **Q:** Além de tecla, atalho de sistema, texto, abrir a paleta e nenhuma, que tipos de ação entram?
  **R:** Nenhum outro; abrir aplicativo, toque curto e longo e troca dos botões de clique ficam para depois. Integrado na seção 8 e registrado em `backlog-editor.md`, pois os tipos de ação só se aplicam ao editor.
- **Q:** Como a paleta deve funcionar?
  **R:** Tocar em PS abre; o direcional escolhe; ✕ digita; ○ ou outro toque em PS fecha. Integrado em RN-03, RF-01 a RF-04 e nos cenários de navegação e fechamento.
- **Q:** Por onde se abre o editor de atalhos?
  **R:** Por um ícone mínimo na barra de menus e por um item fixo no fim da paleta. Como o editor saiu desta feature, a decisão foi registrada em `backlog-editor.md` e na seção 8 como Won't nesta entrega.
- **Q:** Que comandos a paleta traz de fábrica?
  **R:** Os do Reversa e alguns do Claude Code muito usados: `/clear`, `/compact` e `/resume`. Integrado na lista fixa da seção 4 (17 itens) e em RF-05.

## 10. Lacunas

- 🟡 **Enter após comando com barra.** Ao digitar `/reversa-forward`, o Claude Code exibe sugestões de autocompletar; é preciso verificar se o Enter executa o comando digitado ou aceita outra sugestão, e se há atraso mínimo necessário entre o texto e o Enter. Verificação manual do plano, não decisão.
- 🟡 **Paleta sobre tela cheia e outras mesas.** Resta verificar no plano se a paleta aparece sobre aplicativos em tela cheia e na mesa ativa.
- 🟡 **Confirmação acidental de `/clear`.** O item apaga a conversa do Claude Code sem pedir confirmação. A posição próxima ao fim da lista reduz, mas não elimina, o risco; convém observar no uso real antes de decidir por uma confirmação.
- 🟡 **Convergência nas specs.** A paleta é componente novo, não previsto em `action-mapping`, e substitui a associação planejada de L1+↑ a `/reversa-forward`; o `/reversa-sync` deve registrá-lo.

## 11. Histórico de alterações

| Data | Alteração | Autor |
|------|-----------|-------|
| 2026-09-14 | Versão inicial gerada por `/reversa-requirements`, com editor e paleta | reversa |
| 2026-09-14 | Sessão de esclarecimentos: cinco perguntas respondidas e três dúvidas resolvidas; recorte reduzido à paleta com lista fixa de 17 itens; editor preservado em `backlog-editor.md`; pasta renomeada de `002-editor-atalhos-paleta` para `002-paleta-comandos` | reversa |

## Pendências de Qualidade

- **Q-018 (produto comercial no documento), exceção assumida.** DualSense, macOS, Claude Code, VS Code, Terminal e Raycast aparecem porque são o domínio do problema e os ambientes de uso, não escolhas de solução. Frameworks e APIs de implementação ficam para o `/reversa-plan`.
- **Q-011 e Q-019, não aplicáveis.** Não existem `_reversa_sdd/domain.md` nem `.reversa/principles.md`; as regras citam as specs SDD e o adendo da feature 001 como origem.
