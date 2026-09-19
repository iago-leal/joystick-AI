# Requirements: Sugestão de palavras no teclado remoto

> Identificador: `009-sugestao-de-palavras`
> Data: `2026-09-19`
> Pasta da extração reversa: `_reversa_sdd/`
> Confidência: 🟢 CONFIRMADO, 🟡 INFERIDO, 🔴 LACUNA / DÚVIDA

## 1. Resumo executivo

A feature acrescenta ao teclado remoto do iPhone (feature 008) uma faixa acima das teclas com sugestões de palavras que completam o que o usuário está escrevendo e, depois de um espaço, preveem a palavra seguinte. Tocar numa sugestão escreve a palavra no aplicativo em foco no Mac, seguida de espaço, poupando toques num teclado sem retorno tátil, preso ao controle. Hoje cada letra exige um toque, e palavras longas em português, com acentos por tecla morta, custam muitos toques e erros. A correção automática e a previsão por serviço externo ficam fora desta feature (seção 8).

## 2. Contexto a partir do legado

| Fonte | Trecho relevante | Confidência |
|-------|------------------|-------------|
| Pedido do usuário, 2026-09-19 | "Gostaria de acrescentar ao teclado que criamos para rodar no iPhone uma telinha que fique acima dele, com a sugestão de palavras de acordo com o que vai sendo escrito." | 🟢 |
| `_reversa_forward/008-iphone-teclado-remoto/requirements.md#4. Regras de negócio novas ou alteradas` | RN-06: cada tecla da página é uma posição física, e o caractere é decidido pela fonte de entrada ativa no Mac. RN-12: os rótulos acompanham a fonte ativa. RN-13: teclas, rótulos e código nunca vão ao log | 🟢 |
| `_reversa_forward/008-iphone-teclado-remoto/requirements.md#5. Requisitos Funcionais` | RF-04: o teclado completo cabe numa só tela na horizontal, sem rolar. RF-10: a página mostra o estado da ligação numa faixa | 🟢 |
| `_reversa_forward/008-iphone-teclado-remoto/interfaces/remote-keyboard-protocol.md#3. Canal (porta 47811)` | A página envia só códigos de tecla (`down`, `up`); o Mac envia `layout`, `modifiers`, `status` e `caps`. Hoje nenhum texto circula pelo canal | 🟢 |
| `_reversa_forward/008-iphone-teclado-remoto/onboarding.md#Resultado do PM-1` | Passos 1 a 12 aprovados em 2026-09-19, inclusive acentos por tecla morta (passo 8) e troca de fonte de entrada (passo 7); passos 13 a 17 e a sincronização da 008 estão pendentes | 🟢 |
| `_reversa_sdd/injecao-de-eventos/requirements.md#Regras de Negócio` | RN-IN-12: o app já injeta texto por unidade de caractere, sem depender da fonte de entrada. RN-IN-16: teclas, acordes e textos nunca vão ao log | 🟢 |
| `_reversa_sdd/domain.md#3.1 Controle e entrada (001)` | 001 RN-12: sem rede; nada do que é digitado vai ao log. A 008 abriu a exceção do canal local do teclado remoto | 🟢 |
| `_reversa_sdd/permissions.md#4. Restrições de acesso internas` | Textos, rótulos e acordes nunca vão ao log; ações de texto só digitam | 🟢 |
| `_reversa_sdd/architecture.md#2. Estilo arquitetural` | Núcleo funcional testável (`JoystickCore`) com casca imperativa fina | 🟢 |
| `_reversa_sdd/architecture.md#4. Integrações externas` | Nenhuma API nem serviço externo; todas as integrações são com o sistema operacional | 🟢 |
| `_reversa_sdd/personas.md#Persona 1: Programador de sofá` | Usuário único, que escreve prompts e comandos longe da mesa | 🟡 |
| Sonda de 2026-09-19 no Mac do usuário (sessão do `/reversa-clarify`) | Ver "Viabilidade", abaixo | 🟢 |

