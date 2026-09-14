# Spec: app-shell

**Versão:** 1.0
**Status:** Rascunho
**Autor:** reversa-spec-sdd
**Data:** 2026-09-14
**Reviewers:** iago

> Selo 🟡 PLANEJADO em todos os itens. Fonte primária: [`prd.md`](../prd.md).

---

## 1. Resumo

🟡 Componente que hospeda o produto como app de barra de menus do macOS: inicia e encerra os demais componentes, verifica e orienta a concessão das permissões de Acessibilidade e Input Monitoring, liga e desliga o modo de condução e mostra o estado do controle, das permissões, do microfone e da configuração. Atende ao passo 1 da jornada e sustenta os demais.

---

## 2. Contexto e Motivação

**Problema:**
🟡 Um app que injeta mouse e teclado só funciona com permissões concedidas manualmente em Ajustes do Sistema. Sem orientação e sem indicação de estado, o usuário não sabe por que o controle "não faz nada", e o diagnóstico exige teclado e mouse.

**Evidências:**
🟡 Premissa 2 do `ideation.md` e escopo "Permissões do macOS" do PRD. Riscos de conflito com jogos (seção 8 do PRD) pedem desligamento rápido do modo.

**Por que agora:**
🟡 Nenhum componente funciona sem as permissões, e o ciclo de desenvolvimento reinstala o app com frequência, o que pode invalidar permissões concedidas (EC-01).

---

## 3. Goals (Objetivos)

- [ ] 🟡 G-01: Levar o usuário de uma primeira execução sem permissões ao controle funcionando em até 3 minutos, seguindo só as orientações do app.
- [ ] 🟡 G-02: Mostrar no menu, em até 2 s após qualquer mudança, o estado do controle, das permissões, do modo, do microfone e da configuração.
- [ ] 🟡 G-03: Ligar e desligar o modo de condução pelo controle e pelo menu.

**Métricas de sucesso:**
| Métrica | Baseline atual | Target | Prazo |
|---------|---------------|--------|-------|
| 🟡 Tempo da primeira execução até o controle funcionando | 🟡 não medido | 🟡 ≤ 3 min | 🟡 fim do MVP |
| 🟡 Atraso entre mudança de estado e atualização do menu | 🟡 não medido | 🟡 ≤ 2 s | 🟡 fim do MVP |

---

## 4. Non-Goals (Fora do Escopo)

- 🟡 NG-01: Ícone no Dock e janela principal permanente; o app vive só na barra de menus.
- 🟡 NG-02: Distribuição pública: App Store, notarização, instalador e atualização automática.
- 🟡 NG-03: Tela de configuração de mapeamentos (ver `action-mapping`, NG-01).
- 🟡 NG-04: Registro de horas de uso para a métrica do PRD; fica para um eventual componente `usage-tracking`.
- 🟡 NG-05: Suporte a Windows e Linux.

---

## 5. Usuários e Personas

**Usuário primário:** 🟡 Programador de sofá, que instala o app na própria máquina e o usa todas as noites.
**Usuário secundário:** 🟡 O mesmo usuário no papel de desenvolvedor, reinstalando versões novas do app.

**Jornada atual (sem a feature):**
1. 🟡 O usuário executa um binário que injeta eventos.
2. 🟡 Nada acontece, porque faltam permissões, sem aviso.
3. 🟡 O usuário procura manualmente em Ajustes do Sistema o que liberar.

**Jornada futura (com a feature):**
1. 🟡 O usuário abre o app; o ícone aparece na barra de menus e uma janela de boas-vindas lista as permissões pendentes.
2. 🟡 Cada permissão tem um botão que abre o painel certo de Ajustes; a lista se atualiza sozinha ao conceder.
3. 🟡 Com tudo concedido, o menu mostra "Controle conectado · Modo ativo" e o controle já funciona.

---

## 6. Requisitos Funcionais

### 6.1 Requisitos Principais

