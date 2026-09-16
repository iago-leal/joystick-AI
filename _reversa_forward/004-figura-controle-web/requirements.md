# Requirements: Figura do controle em página web embutida

> Identificador: `004-figura-controle-web`
> Data: `2026-09-15`
> Pasta da extração reversa: `_reversa_sdd/`
> Confidência: 🟢 CONFIRMADO, 🟡 INFERIDO, 🔴 LACUNA / DÚVIDA

## 1. Resumo executivo

A feature substitui a figura esquemática do controle na aba Atalhos do editor, hoje um conjunto de 18 fichas retangulares sobre um retângulo cinza, por uma representação fiel do DualSense, em estilo plano, desenhada numa página web local embutida na janela e escrita em HTML, CSS e JavaScript sem bibliotecas. O programador de sofá passa a reconhecer cada botão pela forma e pela posição do aparelho real, com os mesmos estados visuais (fixo, modificador, herdado, problema, selecionado) e o mesmo resumo de ação por camada que a figura atual oferece, agora em balões ao redor da silhueta. A página substitui somente a figura; o restante do editor permanece como está. Toda a lógica permanece no rascunho e no modelo do editor; a página apenas apresenta o estado que recebe e devolve o botão clicado. O arquivo de configuração, a validação, o modelo do rascunho e o esquema do log não mudam.

## 2. Contexto a partir do legado

| Fonte | Trecho relevante | Confidência |
|-------|------------------|-------------|
| `_reversa_sdd/architecture.md#1. Visão geral` | App sem dependências de terceiros, sem rede e sem banco; interface do editor em SwiftUI dentro de `NSWindow` com ativação forçada (ADR-013, ADR-014) | 🟢 |
| `_reversa_sdd/architecture.md#2. Estilo arquitetural` | Núcleo funcional com casca imperativa: decisões de domínio em `struct` de valor no núcleo; o app só executa efeitos e desenha | 🟢 |
| `_reversa_sdd/architecture.md#7. Dívidas técnicas` | TD-01: nenhum teste automatizado no alvo do app; a figura atual também não é testada | 🟢 |
| `_reversa_sdd/domain.md#2. Glossário` | Gatilho, modificador, camada, herança, botões de apontamento, modo de identificação e escala de TV | 🟢 |
| `_reversa_sdd/domain.md#3.1 Controle e entrada (001)` | 001 RN-12: sem rede; entradas só no log e nos resultados locais | 🟢 |
| `_reversa_sdd/domain.md#3.3 Atalhos, configuração e editor (003)` | 003 RN-14: log sem textos, rótulos nem acordes; 003 RN-16: no modo de identificação, botões não de apontamento só identificam | 🟢 |
| `_reversa_sdd/code-analysis.md#8.2 Modelo e janela` | Escala de TV: corpo 32 pt, título 40 pt, alvo mínimo 60 pt, janela mínima 1.400 × 800 pt; rolagem só vertical | 🟢 |
| `_reversa_sdd/code-analysis.md#8.3 Interface` | Figura de 830 × 620 pt com 18 fichas de 160 × 96 pt em posições fixas; herdados com opacidade 0,55; fixos e modificadores em cinza; problemas em vermelho; selecionado com contorno de destaque | 🟢 |
| `_reversa_sdd/editor/requirements.md#Regras de Negócio` | RN-ED-13 (escala de TV), RN-ED-14 (figura e resumo), RN-ED-31 (identificação pelo controle) | 🟢 |
| `_reversa_sdd/editor/requirements.md#Requisitos Funcionais` | RF-ED-02 (figura com ação resumida por camada) e RF-ED-09 (identificar pelo controle) | 🟢 |
| `_reversa_sdd/editor/design.md#Interface` | A aba Atalhos compõe seletor de camada, figura e painel de ação lado a lado; o painel ocupa a largura restante | 🟢 |
| `_reversa_sdd/editor/design.md#Fluxo Principal` | A seleção do botão pode vir do clique (`select`) ou do controle (`identified`), ambos no modelo, na thread principal | 🟢 |
| `_reversa_sdd/adrs/014-editor-swiftui-em-escala-de-tv.md` | O editor foi decidido em SwiftUI; a alternativa descartada foi AppKit puro; tamanhos de desktop foram reprovados no PM-1a | 🟢 |
| `_reversa_sdd/inventory.md#7. Build, assinatura e distribuição` | O script de build copia para o bundle apenas o binário e o `Info.plist`; nenhum recurso é empacotado hoje, e a assinatura estável é requisito para preservar as permissões | 🟢 |
| `_reversa_sdd/dependencies.md#3. Frameworks do sistema por alvo` | Nenhum framework de conteúdo web em uso; o núcleo importa só Foundation | 🟢 |
| `_reversa_sdd/addenda/003-editor-atalhos.md#Regras sob vigilância` | Os limites de W007 (24 pt e 44 pt) são pisos; o entregue é 32 pt e 60 pt, conforme o PM-1a | 🟢 |
| `_reversa_sdd/personas.md#Persona 1` | Programador de sofá, a cerca de 3 m da TV, que orquestra agentes e quer reduzir a dependência de teclado e mouse | 🟡 |

