# Onboarding: Figura do controle em página web embutida

> Identificador: `004-figura-controle-web`
> Data: `2026-09-15`
> Público: quem vai testar a figura pela primeira vez (o programador de sofá, no papel de avaliador)
> Roadmap: `_reversa_forward/004-figura-controle-web/roadmap.md`

Este roteiro pressupõe o código entregue pelo `/reversa-coding`. Se a implementação alterar nomes de arquivo, eventos ou textos da interface, o `/reversa-coding` deve atualizar este arquivo. Cada passo indica o cenário da seção 7 do `requirements.md` que verifica.

## 0. Pré-requisitos

| Item | Como conferir |
|------|---------------|
| App da feature 003 instalado, assinado com "JoystickAI Local Signing", Acessibilidade e Input Monitoring concedidas | `./scripts/check-signature.sh`; log com `permissions.status` e `postEvent: true` |
| Configuração padrão de atalhos e paleta | No editor, "Restaurar padrão", ou remover as seções `shortcuts` e `palette` do arquivo |
| Mac ligado à TV, sofá a cerca de 3 m, DualSense conectado | O ponteiro se move com o analógico esquerdo |
| Teclado físico ao alcance | Só para o cenário de gravação de acorde do passo 2.14 |
| Rede desligável | Wi-Fi e cabo, para o cenário "Sem rede" |

Antes de tudo, guarde a configuração atual e a saída da assinatura, que servem de comparação:

```sh
cp ~/.config/joystick-ai/config.json ~/.config/joystick-ai/config.pre-004.json
./scripts/check-signature.sh > /tmp/signature-pre-004.txt
ls ~/Library/WebKit 2>/dev/null
```

Comandos úteis:

```sh
# compilar, assinar e instalar
JOYSTICK_SIGN_IDENTITY="JoystickAI Local Signing" ./scripts/build-app.sh
# conferir o bundle
ls -R ~/Applications/JoystickAIPoC.app/Contents/Resources/ControllerFigure
codesign --verify --strict --verbose=2 ~/Applications/JoystickAIPoC.app
diff /tmp/signature-pre-004.txt <(./scripts/check-signature.sh)
# abrir com depuração
open ~/Applications/JoystickAIPoC.app --args --debug
# encerrar
osascript -e 'quit app "JoystickAIPoC"'
# log mais recente
LOG="$(ls -t ~/Library/Logs/joystick-ai/poc-*.jsonl | head -1)"
grep -E '"(editor|permissions\.status)' "$LOG"
# testes automatizados
./scripts/test.sh
# restaurar a configuração guardada
cp ~/.config/joystick-ai/config.pre-004.json ~/.config/joystick-ai/config.json
```

## 1. Portão PM-1: sondas com a página mínima

As sondas rodam com a página mínima da Fase 0 (silhueta e três botões: ✕, L1 e Touchpad, com balões), antes do desenho dos 18 botões. Cada sonda responde a uma pergunta do `investigation.md` §6.

### P-01, tema e fundo (D-11)

1. Abra o editor pela paleta (PS, depois "Editar atalhos") com o sistema no tema claro.
2. Confira que o quadro arredondado da figura tem o mesmo tom do seletor de camada ao lado, e que não há retângulo branco ou preto por trás da silhueta.
3. Em Ajustes do Sistema › Aparência, troque para Escuro com o editor aberto.
4. Confira que fundo, traços, rótulos e balões da figura mudam sem reabrir a janela, e que o contorno do botão selecionado usa a cor de destaque do sistema.
5. Volte ao tema claro e repita a conferência.

Aprovado se os dois temas estão corretos e a troca é imediata. Reprovado: o bridge passa a observar `effectiveAppearance` e a chamar `figure.setTheme` (reserva de D-11).

### P-02, rolagem, foco do teclado e clique direito (D-09)

