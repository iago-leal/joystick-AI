# Spec: action-mapping

**Versão:** 1.1
**Status:** Rascunho
**Autor:** reversa-spec-sdd
**Data:** 2026-09-14
**Reviewers:** iago

> Selo 🟡 PLANEJADO em todos os itens. Fonte primária: [`prd.md`](../prd.md).

---

## 1. Resumo

🟡 Componente que associa botões e combinações do DualSense a ações (abrir aplicativo, disparar atalho de teclado, digitar texto pré-definido, clicar, ditar e alternar o modo) e mantém essa associação num arquivo JSON editável e recarregado automaticamente. Traz um mapeamento padrão voltado ao fluxo com Claude Code e Reversa. Atende aos passos 2, 4 e 5 da jornada.

---

## 2. Contexto e Motivação

**Problema:**
🟡 A condução de uma sessão com agentes é feita de interações discretas e repetitivas: comandos com barra, `CONTINUAR`, escolhas em menus, aprovação de permissões. Hoje todas exigem teclado.

**Evidências:**
🟡 Observação de design confirmada em `personas.md`: essas interações se mapeiam melhor para botões do que a programação clássica. Decisões do usuário: configuração por arquivo JSON e teclado virtual fora do MVP.

**Por que agora:**
🟡 É o componente que entrega a maior parte do valor diário e define o formato de configuração consumido por `pointer-control` e `voice-dictation`.

---

## 3. Goals (Objetivos)

- [ ] 🟡 G-01: Conduzir um ciclo completo do `/reversa-forward` (enviar comando, navegar em menus, aprovar permissões, responder `CONTINUAR`) usando só o controle.
- [ ] 🟡 G-02: Aplicar uma alteração salva no arquivo de configuração em até 1 s, sem reiniciar o app.
- [ ] 🟡 G-03: Executar a ação de um botão em até 30 ms (p95) após o evento de entrada.

**Métricas de sucesso:**
| Métrica | Baseline atual | Target | Prazo |
|---------|---------------|--------|-------|
| 🟡 Interações de teclado necessárias num ciclo do `/reversa-forward` | 🟡 todas | 🟡 0 | 🟡 fim do MVP |
| 🟡 Tempo entre salvar o JSON e a nova configuração valer | 🟡 inexistente | 🟡 ≤ 1 s | 🟡 fim do MVP |

---

## 4. Non-Goals (Fora do Escopo)

- 🟡 NG-01: Tela gráfica de configuração; a edição é feita só no arquivo JSON.
- 🟡 NG-02: Teclado virtual na tela para digitação caractere a caractere.
- 🟡 NG-03: Perfis de mapeamento diferentes por aplicativo em foco.
- 🟡 NG-04: Macros com sequências temporizadas, condicionais ou execução de scripts de shell.
- 🟡 NG-05: Sincronização da configuração entre máquinas.

---

## 5. Usuários e Personas

**Usuário primário:** 🟡 Programador de sofá conduzindo sessões do Claude Code e do Reversa no terminal ou no VS Code.
**Usuário secundário:** 🟡 O mesmo usuário no papel de configurador, editando o JSON para ajustar o mapeamento.

**Jornada atual (sem a feature):**
1. 🟡 O agente termina uma etapa e pede `CONTINUAR`.
2. 🟡 O usuário digita o comando e pressiona Enter.
3. 🟡 Um menu de opções aparece e o usuário usa setas e Enter no teclado.

**Jornada futura (com a feature):**
1. 🟡 O agente pede `CONTINUAR` e o usuário pressiona L1 + ✕.
2. 🟡 Um menu aparece e o usuário escolhe com o direcional e confirma com ✕.
3. 🟡 Um pedido de permissão aparece e o usuário aprova com ✕ ou recusa com ○.

---

## 6. Requisitos Funcionais

### 6.1 Requisitos Principais

