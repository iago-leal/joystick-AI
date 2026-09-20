# Roadmap: Carga do controle no editor e na paleta, e cursor preservado após o menu da barra

> Identificador: `011-bateria-e-cursor-no-menu`
> Data: `2026-09-20`
> Requirements: `_reversa_forward/011-bateria-e-cursor-no-menu/requirements.md`
> Confidência: 🟢 CONFIRMADO, 🟡 INFERIDO, 🔴 LACUNA

## 1. Resumo da abordagem

A feature tem duas metades de natureza oposta, e o plano as trata de modo diferente. A metade da carga é construção sobre terreno conhecido: a interface de controles do sistema já expõe nível e estado de carga, o app já publica o controle ativo para o editor desde a `007-controle-ipega`, e a decisão de exibição cabe inteira num tipo de valor do `JoystickCore`, testável sem hardware. Nada disso toca a fila de entrada nem o temporizador de 120 Hz: a consulta é periódica, feita na main thread, e só existe enquanto uma das duas interfaces estiver aberta.

A metade do defeito é terreno desconhecido, e por isso entra pelo rito que o projeto já usa desde a 001: sondas no hardware antes de fixar a solução. Duas verificações baratas separam os dois mecanismos plausíveis, estado retido pelo sistema contra parada da emissão pelo app, e as duas convergem para o mesmo ponto de tratamento, o fim do ciclo do menu. A correção proposta é pequena e cabe no `StatusMenu`, que já implementa o protocolo de delegação do menu: ao fechar, o app solta o que possa ter ficado retido, ressincroniza a posição acompanhada do injetor e religa o temporizador de movimento se algum analógico estiver fora do repouso. Se as sondas mostrarem que a causa é outra, o ponto de tratamento continua servindo, e só muda o que se faz ali.

## 2. Princípios aplicados

O arquivo `.reversa/principles.md` não existe neste projeto, portanto não há princípios formais a confrontar. Na falta dele, a tabela abaixo usa as invariantes arquiteturais que o `_reversa_sdd/architecture.md` trata como não negociáveis e que esta feature poderia ferir.

| Princípio | Como a feature se relaciona | Status |
|-----------|------------------------------|--------|
| Núcleo puro: `JoystickCore` importa apenas `Foundation` (`architecture.md#3`, ADR-001) | A decisão de exibição vai para o núcleo como tipo de valor, sem importar a interface de controles; o acesso ao sistema fica no app | respeita |
| Núcleo funcional com casca imperativa (`architecture.md#2`) | O núcleo decide o que mostrar; o app consulta o sistema e desenha | respeita |
| Fila serializada e temporizador só sob demanda (ADR-006) | A consulta de carga não entra na fila de entrada e tem temporizador próprio, ligado apenas com editor ou paleta abertos | respeita |
| Catálogo fechado de eventos, sem dado sensível (ADR-008, 001 RN-12) | Os eventos novos entram no catálogo com teste próprio; porcentagem de carga não identifica pessoa | respeita |
| A paleta nunca toma o foco (002 RN-02) | A carga entra como parte desenhada do painel, que continua não ativador e transparente ao mouse | respeita |
| Sem rede (001 RN-12) | Nada na feature abre conexão | respeita |

## 3. Decisões técnicas

