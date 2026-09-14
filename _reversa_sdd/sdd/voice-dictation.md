# Spec: voice-dictation

**Versão:** 1.1
**Status:** Rascunho
**Autor:** reversa-spec-sdd
**Data:** 2026-09-14
**Reviewers:** iago

> Selo 🟡 PLANEJADO em todos os itens. Fonte primária: [`prd.md`](../prd.md).

---

## 1. Resumo

🟡 Componente que permite ditar prompts segurando um botão do DualSense: enquanto o botão está pressionado, o ditado do Raycast fica ativo, captando o áudio de preferência pelo microfone do próprio controle. O app não transcreve áudio; só aciona o Raycast e escolhe o microfone. Atende aos passos 3 e 7 da jornada.

---

## 2. Contexto e Motivação

**Problema:**
🟡 Prompts e briefs para agentes são texto livre, impossível de produzir com poucos botões. Sem voz, o programador de sofá precisa do teclado para o principal insumo da sessão.

**Evidências:**
🟡 Premissa 3 do `ideation.md`, reformulada pelo usuário: a transcrição do Raycast atende bem; falta usar o microfone do DualSense. Decisão do usuário: modo segurar para falar. Risco de impacto alto na seção 8 do PRD para o microfone via Bluetooth.

**Por que agora:**
🟡 Sem ditado, a meta de 10 h semanais só com o controle é inalcançável, porque todo prompt exigiria teclado.

---

## 3. Goals (Objetivos)

- [ ] 🟡 G-01: Ditar um prompt de até 60 s e vê-lo inserido no Claude Code segurando e soltando um único botão.
- [ ] 🟡 G-02: Iniciar a captação em até 300 ms após pressionar o botão.
- [ ] 🟡 G-03: Usar o microfone do DualSense sempre que o macOS o expuser, com troca automática para um microfone alternativo quando não expuser.

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
| RF-04 | 🟡 O sistema deve tornar o microfone do DualSense a entrada padrão do sistema quando ele ficar disponível e `dictation.preferControllerMic` for verdadeiro, guardando a entrada anterior. | Must | 🟡 Ao conectar o controle por USB, Ajustes > Som > Entrada passa a mostrar o DualSense. |
| RF-05 | 🟡 O sistema deve restaurar a entrada padrão anterior quando o microfone do controle deixar de existir, quando o modo de condução for desligado e quando o app for encerrado. | Must | 🟡 Desconectar o controle devolve a entrada ao microfone que estava ativo antes. |
| RF-06 | 🟡 O sistema deve manter a entrada padrão atual e informar "microfone do controle indisponível, usando nome do dispositivo" quando o DualSense não expuser microfone. | Must | 🟡 Com o controle só por Bluetooth e sem microfone exposto, o ditado usa o microfone do Mac e o menu mostra o aviso. |
| RF-07 | 🟡 O sistema deve sinalizar no controle o início e o fim do ditado com vibração curta e cor distinta da barra de luz, quando `controller-input` oferecer feedback. | Should | 🟡 Pressionar L2 faz o controle vibrar e a barra de luz mudar de cor até soltar. |
| RF-08 | 🟡 O sistema deve encerrar o ditado e soltar o atalho quando o controle desconectar, quando o modo for desligado ou quando o ditado passar de `dictation.maxDurationS` (padrão 120 s). | Must | 🟡 Segurar L2 por 121 s encerra o ditado sozinho e nenhuma tecla fica presa. |
| RF-09 | 🟡 O sistema deve informar ao `action-mapping` que o ditado está ativo, para suspender ações de teclado durante a captação. | Must | 🟡 Com L2 segurado, pressionar ✕ não envia Enter. |
| RF-10 | 🟡 O sistema deve ignorar pressionamentos de L2 com duração inferior a `dictation.minHoldMs` (padrão 150 ms), sem acionar o Raycast. | Should | 🟡 Um toque acidental de 80 ms em L2 não abre o ditado. |

### 6.2 Fluxo Principal (Happy Path)

