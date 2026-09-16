# Requirements: Atalhos de zoom montados pelo controle

> Identificador: `005-sinais-matematicos`
> Data: `2026-09-16`
> Pasta da extração reversa: `_reversa_sdd/`
> Confidência: 🟢 CONFIRMADO, 🟡 INFERIDO, 🔴 LACUNA / DÚVIDA

## 1. Resumo executivo

A feature permite que o programador de sofá monte pelo controle, no editor de atalhos, os acordes de aumentar e diminuir o zoom, ⌘+ e ⌘-, escolhendo diretamente os sinais `+` e `-`. Hoje o sinal `-` já está na grade de montagem, mas o `+` não existe como tecla: o usuário precisa saber que ⌘+ equivale a ⌘⇧= e montá-lo assim, e o editor exibe o resultado como "⌘⇧=", não como "⌘+". A feature acrescenta o `+` à grade e passa a exibir o acorde com o sinal. O formato do arquivo de configuração, a validação, a execução dos acordes e o log não mudam.

## 2. Contexto a partir do legado

| Fonte | Trecho relevante | Confidência |
|-------|------------------|-------------|
| `_reversa_sdd/domain.md#1. Propósito do domínio` | O usuário-alvo acompanha agentes na TV a cerca de 3 m e deseja passar a maior parte do tempo sem teclado | 🟢 |
| `_reversa_sdd/domain.md#2. Glossário` | Acorde: tecla do catálogo com zero ou mais modificadores, opcionalmente com repetição | 🟢 |
| `_reversa_sdd/atalhos/requirements.md#Regras de Negócio` | RN-AT-18: o catálogo tem 73 teclas com nome estável, entre elas 11 pontuações; as teclas são posições físicas, independentes do layout; tecla fora do catálogo não pode ser gravada | 🟢 |
| `_reversa_sdd/code-analysis.md#5.3 Catálogos` | O grupo de pontuação contém `-`, `=`, `[`, `]`, `\`, `;`, `'`, `,`, `.`, `/` e `` ` ``; não há `+` | 🟢 |
| `_reversa_sdd/editor/requirements.md#Regras de Negócio` | RN-ED-13: escala de TV com corpo de 32 pt e alvo mínimo de 60 pt; RN-ED-14: a figura resume o acorde por símbolos; RN-ED-17: acorde montado pelo ponteiro (quatro modificadores, grupo de teclas, grade do catálogo) ou gravado pelo teclado | 🟢 |
| `_reversa_sdd/editor/requirements.md#Requisitos Funcionais` | RF-ED-05: montar e gravar acordes, com o critério "montar ⌘⇧T só com o ponteiro" | 🟢 |
| `_reversa_sdd/domain.md#3.3 Atalhos, configuração e editor (003)` | 003 RN-06: o acorde admite repetição opcional; 003 RN-14: o log não registra acordes | 🟢 |
| `_reversa_sdd/injecao-de-eventos/requirements.md#Regras de Negócio` | Os acordes são postados por tecla virtual com os modificadores mantidos, como o teclado físico faria | 🟢 |
| `_reversa_sdd/addenda/004-figura-controle-web.md#Atualização 2026-09-16` | A figura do controle, em página web embutida, mostra o resumo recebido do editor; os grupos de botões do editor de acorde quebram linha conforme a largura (E002) | 🟢 |

**Constatação.** Com o legado atual, ⌘- já pode ser montado pela tecla `-`, e ⌘+ pode ser montado como ⌘⇧= (ou ⌘=, que muitos aplicativos também aceitam para aumentar o zoom). A lacuna é de descoberta e de leitura: o sinal `+` não aparece na grade nem no resumo. 🟢

## 3. Personas e cenários de uso

| Persona | Objetivo | Cenário-chave |
|---------|----------|---------------|
| Programador de sofá (`_reversa_sdd/personas.md#Persona 1: Programador de sofá`) | Ampliar e reduzir o texto do editor de código ou do terminal visto na TV | No editor de atalhos, seleciona ↑ na camada L1, escolhe Acorde, liga ⌘ e aciona `+` na grade; faz o mesmo com ↓ e `-`; salva, e L1 + ↑ e L1 + ↓ passam a aumentar e diminuir o zoom |

