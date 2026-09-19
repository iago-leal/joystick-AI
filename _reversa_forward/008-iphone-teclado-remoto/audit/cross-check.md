# Auditoria cruzada: iPhone como teclado touch do Mac

> Feature: `008-iphone-teclado-remoto`
> Data: `2026-09-19` (segunda rodada, após a revisão de A001 e A002)
> Artefatos analisados: [`requirements.md`](../requirements.md), [`roadmap.md`](../roadmap.md), [`actions.md`](../actions.md)
> Apoio: [`data-delta.md`](../data-delta.md), [`interfaces/`](../interfaces/), [`investigation.md`](../investigation.md), [`onboarding.md`](../onboarding.md), `_reversa_sdd/domain.md`, `_reversa_sdd/architecture.md` e o código em `Sources/`
> Gerado por `/reversa-audit`, que só lê: nenhum artefato da feature foi alterado.

Os IDs dos achados que já existiam na primeira rodada foram mantidos, para facilitar a comparação. A001 e A002 foram resolvidos, e os achados novos começam em A014.

## Resumo

| Severidade | Quantidade |
|------------|-----------:|
| CRITICAL | 0 |
| HIGH | 0 |
| MEDIUM | 11 |
| LOW | 3 |
| **Total em aberto** | **14** |
| Resolvidos desde a rodada anterior | 2 (A001, A002) |

## Achados em aberto