1. 🟡 O usuário conecta o DualSense por USB; o sistema detecta o microfone e o torna entrada padrão, guardando a anterior.
2. 🟡 Com o Claude Code em foco, o usuário segura L2.
3. 🟡 Passados 150 ms, o sistema aciona o atalho do Raycast conforme o estilo configurado e sinaliza no controle.
4. 🟡 O usuário fala o prompt; o Raycast capta pelo microfone do controle.
5. 🟡 O usuário solta L2; o sistema encerra o ditado pelo atalho e sinaliza o fim.
6. 🟡 O Raycast insere o texto transcrito no campo em foco.
7. 🟡 O usuário pressiona ✕ e o prompt é enviado.

### 6.3 Fluxos Alternativos

**Fluxo Alternativo A: microfone do controle indisponível**
1. 🟡 O controle está conectado por Bluetooth e o macOS não expõe o microfone.
2. 🟡 O sistema mantém a entrada padrão, exibe o aviso e o ditado segue pelo microfone disponível.

**Fluxo Alternativo B: controle desconecta durante o ditado**
1. 🟡 A bateria acaba com L2 segurado.
2. 🟡 O sistema encerra o ditado pelo atalho, restaura a entrada padrão e libera as ações de teclado.

---

## 7. Requisitos Não-Funcionais

| ID | Requisito | Valor alvo | Observação |
|----|-----------|-----------|------------|
| RNF-01 | 🟡 Performance | 🟡 ≤ 300 ms do pressionar ao acionamento do Raycast, incluindo os 150 ms de `minHoldMs` | 🟡 Medido por carimbos de tempo no log. |
| RNF-02 | 🟡 Robustez | 🟡 Zero teclas presas em 50 ciclos de ditado com desconexões forçadas | 🟡 Teste manual. |
| RNF-03 | 🟡 Privacidade | 🟡 Nenhum byte de áudio lido pelo app | 🟡 O app só altera o dispositivo padrão; a captação é do Raycast. |
| RNF-04 | 🟡 Reversibilidade | 🟡 Entrada padrão original restaurada em 100% dos encerramentos normais | 🟡 Encerramento forçado coberto por EC-04. |

---

## 8. Design e Interface

**Componentes afetados:** 🟡 Dispositivo padrão de entrada de áudio do macOS; atalho global do Raycast; barra de luz e vibração do controle.

**Comportamento esperado:**
🟡 O usuário percebe o ditado como segurar para falar, independentemente de o Raycast operar em modo segurar ou alternar: o estilo `tapOnPressAndRelease` emula a semântica de segurar enviando o atalho duas vezes. A troca de microfone acontece na conexão do controle, não a cada ditado, para não atrasar o início da captação.

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
  preferControllerMic: Bool         // padrão true
  micNameContains: String           // padrão "DualSense"
  minHoldMs: Int                    // padrão 150
  maxDurationS: Int                 // padrão 120
}

