# Fluxogramas — `targets-analysis`

> Gerado pelo Arqueólogo em 2026-09-15. Fonte: `TargetSession.swift`, `TargetAbortMonitor.swift`, `TargetRunWriter.swift`, `TargetRun.swift`, `Sources/poc-tools/`. 🟢

## 1. Sessão da tela de alvos

```mermaid
flowchart TD
    A([start]) --> B[20 posições por SplitMix64 com a semente]
    B --> C[Janela sem borda na tela escolhida; monitor local de clique e tecla]
    C --> D[activate; targets.started]
    D --> E[Mostra alvo N; guarda instante]
    E --> F{Evento}
    F -- Esc --> G[abort user]
    F -- "clique na janela" --> H{Marca do injetor?}
    H -- não --> I[ignoredPhysicalClicks + 1] --> F
    H -- sim --> J[acerto = ponto dentro do alvo; tempo; L1 pressionado]
    J --> K{20 tentativas?}
    K -- não --> E
    K -- sim --> L[finish complete]
    M([○ no controle, tela removida ou injeção suspensa]) --> G
    G --> N[finish incompleta]
    L --> O[Resumo na tela por 3 s]
    O --> P[TargetRunWriter.write]
    N --> P
    P --> Q[Fecha janela; desbloqueia paleta]
```

## 2. Gravação do resultado

```mermaid
flowchart TD
    A([write run]) --> B{Codificou?}
    B -- não --> C([targets.write_failed sem payload])
    B -- sim --> D["Nome AAAAMMDD-HHMMSS-env.json, com sufixo em colisão"]
    D --> E{Gravou sem sobrescrever?}
    E -- sim --> F([targets.finished com caminho])
    E -- não --> G([targets.write_failed com JSON compacto no payload])
```

## 3. `poc-tools`

```mermaid
flowchart TD
    A([poc-tools args]) --> B{Subcomando}
    B -- ausente --> U([uso em stderr; 64])
    B -- "help ou -h" --> H([uso; 0])
    B -- buttons --> R1[readLog]
    B -- latency --> R1
    B -- cycles --> R1
    B -- runs --> R2[--env e --dir]
    B -- desconhecido --> U
    R1 --> C{Um argumento e arquivo legível?}
    C -- "não, uso" --> U
    C -- "não, arquivo" --> N([66])
    C -- sim --> D[Linhas JSONL; malformadas viram aviso]
    D --> E{Qual}
    E -- buttons --> F[Tabela dos 18 botões com down e up não sintéticos]
    E -- latency --> G[p50, p95, máximo; aprovado se p95 ≤ 5 ms e ≤ 20 ms]
    E -- cycles --> I[Ciclos por id, órfãs, sessões]
    R2 --> J{Diretório existe?}
    J -- não --> N
    J -- sim --> K[Decodifica .json; ilegíveis viram aviso]
    K --> L[Tabela Markdown só das completas, por data]
    F --> O([0])
    G --> O
    I --> O
    L --> O
```
