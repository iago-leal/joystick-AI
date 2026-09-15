# Perguntas para Validação — joystick-AI

> Gerado pelo Revisor em 2026-09-15 · `answer_mode = chat`: as perguntas são feitas no chat e as respostas registradas aqui.

---

## Pergunta 1

**Contexto:** Lacuna L-01 (`domain.md` §8). O PRD e `sdd/voice-dictation.md` preveem ditado de prompts por botão; o código não tem componente de ditado, e R3 apenas envia ⌘M ao transcritor do Raycast (`ShortcutDefaults.swift`).
**Spec afetada:** [`_reversa_sdd/atalhos/requirements.md`] (RN-AT-21, MoSCoW), [`_reversa_sdd/atalhos/design.md`], [`_reversa_sdd/atalhos/tasks.md`], [`_reversa_sdd/user-stories/conduzir-agentes-pelo-controle.md`] (US-AG-04)
**Pergunta:** O componente de ditado próprio (`voice-dictation`) foi abandonado em favor do transcritor do Raycast em R3, ou continua planejado?
**Impacto:** Se abandonado, RN-AT-21 passa a 🟢 como decisão e `sdd/voice-dictation.md` fica marcada como superada. Se planejado, vira item Could/Should do *backlog* com a spec ativa.

✅ Respondida

**Resposta:** Superado pelo atalho R3. O atalho configurável R3 → ⌘M é a solução definitiva do ditado: RN-AT-21 passa a 🟢 como decisão, `sdd/voice-dictation.md` fica marcada como superada e o ADR-015 passa a Aceito. L-01 fechada em 2026-09-15.

---

## Pergunta 2

**Contexto:** Lacuna L-02, divergência DV-04. `ExtendedReportActivator.homePressed` e `onHomeButton` não identificam o dispositivo; o PS de um controle em fila age como PS do controle ativo.
**Spec afetada:** [`_reversa_sdd/entrada-do-controle/requirements.md`] (RN-EC-17), [`_reversa_sdd/entrada-do-controle/design.md`]
**Pergunta:** Com dois DualSense conectados, o PS do controle em fila abrir a paleta é comportamento aceito ou defeito a corrigir?
**Impacto:** Aceito: RN-EC-17 vira 🟢 como exceção documentada a RN-EC-02. Defeito: registra-se como débito com tarefa de correção.

✅ Respondida

**Resposta:** Aceito. RN-EC-17 passa a 🟢 como exceção documentada a RN-EC-02.

---

## Pergunta 3

**Contexto:** Lacuna L-02, divergência DV-05. "Copiar e gravar" chama `save(confirmBackup:)` sem reverificar `canSave`, e `ConfigWriter` não valida o documento.
**Spec afetada:** [`_reversa_sdd/configuracao/requirements.md`] (RN-CF-32), [`_reversa_sdd/editor/requirements.md`], [`_reversa_sdd/user-stories/personalizar-atalhos-e-paleta.md`] (US-PE-06)
**Pergunta:** A gravação com `.bak` deve reverificar o rascunho antes de gravar (defeito a corrigir) ou o comportamento atual é aceito?
**Impacto:** Defeito: tarefa de correção e regra "configuração inválida nunca é gravada". Aceito: RN-CF-32 vira 🟢 com o risco declarado.

✅ Respondida

**Resposta:** Defeito. Correção registrada em `configuracao/tasks.md` T-11 e `editor/tasks.md` T-10.

---

## Pergunta 4

**Contexto:** Lacuna L-02, divergência DV-06. Os atalhos de sistema são lidos de `AppleSymbolicHotKeys`; quando o atalho está desativado nas preferências, o app posta o acorde padrão.
**Spec afetada:** [`_reversa_sdd/atalhos/requirements.md`], [`_reversa_sdd/atalhos/design.md`], [`_reversa_sdd/user-stories/conduzir-agentes-pelo-controle.md`] (US-AG-05)
**Pergunta:** Com o atalho de sistema desativado no macOS, o botão deve postar o acorde padrão (como hoje), não fazer nada, ou avisar?
**Impacto:** Define a regra de desativação, hoje 🔴, e se há tarefa de correção.

✅ Respondida

**Resposta:** Postar o acorde padrão, como hoje. RN-AT-22 passa a 🟢.

---

## Pergunta 5

**Contexto:** Lacuna L-03. O PM-3 da `001-poc-entrada-ponteiro` segue parcial: `target-runs` está vazio, e faltam a latência de entrada ao movimento, a CPU em movimento e os 100 ciclos de conexão.
**Spec afetada:** [`_reversa_sdd/tela-de-alvos-e-analise/requirements.md`] (RN-TA-25), [`_reversa_sdd/tela-de-alvos-e-analise/tasks.md`], [`_reversa_sdd/user-stories/validar-a-poc.md`]
**Pergunta:** Essas medições ainda serão feitas, ou o portão de precisão e desempenho foi dispensado?
**Impacto:** Planejadas: RN-TA-25 fica como pendência Must com data. Dispensadas: a tela de alvos passa a ferramenta opcional, e o risco de precisão do PRD fica registrado como aceito sem número.

✅ Respondida

**Resposta:** Ainda serão feitas. RN-TA-25 passa a 🟢 como pendência planejada (TT-02 a TT-04).
