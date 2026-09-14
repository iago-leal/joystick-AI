# Spec: controller-input

**Versão:** 1.1
**Status:** Rascunho
**Autor:** reversa-spec-sdd
**Data:** 2026-09-14
**Reviewers:** iago

> Selo 🟡 PLANEJADO em todos os itens. Fonte primária: [`prd.md`](../prd.md).

---

## 1. Resumo

🟡 Componente que conecta o controle DualSense ao app e converte tudo o que ele produz (botões, direcional, analógicos, gatilhos e touchpad) em eventos de entrada normalizados, com aviso de conexão e desconexão. É a base consumida por `pointer-control`, `action-mapping`, `voice-dictation` e `app-shell`.

---

## 2. Contexto e Motivação

**Problema:**
🟡 Nenhuma função do produto existe sem a leitura confiável do controle. O app precisa receber a entrada do DualSense mesmo quando não é o aplicativo em primeiro plano, já que o foco estará no terminal ou no VS Code durante toda a sessão.

**Evidências:**
🟡 Premissa 2 do `ideation.md` (acesso ao hardware no macOS), classificada como crítica pelo usuário; risco de impacto alto na seção 8 do PRD.

**Por que agora:**
🟡 É o primeiro componente da cadeia e o que valida a premissa técnica mais barata de testar; os demais dependem da sua interface de eventos.

---

## 3. Goals (Objetivos)

- [ ] 🟡 G-01: Detectar a conexão de um DualSense por USB e por Bluetooth em até 2 s após o sistema reconhecê-lo.
- [ ] 🟡 G-02: Entregar eventos de todos os botões, do direcional, dos dois analógicos, dos dois gatilhos e do touchpad (posição de até dois toques e clique) com o app em segundo plano.
- [ ] 🟡 G-03: Manter latência de processamento, do evento do framework até a entrega ao consumidor, de no máximo 5 ms no p95.

**Métricas de sucesso:**
| Métrica | Baseline atual | Target | Prazo |
|---------|---------------|--------|-------|
| 🟡 Elementos do DualSense lidos com o app em segundo plano | 🟡 0 de 18 | 🟡 18 de 18 (exceto botão de mudo, ver OQ-01) | 🟡 fim da prova de conceito |
| 🟡 Latência de processamento p95 | 🟡 inexistente | 🟡 ≤ 5 ms | 🟡 fim do MVP |

---

## 4. Non-Goals (Fora do Escopo)

- 🟡 NG-01: Suporte a controles que não sejam DualSense (Xbox, DualShock 4, Switch Pro) no MVP.
- 🟡 NG-02: Uso simultâneo de mais de um controle; apenas um DualSense ativo por vez.
- 🟡 NG-03: Controle de gatilhos adaptativos, alto-falante e sensores de movimento (giroscópio e acelerômetro).
- 🟡 NG-04: Leitura HID de baixo nível fora do framework GameController, salvo se OQ-01 exigir.
- 🟡 NG-05: Interpretação de eventos em ações; este componente só normaliza e entrega, sem decidir o que cada botão faz.

---

## 5. Usuários e Personas

**Usuário primário:** 🟡 Programador de sofá (ver [`personas.md`](../personas.md)), conectando o DualSense ao Mac com ou sem TV.
**Usuário secundário:** 🟡 Os componentes internos `pointer-control`, `action-mapping`, `voice-dictation` e `app-shell`, que consomem os eventos.

**Jornada atual (sem a feature):**
1. 🟡 O usuário conecta o DualSense ao Mac.
2. 🟡 O macOS reconhece o controle, que só funciona em jogos compatíveis.
3. 🟡 Fora de jogos, o controle não produz efeito algum no terminal ou no VS Code.

**Jornada futura (com a feature):**
1. 🟡 O usuário conecta o DualSense por cabo ou Bluetooth.
2. 🟡 O sistema detecta o controle e passa a entregar eventos aos consumidores internos.
3. 🟡 Com qualquer aplicativo em foco, cada interação no controle chega ao app em forma de evento normalizado.

---

## 6. Requisitos Funcionais

### 6.1 Requisitos Principais