| ID | Severidade | Eixo | Descrição | Onde está |
|----|------------|------|-----------|-----------|
| A003 | MEDIUM | Consistência | "Sessão" tem dois sentidos. RN-04 diz que o código vale "para uma única sessão do teclado remoto", mas o protocolo aceita o mesmo código em qualquer pareamento sem conexão ativa, enquanto o recurso estiver ligado, e o `data-delta.md` usa `activeSession` para a conexão de um aparelho | `requirements.md` RN-04; `roadmap.md` D-05, D-06; `interfaces/remote-keyboard-protocol.md` §3.4; `data-delta.md` §3 (`RemotePairing`) |
| A004 | MEDIUM | Consistência | RN-03 diz que "o app gera uma identidade própria" e RF-03 que o app "oferece ao iPhone a identidade de RN-03"; no plano, quem gera é um script executado pelo usuário, e o que vai ao iPhone é só o certificado da autoridade | `requirements.md` RN-03, RF-03; `roadmap.md` D-03, D-04; `interfaces/identidade-tls.md` §1 e §2 |
| A005 | MEDIUM | Consistência | `remote.rejected` também registra as falhas ao ligar o recurso (`no_identity`, `host_mismatch`, `expired`), embora RN-13 o restrinja à recusa de um aparelho. `remote.disabled` com `listener_failed` descreve um recurso que, pela D-02, nem chegou a ligar | `requirements.md` RN-13; `roadmap.md` D-02, §8; `interfaces/diagnostic-log.md` §2; `interfaces/identidade-tls.md` §2 |
| A006 | MEDIUM | Consistência | Dois fechamentos do canal não têm motivo no log: a mensagem antes do `hello` (código 4002) e o `hello` que não chega em 5 s. Com a D-06 revista, a conexão nova aguarda o `hello` também com sessão ativa, e o caso ficou mais frequente | `interfaces/remote-keyboard-protocol.md` §3.1, §3.2; `interfaces/diagnostic-log.md` §2; `actions.md` T017, T020 |
| A007 | MEDIUM | Consistência | Não se sabe quem conta as mensagens inválidas. T007 e T016 põem o contador na `RemoteKeyboardMachine`, o `data-delta.md` não o lista entre os campos da máquina, e T020 valida as mensagens contra a geometria no listener | `data-delta.md` §3 (`RemoteKeyboardMachine`); `actions.md` T007, T016, T020; `roadmap.md` D-16 |
| A008 | MEDIUM | Cobertura | T030 passou a tratar `busy`, mas ainda não diz como a página trata `welcome` (guardar o token), `reject` com os demais motivos, `layout` depois da troca de fonte, `modifiers` e `status`. RF-09 e a faixa de estado de RF-10 ficam sem ação explícita do lado da página | `requirements.md` RF-06, RF-09, RF-10, RF-12; `roadmap.md` D-12, D-15; `actions.md` T009, T029, T030 |
| A009 | MEDIUM | Cobertura | O requisito não funcional "nenhuma tecla perdida nem trocada de ordem numa rajada de 10 teclas por segundo" não tem decisão, sonda nem passo de roteiro | `requirements.md` §6 (desempenho, segunda linha); `roadmap.md` §3, §4; `investigation.md` §5; `actions.md` PM-0, PM-1 |
| A010 | MEDIUM | Coerência com o legado | No glossário 🟢, acorde é "tecla do `KeyCatalog`", mas a D-09 e o `data-delta.md` passam a criar `KeyChord` com códigos fora do catálogo, sem registrar a alteração do termo | `_reversa_sdd/domain.md` §2 (Acorde); `roadmap.md` D-09; `data-delta.md` §4 (`KeyChord`) |
| A014 | MEDIUM | Coerência com o legado | A D-17 não diz se as teclas seguintes levam `maskAlphaShift` enquanto o Caps Lock estiver ativo. `postKey` monta as `flags` só com os modificadores contados (RN-IN-08 🟢), e a máquina não guarda o estado alternado do Caps Lock. Se o sistema calcular o caractere pelas `flags` do evento injetado, as letras sairão minúsculas e a P-04 será reprovada por omissão do plano | `roadmap.md` D-17; `data-delta.md` §3 e §4; `actions.md` T015, T037; `investigation.md` P-04; `KeyboardInjector.swift:35-39,105-117` |
| A015 | MEDIUM | Consistência | Não está definido o que a página faz quando a própria conexão é fechada com o código 4004 (`replaced`). T030 manda reconectar a cada 1 s com o token. Duas abas com o mesmo `sessionStorage` (o Safari copia esse armazenamento ao duplicar uma aba) passariam a tomar a sessão uma da outra sem parar, e cada substituição solta as teclas mantidas | `roadmap.md` D-06; `interfaces/remote-keyboard-protocol.md` §3.4, §3.5; `actions.md` T030 |
| A016 | MEDIUM | Consistência | O contrato diverge de si mesmo quanto ao token desconhecido com sessão ativa: o §3.1 manda responder `busy` a "outro token", e o §3.4 manda responder `bad_token` a "token desconhecido", sem condição de sessão. A escolha muda a página, que volta a pedir o QR com `bad_token` e para com `busy` | `interfaces/remote-keyboard-protocol.md` §3.1, §3.4; `data-delta.md` §3 (`PairingOutcome`); `actions.md` T005, T020 |
| A011 | LOW | Sanidade do actions | T029 cria `index.html` e `keyboard.css`, mas a coluna de arquivo alvo cita só o primeiro | `actions.md` T029 |
| A012 | LOW | Sanidade do actions | T033 aponta `scripts/build-app.sh` como arquivo alvo, embora só o execute; o mesmo arquivo é alvo de T031. Não há conflito, porque T033 não é `[//]` e depende de T031 por T032 | `actions.md` T031, T033 |
| A013 | LOW | Coerência com o legado | A feature altera, de caso pensado, regras 🟢 do legado: 001 RN-12 (sem rede), RN-IN-02 (descarte silencioso), a linha "Rede" de `permissions.md` §2 e a ausência de servidor em `architecture.md` §4. A alteração está registrada em RN-01, RN-11 e no roadmap §2, mas os documentos do legado ficam desatualizados até o `/reversa-sync` | `requirements.md` RN-01, RN-11; `roadmap.md` §2; `_reversa_sdd/domain.md` §3.1; `_reversa_sdd/permissions.md` §2; `_reversa_sdd/architecture.md` §4 |

## Achados resolvidos desde a rodada anterior

| ID | Situação anterior | Como foi resolvido |
|----|-------------------|--------------------|
| A001 | HIGH: Caps Lock sem caminho de injeção | A D-17 passou a prever `KeyboardInjector.capsLock(down:)` e o efeito `.capsLock(down:)`; o `data-delta.md` registra o método e o efeito, a nova ação T037 os implementa, e T007, T015 e T021 foram ajustadas. Resta a omissão das `flags` das teclas seguintes (A014) |
| A002 | HIGH: retomada pelo token bloqueada pela regra de um aparelho | A D-06 e o protocolo (§3.1, §3.4, §3.5) deixam o token da sessão substituir a conexão ativa, com soltura e código 4004; a página trata `busy` como final; T005, T020 e T030 foram ajustadas, e o log ganhou `replaced`. Restam o tratamento do 4004 (A015) e a ambiguidade do token desconhecido (A016) |

