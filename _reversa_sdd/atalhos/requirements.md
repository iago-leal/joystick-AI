# Atalhos (shortcuts)

> Unit do módulo `shortcuts` · Gerado pelo Redator em 2026-09-15 · Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA

## Visão Geral

Converte os botões do controle que não são de apontamento em acordes de teclado, atalhos de sistema do macOS, textos e abertura da paleta, segundo um mapeamento em camadas: uma base e uma camada por botão modificador. A decisão é pura (`ShortcutMapper`, no núcleo); a execução, com repetição e leitura das preferências do sistema, fica no app (`ShortcutActions`). 🟢

## Responsabilidades

- Resolver a ação de cada pressionar na camada vigente, com herança da base. 🟢
- Manter as teclas modificadoras enquanto o botão modificador estiver segurado. 🟢
- Guardar a ação resolvida até o soltar, para soltar exatamente o que foi pressionado. 🟢
- Repetir acordes marcados com repetição (400 ms, depois a cada 50 ms). 🟢
- Ler o acorde dos atalhos de sistema nas preferências do macOS no instante do uso. 🟢
- Soltar tudo em desconexão, encerramento, perda de permissão, modo de identificação, troca de configuração e abertura da paleta. 🟢
- Registrar `shortcut.triggered` sem revelar teclas nem textos. 🟢
- Manter o catálogo fixo de teclas nomeáveis no arquivo. 🟢

## Regras de Negócio

- RN-AT-01: R1, R2 e clique do touchpad nunca produzem ação de atalho nem são modificadores; ficam com os cliques. 🟢
- RN-AT-02: Botão declarado em `modifiers` é modificador: ao pressionar, entra no fim da ordem de modificadores e pressiona suas teclas (em ordem ⌃⌥⇧⌘); ao soltar, sai da ordem e solta as mesmas teclas. Modificador com lista vazia (L1, L2 no padrão) só define camada. 🟢
- RN-AT-03: A camada vigente é a do modificador segurado há mais tempo; sem modificador, a base. 🟢
- RN-AT-04: Ação na camada: própria, se existir; senão a da base; senão "nenhuma". "Nenhuma" declarada na camada bloqueia a herança. 🟢
- RN-AT-05: A ação é decidida no pressionar e mantida até o soltar do mesmo botão, ainda que o modificador seja solto antes. 🟢
- RN-AT-06: Pressionar um botão já pressionado não produz nada. 🟢
- RN-AT-07: Tipos de ação: `chord` (tecla do catálogo, modificadores, repetição opcional), `systemShortcut` (5 atalhos), `text` (uma linha, 1 a 1.000 caracteres, Enter opcional), `openPalette` e `none`. 🟢
- RN-AT-08: `chord` e `systemShortcut` pressionam no pressionar e soltam no soltar; `text` e `openPalette` agem só no pressionar. 🟢
- RN-AT-09: Repetição: 400 ms após o pressionar e depois a cada 50 ms, com `keyboardEventAutorepeat`; só um acorde repete por vez, e um novo acorde com repetição encerra a do anterior. 🟢
- RN-AT-10: Atalho de sistema: o acorde vem de `com.apple.symbolichotkeys` → `AppleSymbolicHotKeys` (IDs 27, 32, 33, 79 e 81) no instante do pressionar; entrada ausente, **desativada** ou malformada usa o acorde padrão. O acorde pressionado é guardado e é ele que se solta. 🟢
- RN-AT-11: Máscara das preferências: `0x20000` ⇧, `0x40000` ⌃, `0x80000` ⌥, `0x100000` ⌘; a tecla virtual é `parameters[1]`. 🟢
- RN-AT-12: `openPalette` solta antes tudo o que os atalhos mantêm e só então abre a paleta. 🟢
- RN-AT-13: Com a paleta aberta, os botões vão à paleta e não aos atalhos; no modo de identificação do editor, nenhum botão chega aos atalhos. 🟢
- RN-AT-14: Soltar tudo: primeiro as ações guardadas, na ordem de `ButtonID`; depois as teclas de cada modificador, do mais antigo ao mais recente; o estado é zerado. 🟢
- RN-AT-15: Na suspensão da injeção, as solturas feitas são guardadas (atalho de sistema convertido no acorde efetivamente pressionado) e repetidas à força na retomada. 🟢
- RN-AT-16: Configuração nova: interrompe a repetição, solta tudo e recria o mapeador; botões segurados durante a troca são ignorados até serem soltos. 🟢
- RN-AT-17: `shortcut.triggered { button, layer, type }` é registrado a cada pressionar com ação diferente de "nenhuma"; `layer` é `base` ou o nome do botão. Nunca registra tecla, acorde, texto nem rótulo. 🟢
- RN-AT-18: O catálogo tem 73 teclas com nome estável (26 letras, 10 dígitos, 11 pontuações, 6 de edição, 8 de navegação, F1 a F12); tecla fora do catálogo não pode ser gravada. As teclas virtuais são posições físicas, independentes do layout. 🟢
- RN-AT-19: Mapeamento padrão (sem arquivo ou sem a seção `shortcuts`), idêntico ao protótipo da feature 001 com PS abrindo a paleta:

