# ADR-012: Gravação por fusão atômica, preservando seções e com cópia .bak

- **Status:** Aceito
- **Data:** 2026-09-14
- **Tipo:** retroativo (reconstruído pelo Detetive em 2026-09-15)

## Contexto

O editor grava um arquivo que o usuário também edita à mão e que contém `pointer`, que o editor não gerencia. O arquivo pode ser um link simbólico (dotfiles) ou estar sintaticamente inválido no momento de salvar.

## Decisão

Resolver até 16 níveis de link, ler a raiz atual, substituir só `shortcuts` e `palette` e gravar com troca atômica no destino, com codificação determinística. Se o arquivo atual tiver erro de sintaxe, pedir confirmação e copiar o conteúdo para `config.json.bak` antes de gravar. Bytes idênticos aos gravados não disparam nova aplicação.

## Alternativas consideradas

Sobrescrever o arquivo inteiro (perde `pointer` e chaves desconhecidas); gravar no próprio link (quebra o dotfile).

## Consequências

🟢 Edição manual e editor convivem. 🟡 A confirmação da cópia grava sem revalidar o rascunho. 🟡 O limite de 1 MiB não é aplicado à leitura feita antes da fusão.

## Evidências

- `ConfigWriter.swift:24-61`
- `ConfigDocument.swift:3-79`
- 003 D-07, D-17, RN-10
