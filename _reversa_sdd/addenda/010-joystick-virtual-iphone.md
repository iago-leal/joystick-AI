# Adendo: Controle virtual no iPhone

> Identificador: `010-joystick-virtual-iphone`
> Data: 2026-09-20
> Cenário: legado

## Vigência

Vigente desde 2026-09-20.

## Resumo da entrega

A página que servia de teclado remoto passa a reunir, numa só tela na horizontal, o controle inteiro e o teclado que já existia. Uma faixa no alto traz os gatilhos e os botões secundários; as colunas laterais trazem o direcional e as faces, com o analógico de cada lado no vão do seu agrupamento; e o bloco central alterna entre três estados: área de apontamento, teclado reduzido e teclado completo. Um botão esconde o controle e entrega a tela ao bloco central, para quem está com o controle físico na mão e quer o iPhone só como teclado.

O princípio que organiza a entrega é a origem única de regras. O iPhone **não** se registra como controle ativo: a `VirtualControllerMachine` traduz as mensagens do canal nos mesmos `InputEvent` que a leitura do controle produz, e o `CombinedPressed` soma os botões das duas origens, de modo que cliques, camadas de atalho, paleta, precisão e apontamento continuam com uma regra só, sem caminho duplicado. Controle físico e iPhone coexistem e se combinam: L1 preso no controle vale para o ✕ tocado na tela.

O arrasto remoto foi o único ponto que exigiu tratamento próprio, e a lição vale além desta feature: **uma fonte remota de movimento tem duas cadências a cuidar, a de amostragem e a de entrega**. A página coalesce o envio por quadro (E-09) e o Mac alisa a chegada com o `TouchGlide`, que gasta uma fração do que falta andar a cada tick do laço de 120 Hz (E-10); o touchpad físico segue pelo caminho de antes, sem atraso acrescentado.

Sincronização completa: 38 de 38 ações de `actions.md` fechadas. O PM-0 reprovou a sonda P-01 (o microfone do iPhone aciona junto a Continuity Camera e toma a tela do aparelho), e o usuário decidiu manter o ditado no microfone do Mac, com RF-14 reescrito e D-09 revista, sem uma linha de código. O PM-1 correu inteiro no aparelho e **aprovou os 40 passos**, sem reprovação nem ressalva pendente, com dois desvios anotados: os passos de coexistência correram com o Ipega, e não com o DualSense, de modo que o cruzamento do touchpad físico com o apontamento do iPhone ficou sem cobertura; e a leitura do log foi feita pelo assistente. A sonda P-03, que o PM-0 não pôde executar por falta de cabo, foi executada sem cabo: a página passou a se medir sozinha, e a medição foi repetida num navegador dirigido. Doze emendas saíram das duas passagens. `swift build -c release` passa sem avisos do código, com 427 testes em 43 suítes (379 antes da feature), medidos com o SDK 26.5.

A feature estende a 008 (iPhone como teclado remoto), que está em código mas ainda sem adendo, e a 009 (sugestão de palavras), já sincronizada. O canal e os componentes remotos que este adendo cita estão descritos em `_reversa_forward/008-iphone-teclado-remoto/` até que a 008 seja sincronizada.

## Impacto por artefato da extração