| ID | Requisito | Prioridade | Critério de Aceite |
|----|-----------|-----------|-------------------|
| RF-01 | 🟡 O sistema deve detectar a conexão de um DualSense por USB e por Bluetooth e emitir o evento `controllerConnected` com nome, tipo de conexão e identificador. | Must | 🟡 Conectar o controle por cabo e depois por Bluetooth gera um `controllerConnected` em cada caso em até 2 s. |
| RF-02 | 🟡 O sistema deve emitir `controllerDisconnected` quando o controle ativo for desconectado, desligado ou perder o Bluetooth. | Must | 🟡 Desligar o controle segurando o botão PS gera `controllerDisconnected` em até 2 s. |
| RF-03 | 🟡 O sistema deve receber a entrada do controle com o app em segundo plano. | Must | 🟡 Com o Terminal em primeiro plano, pressionar ✕ gera `buttonDown` e `buttonUp` para `cross`. |
| RF-04 | 🟡 O sistema deve emitir `buttonDown` e `buttonUp` para ✕, ○, □, △, L1, R1, L2, R2, L3, R3, Options, Create, PS, clique do touchpad e as quatro direções do direcional. | Must | 🟡 Um teste manual guiado registra os dois eventos para cada um dos 18 identificadores listados. |
| RF-05 | 🟡 O sistema deve emitir `axisChanged` para os eixos X e Y de cada analógico, com valores normalizados em -1,0 a 1,0 e zona morta configurável (padrão 0,12). | Must | 🟡 Com o analógico em repouso nenhum evento fora de 0,0 é emitido; no curso máximo o valor absoluto chega a 1,0. |
| RF-06 | 🟡 O sistema deve emitir `triggerChanged` para L2 e R2, com valor de 0,0 a 1,0, e tratá-los como botão pressionado a partir de 0,5. | Must | 🟡 Pressionar R2 até a metade gera `buttonDown` de `r2`; soltar abaixo de 0,5 gera `buttonUp`. |
| RF-07 | 🟡 O sistema deve emitir `touchChanged` com posição normalizada (-1,0 a 1,0 nos dois eixos) e estado de toque para até dois dedos no touchpad. | Must | 🟡 Deslizar um dedo da esquerda para a direita gera eventos com X crescente e estado `touching`; tirar o dedo gera estado `ended`. |
| RF-08 | 🟡 O sistema deve manter um único controle ativo, o primeiro DualSense conectado, e ignorar os demais até o ativo se desconectar. | Must | 🟡 Com dois DualSense conectados, só os eventos do primeiro chegam aos consumidores; ao desconectá-lo, o segundo passa a ser o ativo. |
| RF-09 | 🟡 O sistema deve desativar os gestos do sistema associados a botões do controle (como o botão PS abrindo o Launchpad) enquanto o modo de condução estiver ativo, quando o macOS permitir. | Should | 🟡 Com o modo ativo, pressionar PS não abre o Launchpad nem a sobreposição de jogos. |
| RF-10 | 🟡 O sistema deve expor o nível de bateria e o estado de carga do controle ativo, quando disponíveis. | Could | 🟡 Com o controle por Bluetooth, o `app-shell` consegue exibir a porcentagem de bateria. |
| RF-11 | 🟡 O sistema deve oferecer aos consumidores o acionamento de vibração curta e da cor da barra de luz do controle. | Could | 🟡 Uma chamada de feedback faz o controle vibrar por até 100 ms. |

### 6.2 Fluxo Principal (Happy Path)

1. 🟡 O usuário liga o DualSense já pareado por Bluetooth com o app em execução.
2. 🟡 O sistema recebe a notificação de conexão do framework, marca o controle como ativo e emite `controllerConnected`.
3. 🟡 O sistema registra os manipuladores de mudança de valor de todos os elementos e ativa o recebimento de eventos em segundo plano.
4. 🟡 O usuário pressiona ✕ com o Terminal em foco.
5. 🟡 O sistema emite `buttonDown(cross)` e, ao soltar, `buttonUp(cross)`, com carimbo de tempo monotônico.
6. 🟡 O usuário desliga o controle.
7. 🟡 O sistema emite `controllerDisconnected` e deixa de ter controle ativo.

### 6.3 Fluxos Alternativos

**Fluxo Alternativo A: controle conectado antes de abrir o app**
1. 🟡 Ao iniciar, o sistema consulta os controles já conectados.
2. 🟡 Se houver um DualSense, o sistema o torna ativo e emite `controllerConnected` sem esperar uma nova conexão.

**Fluxo Alternativo B: troca de USB para Bluetooth**
1. 🟡 O usuário desconecta o cabo com o controle ligado.
2. 🟡 O sistema emite `controllerDisconnected` e, se o controle reaparecer por Bluetooth, emite um novo `controllerConnected` com tipo `bluetooth`.

