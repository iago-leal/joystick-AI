# Spec: voice-dictation

**Versão:** 1.3
**Status:** Rascunho
**Autor:** reversa-spec-sdd
**Data:** 2026-09-14
**Reviewers:** iago

> Selo 🟡 PLANEJADO nos itens sem outra marca; 🟢 CONFIRMADO nos fatos verificados no hardware pelos testes do microfone e do ditado de 2026-09-14 (seção 13). Fonte primária: [`prd.md`](../prd.md).

---

## 1. Resumo

🟡 Componente que permite ditar prompts segurando um botão do DualSense: enquanto o botão está pressionado, o ditado do Raycast fica ativo, captando o áudio de preferência pelo microfone do próprio controle. O app não transcreve áudio nem troca o microfone: aciona o Raycast, cuja lista de prioridade de microfones escolhe a entrada, e detecta se o controle expõe microfone. Atende aos passos 3 e 7 da jornada.

---

## 2. Contexto e Motivação

**Problema:**
🟡 Prompts e briefs para agentes são texto livre, impossível de produzir com poucos botões. Sem voz, o programador de sofá precisa do teclado para o principal insumo da sessão.

**Evidências:**
🟡 Premissa 3 do `ideation.md`, reformulada pelo usuário: a transcrição do Raycast atende bem; falta usar o microfone do DualSense. Decisão do usuário: modo segurar para falar. Risco de impacto alto na seção 8 do PRD para o microfone via Bluetooth.
🟢 Teste de 2026-09-14 no Mac do usuário: por Bluetooth, o controle negocia apenas o serviço `HID ACL` e não surge nenhum dispositivo de áudio; por USB, o macOS expõe a entrada "DualSense Wireless Controller" (Sony Interactive Entertainment, 2 canais, 48 kHz), listada também pelo AVFoundation, e uma saída de 4 canais. Uma captura de 5 s pela entrada USB registrou nível médio de −38,7 dBFS e pico de −18,8 dBFS, sem silêncio digital, com os dois canais idênticos (cápsula mono duplicada). A conexão do controle não altera a entrada padrão do sistema, que permaneceu no microfone do Mac.
🟢 Teste do ditado de 2026-09-14 (Raycast 2.4.1), com um monitor dos processos que capturam áudio pelo Core Audio: (1) com "Use System Default" ligado em Settings › Dictation › Microphone e a entrada padrão no microfone do Mac, o Raycast gravou do microfone do Mac; (2) com a mesma opção ligada e a entrada padrão trocada para o DualSense 5 s antes do ditado, com o Raycast já aberto, o Raycast **ignorou a troca** e gravou de novo do microfone do Mac; (3) com a opção desligada e o DualSense no topo da lista de prioridade, o Raycast gravou do DualSense, com a entrada padrão ainda no microfone do Mac, e transcreveu fielmente "Alô? Teste, teste. Testando no DualSense."; (4) com a mesma lista e o controle só por Bluetooth, o ditado funcionou, mas **sem o microfone do controle**: o Raycast recorreu sozinho ao Microfone (MacBook Pro), o primeiro disponível da lista, e foi ele que captou a voz. Em (4) o microfone do Mac era também a entrada padrão, de modo que o teste não distingue se a escolha veio da lista ou da entrada padrão; o resultado para o usuário é o mesmo.
🟢 Sonda HID do microfone por Bluetooth, 2026-09-14, em duas rodadas. A descrição HID do controle por Bluetooth declara, do controle para o host, apenas os relatórios de entrada `0x01` (10 bytes) e `0x31` (78 bytes); os relatórios grandes (`0x32` a `0x39`, até 547 bytes) são só de saída, do host para o controle. Uma sonda abriu o controle pelo `IOHIDManager`, como a PoC, e, com o usuário falando sem parar e o controle parado, percorreu quatro fases de 10 a 12 s sinalizadas pela barra de luz: referência sem comando de áudio; relatório de saída `0x31` com `mic_volume` no máximo (0x40) e microfone sem mudo; o mesmo com o microfone interno selecionado em `audio_control`; e microfone mudo, como controle. Em todas as fases chegaram só relatórios `0x31` de 78 bytes (cerca de 62 por segundo), sem nenhum relatório novo e sem byte que acompanhasse a fala. O controle aceitou os comandos: a barra de luz passou pelas quatro cores, o botão de mudo acendeu na última fase e o byte 55 do `0x31`, aparentemente o indicador de mudo, só variou nela. Conclusão: pelo caminho HID do macOS, o microfone do DualSense não envia áudio por Bluetooth. Fica não descartada, e sem registro público, a hipótese de um canal Bluetooth fora do HID usado só pelo PS5; mesmo que existisse, exigiria ainda um driver de microfone virtual para o Raycast gravar por ele. Fontes consultadas: a documentação do DS4Windows afirma que o fone e o microfone do controle só funcionam por USB; o sentido inverso, áudio háptico do host para o controle por Bluetooth, já foi decifrado por terceiros.

