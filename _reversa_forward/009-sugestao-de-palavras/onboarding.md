# Onboarding: Sugestão de palavras no teclado remoto

> Identificador: `009-sugestao-de-palavras`
> Data: `2026-09-19`
> Para: quem vai testar a feature pela primeira vez, com o teclado remoto da 008 já pareado no iPhone

## 1. Preparar

1. Confira que o teclado remoto da 008 funciona: o iPhone abre a página pela Tela de Início e digita no Mac.
2. Compile e instale: `JOYSTICK_SIGN_IDENTITY="JoystickAI Local Signing" ./scripts/build-app.sh` e `./scripts/check-signature.sh`.
3. Abra o app, ligue "Teclado remoto" no menu e reabra a página no iPhone, para carregar a versão nova.
4. Deixe ativas no Mac as fontes de entrada Português e EUA Internacional.

## 2. PM-0: sondas de plataforma

Registre o resultado de cada sonda com data. Os métodos e critérios estão em `investigation.md` §5.

| Sonda | Resultado | Data |
|-------|-----------|------|
| P-01 entrada segura | Aprovada, relatada pelo usuário | 2026-09-19 |
| P-02 tradução com tecla morta | Aprovada, relatada pelo usuário | 2026-09-19 |
| P-03 inserção nos terminais | Aprovada, relatada pelo usuário | 2026-09-19 |
| P-04 altura da barra | Aprovada, relatada pelo usuário | 2026-09-19 |

## 3. PM-1: roteiro da feature

Com o iPhone preso ao controle, na horizontal, e o TextEdit ou o terminal em foco no Mac:

| # | Passo | Esperado | Cenário do `requirements.md` §7 |
|---|-------|----------|--------------------------------|
| 1 | Com PT selecionado, digitar "vamos impl" | Até três sugestões iniciadas por "impl", como "implementar", sem o próprio "impl" | Sugestões enquanto digita |
| 2 | Tocar apagar uma vez | Sugestões iniciadas por "imp" | Apagar atualiza as sugestões |
| 3 | Numa linha nova, com a fonte Português, digitar "funç" e tocar em "função" | "função " no lugar de "funç" | Completar com acento e espaço |
| 4 | Digitar "Impl" e tocar numa sugestão | Palavra escrita com "I" maiúsculo | Caixa da primeira letra |
| 5 | Digitar "vamos impl" e tocar em "implementar" | "implementar " com minúscula | Minúscula mantida |
| 6 | Digitar "Olá, tudo " | Previsões como "bem" antes de qualquer letra | Previsão da palavra seguinte |
| 7 | Tocar EN, digitar "refac"; depois fechar e reabrir a página | "refactor" na faixa; o seletor continua em EN | Troca de idioma |
| 8 | No terminal, digitar "cd ~/dev/joy" | Faixa vazia a partir do "~"; nenhum espaço extra | Caminho no terminal |
| 9 | No terminal, digitar "ls -la" | Faixa vazia enquanto a palavra é "-la" | Opção de comando |
| 10 | Digitar "exe", tocar ←; repetir com um clique do controle no texto | Faixa vazia; a letra seguinte começa palavra nova | Ponto de escrita movido |
| 11 | Digitar "rev" no editor e trocar para o terminal | Faixa vazia | Troca de aplicativo |
| 12 | Num campo de senha do Safari, digitar "abc" | Faixa sempre vazia | Campo de senha |
| 13 | Tocar ocultar, digitar "funç"; tocar de novo | Nenhuma sugestão com a faixa oculta; a faixa volta | Faixa oculta |
| 14 | Com "funç" digitado, revogar a Acessibilidade e tocar numa sugestão | Nada escrito; página mostra "sem permissão"; religar a permissão ao fim | Sugestão sem permissão de Acessibilidade |
| 15 | Digitar rápido "implementação" letra a letra, observando a faixa | A faixa esmaece a cada letra e nunca mostra sugestões de um prefixo já ultrapassado | Sugestão obsoleta |
| 16 | Digitar "xqzw" | Faixa vazia; as teclas continuam chegando | Sem sugestão |
| 17 | Com a faixa vazia, tocar nela | Nada acontece no Mac | Toque fora das sugestões |
| 18 | Aceitar 3 sugestões, sair pela página e abrir o log | `remote.disconnected` com `suggestions: 3` e nenhuma palavra | Log sem conteúdo |

Registre aprovado ou reprovado por passo, com observações, nesta seção.

### Resultado do PM-1

| # | Resultado | Data | Observações |
|---|-----------|------|-------------|
| 1 | Aprovado | 2026-09-19 | Relatado pelo usuário |
| 2 | Aprovado | 2026-09-19 | Relatado pelo usuário |
| 3 | Aprovado | 2026-09-19 | Relatado pelo usuário |
| 4 | Aprovado | 2026-09-19 | Relatado pelo usuário |
| 5 | Aprovado | 2026-09-19 | Relatado pelo usuário |
| 6 | Aprovado | 2026-09-19 | Relatado pelo usuário |
| 7 | Aprovado | 2026-09-19 | Relatado pelo usuário |
| 8 | Aprovado | 2026-09-19 | Relatado pelo usuário |
| 9 | Aprovado | 2026-09-19 | Relatado pelo usuário |
| 10 | Aprovado | 2026-09-19 | Relatado pelo usuário |
| 11 | Aprovado | 2026-09-19 | Relatado pelo usuário |
| 12 | Aprovado | 2026-09-19 | Relatado pelo usuário |
| 13 | Aprovado | 2026-09-19 | Relatado pelo usuário |
| 14 | Não executado | 2026-09-19 | Por escolha do usuário, que não quis revogar a Acessibilidade. A recusa do `pick` com o portão fechado está no código (`RemoteKeyboardActions.pick`), sem verificação no aparelho |
| 15 | Aprovado | 2026-09-19 | Relatado pelo usuário |
| 16 | Aprovado | 2026-09-19 | Relatado pelo usuário |
| 17 | Aprovado | 2026-09-19 | Relatado pelo usuário |
| 18 | Aprovado | 2026-09-19 | Saída pela página às 18h58: `remote.disconnected` com `reason: bye`, `keys: 140` e `suggestions: 19`, contagem da sessão inteira do roteiro, e não só de 3 aceitações; nenhum campo com palavra, contexto, revisão ou idioma no log |