1. Com a janela na altura mínima (800 pt), leve o ponteiro do controle sobre a figura e role com o analógico direito.
2. Confira que a janela inteira rola, como ao rolar sobre o painel de ação.
3. Clique num botão da figura com R1; depois clique no campo de texto do painel (tipo Texto) e digite pelo teclado físico.
4. Confira que o texto entra no campo e que a figura não fica com anel de foco.
5. No painel, escolha Acorde, clique em "Gravar pelo teclado" e pressione ⌘K.
6. Confira que o acorde é gravado, como no PM-1a da 003.
7. Com o ponteiro sobre a figura, pressione R2 (clique direito).
8. Confira que nenhum menu de contexto do WebKit aparece.

Aprovado se os quatro comportamentos batem. Reprovado no passo 2: registre; a decisão de reduzir a altura da figura é do usuário.

### P-03, isolamento, assinatura e permissões (D-02, D-06)

1. Compare a assinatura: `diff /tmp/signature-pre-004.txt <(./scripts/check-signature.sh)` deve ser vazio.
2. Abra o app e confira no log `permissions.status` com `postEvent: true` e `listenEvent: true`, sem novo pedido de permissão.
3. Desligue Wi-Fi e cabo; abra o editor; confira que a figura aparece completa.
4. Confira que `figure.css` e `figure.js` foram aplicados (estilos visíveis e clique funcionando), o que prova que a CSP com `'self'` aceitou os arquivos irmãos.
5. Confira que `~/Library/WebKit/dev.iagoleal.joystick-ai.poc` não existe depois de abrir e fechar o editor.
6. Rode `./scripts/test.sh` e confira `FigureAssetsTests` verde.

Aprovado se os seis passos passam. Reprovado no passo 4: a página vira um único `index.html` inline (reserva de D-06). Reprovado nos passos 1 ou 2: pare e revise D-02 antes de seguir.

## 2. Portão PM-2: cenários da figura completa

Na TV, a 3 m, com a configuração padrão, salvo indicação. Cada item cita o cenário do `requirements.md` §7.

