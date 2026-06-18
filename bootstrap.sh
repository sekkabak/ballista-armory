#!/usr/bin/env bash
# Remote bootstrap - this is what cbak.pl/armory serves.
#   curl -sSL cbak.pl/armory | bash
# It fetches the self-contained armory folder, then runs its install.sh
# (which only creates the PATH symlink).
#
#   override target dir:  ARMORY_DIR=/opt/armory  curl -sSL cbak.pl/armory | bash
set -euo pipefail

OWNER="${ARMORY_OWNER:-sekkabak}"
REPO="${ARMORY_REPO:-ballista-armory}"
BRANCH="${ARMORY_BRANCH:-main}"
DIR="${ARMORY_DIR:-$HOME/$REPO}"

c() { [ -t 1 ] && printf '\e[%sm%s\e[0m' "$1" "$2" || printf '%s' "$2"; }
say() { printf '%s %s\n' "$(c '35;1' '::')" "$*"; }
die() { printf '%s %s\n' "$(c '31;1' 'xx')" "$*" >&2; exit 1; }

command -v curl >/dev/null || die "curl is required"

if [ -d "$DIR/.git" ]; then
  say "updating existing vault at $DIR"
  git -C "$DIR" pull --ff-only || say "git pull failed - keeping current copy"
elif command -v git >/dev/null 2>&1; then
  say "cloning vault -> $DIR"
  git clone --depth 1 -b "$BRANCH" "https://github.com/$OWNER/$REPO.git" "$DIR"
else
  # no git: grab a tarball of the branch and extract
  say "downloading vault tarball -> $DIR"
  mkdir -p "$DIR"
  curl -fsSL "https://github.com/$OWNER/$REPO/archive/refs/heads/$BRANCH.tar.gz" \
    | tar -xz -C "$DIR" --strip-components=1
fi

say "running local installer (symlink only)"
bash "$DIR/install.sh"
say "vault is self-contained in: $(c '36;1' "$DIR")"
