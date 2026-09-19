# Requirements: iPhone como teclado touch do Mac

> Identificador: `008-iphone-teclado-remoto`
> Data: `2026-09-19`
> Pasta da extração reversa: `_reversa_sdd/`
> Confidência: 🟢 CONFIRMADO, 🟡 INFERIDO, 🔴 LACUNA / DÚVIDA

## 1. Resumo executivo

A feature transforma o iPhone, preso ao controle na horizontal, num teclado de Mac completo, desenhado à maneira do Teclado de Acessibilidade do macOS, com ⌘, ⇧, ⌥ e ⌃. Cada toque chega ao Mac como a tecla física correspondente, de modo que o programador de sofá pode digitar linhas de comando e disparar atalhos com os dedos, em vez de mover o ponteiro e clicar tecla a tecla. Hoje a digitação livre depende do Teclado de Acessibilidade na tela do Mac, acionado pelo controle (feature 006), em que cada tecla custa um movimento do ponteiro e um clique. O espelhamento da tela do Mac no iPhone fica fora desta feature (seção 8).

## 2. Contexto a partir do legado

| Fonte | Trecho relevante | Confidência |
|-------|------------------|-------------|
| Pedido do usuário, 2026-09-19 | "Muitas vezes preciso digitar algo e o teclado de acessibilidade ajuda, mas acabo tendo que ficar clicando ao invés de digitar. Se eu conseguisse fazer um teclado touch com o meu iPhone, que eu poderia acoplar fisicamente ao joystick, seria fantástico." | 🟢 |
| Esclarecimento do usuário, 2026-09-19 | "Precisaria que fosse um teclado de computador mesmo, que reproduzisse esse teclado de acessibilidade, porque o teclado do iOS não tem Command, Shift, Option." | 🟢 |
| `_reversa_sdd/addenda/006-teclado-virtual.md#Resumo da entrega` | A digitação livre atual usa o Teclado de Acessibilidade do macOS, alternado por um botão; as teclas são acionadas com os cliques do ponteiro. As teclas F1 a F12 saem com a máscara de função | 🟢 |
| `_reversa_sdd/prd.md#5. Não-objetivos (out)` | O teclado virtual ficou "não excluído, mas também não incluído"; distribuição pública, App Store e notarização estão fora | 🟡 |
| `_reversa_sdd/personas.md#Persona 1: Programador de sofá` | Usuário único, diante da TV a cerca de 3 m, que quer passar a maior parte do tempo sem teclado | 🟢 |
| `_reversa_sdd/domain.md#3.1 Controle e entrada (001)` | 001 RN-04: nenhuma desconexão deixa entrada presa. 001 RN-12: o app não usa rede; entradas só vão ao log local | 🟢 |
| `_reversa_sdd/permissions.md#2. Matriz de permissões do sistema operacional` | A única permissão exigida é a de Acessibilidade; a linha "Rede" registra nenhum uso | 🟢 |
| `_reversa_sdd/permissions.md#4. Restrições de acesso internas` | Textos, rótulos e acordes nunca vão ao log | 🟢 |
| `_reversa_sdd/injecao-de-eventos/requirements.md#Regras de Negócio` | RN-IN-02: sem a permissão, teclas são descartadas sem aviso. RN-IN-07 e RN-IN-08: modificadores com contagem de referência por tecla, compartilhada por todas as origens. RN-IN-11: repetição por `keyDown` com marca de autorrepetição. RN-IN-16: teclas nunca vão ao log | 🟢 |
| `_reversa_sdd/atalhos/requirements.md#Regras de Negócio` | RN-AT-09: a repetição dos acordes do controle usa tempos fixos, 400 ms e depois 50 ms | 🟢 |
| `_reversa_sdd/architecture.md#4. Integrações externas` | Não há API, servidor nem mensageria; todas as integrações são com o sistema operacional | 🟢 |

**Viabilidade.** Os recursos da Apple não atendem ao pedido: o Espelhamento do iPhone faz o caminho inverso (o Mac controla o iPhone), e o Sidecar e o Controle Universal funcionam só com o iPad. O iPhone também não pode se apresentar ao Mac como teclado Bluetooth, porque o iOS não oferece essa função a aplicativos. O caminho viável é uma página aberta no navegador do iPhone, servida pelo app do Mac na rede local, que desenha o teclado e envia cada toque; o app injeta a tecla pelo mecanismo que o controle já usa. A página dispensa instalar aplicativo no iPhone, o que respeita a ausência de distribuição pela App Store. 🟡 (conhecimento das plataformas, não verificado por sonda neste projeto)

