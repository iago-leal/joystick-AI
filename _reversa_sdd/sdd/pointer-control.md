# Spec: pointer-control

**Versão:** 1.1
**Status:** Rascunho
**Autor:** reversa-spec-sdd
**Data:** 2026-09-14
**Reviewers:** iago

> Selo 🟡 PLANEJADO em todos os itens. Fonte primária: [`prd.md`](../prd.md).

---

## 1. Resumo

🟡 Componente que transforma o DualSense em mouse: o touchpad move o cursor para ajustes finos, o analógico esquerdo faz deslocamentos longos, o analógico direito rola a tela e os botões configurados clicam e arrastam. Atende ao passo 6 da jornada (revisar artefatos e código apontando e rolando).

---

## 2. Contexto e Motivação

**Problema:**
🟡 Revisar código e artefatos gerados pelos agentes exige apontar, clicar em abas e linhas e rolar documentos longos. Sem um substituto para o mouse, o programador de sofá volta à mesa a cada revisão.

**Evidências:**
🟡 Premissa 1 do `ideation.md` (precisão do apontamento), classificada como crítica; risco de impacto alto na seção 8 do PRD. Decisão do usuário: touchpad e analógico ativos ao mesmo tempo.

**Por que agora:**
🟡 A precisão do apontamento é a premissa com maior incerteza de experiência de uso e precisa ser validada antes de investir nos demais componentes.

---

## 3. Goals (Objetivos)

- [ ] 🟡 G-01: Permitir clicar em alvos de 16 × 16 pontos (abas e ícones do VS Code) com taxa de acerto ≥ 90% na primeira tentativa.
- [ ] 🟡 G-02: Atravessar a largura de uma tela de 1920 pontos com o analógico em até 1,5 s.
- [ ] 🟡 G-03: Rolar um arquivo de 1.000 linhas do início ao fim em até 10 s com o analógico direito.

**Métricas de sucesso:**
| Métrica | Baseline atual | Target | Prazo |
|---------|---------------|--------|-------|
| 🟡 Acerto em alvos de 16 × 16 pt na primeira tentativa | 🟡 não medido | 🟡 ≥ 90% em 20 tentativas | 🟡 fim da prova de conceito |
| 🟡 Latência entre entrada e movimento do cursor | 🟡 não medido | 🟡 p95 ≤ 20 ms | 🟡 fim do MVP |

---

## 4. Non-Goals (Fora do Escopo)

- 🟡 NG-01: Gestos multitoque de trackpad do macOS (pinça para zoom, deslizar com três dedos entre espaços).
- 🟡 NG-02: Movimento absoluto em que a posição no touchpad corresponde a uma posição fixa na tela.
- 🟡 NG-03: Uso do giroscópio como apontador.
- 🟡 NG-04: Clique do meio e botões extras de mouse.
- 🟡 NG-05: Perfis de sensibilidade diferentes por aplicativo.

---

## 5. Usuários e Personas

**Usuário primário:** 🟡 Programador de sofá revisando código e artefatos do Reversa numa tela a distância (monitor ou TV).
**Usuário secundário:** 🟡 Não há.

**Jornada atual (sem a feature):**
1. 🟡 O usuário lê a resposta do agente no terminal.
2. 🟡 Para abrir um arquivo, trocar de aba ou rolar um documento, pega o mouse ou o trackpad.
3. 🟡 A revisão prende o usuário à mesa.

**Jornada futura (com a feature):**
1. 🟡 O usuário leva o cursor até a região desejada com o analógico esquerdo.
2. 🟡 Ajusta a posição fina deslizando o dedo no touchpad.
3. 🟡 Clica com o botão configurado e rola o conteúdo com o analógico direito.

---

## 6. Requisitos Funcionais

### 6.1 Requisitos Principais

