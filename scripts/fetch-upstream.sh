#!/usr/bin/env bash
# Clone the pinned upstream release into ./upstream.
#   ./scripts/fetch-upstream.sh            # tag from upstream.env
#   ./scripts/fetch-upstream.sh <ref>      # another tag or branch (patches may not apply)
#   REFRESH=1 ./scripts/fetch-upstream.sh  # delete and re-clone
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../upstream.env
source "$ROOT/upstream.env"
REF="${1:-$UPSTREAM_TAG}"
DEST="$ROOT/upstream"
if [[ -d "$DEST/.git" ]]; then
  if [[ "${REFRESH:-0}" != 1 ]]; then echo "==> $DEST already exists (REFRESH=1 to re-clone)"; exit 0; fi
  rm -rf "$DEST"
fi
echo "==> cloning $UPSTREAM_REPO @ $REF"
GIT_LFS_SKIP_SMUDGE=1 git clone --depth 1 --branch "$REF" "$UPSTREAM_REPO" "$DEST"
if [[ "$REF" == "$UPSTREAM_TAG" ]]; then
  actual="$(git -C "$DEST" rev-parse HEAD)"
  [[ "$actual" == "$UPSTREAM_COMMIT" ]] || { echo "error: $REF resolved to $actual, expected $UPSTREAM_COMMIT" >&2; exit 1; }
fi