**Viabilidade.** O Mac já conhece o caractere que cada tecla produz na fonte de entrada ativa, porque monta a tabela de rótulos da página (008 RN-12), e já sabe injetar texto arbitrário (RN-IN-12). A sonda de 2026-09-19 confirmou que o macOS oferece, localmente e sem rede, um motor de previsão de texto com as seguintes propriedades 🟢:

- responde em 2 a 17 ms, exceto a primeira consulta, que levou cerca de 90 ms;
- completa palavras em português do Brasil com acento ("funç" → "Função"; "o reposit" → "repositório") e em inglês ("Please refac" → "refactor");
- prevê a próxima palavra ("Olá, tudo " → "bem"; "Eu quero " → "que", "ver", "saber");
- depende do contexto anterior: "impl" sozinho é tratado como início de frase, com maiúscula e sugestões fracas ("Implorando"), enquanto "vamos impl" sugere "implementar";
- erra o idioma em trechos curtos quando deixado em detecção automática ("vamos impl" → "implementation");
- entrega cada sugestão com um espaço no fim e devolve a própria palavra digitada como primeira opção;
- gera ruído em comandos e caminhos ("cd ~/dev/joy" → "joystick "; "ls -la" → "lado").

O completamento simples de palavras do sistema, por outro lado, não devolveu nada em português do Brasil. 🟢

**Dependência.** A feature estende a 008, cuja entrega está em código, mas ainda sem sincronização em `_reversa_sdd/addenda/` e com os passos 13 a 17 do PM-1 pendentes. O plano deve partir do estado atual do código da 008. 🟢

**Constatação.** Pela primeira vez, conteúdo digitado circula do Mac para a página, e o Mac guarda em memória um trecho do que foi escrito: as sugestões derivam desse trecho. Isso amplia a superfície de privacidade da 008, que até aqui só transportava códigos de tecla, e motiva RN-06 a RN-08. 🟢

## 3. Personas e cenários de uso

| Persona | Objetivo | Cenário-chave |
|---------|----------|---------------|
| Programador de sofá (`_reversa_sdd/personas.md#Persona 1: Programador de sofá`) | Escrever um prompt em português com menos toques | No terminal com o Claude Code, digita "vamos impl", vê "implementar" na faixa e toca nela; a palavra aparece completa, seguida de espaço |
| Programador de sofá | Evitar os acentos por tecla morta em palavras longas | Digita "funç" e escolhe "função" em vez de tocar mais três teclas |
| Programador de sofá | Escrever a mensagem de um commit em inglês | Toca EN no seletor da faixa, digita "refac" e escolhe "refactor" |
| Programador de sofá | Digitar comandos e caminhos sem ruído | Digita `cd ~/dev/joy`; a faixa fica vazia enquanto a palavra contém `/` ou `~` |
| Programador de sofá | Digitar senha sem exposição | Num campo de senha, a faixa fica vazia e o Mac não guarda o que é digitado |

A frequência esperada acompanha a do teclado remoto: contínua durante as sessões, com mais uso na escrita de prompts do que na de comandos. 🟡

## 4. Regras de negócio novas ou alteradas

**Termos.**

- *Palavra em composição*: a sequência de caracteres produzida pelas teclas do iPhone desde o último espaço, Return ou Tab, descontadas as teclas de apagar, e sem os sinais de abertura iniciais `(`, `[`, `"` e `'`.
- *Contexto recente*: o texto produzido pelas teclas do iPhone desde o último descarte (RN-03), limitado aos últimos 200 caracteres, que inclui a palavra em composição.

1. **RN-01:** Com a página conectada, uma faixa de sugestões fica acima das teclas e mostra até três palavras, da mais provável para a menos provável. Com palavra em composição, as sugestões a completam; logo após um espaço, preveem a palavra seguinte (RN-12). A faixa não repete como sugestão a própria palavra digitada. Sem sugestão, a faixa fica vazia, mas continua ocupando o mesmo espaço. 🟢
   - Tipo: nova