**Por que agora:**
🟡 Sem ditado, a meta de 10 h semanais só com o controle é inalcançável, porque todo prompt exigiria teclado.

---

## 3. Goals (Objetivos)

- [ ] 🟡 G-01: Ditar um prompt de até 60 s e vê-lo inserido no Claude Code segurando e soltando um único botão.
- [ ] 🟡 G-02: Iniciar a captação em até 300 ms após pressionar o botão.
- [ ] 🟡 G-03: Usar o microfone do DualSense sempre que o macOS o expuser, com retorno automático a um microfone alternativo quando não expuser, pela lista de prioridade do Raycast.

**Métricas de sucesso:**
| Métrica | Baseline atual | Target | Prazo |
|---------|---------------|--------|-------|
| 🟡 Prompts ditados pelo controle por sessão sem recorrer ao teclado | 🟡 0 | 🟡 100% dos prompts da sessão | 🟡 fim do MVP |
| 🟡 Tempo entre pressionar o botão e início da captação | 🟡 não medido | 🟡 ≤ 300 ms | 🟡 fim do MVP |

---

## 4. Non-Goals (Fora do Escopo)

- 🟡 NG-01: Transcrição própria de voz para texto; a transcrição é do Raycast.
- 🟡 NG-02: Comandos de voz que executam ações (por exemplo, dizer "abrir VS Code").
- 🟡 NG-03: Gravação, armazenamento ou envio de áudio pelo app.
- 🟡 NG-04: Integração com ferramentas de ditado diferentes do Raycast no MVP.
- 🟡 NG-05: Edição por voz do texto já inserido.

---

## 5. Usuários e Personas

**Usuário primário:** 🟡 Programador de sofá ditando briefs, prompts e ajustes para o Claude Code.
**Usuário secundário:** 🟡 Não há.

**Jornada atual (sem a feature):**
1. 🟡 O usuário pensa no prompt.
2. 🟡 Aciona o ditado do Raycast pelo atalho de teclado ou digita o texto.
3. 🟡 Em ambos os casos, o teclado é necessário.

**Jornada futura (com a feature):**
1. 🟡 O usuário segura L2 e fala o prompt no microfone do controle.
2. 🟡 Solta L2 e o texto transcrito aparece no campo em foco.
3. 🟡 Pressiona ✕ para enviar.

---

## 6. Requisitos Funcionais

### 6.1 Requisitos Principais