| ID | Requisito | Prioridade | Critério de Aceite |
|----|-----------|-----------|-------------------|
| RF-01 | 🟡 O sistema deve carregar os mapeamentos de `~/.config/joystick-ai/config.json` ao iniciar. | Must | 🟡 Com o arquivo presente e válido, os botões executam as ações nele definidas. |
| RF-02 | 🟡 O sistema deve criar o arquivo com o mapeamento padrão (seção 8) quando ele não existir. | Must | 🟡 Apagar o arquivo e iniciar o app recria o arquivo com o conteúdo padrão. |
| RF-03 | 🟡 O sistema deve observar o arquivo e recarregar a configuração em até 1 s após cada gravação. | Must | 🟡 Trocar a ação de △ no JSON e salvar faz △ executar a nova ação sem reiniciar o app. |
| RF-04 | 🟡 O sistema deve validar o arquivo e, se inválido, manter a última configuração válida e informar ao `app-shell` a mensagem de erro com a linha. | Must | 🟡 Salvar JSON com vírgula faltando mantém os mapeamentos anteriores e o menu mostra o erro com o número da linha. |
| RF-05 | 🟡 O sistema deve suportar os gatilhos `press` (dispara ao pressionar), `tap` (dispara ao soltar se segurado por menos de `longPressMs`), `longPress` (dispara ao atingir `longPressMs`, padrão 800 ms) e `hold` (inicia ao pressionar e termina ao soltar). | Must | 🟡 Com Options em `tap` e `longPress`, um toque de 200 ms dispara só a ação de `tap` e segurar 1 s dispara só a de `longPress`. |
| RF-06 | 🟡 O sistema deve suportar combinações com um botão modificador declarado (padrão: L1): o gatilho dispara quando o botão é pressionado com o modificador segurado. | Must | 🟡 Com L1 segurado, ✕ executa a ação de `l1+cross` e não a ação de ✕ sozinho. |
| RF-07 | 🟡 O sistema deve executar a ação `openApp`, abrindo ou trazendo para frente o aplicativo pelo bundle id. | Must | 🟡 A ação com `com.microsoft.VSCode` abre o VS Code se fechado ou o traz para frente se aberto. |
| RF-08 | 🟡 O sistema deve executar a ação `keystroke`, injetando uma tecla com modificadores (Command, Option, Control, Shift). | Must | 🟡 A ação `{ "key": "z", "modifiers": ["command"] }` desfaz a última edição no VS Code. |
| RF-09 | 🟡 O sistema deve executar a ação `text`, digitando o texto no aplicativo em foco e, se `pressEnter` for verdadeiro, pressionando Enter ao final. | Must | 🟡 A ação `{ "text": "CONTINUAR", "pressEnter": true }` com o Claude Code em foco envia `CONTINUAR` e avança o fluxo. |
| RF-10 | 🟡 O sistema deve repetir ações `keystroke` com `repeat: true` enquanto o botão estiver pressionado, após 400 ms e a cada 50 ms. | Must | 🟡 Segurar o direcional para baixo por 1 s num menu move a seleção ao menos 10 posições. |
| RF-11 | 🟡 O sistema deve executar as ações `mouseLeft` e `mouseRight` repassando pressionar e soltar ao `pointer-control`. | Must | 🟡 R2 mapeado para `mouseLeft` clica ao pressionar e soltar. |
| RF-12 | 🟡 O sistema deve executar a ação `dictation` com semântica `hold`, repassando início e fim ao `voice-dictation`. | Must | 🟡 Segurar L2 inicia o ditado; soltar encerra. |
| RF-13 | 🟡 O sistema deve executar a ação `toggleMode`, que liga e desliga o modo de condução, e continuar processando só essa ação com o modo desligado. | Must | 🟡 Com o modo desligado, só o `longPress` de Options produz efeito; os demais botões são ignorados. |
| RF-14 | 🟡 O sistema deve rejeitar na validação um mesmo botão com `press` junto de `tap` ou `longPress`, e um modificador com ação própria. | Should | 🟡 Um JSON com `cross` em `press` e em `tap` é rejeitado com mensagem que cita `cross`. |
| RF-15 | 🟡 O sistema deve ignorar ações `keystroke` e `text` enquanto o ditado estiver ativo. | Must | 🟡 Pressionar ✕ com L2 segurado não envia Enter. |

### 6.2 Fluxo Principal (Happy Path)