**Constatação.** A feature rompe 001 RN-12: o app passa a aceitar conexões da rede local pela primeira vez, e o canal permite qualquer combinação de teclas. Por isso a superfície nova vem desligada, exige pareamento, aceita um aparelho por vez e cifra todo o tráfego (seção 4). 🟢

## 3. Personas e cenários de uso

| Persona | Objetivo | Cenário-chave |
|---------|----------|---------------|
| Programador de sofá (`_reversa_sdd/personas.md#Persona 1: Programador de sofá`) | Escrever uma linha de comando no terminal sem levantar | Com o iPhone preso ao controle na horizontal, digita `git log --oneline -5` no teclado da página e toca em Return |
| Programador de sofá | Usar atalhos de edição | Segura ⌘ com um dedo e toca C com outro para copiar; depois toca ⌘, solta e toca V para colar |
| Programador de sofá | Apagar e corrigir | Segura a tecla de apagar e vê os caracteres sumirem na cadência do Mac |
| Programador de sofá | Escrever em português | Com a fonte de entrada ABNT2 ativa no Mac, vê o Ç e os acentos nos rótulos da página e digita "ação" |

A frequência esperada é contínua durante as sessões de programação, com rajadas de algumas dezenas de teclas. 🟡

## 4. Regras de negócio novas ou alteradas

1. **RN-01:** O app passa a aceitar conexões de um único aparelho, na rede local, exclusivamente para receber teclas. Nenhuma outra função do app fica acessível por esse canal. 🟢
   - Origem no legado: `_reversa_sdd/domain.md#3.1 Controle e entrada (001)` (001 RN-12)
   - Tipo: alterada (001 RN-12 passa a ler "sem rede, exceto o teclado remoto, restrito à rede local")
2. **RN-02:** O teclado remoto começa desligado a cada abertura do app e só é ligado por ação explícita do usuário no Mac. Desligado, o app não aceita conexão alguma. 🟢
   - Tipo: nova
3. **RN-03:** Todo o tráfego entre a página e o app é cifrado. O app gera uma identidade própria, que o iPhone instala e marca como confiável uma única vez; a identidade persiste entre aberturas do app e sua parte secreta nunca sai do Mac. Sem a identidade confiável no iPhone, a conexão não se estabelece. 🟢
   - Tipo: nova
4. **RN-04:** Só um aparelho pareado pode enviar teclas. O pareamento exige um código exibido no Mac; o código vale para uma única sessão do teclado remoto e deixa de valer quando o teclado é desligado ou o app encerra. 🟢
   - Tipo: nova
5. **RN-05:** Com um aparelho conectado, uma segunda conexão é recusada até a primeira terminar. 🟢
   - Tipo: nova
6. **RN-06:** Cada tecla da página corresponde a uma posição física do teclado do Mac. Tocar pressiona a tecla, e soltar a solta; o caractere resultante é decidido pela fonte de entrada ativa no Mac, inclusive acentos compostos por tecla morta. 🟢
   - Tipo: nova
7. **RN-07:** Os modificadores ⌘, ⇧, ⌥ e ⌃ têm dois modos. Segurados, valem enquanto o dedo estiver sobre eles. Tocados e soltos sem outra tecla no meio, ficam presos até a próxima tecla que não seja modificador, e se soltam depois dela. Tocar de novo um modificador preso o solta. 🟢
   - Tipo: nova
8. **RN-08:** Os modificadores do teclado remoto somam-se aos do controle pela mesma contagem por tecla: um ⌘ mantido pelo controle e outro pelo iPhone só se soltam quando os dois forem soltos. 🟢
   - Origem no legado: `_reversa_sdd/injecao-de-eventos/requirements.md#Regras de Negócio` (RN-IN-07, RN-IN-08)
   - Tipo: alterada (nova origem da contagem)