2. **RN-02:** As sugestões partem do contexto recente, montado apenas com as teclas do iPhone e mantido só em memória no Mac. O app não lê o texto dos aplicativos do Mac. 🟢
   - Tipo: nova
3. **RN-03:** O contexto recente é descartado por inteiro, e a faixa esvazia, quando o ponto de escrita pode ter mudado sem o app saber: tecla de seta, Esc, tecla com ⌘ ou ⌃, qualquer entrada do controle (movimento com clique, tecla, acorde ou texto), troca do aplicativo em foco, troca da fonte de entrada, fim da sessão ou teclado remoto desligado. Espaço, Return e Tab encerram a palavra em composição, mas mantêm o contexto recente. 🟡
   - Tipo: nova
4. **RN-04:** Tocar numa sugestão substitui, no aplicativo em foco, a palavra em composição pela palavra sugerida seguida de um espaço, em qualquer aplicativo; em seguida, uma nova palavra começa. A caixa da primeira letra segue a digitada: se a palavra em composição começa com minúscula, a sugestão é escrita com minúscula, e se começa com maiúscula, com maiúscula. Na previsão da palavra seguinte, sem letra digitada, vale a caixa sugerida. 🟢
   - Tipo: nova
5. **RN-05:** As sugestões vêm em português do Brasil ou em inglês, conforme um seletor PT / EN na faixa. O padrão é português. A escolha vale até ser trocada, inclusive entre sessões, e não é considerada conteúdo digitado. 🟢
   - Tipo: nova
6. **RN-06:** Em entrada segura (campo de senha ou modo de entrada segura de um aplicativo), o app não monta contexto recente, descarta o que já tinha e deixa a faixa vazia. 🟢
   - Origem no legado: `_reversa_forward/008-iphone-teclado-remoto/requirements.md#4. Regras de negócio novas ou alteradas` (RN-13: o que é digitado, inclusive senhas, não fica registrado)
   - Tipo: nova
7. **RN-07:** As sugestões são calculadas no Mac, sem serviço externo nem rede além do canal da 008. O app não aprende palavras, não guarda histórico e não grava o contexto recente nem as sugestões em disco. O contexto recente só existe em memória e é apagado a cada descarte. 🟢
   - Origem no legado: `_reversa_sdd/domain.md#3.1 Controle e entrada (001)` (001 RN-12)
   - Tipo: alterada (o canal da 008 passa a transportar sugestões, e só elas)
8. **RN-08:** O contexto recente, as sugestões e a sugestão escolhida nunca vão ao log. O log registra apenas, no fim da sessão, quantas sugestões foram aceitas. 🟢
   - Origem no legado: `_reversa_forward/008-iphone-teclado-remoto/requirements.md#4. Regras de negócio novas ou alteradas` (RN-13); `_reversa_sdd/injecao-de-eventos/requirements.md#Regras de Negócio` (RN-IN-16)
   - Tipo: alterada (nova contagem no evento de fim de sessão)
9. **RN-09:** As sugestões nunca atrasam as teclas: cada tecla é injetada antes de qualquer cálculo de sugestão, e uma lista de sugestões que chega depois de o contexto recente mudar é descartada pela página. 🟢
   - Origem no legado: `_reversa_forward/008-iphone-teclado-remoto/requirements.md#6. Requisitos Não Funcionais` (latência de 150 ms por tecla)
   - Tipo: nova
10. **RN-10:** O toque numa sugestão passa pelo portão de injeção como as teclas: sem a permissão de Acessibilidade, nada é escrito e a palavra em composição é mantida. 🟢
    - Origem no legado: `_reversa_forward/008-iphone-teclado-remoto/requirements.md#4. Regras de negócio novas ou alteradas` (RN-11); `_reversa_sdd/injecao-de-eventos/requirements.md#Regras de Negócio` (RN-IN-02)
    - Tipo: alterada (nova origem de texto no portão)