1. **Figura fiel com a configuração padrão.** Abra o editor na aba Atalhos, camada Base. Sem ler os rótulos, aponte os 18 botões pela forma e posição. Confira ✕ "Return", PS "abrir paleta", R1 "clique esquerdo, fixo".
2. **Balões visíveis ao mesmo tempo.** Confira os 18 balões, cada um com linha-guia ao seu botão, sem sobreposição entre balões nem sobre botões.
3. **Resumo por camada.** Escolha L2 no seletor. Confira ← "mesa à esquerda" e os demais esmaecidos com "(herdado)".
4. **Clique seleciona o botão.** Na Base com ✕ selecionado, clique em △ com R1. Confira o contorno em △, sem contorno em ✕, e o título "△ na camada Base" no painel.
5. **Alvo mínimo nos botões pequenos.** Na janela mínima, clique a cerca de 28 pt do centro de ○ (fora do desenho, dentro da área invisível). Confira ○ selecionado. Repita para ✕ a 30 pt.
6. **Identificação pelo controle reflete na figura.** Ligue "Identificar pelo controle" e pressione □ no controle. Confira □ selecionado sem clique e nenhum atalho executado. Desligue o modo.
7. **Edição reflete no resumo.** Com ✕ selecionado, troque o tipo para Texto e digite CONTINUAR (ditado pelo Raycast ou teclado). Confira "“CONTINUAR”" no balão de ✕ imediatamente.
8. **Problema em vermelho.** Apague o texto de ✕. Confira ✕ em vermelho e o rodapé "1 problema impede salvar". Desfaça com "Descartar alterações".
9. **Texto do usuário não vira marcação.** Em ✕, tipo Texto, cole `<img src=x onerror=alert(1)>`. Confira o balão literal entre aspas, truncado em 24 caracteres, sem imagem quebrada e sem diálogo. Descarte.
10. **Cores dos botões de ação.** Com ✕ selecionado, confira △ verde, ○ vermelho, ✕ azul e □ rosa, e o contorno de seleção visível sobre o azul.
11. **Realce sob o ponteiro.** Passe o ponteiro sobre ○ sem clicar. Confira o realce leve e a seleção inalterada.
12. **Transição de seleção discreta.** Com "Reduzir movimento" desligado, clique em △ e observe a transição breve. Ligue "Reduzir movimento" em Ajustes › Acessibilidade › Tela e repita: sem animação.
13. **Área da figura constante.** Amplie a janela de 1.400 × 800 para cerca de 1.900 × 1.000 pt. Confira a figura no mesmo tamanho e o painel mais largo.
14. **Regressão do teclado.** Grave um acorde pelo teclado e cole um texto ditado; ambos devem funcionar como na 003.
15. **Tema do sistema.** Troque para o tema escuro com o editor aberto. Confira fundo, traços e textos atualizados e legíveis a 3 m.
16. **Sem modificadores.** Desmarque "Este botão é modificador" em L1, L2, L3 e Options. Confira o seletor só com Base e nenhum balão esmaecido nem com "(herdado)". Descarte.
17. **Camada some após recarregar.** Selecione a camada △ (marque △ como modificador e salve). Com o rascunho limpo, edite o arquivo por fora removendo △ de `modifiers` e da camada. Confira a figura na camada Base e o seletor sem △. Restaure a configuração guardada.
18. **Estado enviado antes da carga.** Encerre e abra o app; abra o editor pela paleta imediatamente. Confira a figura com o estado vigente e ✕ selecionado, sem clique nem troca de camada.
19. **Sem rede.** Desligue Wi-Fi e cabo, abra o editor. Cronometre da abertura à figura completa (vídeo da tela ou cronômetro); deve ficar em até 500 ms. Repita com rede ligada.
20. **Página indisponível.** Encerre o app. Renomeie `~/Applications/JoystickAIPoC.app/Contents/Resources/ControllerFigure/index.html` para `index.html.bak`. Abra o app e o editor. Confira a mensagem "A figura do controle não pôde ser carregada; reinstale o app." no lugar da figura, o painel operável, e a identificação pelo controle selecionando △. Confira `editor.figure_unavailable` com `reason: resource_missing` no log. Encerre, desfaça a renomeação (ou rode `build-app.sh`) e confira que a assinatura segue válida com `codesign --verify --strict`.
21. **Mensagem desconhecida da página é ignorada.** Só em build de desenvolvimento, com o inspetor do WebKit habilitado pelo desenvolvedor: execute `webkit.messageHandlers.figure.postMessage({button: "nope"})` e `postMessage("x")` no console da página. Confira que a seleção não muda e nada aparece no log. Se o inspetor não estiver habilitado, o teste `FigureBridge` de validação de `ButtonID(rawValue:)` cobre o caso por inspeção de código.

Aprovado com os 21 passos verdes; qualquer reprovação vira nota de rodada no `actions.md`.

## 3. Se algo der errado

| Sintoma | Onde olhar | Provável causa |
|---------|------------|----------------|
| Mensagem de RN-12 logo após instalar | `ls Contents/Resources/ControllerFigure`; `editor.figure_unavailable.reason` | `build-app.sh` não copiou a pasta (`resource_missing`) ou a CSP bloqueou o script (`load_failed`) |
| Figura em branco, sem mensagem | `codesign --verify --strict --verbose=2`; console do WebKit | Recurso presente mas `figure.js` recusado; ver P-03 |
| Pedido de Acessibilidade de novo | `diff` da assinatura | Identidade de assinatura diferente da anterior, não a feature |
| Janela não rola sobre a figura | P-02 | `scrollWheel` não encaminhado; ver D-09 |
| Teclado não chega aos campos após clicar na figura | P-02 | `acceptsFirstResponder` não sobrescrito |
| Resumo não muda ao editar | log com `--debug`; `figureState` no modelo | Assinatura de `objectWillChange` perdida ou estado igual ao anterior por engano |
| Aparece `~/Library/WebKit/dev.iagoleal.joystick-ai.poc` | P-03 | `WKWebsiteDataStore` padrão em vez de `nonPersistent()` |
