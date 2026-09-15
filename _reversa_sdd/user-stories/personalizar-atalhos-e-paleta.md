# Personalizar atalhos e paleta

> Gerado pelo Redator em 2026-09-15 · Persona: programador de sofá (`personas.md`) · PRD §4, configuração dos mapeamentos · Escala: 🟢 CONFIRMADO · 🟡 INFERIDO · 🔴 LACUNA

## Contexto

O usuário ajusta o mapeamento dos botões e a lista da paleta sem reiniciar o app, pelo editor em escala de TV ou editando `~/.config/joystick-ai/config.json` nos dotfiles. O fluxo reúne as units `editor`, `configuracao`, `atalhos` e `paleta`. 🟢

## Histórias

### US-PE-01, Abrir o editor de onde estiver

**Como** programador de sofá, **quero** abrir o editor pela paleta ou pelo ícone da barra de menus, **para** ajustar atalhos sem levantar. 🟢

```gherkin
Dado o Terminal em foco e a paleta aberta
Quando "Editar atalhos" é confirmado
Então o editor abre ativo, pronto para teclado e ditado
E ao fechar o foco volta ao Terminal
```

Units: `editor` (RN-ED-32 a RN-ED-34), `paleta` (RN-PA-07). 🟢

### US-PE-02, Mudar a ação de um botão

**Como** programador de sofá, **quero** escolher um botão na figura do controle ou pressioná-lo no próprio controle e trocar sua ação, **para** adaptar o controle ao meu fluxo. 🟢

```gherkin
Dado o editor aberto com "Identificar pelo controle" ligado
Quando □ é pressionado no controle
Então □ fica selecionado e nenhuma tecla é enviada

Dado □ selecionado na base
Quando o tipo "Texto" é escolhido, "/clear" é digitado e Salvar é acionado
Então config.json passa a conter a ação e □ digita "/clear" no pressionar seguinte
```

Units: `editor`, `configuracao` (RN-CF-26 a RN-CF-31), `atalhos` (RN-AT-16). 🟢

### US-PE-03, Criar uma camada nova

**Como** programador de sofá, **quero** transformar um botão em modificador, **para** ter mais combinações. 🟢

```gherkin
Dado △ marcado como modificador
Quando as ações de △ na base, em L1 e em L2 são removidas
Então Salvar volta a ser possível e a camada △ aparece no seletor
```

Units: `editor` (RN-ED-08, RN-ED-09), `configuracao` (RN-CF-15). 🟢

### US-PE-04, Editar a lista da paleta

**Como** programador de sofá, **quero** incluir, rotular, reordenar e remover comandos da paleta, **para** manter à mão os comandos que uso. 🟢

```gherkin
Dado a aba Paleta
Quando um item é incluído no topo com texto "/reversa-sync", marcado com Enter e salvo
Então a paleta abre com o item novo em primeiro e o envia com Enter
```

Units: `editor` (`PaletteTab`), `paleta` (RN-PA-15), `configuracao` (RN-CF-16). 🟢

### US-PE-05, Editar pelo arquivo sem quebrar nada

**Como** programador de sofá, **quero** editar `config.json` em outro editor e ver o efeito na hora, com erros apontados por linha, **para** versionar a configuração nos dotfiles. 🟢

```gherkin
Dado config.json como link para os dotfiles
Quando uma tecla desconhecida é gravada no arquivo por outro editor
Então a configuração vigente continua, o ícone vira alerta e o menu mostra a linha do erro

Dado o editor com alterações não salvas
Quando o arquivo muda por fora e é válido
Então o editor oferece "Recarregar do arquivo" ou "Manter minhas alterações"
```

Units: `configuracao` (RN-CF-18 a RN-CF-25), `editor` (RN-ED-26, RN-ED-27). 🟢

### US-PE-06, Recuperar um arquivo corrompido

**Como** programador de sofá, **quero** gravar pelo editor mesmo com o arquivo quebrado, guardando uma cópia, **para** não perder o conteúdo antigo. 🟢

```gherkin
Dado config.json com erro de sintaxe na linha 7
Quando Salvar é acionado no editor
Então a faixa pede confirmação citando a linha 7
E "Copiar e gravar" cria config.json.bak e grava o rascunho
```

Units: `configuracao` (RN-CF-27), `editor` (RN-ED-22, RN-ED-23). "Copiar e gravar" não reverifica o rascunho, defeito confirmado (DV-05). 🟢

## Pendências

- 🟢 DV-05: corrigir a revalidação na gravação com `.bak` (`configuracao` T-11, `editor` T-10).