9. **RN-09:** Uma tecla que não seja modificador, segurada, repete na cadência de repetição configurada no macOS (atraso inicial e intervalo), e não nos tempos fixos de 400 ms e 50 ms dos acordes do controle. Só a última tecla segurada repete. 🟢
   - Origem no legado: `_reversa_sdd/atalhos/requirements.md#Regras de Negócio` (RN-AT-09, que segue valendo para o controle)
   - Tipo: nova
10. **RN-10:** Nenhuma perda de conexão deixa tecla presa: quando o aparelho sai, a conexão cai, a página vai para segundo plano ou o teclado remoto é desligado, o app solta todas as teclas e modificadores mantidos pelo iPhone e interrompe a repetição. 🟢
    - Origem no legado: `_reversa_sdd/domain.md#3.1 Controle e entrada (001)` (001 RN-04, estendida ao teclado remoto)
    - Tipo: alterada
11. **RN-11:** As teclas recebidas passam pelo portão de injeção como as do controle: sem a permissão de Acessibilidade, são descartadas, e a página é avisada. 🟢
    - Origem no legado: `_reversa_sdd/injecao-de-eventos/requirements.md#Regras de Negócio` (RN-IN-02)
    - Tipo: alterada (o descarte deixa de ser silencioso para o teclado remoto)
12. **RN-12:** Os rótulos das teclas acompanham a fonte de entrada ativa no Mac e mudam quando o usuário a troca, sem recarregar a página. 🟢
    - Tipo: nova
13. **RN-13:** Teclas, rótulos exibidos, código de pareamento e endereço do aparelho nunca vão ao log. O log registra apenas que o teclado foi ligado ou desligado, que um aparelho se conectou, foi recusado (com o motivo) ou saiu, e o número de teclas da sessão ao final dela. 🟢
    - Origem no legado: `_reversa_sdd/domain.md#3.1 Controle e entrada (001)` (001 RN-12); `_reversa_sdd/injecao-de-eventos/requirements.md#Regras de Negócio` (RN-IN-16)
    - Tipo: alterada (novos eventos, mesma minimização)
14. **RN-14:** O controle continua funcionando enquanto o teclado remoto está conectado; as entradas das duas origens são injetadas na ordem de chegada. 🟡
    - Tipo: nova

## 5. Requisitos Funcionais

| ID | Requisito | Prioridade | Critério de aceite | Confidência |
|----|-----------|------------|--------------------|-------------|
| RF-01 | O usuário liga e desliga o teclado remoto pelo menu do app no Mac | Must | Com o teclado desligado, nenhuma conexão é aceita; ligado, o menu indica o estado | 🟢 |
| RF-02 | Ao ligar, o Mac exibe, legível a 3 m, o endereço da página e o código de pareamento, também na forma de código escaneável pela câmera do iPhone | Must | Da TV, o usuário abre a página no iPhone escaneando o código, sem consultar outro lugar | 🟢 |
| RF-03 | Na primeira vez, o app oferece ao iPhone a identidade de RN-03 para instalação, e o roteiro de instalação descreve os passos de confiança no iOS | Must | Seguindo o roteiro uma vez, as sessões seguintes abrem a página sem aviso de conexão insegura, inclusive após reabrir o app | 🟡 |
| RF-04 | A página desenha, numa só tela na horizontal, o teclado completo do Mac: Esc e F1 a F12, números, letras e pontuação, Tab, Caps Lock, Return, apagar, espaço, ⇧ ⌃ ⌥ ⌘ dos dois lados e as quatro setas | Must | Em um iPhone na horizontal, todas as teclas estão visíveis sem rolar, com a disposição do teclado do Mac | 🟡 |
| RF-05 | Cada tecla pressiona no toque e solta ao levantar o dedo, conforme RN-06, com vários dedos ao mesmo tempo | Must | Tocar A produz "a" no aplicativo em foco; segurar ⌘ e tocar C copia a seleção | 🟢 |
| RF-06 | Os modificadores seguem RN-07 e mostram na página se estão soltos, mantidos ou presos | Must | Tocar e soltar ⌘ e depois tocar V cola, e o ⌘ aparece solto em seguida | 🟢 |
| RF-07 | Teclas seguradas repetem conforme RN-09 | Must | Segurar apagar por 2 s apaga vários caracteres na cadência configurada no macOS | 🟢 |
| RF-08 | Os rótulos seguem a fonte de entrada ativa, conforme RN-12 | Must | Com ABNT2 ativo, a tecla à direita do L mostra Ç; ao trocar para o layout americano, passa a mostrar ; sem recarregar a página | 🟢 |
| RF-09 | Com ⇧ ou ⌥ mantido ou preso, os rótulos mostram o caractere que cada tecla produzirá | Should | Com ⇧ preso, a tecla 1 mostra ! | 🟡 |
| RF-10 | A página mostra o estado da ligação (conectado, sem permissão de Acessibilidade no Mac, desconectado) e marca visualmente cada tecla tocada | Must | Ao revogar a permissão no Mac, a página passa a "sem permissão" em até 3 s | 🟡 |
| RF-11 | O app solta tudo o que o iPhone mantinha, conforme RN-10 | Must | Com ⌘ segurado no iPhone, bloquear o iPhone solta o ⌘ no Mac em até 1 s | 🟢 |
| RF-12 | A página se reconecta sozinha quando volta ao primeiro plano, sem novo pareamento enquanto o código for válido | Should | Após bloquear e desbloquear o iPhone, a página volta a digitar sem pedir o código | 🟡 |
| RF-13 | O app registra no log os eventos de RN-13, sem conteúdo | Must | Uma sessão com 50 teclas gera eventos com a contagem 50 e nenhuma tecla, rótulo, código ou endereço | 🟢 |

