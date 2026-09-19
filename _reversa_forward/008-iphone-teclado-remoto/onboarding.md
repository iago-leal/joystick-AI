# Onboarding: iPhone como teclado touch do Mac

> Identificador: `008-iphone-teclado-remoto`
> Data: `2026-09-19`
> Para: quem vai testar a feature pela primeira vez, com o Mac, o iPhone na mesma rede Wi-Fi e o controle

## 1. Preparar o Mac

1. Confira que a identidade de assinatura local existe: `security find-identity -v -p codesigning | grep "JoystickAI Local Signing"`.
2. Crie a identidade do teclado remoto: `./scripts/create-remote-keyboard-identity.sh`. Anote o nome do host que ele imprime (por exemplo, `MacBook-de-Iago.local`).
3. Compile e instale: `JOYSTICK_SIGN_IDENTITY="JoystickAI Local Signing" ./scripts/build-app.sh` e `./scripts/check-signature.sh`.
4. Abra o app. No menu do ícone do controle, escolha "Teclado remoto". Se o macOS perguntar se o app pode aceitar conexões recebidas, responda Permitir e anote o diálogo (sonda P-02).

## 2. Preparar o iPhone (uma única vez)

1. No menu do app, escolha "Enviar certificado ao iPhone…" e envie por AirDrop.
2. No iPhone, abra Ajustes › Geral › VPN e Gerenciamento de Dispositivos, toque no perfil "JoystickAI Local CA" e instale.
3. Abra Ajustes › Geral › Sobre › Ajustes de Confiança de Certificados e ligue "JoystickAI Local CA".
4. Na janela de pareamento do Mac, escaneie o QR com a câmera do iPhone e abra o link.
5. Com a página aberta, toque em Compartilhar › Adicionar à Tela de Início. Daqui em diante, abra o teclado pelo ícone, na horizontal.

## 3. PM-0: sondas de plataforma

Registre o resultado de cada sonda nesta seção, com data. Os métodos e critérios estão em `investigation.md` §5.

| Sonda | Resultado | Data |
|-------|-----------|------|
| P-01 confiança do iOS | aprovada: página e canal abertos sem aviso após instalar e confiar na autoridade; antes, o canal recusava por `bad_origin` (host em minúsculas no `Origin`), corrigido | 2026-09-19 |
| P-02 chaveiro e firewall | aprovada: app reaberto e recurso ligado sem diálogo do chaveiro nem do firewall | 2026-09-19 |
| P-03 ABNT2 por código | aprovada: "ç", "´" + "a" e "⇧2" chegaram como "ç", "á" e "@"; teclado pt-PT com a fonte EUA Internacional, não ABNT2 | 2026-09-19 |
| P-04 Caps Lock | reprovada pelo `flagsChanged` sintético; aprovada após a revisão da D-17, com a trava pela IOKit (`IOHIDSetModifierLockState`) | 2026-09-19 |
| P-05 latência e vigia | aprovada no vigia: nenhum `remote.watchdog` em digitação contínua de 1 a 2 min; latência sem medição (o `ts` da página não vai ao log), sem atraso percebido pelo usuário | 2026-09-19 |
| P-06 multitoque | aprovada: ⌘ segurado com um dedo e C com outro copiaram | 2026-09-19 |
| P-07 geometria física | aprovada: `KBGetLayoutType` informa ISO (tipo 89), coerente com o teclado pt-PT; a página passou a desenhar sempre ANSI por escolha do usuário (D-12 revista) | 2026-09-19 |

## 4. PM-1: roteiro da feature

Com o iPhone preso ao controle, na horizontal, e o TextEdit ou o Terminal em foco no Mac:

