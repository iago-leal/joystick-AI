# Relatório de Confiança — joystick-AI

> Gerado pelo Revisor em 2026-09-15 · `doc_level = completo` · Contagem de marcadores nas pastas de unit e em `user-stories/`, sem as linhas de legenda da escala e os títulos de seção.

---

## Resumo Geral

| Nível | Quantidade | Percentual |
|-------|-----------|------------|
| 🟢 CONFIRMADO | 802 | 95,0% |
| 🟡 INFERIDO   | 42 | 5,0% |
| 🔴 LACUNA     | 0 | 0,0% |
| **Total**     | 844 | 100% |

**Confiança geral:** 97,5% (soma de 🟢 + metade dos 🟡)

---

## Por Spec

| Spec | 🟢 | 🟡 | 🔴 | Confiança |
|------|----|----|-----|-----------|
| `aplicativo/` | 73 | 5 | 0 | 97% |
| `entrada-do-controle/` | 75 | 3 | 0 | 98% |
| `ponteiro/` | 80 | 2 | 0 | 99% |
| `injecao-de-eventos/` | 52 | 5 | 0 | 96% |
| `atalhos/` | 73 | 4 | 0 | 97% |
| `paleta/` | 60 | 7 | 0 | 95% |
| `configuracao/` | 95 | 3 | 0 | 98% |
| `editor/` | 105 | 3 | 0 | 99% |
| `log-de-diagnostico/` | 55 | 6 | 0 | 95% |
| `tela-de-alvos-e-analise/` | 85 | 3 | 0 | 98% |
| `user-stories/` | 49 | 1 | 0 | 99% |

Os 🟡 restantes são, em sua maioria, riscos de execução deduzidos do código (condições de corrida, comportamento com várias telas, cache do `cfprefsd`, perda de linhas em queda abrupta), que só uma execução instrumentada confirmaria.

---

## Lacunas Pendentes 🔴

Nenhuma. A última, L-01 (destino do ditado de prompts), foi fechada em 2026-09-15: o atalho R3 → ⌘M do Raycast substitui o componente próprio (`questions.md#pergunta-1`).

---

## Recomendações

- [x] `atalhos` — L-01 decidida em 2026-09-15; `sdd/voice-dictation.md` marcada como superada.
- [ ] `configuracao` e `editor` — corrigir DV-05 (T-11 e T-10): nenhuma gravação deve aceitar documento inválido, nem após "Copiar e gravar".
- [ ] `tela-de-alvos-e-analise` — executar TT-02 a TT-04 para fechar o PM-3 da 001; o risco de precisão do PRD segue sem número.
- [ ] `paleta` — DV-07 (fechamentos sem `palette.closed`) segue 🟡; convém decidir se a abertura do editor pela paleta deve registrar fechamento.
- [ ] `log-de-diagnostico` — a falta de rotação dos arquivos está confirmada; convém decidir retenção.

---

## Validação das Matrizes

- `traceability/code-spec-matrix.md`: 100 arquivos de produção e 29 de teste, todos mapeados a uma unit, conferidos contra `find Sources scripts Resources`; 253 `@Test` conferidos por arquivo. 🟢
- `traceability/spec-impact-matrix.md`: contratos e dependências coerentes com as units; nenhuma correção necessária. 🟢
- Referências cruzadas: 316 identificadores RN/RF definidos; nenhuma referência, inclusive em intervalos "RN-xx-nn a RN-xx-mm", aponta para identificador inexistente. 🟢

---

## Revisão Cruzada

- Engine externa consultada: nenhuma (plugin do Codex indisponível nesta sessão)

---

## Histórico de Reclassificações

| De | Para | Afirmação | Evidência |
|----|------|-----------|-----------|
| 🟡 | 🟢 | RN-LG-13: sem rotação nem limpeza de logs | Nenhum `removeItem`/`contentsOfDirectory` em `Log/` |
| 🟡 | 🟢 | Sem retenção, `~/Library/Logs/joystick-ai` cresce indefinidamente (`log-de-diagnostico/design.md`) | Idem |
| 🟡 | 🟢 | `clickState` sem teto | `ClickStateMachine.swift:83-88` |
| 🟡 | 🟢 | RN-IN-17: contagem de modificadores muda com a injeção desligada | `KeyboardInjector.swift:41-44`, `:96-97` |
| 🟡 | 🟢 | `.bak` sobrescrito a cada gravação | `ConfigWriter.swift:41-43` |
| 🟡 | 🟢 | `EditorDraft.restoreDefaults` não usado pelo app | `EditorDraft.swift:220`; `EditorViewModel.swift:187` |
| 🟡 | 🟢 | `runs` ordena `startedAt` como texto | `RunsReport.swift:10` |
| 🟡 | 🟢 | `timeToClickMs` trunca, `meanTimeMs` arredonda | `TargetSession.swift:88`, `TargetRun.swift:115` |
| 🟡 | 🟢 | Erros de `--seed`/`--scroll-unit` sem `--targets` não são registrados | `AppDelegate.swift:136-150`, `LaunchArguments.swift:102-108` |
| 🟡 | 🟢 | A tela de alvos só mede cliques esquerdos | `TargetSession.swift:51`, `:72` |
| 🟡 | 🟢 | RN-EC-17: PS de controle em fila age como PS do ativo | Usuário: comportamento aceito (Pergunta 2) |
| 🟡 | 🟢 | RN-CF-32: gravação não reverifica o documento | Usuário: defeito a corrigir (Pergunta 3) |
| 🔴 | 🟢 | RN-ED-23: "Copiar e gravar" ignora `canSave` | Usuário: defeito a corrigir (Pergunta 3) |
| 🔴 | 🟢 | RN-AT-22: atalho de sistema desativado posta o padrão | Usuário: comportamento aceito (Pergunta 4) |
| 🔴 | 🟢 | RN-TA-25: medições do PM-3 pendentes | Usuário: continuam planejadas (Pergunta 5) |
| 🔴 | 🟢 | RN-AT-21: ditado de prompts sem componente próprio | Usuário: superado pelo atalho R3 → ⌘M (Pergunta 1) |

Além das 16 afirmações principais, os marcadores que as repetiam em `design.md`, `tasks.md` e `user-stories/` foram atualizados na mesma direção.