| Camada | Botão | Ação |
|--------|-------|------|
| base | ↑ ↓ ← → | setas, com repetição |
| base | ✕ / ○ / □ / △ | Return / Esc / Delete com repetição / Tab |
| base | Create | Mission Control (sistema) |
| base | R3 | ⌘M (transcritor do Raycast) |
| base | PS | abrir paleta |
| base | L3 | nenhuma |
| L1 (sem teclas) | ✕ / △ | texto "CONTINUAR" + Enter / ⇧Tab |
| L2 (sem teclas) | ← / → / ↓ / ↑ / △ | mesa à esquerda / mesa à direita / janelas do aplicativo / Mission Control / próxima janela |
| Options (⌘) | → / ← | ⌘Tab / ⌘⇧Tab; todos os demais botões "nenhuma" |

🟢

- RN-AT-20: Acordes padrão dos atalhos de sistema: próxima janela ⌘\`, Mission Control ⌃↑, janelas do aplicativo ⌃↓, mesa à esquerda ⌃←, mesa à direita ⌃→. 🟢
- RN-AT-21: O ditado de prompts é feito pelo transcritor do Raycast, acionado por R3 com ⌘M; não há componente próprio de ditado, e o modo segurar para falar de `sdd/voice-dictation.md` está superado. 🟢 (decisão do usuário em 2026-09-15, `questions.md` Pergunta 1)
- RN-AT-22: Atalho de sistema desativado nas preferências posta mesmo assim o acorde padrão; é comportamento aceito. 🟢 (respondida em 2026-09-15, `questions.md` Pergunta 4)

## Requisitos Funcionais

| ID | Requisito | Prioridade | Critério de Aceite |
|----|-----------|-----------|-------------------|
| RF-AT-01 | Resolver ações por camada com herança | Must | L1 + △ envia ⇧Tab; L1 + ○ envia Esc (herdado) |
| RF-AT-02 | Manter modificadores durante o botão | Must | Options + → + → alterna dois aplicativos sem soltar ⌘ |
| RF-AT-03 | Repetir acordes marcados | Must | ↓ segurado desce várias linhas no editor de texto |
| RF-AT-04 | Usar o acorde atual dos atalhos de sistema | Must | Mission Control remapeado nas preferências é respeitado sem reiniciar o app |
| RF-AT-05 | Digitar textos configurados | Must | L1 + ✕ digita "CONTINUAR" e envia |
| RF-AT-06 | Abrir a paleta sem deixar tecla presa | Must | Com L2 + → segurados (⌃→ pressionado), PS abre a paleta e ⌃→ é solto antes |
| RF-AT-07 | Soltar tudo nos eventos de ruptura | Must | Desconectar com Options segurado não deixa ⌘ pressionado |
| RF-AT-08 | Aplicar configuração nova sem reiniciar | Must | Gravar no editor muda a ação no pressionar seguinte |
| RF-AT-09 | Registrar gatilhos sem conteúdo | Should | O log mostra `button`, `layer` e `type`, e nunca a tecla |

## Requisitos Não Funcionais

| Tipo | Requisito inferido | Evidência no código | Confiança |
|------|--------------------|---------------------|-----------|
| Privacidade | Log sem teclas, acordes ou textos | `LogEventCatalog.swift:257-305` | 🟢 |
| Testabilidade | Decisão pura em `struct` de valor, testada com sequências aleatórias | `ShortcutMapperTests.swift:226` | 🟢 |
| Compatibilidade | Acordes por tecla virtual; textos por Unicode | `KeyCatalog.swift:12`, `KeyboardInjector.type` | 🟢 |
| Robustez | Nenhuma tecla presa após ruptura | `ShortcutMapper.releaseAll`, `InjectionGate.swift:40-51` | 🟢 |

## Critérios de Aceitação

```gherkin
Dado o mapeamento padrão e nenhum botão pressionado
Quando L2 é pressionado e ← é pressionado
Então é pressionado o acorde de "mesa à esquerda" lido das preferências
E shortcut.triggered registra button dpadLeft, layer l2, type systemShortcut

