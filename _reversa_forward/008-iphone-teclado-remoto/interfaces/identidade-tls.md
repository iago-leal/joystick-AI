# Interface: identidade TLS do teclado remoto

> Feature: `008-iphone-teclado-remoto`
> Tipo: script, chaveiro e arquivo
> Origem: `requirements.md` RN-03, RF-03, RNF de segurança e de privacidade; `roadmap.md` D-03, D-04
> Confidência: 🟡 até a sonda P-01, salvo indicação

## 1. Produtor: `scripts/create-remote-keyboard-identity.sh`

| Passo | Detalhe |
|-------|---------|
| Nome do host | `scutil --get LocalHostName`, acrescido de `.local` |
| Autoridade | RSA 2048, 10 anos, `CN=JoystickAI Local CA`, `basicConstraints=critical,CA:TRUE,pathlen:0`, `keyUsage=critical,keyCertSign,cRLSign`, `nameConstraints=critical,permitted;DNS:.local` |
| Servidor | RSA 2048, 825 dias, `CN=<host>.local`, `subjectAltName=DNS:<host>.local`, `extendedKeyUsage=serverAuth`, `keyUsage=critical,digitalSignature,keyEncipherment` |
| Chaveiro | Importa a identidade do servidor no chaveiro de sessão com o rótulo "JoystickAI Remote Keyboard", liberando o acesso a `~/Applications/JoystickAIPoC.app` |
| Arquivo | Grava o certificado da autoridade em DER em `~/Library/Application Support/joystick-ai/remote-keyboard/JoystickAI-Local-CA.cer` (pasta `0700`, arquivo `0600`) |
| Limpeza | Apaga a pasta temporária com as chaves da autoridade e do servidor |
| Reexecução | Se já houver identidade com o rótulo, pergunta antes de substituir; substituir exige reinstalar a autoridade no iPhone |

## 2. Consumidor: app

- `RemoteKeyboardIdentity` busca `SecIdentity` pelo rótulo e confere se o SAN contém o `LocalHostName` atual e se a validade não venceu.
- Falhas viram mensagem no menu e `remote.rejected` com `reason`: `no_identity`, `host_mismatch` ou `expired`; o recurso não liga.
- "Enviar certificado ao iPhone…" oferece o arquivo da autoridade pelo AirDrop; sem arquivo, o item fica desabilitado.

## 3. Consumidor: iPhone

Instalar o perfil recebido (Ajustes › Geral › VPN e Gerenciamento de Dispositivos) e ligar a confiança total (Ajustes › Geral › Sobre › Ajustes de Confiança de Certificados). Passo a passo no `onboarding.md` §2.