A configuração é feita uma vez; o uso dos dois atalhos se repete ao longo da sessão, sobretudo ao alternar entre a mesa e a TV. 🟡

## 4. Regras de negócio novas ou alteradas

1. **RN-01:** O sinal `+` é a tecla `=` com ⇧, que é como o teclado físico o produz nos layouts US Internacional e ABNT2, em que os dois sinais ocupam a mesma tecla. Assim, o ⌘+ montado chega ao aplicativo exatamente como o ⌘+ digitado no teclado físico. 🟡
   - Origem no legado: `_reversa_sdd/atalhos/requirements.md#Regras de Negócio` (RN-AT-18)
   - Tipo: nova
2. **RN-02:** Escolher `+` na grade seleciona a tecla `=` e liga ⇧, preservando os demais modificadores já ligados. Desligar ⇧ depois disso deixa o acorde com a tecla `=`, exibido com `=`. 🟡
   - Origem no legado: `_reversa_sdd/editor/requirements.md#Regras de Negócio` (RN-ED-17)
   - Tipo: alterada (a montagem ganha uma escolha que atua em tecla e modificador ao mesmo tempo)
3. **RN-03:** Todo acorde com a tecla `=` e ⇧ é exibido com `+` no lugar de ⇧=, mantendo os demais modificadores na ordem ⌃⌥⌘: ⌘⇧= aparece como "⌘+". A regra vale no resumo do painel, na grade de montagem, na figura do controle e para acordes gravados pelo teclado ou lidos do arquivo. 🟡
   - Origem no legado: `_reversa_sdd/editor/requirements.md#Regras de Negócio` (RN-ED-14)
   - Tipo: alterada
4. **RN-04:** O sinal `-` continua sendo a tecla `-` já existente, sem modificador implícito, e aparece na grade junto do `+`. 🟢
   - Origem no legado: `_reversa_sdd/code-analysis.md#5.3 Catálogos`
   - Tipo: alterada (só a vizinhança na grade)
5. **RN-05:** O arquivo de configuração não ganha nome de tecla, campo nem tipo novo: um ⌘+ montado é gravado de forma idêntica ao ⌘⇧= montado hoje, e um arquivo existente com ⌘⇧= continua válido e passa a ser exibido como ⌘+. 🟡
   - Origem no legado: `_reversa_sdd/configuracao/requirements.md#Regras de Negócio` (RN-CF-14)
   - Tipo: nova
6. **RN-06:** O log continua sem registrar teclas nem acordes; nenhum evento novo é criado. 🟢
   - Origem no legado: `_reversa_sdd/domain.md#3.3 Atalhos, configuração e editor (003)` (003 RN-14)
   - Tipo: alterada (a restrição passa a cobrir a nova escolha)

## 5. Requisitos Funcionais

| ID | Requisito | Prioridade | Critério de aceite | Confidência |
|----|-----------|------------|--------------------|-------------|
| RF-01 | A grade de montagem de acordes oferece o sinal `+`, no mesmo grupo e ao lado do `-` (RN-01, RN-04) | Must | No grupo de pontuação, `+` aparece imediatamente ao lado de `-` | 🟢 |
| RF-02 | Escolher `+` monta a tecla `=` com ⇧, preservando os modificadores já ligados (RN-02) | Must | Com ⌘ ligado, acionar `+` pelo ponteiro deixa o acorde com ⌘ e ⇧ ligados e a tecla `=` | 🟢 |
| RF-03 | O acorde com `=` e ⇧ é exibido com `+` no painel e na figura (RN-03) | Must | O acorde do passo anterior aparece como "⌘+" no painel e no balão do botão na figura | 🟢 |
| RF-04 | Os atalhos montados aumentam e diminuem o zoom no aplicativo em foco | Must | Com ⌘+ em L1 + ↑ e ⌘- em L1 + ↓, o editor de código e o terminal em foco ampliam e reduzem o texto a cada pressionar | 🟡 |
| RF-05 | O `+` segue a escala de TV (RN-ED-13) | Must | O botão `+` tem alvo de pelo menos 60 pt e é legível a 3 m | 🟢 |
| RF-06 | O arquivo não muda de formato (RN-05) | Must | Um ⌘+ salvo é gravado igual a um ⌘⇧= montado na versão anterior; um arquivo anterior com ⌘⇧= abre e é exibido como ⌘+ | 🟢 |
| RF-07 | O ⌘+ gravado pelo teclado físico é exibido como ⌘+ | Should | Com a gravação pelo teclado ativa, pressionar ⌘+ no teclado resulta em "⌘+" | 🟢 |