Observações derivadas do contexto:

- 🟢 O resumo de cada botão pode conter texto digitado pelo usuário (ação de texto, entre aspas e truncada em 24 caracteres). Qualquer apresentação em página web deve tratar esse conteúdo como texto, nunca como marcação.
- 🟡 Como o bundle não empacota recursos, a página, a folha de estilo e o script precisarão passar a ser embarcados e assinados junto com o app. Isso é restrição de entrega, não de comportamento.

## 3. Personas e cenários de uso

| Persona | Objetivo | Cenário-chave |
|---------|----------|---------------|
| Programador de sofá (a 3 m da TV, com o ponteiro do controle) | Reconhecer de relance, na forma do aparelho, o que cada botão faz na camada escolhida | Abre o editor pela paleta, escolhe a camada L2 e vê, sobre a silhueta do controle, que ← é "mesa à esquerda" |
| Programador de sofá em modo de identificação | Achar um botão sem procurá-lo na figura | Liga "Identificar pelo controle", pressiona △ e a figura destaca △ e abre o painel dele |
| O mesmo usuário à mesa, com teclado e mouse | Ajustar atalhos com precisão e conferir o resultado visualmente | Clica no ✕ desenhado na figura, troca o tipo para Texto e vê o resumo mudar no próprio botão |

## 4. Regras de negócio novas ou alteradas

1. **RN-01:** A figura apresenta os 18 botões sobre uma silhueta do DualSense, nas posições e com as formas do aparelho real: L1 e R1 acima de L2 e R2 nos ombros; direcional à esquerda; △, ○, ✕ e □ à direita; touchpad ao centro, ladeado por Create e Options; PS abaixo do touchpad; L3 e R3 nas hastes dos analógicos. O desenho é plano, com traços e preenchimentos chapados e cores semânticas do sistema, sem volume, sombras nem gradientes, para manter o contraste a 3 m nos dois temas. 🟢
   - Origem no legado: `_reversa_sdd/editor/requirements.md#RN-ED-14` (posições físicas aproximadas em fichas)
   - Tipo: alterada
2. **RN-02:** Os estados visuais da figura atual são preservados com o mesmo significado: botões fixos (R1, R2, clique do touchpad) e modificadores em tom neutro; ação herdada esmaecida; botão com problema em vermelho; botão selecionado com contorno de destaque. O texto do resumo por camada é exatamente o que o núcleo produz hoje (`ActionSummary`), inclusive o sufixo " (herdado)". O rótulo do botão fica dentro do botão desenhado; o resumo fica num balão ao redor da silhueta, ligado ao botão por uma linha-guia, e os 18 balões ficam visíveis ao mesmo tempo. Os estados visuais aplicam-se ao botão e ao balão dele em conjunto. 🟢
   - Origem no legado: `_reversa_sdd/editor/requirements.md#RN-ED-14`
   - Tipo: alterada (a aparência muda, o significado não)