| ID | Requisito | Prioridade | Critério de Aceite |
|----|-----------|-----------|-------------------|
| RF-01 | 🟡 O sistema deve executar como app de barra de menus, sem ícone no Dock. | Must | 🟡 Com o app aberto, há ícone na barra de menus e nenhum ícone no Dock. |
| RF-02 | 🟡 O sistema deve verificar ao iniciar, e a cada 2 s enquanto houver pendência, se as permissões de Acessibilidade e de Input Monitoring estão concedidas. | Must | 🟡 Conceder Acessibilidade com o app aberto atualiza o estado no menu em até 2 s sem reiniciar. |
| RF-03 | 🟡 O sistema deve exibir, com alguma permissão pendente, uma janela listando cada permissão, sua finalidade e um botão que abre o painel correspondente de Ajustes do Sistema. | Must | 🟡 Clicar em "Abrir Ajustes" da Acessibilidade abre Privacidade e Segurança > Acessibilidade. |
| RF-04 | 🟡 O sistema deve fechar a janela de permissões e iniciar os componentes de entrada quando todas as permissões obrigatórias estiverem concedidas. | Must | 🟡 Ao conceder a última permissão, a janela fecha sozinha e o controle passa a mover o cursor. |
| RF-05 | 🟡 O sistema deve mostrar no menu: controle (nome, conexão e bateria quando disponível, ou "Nenhum controle"), permissões, modo de condução, microfone em uso e estado da configuração. | Must | 🟡 Com o DualSense por USB, o menu mostra "DualSense · USB", "Permissões OK", "Modo ativo", "Microfone: DualSense" e "Configuração carregada". |
| RF-06 | 🟡 O sistema deve permitir ligar e desligar o modo de condução pelo menu e pela ação `toggleMode` do controle. | Must | 🟡 Desligar pelo menu faz o controle deixar de mover o cursor; o `longPress` de Options liga de novo. |
| RF-07 | 🟡 O sistema deve refletir o modo no ícone da barra de menus com duas variantes visuais distintas (ativo e desligado). | Must | 🟡 Alternar o modo troca o ícone em até 1 s. |
| RF-08 | 🟡 O sistema deve oferecer no menu os itens "Abrir configuração" (abre o JSON no editor padrão), "Recarregar configuração" e "Sair". | Must | 🟡 "Abrir configuração" abre `~/.config/joystick-ai/config.json`. |
| RF-09 | 🟡 O sistema deve, ao sair, desligar o modo, soltar botões de mouse e teclas pressionados, encerrar o ditado e restaurar o microfone padrão. | Must | 🟡 Sair com R2 segurado não deixa o botão do mouse preso. |
| RF-10 | 🟡 O sistema deve oferecer a opção "Abrir ao iniciar sessão", desligada por padrão. | Should | 🟡 Com a opção ligada, o app abre após reiniciar o Mac. |
| RF-11 | 🟡 O sistema deve exibir notificação do sistema quando o controle conectar ou desconectar e quando uma permissão for revogada. | Should | 🟡 Desligar o controle gera a notificação "DualSense desconectado". |
| RF-12 | 🟡 O sistema deve registrar erros dos componentes num log em `~/Library/Logs/joystick-ai/` e oferecer no menu o item "Mostrar log". | Should | 🟡 Um JSON inválido gera entrada no log com a mensagem de validação. |

### 6.2 Fluxo Principal (Happy Path)

1. 🟡 O usuário abre o app pela primeira vez.
2. 🟡 O sistema mostra o ícone na barra de menus e verifica as permissões.
3. 🟡 Faltando Acessibilidade e Input Monitoring, o sistema abre a janela de permissões.
4. 🟡 O usuário clica em "Abrir Ajustes", concede Acessibilidade e depois Input Monitoring.
5. 🟡 O sistema detecta cada concessão em até 2 s, fecha a janela e inicia `controller-input`, `pointer-control`, `action-mapping` e `voice-dictation`.
6. 🟡 O usuário liga o DualSense; o menu mostra o controle conectado e o modo ativo.
7. 🟡 Resultado: o controle move o cursor e executa as ações.

### 6.3 Fluxos Alternativos

**Fluxo Alternativo A: jogar com o controle**
1. 🟡 O usuário segura Options por 800 ms.
2. 🟡 O sistema desliga o modo, troca o ícone, solta entradas pressionadas e vibra o controle.
3. 🟡 Para voltar, o usuário segura Options de novo.

**Fluxo Alternativo B: permissão revogada durante o uso**
1. 🟡 O usuário remove o app da lista de Acessibilidade.
2. 🟡 O sistema detecta em até 2 s, suspende a injeção, notifica e reabre a janela de permissões.

---

## 7. Requisitos Não-Funcionais