| ID | Requisito | Prioridade | Critério de Aceite |
|----|-----------|-----------|-------------------|
| RF-01 | 🟡 O sistema deve mover o cursor de forma relativa ao deslocamento de um dedo no touchpad, na mesma direção do movimento. | Must | 🟡 Deslizar o dedo para a direita move o cursor para a direita; manter o dedo parado não move o cursor. |
| RF-02 | 🟡 O sistema deve ignorar o primeiro evento de cada novo toque no touchpad, para que o cursor não salte ao pousar o dedo. | Must | 🟡 Pousar o dedo em qualquer ponto do touchpad não altera a posição do cursor. |
| RF-03 | 🟡 O sistema deve mover o cursor continuamente com o analógico esquerdo, com velocidade proporcional à inclinação e curva de aceleração configurável (padrão: expoente 2,0). | Must | 🟡 Inclinação de 30% move o cursor a menos de 10% da velocidade máxima; inclinação total atinge a velocidade máxima configurada (padrão 1.500 pt/s). |
| RF-04 | 🟡 O sistema deve rolar o conteúdo sob o cursor com o analógico direito, nos eixos vertical e horizontal, com velocidade proporcional à inclinação. | Must | 🟡 Inclinar o analógico direito para baixo rola o arquivo aberto no VS Code para baixo; para a direita, rola horizontalmente. |
| RF-05 | 🟡 O sistema deve executar clique esquerdo com `mouseDown` ao pressionar e `mouseUp` ao soltar o botão mapeado (padrão: clique do touchpad e R2). | Must | 🟡 Pressionar e soltar R2 sobre uma aba do VS Code a seleciona. |
| RF-06 | 🟡 O sistema deve executar clique direito com o botão mapeado (padrão: R1). | Must | 🟡 Pressionar R1 sobre um arquivo no explorador do VS Code abre o menu de contexto. |
| RF-07 | 🟡 O sistema deve permitir arrastar: com o botão de clique esquerdo pressionado, movimentos do touchpad ou do analógico geram eventos de arraste. | Must | 🟡 Segurar R2 e mover o analógico seleciona um trecho de texto no editor. |
| RF-08 | 🟡 O sistema deve reconhecer duplo clique quando dois cliques esquerdos ocorrem em até 400 ms a no máximo 4 pt de distância. | Must | 🟡 Dois cliques rápidos de R2 sobre uma palavra no editor a selecionam. |
| RF-09 | 🟡 O sistema deve reduzir a velocidade do analógico e do touchpad para 30% enquanto o botão modificador (padrão: L1) estiver pressionado sem combinação com outro botão. | Should | 🟡 Com L1 segurado, a mesma inclinação do analógico desloca o cursor a 30% da distância obtida sem L1, com tolerância de 5%. |
| RF-10 | 🟡 O sistema deve ler sensibilidade do touchpad, velocidade máxima e expoente do analógico, velocidade de rolagem e inversão de eixo de rolagem a partir da configuração do `action-mapping`. | Should | 🟡 Alterar `pointer.stickMaxSpeed` no JSON e salvar muda a velocidade em até 1 s, sem reiniciar o app. |
| RF-11 | 🟡 O sistema deve suspender o controle do cursor quando o modo de condução estiver desativado. | Must | 🟡 Com o modo desligado pelo `app-shell`, mover o analógico não move o cursor. |
| RF-12 | 🟡 O sistema deve manter o cursor dentro dos limites da união de todas as telas conectadas. | Must | 🟡 Com Mac e TV lado a lado, o cursor atravessa de uma tela para a outra e para na borda externa. |

### 6.2 Fluxo Principal (Happy Path)

1. 🟡 O usuário inclina o analógico esquerdo em direção à barra de abas do VS Code.
2. 🟡 O sistema calcula o deslocamento a cada quadro (120 Hz), aplica zona morta e curva de aceleração e injeta movimento do cursor.
3. 🟡 O usuário solta o analógico perto da aba e desliza o dedo no touchpad para posicionar o cursor sobre ela.
4. 🟡 O sistema converte o deslocamento do toque em movimento relativo, com a sensibilidade configurada.
5. 🟡 O usuário pressiona e solta R2.
6. 🟡 O sistema injeta `mouseDown` e `mouseUp` esquerdos na posição do cursor.
7. 🟡 O usuário inclina o analógico direito para baixo.
8. 🟡 O sistema injeta eventos de rolagem contínua sob o cursor.
9. 🟡 Resultado: aba selecionada e conteúdo rolado sem mouse.

### 6.3 Fluxos Alternativos

**Fluxo Alternativo A: arrastar para selecionar texto**
1. 🟡 O usuário segura R2 com o cursor no início do trecho.
2. 🟡 Move o touchpad ou o analógico até o fim do trecho; o sistema injeta eventos de arraste.
3. 🟡 Solta R2; o sistema injeta `mouseUp` e o texto fica selecionado.

**Fluxo Alternativo B: ajuste de precisão**
1. 🟡 O usuário segura L1 e move o analógico.
2. 🟡 O sistema aplica o fator de 30% enquanto L1 estiver pressionado sem outro botão.