| ID | Requisito | Prioridade | Critério de Aceite |
|----|-----------|-----------|-------------------|
| RF-01 | 🟡 O sistema deve iniciar o ditado do Raycast quando receber o início da ação `dictation` e encerrá-lo quando receber o fim. | Must | 🟡 Segurar L2, falar "listar arquivos" e soltar insere "listar arquivos" no campo em foco. |
| RF-02 | 🟡 O sistema deve acionar o Raycast pelo atalho definido em `dictation.shortcut` e pelo estilo definido em `dictation.triggerStyle`: `holdShortcut` (tecla pressionada durante todo o ditado) ou `tapOnPressAndRelease` (um toque do atalho ao pressionar e outro ao soltar). | Must | 🟡 Com cada estilo configurado igual ao modo do Raycast, o ditado começa ao pressionar L2 e termina ao soltar. |
| RF-03 | 🟡 O sistema deve detectar o microfone do DualSense entre os dispositivos de entrada de áudio pelo nome configurado em `dictation.micNameContains` (padrão "DualSense"). | Must | 🟡 Com o controle por USB, o menu do `app-shell` mostra "Microfone: DualSense". |
| RF-04 | 🟡 O sistema não deve alterar a entrada padrão de áudio do macOS. A escolha do microfone do ditado cabe à lista de prioridade do Raycast, configurada uma vez pelo usuário: "Use System Default" desligado, DualSense no topo e o microfone do Mac logo abaixo. | Must | 🟡 Conectar e desconectar o controle, ligar e desligar o modo e encerrar o app não mudam Ajustes > Som > Entrada. |
| RF-05 | 🟡 O sistema deve ler as preferências de microfone do Raycast (`RaycastDictationUseSystemDefaultInput` e `RaycastDictationInputDevicePriorityOrder` no domínio `com.raycast.macos`) e, quando "Use System Default" estiver ligado ou o DualSense não estiver no topo da lista, mostrar no menu "Raycast não prioriza o microfone do controle: ajuste em Settings › Dictation › Microphone". | Should | 🟡 Com "Use System Default" ligado, o menu mostra o aviso; ao desligá-lo e pôr o DualSense no topo, o aviso some em até 2 s. |
| RF-06 | 🟡 O sistema deve informar "microfone do controle indisponível" quando o DualSense não expuser microfone, sem intervir na escolha do Raycast. | Must | 🟢 Com o controle só por Bluetooth, o Raycast grava pelo próximo microfone disponível da sua lista (teste de 2026-09-14). 🟡 O menu mostra o aviso. |
| RF-07 | 🟡 O sistema deve sinalizar no controle o início e o fim do ditado com vibração curta e cor distinta da barra de luz, quando `controller-input` oferecer feedback. | Should | 🟡 Pressionar L2 faz o controle vibrar e a barra de luz mudar de cor até soltar. |
| RF-08 | 🟡 O sistema deve encerrar o ditado e soltar o atalho quando o controle desconectar, quando o modo for desligado ou quando o ditado passar de `dictation.maxDurationS` (padrão 120 s). | Must | 🟡 Segurar L2 por 121 s encerra o ditado sozinho e nenhuma tecla fica presa. |
| RF-09 | 🟡 O sistema deve informar ao `action-mapping` que o ditado está ativo, para suspender ações de teclado durante a captação. | Must | 🟡 Com L2 segurado, pressionar ✕ não envia Enter. |
| RF-10 | 🟡 O sistema deve ignorar pressionamentos de L2 com duração inferior a `dictation.minHoldMs` (padrão 150 ms), sem acionar o Raycast. | Should | 🟡 Um toque acidental de 80 ms em L2 não abre o ditado. |

### 6.2 Fluxo Principal (Happy Path)

1. 🟡 O usuário conecta o DualSense por USB; o sistema detecta o microfone e mostra "Microfone: DualSense" no menu. 🟢 Com o DualSense no topo da lista de prioridade do Raycast, o ditado passa a captar por ele sem nenhuma troca de entrada padrão.
2. 🟡 Com o Claude Code em foco, o usuário segura L2.
3. 🟡 Passados 150 ms, o sistema aciona o atalho do Raycast conforme o estilo configurado e sinaliza no controle.
4. 🟡 O usuário fala o prompt; o Raycast capta pelo microfone do controle.
5. 🟡 O usuário solta L2; o sistema encerra o ditado pelo atalho e sinaliza o fim.
6. 🟡 O Raycast insere o texto transcrito no campo em foco.
7. 🟡 O usuário pressiona ✕ e o prompt é enviado.

### 6.3 Fluxos Alternativos

**Fluxo Alternativo A: microfone do controle indisponível**
1. 🟢 O controle está conectado só por Bluetooth, e o macOS não expõe o microfone (confirmado no teste de 2026-09-14).
2. 🟡 O sistema exibe o aviso. 🟢 O Raycast recorre ao próximo microfone disponível da sua lista, no teste o Microfone (MacBook Pro), e a voz passa a ser captada por esse microfone, não pelo controle.

**Fluxo Alternativo B: controle desconecta durante o ditado**
1. 🟡 A bateria acaba com L2 segurado.
2. 🟡 O sistema encerra o ditado pelo atalho e libera as ações de teclado.

---

## 7. Requisitos Não-Funcionais