Dado L2 pressionado e ← pressionado
Quando L2 é solto antes de ←
Então nada é postado ao soltar L2
E ao soltar ← é solto o mesmo acorde pressionado

Dado L1 pressionado antes de L2
Quando △ é pressionado
Então vale a camada L1 e é enviado ⇧Tab

Dado a camada Options com ✕ = nenhuma
Quando Options e ✕ são pressionados
Então só ⌘ é pressionado e não há shortcut.triggered para ✕

Dado ↓ pressionado com repetição
Quando passam 500 ms
Então houve um keyDown inicial e ao menos duas repetições com autorepeat

Dado L2 e → segurados, com o acorde de "mesa à direita" pressionado
Quando PS é pressionado (herdado da base na camada L2)
Então o acorde é solto antes de a paleta abrir
E soltar → e L2 depois não posta nada

Dado Options segurado (⌘ pressionado)
Quando PS é pressionado
Então nada acontece, pois a camada Options declara PS como "nenhuma"

Dado Mission Control desativado nas preferências
Quando Create é pressionado
Então é postado ⌃↑ (padrão)
```

## Prioridade (MoSCoW)

| Requisito | MoSCoW | Justificativa |
|-----------|--------|---------------|
| Camadas, herança e modificadores | Must | Núcleo da feature 003 |
| Solturas em ruptura | Must | Tecla presa inutiliza o Mac |
| Atalhos de sistema pelas preferências | Must | Respeita remapeamentos do usuário |
| Repetição | Must | Navegação por setas |
| Log de gatilhos | Should | Diagnóstico |
| Ditado por componente próprio (segurar para falar) | Won't | Superado pelo atalho R3 → ⌘M do transcritor do Raycast (decisão de 2026-09-15) 🟢 |
| Abrir aplicativo (`openApp`), toque curto e longo (`tap`, `longPress`) | Won't (nesta versão) | Previstos em `sdd/action-mapping.md`, adiados para o *backlog* do editor (`_reversa_forward/002-paleta-comandos/requirements.md:241`, `003-editor-atalhos/data-delta.md:135`) 🟢 |

## Rastreabilidade de Código

| Arquivo | Função / Classe | Cobertura |
|---------|-----------------|-----------|
| `Sources/JoystickCore/Shortcuts/ShortcutMapper.swift` | `KeyModifier`, `KeyChord`, `SystemShortcut`, `ShortcutAction`, `ShortcutMapper` | 🟢 |
| `Sources/JoystickCore/Shortcuts/KeyCatalog.swift` | `KeyGroup`, `KeyEntry`, `KeyCatalog` | 🟢 |
| `Sources/JoystickCore/Shortcuts/KeyRepeat.swift` | `KeyRepeat` | 🟢 |
| `Sources/JoystickCore/Config/ShortcutConfig.swift` | `TriggerActionType`, `TriggerAction`, `ShortcutConfig.resolvedAction` | 🟢 |
| `Sources/JoystickCore/Config/ShortcutDefaults.swift` | `ShortcutDefaults` | 🟢 |
| `Sources/JoystickAIPoC/Pointer/ShortcutActions.swift` | `ShortcutActions` | 🟢 |
