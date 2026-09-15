# Injeção de eventos (injection)

> Unit do módulo `injection` · Gerado pelo Redator em 2026-09-15 · Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA

## Visão Geral

Posta eventos sintéticos de mouse, rolagem e teclado no macOS por `CGEvent`, com uma marca que os distingue do hardware físico. É o único ponto do app que produz efeito fora do processo. 🟢

## Responsabilidades

- Mover o cursor e arrastar a partir de uma posição de partida confiável, limitada às telas. 🟢
- Postar `mouseDown`/`mouseUp` com `clickState`. 🟢
- Postar rolagem em pixel ou linha. 🟢
- Postar teclas, acordes com modificadores compartilhados, repetição e texto Unicode. 🟢
- Clicar para ativar a janela do editor e devolver o cursor. 🟢
- Descartar tudo enquanto a injeção estiver desligada. 🟢
- Registrar `pointer.posted` para eventos com origem, nunca para teclas ou texto. 🟢

## Regras de Negócio

- RN-IN-01: Todo evento é criado com `CGEventSource(stateID: .hidSystemState)`, recebe `eventSourceUserData = 0x4A4F5953` e é postado em `.cghidEventTap`. 🟢
- RN-IN-02: A injeção começa desligada (`enabled = false`) e só o portão de injeção a altera; desligada, movimento, cliques, rolagem, teclas, texto e clique de ativação são descartados sem aviso. 🟢
- RN-IN-03: Posição de partida: a posição acompanhada vale se existir, se a última emissão ocorreu há menos de 100 ms e se a leitura do sistema (`CGEvent(source: nil).location`) é uma das últimas 32 posições postadas; caso contrário, o acompanhamento é descartado e a leitura do sistema passa a valer. 🟢
- RN-IN-04: Movimento: destino = partida + delta, limitado à união das telas quando houver telas; tipo `mouseMoved`, `leftMouseDragged` ou `rightMouseDragged`; `mouseEventDeltaX/Y` = diferença arredondada entre destino e partida. 🟢
- RN-IN-05: Cliques são postados na posição de partida, com `mouseEventClickState` informado. 🟢
- RN-IN-06: `pointer.posted` só é registrado quando há origem e `t_arrival`; os ticks de 120 Hz não registram. Cliques sempre têm origem `button`. 🟢
- RN-IN-07: Modificadores têm contagem de referência por tecla (⌃ 59, ⌥ 58, ⇧ 56, ⌘ 55): só a passagem de 0 para 1 posta `flagsChanged` de pressionar e só a de 1 para 0 posta o de soltar; `modifierUp` com contagem zero é ignorado. 🟢
- RN-IN-08: As `flags` de cada evento de tecla e de `flagsChanged` são os modificadores com contagem maior que zero no momento da postagem. 🟢
- RN-IN-09: Acorde: pressiona os modificadores do acorde em ordem ⌃⌥⇧⌘, depois a tecla; solta a tecla, depois os modificadores em ordem inversa. 🟢
- RN-IN-10: Setas (códigos 123 a 126) recebem também `maskNumericPad` e `maskSecondaryFn`. 🟢
- RN-IN-11: Repetição posta só o `keyDown` com `keyboardEventAutorepeat = 1`. 🟢
- RN-IN-12: Texto: para cada unidade UTF-16, um `keyDown` e um `keyUp` com `virtualKey 0`, `keyboardSetUnicodeString` de 1 unidade e `flags` vazias; com `pressEnter`, acorde de Return (36) ao final. 🟢
- RN-IN-13: Soltura forçada (retomada da injeção, `InjectionGate.swift:40-45`, que repete as solturas descartadas durante a revogação): posta o `keyUp` da tecla e o `flagsChanged` de soltar de cada modificador **cuja contagem é zero**. 🟢
- RN-IN-14: Rolagem: `scrollWheelEvent2` com 2 rodas (vertical, horizontal), unidade pixel ou linha; passos (0, 0) não são postados. 🟢
- RN-IN-15: Clique de ativação: `leftMouseDown` e `leftMouseUp` com `clickState 1` no ponto pedido, `mouseMoved` de volta à posição anterior, sem registro; as duas posições entram no acompanhamento. 🟢
- RN-IN-16: Teclas, acordes e textos nunca vão ao log. 🟢
- RN-IN-17: A contagem de modificadores muda mesmo com a injeção desligada, embora nada seja postado. 🟢 (`KeyboardInjector.swift:41-44`, `:96-97`; [Revisor])