| ID | Requisito | Valor alvo | Observação |
|----|-----------|-----------|------------|
| RNF-01 | 🟡 Inicialização | 🟡 ≤ 1 s até o ícone aparecer na barra de menus | 🟡 Medido do clique no app. |
| RNF-02 | 🟡 Memória | 🟡 ≤ 60 MB residentes em uso normal | 🟡 Medido no Monitor de Atividade. |
| RNF-03 | 🟡 Compatibilidade | 🟡 macOS 13 ou superior | 🟡 Piso definido por "Abrir ao iniciar sessão" pela API atual do sistema (OQ-02). |
| RNF-04 | 🟡 Estabilidade | 🟡 Sessão de 4 h sem travamento nem vazamento acima de 10 MB | 🟡 Duração de uma noite de uso. |
| RNF-05 | 🟡 Assinatura | 🟡 Assinado com certificado de desenvolvimento estável | 🟡 Mantém as permissões entre reinstalações (EC-01). |

---

## 8. Design e Interface

**Componentes afetados:** 🟡 Item da barra de menus, janela de permissões, notificações do sistema.

**Comportamento esperado:**
🟡 Menu da barra, de cima para baixo: estado do controle; estado das permissões; microfone; estado da configuração; separador; "Modo de condução" com marca de seleção; "Abrir ao iniciar sessão" com marca; separador; "Abrir configuração", "Recarregar configuração", "Mostrar log"; separador; "Sair". A janela de permissões lista Acessibilidade ("mover o cursor e digitar pelo controle") e Input Monitoring ("ler o controle com outros apps em foco"), cada uma com indicador concedida ou pendente e botão "Abrir Ajustes".

**Estados da UI:**
- Estado vazio: 🟡 sem controle, o menu mostra "Nenhum controle · conecte um DualSense por USB ou Bluetooth".
- Estado de carregamento: 🟡 durante a verificação inicial de permissões, o menu mostra "Verificando permissões".
- Estado de erro: 🟡 permissão pendente, configuração inválida ou ditado indisponível aparecem com ícone de alerta no item correspondente e no ícone da barra.
- Estado de sucesso: 🟡 todos os itens sem alerta e ícone na variante ativa.

---

## 9. Modelo de Dados

**Entidades novas ou modificadas:**

```
AppState {                        // em memória
  controller: ControllerInfo?     // ver controller-input
  accessibilityGranted: Bool
  inputMonitoringGranted: Bool
  conductionModeOn: Bool
  microphoneName: String?
  configStatus: Enum              // loaded | invalid | defaultInMemory
  configError: String?
}

PersistedState {                  // ~/.config/joystick-ai/state.json
  conductionModeOn: Bool          // restaurado ao iniciar; padrão true
  launchAtLogin: Bool             // padrão false
  previousDefaultInputUID: String?// ver voice-dictation, EC-04
}
```

**Migrações necessárias:** 🟡 Não.

---

## 10. Integrações e Dependências

| Dependência | Tipo | Impacto se indisponível |
|-------------|------|------------------------|
| 🟡 APIs de permissão do macOS (Acessibilidade e Input Monitoring) | Obrigatória | 🟡 Sem verificação possível, o app assume pendente e mantém a janela de orientação. |
| 🟡 URLs de painéis de Ajustes do Sistema | Obrigatória | 🟡 Se o painel não abrir, a janela mostra o caminho por extenso para navegação manual. |
| 🟡 Serviço de login do macOS | Opcional | 🟡 Falha em "Abrir ao iniciar sessão" desmarca a opção e exibe aviso. |
| 🟡 Central de notificações | Opcional | 🟡 Sem permissão de notificação, o estado segue visível só no menu. |
| 🟡 Certificado de desenvolvimento Apple | Obrigatória | 🟡 Sem assinatura estável, as permissões se perdem a cada reinstalação (EC-01). |
| 🟡 `controller-input`, `pointer-control`, `action-mapping`, `voice-dictation` | Obrigatória | 🟡 Falha ao iniciar um componente é exibida no menu e registrada no log; os demais seguem. |

---

## 11. Edge Cases e Tratamento de Erros