## 6. Requisitos Não Funcionais

| Tipo | Requisito | Evidência ou justificativa | Confidência |
|------|-----------|----------------------------|-------------|
| Desempenho | Uma tecla chega ao aplicativo em foco em até 150 ms após o toque, na rede doméstica, no percentil 95 | Digitação tecla a tecla; acima disso, a digitação parece atrasada | 🟡 |
| Desempenho | Nenhuma tecla é perdida nem trocada de ordem numa rajada de 10 teclas por segundo | Digitação rápida de comandos | 🟡 |
| Segurança | Todo o tráfego é cifrado, e a página só conecta a um Mac cuja identidade o iPhone marcou como confiável | RN-03; decisão do usuário na sessão de 2026-09-19 | 🟢 |
| Segurança | Nenhuma conexão de fora da rede local é aceita, e nenhum aparelho sem o código vigente consegue enviar teclas | RN-01, RN-02, RN-04 e RN-05; o canal permite qualquer atalho | 🟢 |
| Privacidade | Teclas, código e endereço do aparelho não são gravados em disco, nem no log nem em cache do app; só a identidade de RN-03 é persistida, legível apenas pelo usuário do Mac | RN-13; `_reversa_sdd/permissions.md#4. Restrições de acesso internas` | 🟢 |
| Compatibilidade | Funciona no navegador padrão do iOS sem instalar aplicativo no iPhone | PRD sem App Store nem distribuição pública (`_reversa_sdd/prd.md#5. Não-objetivos (out)`) | 🟡 |
| Permissões | Nenhuma permissão nova de TCC além da Acessibilidade; o aviso de conexões recebidas do firewall do macOS, se aparecer, é documentado no roteiro de instalação | `_reversa_sdd/permissions.md#2. Matriz de permissões do sistema operacional` | 🟡 |
| Arquitetura | As regras de pareamento, modificadores presos, repetição e soltura ficam no núcleo testável, sem depender de rede | `_reversa_sdd/architecture.md#2. Estilo arquitetural` (núcleo funcional com casca imperativa) | 🟢 |
| Observabilidade | Eventos do teclado remoto no log JSONL existente, com a versão de esquema ampliada por eventos novos | `_reversa_sdd/architecture.md#5. Modelo de dados em arquivo` | 🟡 |

## 7. Critérios de Aceitação

