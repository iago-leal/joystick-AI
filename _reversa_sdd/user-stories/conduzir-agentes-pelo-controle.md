# Conduzir agentes pelo controle

> Gerado pelo Redator em 2026-09-15 · Persona: programador de sofá (`personas.md`) · Jornada: passos 3, 4, 5 e 7 · Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA

## Contexto

O fluxo com Claude Code e Reversa é feito de interações discretas: comandos com barra, `CONTINUAR`, menus de opção e aprovações. O fluxo reúne as units `atalhos`, `paleta` e `injecao-de-eventos`. 🟢

## Histórias

### US-AG-01, Responder menus e aprovações

**Como** programador de sofá, **quero** usar o direcional, ✕ e ○ como setas, Enter e Esc, **para** escolher opções e aprovar permissões do Claude Code. 🟢

```gherkin
Dado um menu de escolha do Claude Code no Terminal
Quando ↓ é pressionado duas vezes e ✕ em seguida
Então a terceira opção é confirmada

Dado ↓ segurado
Quando passam 400 ms
Então a seta passa a repetir a cada 50 ms
```

Units: `atalhos` (RN-AT-19, RN-AT-09). 🟢

### US-AG-02, Enviar CONTINUAR com um gesto

**Como** programador de sofá, **quero** enviar `CONTINUAR` com Enter por uma combinação, **para** avançar o Reversa sem abrir menus. 🟢

```gherkin
Dado o Reversa aguardando CONTINUAR no terminal em foco
Quando L1 é segurado e ✕ é pressionado
Então "CONTINUAR" é digitado e Enter é enviado
```

Units: `atalhos` (camada L1), `injecao-de-eventos` (RN-IN-12). 🟢

### US-AG-03, Escolher um comando na paleta

**Como** programador de sofá, **quero** abrir uma lista de comandos com PS e confirmar com ✕, **para** enviar comandos com barra sem digitar. 🟢

```gherkin
Dado o Terminal em foco
Quando PS abre a paleta, ↓ chega a "/reversa-coding" e ✕ confirma
Então "/reversa-coding" é digitado na linha do Terminal, sem Enter
E o Terminal continua em foco

Dado a paleta aberta
Quando ○ é pressionado
Então a paleta fecha sem digitar nada
```

Units: `paleta` (RN-PA-01 a RN-PA-13), `atalhos` (`openPalette`). 🟢

### US-AG-04, Ditar prompts

**Como** programador de sofá, **quero** ditar prompts por um botão, **para** descrever pedidos longos sem teclado. 🟢

```gherkin
Dado o transcritor do Raycast configurado com ⌘M
Quando R3 é pressionado
Então ⌘M é enviado e o Raycast inicia a transcrição no campo em foco
```

Units: `atalhos` (R3 → ⌘M). O app não tem componente próprio de ditado, por decisão (RN-AT-21); o comportamento depende do atalho do transcritor configurado no Raycast. 🟢

### US-AG-05, Trocar de janela, aplicativo e mesa

**Como** programador de sofá, **quero** alternar aplicativos, janelas e mesas pelo controle, **para** ir do terminal ao navegador e ao VS Code. 🟢

```gherkin
Dado dois aplicativos abertos
Quando Options é segurado e → é pressionado duas vezes
Então ⌘Tab alterna dois aplicativos sem soltar ⌘ entre os toques

Dado Mission Control remapeado nas preferências do macOS
Quando Create é pressionado
Então o acorde remapeado é usado
```

Units: `atalhos` (camadas Options e L2, RN-AT-10). 🟢 Atalho de sistema desativado posta o acorde padrão, comportamento aceito (RN-AT-22). 🟢

## Pendências

- 🟢 L-01 fechada: o ditado de prompts é o atalho R3 → ⌘M do Raycast (RN-AT-21).
- 🟢 Abrir o VS Code por um botão (jornada, passo 2) está adiado para o *backlog* do editor; não há ação `openApp`.
