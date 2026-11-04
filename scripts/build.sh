#!/usr/bin/env bash
# Build the Linux Desktop app from ./upstream (after apply-patches.sh).
#   ./scripts/build.sh            # AppImage (default)
#   ./scripts/build.sh --deb      # .deb only
#   ./scripts/build.sh --rpm      # .rpm only (needs rpmbuild)
#   ./scripts/build.sh --all      # AppImage + deb + rpm
#   ./scripts/build.sh --dir      # unpacked directory only (fastest)
# Env:
#   DSH_DESKTOP_LINUX_MAINTAINER  "Name <email>" written into deb/rpm metadata
#   DSH_DESKTOP_LINUX_UPDATE_URL  https feed the app's updater polls (unset: no auto-update), e.g.
#                                 https://github.com/<owner>/<repo>/releases/latest/download
#   DSH_BUILD_HOME                isolated dsh data dir used during the build (default: mktemp)
# Artifacts: upstream/apps/desktop/.desktop-build/targets/linux-<arch>/unsigned-artifacts/
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPSTREAM="$ROOT/upstream"
[[ -d "$UPSTREAM/apps/desktop" ]] || { echo "error: run fetch-upstream.sh and apply-patches.sh first" >&2; exit 1; }

case "$(uname -m)" in
  x86_64) ARCH=x64 ;; aarch64|arm64) ARCH=arm64 ;;
  *) echo "error: unsupported build host $(uname -m); build natively on x86_64 or aarch64" >&2; exit 1 ;;
esac

# Node 24.9+ with TypeScript type stripping (nodejs.org builds have it; some distro builds do not).
node -e 'const [a,b]=process.versions.node.split(".").map(Number); if (a<24||(a===24&&b<9)) process.exit(1)' \
  || { echo "error: Node >= 24.9 required (found $(node -v 2>/dev/null || echo none))" >&2; exit 1; }
node --input-type=module -e 'process.exit(process.features.typescript ? 0 : 1)' \
  || { echo "error: this Node build lacks TypeScript type stripping; use an official nodejs.org build" >&2; exit 1; }

# pnpm 11 whose script entry is JavaScript (upstream runs `node $npm_execpath`), so a standalone pnpm binary will not do.
PNPM="$(command -v pnpm || true)"
if [[ -z "$PNPM" || "$("$PNPM" --version 2>/dev/null)" != 11.* || "$(head -c2 "$(readlink -f "$PNPM")")" != "#!" ]]; then
  echo "==> using corepack pnpm (install pnpm 11 with npm or corepack to skip this)"
  mkdir -p "$ROOT/.tools"
  corepack enable --install-directory "$ROOT/.tools" pnpm
  PNPM="$ROOT/.tools/pnpm"
fi

MODE="${1:---appimage}"
case "$MODE" in
  --dir)      SCRIPT="package:linux:$ARCH:dir"; FORMATS="" ;;
  --appimage) SCRIPT="package:linux:$ARCH"; FORMATS="AppImage" ;;
  --deb)      SCRIPT="package:linux:$ARCH"; FORMATS="deb" ;;
  --rpm)      SCRIPT="package:linux:$ARCH"; FORMATS="rpm" ;;
  --all)      SCRIPT="package:linux:$ARCH"; FORMATS="AppImage,deb,rpm" ;;
  *) echo "unknown option: $MODE" >&2; exit 2 ;;
esac

# Upstream reads release settings from apps/desktop/.env.linux and ignores same-named environment
# variables, so the maintainer is written into that file.
ENV_FILE="$UPSTREAM/apps/desktop/.env.linux"
MAINTAINER="${DSH_DESKTOP_LINUX_MAINTAINER:-dsh-desktop-linux builder <builder@localhost>}"
sed "s|^DSH_DESKTOP_LINUX_MAINTAINER=.*|DSH_DESKTOP_LINUX_MAINTAINER=\"$MAINTAINER\"|" "$ENV_FILE.example" > "$ENV_FILE"
if [[ -n "${DSH_DESKTOP_LINUX_UPDATE_URL:-}" ]]; then
  echo "DSH_DESKTOP_LINUX_UPDATE_URL=$DSH_DESKTOP_LINUX_UPDATE_URL" >> "$ENV_FILE"
  echo "==> auto-update feed: $DSH_DESKTOP_LINUX_UPDATE_URL"
else
  echo "==> no DSH_DESKTOP_LINUX_UPDATE_URL: this build will not auto-update"
fi

# Never let the build touch the real ~/.dsh.
export DSH_HOME="${DSH_BUILD_HOME:-$(mktemp -d -t dsh-build-home.XXXXXX)}"
[[ "$DSH_HOME" != "$HOME/.dsh" ]] || { echo "error: DSH_BUILD_HOME must not be ~/.dsh" >&2; exit 1; }

echo "==> target linux-$ARCH, script $SCRIPT${FORMATS:+, formats $FORMATS}"
( cd "$UPSTREAM" && "$PNPM" install --frozen-lockfile )
[[ -z "$FORMATS" ]] || export DSH_DESKTOP_TARGET_FORMATS="$FORMATS"
# Run inside the upstream tree so corepack honours its packageManager pin (pnpm 11).
( cd "$UPSTREAM/apps/desktop" && "$PNPM" run "$SCRIPT" )
echo "==> done: $UPSTREAM/apps/desktop/.desktop-build/targets/linux-$ARCH/unsigned-artifacts"
