# Apontar, clicar e rolar do sofá

> Gerado pelo Redator em 2026-09-15 · Persona: programador de sofá (`personas.md`) · Jornada: passos 1 e 6 · Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA

## Contexto

O usuário revisa artefatos e código gerados por agentes, a cerca de 3 m da TV, usando o DualSense como mouse. O fluxo reúne as units `entrada-do-controle`, `ponteiro` e `injecao-de-eventos`, com o portão de permissão da unit `aplicativo`. 🟢

## Histórias

### US-AP-01, Conectar e usar sem configurar

**Como** programador de sofá, **quero** que o controle funcione assim que conectado, por USB ou Bluetooth, **para** não precisar voltar à mesa. 🟢

```gherkin
Dado o app aberto com a Acessibilidade concedida
Quando um DualSense é pareado por Bluetooth
Então controller.connected é registrado, o modo estendido é pedido e o touchpad passa a mover o cursor

Dado um DualSense ativo
Quando um segundo controle se conecta
Então o segundo fica em fila (controller.queued) e não move o cursor
```

Units: `entrada-do-controle` (RN-EC-01 a RN-EC-12), `aplicativo`. 🟢

### US-AP-02, Mover o cursor com precisão

**Como** programador de sofá, **quero** mover o cursor pelo touchpad e pelo analógico esquerdo, com um modo de precisão, **para** acertar botões pequenos na TV. 🟢

```gherkin
Dado o controle ativo
Quando o dedo desliza no touchpad
Então o cursor acompanha o deslize, sem salto ao pousar o dedo

Dado o analógico esquerdo inclinado
Quando L1 é segurado sozinho
Então a velocidade é multiplicada por precisionFactor (0,3 por padrão)

Dado o analógico direito inclinado
Quando L1 é segurado sozinho
Então a rolagem é multiplicada por precisionFactor, como o cursor
```

Units: `ponteiro` (RN-PT sobre cinemática, toque e precisão), `injecao-de-eventos` (RN-IN-03, RN-IN-04). 🟢

### US-AP-03, Clicar, arrastar e dar duplo clique

**Como** programador de sofá, **quero** clicar com R1 e com o clique do touchpad (esquerdo) e com R2 (direito), arrastar e dar duplo clique, **para** operar qualquer aplicativo. 🟢

```gherkin
Dado o cursor sobre uma palavra no VS Code
Quando R1 é pressionado duas vezes dentro de 400 ms e perto do primeiro clique
Então a palavra é selecionada

Dado R1 segurado
Quando o cursor se move
Então é postado leftMouseDragged e o texto é selecionado
```

Units: `ponteiro` (`ClickStateMachine`, `ButtonActions`), `injecao-de-eventos`. 🟢

### US-AP-04, Rolar documentos

**Como** programador de sofá, **quero** rolar com o analógico direito, **para** ler specs longas. 🟢

```gherkin
Dado um documento aberto
Quando o analógico direito é inclinado para baixo
Então o conteúdo rola imediatamente e continua rolando enquanto inclinado
```

Units: `ponteiro` (`ScrollMapper`, `MotionLoop`), `injecao-de-eventos` (RN-IN-14). 🟢

### US-AP-05, Não perder o controle do Mac

**Como** programador de sofá, **quero** que nenhum botão de mouse fique preso quando o controle desconecta, o app fecha ou a permissão é revogada, **para** não precisar do mouse físico para destravar. 🟢

```gherkin
Dado R1 segurado durante um arraste
Quando o controle desconecta
Então o botão esquerdo é solto

Dado R1 segurado
Quando a Acessibilidade é revogada e depois concedida
Então pointer.injection_suspended e pointer.injection_resumed são registrados e o botão é solto na retomada
```

Units: `aplicativo` (`InjectionGate`, `Lifecycle`), `ponteiro`. 🟢

## Pendências

- 🟢 Precisão na tela de alvos, latência de entrada ao movimento e CPU em movimento ainda sem medição, com execução planejada (L-03 respondida; `tela-de-alvos-e-analise`).