| ID | Requisito | Valor alvo | Observação |
|----|-----------|-----------|------------|
| RNF-01 | 🟡 Performance | 🟡 ≤ 300 ms do pressionar ao acionamento do Raycast, incluindo os 150 ms de `minHoldMs` | 🟡 Medido por carimbos de tempo no log. |
| RNF-02 | 🟡 Robustez | 🟡 Zero teclas presas em 50 ciclos de ditado com desconexões forçadas | 🟡 Teste manual. |
| RNF-03 | 🟡 Privacidade | 🟡 Nenhum byte de áudio lido pelo app | 🟡 O app só lê a lista de dispositivos de entrada e as preferências do Raycast; a captação é do Raycast. |
| RNF-04 | 🟡 Não interferência | 🟡 Entrada padrão de áudio do macOS inalterada em 100% das sessões, inclusive em encerramentos forçados | 🟡 Sem troca de dispositivo, não há estado a restaurar. |

---

## 8. Design e Interface

**Componentes afetados:** 🟡 Lista de dispositivos de entrada de áudio do macOS e preferências de microfone do Raycast, ambas só em leitura; atalho global do Raycast; barra de luz e vibração do controle.

**Comportamento esperado:**
🟡 O usuário percebe o ditado como segurar para falar, independentemente de o Raycast operar em modo segurar ou alternar: o estilo `tapOnPressAndRelease` emula a semântica de segurar enviando o atalho duas vezes. O app não troca microfone: o Raycast já capta pelo primeiro disponível da sua lista, o que não acrescenta atraso ao início do ditado.

**Estados da UI:**
- Estado vazio: 🟡 sem controle ativo, a ação de ditado não é acionável.
- Estado de carregamento: 🟡 entre pressionar L2 e completar `minHoldMs`, nada é acionado.
- Estado de erro: 🟡 atalho não configurado ou falha de injeção exibe no menu "Ditado indisponível: motivo" e o controle vibra duas vezes.
- Estado de sucesso: 🟡 barra de luz na cor de ditado enquanto L2 estiver segurado.

---

## 9. Modelo de Dados

**Entidades novas ou modificadas:**

```
DictationSettings {                 // seção "dictation" do arquivo de configuração
  shortcut: Keystroke               // atalho do ditado configurado no Raycast; sem padrão, ver OQ-01
  triggerStyle: Enum                // holdShortcut | tapOnPressAndRelease; padrão tapOnPressAndRelease
  micNameContains: String           // padrão "DualSense"
  minHoldMs: Int                    // padrão 150
  maxDurationS: Int                 // padrão 120
}

AudioInputState {                   // em memória, não persistido
  controllerMicUID: String?         // microfone do DualSense, quando existir
  raycastPrioritizesController: Bool?  // RF-05; nil quando as preferências do Raycast não puderem ser lidas
}
```

**Migrações necessárias:** 🟡 Não.

---

## 10. Integrações e Dependências

| Dependência | Tipo | Impacto se indisponível |
|-------------|------|------------------------|
| 🟡 Raycast com ditado configurado | Obrigatória | 🟡 Sem Raycast ou sem atalho, o ditado fica indisponível e o menu exibe o motivo; as demais funções seguem. |
| 🟡 Core Audio (lista de dispositivos de entrada, só leitura) | Obrigatória | 🟡 Falha na leitura deixa o microfone como "desconhecido" no menu e registra aviso; o ditado segue. |
| 🟡 Preferências de microfone do Raycast | Opcional | 🟢 Chaves internas observadas no Raycast 2.4.1. 🟡 Ausentes ou renomeadas numa versão futura, o aviso de RF-05 não é exibido e o log registra a falha de leitura. |
| 🟡 Microfone do DualSense | Opcional | 🟢 Exposto só por USB, como entrada "DualSense Wireless Controller", nome que casa com o padrão de `micNameContains`; por Bluetooth fica indisponível. O Raycast só o usa se ele estiver no topo da própria lista. 🟡 Indisponível leva ao Fluxo Alternativo A. |
| 🟡 `action-mapping` | Obrigatória | 🟡 Entrega início e fim da ação e recebe o aviso de ditado ativo. |
| 🟡 `controller-input` (feedback e desconexão) | Obrigatória | 🟡 Sem feedback, o ditado funciona sem vibração e sem luz. |
| 🟡 Permissão de Acessibilidade | Obrigatória | 🟡 Sem ela, o atalho do Raycast não é injetado. |

---

## 11. Edge Cases e Tratamento de Erros

