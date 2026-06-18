#!/usr/bin/env bash
# publish.sh - upload heavy assets to a GitHub Release and print the
# release:// URLs to paste into a package.yaml.
#
#   scripts/publish.sh <tag> <file> [file...]
#
# Examples:
#   scripts/publish.sh binaries ./chisel ./chisel.exe
#   scripts/publish.sh wordlists ./seclists-2024.3.tar.gz
#
# Needs the GitHub CLI (`gh auth login` once). Creates the release if missing
# and clobbers existing assets of the same name so re-uploads are idempotent.
set -euo pipefail

command -v gh >/dev/null || { echo "gh (GitHub CLI) required: https://cli.github.com" >&2; exit 1; }
[ $# -ge 2 ] || { echo "usage: scripts/publish.sh <tag> <file> [file...]" >&2; exit 1; }

TAG="$1"; shift
TITLE="${ARMORY_RELEASE_TITLE:-armory assets: $TAG}"

if ! gh release view "$TAG" >/dev/null 2>&1; then
  echo ":: creating release '$TAG'"
  gh release create "$TAG" --title "$TITLE" --notes "Armory asset bucket: $TAG" --latest=false
fi

for f in "$@"; do
  [ -f "$f" ] || { echo "!! not a file: $f" >&2; continue; }
  echo ":: uploading $(basename "$f")"
  gh release upload "$TAG" "$f" --clobber
done

echo
echo "paste these into your package.yaml 'files:' entries:"
for f in "$@"; do
  [ -f "$f" ] || continue
  printf '    url: release://%s/%s\n' "$TAG" "$(basename "$f")"
done
