#!/usr/bin/env bash
# Local installer - run from inside the armory folder.
# It does ONE thing: symlink bin/armory into your PATH. Nothing is downloaded;
# the whole vault stays self-contained in this folder.
#
#   ./install.sh              -> symlink into ~/.local/bin
#   ./install.sh /usr/local/bin   (or set ARMORY_BINDIR)
set -euo pipefail

# resolve this script's own folder (the vault root), following symlinks
src="${BASH_SOURCE[0]}"
while [ -h "$src" ]; do
  dir="$(cd -P "$(dirname "$src")" && pwd)"; src="$(readlink "$src")"
  [ "${src:0:1}" != "/" ] && src="$dir/$src"
done
ROOT="$(cd -P "$(dirname "$src")" && pwd)"
TARGET="$ROOT/bin/armory"
BINDIR="${1:-${ARMORY_BINDIR:-$HOME/.local/bin}}"

c() { [ -t 1 ] && printf '\e[%sm%s\e[0m' "$1" "$2" || printf '%s' "$2"; }
say() { printf '%s %s\n' "$(c '35;1' '::')" "$*"; }

[ -f "$TARGET" ] || { echo "bin/armory not found next to install.sh" >&2; exit 1; }
command -v jq   >/dev/null || say "$(c '33;1' 'note:') install 'jq' (apt install jq) - armory needs it"

chmod +x "$TARGET"
mkdir -p "$BINDIR"
ln -sf "$TARGET" "$BINDIR/armory"
say "linked $(c '36;1' "$BINDIR/armory") -> $TARGET"

case ":$PATH:" in
  *":$BINDIR:"*) : ;;
  *) say "add to your shell rc:  export PATH=\"$BINDIR:\$PATH\"" ;;
esac
command -v gum >/dev/null 2>&1 || say "$(c '33;1' 'optional:') 'gum' + 'fzf' for the prettiest UI"
say "done. try:  $(c '36;1' 'armory search kerberos')"