| ID | Decisão | Justificativa | Alternativas descartadas | Confidência |
|----|---------|----------------|--------------------------|-------------|
| D-01 | Ler a carga pela propriedade `battery` do controle na interface de controles do sistema | Disponível desde macOS 11, abaixo do mínimo de macOS 13 do projeto (`dependencies.md#2`); expõe nível de 0,0 a 1,0 e estado entre desconhecido, descarregando, carregando e cheio | Ler o relatório HID bruto do DualSense, caminho já usado para o PS e o touchpad: custaria decodificação por modelo e não serviria ao Ipega | 🟢 |
| D-02 | Tratar a carga como indisponível quando a propriedade não existir **ou** o estado for desconhecido, nunca deduzir indisponibilidade do número | O cabeçalho do sistema documenta nível padrão 0 e estado padrão desconhecido; decidir pelo número faria um controle sem suporte aparecer como "0%", exatamente o que RN-03 e RN-04 proíbem | Comparar o nível com zero; assumir que a propriedade ausente é o único caso de indisponibilidade | 🟢 |
| D-03 | Concentrar a decisão de exibição num tipo de valor novo do `JoystickCore`, que recebe nível, estado e presença de controle ativo e devolve o que mostrar: porcentagem inteira, marca de carregamento, marca de carga baixa ou frase de ausência | O alvo do aplicativo não tem teste automatizado (TD-01); no núcleo, as regras RN-01 a RN-07 ficam cobertas sem hardware | Decidir dentro da camada de interface, em dois lugares distintos, um para o editor e outro para a paleta | 🟢 |
| D-04 | Consultar a carga na main thread, por temporizador de 60 s ligado apenas enquanto o editor ou a paleta estiverem abertos, mais uma leitura imediata na conexão, na desconexão e na promoção do controle ativo | Atende RN-10 sem ferir RN-11; a interface de controles não emite notificação de mudança de carga, portanto a consulta periódica é o único caminho | Consultar a cada tick de 120 Hz; consultar sempre, mesmo sem interface aberta; esperar notificação do sistema, que não existe | 🟢 |
| D-05 | Estender o canal que a `007-controle-ipega` abriu, hoje publicando apenas o modelo do controle ativo, para publicar modelo e carga juntos | Um canal só evita dois caminhos concorrentes de verdade sobre o mesmo controle ativo, e o editor já consome esse canal | Criar um segundo canal exclusivo da carga; fazer cada interface consultar o sistema por conta própria | 🟢 |
| D-06 | No editor, exibir a carga no cabeçalho, ao lado do alternador de identificação, no corpo de 32 pt da escala de TV | É a única faixa do editor sempre visível sem rolagem, e a rolagem é só vertical | Rodapé, que divide espaço com salvar, descartar e contagem de problemas; aba Atalhos, que sumiria na aba Paleta | 🟡 |
| D-07 | Na paleta, exibir a carga como rodapé fixo do painel, desenhado fora do arranjo de linhas | Mantém a carga fora da navegação, da contagem de itens e do índice do último confirmado, como exige RN-08, sem tocar a máquina da paleta | Acrescentar uma linha à lista, o que a tornaria selecionável e mudaria a contagem; usar o cabeçalho, que empurraria a seleção para baixo na abertura | 🟡 |
| D-08 | Marcar a carga baixa por cor **e** por símbolo, nunca só por cor | A leitura é a 3 m, e o painel da paleta tem fundo escuro próprio; depender de matiz sozinha é frágil nessa distância | Só cor; piscar, que competiria com a leitura do texto; som, proibido por RN-07 | 🟡 |
| D-09 | Acrescentar a carga ao evento de conexão do controle e criar um evento próprio, emitido apenas na mudança de faixa | O log não tem rotação (TD-07); registrar cada leitura somaria uma linha por minuto de sessão sem ganho de diagnóstico | Registrar toda leitura; não registrar nada, o que deixaria a queda de carga fora do histórico | 🟢 |
| D-10 | Tratar o defeito no fim do ciclo do menu, pelo método de fechamento do protocolo de delegação, no `StatusMenu`, que já é delegado do próprio menu e já usa o método de abertura | É o único ponto do app que sabe, com certeza, que o rastreamento modal terminou; nenhum outro componente observa esse ciclo | Observar ativação e desativação do app, que disparam em muitas outras situações; instalar um monitor global de eventos, que pediria permissão nova | 🟡 |
| D-11 | No fechamento, executar três providências: repostar a soltura dos botões de mouse que possam ter ficado retidos, ressincronizar a posição acompanhada do injetor com a leitura real do sistema e religar o temporizador de movimento se algum analógico estiver fora do repouso | Cada providência cobre um dos mecanismos plausíveis do defeito, e as três são idempotentes: executadas sem necessidade, não produzem efeito observável | Reiniciar o leitor do controle, caro e com risco de perder o controle ativo; suspender e retomar o portão de injeção, que registraria eventos falsos de permissão | 🟡 |
| D-12 | Confirmar o mecanismo por duas sondas no hardware antes de escrever a correção, com o detalhe em `investigation.md` | É o rito do projeto desde a 001, e a resposta muda o que fazer no ponto de tratamento, não onde tratar | Escrever a correção direto e validar no portão manual, o que arriscaria uma correção que trata sintoma e não causa | 🔴 |

