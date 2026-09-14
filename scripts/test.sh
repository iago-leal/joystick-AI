#!/bin/sh
# Roda `swift test` também quando só as Command Line Tools estão instaladas.
# Nesse caso o Swift Testing fica fora do caminho de busca, e o runner gerado pelo
# SwiftPM não herda as flags do alvo de testes; a flag precisa vir da linha de comando.
set -eu
cd "$(dirname "$0")/.."

CLT_FRAMEWORKS=/Library/Developer/CommandLineTools/Library/Developer/Frameworks
if [ -d "$CLT_FRAMEWORKS/Testing.framework" ] && ! xcode-select -p 2>/dev/null | grep -q '\.app/'; then
    exec swift test -Xswiftc -F -Xswiftc "$CLT_FRAMEWORKS" "$@"
fi
exec swift test "$@"