| Cenário | Trigger | Comportamento esperado |
|---------|---------|----------------------|
| EC-01: 🟡 Raycast fechado ou não instalado | 🟡 Atalho injetado sem Raycast em execução | 🟡 O sistema detecta a ausência do processo do Raycast antes de acionar, não injeta o atalho, vibra duas vezes e mostra "Raycast não está em execução". |
| EC-02: 🟡 Atalho não configurado | 🟡 `dictation.shortcut` ausente no JSON | 🟡 A ação de ditado é desativada e o menu orienta a configurar o atalho. |
| EC-03: 🟢 Microfone indisponível via Bluetooth | 🟢 Controle sem cabo | 🟡 Fluxo Alternativo A, com aviso persistente no menu enquanto durar. |
| EC-04: 🟡 App encerrado à força durante o ditado | 🟡 Travamento ou `kill -9` com L2 segurado | 🟡 Nenhuma entrada de áudio a restaurar desde a versão 1.3; o risco residual é o atalho do Raycast preso, coberto pelo `app-shell`. |
| EC-05: 🟡 Usuário trocou o microfone manualmente | 🟡 Muda a entrada em Ajustes ou a ordem da lista no Raycast | 🟡 O sistema não reage à entrada padrão; se a lista do Raycast deixar de ter o DualSense no topo, exibe o aviso de RF-05. |
| EC-06: 🟡 Duração máxima atingida | 🟡 L2 segurado por mais de 120 s | 🟡 Encerra o ditado, vibra e ignora o soltar posterior de L2. |
| EC-07: 🟡 Falha na leitura de dispositivos ou das preferências do Raycast | 🟡 Core Audio retorna erro ou as chaves do Raycast não existem | 🟡 Registra o código de erro, mostra o microfone como "desconhecido" e omite o aviso de RF-05; o ditado segue. |

---

## 12. Segurança e Privacidade

- **Autenticação:** 🟡 Não se aplica.
- **Autorização:** 🟡 Exige Acessibilidade para injetar o atalho; não exige permissão de microfone, pois o app não capta áudio.
- **Dados sensíveis:** 🟡 A voz do usuário é processada pelo Raycast conforme a configuração dele; o app não acessa áudio nem o texto transcrito.
- **Auditoria:** 🟡 Log de depuração opcional com início, fim e duração do ditado, sem conteúdo.

---

## 13. Plano de Rollout

- **Estratégia:** 🟡 Antes de implementar, teste manual de 15 minutos: conectar o DualSense por USB e por Bluetooth e verificar se aparece em Ajustes > Som > Entrada, acionando o ditado do Raycast com ele. O resultado define se RF-04 e RF-05 entram no MVP ou se o controle só aciona o ditado. 🟢 Concluído em 2026-09-14: a exposição do microfone foi verificada por USB (disponível e captando) e por Bluetooth (indisponível), respondendo OQ-02, e o ditado do Raycast foi acionado com o microfone do controle, com e sem cabo, respondendo OQ-03 (seção 2, Evidências). 🟡 Decisão resultante: RF-04 e RF-05 deixam de trocar a entrada padrão; o microfone passa a ser escolhido pela lista de prioridade do Raycast.
- **Como reverter (rollback):** 🟡 Ligar "Use System Default" no Raycast, ou reinstalar a versão anterior pela tag git.
- **Monitoramento pós-deploy:** 🟡 Na primeira semana, anotar falhas de ditado e casos em que o Raycast não captou pelo microfone esperado.

---

## 14. Open Questions

| # | Pergunta | Impacto | Dono | Prazo |
|---|---------|---------|------|-------|
| OQ-01 | 🟡 Qual o atalho e o modo (segurar ou alternar) do ditado do Raycast usado hoje? Existe deeplink estável como alternativa ao atalho? | Alto | iago | antes do plano |
| OQ-02 | 🟢 O macOS expõe o microfone do DualSense por Bluetooth, ou só por USB? **Respondida: só por USB**, com captação de sinal real; por Bluetooth não há dispositivo de áudio, e a sonda HID confirmou que o controle não envia áudio nem com o microfone ligado por comando (seção 2, Evidências). | Alto | iago | respondida em 2026-09-14 |
| OQ-03 | 🟢 O Raycast usa a entrada padrão do sistema ou tem seleção própria de microfone que ignora a troca? **Respondida: tem seleção própria.** Com "Use System Default" ligado, ignorou a troca da entrada padrão feita com o Raycast aberto; com a opção desligada, segue a lista de prioridade e recorre ao próximo microfone disponível sem o cabo (seção 2, Evidências). | Alto | iago | respondida em 2026-09-14 |