3. **RN-03:** A figura é uma página local embutida na janela do editor, composta de HTML, CSS e JavaScript escritos no projeto, sem bibliotecas nem código de terceiros, empacotada no app. A página não carrega recurso de rede nem executa código que não esteja no bundle. 🟢
   - Origem no legado: `_reversa_sdd/domain.md#3.1` (001 RN-12, sem rede) e `_reversa_sdd/architecture.md#1` (sem dependências de terceiros)
   - Tipo: nova
4. **RN-04:** A página não decide nada. Ela recebe do editor a descrição do estado dos 18 botões na camada selecionada (rótulo, resumo, estado visual e seleção) e devolve ao editor somente o identificador do botão clicado. Rascunho, validação, herança e resumo permanecem no núcleo e no modelo do editor. 🟢
   - Origem no legado: `_reversa_sdd/architecture.md#2. Estilo arquitetural`
   - Tipo: nova
5. **RN-05:** A escala de TV vale para a figura: a área de clique de cada botão é o botão desenhado mais o balão dele, e tem ao menos 60 pt em cada dimensão, mesmo quando o desenho do botão é menor; rótulos com ao menos 26 pt e resumos com ao menos 24 pt, que são os valores da figura atual. 🟢
   - Origem no legado: `_reversa_sdd/editor/requirements.md#RN-ED-13`; `_reversa_sdd/addenda/003-editor-atalhos.md#Regras sob vigilância` (W007)
   - Tipo: alterada (estende à figura desenhada)
6. **RN-06:** Toda mudança de seleção feita fora da página se reflete nela sem clique: identificação pelo controle, correção da camada selecionada após gravar ou recarregar, e troca de camada pelo seletor. A identificação pelo controle continua a selecionar o botão e a abrir o painel dele. 🟢
   - Origem no legado: `_reversa_sdd/editor/requirements.md#RN-ED-31`; `_reversa_sdd/domain.md#3.3` (003 RN-16)
   - Tipo: alterada (a fonte da seleção passa a ser externa à figura)
7. **RN-07:** O conteúdo do resumo é sempre inserido como texto. Texto digitado pelo usuário numa ação de texto nunca é interpretado como marcação nem como código pela página. 🟢
   - Origem no legado: `_reversa_sdd/domain.md#3.3` (003 RN-13, ações de texto só digitam) e `_reversa_sdd/editor/requirements.md#RN-ED-10`
   - Tipo: nova
8. **RN-08:** A figura acompanha o tema claro e escuro do sistema, como o restante do editor já faz, e mantém contraste legível a 3 m em ambos. 🟡
   - Origem no legado: `_reversa_sdd/code-analysis.md#8.3 Interface` (cores semânticas do sistema na figura atual)
   - Tipo: nova (o comportamento hoje é implícito nas cores do sistema)
9. **RN-09:** A página não grava, não lê e não envia nada: sem armazenamento local, sem log próprio e sem evento novo com texto, rótulo, tecla ou acorde. 🟢
   - Origem no legado: `_reversa_sdd/domain.md#3.3` (003 RN-14)
   - Tipo: nova
10. **RN-10:** A página web substitui somente a figura do controle na aba Atalhos. A feature não altera o seletor de camada, o painel de ação, a aba Paleta, as faixas, o rodapé, o arquivo de configuração, as regras de validação, o modelo do rascunho nem o esquema do log (`logSchema` continua 1). 🟢
    - Origem no legado: `_reversa_sdd/editor/design.md#Interface`; `_reversa_sdd/architecture.md#5. Modelo de dados em arquivo`
    - Tipo: nova (delimitação de escopo)
11. **RN-11:** A figura ocupa a mesma área da figura atual, 830 × 620 pt, e não cresce com a janela, para que o painel de ação mantenha a largura que tem hoje. 🟢
    - Origem no legado: `_reversa_sdd/code-analysis.md#8.3 Interface`; `_reversa_sdd/editor/design.md#Interface`
    - Tipo: nova
12. **RN-12:** Se a página não puder ser carregada, a aba Atalhos mostra, no lugar da figura, a mensagem "A figura do controle não pôde ser carregada; reinstale o app." e continua operável: o seletor de camada e o painel de ação funcionam, e a seleção de botão é feita pelo modo de identificação. Não há figura reserva. 🟢
    - Origem no legado: `_reversa_sdd/editor/requirements.md#RN-ED-31`; `_reversa_sdd/inventory.md#7. Build, assinatura e distribuição`
    - Tipo: nova