---

## 7. Requisitos Não-Funcionais

| ID | Requisito | Valor alvo | Observação |
|----|-----------|-----------|------------|
| RNF-01 | 🟡 Performance | 🟡 p95 ≤ 20 ms da entrada ao evento de cursor injetado | 🟡 Soma de `controller-input` e deste componente. |
| RNF-02 | 🟡 Suavidade | 🟡 Atualização do cursor a 120 Hz durante movimento do analógico | 🟡 Temporizador ativo só enquanto houver inclinação fora da zona morta. |
| RNF-03 | 🟡 Consumo de CPU | 🟡 ≤ 5% de um núcleo durante movimento contínuo; ≤ 1% parado | 🟡 Medido no Monitor de Atividade. |
| RNF-04 | 🟡 Acessibilidade | 🟡 Sensibilidades ajustáveis em faixa de 0,1× a 5× | 🟡 Atende usuários com diferentes níveis de controle motor. |

---

## 8. Design e Interface

**Componentes afetados:** 🟡 Cursor do sistema; nenhuma tela própria.

**Comportamento esperado:**
🟡 Touchpad e analógico esquerdo atuam de forma simultânea e aditiva sobre o cursor. O touchpad segue o dedo de modo relativo, como o trackpad de um notebook. O analógico gera movimento contínuo enquanto inclinado. O analógico direito rola sob o cursor. Os botões de clique são definidos pelo mapeamento de `action-mapping` com ações `mouseLeft` e `mouseRight`.

**Estados da UI:**
- Estado vazio: 🟡 sem controle ativo, o cursor responde só ao mouse físico.
- Estado de carregamento: 🟡 não se aplica.
- Estado de erro: 🟡 sem permissão de Acessibilidade, eventos não são injetados e o `app-shell` exibe o alerta de permissão.
- Estado de sucesso: 🟡 cursor responde ao controle com o modo de condução ativo.

---

## 9. Modelo de Dados

**Entidades novas ou modificadas:**

```
PointerSettings {                // seção "pointer" do arquivo de configuração
  touchpadSensitivity: Float     // padrão 1,0; faixa 0,1 a 5,0
  stickMaxSpeed: Float           // pontos por segundo; padrão 1500
  stickExponent: Float           // curva de aceleração; padrão 2,0
  deadzone: Float                // padrão 0,12
  scrollSpeed: Float             // linhas por segundo na inclinação total; padrão 40
  invertScrollY: Bool            // padrão false
  precisionFactor: Float         // padrão 0,3
  doubleClickIntervalMs: Int     // padrão 400
}
```

**Migrações necessárias:** 🟡 Não. Valores ausentes no JSON assumem os padrões acima.

---

## 10. Integrações e Dependências

| Dependência | Tipo | Impacto se indisponível |
|-------------|------|------------------------|
| 🟡 `controller-input` | Obrigatória | 🟡 Sem eventos, o cursor não se move. |
| 🟡 `action-mapping` (configuração e botões de clique) | Obrigatória | 🟡 Sem configuração válida, o componente usa os padrões da seção 9. |
| 🟡 Injeção de eventos do macOS (CGEvent) | Obrigatória | 🟡 Sem ela, nada é injetado; ver EC-01. |
| 🟡 Permissão de Acessibilidade | Obrigatória | 🟡 Sem ela, o macOS descarta os eventos injetados; o `app-shell` orienta a concessão. |

---

## 11. Edge Cases e Tratamento de Erros

| Cenário | Trigger | Comportamento esperado |
|---------|---------|----------------------|
| EC-01: 🟡 Permissão de Acessibilidade revogada durante o uso | 🟡 Usuário remove o app da lista em Ajustes | 🟡 O sistema detecta a falha na próxima injeção, para de injetar e notifica o `app-shell`, sem travar. |
| EC-02: 🟡 Controle desconecta com clique pressionado | 🟡 Bateria acaba durante um arraste | 🟡 O sistema injeta `mouseUp` imediato ao receber `buttonUp` sintético ou `controllerDisconnected`, evitando botão preso. |
| EC-03: 🟡 Touchpad com dois dedos | 🟡 Usuário pousa um segundo dedo | 🟡 O sistema considera só o primeiro toque para mover o cursor e ignora o segundo. |
| EC-04: 🟡 Touchpad e analógico ao mesmo tempo | 🟡 Usuário inclina o analógico e desliza o dedo | 🟡 Os deslocamentos são somados no mesmo quadro. |
| EC-05: 🟡 Tela desconectada | 🟡 TV desligada com o cursor sobre ela | 🟡 O sistema recalcula os limites e reposiciona o cursor na tela restante. |
| EC-06: 🟡 Modo desativado durante arraste | 🟡 Usuário desliga o modo segurando R2 | 🟡 O sistema injeta `mouseUp` antes de suspender. |
| EC-07: 🟡 App em tela cheia com captura de cursor | 🟡 Jogo ou app que oculta o cursor em foco | 🟡 O sistema continua injetando eventos sem tratamento especial; o conflito é mitigado pelo modo desligado. |

