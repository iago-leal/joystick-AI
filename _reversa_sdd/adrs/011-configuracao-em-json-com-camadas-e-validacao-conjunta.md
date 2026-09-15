# ADR-011: Configuração em JSON com camadas por modificador e validação conjunta

- **Status:** Aceito
- **Data:** 2026-09-14
- **Tipo:** retroativo (reconstruído pelo Detetive em 2026-09-15)

## Contexto

O mapeamento fixo do protótipo precisava virar configurável, editável tanto à mão quanto pelo editor, sem que um erro deixe o controle inutilizável.

## Decisão

Seções `shortcuts` (`version`, `modifiers`, `layers`) e `palette` (`version`, `items`) ao lado de `pointer` em `~/.config/joystick-ai/config.json`. Qualquer botão não de apontamento pode ser modificador, com teclas ⌃⌥⇧⌘; camadas herdam da base; a ação é resolvida no pressionar pela camada do modificador mais antigo. Mapeamento e paleta são validados juntos, e uma configuração inválida nunca substitui a vigente; cada problema recebe a linha por um localizador léxico próprio. O arquivo é observado e relido sem reiniciar.

## Alternativas consideradas

Arquivos separados para atalhos e paleta (validação cruzada mais difícil); camada combinada para vários modificadores (explosão de combinações); `plist` (menos amigável à edição manual).

## Consequências

🟢 Erros apontam linha e regra sem expor valores. 🟢 Releitura automática com agregação de 150 ms. 🟡 `pointer` continua lido só no início.

## Evidências

- `ShortcutConfig.swift`
- `ShortcutConfigValidation.swift`
- `ConfigLineLocator.swift`
- `ConfigStore.swift`
- 003 D-01, D-05, D-06, D-09, D-15, D-16, RN-08