## 5. Requisitos Funcionais

| ID | Requisito | Prioridade | Critério de aceite | Confidência |
|----|-----------|------------|--------------------|-------------|
| RF-01 | A figura desenha a silhueta do DualSense com os 18 botões nas posições e formas de RN-01 | Must | Uma pessoa que conhece o controle identifica os 18 botões sem ler os rótulos; nenhum botão do catálogo falta nem sobra | 🟢 |
| RF-02 | Cada botão exibe o rótulo (✕, ○, □, △, L1, R1, L2, R2, L3, R3, Options, Create, PS, Touchpad, ↑, ↓, ←, →) e o resumo da ação na camada selecionada | Must | Na camada base padrão, ✕ mostra "Return" e PS mostra "abrir paleta"; na camada L2, ← mostra "mesa à esquerda" | 🟢 |
| RF-03 | Os cinco estados visuais de RN-02 são distinguíveis a 3 m: fixo, modificador, herdado, problema e selecionado | Must | Com L1 modificador, ○ sem ação própria em L1 e ✕ com texto vazio, a figura mostra L1 neutro, ○ esmaecido com "(herdado)", ✕ em vermelho e o selecionado com contorno | 🟢 |
| RF-04 | Clicar num botão da figura o seleciona e abre o painel de ação dele, como hoje | Must | Clique em △ muda o título do painel para "△ na camada Base" | 🟢 |
| RF-05 | A figura reflete mudanças de seleção e de camada vindas de fora dela (RN-06) | Must | Com identificação ligada, pressionar △ no controle destaca △ na figura sem clique; trocar a camada pelo seletor atualiza os 18 resumos | 🟢 |
| RF-06 | A figura reflete edições do rascunho imediatamente | Must | Trocar o tipo de ✕ para Texto atualiza o resumo de ✕ para o texto entre aspas sem trocar de aba nem de camada | 🟢 |
| RF-07 | A área de clique de cada botão tem ao menos 60 × 60 pt (RN-05), inclusive nos botões pequenos do aparelho | Must | Clicar até 30 pt do centro de ✕ com o ponteiro do controle seleciona ✕ | 🟢 |
| RF-08 | A página é local, embarcada no app, sem bibliotecas e sem acesso à rede (RN-03) | Must | Com a rede desligada, a figura aparece igual; a inspeção do bundle mostra somente arquivos do projeto | 🟢 |
| RF-09 | O resumo é inserido como texto (RN-07) | Must | Uma ação de texto com o conteúdo `<b>x</b>` aparece literalmente, entre aspas, sem negrito | 🟢 |
| RF-10 | A figura ocupa a área de 830 × 620 pt da figura atual (RN-11) e mantém a janela mínima de 1.400 × 800 pt e a altura de tela de 900 pt | Must | A janela mínima continua a exibir seletor de camada, figura, painel e rodapé sem rolagem horizontal, e o painel de ação tem a mesma largura de hoje | 🟢 |
| RF-11 | A figura acompanha o tema claro e escuro do sistema (RN-08) | Should | Trocar o tema com o editor aberto atualiza fundo, traços e textos da figura sem reabrir | 🟡 |
| RF-12 | Os símbolos dos botões de ação usam as cores do aparelho (△ verde, ○ vermelho, ✕ azul, □ rosa), mantendo os estados de RN-02 legíveis | Should | Os quatro símbolos têm cores distintas e o contorno de seleção continua visível sobre eles | 🟡 |
| RF-13 | Se a página não carregar, a aba Atalhos mostra a mensagem de RN-12 no lugar da figura e continua utilizável | Should | Com o recurso ausente do bundle, a mensagem aparece, o painel de ação funciona e o modo de identificação seleciona botões | 🟢 |
| RF-14 | O botão sob o ponteiro recebe um realce leve, para orientar o clique a 3 m | Could | Mover o ponteiro sobre ○ realça ○ antes do clique | 🟡 |
| RF-15 | A troca de seleção e de camada é animada de forma breve e discreta | Could | A transição não passa de 150 ms e pode ser desligada com "Reduzir movimento" do sistema | 🟡 |

