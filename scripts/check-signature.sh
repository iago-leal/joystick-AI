#!/bin/sh
# Imprime identificador e requisito designado do app instalado, em saída estável para diff (R-01).
set -eu

APP_PATH="$HOME/Applications/JoystickAIPoC.app"
if [ ! -d "$APP_PATH" ]; then
    echo "erro: $APP_PATH não está instalado; rode ./scripts/build-app.sh antes." >&2
    exit 66
fi

identifier="$(codesign -d -v "$APP_PATH" 2>&1 | sed -n 's/^Identifier=//p')"
authority="$(codesign -d -vv "$APP_PATH" 2>&1 | sed -n 's/^Authority=//p' | head -1)"
requirement="$(codesign -d -r- "$APP_PATH" 2>&1 | sed -n 's/^designated => //p')"

if [ -z "$requirement" ]; then
    echo "erro: não foi possível ler o requisito designado de $APP_PATH." >&2
    exit 65
fi

echo "identifier: $identifier"
echo "authority: ${authority:-(ad hoc)}"
echo "designated: $requirement"