AudioInputState {                   // em memória, não persistido
  previousDefaultInputUID: String?  // entrada padrão antes da troca
  controllerMicUID: String?         // microfone do DualSense, quando existir
}
```

**Migrações necessárias:** 🟡 Não.

---

## 10. Integrações e Dependências

| Dependência | Tipo | Impacto se indisponível |
|-------------|------|------------------------|
| 🟡 Raycast com ditado configurado | Obrigatória | 🟡 Sem Raycast ou sem atalho, o ditado fica indisponível e o menu exibe o motivo; as demais funções seguem. |
| 🟡 Core Audio (dispositivos de entrada) | Obrigatória | 🟡 Falha ao trocar a entrada mantém a entrada atual e registra aviso. |
| 🟡 Microfone do DualSense | Opcional | 🟡 Indisponível leva ao Fluxo Alternativo A. |
| 🟡 `action-mapping` | Obrigatória | 🟡 Entrega início e fim da ação e recebe o aviso de ditado ativo. |
| 🟡 `controller-input` (feedback e desconexão) | Obrigatória | 🟡 Sem feedback, o ditado funciona sem vibração e sem luz. |
| 🟡 Permissão de Acessibilidade | Obrigatória | 🟡 Sem ela, o atalho do Raycast não é injetado. |

---

## 11. Edge Cases e Tratamento de Erros

| Cenário | Trigger | Comportamento esperado |
|---------|---------|----------------------|
| EC-01: 🟡 Raycast fechado ou não instalado | 🟡 Atalho injetado sem Raycast em execução | 🟡 O sistema detecta a ausência do processo do Raycast antes de acionar, não injeta o atalho, vibra duas vezes e mostra "Raycast não está em execução". |
| EC-02: 🟡 Atalho não configurado | 🟡 `dictation.shortcut` ausente no JSON | 🟡 A ação de ditado é desativada e o menu orienta a configurar o atalho. |
| EC-03: 🟡 Microfone indisponível via Bluetooth | 🟡 Controle sem cabo | 🟡 Fluxo Alternativo A, com aviso persistente no menu enquanto durar. |
| EC-04: 🟡 App encerrado à força com a entrada trocada | 🟡 Travamento ou `kill -9` | 🟡 No próximo início, o sistema lê a entrada anterior salva em `~/.config/joystick-ai/state.json` e a restaura se o controle não estiver conectado. |
| EC-05: 🟡 Usuário trocou a entrada manualmente | 🟡 Escolhe outro microfone em Ajustes com o controle conectado | 🟡 O sistema respeita a escolha, não força a troca de novo até a próxima conexão do controle e não restaura a anterior na desconexão. |
| EC-06: 🟡 Duração máxima atingida | 🟡 L2 segurado por mais de 120 s | 🟡 Encerra o ditado, vibra e ignora o soltar posterior de L2. |
| EC-07: 🟡 Falha na troca de dispositivo de áudio | 🟡 Core Audio retorna erro | 🟡 Mantém a entrada atual, registra o código de erro e exibe aviso no menu. |

---

## 12. Segurança e Privacidade

- **Autenticação:** 🟡 Não se aplica.
- **Autorização:** 🟡 Exige Acessibilidade para injetar o atalho; não exige permissão de microfone, pois o app não capta áudio.
- **Dados sensíveis:** 🟡 A voz do usuário é processada pelo Raycast conforme a configuração dele; o app não acessa áudio nem o texto transcrito.
- **Auditoria:** 🟡 Log de depuração opcional com início, fim e duração do ditado, sem conteúdo.

---

## 13. Plano de Rollout

- **Estratégia:** 🟡 Antes de implementar, teste manual de 15 minutos: conectar o DualSense por USB e por Bluetooth e verificar se aparece em Ajustes > Som > Entrada, acionando o ditado do Raycast com ele. O resultado define se RF-04 e RF-05 entram no MVP ou se o controle só aciona o ditado.
- **Como reverter (rollback):** 🟡 Definir `preferControllerMic: false` no JSON ou reinstalar a versão anterior pela tag git.
- **Monitoramento pós-deploy:** 🟡 Na primeira semana, anotar falhas de ditado e casos em que a entrada padrão não foi restaurada.

---

## 14. Open Questions

| # | Pergunta | Impacto | Dono | Prazo |
|---|---------|---------|------|-------|
| OQ-01 | 🟡 Qual o atalho e o modo (segurar ou alternar) do ditado do Raycast usado hoje? Existe deeplink estável como alternativa ao atalho? | Alto | iago | antes do plano |
| OQ-02 | 🟡 O macOS expõe o microfone do DualSense por Bluetooth, ou só por USB? | Alto | iago | teste da seção 13 |
| OQ-03 | 🟡 O Raycast usa a entrada padrão do sistema ou tem seleção própria de microfone que ignora a troca? | Alto | iago | teste da seção 13 |

---

## 15. Decisões Tomadas (Decision Log)

| Decisão | Alternativas consideradas | Racional |
|---------|--------------------------|---------|
| 🟡 Segurar para falar | 🟡 Alternar; ambos | 🟡 Escolha do usuário; evita microfone esquecido ligado. |
| 🟡 Transcrição delegada ao Raycast | 🟡 Speech framework do macOS; Whisper local | 🟡 Não-objetivo do PRD; o usuário já considera a transcrição do Raycast satisfatória. |
| 🟡 Trocar o microfone na conexão do controle | 🟡 Trocar a cada ditado | 🟡 A troca a cada ditado atrasaria o início da captação e poderia não ser vista pelo Raycast a tempo. |
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