---

## 15. Decisões Tomadas (Decision Log)

| Decisão | Alternativas consideradas | Racional |
|---------|--------------------------|---------|
| 🟡 Segurar para falar | 🟡 Alternar; ambos | 🟡 Escolha do usuário; evita microfone esquecido ligado. |
| 🟡 Transcrição delegada ao Raycast | 🟡 Speech framework do macOS; Whisper local | 🟡 Não-objetivo do PRD; o usuário já considera a transcrição do Raycast satisfatória. |
| 🟡 ~~Trocar o microfone na conexão do controle~~ (substituída na versão 1.3) | 🟡 Trocar a cada ditado | 🟡 A troca a cada ditado atrasaria o início da captação e poderia não ser vista pelo Raycast a tempo. |
| 🟡 Delegar a escolha do microfone à lista de prioridade do Raycast (versão 1.3) | 🟡 Trocar a entrada padrão do sistema na conexão (decisão anterior); escrever nas preferências do Raycast | 🟢 No teste de 2026-09-14, o Raycast ignorou a troca da entrada padrão e, com a lista própria, captou pelo DualSense e recorreu ao Mac sem o cabo. 🟡 Escrever em preferências internas de outro app com ele aberto é frágil; o app só as lê para avisar (RF-05). |
| 🟡 Não buscar o microfone do DualSense por Bluetooth (versão 1.3) | 🟡 Canal Bluetooth fora do HID com driver de microfone virtual; cabo USB-C longo; fone Bluetooth na lista do Raycast | 🟢 A sonda HID não recebeu áudio com o microfone ligado por comando, e não há registro público de outro canal. 🟡 Sem cabo, o ditado usa o próximo microfone da lista do Raycast; para uso no sofá, cabo longo ou fone Bluetooth. |
| 🟡 L2 segurado como botão de ditado | 🟡 R1; △; clique do analógico | 🟡 Escolha do usuário. O gatilho deixa os polegares livres para apontar e rolar enquanto fala; conta como pressionado a partir de metade do curso (`controller-input`, RF-06), e o `minHoldMs` descarta toques acidentais. |

---

## Apêndice

### Referências
- 🟡 [`prd.md`](../prd.md), seções 4, 7 e 8
- 🟡 [`ideation.md`](../ideation.md), premissa 3
- 🟡 [`action-mapping.md`](./action-mapping.md), [`controller-input.md`](./controller-input.md)

### Histórico de Revisões
| Versão | Data | Autor | Mudanças |
|--------|------|-------|---------|
| 1.0 | 2026-09-14 | reversa-spec-sdd | Criação inicial |
| 1.1 | 2026-09-14 | reversa-spec-sdd | Ditado passa para L2 segurado; clique direito passa para R1 (pedido do usuário). |
| 1.2 | 2026-09-14 | iago | Registro do teste do microfone: exposto e captando por USB, indisponível por Bluetooth; OQ-02 respondida. |
| 1.3 | 2026-09-14 | iago | Registro do teste do ditado: o Raycast escolhe o microfone pela própria lista de prioridade e ignora a troca da entrada padrão; OQ-03 respondida; RF-04, RF-05, RF-06, fluxos, RNF-03, RNF-04, modelo de dados, dependências e EC-04, EC-05 e EC-07 reescritos para o app não trocar a entrada padrão; `preferControllerMic` removido. Registro da sonda HID por Bluetooth, com resultado negativo, e da decisão de não buscar o microfone do controle sem cabo. |

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
- 🟡 Open questions pendentes: 1 (seção 14, OQ-01; OQ-02 e OQ-03 respondidas em 2026-09-14)
- 🟡 Nota: a versão 1.3 alterou requisitos após esta avaliação, que não foi refeita.
- 🟡 Observação: o scorer é heurístico e verifica estrutura e vocabulário, não a correção técnica; as open questions de impacto alto continuam bloqueando o plano.

---
Gerado por reversa-spec-sdd em 2026-09-14T18:24:08Z
Fonte: prd.md
