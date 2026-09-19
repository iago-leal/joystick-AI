# Interface: página e canal do teclado remoto

> Feature: `008-iphone-teclado-remoto`
> Tipo: HTTP/1.1 sobre TLS (porta 47810) e WebSocket sobre TLS (porta 47811)
> Origem: `requirements.md` RN-01 a RN-12, RF-01 a RF-12; `roadmap.md` D-02, D-05 a D-11, D-16
> Confidência: 🟢 salvo indicação

## 1. Disponibilidade

- Os dois listeners só existem com o recurso ligado pelo menu (RN-02). Desligado, as portas ficam fechadas.
- Conexões cuja origem não passa em `LocalAddressPolicy` são fechadas logo após o aceite, sem bytes de resposta, e registradas como `remote.rejected` com `reason: not_local`.
- TLS 1.2 ou superior, com a identidade "JoystickAI Remote Keyboard" (`identidade-tls.md`). Sem identidade, o recurso não liga.

## 2. Página (porta 47810)

| Requisição | Resposta | Observação |
|------------|----------|------------|
| `GET /` | `200`, `text/html; charset=utf-8`, `index.html` | |
| `GET /keyboard.css` | `200`, `text/css; charset=utf-8` | |
| `GET /keyboard.js` | `200`, `text/javascript; charset=utf-8` | |
| Outro caminho | `404` sem corpo | |
| Outro método | `405` sem corpo | |
| Requisição acima de 8 KiB ou incompleta em 5 s | Conexão fechada | Sem registro |

Cabeçalhos de toda resposta `200`: `Cache-Control: no-store`, `Content-Security-Policy: default-src 'self'; connect-src wss://<host>.local:47811; script-src 'self'; style-src 'self'`, `X-Content-Type-Options: nosniff`. A conexão é fechada após cada resposta (`Connection: close`). 🟡

A URL do QR é `https://<LocalHostName>.local:47810/#c=<código>`. O fragmento não viaja no HTTP; `keyboard.js` o lê, remove-o da barra de endereço com `history.replaceState` e o usa só na primeira mensagem do canal.

## 3. Canal (porta 47811)

### 3.1 Aperto de mão

- Caminho `/ws`. O cabeçalho `Origin` deve ser `https://<LocalHostName>.local:47810`; outro valor recusa o aperto de mão com `403` e registra `reason: bad_origin`.
- Com sessão ativa (D-06), a nova conexão é aceita e examinada pelo `hello` (§3.4): com o token da sessão, substitui a conexão ativa; com código ou qualquer outro token, recebe `{"t":"reject","reason":"busy"}` e é fechada com código 4001, sem revelar se o token é válido. A página trata `busy` como final: mostra "ocupado" e não tenta de novo.

### 3.2 Mensagens do cliente

Todas em texto JSON, um objeto por quadro, com o campo `t`. Quadros binários ou acima de 1 KiB são inválidos.

| `t` | Campos | Quando | Efeito no Mac |
|-----|--------|--------|---------------|
| `hello` | `code` (6 dígitos) ou `token` (32 hexadecimais), `v: 1` | Primeira mensagem, em até 5 s | Pareamento (§3.4) |
| `down` | `k` (código virtual) , `ts` (ms do relógio da página) | `touchstart` numa tecla | `RemoteKeyboardMachine`; `ts` só serve à sonda P-05 e não vai ao log |
| `up` | `k`, `ts` | `touchend` ou `touchcancel` | Idem |
| `ping` | nenhum | A cada 250 ms | Renova o vigia (D-11) |
| `release` | nenhum | `visibilitychange` para oculto, `pagehide` | Solta tudo |
| `bye` | nenhum | Usuário fecha a página pelo botão "Sair" | Solta tudo e encerra a sessão |

Qualquer mensagem antes de `hello` aceito encerra a conexão (código 4002). `k` fora da geometria vigente, JSON inválido ou `t` desconhecido contam como inválidos; cinco seguidos encerram a sessão (código 4003, `reason: invalid_messages`).

### 3.3 Mensagens do servidor

| `t` | Campos | Quando |
|-----|--------|--------|
| `welcome` | `token`, `v: 1` | Pareamento aceito |
| `reject` | `reason`: `bad_code`, `bad_token`, `busy`, `code_rotated` | Pareamento recusado; a conexão fecha em seguida |
| `layout` | `physical`: `ansi` ou `iso`; `rows`: códigos da geometria por linha, na ordem de desenho; `keys`: lista de `{k, plain, shift, option, shiftOption, dead}`, só das teclas que produzem caractere | Após `welcome` e a cada troca de fonte de entrada |
| `modifiers` | `command`, `shift`, `option`, `control`: `released`, `held` ou `latched` | Após cada mudança de estado de modificador |
| `status` | `injection`: `on` ou `no_permission` | Após `welcome` e a cada mudança do portão (RN-11, RF-10) |
| `caps` | `on`: booleano | Após `welcome` e a cada toque no ⇪; a trava é do sistema (D-17, revista no PM-0) |

### 3.4 Pareamento

| Situação | Resposta |
|----------|----------|
| `code` igual ao vigente, sem sessão ativa | `welcome` com token novo; zera as falhas |
| `code` diferente | `reject` `bad_code`; soma uma falha |
| Quinta falha | `reject` `code_rotated`; código novo na janela de pareamento |
| `token` igual ao da sessão, sem conexão ativa | `welcome` com o mesmo token (RF-12) |
| `token` igual ao da sessão, com conexão ativa | A conexão ativa tem tudo solto e é fechada com código 4004 (`reason: replaced`); a nova recebe `welcome` com o mesmo token (RF-12, D-06) 🟡 |
| `code`, certo ou errado, com conexão ativa | `reject` `busy`; não soma falha |
| `token` desconhecido ou recurso religado, sem conexão ativa | `reject` `bad_token`; a página volta a pedir o QR |
| `token` desconhecido, com conexão ativa | `reject` `busy` (§3.1) |

### 3.5 Tempos e idempotência

- `down` repetido para tecla já mantida é ignorado; `up` de tecla solta é ignorado. A máquina é idempotente por tecla. 🟢
- Sem mensagem por 1 s com tecla ou modificador mantido ou preso: soltura geral e `remote.watchdog`; a sessão continua. 🟡
- Sem mensagem por 10 s: a conexão é fechada (`reason: timeout`) e a página tenta reconectar a cada 1 s, com o token.
- A página só reconecta sozinha depois de fechamentos sem código de aplicação ou por `timeout`. Com 4001 (`busy`) mostra "ocupado"; com 4004 (`replaced`) mostra "sessão aberta noutra aba"; com `bad_token` volta a pedir o QR. Em nenhum desses casos tenta de novo.
- Fechamento do canal por qualquer motivo, inclusive a substituição pelo token (código 4004), solta tudo antes de liberar a sessão ou entregá-la à nova conexão.

## 4. Privacidade

`k`, `ts`, `code`, `token`, rótulos e o endereço remoto não vão ao log (RN-13). A página guarda só o token, em `sessionStorage`, que o Safari apaga ao fechar a aba.