---

## 7. Requisitos Não-Funcionais

| ID | Requisito | Valor alvo | Observação |
|----|-----------|-----------|------------|
| RNF-01 | 🟡 Performance | 🟡 p95 ≤ 5 ms do evento do framework até a entrega | 🟡 Medido por carimbos de tempo no log de depuração. |
| RNF-02 | 🟡 Consumo de CPU | 🟡 ≤ 2% de um núcleo com o controle parado | 🟡 Medido no Monitor de Atividade por 60 s. |
| RNF-03 | 🟡 Compatibilidade | 🟡 macOS 13 ou superior | 🟡 O suporte a DualSense no GameController existe desde o macOS 11.3; o piso vem de `app-shell` (OQ-02). |
| RNF-04 | 🟡 Robustez | 🟡 Zero travamentos em 100 ciclos de conectar e desconectar | 🟡 Teste manual com script de contagem no log. |

---

## 8. Design e Interface

**Componentes afetados:** 🟡 Nenhuma tela. Interface interna de eventos consumida pelos demais componentes.

**Comportamento esperado:**
🟡 O componente publica um fluxo único de eventos tipados, na ordem em que ocorreram: `controllerConnected`, `controllerDisconnected`, `buttonDown`, `buttonUp`, `axisChanged`, `triggerChanged`, `touchChanged`. Cada evento carrega carimbo de tempo monotônico. Os identificadores de botão são estáveis e em inglês (`cross`, `circle`, `square`, `triangle`, `l1`, `r1`, `l2`, `r2`, `l3`, `r3`, `options`, `create`, `ps`, `touchpadClick`, `dpadUp`, `dpadDown`, `dpadLeft`, `dpadRight`), usados sem alteração no arquivo de configuração de `action-mapping`.

**Estados da UI:**
- Estado vazio: 🟡 sem controle ativo; nenhum evento de entrada é emitido.
- Estado de carregamento: 🟡 não se aplica; a conexão é assíncrona e sinalizada por evento.
- Estado de erro: 🟡 falha ao registrar manipuladores gera o evento `controllerError` com descrição, exibido pelo `app-shell`.
- Estado de sucesso: 🟡 controle ativo e eventos fluindo.

---

## 9. Modelo de Dados

**Entidades novas ou modificadas:**

```
ControllerInfo {
  id: String              // identificador estável da sessão de conexão
  name: String            // nome informado pelo sistema, ex.: "DualSense Wireless Controller"
  connection: Enum        // usb | bluetooth | unknown
  batteryLevel: Float?    // 0,0 a 1,0, quando disponível
}

InputEvent {
  kind: Enum              // buttonDown | buttonUp | axisChanged | triggerChanged | touchChanged | controllerConnected | controllerDisconnected | controllerError
  element: String?        // identificador do botão, eixo ou toque
  value: Float?           // valor normalizado, quando aplicável
  x: Float?               // touchpad ou analógico
  y: Float?
  touchIndex: Int?        // 0 ou 1
  timestamp: UInt64       // relógio monotônico em nanossegundos
}
```

**Migrações necessárias:** 🟡 Não. Nenhum dado persistido; a zona morta vem da configuração de `action-mapping`.

---

## 10. Integrações e Dependências

| Dependência | Tipo | Impacto se indisponível |
|-------------|------|------------------------|
| 🟡 Framework GameController do macOS | Obrigatória | 🟡 Sem ele não há leitura do controle; o `app-shell` exibe erro e o app fica ocioso. |
| 🟡 Controle DualSense | Obrigatória | 🟡 Sem controle ativo o sistema fica em estado vazio aguardando conexão. |
| 🟡 Permissão de Input Monitoring | Obrigatória, a confirmar (OQ-03) | 🟡 Se exigida e negada, os eventos em segundo plano não chegam; o `app-shell` orienta a concessão. |

---

## 11. Edge Cases e Tratamento de Erros

