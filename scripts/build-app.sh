#!/bin/sh
# Compila, monta, assina e instala JoystickAIPoC.app em caminho fixo (D-01, D-02).
# Desde a `004-figura-controle-web` (D-01, D-02) o bundle leva Resources/ControllerFigure em Contents/Resources.
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

# Página da figura do controle (`004-figura-controle-web` D-01, D-02): entra em Contents/Resources antes da
# assinatura, para o CodeResources selar os três arquivos junto com o binário e o Info.plist.
FIGURE_SRC="Resources/ControllerFigure"
if [ ! -d "$FIGURE_SRC" ]; then
    echo "erro: pasta $FIGURE_SRC não encontrada; a figura do controle (index.html, figure.css, figure.js) faz parte do bundle." >&2
    exit 66
fi
for f in index.html figure.css figure.js; do
    if [ ! -f "$FIGURE_SRC/$f" ]; then
        echo "erro: $FIGURE_SRC/$f não encontrado; o bundle exige os três arquivos da figura." >&2
        exit 66
    fi
done
mkdir -p "$STAGING/Contents/Resources"
cp -R "$FIGURE_SRC" "$STAGING/Contents/Resources/ControllerFigure"

# Página do teclado remoto (`008-iphone-teclado-remoto` D-15): servida pelo app ao iPhone, selada como a figura.
REMOTE_SRC="Resources/RemoteKeyboard"
for f in index.html keyboard.css keyboard.js; do
    if [ ! -f "$REMOTE_SRC/$f" ]; then
        echo "erro: $REMOTE_SRC/$f não encontrado; o bundle exige os três arquivos do teclado remoto." >&2
        exit 66
    fi
done
cp -R "$REMOTE_SRC" "$STAGING/Contents/Resources/RemoteKeyboard"

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
