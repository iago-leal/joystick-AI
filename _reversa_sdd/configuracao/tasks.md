# Configuração (config), Tarefas de Implementação

> Gerado pelo Redator em 2026-09-15 · Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA

## Pré-requisitos

- [ ] `JSONValue` e catálogo de eventos (unit `log-de-diagnostico`)
- [ ] `PointerSettings` com faixas (unit `ponteiro`)
- [ ] Tipos de atalho, catálogo de teclas e padrões (unit `atalhos`)
- [ ] `PaletteItem` e `PaletteDefaults` (unit `paleta`)

## Tarefas

- [ ] T-01, Implementar `PointerSettingsValidation` e `ConfigIssue`
  - Origem no legado: `Sources/JoystickCore/Config/PointerSettingsValidation.swift`
  - Critério de pronto: `PointerSettingsValidationTests` (8); `null` ignorado; inteiro exigido em `doubleClickIntervalMs`
  - Confiança: 🟢

- [ ] T-02, Implementar `ShortcutsDocument`, `ShortcutIssue` e `ShortcutConfigValidation` (decodificação e semântica)
  - Origem no legado: `Sources/JoystickCore/Config/ShortcutConfig.swift:68-116`, `ShortcutConfigValidation.swift`
  - Critério de pronto: `ShortcutConfigValidationTests` (20); recusa conjunta das duas seções
  - Confiança: 🟢

- [ ] T-03, Implementar `ConfigLineLocator`
  - Origem no legado: `Sources/JoystickCore/Config/ConfigLineLocator.swift`
  - Critério de pronto: `ConfigLineLocatorTests` (7), incluindo escapes, CRLF e ancestral mais próximo
  - Confiança: 🟢

- [ ] T-04, Implementar `ConfigLoader`
  - Origem no legado: `Sources/JoystickCore/Config/ConfigLoader.swift`
  - Critério de pronto: `ConfigLoaderTests` (16): ausente, diretório, grande, sintaxe com linha, raiz não objeto, seções ausentes
  - Confiança: 🟢

- [ ] T-05, Implementar `ConfigDocument` (codificação e fusão determinística)
  - Origem no legado: `Sources/JoystickCore/Config/ConfigDocument.swift`
  - Critério de pronto: `ConfigDocumentTests` (8): ida e volta com `decode`, chaves desconhecidas preservadas, mesmos *bytes*
  - Confiança: 🟢

- [ ] T-06, Implementar `ActionSummary`
  - Origem no legado: `Sources/JoystickCore/Config/ActionSummary.swift`
  - Critério de pronto: `ActionSummaryTests` (5): cliques fixos, modificador, herdado, texto truncado em 24
  - Confiança: 🟢

- [ ] T-07, Implementar `ConfigWriter` (links, `.bak`, fusão, troca atômica)
  - Origem no legado: `Sources/JoystickAIPoC/Config/ConfigWriter.swift`
  - Critério de pronto: gravação preserva *link*; arquivo corrompido pede confirmação e cria `.bak`
  - Confiança: 🟢

- [ ] T-08, Implementar `ConfigStore` (vigente, releitura, gravação, observadores)
  - Origem no legado: `Sources/JoystickAIPoC/Config/ConfigStore.swift`
  - Critério de pronto: arquivo inválido ou removido não altera a vigente; própria gravação não reaplica
  - Confiança: 🟢

- [ ] T-09, Implementar `ConfigWatcher`
  - Origem no legado: `Sources/JoystickAIPoC/Config/ConfigWatcher.swift`
  - Critério de pronto: edição por troca atômica, por escrita no lugar e criação do diretório disparam uma releitura
  - Confiança: 🟢

- [ ] T-10, Ligar no bootstrap: leitura antes do controle, eventos `config.*`, `onApply` na fila `input`, barra de menus
  - Origem no legado: `Sources/JoystickAIPoC/App/AppDelegate.swift:48-55,80-84,103-109`
  - Critério de pronto: ordem paleta → atalhos na aplicação
  - Confiança: 🟢

- [ ] T-11, Corrigir DV-05: `ConfigStore.save` revalida o documento antes de gravar e recusa documento com problemas, com ou sem confirmação do `.bak`
  - Origem no legado: `Sources/JoystickAIPoC/Config/ConfigStore.swift`, `Sources/JoystickAIPoC/Config/ConfigWriter.swift` (defeito, L-02 respondida em 2026-09-15)
  - Critério de pronto: gravar documento inválido após "Copiar e gravar" falha sem criar `.bak` nem alterar `config.json`
  - Confiança: 🟢

## Tarefas de Teste

- [ ] TT-01, Testes do núcleo listados acima (64 no total), mais os 7 de `ShortcutConfigTests`
- [ ] TT-02, Roteiro manual: editar `config.json` com `vim`, VS Code e `echo >`, com o app aberto
- [ ] TT-03, Roteiro manual: `config.json` como *link* para dotfiles, gravar pelo editor
- [ ] TT-04, Roteiro manual: corromper o arquivo, gravar pelo editor com e sem confirmação
- [ ] TT-05, Roteiro manual: apagar o diretório `~/.config/joystick-ai` com o app aberto e recriar

## Ordem Sugerida

1. T-01 a T-06 no núcleo, com testes.
2. T-07 e T-08.
3. T-09 e T-10.

## Lacunas Pendentes (🔴)

Nenhuma. DV-05 foi classificada como defeito em 2026-09-15 e virou T-11.