## Detalhe dos achados CRITICAL e HIGH

Nenhum nesta rodada.

## Itens verificados que passaram

### Cobertura

- RF-01 a RF-13 têm ao menos uma decisão no roadmap: RF-01 e RF-02 (D-14), RF-03 (D-03, D-04), RF-04 a RF-06 (D-08, D-09, D-15), RF-07 (D-10), RF-08 e RF-09 (D-12), RF-10 (D-13, D-15), RF-11 (D-11, D-13), RF-12 (D-05, D-06), RF-13 (D-18).
- As decisões D-01 a D-18 aparecem na tabela de correspondência do `actions.md`, cada uma com ações existentes; a D-06 inclui agora T030, e a D-17 inclui T007, T015 e T037.
- Os 17 cenários Gherkin do §7 têm decisão e passo correspondente no roteiro do PM-1. O cenário "Reconexão após bloqueio" deixou de depender do prazo de 10 s, e o cenário "Segundo aparelho" segue coberto pelo `busy` com código (§3.4).
- As regras RN-01 a RN-14 estão cobertas por decisões. A substituição pelo token não fere RN-05, porque só o portador do token da sessão, isto é, o próprio aparelho pareado, a aciona.
- As premissas do roadmap §4 correspondem às lacunas do `requirements.md` §10 e às sondas P-01 a P-05.
- A meta de 3 s de RF-10 é viável: `PermissionMonitor` consulta a permissão a cada 2 s, com folga de 200 ms.

### Consistência

- Todos os identificadores citados no roadmap existem no `requirements.md`.
- Os identificadores do legado citados existem: 001 RN-04, 001 RN-12, RN-IN-02, RN-IN-07, RN-IN-08, RN-IN-10, RN-IN-11, RN-IN-16, RN-AT-09 e 002 D-05.
- Os três contratos em `interfaces/` estão listados no roadmap §7.
- `PairingOutcome.resumed` corresponde a `remote.connected` com `resumed: true`, e `replaced` aparece na D-06, no protocolo §3.4 e §3.5 e no contrato do log.
- O efeito `.capsLock(down:)` e o método `capsLock(down:)` aparecem com o mesmo nome no roadmap, no `data-delta.md` e nas ações T015, T021 e T037.
- As integrações novas I-14 e I-15 não colidem com I-01 a I-13.
- Terminologia estável nos três documentos: "teclado remoto", "preso" e "mantido" (`latched` e `held`), "vigia", "fonte de entrada", "portão de injeção".

### Coerência com o legado

- O Caps Lock fica fora de `modifierCounts` (D-17, T037), o que preserva RN-IN-07 para ⌘, ⇧, ⌥ e ⌃.
- A D-09 respeita RN-IN-07 e RN-IN-08 para os quatro modificadores (`KeyboardInjector.swift:41-50`) e herda RN-IN-10 e a máscara das teclas F (`KeyboardInjector.swift:109-114`).
- A D-13 segue RI-04 (`InjectionGate.swift:47-56`); a D-10 preserva RN-AT-09 para o controle; RI-07 não é tocada.
- ADR-001, ADR-002, ADR-005 e ADR-008 estão respeitados.
- Os componentes citados existem: `KeyboardInjector`, `InjectionGate`, `Lifecycle.cleanUp`, `StatusMenu`, `AppDelegate`, `EditorMetrics`, `ShortcutActions`, `KeyRepeat`, `LogEventCatalog`, `LogEventCatalogTests.sampleEvents`, `FigureAssetsTests`, `scripts/build-app.sh`, `scripts/check-signature.sh` e `scripts/create-local-signing-identity.sh`.
- As seções de `architecture.md` citadas no roadmap §5 (§1, §3, §4, §5) existem.

### Sanidade do actions

- Todas as dependências apontam para IDs existentes (T001 a T037, PM-0, PM-1); T037 depende de T001, e T021 de T016, T017 e T037.
- Não há ciclo de dependência. A cadeia mais longa segue com 9 ações (T001 → T011 → T015 → T016 → T021 → T023 → T028 → T032 → T033); o ramo por T037 é mais curto.
- Nenhum par de ações `[//]` compartilha arquivo alvo; T037 é a única a tocar `KeyboardInjector.swift`.
- As contagens do resumo conferem: 37 ações, 24 paralelizáveis.
- Nenhum ID foi reciclado: a ação nova recebeu T037, e as existentes mantiveram os números.
