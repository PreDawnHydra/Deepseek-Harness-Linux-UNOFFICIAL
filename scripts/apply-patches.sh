#!/usr/bin/env bash
# Apply patches/*.patch to ./upstream in filename order and place binary assets.
#   ./scripts/apply-patches.sh           # apply
#   ./scripts/apply-patches.sh --check   # dry run
#   ./scripts/apply-patches.sh --revert  # undo
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPSTREAM="$ROOT/upstream"
MODE="${1:-apply}"
[[ -d "$UPSTREAM/.git" ]] || { echo "error: run scripts/fetch-upstream.sh first" >&2; exit 1; }
mapfile -t PATCHES < <(ls "$ROOT"/patches/*.patch | sort)
ASSET_SRC="$ROOT/assets/tray-linux.png"
ASSET_DST="$UPSTREAM/apps/desktop/resources/tray-linux.png"
case "$MODE" in
  --check)
    # Patches build on each other, so check them cumulatively in a throwaway index.
    tmp="$(mktemp -d)"; trap 'git -C "$UPSTREAM" worktree remove --force "$tmp/wt" 2>/dev/null || true; rm -rf "$tmp"' EXIT
    git -C "$UPSTREAM" worktree add -q --detach "$tmp/wt" HEAD
    for p in "${PATCHES[@]}"; do
      git -C "$tmp/wt" apply "$p" || { echo "FAIL $(basename "$p")" >&2; exit 1; }
      echo "ok   $(basename "$p")"
    done ;;
  --revert)
    for (( i=${#PATCHES[@]}-1; i>=0; i-- )); do git -C "$UPSTREAM" apply -R "${PATCHES[$i]}"; echo "reverted $(basename "${PATCHES[$i]}")"; done
    rm -f "$ASSET_DST" ;;
  apply)
    for p in "${PATCHES[@]}"; do git -C "$UPSTREAM" apply "$p"; echo "applied $(basename "$p")"; done
    install -Dm644 "$ASSET_SRC" "$ASSET_DST"; echo "installed apps/desktop/resources/tray-linux.png" ;;
  *) echo "usage: $0 [--check|--revert]" >&2; exit 2 ;;
esac