11. **RN-11:** Um toque na faixa só escolhe a sugestão sob o dedo; tocar fora das sugestões, ou numa faixa vazia, não produz efeito no Mac. Tocar numa sugestão não solta modificadores presos e não conta como tecla da sessão. 🟡
    - Tipo: nova
12. **RN-12:** A previsão da palavra seguinte só aparece logo após um espaço que encerrou uma palavra só de letras; depois de Return ou Tab, ou quando não há contexto recente, a faixa fica vazia até a primeira letra. 🟡
    - Tipo: nova
13. **RN-13:** Palavras com cara de código não recebem sugestão: se a palavra em composição contém algum caractere que não seja letra, inclusive letra acentuada (por exemplo `/`, `~`, `.`, `-`, `_`, `=` ou dígito), a faixa fica vazia até o próximo espaço, Return ou Tab. 🟢
    - Tipo: nova
14. **RN-14:** O usuário pode ocultar a faixa por um botão na página e mostrá-la de novo pelo mesmo botão. Com a faixa oculta, nenhuma sugestão é pedida ao Mac nem exibida. A escolha vale até ser trocada, inclusive entre sessões. 🟢
    - Tipo: nova

## 5. Requisitos Funcionais

| ID | Requisito | Prioridade | Critério de aceite | Confidência |
|----|-----------|------------|--------------------|-------------|
| RF-01 | A página desenha a faixa de RN-01 acima das teclas, sem tirar nenhuma tecla da tela | Must | No iPhone na horizontal, a faixa e todas as teclas de 008 RF-04 estão visíveis sem rolar | 🟡 |
| RF-02 | A faixa se atualiza a cada tecla que altera a palavra em composição, inclusive apagar | Must | Com "vamos " digitado, digitar "impl" mostra palavras iniciadas por "impl"; apagar o "l" mostra palavras iniciadas por "imp" | 🟢 |
| RF-03 | Tocar numa sugestão escreve a palavra conforme RN-04 | Must | Com "funç" digitado, tocar em "função" deixa "função " no aplicativo em foco, sem letra duplicada | 🟢 |
| RF-04 | O contexto recente é descartado nas situações de RN-03 | Must | Após digitar "exe" e tocar ←, a faixa esvazia; a letra seguinte começa palavra nova, sem contexto anterior | 🟡 |
| RF-05 | A faixa fica vazia em entrada segura, conforme RN-06 | Must | Num campo de senha, digitar "abc" não mostra sugestão alguma | 🟢 |
| RF-06 | As sugestões usam os caracteres da fonte de entrada ativa, inclusive os compostos por tecla morta | Must | Com a fonte ABNT2 ou EUA Internacional e português selecionado, digitar "funç" sugere "função" | 🟢 |
| RF-07 | A faixa tem o seletor PT / EN de RN-05 | Must | Com EN selecionado, digitar "refac" sugere "refactor"; com PT, digitar "funç" sugere "função"; reabrir a página mantém a última escolha | 🟢 |
| RF-08 | Palavras com cara de código ficam sem sugestão, conforme RN-13 | Must | Digitar `cd ~/dev/joy` não mostra sugestão depois do `~`; digitar `-la` não mostra sugestão | 🟢 |
| RF-09 | O evento de fim de sessão registra a contagem de sugestões aceitas, sem conteúdo (RN-08) | Must | Uma sessão com 3 sugestões aceitas gera o evento de fim de sessão com a contagem 3 e nenhuma palavra | 🟢 |
| RF-10 | A caixa da primeira letra segue RN-04 | Should | Digitar "Impl" e escolher a sugestão escreve "Implementar "; digitar "vamos impl" e escolher escreve "implementar " | 🟢 |
| RF-11 | Depois de um espaço, a faixa prevê a palavra seguinte, conforme RN-12 | Should | Com "Olá, tudo " digitado, a faixa mostra sugestões como "bem" antes de qualquer letra | 🟢 |
| RF-12 | Um botão oculta e mostra a faixa, conforme RN-14 | Should | Com a faixa oculta, digitar não mostra sugestões; tocar o botão de novo traz a faixa de volta | 🟢 |
| RF-13 | A faixa marca visualmente a sugestão tocada, como as teclas | Should | Ao tocar numa sugestão, ela muda de aparência até o dedo sair | 🟡 |

