# Plano de Exploração — joystick-AI

> Criado pelo Reversa em 2026-09-14
> Ajustado e aprovado em 2026-09-15: sem matriz RBAC, ERD, OpenAPI nem Data Master (app local sem servidor, usuários ou banco); Visor, Design System e Tracer opcionais.
> Marque cada tarefa com ✅ quando concluída.
> Você pode editar este plano antes de iniciar: adicione, remova ou reordene tarefas conforme necessário.

---

## Fase 1: Reconhecimento 🔍

- [x] ✅ **Scout** — Mapeamento de estrutura de pastas e tecnologias
- [x] ✅ **Scout** — Análise de dependências e gerenciadores de pacotes
- [x] ✅ **Scout** — Identificação de entry points, CI/CD e configurações

## Decisão de organização das specs 🗂️ ✅ (por módulo, decidida em 2026-09-14)

> Entre o Scout e o Arqueólogo, o Reversa pergunta como você quer organizar as specs (por módulo, caso de uso, endpoint, híbrida, por features ou customizada). A escolha fica persistida em `.reversa/config.toml` na seção `[specs]` e não será reperguntada em execuções futuras. Para reapresentar o menu, remova manualmente a seção.

## Fase 2: Escavação 🏗️

> Módulos preenchidos pelo Reversa após o Scout (2026-09-15), organização por módulo.

- [x] ✅ **Arqueólogo** — Análise do módulo `app-shell` (ciclo de vida, permissões, assinatura, menus e argumentos de abertura)
- [x] ✅ **Arqueólogo** — Análise do módulo `controller-input` (leitura do DualSense por GameController e IOKit HID)
- [x] ✅ **Arqueólogo** — Análise do módulo `pointer` (cinemática, cliques, touchpad, rolagem e telas)
- [x] ✅ **Arqueólogo** — Análise do módulo `injection` (injeção de mouse, teclado e rolagem por CGEvent)
- [x] ✅ **Arqueólogo** — Análise do módulo `shortcuts` (catálogo de teclas, camadas e repetição)
- [x] ✅ **Arqueólogo** — Análise do módulo `palette` (máquina de estados, painel e ações da paleta)
- [x] ✅ **Arqueólogo** — Análise do módulo `config` (modelo, carga, validação, observação e gravação do config.json)
- [x] ✅ **Arqueólogo** — Análise do módulo `editor` (janela SwiftUI do editor e rascunho)
- [x] ✅ **Arqueólogo** — Análise do módulo `diagnostics-log` (catálogo de eventos e log JSONL)
- [x] ✅ **Arqueólogo** — Análise do módulo `targets-analysis` (tela de alvos, análise e poc-tools)

## Fase 3: Interpretação 🧠

- [x] ✅ **Detetive** — Arqueologia Git e ADRs retroativos
- [x] ✅ **Detetive** — Regras de negócio implícitas e máquinas de estado (inclui a permissão de Acessibilidade do macOS)
- [x] ✅ **Arquiteto** — Diagramas C4 (Contexto, Containers, Componentes)
- [x] ✅ **Arquiteto** — Integrações externas e modelo de dados em arquivo (`config.json`, log JSONL, argumentos de abertura)
- [x] ✅ **Arquiteto** — Spec Impact Matrix

## Fase 4: Geração 📝

- [x] ✅ **Redator** — Specs SDD por componente
- [x] ✅ **Redator** — User Stories (se aplicável)
- [x] ✅ **Redator** — Code/Spec Matrix

## Fase 5: Revisão ✅

- [x] ✅ **Revisor** — Revisão cruzada de specs
- [x] ✅ **Revisor** — Resolução de lacunas com o usuário
- [x] ✅ **Revisor** — Relatório de confiança final

---

## Agentes Independentes

> Execute estes agentes quando os recursos estiverem disponíveis — podem rodar em qualquer fase.

- [ ] **Visor** — Análise de interface via screenshots (opcional, se o usuário fornecer screenshots)
- [ ] **Design System** — Extração de tokens de design (opcional; tokens concentrados em `EditorMetrics`)
- [ ] **Tracer** — Análise dinâmica (opcional; exige o controle na mão)

---

## Próximo passo

Após o Time de Descoberta concluir e o `_reversa_sdd/` estar populado, você pode disparar um dos fluxos seguintes:

- `/reversa-migrate`: orquestrador do **Time de Migração** (Paradigm Advisor → Curator → Strategist → Designer → Screen Translator → Inspector). Gera as specs do sistema novo. Saída em `_reversa_sdd/migration/` e `_reversa_sdd/screens/`.
- `/reversa-reconstructor`: gera plano bottom-up para reimplementar o software a partir das specs do legado (uma tarefa por sessão).