1. 🟡 O usuário está no Claude Code e o `/reversa-forward` pede `CONTINUAR`.
2. 🟡 O usuário segura L1 e pressiona ✕.
3. 🟡 O sistema resolve o gatilho `l1+cross`, encontra a ação `text` com `CONTINUAR` e `pressEnter: true` e a executa.
4. 🟡 O agente apresenta um menu de escolha; o usuário pressiona o direcional para baixo duas vezes.
5. 🟡 O sistema injeta duas setas para baixo.
6. 🟡 O usuário pressiona ✕ e o sistema injeta Enter.
7. 🟡 Resultado: a opção foi escolhida e o fluxo avançou sem teclado.

### 6.3 Fluxos Alternativos

**Fluxo Alternativo A: abrir o VS Code e alternar o modo com o mesmo botão**
1. 🟡 Um toque curto em Options dispara `tap` e abre o VS Code.
2. 🟡 Segurar Options por 800 ms dispara `longPress` e alterna o modo de condução; ao soltar, nenhuma ação de `tap` é executada.

**Fluxo Alternativo B: edição da configuração**
1. 🟡 O usuário abre o JSON pelo menu do `app-shell`, altera um mapeamento e salva.
2. 🟡 O sistema valida e aplica a nova configuração; se houver erro, mantém a anterior e exibe a mensagem.

---

## 7. Requisitos Não-Funcionais

| ID | Requisito | Valor alvo | Observação |
|----|-----------|-----------|------------|
| RNF-01 | 🟡 Performance | 🟡 p95 ≤ 30 ms da entrada à ação injetada | 🟡 Exceto `tap`, que por definição espera o soltar. |
| RNF-02 | 🟡 Recarga | 🟡 ≤ 1 s entre gravação e aplicação | 🟡 Observação de arquivo do sistema, sem varredura periódica. |
| RNF-03 | 🟡 Compatibilidade de layout | 🟡 Ação `text` independente do layout de teclado | 🟡 O texto é injetado como caracteres Unicode, não como teclas físicas. |
| RNF-04 | 🟡 Legibilidade | 🟡 Arquivo padrão com no máximo 150 linhas | 🟡 JSON formatado com dois espaços. |

---

## 8. Design e Interface

**Componentes afetados:** 🟡 Arquivo `~/.config/joystick-ai/config.json`; eventos injetados no aplicativo em foco.

**Comportamento esperado:**
🟡 Cada evento de botão é resolvido nesta ordem: se o modo está desligado, só `toggleMode` é considerado; se há modificador segurado e existe combinação para o botão, executa a combinação; se não, executa o gatilho do botão sozinho. Mapeamento padrão:

| Gatilho | Tipo | Ação | Uso no fluxo |
|---------|------|------|--------------|
| 🟡 direcional ↑ ↓ ← → | press, repeat | 🟡 setas | 🟡 navegar em menus e no editor |
| 🟡 ✕ | press | 🟡 Enter | 🟡 confirmar opção ou permissão |
| 🟡 ○ | press | 🟡 Esc | 🟡 cancelar ou interromper o agente |
| 🟡 □ | press, repeat | 🟡 Backspace | 🟡 apagar caractere |
| 🟡 △ | press | 🟡 Tab | 🟡 completar ou alternar foco |
| 🟡 L1 | modificador | 🟡 nenhuma | 🟡 camada de combinações e precisão |
| 🟡 L1 + ✕ | press | 🟡 texto `CONTINUAR` + Enter | 🟡 avançar fluxo do Reversa |
| 🟡 L1 + ↑ | press | 🟡 texto `/reversa-forward` + Enter | 🟡 iniciar ciclo forward |
| 🟡 L1 + □ | press, repeat | 🟡 Option + Backspace | 🟡 apagar palavra |
| 🟡 L1 + ○ | press | 🟡 Command + Z | 🟡 desfazer |
| 🟡 L1 + △ | press | 🟡 Shift + Tab | 🟡 alternar modo do Claude Code |
| 🟡 L2 | hold | 🟡 ditado | 🟡 ditar prompt |
| 🟡 R2 e clique do touchpad | hold | 🟡 clique esquerdo | 🟡 apontar e arrastar |
| 🟡 R1 | hold | 🟡 clique direito | 🟡 menu de contexto |
| 🟡 Options | tap | 🟡 abrir VS Code | 🟡 abrir o ambiente |
| 🟡 Options | longPress | 🟡 alternar modo de condução | 🟡 liberar o controle para jogos |
| 🟡 Create | tap | 🟡 Command + Tab | 🟡 voltar ao aplicativo anterior |