## 6. Requisitos Não Funcionais

| Tipo | Requisito | Evidência ou justificativa | Confidência |
|------|-----------|----------------------------|-------------|
| Desempenho | As sugestões aparecem em até 150 ms após o toque que mudou o contexto recente, no percentil 95, na rede doméstica | Acima disso, o usuário já tocou a letra seguinte; a sonda mediu 2 a 17 ms de cálculo no Mac, e a primeira consulta, cerca de 90 ms | 🟢 |
| Desempenho | A latência das teclas da 008 (150 ms no percentil 95) não piora com a faixa ativa | RN-09; `_reversa_forward/008-iphone-teclado-remoto/requirements.md#6. Requisitos Não Funcionais` | 🟢 |
| Privacidade | Contexto recente e sugestões não vão ao log nem a disco e não são aprendidos pelo app; o contexto recente não passa de 200 caracteres | RN-02, RN-07, RN-08; `_reversa_sdd/permissions.md#4. Restrições de acesso internas` | 🟢 |
| Privacidade | Nenhum contexto é montado nem sugestão é pedida em entrada segura | RN-06 | 🟢 |
| Privacidade | As preferências da faixa (idioma e visibilidade) são as únicas escolhas persistidas pela feature e não contêm conteúdo digitado | RN-05, RN-14 | 🟢 |
| Segurança | As sugestões trafegam só pelo canal cifrado e pareado da 008; a página as exibe como texto, nunca como marcação | `_reversa_forward/008-iphone-teclado-remoto/interfaces/remote-keyboard-protocol.md#3. Canal (porta 47811)`; a 008 proíbe montar HTML a partir de texto na página | 🟢 |
| Disponibilidade | A falta de sugestões (erro ou demora do motor) deixa a faixa vazia sem afetar as teclas | RN-09 | 🟡 |
| Permissões | Nenhuma permissão nova de TCC além da Acessibilidade | `_reversa_sdd/permissions.md#2. Matriz de permissões do sistema operacional` | 🟡 |
| Arquitetura | A montagem e o descarte do contexto recente, a detecção de palavra com cara de código, a substituição pela sugestão e a regra de caixa ficam no núcleo testável, sem depender de rede nem do sistema | `_reversa_sdd/architecture.md#2. Estilo arquitetural` | 🟢 |
| Usabilidade | As sugestões são legíveis e tocáveis com o iPhone preso ao controle, com área de toque não menor que a de uma tecla de letra | `_reversa_forward/008-iphone-teclado-remoto/requirements.md#5. Requisitos Funcionais` (RF-04) | 🟡 |

## 7. Critérios de Aceitação