| Cenário | Trigger | Comportamento esperado |
|---------|---------|----------------------|
| EC-01: 🟡 Desconexão com botões pressionados | 🟡 Bateria acaba enquanto R2 está segurado | 🟡 O sistema emite `buttonUp` para todo botão ainda pressionado antes de `controllerDisconnected`, para que os consumidores soltem cliques, teclas e ditado. |
| EC-02: 🟡 Analógico com desvio em repouso | 🟡 Desgaste físico gera leitura de 0,08 parado | 🟡 A zona morta descarta valores abaixo do limite configurado e o sistema não emite movimento. |
| EC-03: 🟡 Segundo controle conectado | 🟡 Um DualSense e um controle Xbox ligados | 🟡 O controle não DualSense é ignorado e registrado no log; o ativo não muda. |
| EC-04: 🟡 Eventos em segundo plano não chegam | 🟡 Permissão ausente ou falha do framework | 🟡 O sistema detecta que nenhum evento chegou em 5 s com botão pressionado durante o teste de permissões e emite `controllerError` com orientação. |
| EC-05: 🟡 Reconexão rápida | 🟡 Bluetooth cai e volta em menos de 1 s | 🟡 O sistema emite desconexão e nova conexão em ordem, sem duplicar o controle ativo. |
| EC-06: 🟡 Gesto do sistema não pode ser desativado | 🟡 A versão do macOS ignora o pedido do RF-09 | 🟡 O sistema registra aviso no log e segue funcionando; o botão PS fica sem mapeamento padrão. |

---

## 12. Segurança e Privacidade

- **Autenticação:** 🟡 Não se aplica; app local de usuário único.
- **Autorização:** 🟡 Pode exigir a permissão de Input Monitoring (OQ-03), solicitada e verificada pelo `app-shell`.
- **Dados sensíveis:** 🟡 O componente não lê teclado nem mouse físicos; processa apenas a entrada do controle e não a persiste.
- **Auditoria:** 🟡 Log de depuração opcional com conexões e erros; eventos de botão só são registrados com o modo de depuração ligado.

---

## 13. Plano de Rollout

- **Estratégia:** 🟡 Entrega como prova de conceito isolada (app que só registra eventos no log) antes de conectar os demais componentes, validando a premissa 2 do `ideation.md`.
- **Como reverter (rollback):** 🟡 Reinstalar a versão anterior do `.app` a partir da tag git correspondente.
- **Monitoramento pós-deploy:** 🟡 Nas primeiras sessões, conferir no log a taxa de desconexões inesperadas e a latência p95.

---

## 14. Open Questions

| # | Pergunta | Impacto | Dono | Prazo |
|---|---------|---------|------|-------|
| OQ-01 | 🟡 O botão de mudo do microfone do DualSense é exposto pelo GameController? Se não, vale ler via HID? | Baixo | iago | fim da prova de conceito |
| OQ-02 | 🟡 Versão mínima do macOS: 13 atende todos os componentes? | Baixo | iago | antes do plano |
| OQ-03 | 🟡 A recepção de eventos em segundo plano exige Input Monitoring ou só a opção do framework? | Médio | iago | fim da prova de conceito |

---

## 15. Decisões Tomadas (Decision Log)

| Decisão | Alternativas consideradas | Racional |
|---------|--------------------------|---------|
| 🟡 Usar o framework GameController | 🟡 IOKit HID direto; bibliotecas como SDL | 🟡 Suporte oficial ao DualSense com touchpad, menor atrito com permissões, alinhado à stack Swift nativa do PRD. |
| 🟡 Identificadores de botão em inglês e estáveis | 🟡 Nomes em português; símbolos PlayStation | 🟡 Evitam problemas de codificação no JSON e coincidem com a nomenclatura do framework. |
| 🟡 Um controle ativo por vez | 🟡 Vários controles simultâneos | 🟡 Persona trabalha sozinha; simplifica o estado e evita ações duplicadas. |

---

## Apêndice

### Referências
- 🟡 [`prd.md`](../prd.md), seções 4, 6, 8 e 9
- 🟡 [`ideation.md`](../ideation.md), premissa 2

### Histórico de Revisões
| Versão | Data | Autor | Mudanças |
|--------|------|-------|---------|
| 1.0 | 2026-09-14 | reversa-spec-sdd | Criação inicial |
| 1.1 | 2026-09-14 | reversa-spec-sdd | Corrigida a contagem de elementos do controle de 16/17 para 18. |

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
- 🟡 Open questions pendentes: 3 (seção 14)
- 🟡 Observação: o scorer é heurístico e verifica estrutura e vocabulário, não a correção técnica; as open questions de impacto alto continuam bloqueando o plano.

---
Gerado por reversa-spec-sdd em 2026-09-14T18:24:08Z
Fonte: prd.md
