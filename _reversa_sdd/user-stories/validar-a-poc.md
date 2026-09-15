# Validar a PoC

> Gerado pelo Redator em 2026-09-15 · Persona: programador de sofá, no papel de avaliador da PoC · Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA

## Contexto

As features do ciclo forward fecham com portões manuais que exigem números: cobertura dos 18 botões, precisão em mesa e sofá, latências e robustez em ciclos de conexão. O fluxo reúne as units `tela-de-alvos-e-analise`, `log-de-diagnostico` e `aplicativo` (argumentos de abertura). 🟢

## Histórias

### US-VA-01, Registrar uma sessão para análise

**Como** avaliador, **quero** abrir o app com `--debug` e obter um log JSONL com carimbos monotônicos, **para** medir sem expor o que foi digitado. 🟢

```gherkin
Dado o app aberto com --debug
Quando os 18 botões são pressionados e soltos
Então poc-tools buttons <log> mostra "Total: 18 de 18."
E o log não contém coordenadas, teclas nem textos
```

Units: `log-de-diagnostico` (RN-LG-01 a RN-LG-14), `tela-de-alvos-e-analise` (RN-TA-21). 🟢

### US-VA-02, Medir a precisão do ponteiro

**Como** avaliador, **quero** acertar 20 alvos de 16 pt com posições reproduzíveis, na mesa e no sofá, **para** comparar ajustes do ponteiro. 🟢

```gherkin
Dado o app aberto com --targets --env sofa --seed 42
Quando os 20 alvos são clicados com R1
Então um arquivo em target-runs registra acertos, tempos, uso de L1 e os parâmetros vigentes
E poc-tools runs --env sofa imprime a linha da sequência
```

Units: `tela-de-alvos-e-analise` (RN-TA-01 a RN-TA-17, RN-TA-24). Nenhuma sequência gravada até agora; execução planejada (L-03). 🟢

### US-VA-03, Medir latências

**Como** avaliador, **quero** p50, p95 e máximo do processamento e da entrada ao movimento, **para** verificar as metas de 5 ms e 20 ms. 🟢

```gherkin
Dado um log --debug com movimento pelo touchpad e pelo analógico
Quando poc-tools latency <log> é executado
Então a tabela mostra as duas medidas com aprovação pelo p95
```

Units: `tela-de-alvos-e-analise` (RN-TA-23). Processamento medido (p95 0,110 ms); entrada ao movimento pendente, com medição planejada (L-03). 🟢

### US-VA-04, Verificar robustez de conexão

**Como** avaliador, **quero** contar ciclos de conexão e reinícios num log, **para** confirmar 100 ciclos sem reiniciar o app. 🟢

```gherkin
Dado um log com 100 conexões e desconexões do mesmo controle
Quando poc-tools cycles <log> é executado
Então mostra 100 ciclos completos e 1 sessão
```

Units: `tela-de-alvos-e-analise` (RN-TA-22). Execução pendente e planejada (L-03). 🟢

## Pendências

- 🟢 L-03 respondida: tela de alvos, latência de entrada ao movimento, CPU em movimento e 100 ciclos do PM-3 da 001 continuam planejados.