| # | Passo | Esperado | Cenário do `requirements.md` §7 |
|---|-------|----------|--------------------------------|
| 1 | Abrir a página pelo ícone da Tela de Início | "conectado", sem aviso de segurança | Primeira instalação e pareamento |
| 2 | No Terminal, digitar `ls -la` e Return | O comando roda | Digitar uma linha de comando |
| 3 | Selecionar um texto, segurar ⌘ e tocar C; depois colar pelo menu Editar do Mac | O texto copiado é colado | Modificador segurado |
| 4 | Tocar e soltar ⌘, depois tocar V | Cola; o ⌘ volta a solto na página | Modificador preso por toque |
| 5 | Tocar ⇧ duas vezes e depois uma letra | Letra minúscula | Soltar um modificador preso |
| 6 | Segurar apagar por 2 s | Apaga vários caracteres na cadência do Mac e para ao soltar | Repetição |
| 7 | Com ABNT2, trocar a fonte para o layout americano pelo menu de entrada | A tecla à direita do L passa de Ç para ; | Rótulos pela fonte de entrada |
| 8 | Com ABNT2, tocar ´ e depois A | "á" | Acento por tecla morta |
| 9 | Manter ⌘ pelo controle (Options com ⌘, se configurado) e pelo iPhone; soltar só no iPhone | ⌘ continua ativo até o controle soltar | Modificadores do controle e do iPhone juntos |
| 10 | Segurar ⌘ e apagar no iPhone e bloquear o iPhone | Em até 1 s, nada fica pressionado no Mac | Conexão perdida com tecla segurada |
| 11 | Desbloquear o iPhone | A página volta a digitar sem pedir código | Reconexão após bloqueio |
| 12 | Desligar o recurso no menu, reabrir o app e tentar abrir a página | Página não conecta | Teclado remoto desligado |
| 13 | Abrir a página num aparelho sem a autoridade instalada | Conexão insegura recusada | Identidade não confiável |
| 14 | Com o recurso ligado, abrir `https://<host>.local:47810/#c=000000` noutro aparelho confiável | "código incorreto"; na quinta tentativa, o código do Mac muda | Código errado |
| 15 | Com o iPhone conectado, abrir o QR noutro aparelho | "ocupado" | Segundo aparelho |
| 16 | Revogar a Acessibilidade do app e tocar uma tecla | Nada digitado; página mostra "sem permissão" em até 3 s | Sem permissão de Acessibilidade |
| 17 | Digitar 50 teclas, sair pela página e abrir o log | `remote.disconnected` com `keys: 50` e nenhum conteúdo | Log sem conteúdo |

Registre aprovado ou reprovado por passo, com observações, nesta seção.

### Resultado do PM-1

| # | Resultado | Data | Observações |
|---|-----------|------|-------------|
| 1 | aprovado | 2026-09-19 | |
| 2 | aprovado | 2026-09-19 | |
| 3 | aprovado | 2026-09-19 | |
| 4 | aprovado | 2026-09-19 | |
| 5 | aprovado | 2026-09-19 | |
| 6 | aprovado | 2026-09-19 | |
| 7 | aprovado após correção | 2026-09-19 | As teclas passaram a produzir os caracteres da fonte nova, mas os rótulos da página não mudaram. Causa: a notificação de troca de fonte chegava suspensa, porque o app de barra de menus quase nunca está à frente; corrigida com `suspensionBehavior: .deliverImmediately`. Repetido após a correção: aprovado, os rótulos mudaram sem reconectar |
| 8 | aprovado | 2026-09-19 | Coberto pela P-03: "´" seguido de "a" deu "á" com a fonte EUA Internacional |
| 9 | aprovado | 2026-09-19 | ⌘ mantido pelo L1 do controle e pelo iPhone; soltar só no iPhone manteve o ⌘ (⌘A selecionou tudo); depois de soltar o L1, A digitou "a" |
| 10 | aprovado | 2026-09-19 | Nada ficou pressionado no Mac após bloquear o iPhone com ⌘ e apagar seguros; sem `remote.watchdog` no log, sinal de que o `release` da página ao ficar oculta soltou tudo antes do vigia |
| 11 | aprovado | 2026-09-19 | A página voltou a digitar sem código; o log mostra `remote.disconnected` `replaced` seguido de `remote.connected` `resumed: true` (a conexão antiga ainda não tinha expirado no Mac) |
| 12 | aprovado | 2026-09-19 | Recurso desligado e app reaberto: página sem conexão |
| 13 | suspenso | 2026-09-19 | Sem segundo aparelho no momento |
| 14 | suspenso | 2026-09-19 | Sem segundo aparelho no momento |
| 15 | suspenso | 2026-09-19 | Sem segundo aparelho no momento |
| 16 | pendente | | |
| 17 | pendente | | |