## 6. Requisitos Não Funcionais

| Tipo | Requisito | Evidência ou justificativa | Confidência |
|------|-----------|----------------------------|-------------|
| Usabilidade | Montar ⌘+ e ⌘-, da abertura do editor à gravação, pode ser concluído sem teclado físico nem mouse | Objetivo do produto em `_reversa_sdd/domain.md#1. Propósito do domínio` | 🟢 |
| Usabilidade | Alvo de pelo menos 60 pontos (pt) e texto de pelo menos 32 pt no botão `+` | `_reversa_sdd/editor/requirements.md#Regras de Negócio` (RN-ED-13) | 🟢 |
| Compatibilidade | O ⌘+ montado produz o mesmo efeito que o ⌘+ digitado no teclado físico, nos layouts US Internacional (o do usuário) e ABNT2 | RN-01; `_reversa_sdd/atalhos/requirements.md#Regras de Negócio` (RN-AT-18) | 🟡 |
| Compatibilidade | Configurações existentes continuam válidas sem migração | RN-05; `_reversa_sdd/architecture.md#5. Modelo de dados em arquivo` (sem migração de esquema) | 🟢 |
| Segurança e privacidade | Nenhum acorde chega ao log | `_reversa_sdd/domain.md#3.3 Atalhos, configuração e editor (003)` (003 RN-14) | 🟢 |
| Testabilidade | As regras de montagem e de exibição do `+` são verificáveis por testes automatizados, sem controle nem janela | `_reversa_sdd/architecture.md#2. Estilo arquitetural` | 🟢 |
| Observabilidade | n/a: nenhum evento de log é criado (RN-06) | `_reversa_sdd/domain.md#3.3 Atalhos, configuração e editor (003)` | 🟢 |

## 7. Critérios de Aceitação

```gherkin
Cenário: Montar o zoom in só com o ponteiro
  Dado o editor aberto na camada L1, com ↑ selecionado e o tipo Acorde
  Quando o usuário liga ⌘ e aciona "+" na grade, com o R1
  E aciona "Salvar"
  Então o acorde aparece como "⌘+" no painel e no balão de ↑ na figura
  E pressionar L1 + ↑ com o editor de código em foco aumenta o zoom

Cenário: Montar o zoom out só com o ponteiro
  Dado o editor aberto na camada L1, com ↓ selecionado e o tipo Acorde
  Quando o usuário liga ⌘ e aciona "-" na grade
  E aciona "Salvar"
  Então o acorde aparece como "⌘-"
  E pressionar L1 + ↓ com o editor de código em foco diminui o zoom

Cenário: Localizar o sinal de soma
  Dado a grade de montagem no grupo de pontuação
  Quando a grade é exibida
  Então "+" aparece ao lado de "-", com alvo de pelo menos 60 pt

Cenário: Escolher "+" preserva os modificadores ligados
  Dado um acorde com ⌘ e ⌥ ligados
  Quando o usuário aciona "+"
  Então o acorde tem ⌘, ⌥ e ⇧ ligados e a tecla "="
  E é exibido como "⌥⌘+"

Cenário: Desligar o Shift desfaz o sinal de soma
  Dado o acorde "⌘+"
  Quando o usuário desliga ⇧
  Então o acorde passa a ser exibido como "⌘="

Cenário: Arquivo anterior exibido com o sinal
  Dado um arquivo de configuração gravado antes da feature com ⌘⇧= em L1 + ↑
  Quando o editor é aberto
  Então o arquivo é aceito sem erro
  E L1 + ↑ aparece como "⌘+"

Cenário: Arquivo gravado sem formato novo
  Dado o acorde "⌘+" salvo em L1 + ↑
  Quando o arquivo de configuração é aberto num editor de texto
  Então a ação contém a tecla "=" com os modificadores ⌘ e ⇧, sem nome de tecla novo

Cenário: Gravação pelo teclado físico
  Dado a gravação pelo teclado ativa
  Quando o usuário pressiona ⌘+ no teclado
  Então o acorde aparece como "⌘+"

Cenário: Log sem acorde
  Dado o log de diagnóstico ativo
  Quando o usuário monta, salva e usa ⌘+
  Então nenhuma linha do log contém o acorde
```