## 6. Requisitos Não Funcionais

| Tipo | Requisito | Evidência ou justificativa | Confidência |
|------|-----------|----------------------------|-------------|
| Desempenho | A figura aparece em até 500 ms após a janela do editor ficar visível; cada atualização de estado (camada, seleção, edição) reflete-se em até 100 ms | Editor aberto do sofá pelo controle; hoje a figura é imediata (`_reversa_sdd/code-analysis.md#8.3`) | 🟡 |
| Desempenho | Sem consumo perceptível de CPU com o editor aberto em repouso; nenhum laço de animação contínuo | `_reversa_sdd/architecture.md#6` (temporizador só sob demanda) | 🟡 |
| Segurança | Nenhuma carga de rede, nenhum script de terceiros; a única mensagem que a página pode enviar ao editor é o identificador de um botão do catálogo; identificadores desconhecidos são ignorados | `_reversa_sdd/domain.md#3.1` (001 RN-12); RN-04 | 🟢 |
| Segurança | Conteúdo do usuário só como texto (RN-07) | `_reversa_sdd/editor/requirements.md#RN-ED-10` (texto de até 1.000 caracteres, qualquer conteúdo numa linha) | 🟢 |
| Privacidade | Nenhum evento novo no log com texto, rótulo, tecla ou acorde; nenhum armazenamento pela página | `_reversa_sdd/domain.md#3.3` (003 RN-14) | 🟢 |
| Usabilidade | Legível e clicável a 3 m pelo ponteiro: alvos ≥ 60 pt, textos ≥ 24 pt, contraste de texto ≥ 4,5:1 nos dois temas | `_reversa_sdd/editor/requirements.md#RN-ED-13`; PM-1a da 003 | 🟢 |
| Compatibilidade | macOS 13 ou superior, o mínimo do app; janela mínima de 1.400 × 800 pt; tela de 900 pt de altura | `_reversa_sdd/inventory.md#1`; `_reversa_sdd/code-analysis.md#8.2` | 🟢 |
| Entrega | Página, estilo e script embarcados no bundle e cobertos pela assinatura estável, sem invalidar as permissões de Acessibilidade | `_reversa_sdd/inventory.md#7` (assinatura estável é requisito) | 🟢 |
| Manutenibilidade | O núcleo continua importando só Foundation; o contrato de estado entre editor e página é documentado em `interfaces/` da feature | `_reversa_sdd/architecture.md#3`; `_reversa_sdd/dependencies.md#3` | 🟢 |
| Testabilidade | O contrato de estado é um tipo de valor codificável, testável sem interface; a página em si é validada no portão manual | `_reversa_sdd/architecture.md#7` (TD-01, sem testes no alvo do app) | 🟡 |
| Observabilidade | Os eventos `editor.*` existentes continuam iguais; qualquer evento novo, se houver, cita apenas motivo, sem conteúdo | `_reversa_sdd/editor/design.md#Observabilidade` | 🟢 |

## 7. Critérios de Aceitação