```gherkin
Cenário: Sugestões enquanto digita
  Dado um iPhone pareado, português selecionado e um campo de texto em foco no Mac
  Quando o usuário digita "vamos impl"
  Então a faixa mostra até três palavras iniciadas por "impl", como "implementar"
  E nenhuma delas é o próprio "impl"

Cenário: Apagar atualiza as sugestões
  Dado um iPhone pareado com "vamos impl" digitado
  Quando o usuário toca a tecla de apagar uma vez
  Então a faixa mostra palavras iniciadas por "imp"

Cenário: Completar com acento e espaço
  Dado um iPhone pareado, a fonte ABNT2 ativa, português selecionado e "funç" digitado
  Quando o usuário toca na sugestão "função"
  Então o aplicativo em foco contém "função " no lugar de "funç"

Cenário: Caixa da primeira letra
  Dado um iPhone pareado com "Impl" digitado
  Quando o usuário toca numa sugestão iniciada por "impl"
  Então a palavra escrita começa com "I" maiúsculo

Cenário: Minúscula mantida
  Dado um iPhone pareado com "vamos impl" digitado
  Quando o usuário toca em "implementar"
  Então o aplicativo em foco recebe "implementar " com minúscula

Cenário: Previsão da palavra seguinte
  Dado um iPhone pareado com "Olá, tudo " digitado
  Quando nenhuma letra foi digitada depois do espaço
  Então a faixa mostra previsões da palavra seguinte, como "bem"

Cenário: Troca de idioma
  Dado um iPhone pareado com português selecionado
  Quando o usuário toca EN no seletor e digita "refac"
  Então a faixa mostra "refactor"
  E ao reabrir a página o seletor continua em EN

Cenário: Caminho no terminal
  Dado um iPhone pareado e o terminal em foco
  Quando o usuário digita "cd ~/dev/joy"
  Então a faixa fica vazia a partir do "~"
  E nenhum espaço é acrescentado ao caminho

Cenário: Opção de comando
  Dado um iPhone pareado e o terminal em foco
  Quando o usuário digita "ls -la"
  Então a faixa fica vazia enquanto a palavra em composição é "-la"

Cenário: Ponto de escrita movido
  Dado um iPhone pareado com "exe" digitado
  Quando o usuário toca ← ou clica com o controle noutro lugar do texto
  Então a faixa esvazia
  E a próxima letra começa uma palavra nova, sem o contexto anterior

Cenário: Troca de aplicativo
  Dado um iPhone pareado com "rev" digitado no editor
  Quando o aplicativo em foco muda para o terminal
  Então a faixa esvazia e o contexto recente é descartado

Cenário: Campo de senha
  Dado um iPhone pareado e um campo de senha em foco no Mac
  Quando o usuário digita "abc"
  Então a faixa permanece vazia
  E o Mac não guarda "abc" no contexto recente

Cenário: Faixa oculta
  Dado um iPhone pareado com a faixa visível
  Quando o usuário toca o botão de ocultar e digita "funç"
  Então nenhuma sugestão é exibida nem pedida ao Mac
  E tocar o botão de novo traz a faixa de volta

Cenário: Sugestão sem permissão de Acessibilidade
  Dado um iPhone pareado com "funç" digitado e a permissão de Acessibilidade revogada
  Quando o usuário toca numa sugestão
  Então nada é escrito no Mac e a página mostra "sem permissão"

Cenário: Sugestão obsoleta
  Dado um iPhone pareado digitando rápido
  Quando a lista de sugestões de "im" chega depois de o usuário já ter digitado "imp"
  Então a faixa não mostra a lista de "im"

Cenário: Sem sugestão
  Dado um iPhone pareado
  Quando o usuário digita uma sequência de letras que não começa nenhuma palavra conhecida
  Então a faixa fica vazia e as teclas continuam chegando normalmente

Cenário: Toque fora das sugestões
  Dado um iPhone pareado com a faixa vazia
  Quando o usuário toca na faixa
  Então nada acontece no Mac

Cenário: Log sem conteúdo
  Dado uma sessão em que o usuário aceitou 3 sugestões
  Quando o usuário abre o log da sessão
  Então o evento de fim de sessão traz a contagem 3 de sugestões aceitas
  E nenhuma palavra digitada, sugerida ou escolhida aparece no log
```

## 8. Prioridade MoSCoW

| Item | MoSCoW | Justificativa |
|------|--------|---------------|
| RF-01 a RF-09 | Must | Núcleo do pedido: ver e escolher palavras que completam o que se escreve, no idioma certo, sem ruído em comandos e sem vazar conteúdo |
| RNF de privacidade e segurança | Must | O canal passa a transportar palavras derivadas do que é digitado, e o Mac guarda um trecho em memória |
| RNF de desempenho | Must | Sugestão atrasada não serve, e as teclas não podem ficar mais lentas |
| RF-10 a RF-13 | Should | Conforto: caixa correta, previsão da palavra seguinte, faixa ocultável e retorno visual do toque |
| Leitura do texto do campo em foco no Mac | Won't (nesta feature) | Faria o app ler conteúdo de outros aplicativos; registrada como evolução possível |
| Correção automática de palavras erradas | Won't (nesta feature) | Muda o texto sem ação do usuário e atrapalha comandos no terminal |
| Previsão por modelo de linguagem ou serviço externo | Won't (nesta feature) | Exigiria rede ou modelo próprio; contraria RN-07 |
| Aprender palavras novas do usuário | Won't (nesta feature) | Exigiria guardar o que é digitado |
| Idiomas além de português do Brasil e inglês | Won't (nesta feature) | Fora do uso do usuário |
| Sugestões para teclas do controle ou do Teclado de Acessibilidade | Won't (nesta feature) | O pedido é para o teclado do iPhone |

