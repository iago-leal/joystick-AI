# Backlog: editor visual de atalhos e configuração persistida

> Origem: `_reversa_forward/002-paleta-comandos/requirements.md`, versão inicial de 2026-09-14, quando a feature cobria editor e paleta.
> Situação: fora da feature 002 por decisão do usuário na sessão de esclarecimentos de 2026-09-14 (resposta 1b). Serve de ponto de partida para o `/reversa-requirements` da feature seguinte; não é artefato do pipeline e não tem peso de requisito até lá.

## Decisões já tomadas para esta futura feature

- **Tipos de ação (resposta 2a):** acorde com repetição opcional, atalho de sistema, texto com Enter opcional, abrir a paleta, nenhuma e, fora da camada base, herdar da camada base. Abrir aplicativo, toque curto, toque longo e troca dos botões de clique ficam de fora.
- **Ponto de entrada do editor (resposta 4c):** ícone mínimo na barra de menus, com "Editar atalhos" e "Sair", e item fixo "Editar atalhos" no fim da paleta, que abre o editor em vez de digitar texto.
- **Paleta editável:** a lista fixa entregue pela feature 002 passa a ser editável no editor (incluir, remover, reordenar, rótulo, texto, Enter ao final), com 1 a 50 itens de uma linha e 1 a 1.000 caracteres.

## Termos

- **Botão modificador:** botão que, enquanto segurado, troca o conjunto de ações dos demais botões. No protótipo, L1, L2 e Options.
- **Camada:** conjunto de ações ativo num momento. A camada base vale sem modificador segurado; cada botão modificador define a sua.
- **Gatilho:** par formado por um botão e uma camada; é a unidade que recebe uma ação.
- **Acorde:** tecla do teclado acompanhada de zero ou mais teclas modificadoras (Command, Option, Control, Shift).

## Regras de negócio propostas

1. **Gatilho decidido no pressionar.** Cada gatilho tem no máximo uma ação, decidida no instante em que o botão é pressionado e mantida até ele ser solto (`_reversa_sdd/sdd/action-mapping.md#11`, EC-04).
2. **Vários modificadores.** Com mais de um segurado, vale a camada do que está segurado há mais tempo. Numa camada de modificador, cada gatilho herda a ação da camada base, salvo quando recebe ação própria, e "nenhuma" conta como ação própria (altera a decisão de L1 como único modificador em `action-mapping` §15).
3. **Modificador sem ação.** Um botão modificador não recebe ação em nenhuma camada; pode manter uma tecla modificadora do teclado pressionada enquanto segurado, como Options mantém Command (`action-mapping` RF-14).
4. **Apontamento fixo.** R1 e o clique do touchpad fazem o clique esquerdo, R2 o direito, e L1 reduz a velocidade do cursor mesmo quando também for modificador; os botões de clique não recebem atalho.
5. **Configuração inválida nunca substitui a vigente.** Na primeira leitura, sem configuração vigente, vale o mapeamento padrão (`action-mapping` RF-04, EC-01).
6. **Troca sem tecla presa.** Salvar ou recarregar a configuração solta antes as teclas e as teclas modificadoras mantidas e interrompe a repetição em curso.
7. **Arquivo criado só ao salvar.** Ao gravar, preservam-se as seções não gerenciadas, como `pointer` (altera `action-mapping` RF-02).
8. **Atalhos de sistema pelo nome.** O arquivo guarda o nome do atalho de sistema; o acorde é lido das preferências do macOS no momento do uso.
9. **Privacidade.** O log registra o gatilho executado e os eventos de configuração, nunca os acordes gravados nem as teclas injetadas.

## Mapeamento padrão proposto

Reproduz o protótipo em uso somado ao que a feature 002 entregar (PS abrindo a paleta).

| Camada | Botão | Ação |
|--------|-------|------|
| base | ↑ ↓ ← → | setas, com repetição |
| base | ✕ / ○ / △ | Enter / Esc / Tab |
| base | □ | Backspace, com repetição |
| base | Create | atalho de sistema Mission Control |
| base | R3 | Command+M (ditado do Raycast configurado pelo usuário) |
| base | PS | abrir a paleta de comandos |
| base | L3 | nenhuma |
| L1 | ✕ | texto `CONTINUAR` com Enter |
| L1 | △ | Shift+Tab |
| L2 | ← / → | atalhos de sistema mesa à esquerda / mesa à direita |
| L2 | ↓ / ↑ | atalhos de sistema janelas do aplicativo / Mission Control |
| L2 | △ | atalho de sistema próxima janela |
| Options (mantém Command) | → / ← | Command+Tab / Command+Shift+Tab |
| Options (mantém Command) | demais botões | nenhuma |

