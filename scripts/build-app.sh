#!/bin/sh
# Compila, monta, assina e instala JoystickAIPoC.app em caminho fixo (D-01, D-02).
#
# uso: JOYSTICK_SIGN_IDENTITY="Apple Development: Nome (TEAMID)" ./scripts/build-app.sh
#
# A identidade precisa ser estável entre builds para que as permissões de Acessibilidade
# e Input Monitoring sobrevivam à recompilação; assinatura ad hoc é recusada.
set -eu
cd "$(dirname "$0")/.."

APP_NAME=JoystickAIPoC
INSTALL_DIR="$HOME/Applications"
INSTALL_PATH="$INSTALL_DIR/$APP_NAME.app"
STAGING="$PWD/.build/app/$APP_NAME.app"

identity="${JOYSTICK_SIGN_IDENTITY:-}"
if [ -z "$identity" ]; then
    echo "erro: defina JOYSTICK_SIGN_IDENTITY com o nome da identidade de assinatura." >&2
    echo "identidades disponíveis:" >&2
    security find-identity -v -p codesigning >&2 || true
    exit 64
fi
if [ "$identity" = "-" ]; then
    echo "erro: assinatura ad hoc invalida as permissões a cada build (app-shell EC-01); use uma identidade fixa." >&2
    exit 64
fi
if ! security find-identity -v -p codesigning | grep -Fq "\"$identity\""; then
    if ! security find-identity -v -p codesigning | grep -Fq "$identity"; then
        echo "erro: identidade \"$identity\" não encontrada no chaveiro." >&2
        security find-identity -v -p codesigning >&2 || true
        exit 65
    fi
fi

echo "==> swift build -c release"
swift build -c release --product "$APP_NAME"
BIN_DIR="$(swift build -c release --show-bin-path)"

echo "==> montagem de $STAGING"
rm -rf "$STAGING"
mkdir -p "$STAGING/Contents/MacOS"
cp "$BIN_DIR/$APP_NAME" "$STAGING/Contents/MacOS/$APP_NAME"
cp Resources/Info.plist "$STAGING/Contents/Info.plist"

echo "==> assinatura com \"$identity\""
codesign --force --timestamp=none --sign "$identity" "$STAGING"
codesign --verify --strict "$STAGING"

if pgrep -xq "$APP_NAME"; then
    echo "==> encerrando a instância aberta"
    osascript -e "quit app \"$APP_NAME\"" >/dev/null 2>&1 || true
    for _ in 1 2 3 4 5 6 7 8 9 10; do
        pgrep -xq "$APP_NAME" || break
        sleep 0.5
    done
fi

echo "==> instalação em $INSTALL_PATH"
mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALL_PATH"
ditto "$STAGING" "$INSTALL_PATH"

echo "pronto. Abra com: open \"$INSTALL_PATH\""