```gherkin
Cenário: Primeira instalação e pareamento
  Dado que o app está aberto com a permissão de Acessibilidade
  E o usuário ligou o teclado remoto pelo menu pela primeira vez
  Quando o usuário escaneia o código exibido no Mac e segue o roteiro de confiança no iPhone
  Então a página abre sem aviso de conexão insegura e mostra "conectado"

Cenário: Digitar uma linha de comando
  Dado um iPhone pareado, na horizontal, com o terminal em foco no Mac
  Quando o usuário toca as teclas de "ls -la" e depois Return
  Então o terminal recebe "ls -la" seguido de Return

Cenário: Modificador segurado
  Dado um iPhone pareado e um texto selecionado no Mac
  Quando o usuário segura ⌘ com um dedo e toca C com outro
  Então o texto é copiado

Cenário: Modificador preso por toque
  Dado um iPhone pareado
  Quando o usuário toca e solta ⌘ e em seguida toca V
  Então o conteúdo é colado
  E o ⌘ aparece solto na página

Cenário: Soltar um modificador preso sem usá-lo
  Dado um iPhone pareado com ⇧ preso por toque
  Quando o usuário toca ⇧ de novo
  Então ⇧ fica solto e a próxima letra sai minúscula

Cenário: Repetição
  Dado um iPhone pareado com um campo de texto preenchido em foco
  Quando o usuário segura a tecla de apagar por 2 s
  Então vários caracteres são apagados na cadência de repetição configurada no macOS
  E a repetição para ao levantar o dedo

Cenário: Rótulos pela fonte de entrada
  Dado um iPhone pareado e a fonte de entrada ABNT2 ativa no Mac
  Quando o usuário troca a fonte de entrada para o layout americano
  Então a tecla à direita do L passa de Ç para ; sem recarregar a página

Cenário: Acento por tecla morta
  Dado um iPhone pareado e a fonte de entrada ABNT2 ativa
  Quando o usuário toca a tecla do acento agudo e depois A
  Então o aplicativo em foco recebe "á"

Cenário: Modificadores do controle e do iPhone juntos
  Dado um iPhone pareado e o controle mantendo ⌘ por um modificador
  Quando o usuário solta o ⌘ no iPhone
  Então o ⌘ continua pressionado no Mac até o controle também soltá-lo

Cenário: Conexão perdida com tecla segurada
  Dado um iPhone pareado com ⌘ segurado e a tecla de apagar em repetição
  Quando o iPhone é bloqueado
  Então em até 1 s o Mac solta ⌘ e a tecla de apagar, e a repetição para

Cenário: Reconexão após bloqueio
  Dado um iPhone pareado
  Quando o iPhone é bloqueado e desbloqueado com a página aberta
  Então a página volta a enviar teclas sem pedir o código outra vez

Cenário: Teclado remoto desligado
  Dado que o app acabou de abrir e o usuário não ligou o teclado remoto
  Quando qualquer aparelho tenta abrir a página
  Então a conexão é recusada e nada é digitado no Mac

Cenário: Identidade não confiável
  Dado um aparelho que não instalou nem confiou na identidade do app
  Quando ele tenta abrir a página
  Então a conexão cifrada não se estabelece e nada é digitado

Cenário: Código errado
  Dado que o teclado remoto está ligado
  Quando um aparelho informa um código diferente do exibido no Mac
  Então o pareamento é recusado, nada é digitado e o log registra a recusa sem o código informado

Cenário: Segundo aparelho
  Dado um iPhone pareado e conectado
  Quando outro aparelho tenta se conectar com o código correto
  Então a segunda conexão é recusada até o primeiro aparelho sair

Cenário: Sem permissão de Acessibilidade
  Dado um iPhone pareado e a permissão de Acessibilidade revogada no Mac
  Quando o usuário toca uma tecla
  Então nada é digitado no Mac
  E a página mostra "sem permissão"

Cenário: Log sem conteúdo
  Dado uma sessão com 50 teclas tocadas no iPhone
  Quando o usuário abre o log da sessão
  Então há um evento de fim de sessão com a contagem 50
  E nenhuma tecla, rótulo, código de pareamento ou endereço do aparelho aparece no log
```

## 8. Prioridade MoSCoW