## 9. Esclarecimentos

### Sessão 2026-09-19

Antes das perguntas, uma sonda no Mac do usuário verificou o motor de previsão de texto do macOS (resultados na seção 2, "Viabilidade"). As respostas seguiram as recomendações apresentadas com base nela.

- **Q:** De onde as sugestões tiram o contexto?
  **R:** (b) Das últimas palavras digitadas pelo iPhone, só em memória, apagadas a cada descarte. A palavra sozinha piora as sugestões, e ler o campo em foco pela Acessibilidade abriria uma superfície de privacidade nova e falharia em terminais.
- **Q:** Em que idioma vêm as sugestões?
  **R:** (c) Seletor PT / EN na própria faixa, com português como padrão, lembrado entre sessões. A detecção automática errou em trechos curtos, e a fonte de entrada não indica o idioma.
- **Q:** Ao tocar numa sugestão, entra um espaço depois da palavra?
  **R:** (a) Sim, sempre, como no iPhone. A faixa não mostra a própria palavra digitada, papel que a barra de espaço já cumpre.
- **Q:** Como tratar comandos, caminhos e opções?
  **R:** (c) A faixa esvazia quando a palavra contém caractere que não seja letra (`/`, `~`, `.`, `-`, `_`, `=`, dígitos), e um botão na página oculta e mostra a faixa. Ocultar a faixa em terminais impediria o uso principal, que é escrever prompts ao Claude Code.
- **Q:** A previsão da próxima palavra, depois de um espaço, entra nesta feature?
  **R:** (b) Sim, como Should.

## 10. Lacunas

- 🟡 A detecção de entrada segura no Mac, em campo de senha e no modo de entrada segura do Terminal, não foi verificada. A verificar por sonda no plano.
- 🟡 A altura disponível para a faixa sem reduzir as teclas abaixo do tamanho usável depende do modelo do iPhone e não foi medida.
- 🟡 O limite de 200 caracteres do contexto recente é estimativa; a sonda mostrou que poucas palavras já bastam, e o plano pode reduzi-lo.
- 🟡 A regra de RN-13 deixa sem sugestão palavras compostas com hífen, como "guarda-chuva", depois do hífen. Perda aceita em troca de não sugerir em opções de comando.
- 🟡 A 008 não foi sincronizada e tem os passos 13 a 17 do PM-1 pendentes; o plano desta feature deve registrar essa dependência.

## 11. Histórico de alterações

| Data | Alteração | Autor |
|------|-----------|-------|
| 2026-09-19 | Versão inicial gerada por `/reversa-requirements` | reversa |
| 2026-09-19 | Sessão do `/reversa-clarify`, precedida de sonda do motor de previsão do macOS: contexto pelas últimas palavras em memória, seletor PT / EN, espaço após a sugestão, supressão em palavras com cara de código, botão de ocultar e previsão da palavra seguinte como Should | reversa |

## Pendências de Qualidade

- Q-017 e Q-018: o documento cita iPhone, macOS, Claude Code e o motor de previsão do sistema, e o parágrafo de viabilidade da seção 2 descreve o mecanismo. A menção é deliberada, como na 008: a feature estende um teclado ligado a essas plataformas, e a viabilidade depende do que elas oferecem. Os requisitos das seções 4 a 7 descrevem o comportamento sem fixar a tecnologia.