| Cenário | Trigger | Comportamento esperado |
|---------|---------|----------------------|
| EC-01: 🟡 Permissões perdidas após recompilar | 🟡 Nova assinatura do binário invalida a concessão anterior | 🟡 O sistema detecta a pendência, reabre a janela e exibe a dica "remova a entrada antiga do app em Ajustes e conceda de novo"; a assinatura estável (RNF-05) evita o caso. |
| EC-02: 🟡 Permissão concedida e sem efeito até reiniciar | 🟡 O macOS só aplica Input Monitoring após relançar o app | 🟡 O sistema detecta concessão sem eventos chegando e oferece o botão "Reiniciar app". |
| EC-03: 🟡 Segunda instância aberta | 🟡 Usuário abre o app de novo | 🟡 A nova instância ativa a existente e se encerra, sem dois ícones na barra. |
| EC-04: 🟡 Falha de inicialização de componente | 🟡 Exceção ao iniciar `voice-dictation` | 🟡 O menu mostra "Ditado indisponível", o log registra o erro e os demais componentes funcionam. |
| EC-05: 🟡 `state.json` corrompido | 🟡 Arquivo ilegível | 🟡 O sistema usa os padrões, recria o arquivo e registra aviso no log. |
| EC-06: 🟡 Encerramento pelo sistema | 🟡 Logout ou desligamento do Mac | 🟡 O sistema executa a mesma limpeza do RF-09 antes de sair. |

---

## 12. Segurança e Privacidade

- **Autenticação:** 🟡 Não se aplica; app local.
- **Autorização:** 🟡 Acessibilidade e Input Monitoring, solicitadas com explicação de finalidade e nunca contornadas.
- **Dados sensíveis:** 🟡 O app tem capacidade de injetar teclas; por isso não abre conexões de rede, não registra teclas nem textos e mantém log só de estados e erros.
- **Auditoria:** 🟡 Log local em `~/Library/Logs/joystick-ai/` com rotação ao atingir 5 MB.

---

## 13. Plano de Rollout

- **Estratégia:** 🟡 Build local assinado com certificado de desenvolvimento, instalado em `/Applications` pelo próprio usuário; cada versão marcada com tag git.
- **Como reverter (rollback):** 🟡 Sair do app, substituir o `.app` pelo da tag anterior e abrir de novo; com a mesma assinatura, as permissões continuam válidas.
- **Monitoramento pós-deploy:** 🟡 Nas primeiras noites de uso, verificar o log em busca de erros de componentes e de revogações de permissão.

---

## 14. Open Questions

| # | Pergunta | Impacto | Dono | Prazo |
|---|---------|---------|------|-------|
| OQ-01 | 🟡 Input Monitoring é de fato necessário para receber eventos do GameController em segundo plano? Se não, a janela lista só Acessibilidade. | Médio | iago | fim da prova de conceito |
| OQ-02 | 🟡 Confirmar macOS 13 como versão mínima, já que a máquina de uso tem versão bem mais recente. | Baixo | iago | antes do plano |
| OQ-03 | 🟡 Há conta Apple com certificado de desenvolvimento disponível para assinatura estável? | Médio | iago | antes do plano |

---

## 15. Decisões Tomadas (Decision Log)

| Decisão | Alternativas consideradas | Racional |
|---------|--------------------------|---------|
| 🟡 App de barra de menus sem Dock | 🟡 App com janela; daemon sem interface | 🟡 Fica fora do caminho durante a sessão e ainda mostra estado e permissões. |
| 🟡 Verificação periódica de permissões a cada 2 s só com pendência | 🟡 Verificar só ao iniciar | 🟡 O macOS não notifica concessões; a verificação curta evita pedir reinício. |
| 🟡 Options segurado alterna o modo | 🟡 Botão PS; combinação de três botões | 🟡 O botão PS pode ser capturado pelo sistema; Options segurado é alcançável e raro de acionar por acidente. |
| 🟡 Assinatura com certificado de desenvolvimento | 🟡 Assinatura ad hoc | 🟡 A assinatura ad hoc muda a cada build e invalida as permissões. |

---

## Apêndice

### Referências
- 🟡 [`prd.md`](../prd.md), seções 4, 5, 6 e 8
- 🟡 [`ideation.md`](../ideation.md), premissa 2
- 🟡 [`controller-input.md`](./controller-input.md), [`pointer-control.md`](./pointer-control.md), [`action-mapping.md`](./action-mapping.md), [`voice-dictation.md`](./voice-dictation.md)

### Histórico de Revisões
| Versão | Data | Autor | Mudanças |
|--------|------|-------|---------|
| 1.0 | 2026-09-14 | reversa-spec-sdd | Criação inicial |

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