| Item | MoSCoW | Justificativa |
|------|--------|---------------|
| RF-01 a RF-08, RF-10, RF-11 | Must | Núcleo do pedido: teclado de Mac completo com modificadores, sem clicar tecla a tecla, e sem tecla presa |
| RF-13 e RNF de privacidade | Must | Mantêm 001 RN-12 e RN-IN-16 para o que é digitado |
| RNF de segurança (cifragem, rede local, pareamento) | Must | O canal permite qualquer atalho e transporta cada tecla, inclusive senhas |
| RNF de desempenho | Must | Na digitação tecla a tecla, a latência é o que decide se o teclado é usável |
| RF-09, RF-12 | Should | Conforto: rótulos com ⇧ e ⌥ e reconexão sem código |
| Espelhamento da tela do Mac no iPhone | Won't (nesta feature) | Descartado pelo usuário na sessão de 2026-09-19 |
| Teclado do iOS, composição de texto e ditado pelo iPhone | Won't (nesta feature) | O teclado do iOS não tem ⌘, ⌥ e ⌃; o ditado segue pelo Raycast (`_reversa_sdd/addenda/prd-l01-ditado-pelo-raycast.md`) |
| Área de trackpad na página | Won't (nesta feature) | O usuário quer apenas o teclado; o ponteiro segue no controle |
| Uso na vertical | Won't (nesta feature) | O teclado completo não cabe na vertical com teclas usáveis |
| Aplicativo nativo para iOS | Won't (nesta feature) | Exigiria assinatura e reinstalação periódica no iPhone |
| Suporte físico que prende o iPhone ao controle | Won't (fora do software) | Acessório de mercado; a feature garante o uso na horizontal |

## 9. Esclarecimentos

### Sessão 2026-09-19

- **Q:** A necessidade de espelhamento fica atendida pelo teclado remoto, ou é preciso ver no iPhone parte da tela do Mac?
  **R:** Espelhar a tela, no momento, é demais e não é necessário; a feature é só o teclado.
- **Q:** O envio é em bloco, com o teclado do iOS, ou letra a letra?
  **R:** Não o teclado do iOS, mas um teclado de computador que reproduza o Teclado de Acessibilidade, com Command, Shift e Option, para digitar linhas de comando. Cada toque vira tecla no Mac.
- **Q:** O tráfego é cifrado?
  **R:** (b) Cifragem obrigatória desde a primeira versão, com um certificado instalado e confiado no iPhone uma única vez.
- **Q:** Qual a orientação do iPhone preso ao controle?
  **R:** (a) Horizontal, com o teclado completo numa só tela.
- **Q:** Disposição e rótulos das teclas?
  **R:** (c) Rótulos acompanham a fonte de entrada ativa do Mac, trocando quando o layout é alternado.
- **Q:** Comportamento de ⌘, ⇧, ⌥ e ⌃ no toque?
  **R:** (c) Os dois: segurar mantém; tocar e soltar prende até a próxima tecla.
- **Q:** Tecla segurada repete?
  **R:** (a) Repete como num teclado físico, pela taxa de repetição do Mac.

## 10. Lacunas

- 🟡 O caminho de instalação e confiança da identidade no iOS e o comportamento do navegador com ela não foram verificados. A verificar por sonda no plano, antes de fixar RF-03.
- 🟡 A leitura da fonte de entrada ativa e dos caracteres de cada posição, incluindo teclas mortas, não foi verificada no macOS alvo. A verificar por sonda no plano.
- 🟡 A tecla fn (globo), o bloqueio de um modificador por dois toques e o teclado numérico ficaram fora da lista de RF-04, por não terem sido pedidos.
- 🟡 O aviso do firewall do macOS para conexões recebidas e a interação com a assinatura local (`_reversa_sdd/adrs/002-assinatura-local-para-preservar-tcc.md`) não foram verificados. A verificar por sonda no plano.
- 🟡 A latência de 150 ms é meta, a medir no portão manual com o iPhone na rede doméstica.

## 11. Histórico de alterações

| Data | Alteração | Autor |
|------|-----------|-------|
| 2026-09-19 | Versão inicial gerada por `/reversa-requirements` | reversa |
| 2026-09-19 | Sessão do `/reversa-clarify`: teclado de Mac tecla a tecla em lugar do teclado do iOS, espelhamento e trackpad excluídos, cifragem obrigatória, orientação horizontal, rótulos pela fonte de entrada, modificadores segurados ou presos e repetição pela cadência do macOS | reversa |

## Pendências de Qualidade

- Q-017 e Q-018: o documento cita iPhone, iOS, macOS e Teclado de Acessibilidade, e o parágrafo de viabilidade da seção 2 descreve o mecanismo (página servida pela rede local). A menção é deliberada: o pedido nomeia a plataforma e pergunta se a solução é possível, e a resposta depende do que ela permite. Os requisitos das seções 4 a 7 descrevem o comportamento sem fixar a tecnologia.