---

## 12. Segurança e Privacidade

- **Autenticação:** 🟡 Não se aplica.
- **Autorização:** 🟡 Exige permissão de Acessibilidade para injetar eventos de mouse.
- **Dados sensíveis:** 🟡 Nenhum; posições do cursor não são persistidas.
- **Auditoria:** 🟡 Não se aplica; log de depuração opcional sem coordenadas.

---

## 13. Plano de Rollout

- **Estratégia:** 🟡 Entregue junto com `controller-input` na prova de conceito, com teste de acerto em alvos de 16 × 16 pt antes de seguir para os demais componentes.
- **Como reverter (rollback):** 🟡 Desativar o modo de condução pelo `app-shell` ou reinstalar a versão anterior pela tag git.
- **Monitoramento pós-deploy:** 🟡 Na primeira semana, anotar situações em que foi preciso voltar ao mouse físico e ajustar os padrões da seção 9.

---

## 14. Open Questions

| # | Pergunta | Impacto | Dono | Prazo |
|---|---------|---------|------|-------|
| OQ-01 | 🟡 Os padrões de velocidade e expoente atendem numa TV a 2 m de distância? Exige calibração com uso real. | Médio | iago | primeira semana de uso |
| OQ-02 | 🟡 A rolagem deve usar eventos em pixels (suave) ou em linhas? Depende do comportamento no VS Code e no terminal. | Baixo | iago | fim da prova de conceito |

---

## 15. Decisões Tomadas (Decision Log)

| Decisão | Alternativas consideradas | Racional |
|---------|--------------------------|---------|
| 🟡 Touchpad e analógico esquerdo ativos juntos; analógico direito rola | 🟡 Só touchpad; só analógico | 🟡 Escolha do usuário: combina deslocamento longo com ajuste fino. |
| 🟡 Touchpad relativo | 🟡 Absoluto | 🟡 O touchpad é pequeno demais para mapear telas grandes com precisão. |
| 🟡 Precisão reduzida com L1 | 🟡 Botão dedicado de precisão | 🟡 L1 já é o modificador de `action-mapping`; reaproveitá-lo não consome botão extra. |

---

## Apêndice

### Referências
- 🟡 [`prd.md`](../prd.md), seções 4, 8 e 9
- 🟡 [`ideation.md`](../ideation.md), premissa 1
- 🟡 [`controller-input.md`](./controller-input.md)

### Histórico de Revisões
| Versão | Data | Autor | Mudanças |
|--------|------|-------|---------|
| 1.0 | 2026-09-14 | reversa-spec-sdd | Criação inicial |
| 1.1 | 2026-09-14 | reversa-spec-sdd | Ditado passa para L2 segurado; clique direito passa para R1 (pedido do usuário). |

---

## Relatório de avaliação

```
  SCORE TOTAL: 100.0/100  —  ⭐ Excelente — Pronta para implementação

  BREAKDOWN POR DIMENSÃO:
  Dimensão             Score      Peso     Contribuição
  --------------------------------------------------
  Completude           100%       30%     30.0/pt
  Testabilidade        100%       25%     25.0/pt
  Clareza              100%       20%     20.0/pt
  Escopo               100%       15%     15.0/pt
  Edge Cases           100%       10%     10.0/pt
```

- 🟡 Iterações: 1
- 🟡 Gaps críticos: nenhum
- 🟡 Open questions pendentes: 2 (seção 14)
- 🟡 Observação: o scorer é heurístico e verifica estrutura e vocabulário, não a correção técnica; as open questions de impacto alto continuam bloqueando o plano.

---
Gerado por reversa-spec-sdd em 2026-09-14T18:24:08Z
Fonte: prd.md