| Artefato | Seção | Tipo de impacto | Delta |
|----------|-------|-----------------|-------|
| `_reversa_sdd/architecture.md` | `#3. Camadas e dependências` | componente-novo | O `JoystickCore` ganha `VirtualController` (tipos de valor do controle virtual), `VirtualControllerMachine` (máquina pura que traduz o canal em `InputEvent`, com idempotência e soltura em ordem estável), `CombinedPressed` (união dos botões das duas origens) e `TouchGlide` (alisamento do arrasto remoto); continua importando só `Foundation`. |
| `_reversa_sdd/architecture.md` | `#3. Camadas e dependências` | componente-novo | O app ganha `VirtualControllerActions`, executor na fila `input` que aplica a zona morta da configuração, limita a cadência a 240 mensagens por segundo e mantém o vigia de inatividade da sessão. |
| `_reversa_sdd/architecture.md` | `#3. Camadas e dependências` | regra-alterada | `InputContext` ganha `virtualPressed` e `pressedAll`; `MotionLoop`, `InputRouter` e `TargetSession` passam a consultar a união em vez de `registry.pressed`. `MotionLoop` trata o arrasto remoto por um caminho próprio, pelo planador, e o temporizador de 120 Hz passa a ser ligado e desligado também por ele. |
| `_reversa_sdd/architecture.md` | `#4. Integrações externas` | regra-alterada | Nenhuma integração nova: o controle virtual usa o canal e o servidor de página da 008, e o ditado continua no microfone do Mac (P-01 reprovada). |
| `_reversa_sdd/architecture.md` | `#5. Modelo de dados em arquivo` | delta-de-contrato-externo | O canal da 008 ganha quatro mensagens de cliente (`btn`, `stick`, `pad`, `mode`) e uma de servidor (`mode`). Contrato em `_reversa_forward/010-joystick-virtual-iphone/interfaces/remote-controller-protocol.md`. |
| `_reversa_sdd/architecture.md` | `#5. Modelo de dados em arquivo` | delta-de-dados | `config.json` não muda de forma; `pointer.stickExponent` foi recalibrado pelo usuário (E-02, E-06). O log ganha `buttons` e `clicks` em `remote.disconnected` e o evento `remote.mode`; no iPhone, a página grava o estado do bloco central e a sensibilidade em `remoteKeyboardPrefs`. |
| `_reversa_sdd/domain.md` | `#3.1 Controle e entrada (001)` | regra-alterada | 001 RN-08 (precisão com L1) passa a ser lida sobre a união dos botões das duas origens, sem mudança de enunciado. 001 RN-01 (um só controle ativo) continua ao pé da letra: o iPhone não entra na fila nem emite conexão. 001 RN-12 (sem coordenadas no log) é reforçada, com chaves proibidas novas. |
| `_reversa_sdd/domain.md` | `#3.3 Atalhos, configuração e editor (003)` | regra-alterada | 003 RN-01 e RN-02 (camadas por botão mantido) valem para qualquer das duas origens, inclusive combinadas. Nenhum botão do controle virtual fica preso por toque, exceto L1 e L2 (E-04), justamente porque a camada exige botão mantido. |
| `_reversa_sdd/domain.md` | `#5. Divergências entre specs e código` | regra-alterada | A DV-03 ("a precisão desliga durante arraste com L1+R1") ganha variação: vale também para L1 de uma origem com R1 da outra. |
| `_reversa_sdd/permissions.md` | `#4. Restrições de acesso internas` | regra-alterada | O controle virtual não pede permissão nova: entra pelo mesmo portão de injeção, que ao suspender solta também o que o iPhone mantinha. |
| `_reversa_sdd/code-analysis.md` | `#1. app-shell`; `#3. pointer` | regra-alterada | Montagem do executor do controle virtual no `AppDelegate`, soltura no `Lifecycle` e no `InjectionGate`, e o caminho novo do arrasto remoto no `MotionLoop`, que o distingue do físico pelo campo `remote` do `InputEvent`. |
| `_reversa_sdd/data-dictionary.md` | `#9. Log de diagnóstico (JSONL)` | delta-de-dados | `remote.disconnected` com `reason`, `keys`, `suggestions`, `buttons` e `clicks`; evento `remote.mode` com o estado do bloco central. Os tipos novos do núcleo estão em `_reversa_forward/010-joystick-virtual-iphone/data-delta.md`. |
| `_reversa_sdd/traceability/code-spec-matrix.md` | `#Testes` | regra-nova | Suítes novas `VirtualControllerMachineTests`, `CombinedPressedTests` e `TouchGlideTests`; `RemoteKeyboardAssetsTests`, `RemoteKeyboardMessageTests`, `LogEventCatalogTests` e `PointerMotionEngineTests` crescem. O total do projeto passa a 427 testes em 43 suítes. |

## Regras sob vigilância

W001 a W009 no watch principal e O001 a O014 em "Observações", em [`_reversa_forward/010-joystick-virtual-iphone/regression-watch.md`](../../_reversa_forward/010-joystick-virtual-iphone/regression-watch.md). A O003, dos alvos tocáveis, teve o critério reescrito depois da medição: cobra 44 pt dos botões do controle, que passam, e tecla inteira com arranjo previsível do teclado, que por geometria não alcança 44 com o controle à vista. Os alvos da barra param em 34 pt, por decisão consciente, e o teclado reduzido em 43,4. A O008, da coexistência com controle físico, foi verificada com o Ipega, de modo que o cruzamento do touchpad do DualSense com o apontamento do iPhone, que dividem o mesmo `TouchpadTracker`, segue sem cobertura.

## Fontes

- `_reversa_forward/010-joystick-virtual-iphone/legacy-impact.md`
- `_reversa_forward/010-joystick-virtual-iphone/regression-watch.md`
- `_reversa_forward/010-joystick-virtual-iphone/requirements.md`
- `_reversa_forward/010-joystick-virtual-iphone/progress.jsonl`
- `_reversa_forward/010-joystick-virtual-iphone/actions.md` (notas de execução)
- `_reversa_forward/010-joystick-virtual-iphone/onboarding.md` (emendas E-01 a E-12, sondas do PM-0 e roteiro do PM-1)
- `_reversa_forward/010-joystick-virtual-iphone/data-delta.md`
- `_reversa_forward/010-joystick-virtual-iphone/interfaces/remote-controller-protocol.md`
- `_reversa_forward/010-joystick-virtual-iphone/interfaces/diagnostic-log.md`
