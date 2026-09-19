#!/bin/sh
# Cria a identidade TLS do teclado remoto (`008-iphone-teclado-remoto` D-03, interfaces/identidade-tls.md §1).
#
# uso: ./scripts/create-remote-keyboard-identity.sh
#
# Gera uma autoridade local com restrição de nome a `.local` e, com ela, o certificado do servidor para
# `<LocalHostName>.local`. A identidade do servidor vai ao chaveiro de sessão com o rótulo "JoystickAI Remote Keyboard";
# o certificado da autoridade fica em Application Support, para o app enviá-lo ao iPhone por AirDrop. A chave da
# autoridade é apagada ao fim: sem ela, ninguém que obtenha os arquivos do Mac emite certificados que o iPhone aceite.
set -eu

label="JoystickAI Remote Keyboard"
ca_name="JoystickAI Local CA"
app_path="$HOME/Applications/JoystickAIPoC.app"
out_dir="$HOME/Library/Application Support/joystick-ai/remote-keyboard"
ca_file="$out_dir/JoystickAI-Local-CA.cer"
keychain="$HOME/Library/Keychains/login.keychain-db"

local_name="$(scutil --get LocalHostName 2>/dev/null || true)"
if [ -z "$local_name" ]; then
    echo "erro: o Mac não tem LocalHostName; defina-o em Ajustes › Geral › Compartilhamento." >&2
    exit 65
fi
host="$local_name.local"

if security find-certificate -c "$host" "$keychain" >/dev/null 2>&1; then
    printf 'já existe uma identidade "%s". Substituir? A autoridade nova terá de ser reinstalada no iPhone. [s/N] ' "$label"
    read -r answer
    case "$answer" in
        s|S|sim|Sim) ;;
        *) echo "nada alterado."; exit 0 ;;
    esac
    # Remove a identidade antiga (certificado e chave) pelo nome do certificado.
    while security delete-identity -c "$host" "$keychain" >/dev/null 2>&1; do :; done
fi

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT
passphrase="$(openssl rand -hex 16)"

cat > "$workdir/ca.conf" <<CONF
[req]
distinguished_name = dn
x509_extensions = ext
prompt = no
[dn]
CN = $ca_name
[ext]
basicConstraints = critical,CA:TRUE,pathlen:0
keyUsage = critical,keyCertSign,cRLSign
nameConstraints = critical,permitted;DNS:.local
subjectKeyIdentifier = hash
CONF

cat > "$workdir/server.conf" <<CONF
[req]
distinguished_name = dn
prompt = no
[dn]
CN = $host
[ext]
basicConstraints = critical,CA:FALSE
subjectAltName = DNS:$host
extendedKeyUsage = serverAuth
keyUsage = critical,digitalSignature,keyEncipherment
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid
CONF

echo "==> autoridade \"$ca_name\" (10 anos, restrita a .local)"
openssl req -x509 -newkey rsa:2048 -nodes -days 3650 -sha256 \
    -config "$workdir/ca.conf" -keyout "$workdir/ca.key" -out "$workdir/ca.pem" 2>/dev/null

echo "==> certificado do servidor para $host (825 dias)"
openssl req -new -newkey rsa:2048 -nodes -sha256 \
    -config "$workdir/server.conf" -keyout "$workdir/server.key" -out "$workdir/server.csr" 2>/dev/null
openssl x509 -req -in "$workdir/server.csr" -CA "$workdir/ca.pem" -CAkey "$workdir/ca.key" -CAcreateserial \
    -days 825 -sha256 -extfile "$workdir/server.conf" -extensions ext -out "$workdir/server.pem" 2>/dev/null

# A chave da autoridade não sai da pasta temporária, apagada pelo `trap`; apagá-la já aqui encurta sua vida.
rm -f "$workdir/ca.key"

# OpenSSL 3 precisa de -legacy para gerar PKCS#12 que o `security` aceita; o LibreSSL do macOS não tem a opção.
if ! openssl pkcs12 -export -legacy -inkey "$workdir/server.key" -in "$workdir/server.pem" -certfile "$workdir/ca.pem" \
        -name "$label" -out "$workdir/identity.p12" -passout "pass:$passphrase" 2>/dev/null; then
    openssl pkcs12 -export -inkey "$workdir/server.key" -in "$workdir/server.pem" -certfile "$workdir/ca.pem" \
        -name "$label" -out "$workdir/identity.p12" -passout "pass:$passphrase"
fi

echo "==> chaveiro de sessão, com acesso liberado a $app_path"
if [ -d "$app_path" ]; then
    security import "$workdir/identity.p12" -k "$keychain" -P "$passphrase" -T "$app_path"
else
    echo "aviso: $app_path não existe; o macOS pedirá autorização na primeira vez que o app usar a identidade." >&2
    security import "$workdir/identity.p12" -k "$keychain" -P "$passphrase"
fi

mkdir -p "$out_dir"
chmod 700 "$out_dir"
openssl x509 -in "$workdir/ca.pem" -outform der -out "$ca_file"
chmod 600 "$ca_file"

echo "pronto."
echo "  host:       $host"
echo "  autoridade: $ca_file"
echo "No app, escolha \"Enviar certificado ao iPhone…\" e siga o onboarding.md §2."