```gherkin
Cenário: Figura fiel com a configuração padrão
  Dado o editor aberto na aba Atalhos com a configuração padrão
  Quando a camada Base está selecionada
  Então a silhueta do DualSense mostra os 18 botões nas posições do aparelho
  E ✕ mostra "Return", PS mostra "abrir paleta" e R1 mostra "clique esquerdo, fixo"

Cenário: Resumo por camada
  Dado o editor aberto com a configuração padrão
  Quando o usuário escolhe a camada L2 no seletor
  Então ← passa a mostrar "mesa à esquerda"
  E os botões sem ação própria em L2 aparecem esmaecidos com o sufixo "(herdado)"

Cenário: Clique seleciona o botão
  Dado a camada Base selecionada e ✕ selecionado
  Quando o usuário clica em △ na figura com o ponteiro do controle
  Então △ recebe o contorno de destaque, ✕ perde o contorno
  E o painel passa a exibir "△ na camada Base"

Cenário: Identificação pelo controle reflete na figura
  Dado "Identificar pelo controle" ligado
  Quando o usuário pressiona □ no controle
  Então □ fica selecionado na figura sem nenhum clique
  E nenhuma ação de atalho é executada

Cenário: Edição reflete no resumo
  Dado ✕ selecionado na camada Base
  Quando o usuário troca o tipo de ação para Texto e digita CONTINUAR
  Então o resumo de ✕ na figura passa a "“CONTINUAR”" em até 100 ms

Cenário: Problema em vermelho
  Dado ✕ com ação de texto vazia
  Quando a figura é exibida
  Então ✕ aparece em vermelho
  E o rodapé conta "1 problema impede salvar"

Cenário: Alvo mínimo nos botões pequenos
  Dado a figura exibida na janela mínima de 1.400 × 800 pt
  Quando o usuário clica a 28 pt do centro de ○
  Então ○ é selecionado

Cenário: Texto do usuário não vira marcação
  Dado uma ação de texto com o conteúdo <img src=x onerror=alert(1)>
  Quando a figura exibe o resumo desse botão
  Então o conteúdo aparece literalmente, entre aspas e truncado em 24 caracteres
  E nada é executado

Cenário: Sem rede
  Dado o Mac sem conexão de rede
  Quando o editor é aberto
  Então a figura aparece completa em até 500 ms

Cenário: Mensagem desconhecida da página é ignorada
  Dado a página embutida enviando um identificador que não é botão do catálogo
  Quando o editor recebe a mensagem
  Então a seleção não muda e nenhum erro é exibido

Cenário: Camada some após recarregar
  Dado a camada △ selecionada e o rascunho limpo
  Quando o arquivo é alterado por fora e △ deixa de ser modificador
  Então a figura passa a mostrar a camada Base
  E o seletor de camada não oferece mais △

Cenário: Página indisponível
  Dado o recurso da página ausente ou corrompido no bundle
  Quando o editor é aberto na aba Atalhos
  Então a mensagem "A figura do controle não pôde ser carregada; reinstale o app." aparece no lugar da figura
  E o painel de ação continua funcionando
  E, com "Identificar pelo controle" ligado, pressionar △ seleciona △

Cenário: Balões visíveis ao mesmo tempo
  Dado a figura exibida na camada Base
  Quando o usuário observa a silhueta
  Então os 18 balões de resumo estão visíveis, cada um ligado ao seu botão por uma linha-guia
  E nenhum balão cobre outro botão nem outro balão

Cenário: Área da figura constante
  Dado o editor na janela mínima de 1.400 × 800 pt
  Quando o usuário amplia a janela para 1.900 × 1.000 pt
  Então a figura mantém 830 × 620 pt
  E o painel de ação recebe a largura adicional

Cenário: Tema do sistema
  Dado o editor aberto no tema claro
  Quando o usuário troca o sistema para o tema escuro
  Então fundo, traços e textos da figura mudam sem reabrir a janela
  E o contraste dos textos continua em ao menos 4,5:1

Cenário: Cores dos botões de ação
  Dado a figura exibida com ✕ selecionado
  Quando o usuário observa △, ○, ✕ e □
  Então cada símbolo tem a cor do aparelho (verde, vermelho, azul e rosa)
  E o contorno de seleção de ✕ continua visível sobre o azul

Cenário: Sem modificadores
  Dado um rascunho em que nenhum botão é modificador
  Quando a aba Atalhos é exibida
  Então o seletor oferece somente a camada Base
  E nenhum botão aparece esmaecido nem com o sufixo "(herdado)"

Cenário: Estado enviado antes da carga
  Dado o editor aberto pela paleta com a página ainda carregando
  Quando a página termina de carregar
  Então ela exibe o estado vigente do rascunho e a seleção atual, sem clique nem troca de camada

Cenário: Realce sob o ponteiro
  Dado a figura exibida
  Quando o ponteiro do controle passa sobre ○ sem clicar
  Então ○ recebe um realce leve
  E a seleção não muda

Cenário: Transição de seleção discreta
  Dado "Reduzir movimento" desligado nos Ajustes do Sistema
  Quando o usuário clica em △
  Então o contorno passa de ✕ para △ em até 150 ms
  E, com "Reduzir movimento" ligado, a troca é imediata, sem animação
```

