# Investigation: carga do controle e ciclo do menu da barra

> Identificador: `011-bateria-e-cursor-no-menu`
> Data: `2026-09-20`
> Roadmap: `_reversa_forward/011-bateria-e-cursor-no-menu/roadmap.md`

## 1. Pesquisa de fundo

### 1.1 Carga do controle

A interface de controles do sistema expõe, em cada controle, uma propriedade opcional de bateria com dois campos: o nível, de 0,0 a 1,0, e o estado, entre desconhecido, descarregando, carregando e cheio. A disponibilidade começa em macOS 11, portanto abaixo do mínimo de macOS 13 declarado no manifesto (`_reversa_sdd/dependencies.md#2`), e nenhuma verificação de versão em tempo de execução é necessária. 🟢

Dois detalhes do cabeçalho do sistema governam D-02 e merecem registro literal, porque contrariam a intuição:

- o nível **tem valor padrão 0**, e não valor ausente;
- o estado **tem valor padrão desconhecido**.

A consequência prática é que um controle que não informa carga pode responder com a propriedade presente, nível 0 e estado desconhecido, o que, exibido sem cuidado, vira "0%" na tela do usuário. Decidir a indisponibilidade pelo estado, e nunca pelo número, é o que separa "controle descarregado" de "controle que não conta quanto tem". 🟢

Não há notificação de mudança de carga na interface de controles: só há consulta. Isso é o que força o desenho de D-04, com temporizador próprio, e o que impede prometer atualização mais fina que o período escolhido. 🟢

### 1.2 O que o projeto já sabe sobre janelas, foco e eventos sintéticos

O projeto já colidiu três vezes com a fronteira entre o que ele injeta e o que o sistema decide, e as três colisões orientam a leitura do defeito atual:

| Episódio | O que se aprendeu | Fonte |
|----------|-------------------|-------|
| Sonda P-08 da 001 | A consulta de permissão de postagem continuava verdadeira depois da revogação, e a detecção teve de migrar para outra função; o sistema nem sempre responde o que parece responder | `_reversa_sdd/domain.md#4` (RI-03), `validation-report.md` 001:139 |
| Emenda E003 da 003 | No macOS 26, a ativação de janela pedida a partir do controle é recusada; a saída foi janela em nível flutuante mais clique sintético na barra de título | `_reversa_sdd/domain.md#4` (RI-23) |
| Posição acompanhada do injetor | A leitura de posição do sistema só reflete o que foi postado depois que o sistema processa; o app mantém as 32 últimas posições e uma janela de 100 ms para não desfazer o próprio movimento | `_reversa_sdd/code-analysis.md#4` |

O padrão comum é que o app e o sistema mantêm, cada um, uma versão do estado, e o defeito aparece quando as duas divergem sem que ninguém reconcilie.

### 1.3 Leitura do defeito relatado

Fatos disponíveis, todos de evidência de campo da clarificação de 2026-09-20:

1. O cursor para de se mover **e** o clique deixa de produzir efeito.
2. Só ocorre com o menu deste app; outros menus da barra do macOS abertos pelo controle não reproduzem.
3. Um clique físico devolve o funcionamento.
4. Não se sabe se a condução voltaria sozinha, porque a observação não durou o bastante.

Duas verificações no código, feitas durante o planejamento, estreitam o espaço de hipóteses:

- **Não há chamada síncrona da fila de entrada para a main thread.** As três chamadas síncronas existentes vão no sentido contrário, da main para a fila de entrada, e servem ao encerramento, à tela de alvos e ao serviço remoto. Portanto a main thread presa no rastreamento modal do menu **não** congela a fila de entrada: o leitor do controle, o temporizador de 120 Hz e o injetor continuam correndo. 🟢
- **O menu do ícone é um menu comum ligado ao item da barra**, cujo rastreamento o próprio AppKit conduz num laço modal na main thread deste processo. É o único lugar do app onde um clique do usuário abre rastreamento modal no mesmo processo que injeta os eventos. Isso explica por que outros menus da barra não reproduzem: neles, quem rastreia é outro processo. 🟡

## 2. Alternativas avaliadas

### 2.1 Origem da carga

