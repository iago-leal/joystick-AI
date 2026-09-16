# Interface: Atalho e Teclado de Acessibilidade do macOS

> Identificador: `006-teclado-virtual`
> Data: `2026-09-16`
> Tipo: integração com o sistema operacional (preferência lida, acorde e cliques postados)
> Roadmap: `_reversa_forward/006-teclado-virtual/roadmap.md` (D-01, D-02, D-03)
> Confidência: 🟢 salvo indicação

## 1. Participantes

| Parte | Papel |
|-------|-------|
| joystick-AI (`ShortcutActions`, `KeyboardInjector`, `EventInjector`) | Lê o acorde, posta o acorde no pressionar e na soltura do botão, posta os cliques do ponteiro |
| Preferências `com.apple.symbolichotkeys` | Fonte do acorde do Atalho de Acessibilidade, entrada `162` |
| Atalho de Acessibilidade do macOS | Recebe o acorde e alterna o recurso marcado, ou exibe o painel de escolha 🟡 |
| Teclado de Acessibilidade | Painel que recebe os cliques do ponteiro e digita no aplicativo em foco 🟡 |
| Usuário | Mantém os pré-requisitos nos Ajustes do Sistema |

## 2. Leitura do acorde

| Item | Valor |
|------|-------|
| Momento | No pressionar do botão, em `ShortcutActions.currentChord(for: .accessibilityShortcut)` (RN-AT-10) |
| Fonte | `CFPreferencesCopyAppValue("AppleSymbolicHotKeys", "com.apple.symbolichotkeys")["162"]` |
| Formato | `{ enabled: Bool, value: { type: "standard", parameters: [caractere, teclaVirtual, máscara] } }` |
| Conversão | `parameters[1]` é a tecla virtual; máscara `0x20000` ⇧, `0x40000` ⌃, `0x80000` ⌥, `0x100000` ⌘ (RN-AT-11); outros bits ignorados |
| Padrão | ⌥⌘F5 (`0x60`, ⌥⌘), usado com entrada ausente, desativada ou malformada (RN-AT-22) |
| Observado em 2026-09-16 | `enabled = 1`, `parameters = (65535, 96, 1572864)` → ⌥⌘F5 |

## 3. Envio

| Fase | Eventos postados |
|------|------------------|
| Pressionar o botão | `flagsChanged` de ⌥ e ⌘, na ordem ⌃⌥⇧⌘, e `keyDown` de F5 com as `flags` mantidas (RN-IN-09); só com D-03, a tecla F5 leva também `maskSecondaryFn` |
| Soltar o botão | `keyUp` de F5 e `flagsChanged` de soltar ⌘ e ⌥, em ordem inversa |
| Desconexão, suspensão ou configuração nova com o botão pressionado | Solturas de RN-AT-14 e RN-AT-15 |

Todos os eventos saem em `.cghidEventTap` com a marca `0x4A4F5953` (RN-IN-01). O acorde nunca vai ao log (RN-AT-17).

## 4. Efeito esperado no sistema 🟡

| Pré-requisito nos Ajustes | Estado do teclado | Efeito de um acionamento |
|---------------------------|-------------------|--------------------------|
| Só o Teclado de Acessibilidade marcado no Atalho de Acessibilidade | oculto | exibe o teclado |
| Só o Teclado de Acessibilidade marcado | visível | oculta o teclado |
| Mais de um recurso marcado | qualquer | exibe o painel de atalhos de acessibilidade; escolher o teclado nele com o ponteiro o alterna (passo extra, RN-02) |
| Atalho "controles de acessibilidade" desativado nos atalhos de teclado | qualquer | nenhum; o acorde chega ao aplicativo em foco |

Os cliques de R1 e do touchpad sobre as teclas são cliques esquerdos comuns (003 RN-05; RN-IN-05); o teclado digita no aplicativo em foco, sem ativá-lo.

## 5. Erros e ausência de retorno

- O sistema não devolve confirmação. O app não sabe se o teclado está visível e não tenta descobrir (roadmap D-05).
- Atalho desativado, recurso não marcado ou acorde ignorado resultam em nada visível; o app segue operando, sem erro e sem tecla presa.
- Não há evento de log específico; o diagnóstico usa `shortcut.triggered` com `type: systemShortcut` e o roteiro do `onboarding.md`.

## 6. Idempotência e concorrência

- **Não idempotente:** cada acionamento alterna. Dois acionamentos seguidos exibem e ocultam o teclado.
- Pressionar o botão já pressionado não produz nada (RN-AT-06); a ação é decidida no pressionar e mantida até soltar (RN-AT-05).
- Com a paleta aberta ou no modo de identificação do editor, o botão não chega aos atalhos (RN-AT-13).

## 7. Tempos

| Item | Limite |
|------|--------|
| Do pressionar ao teclado visível ou oculto | até 1 s (RNF de desempenho), medido no PM-0 🟡 |
| Leitura das preferências | síncrona no pressionar, como nos cinco atalhos existentes |

## 8. Segurança e privacidade

- Nenhuma permissão além da Acessibilidade já concedida; nenhuma escrita em preferências do sistema (RN-08).
- O texto digitado no teclado vai do sistema ao aplicativo em foco sem passar pelo app; o app só vê os próprios cliques, registrados em `pointer.posted` sem coordenadas (001 RN-12).