## 8. Prioridade MoSCoW

| Item | MoSCoW | Justificativa |
|------|--------|---------------|
| RF-01, RF-02, RF-03 | Must | São o objetivo da feature: figura fiel com o mesmo conteúdo da atual |
| RF-04, RF-05, RF-06 | Must | Sem eles a figura deixa de ser o instrumento de seleção do editor (RF-ED-02, RF-ED-09) |
| RF-07 | Must | Sem alvo de 60 pt a figura não é clicável do sofá; reprovado no PM-1a com valores menores |
| RF-08, RF-09 | Must | Restrições de segurança e de privacidade herdadas (001 RN-12, 003 RN-13) |
| RF-10 | Must | A janela mínima e a tela de 900 pt são limites verificados no PM-1a |
| RF-11 | Should | O restante do editor já acompanha o tema; a figura destoar seria regressão visual |
| RF-12 | Should | Reforça o reconhecimento dos botões de ação, que é o ganho principal |
| RF-13 | Should | Evita que uma falha de recurso deixe o editor inutilizável, com uma mensagem e sem figura reserva |
| RF-14, RF-15 | Could | Refinamentos de conforto, sem impacto funcional |
| RNF de desempenho | Should | A figura atual é imediata; um atraso visível seria percebido como regressão |
| RNF de entrega (bundle assinado) | Must | Sem recurso no bundle a figura não existe; sem assinatura estável as permissões se perdem |

## 9. Esclarecimentos

### Sessão 2026-09-15

- **Q:** Qual o escopo da página web embutida: só a figura do controle, a aba Atalhos inteira ou o editor inteiro?
  **R:** Só a figura do controle na aba Atalhos. O seletor de camada, o painel de ação, a aba Paleta, as faixas e o rodapé continuam em SwiftUI, porque já passaram pelos portões PM-1a e PM-2 e dependem de comportamentos delicados do AppKit (captura de acorde, colar e ditar, folha de fechamento, ativação por clique sintético). Registrado em RN-10.
- **Q:** Onde fica o resumo da ação de cada botão: em balões ao redor da silhueta, num cartão sobre o botão ou só para o botão selecionado?
  **R:** Balões ao redor da silhueta, ligados a cada botão por linha-guia, com o rótulo dentro do botão. Preserva a fidelidade do desenho e a leitura de relance dos 18 resumos a 3 m; a área clicável passa a ser o botão mais o balão. Registrado em RN-02 e RN-05.
- **Q:** O que acontece se a página não carregar: mensagem pedindo reinstalar, figura reserva de fichas ou fechar o editor com erro?
  **R:** Mensagem na aba pedindo reinstalar o app, com o painel de ação operável e a seleção pelo modo de identificação. Sem figura reserva, para não manter dois desenhos da mesma coisa; o recurso vem do bundle assinado e a falha é improvável. Registrado em RN-12 e RF-13.
- **Q:** Qual o estilo do desenho: plano, realista com volume e sombras, ou só contorno?
  **R:** Plano, com traços e preenchimentos chapados e cores semânticas do sistema, pelo contraste a 3 m e nos dois temas. Registrado em RN-01.
- **Q:** A figura pode crescer além dos 830 × 620 pt atuais?
  **R:** Não. Mantém a área atual para o painel de ação não perder largura. Registrado em RN-11 e RF-10.

## 10. Lacunas

Nenhuma lacuna pendente. As três dúvidas da versão inicial foram resolvidas na sessão de 2026-09-15, junto com duas perguntas adicionais sobre estilo e tamanho da figura.

## 11. Histórico de alterações

| Data | Alteração | Autor |
|------|-----------|-------|
| 2026-09-15 | Versão inicial gerada por `/reversa-requirements` | reversa |
| 2026-09-15 | Sessão de esclarecimentos por `/reversa-clarify`: 5 respostas, RN-11 e RN-12 acrescentadas, RN-01, RN-02, RN-05, RN-10, RF-10 e RF-13 reescritas, 3 cenários novos | reversa |
