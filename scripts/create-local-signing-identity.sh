#!/bin/sh
# Cria um certificado autoassinado de assinatura de código no chaveiro de login (D-01, caminho B).
#
# uso: ./scripts/create-local-signing-identity.sh "JoystickAI Local Signing"
#
# O macOS pede a senha de administrador para confiar no certificado para assinatura de código.
set -eu

name="${1:-}"
if [ -z "$name" ]; then
    echo "uso: $0 <nome da identidade>" >&2
    exit 64
fi

if security find-identity -v -p codesigning | grep -Fq "\"$name\""; then
    echo "a identidade \"$name\" já existe; nada a fazer."
    exit 0
fi

keychain="$HOME/Library/Keychains/login.keychain-db"
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT
passphrase="$(openssl rand -hex 16)"

cat > "$workdir/cert.conf" <<CONF
[req]
distinguished_name = dn
x509_extensions = ext
prompt = no
[dn]
CN = $name
[ext]
basicConstraints = critical,CA:false
keyUsage = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
CONF

openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
    -config "$workdir/cert.conf" \
    -keyout "$workdir/key.pem" -out "$workdir/cert.pem"

# OpenSSL 3 precisa de -legacy para gerar PKCS#12 que o `security` aceita; o LibreSSL do macOS não tem a opção.
if ! openssl pkcs12 -export -legacy -inkey "$workdir/key.pem" -in "$workdir/cert.pem" \
        -name "$name" -out "$workdir/identity.p12" -passout "pass:$passphrase" 2>/dev/null; then
    openssl pkcs12 -export -inkey "$workdir/key.pem" -in "$workdir/cert.pem" \
        -name "$name" -out "$workdir/identity.p12" -passout "pass:$passphrase"
fi

security import "$workdir/identity.p12" -k "$keychain" -P "$passphrase" -T /usr/bin/codesign
security add-trusted-cert -r trustRoot -p codeSign -k "$keychain" "$workdir/cert.pem"

if security find-identity -v -p codesigning | grep -Fq "\"$name\""; then
    echo "identidade \"$name\" criada. Use: JOYSTICK_SIGN_IDENTITY=\"$name\" ./scripts/build-app.sh"
else
    echo "erro: o certificado foi importado, mas não aparece como identidade válida de assinatura." >&2
    exit 65
fi