## 4. Premissas

| Premissa | Origem (`requirements.md` seção) | Risco se errada |
|----------|----------------------------------|-----------------|
| ⚠️ A condução **não** se recupera sozinha após o ciclo do menu, e o clique físico é mesmo a única saída hoje. O plano supõe estado retido de forma duradoura, e não espera por um evento que chegaria mais tarde. | §10, única `[DÚVIDA]` remanescente | Se a condução voltar sozinha em poucos segundos, o defeito é de latência de retomada e não de estado retido. D-11 continuaria correto, mas as três providências poderiam ser desnecessárias, e o esforço certo seria reduzir a espera, não normalizar estado. A sonda P-01 mede exatamente isso e desfaz a premissa em um minuto de observação. |

> ⚠️ Esta premissa foi adotada com o usuário ciente da lacuna, que preferiu levá-la ao plano como sonda em vez de nova rodada de clarificação.

## 5. Delta arquitetural

| Componente | Arquivo de origem no legado | Tipo de mudança | Resumo |
|------------|------------------------------|-----------------|--------|
| `JoystickCore` | `_reversa_sdd/architecture.md#3` | componente-novo | Tipo de valor com a decisão de exibição da carga: porcentagem inteira, carregamento, faixa baixa em 15% e as duas frases de ausência |
| `controller-input` | `_reversa_sdd/code-analysis.md#2` | regra-alterada | O canal que publica o controle ativo passa a levar modelo e carga juntos; a leitura da carga acompanha conexão, desconexão e promoção |
| `app-shell` | `_reversa_sdd/code-analysis.md#1` | componente-novo | Consultor periódico de carga na main thread, ligado apenas com editor ou paleta abertos |
| `app-shell` | `_reversa_sdd/code-analysis.md#1` | regra-alterada | O `StatusMenu` passa a tratar o fim do ciclo do menu, com as três providências de D-11 |
| `editor` | `_reversa_sdd/code-analysis.md#8` | regra-alterada | Cabeçalho do editor ganha a carga; nada mais da tela muda |
| `palette` | `_reversa_sdd/code-analysis.md#6` | regra-alterada | O painel ganha rodapé fixo com a carga, fora do arranjo de linhas; a máquina de estados da paleta não muda |
| `pointer` | `_reversa_sdd/code-analysis.md#3` | regra-alterada | O temporizador de movimento ganha um ponto de religamento a partir da main thread, usado só pelo fim do ciclo do menu |
| `injection` | `_reversa_sdd/code-analysis.md#4` | regra-alterada | O injetor ganha ressincronização explícita da posição acompanhada, hoje possível apenas pela passagem natural dos 100 ms |
| `diagnostics-log` | `_reversa_sdd/code-analysis.md#9` | contrato-alterado | Carga no evento de conexão, evento novo de mudança de faixa e evento do ciclo do menu |

## 6. Delta no modelo de dados

- Resumo das mudanças: o arquivo de configuração não muda de forma nem de versão. O núcleo ganha os tipos de valor da carga. O log, que é o único contrato de dados persistido afetado, ganha um campo no evento de conexão e dois eventos novos, sem mudança da versão de esquema.
- Detalhe completo em: `_reversa_forward/011-bateria-e-cursor-no-menu/data-delta.md`