| Alternativa | Avaliação | Veredito |
|-------------|-----------|----------|
| Propriedade de bateria da interface de controles | Uma linha de leitura, serve a qualquer modelo aceito, disponível abaixo do mínimo do projeto | **Escolhida** (D-01) |
| Relatório HID bruto do DualSense | O app já lê relatórios brutos para o PS e para o touchpad, e o byte de carga do DualSense é conhecido; mas exigiria decodificação por modelo e não resolveria o Ipega | Descartada |
| Registro do sistema de entrada e saída | Traz carga de dispositivos Bluetooth, mas por caminho frágil de correlação de dispositivo, o mesmo que o projeto já usa a contragosto para descobrir transporte | Descartada |

### 2.2 Onde a decisão de exibição mora

| Alternativa | Avaliação | Veredito |
|-------------|-----------|----------|
| Tipo de valor no núcleo puro | Cobre RN-01 a RN-07 com teste sem hardware, o único antídoto disponível para TD-01 | **Escolhida** (D-03) |
| Decidir na camada de interface | Duplicaria a regra entre editor e paleta, com risco de as duas divergirem na faixa de 15% | Descartada |

### 2.3 Tratamento do defeito

| Alternativa | Avaliação | Veredito |
|-------------|-----------|----------|
| Tratar no fim do ciclo do menu, pelo delegado que já existe | Ponto único, certo e barato; o `StatusMenu` já implementa o método de abertura do mesmo protocolo | **Escolhida** (D-10) |
| Observar ativação e desativação do aplicativo | Dispara em muitas outras situações, inclusive na abertura do editor, e misturaria o tratamento do defeito com o caminho da emenda E003 | Descartada |
| Monitor global de eventos para detectar o fim do rastreamento | Pediria permissão nova e contrariaria o desenho de permissões já fechado em `permissions.md` | Descartada |
| Trocar o menu do ícone por um painel próprio, no estilo não ativador da paleta | Resolveria por evitar o rastreamento modal, mas reescreve uma interface que funciona para quem usa o trackpad, e é desproporcional antes das sondas | Descartada por ora; registrada como saída se as sondas mostrarem que o rastreamento é irrecuperável |

## 3. Sondas

As três sondas abaixo correm no hardware antes de a correção ser escrita. Nenhuma exige código novo: bastam o app em modo de depuração e observação dirigida.

### Resultados apurados no PM-0 de 2026-09-20

| Sonda | Veredito | O que mediu |
|-------|----------|-------------|
| P-01 | **Não volta sozinha**, e o menu **fica aberto** | Sessenta segundos de espera sem trackpad; o cursor não volta, e o menu permanece visivelmente aberto durante todo o período morto |
| P-02 | Inconclusiva na primeira leitura, resolvida pela P-04 | Os silêncios do log que eu havia tomado por período morto eram inatividade do usuário; os botões sempre chegaram |
| P-03 | **O Ipega informa carga** | `controller.connected` com `charge: 60` e `chargeState: discharging`; o risco do `roadmap.md` §9 não se confirmou |
| P-04 | **O sistema toma os analógicos; os botões passam** | 156 tiques com o menu aberto: `stickX` e `stickY` em 0,000 em todos, enquanto `r1 down` e `r1 up` entraram pelos manipuladores normais |
| P-05 | **Direcional e faces chegam, mas vazam** | Direcional, ○ e ✕ entregues durante o rastreamento, cada um disparando o acorde da camada base no aplicativo **atrás** do menu; o menu não os usava |
| P-06 | **A correção funciona** | Realce desce pelo direcional, ✕ confirma, ○ sai, nada vaza; `menu.cycle` com `keys=14`, `keys=6` e `keys=0` |

#### O que isso fez com D-10 e D-11

**D-11 está falsificada.** As três providências supunham estado retido no fim do ciclo. Não há estado retido: enquanto o menu rastreia, o sistema captura os eixos e o aplicativo não tem o que soltar, ressincronizar nem religar. Rodadas, encontrariam zero e falso, que é exatamente a assinatura que o `interfaces/diagnostic-log.md` §3 antecipou como sinal de causa fora do alcance de D-11.

**D-10 está redirecionada, não descartada.** O protocolo de delegação do menu continua sendo o ponto certo, pelo motivo que D-10 deu — é o único lugar do app que conhece o ciclo do rastreamento. O que muda é o fim: interessa a **abertura**, para começar a traduzir botão em tecla de navegação, e o fechamento serve para parar de traduzir e registrar o ciclo.