Nas camadas L1 e L2, os botões ausentes da tabela herdam a ação da camada base.

## Requisitos funcionais propostos

| ID provisório | Requisito | Prioridade | Critério de aceite |
|---------------|-----------|------------|--------------------|
| E-01 | Carregar mapeamento e paleta do arquivo ao iniciar; sem arquivo ou sem as seções, usar o padrão. | Must | Sem arquivo, ✕ envia Enter e PS abre a paleta padrão; com △ mapeado para Command+Z no arquivo, △ desfaz. |
| E-02 | Aplicar em até 1 s, sem reiniciar, alteração válida gravada no arquivo por outro programa. | Must | Trocar a ação de ○ num editor de texto e salvar faz ○ executar a nova ação em até 1 s. |
| E-03 | Validar o arquivo a cada leitura; se inválido, manter a configuração vigente, registrar o erro com a linha no log e exibi-lo no editor. | Must | Vírgula faltando na linha 12 mantém os atalhos; log e editor citam a linha 12. |
| E-04 | Gravar mapeamento e paleta criando pasta e arquivo se ausentes e preservando as demais seções. | Must | Salvar com `pointer` calibrado mantém `pointer` idêntico, campo a campo. |
| E-05 | Abrir o editor pelo ícone da barra de menus e pelo item fixo no fim da paleta. | Must | Sem teclado, o usuário abre o editor pela paleta; com o mouse, pelo ícone. |
| E-06 | Exibir os 18 botões e, por camada, a ação de cada um, com modificadores e funções de apontamento identificados como não editáveis. | Must | Na camada L2, ← mostra "mesa à esquerda"; R1 aparece como "clique esquerdo, fixo". |
| E-07 | Atribuir a um gatilho uma ação dos tipos decididos (resposta 2a). | Must | Atribuir Command+Z a L1+○ e salvar faz L1+○ desfazer. |
| E-08 | Gravar acorde pelo teclado físico, ignorando teclas injetadas pelo próprio app. | Must | Com o campo ativo, Command+Shift+Z é gravado; ✕ no controle não grava Enter. |
| E-09 | Marcar e desmarcar botão como modificador e escolher a tecla modificadora mantida. | Must | Marcar L3 como modificador faz aparecer a camada L3. |
| E-10 | Impedir salvar configuração inválida, indicando o gatilho ou item em falta. | Must | Marcar ✕ como modificador mantendo Enter desabilita "Salvar" e destaca ✕. |
| E-11 | Salvar aplicando em até 1 s e permitir descartar alterações não salvas. | Must | Após descartar, o editor volta à configuração vigente. |
| E-12 | Editar a lista da paleta: incluir, remover, reordenar, rótulo, texto e Enter ao final. | Must | Incluir `/reversa-docs` no topo e salvar faz a paleta abrir com ele no topo. |
| E-13 | Restaurar mapeamento e paleta padrão após confirmação. | Should | Cancelar a confirmação não altera nada. |
| E-14 | Selecionar botão pressionando-o no controle, num modo de identificação explícito. | Should | Com o modo ligado, △ seleciona △ e não envia Tab. |
| E-15 | Dispor os botões numa figura com a posição física do controle. | Should | □ aparece à esquerda do grupo de ação. |
| E-16 | Avisar quando o arquivo mudar por fora com alterações não salvas, oferecendo recarregar ou manter. | Should | Nada é sobrescrito sem escolha do usuário. |

## Requisitos não funcionais propostos

- Recarga em até 1 s, sem varredura periódica (`action-mapping` RNF-02).
- Arquivo de no máximo 1 MiB; acima disso, inválido.
- Log com carga, recarga, erro de validação e gravação, sem conteúdo de ações.
- Nenhuma troca de configuração deixa tecla ou modificador presos.

## Decisões das specs a revogar quando esta feature for entregue

`action-mapping` NG-01 (tela gráfica fora do escopo), `app-shell` NG-03 (tela de mapeamentos fora do escopo), `action-mapping` §15 (L1 como único modificador) e `action-mapping` RF-02 (criar o arquivo ao iniciar).