## 7. Delta de contratos externos

| Contrato | Tipo | Arquivo de detalhe |
|----------|------|--------------------|
| Log de diagnóstico | arquivo (JSONL por sessão) | `_reversa_forward/011-bateria-e-cursor-no-menu/interfaces/diagnostic-log.md` |

O canal do teclado remoto e do controle virtual, entregue nas features 008 e 010, não é tocado: o controle virtual não tem carga a exibir, conforme RN-05.

## 8. Plano de migração

Não há migração de dados: nenhum arquivo persistido muda de forma, e a versão do esquema do log continua a mesma. O que existe é uma ordem de execução, imposta pelas sondas.

1. Registrar o número de testes verdes antes de qualquer mudança, como as features anteriores fazem na primeira ação
2. Executar as sondas P-01 e P-02 do `investigation.md`, que não exigem código novo, apenas observação com o log em modo de depuração
3. Fixar, à luz das sondas, quais das três providências de D-11 entram na correção, e registrar a decisão como emenda se o resultado contrariar D-10 ou D-11
4. Construir a metade da carga, que não depende das sondas e pode correr em paralelo: tipo de valor no núcleo, com testes, depois consultor, canal, editor e paleta
5. Aplicar a correção do ciclo do menu
6. Acrescentar os eventos ao catálogo do log, com os testes que o catálogo exige
7. Portão manual no hardware, com DualSense e com Ipega, e com o controle virtual em coexistência

## 9. Riscos e mitigações

| Risco | Impacto | Probabilidade | Mitigação |
|-------|---------|---------------|-----------|
| O Ipega não expõe carga, e a feature entrega, para ele, apenas a frase de indisponibilidade | baixo | alto | É o comportamento correto por RN-04, não um defeito; a sonda P-03 mede antes de o usuário descobrir no uso |
| As sondas não reproduzem o defeito, porque ele depende de uma combinação não percebida | alto | médio | O roteiro do `onboarding.md` fixa a sequência exata relatada pelo usuário, inclusive qual botão do controle clica o ícone; se ainda assim não reproduzir, o defeito volta à clarificação com evidência de log |
| A correção trata sintoma e a condução volta a cair noutra situação de rastreamento modal, como uma folha de confirmação | médio | médio | As três providências de D-11 são genéricas o bastante para servir a qualquer fim de rastreamento; o `regression-watch.md` registra a hipótese para a próxima feature |
| O rodapé da paleta empurra o painel para além da área visível numa tela pequena | baixo | baixo | O painel já calcula altura máxima contra a área visível na abertura; o rodapé entra nesse cálculo |
| A consulta periódica de carga acorda o processo sem necessidade quando nada está aberto | baixo | baixo | D-04 liga o temporizador apenas com editor ou paleta abertos, o mesmo critério de sob demanda do temporizador de movimento |
| Repostar soltura de botão ao fechar o menu provoca clique indesejado no aplicativo em foco | médio | baixo | Soltura sem pressionamento correspondente não produz clique; a sonda P-02 confirma antes, e o portão manual verifica que nada é acionado atrás do menu |

## 10. Critério de pronto

- [ ] Todas as ações do `actions.md` marcadas `[X]`
- [ ] `cross-check.md` (se executado) sem CRITICAL nem HIGH
- [ ] `regression-watch.md` gerado
- [ ] Sondas P-01 a P-03 respondidas e registradas no `investigation.md`
- [ ] Portão manual aprovado com DualSense, com Ipega e com o controle virtual em coexistência
- [ ] Re-extração reversa executada e sem regressão vermelha (recomendado, não obrigatório)

## 11. Histórico de alterações

| Data | Alteração | Autor |
|------|-----------|-------|
| 2026-09-20 | Versão inicial gerada por `/reversa-plan` | reversa |