## Requisitos Funcionais

| ID | Requisito | Prioridade | Critério de Aceite |
|----|-----------|-----------|-------------------|
| RF-IN-01 | Mover e arrastar conforme RN-IN-03 e RN-IN-04 | Must | Arrastar com R1 seleciona texto no editor |
| RF-IN-02 | Postar cliques com `clickState` | Must | Duplo clique seleciona palavra |
| RF-IN-03 | Postar rolagem em pixel e em linha | Must | `--scroll-unit line` rola por linhas |
| RF-IN-04 | Postar acordes com contagem de modificadores | Must | Options (⌘) segurado + → envia ⌘Tab e ⌘ continua pressionado entre toques |
| RF-IN-05 | Postar setas com as máscaras de teclado físico | Must | L2 + ← troca de mesa |
| RF-IN-06 | Digitar texto independente do layout | Must | "CONTINUAR" chega igual com layout ABNT2 e US |
| RF-IN-07 | Marcar todos os eventos | Must | A tela de alvos conta só cliques do controle |
| RF-IN-08 | Descartar tudo com a injeção desligada | Must | Revogada a Acessibilidade, nenhum evento é postado |
| RF-IN-09 | Clique de ativação do editor | Should | Aberto pela paleta, o editor fica em foco e o cursor volta ao lugar |

## Requisitos Não Funcionais

| Tipo | Requisito inferido | Evidência no código | Confiança |
|------|--------------------|---------------------|-----------|
| Performance | Posição acompanhada evita que duas emissões seguidas partam da mesma leitura atrasada | `EventInjector.swift:31-48` | 🟢 |
| Privacidade | Teclas e textos postados sem registro | `EventInjector.swift:134-138`, `KeyboardInjector.swift:79-94` | 🟢 |
| Compatibilidade | Eventos tratados como hardware por qualquer aplicativo | `.cghidEventTap` | 🟢 |
| Segurança | Dependência exclusiva da permissão de Acessibilidade | `permissions.md` §2 | 🟢 |

## Critérios de Aceitação

```gherkin
Dado a injeção ligada, o cursor em (100, 100) e nenhuma emissão recente
Quando move(by: (5, 0), kind: move, origin: touch) é chamado
Então é postado mouseMoved em (105, 100) com mouseEventDeltaX 5 e a marca 0x4A4F5953
E pointer.posted é registrado com kind move e source touch

Dado uma emissão para (105, 100) há 10 ms e o sistema ainda lendo (100, 100), que foi postado antes
Quando move(by: (0, 5)) é chamado
Então a partida é (105, 100) e o destino (105, 105)

Dado uma emissão há 10 ms e o sistema lendo (300, 300), que não foi postado pelo app
Quando move é chamado
Então a partida é (300, 300)

Dado ⌘ mantido por um modificador (contagem 1)
Quando o acorde ⌘Tab é pressionado e solto
Então não há flagsChanged extra; a contagem volta a 1 e ⌘ continua pressionado

Dado a injeção desligada
Quando type("abc") é chamado
Então nenhum evento é postado

Dado o texto "é🙂"
Quando type é chamado
Então são postados 3 pares keyDown/keyUp, um por unidade UTF-16

Dado vertical 0 e horizontal 0
Quando scroll é chamado
Então nada é postado
```

## Prioridade (MoSCoW)

| Requisito | MoSCoW | Justificativa |
|-----------|--------|---------------|
| Movimento, cliques, marca, desligamento | Must | Base de todas as outras units |
| Teclado e texto | Must | Atalhos e paleta dependem |
| Rolagem | Must | Leitura na TV |
| Clique de ativação | Should | Contorno do macOS 26 para o editor |
| Soltura forçada | Should | Só na retomada após revogação |

## Rastreabilidade de Código

| Arquivo | Função / Classe | Cobertura |
|---------|-----------------|-----------|
| `Sources/JoystickAIPoC/Injection/EventInjector.swift` | `EventInjector` | 🟢 |
| `Sources/JoystickAIPoC/Injection/KeyboardInjector.swift` | `KeyboardInjector` | 🟢 |
| `Sources/JoystickAIPoC/Injection/ScrollInjector.swift` | `ScrollInjector` | 🟢 |