**Estados da UI:**
- Estado vazio: 🟡 arquivo ausente leva à criação do padrão (RF-02).
- Estado de carregamento: 🟡 não se aplica; a leitura é síncrona e curta.
- Estado de erro: 🟡 JSON inválido mantém a configuração anterior e o `app-shell` mostra "Configuração inválida: linha N, descrição".
- Estado de sucesso: 🟡 o `app-shell` mostra "Configuração carregada" com horário.

---

## 9. Modelo de Dados

**Entidades novas ou modificadas:**

```
Config {
  version: Int                 // 1
  modifier: String             // identificador do botão modificador; padrão "l1"
  longPressMs: Int             // padrão 800
  pointer: PointerSettings     // ver pointer-control
  dictation: DictationSettings // ver voice-dictation
  mappings: Array<Mapping>
}

Mapping {
  button: String               // identificador de controller-input, ex.: "cross"
  withModifier: Bool           // padrão false
  trigger: Enum                // press | tap | longPress | hold
  action: Action
}

Action {
  type: Enum                   // openApp | keystroke | text | mouseLeft | mouseRight | dictation | toggleMode
  bundleId: String?            // openApp
  key: String?                 // keystroke: nome da tecla, ex.: "z", "return", "escape", "up"
  modifiers: Array<String>?     // keystroke: command | option | control | shift
  repeat: Bool?                // keystroke; padrão false
  text: String?                // text
  pressEnter: Bool?            // text; padrão false
}
```

**Migrações necessárias:** 🟡 Não no MVP. O campo `version` permite migrações futuras; versão desconhecida é tratada como erro de validação.

---

## 10. Integrações e Dependências

| Dependência | Tipo | Impacto se indisponível |
|-------------|------|------------------------|
| 🟡 `controller-input` | Obrigatória | 🟡 Sem eventos, nenhuma ação é executada. |
| 🟡 Injeção de eventos do macOS (CGEvent) e permissão de Acessibilidade | Obrigatória | 🟡 Sem permissão, `keystroke` e `text` falham; o `app-shell` orienta a concessão. |
| 🟡 NSWorkspace (abertura de aplicativos) | Obrigatória | 🟡 Falha em `openApp` é exibida no menu, sem afetar as demais ações. |
| 🟡 VS Code instalado | Opcional | 🟡 Se o bundle id não existir, a ação falha com aviso (EC-03). |
| 🟡 `pointer-control`, `voice-dictation`, `app-shell` | Obrigatória | 🟡 Recebem as ações `mouse*`, `dictation` e `toggleMode`. |

---

## 11. Edge Cases e Tratamento de Erros

| Cenário | Trigger | Comportamento esperado |
|---------|---------|----------------------|
| EC-01: 🟡 JSON inválido | 🟡 Erro de sintaxe ou campo com tipo errado | 🟡 Mantém a última configuração válida e exibe erro com linha; sem configuração válida anterior, usa o padrão embutido. |
| EC-02: 🟡 Tecla desconhecida | 🟡 `key: "enterr"` | 🟡 Validação rejeita o arquivo citando o mapeamento e a tecla. |
| EC-03: 🟡 Aplicativo não instalado | 🟡 `bundleId` sem aplicativo correspondente | 🟡 A ação não faz nada, o controle vibra duas vezes (se RF-11 de `controller-input` existir) e o menu mostra o aviso. |
| EC-04: 🟡 Modificador solto antes do botão | 🟡 Usuário solta L1 e depois ✕ em sequência | 🟡 A combinação é decidida no momento do pressionar de ✕; se L1 já estava solto, vale a ação de ✕ sozinho. |
| EC-05: 🟡 Desconexão com tecla em repetição | 🟡 Controle desliga com □ segurado | 🟡 O sistema interrompe a repetição e não deixa teclas pressionadas. |
| EC-06: 🟡 Aplicativo em foco não aceita texto sintético | 🟡 Campo seguro de senha ou app que filtra eventos | 🟡 O macOS descarta os eventos; o sistema não repete a tentativa e não expõe o texto em log. |
| EC-07: 🟡 Falha de gravação do arquivo padrão | 🟡 Pasta `~/.config` sem permissão de escrita | 🟡 O sistema usa o padrão embutido em memória e exibe o erro com o caminho. |
| EC-08: 🟡 Arquivo removido com o app aberto | 🟡 Usuário apaga o JSON | 🟡 O sistema mantém a configuração em memória e recria o arquivo padrão só no próximo início. |

