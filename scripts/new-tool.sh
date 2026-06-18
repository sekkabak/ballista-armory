#!/usr/bin/env bash
# new-tool.sh - scaffold a packages/<category>/<name>/package.yaml.
#
#   scripts/new-tool.sh <category> <name>
#   scripts/new-tool.sh pivoting sshuttle
set -euo pipefail

[ $# -eq 2 ] || { echo "usage: scripts/new-tool.sh <category> <name>" >&2; exit 1; }
CAT="$1"; NAME="$2"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="$ROOT/packages/$CAT/$NAME"
MF="$DIR/package.yaml"

[ -e "$MF" ] && { echo "already exists: $MF" >&2; exit 1; }
mkdir -p "$DIR"
cat > "$MF" <<YAML
name: $NAME
category: $CAT
version: "0.0.0"
description: TODO one-line description shown in search/list.
tags: [TODO]
homepage: https://github.com/CHANGEME
files:
  # release:// = heavy binary uploaded with scripts/publish.sh
  # raw://     = small script committed in this repo
  # https://   = pulled straight from upstream
  - dest: $NAME
    os: linux          # linux | windows | any
    arch: amd64
    exec: true
    url: release://binaries/${NAME}_linux_amd64
# c2:                  # optional - sliver/adaptix import hints
#   sliver:
#     dir: ~/.sliver-client/aliases
#     note: "aliases load after copy"
YAML

echo ":: created $MF"
echo "   1) edit it, then upload any binary:"
echo "      scripts/publish.sh binaries ./$NAME"
echo "   2) rebuild the index:"
echo "      python3 scripts/build-index.py"
echo "   3) commit + push (the CI also rebuilds index.json)"