## 8. Prioridade MoSCoW

| Item | MoSCoW | Justificativa |
|------|--------|---------------|
| RF-01 | Must | É o pedido: escolher o `+` diretamente |
| RF-02 | Must | Sem ⇧ implícito, o `+` não reproduz o ⌘+ do teclado |
| RF-03 | Must | Sem exibição com `+`, o usuário não reconhece o atalho montado |
| RF-04 | Must | É o objetivo final: aumentar e diminuir o zoom |
| RF-05 | Must | Uso do sofá |
| RF-06 | Must | Preserva configurações e edição manual |
| RF-07 | Should | Coerência na mesa; não afeta o uso pelo controle |
| RNF de compatibilidade de layout | Should | O usuário usa um só layout; ABNT2 é verificação de robustez |
| Outros sinais (`*`, `%`, `^`, `(`, `)`, `<`, `>`) | Won't | Fora do escopo definido pelo usuário |
| Sinais de notação matemática e digitação de sinais como texto | Won't | Fora do escopo definido pelo usuário |
| Teclas do teclado numérico | Won't | Fora do escopo; RN-01 reproduz o teclado principal |

## 9. Esclarecimentos

### Sessão 2026-09-16

- **Q:** O pedido é que o botão digite o sinal como texto, que acordes de teclado usem sinais (como ⌘+), ou as duas coisas?
  **R:** Acordes de teclado com sinais (1b). Numa segunda rodada, o usuário restringiu o escopo: "Eu apenas quero poder montar os atalhos de zoom in e zoom out. É apenas esse o escopo." O documento foi reescrito em torno de ⌘+ e ⌘-.
- **Q:** Quais sinais devem aparecer (teclado comum, notação matemática, ambos ou com acréscimos)?
  **R:** Ambos os grupos (2a), resposta superada pela restrição de escopo: ficam só `+` e `-`. A notação matemática não existe como tecla e não caberia em acorde.
- **Q:** Os dígitos de 0 a 9 e o espaço entram nesta feature?
  **R:** "Eles já estão contemplados." Confirmado no catálogo: os dígitos formam um grupo próprio e o espaço está no grupo de edição.
- **Q:** Onde o sinal deve entrar no texto?
  **R:** Sempre no fim (4a); não se aplica, porque a feature deixou de inserir texto.
- **Q:** O rótulo dos itens da paleta também deve receber os sinais?
  **R:** O usuário não entendeu a pergunta; ela se referia ao nome curto exibido na paleta no lugar do texto e deixou de se aplicar com a resposta 1b.
- **Q:** Como o `+` deve ser enviado: como no teclado principal (`=` com ⇧), pelo teclado numérico ou misto?
  **R:** Sem resposta explícita. Adotado o teclado principal (RN-01), por reproduzir o ⌘+ que o usuário digita no teclado físico e por não depender de como cada aplicativo trata o teclado numérico. Decisão reversível no `/reversa-plan`.

## 10. Lacunas

- n/a: nenhuma dúvida pendente.

## 11. Histórico de alterações

| Data | Alteração | Autor |
|------|-----------|-------|
| 2026-09-16 | Versão inicial gerada por `/reversa-requirements` (sinais digitados como texto) | reversa |
| 2026-09-16 | Reescrita pelo `/reversa-clarify`: escopo restrito aos acordes de zoom ⌘+ e ⌘- | reversa |