---

## 12. Segurança e Privacidade

- **Autenticação:** 🟡 Não se aplica.
- **Autorização:** 🟡 Exige permissão de Acessibilidade para injetar teclas.
- **Dados sensíveis:** 🟡 O arquivo pode conter textos definidos pelo usuário; o sistema não registra em log o conteúdo das ações `text` nem as teclas injetadas.
- **Auditoria:** 🟡 Log de depuração opcional com o identificador do mapeamento executado, sem conteúdo.

---

## 13. Plano de Rollout

- **Estratégia:** 🟡 Entrega após a prova de conceito de `controller-input` e `pointer-control`, validada numa sessão real do `/reversa-forward`.
- **Como reverter (rollback):** 🟡 Restaurar o JSON anterior (recomendado versionar em dotfiles) ou reinstalar a versão anterior do app pela tag git.
- **Monitoramento pós-deploy:** 🟡 Nas duas primeiras semanas, anotar cada vez que foi preciso tocar no teclado e ajustar o mapeamento padrão.

---

## 14. Open Questions

| # | Pergunta | Impacto | Dono | Prazo |
|---|---------|---------|------|-------|
| OQ-01 | 🟡 O mapeamento padrão cobre os atalhos do Claude Code usados de fato (por exemplo, Esc duas vezes, Shift + Tab)? Validar numa sessão real. | Médio | iago | primeira semana de uso |
| OQ-02 | 🟡 A ação `text` digitada como Unicode funciona em todos os terminais usados (Terminal, iTerm2, terminal integrado do VS Code)? | Médio | iago | fim do MVP |
| OQ-03 | 🟡 Vale um segundo modificador (L2 já é ditado) para ampliar as combinações? | Baixo | iago | após um mês de uso |

---

## 15. Decisões Tomadas (Decision Log)

| Decisão | Alternativas consideradas | Racional |
|---------|--------------------------|---------|
| 🟡 Configuração em JSON com recarga automática | 🟡 Tela gráfica; plist | 🟡 Escolha do usuário; versionável em dotfiles e sem custo de interface no MVP. |
| 🟡 Arquivo em `~/.config/joystick-ai/` | 🟡 `~/Library/Application Support/` | 🟡 Caminho fácil de versionar e de abrir pelo terminal. |
| 🟡 L1 como único modificador | 🟡 Vários modificadores; combinações livres | 🟡 Resolução previsível de conflitos e curva de aprendizado menor. |
| 🟡 Texto injetado como Unicode | 🟡 Sequência de teclas físicas | 🟡 Independente do layout ABNT2 ou US e de acentos. |

---

## Apêndice

### Referências
- 🟡 [`prd.md`](../prd.md), seções 4, 5 e 9
- 🟡 [`personas.md`](../personas.md), observação de design
- 🟡 [`controller-input.md`](./controller-input.md), [`pointer-control.md`](./pointer-control.md), [`voice-dictation.md`](./voice-dictation.md), [`app-shell.md`](./app-shell.md)

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

- 🟡 Iterações: 3
- 🟡 Gaps críticos: nenhum
- 🟡 Open questions pendentes: 3 (seção 14)
- 🟡 Observação: o scorer é heurístico e verifica estrutura e vocabulário, não a correção técnica; as open questions de impacto alto continuam bloqueando o plano.

---
Gerado por reversa-spec-sdd em 2026-09-14T18:24:08Z
Fonte: prd.md