**A saída de §2.3 não foi necessária.** O painel próprio resolveria por evitar o rastreamento, mas as sondas mostraram que o rastreamento não é irrecuperável: ele só é surdo aos eixos. Com os botões chegando, o menu se navega por teclado, que é como menu se navega, e o app já sabe injetar teclado. Fica registrada como saída se o comportamento do sistema mudar.

**Um defeito a mais, achado de raspão.** A P-05 revelou que, hoje, apertar o direcional com o menu aberto dispara os acordes da camada base no aplicativo que está atrás. Ninguém tinha notado, e não estava no relato de campo. A correção o elimina junto, porque engolir o que não tem tradução é parte dela.

### P-01: a condução volta sozinha?

**Pergunta:** depois de reproduzir o defeito, a condução pelo controle volta sem clique físico, e em quanto tempo?

**Procedimento:** reproduzir o defeito, então esperar sessenta segundos sem tocar em nada, movendo apenas o analógico a cada dez segundos. Se não voltar, trocar o aplicativo em foco pelo teclado e testar de novo.

**Por que importa:** responde a única lacuna do `requirements.md` e confirma ou desfaz a premissa do roadmap. Se voltar sozinha, o defeito é de espera, não de estado retido, e D-11 encolhe.

### P-02: o app continua postando durante o defeito?

**Pergunta:** enquanto a condução parece morta, o log continua registrando postagens do ponteiro?

**Procedimento:** rodar com o log em modo de depuração, reproduzir o defeito, mover o analógico e tocar o touchpad durante o período morto, e então ler os eventos de postagem do ponteiro no arquivo da sessão, comparando os instantes com o momento do clique no ícone.

**Por que importa:** separa os dois mecanismos. Se as postagens continuam, o app faz a parte dele e o sistema é que retém, o que aponta para a soltura e a ressincronização de D-11. Se as postagens cessam, o problema é interno, e a suspeita passa para o temporizador de movimento e para o estado do injetor.

**Observação de apoio:** o evento de postagem só é registrado quando há origem, ou seja, nos eventos de início de movimento, de toque e de botão; os ticks de 120 Hz não registram, por decisão da 001. Mover o analógico a partir do repouso garante pelo menos um registro de origem.

### P-03: o Ipega informa carga?

**Pergunta:** o Ipega, reconhecido pela categoria de controle do Switch, responde com carga, ou com estado desconhecido?

**Procedimento:** conectar o Ipega como controle ativo, abrir o editor e observar o que a interface mostra, comparando com o comportamento do DualSense no mesmo lugar.

**Por que importa:** decide se a frase de indisponibilidade será o caminho normal para metade dos controles suportados, o que muda o texto a escrever e a expectativa do usuário.

## 4. Padrões aplicáveis

- **Reconciliação em fronteira de estado.** Sempre que o app e o sistema mantêm versões do mesmo estado, é preciso um ponto explícito de reconciliação. O projeto já tem um, no portão de injeção, que solta tudo antes de desligar e repete as solturas ao retomar (`_reversa_sdd/domain.md#4`, RI-04). D-11 aplica o mesmo padrão a outra fronteira, o fim do rastreamento modal.
- **Operação idempotente na reconciliação.** As três providências de D-11 devem poder rodar sem necessidade, sem efeito observável. Soltar um botão já solto, ressincronizar uma posição já correta e religar um temporizador já ligado precisam ser operações neutras, do mesmo modo que a soltura sintética da desconexão já é.
- **Decisão pura na borda de apresentação.** A regra de exibição é função de três entradas e nada mais, sem relógio nem estado acumulado, o que a torna testável por tabela.

## 5. Fontes

- Cabeçalhos do sistema, instalados localmente: a definição da propriedade de bateria do controle e dos quatro estados, com os padrões de nível e de estado
- `_reversa_sdd/code-analysis.md` §1, §3, §4, §6, §8 e §9
- `_reversa_sdd/domain.md` §3.1, §3.2, §3.3 e §4
- `_reversa_sdd/state-machines.md` §5 e §6
- `_reversa_sdd/architecture.md` §2, §3, §6 e §7
- `_reversa_sdd/addenda/007-controle-ipega.md` e `_reversa_sdd/addenda/010-joystick-virtual-iphone.md`
- Relato de campo do usuário e clarificação de 2026-09-20, registrada em `requirements.md` §9
