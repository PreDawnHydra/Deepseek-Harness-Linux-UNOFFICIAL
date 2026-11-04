# DeepSeek Harness Desktop for Linux (unofficial)

An unofficial port of the [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) **Desktop app** (`apps/desktop`, the Electron shell) to Linux. It produces an AppImage, a `.deb` and an `.rpm` for x64 and arm64.

Upstream ships the Desktop app only for macOS and Windows (`apps/desktop/packaging/README.md`: *"Linux is not a supported Desktop release target."*). This port is the same official Electron application built from upstream source with a small patch series. It is not a separate reimplementation.

> **Not affiliated with DeepSeek.** The builds are unsigned and have no auto-update channel. Read the upstream [safety notice](https://github.com/deepseek-ai/deepseek-harness/blob/master/SAFETY.md) before you run it.

**You may not need this.** The harness CLI and Web UI already run on Linux officially:

```sh
npx @deepseek-ai/dsh web     # Node 24.9+, opens http://127.0.0.1:3080
```

This port is for people who want the native Desktop window, tray and bundled runtime.

## Upstream version

| | |
|---|---|
| Upstream tag | `dsh-v0.2.2-rc.1` |
| Upstream commit | `66491b05e3f05ad35bcdd4f6cd7ed26041d9e3db` |

The pin lives in [`upstream.env`](upstream.env).

## Install

Download the artifacts from this repo's Releases page, or from the latest **build** workflow run under Actions.

| Distribution | Format | How |
|---|---|---|
| Any | AppImage | `chmod +x deepseek-harness-*.AppImage && ./deepseek-harness-*.AppImage` |
| Debian / Ubuntu | deb | `sudo apt install ./deepseek-harness-*.deb` |
| Fedora / RHEL | rpm | `sudo dnf install ./deepseek-harness-*.rpm` |

The app keeps its data in `~/.dsh/profiles/desktop`, the same layout as on macOS and Windows.

## Build from source

You need Node 24.9 or newer from nodejs.org (some distro builds lack TypeScript type stripping, which upstream requires), git, and `rpmbuild` if you want the rpm. pnpm 11 is picked up automatically through corepack.

```sh
git clone https://github.com/PreDawnHydra/Deepseek-Harness-Linux-UNOFFICIAL.git
cd Deepseek-Harness-Linux-UNOFFICIAL
./scripts/fetch-upstream.sh     # clone the pinned upstream tag into ./upstream
./scripts/apply-patches.sh      # apply patches/ and place the tray icon
./scripts/build.sh --all        # AppImage + deb + rpm  (or --appimage / --deb / --rpm / --dir)
```

Artifacts land in `upstream/apps/desktop/.desktop-build/targets/linux-<arch>/unsigned-artifacts/`. Build on the target architecture; cross-building is not supported because packaging runs the target's Electron, Node and Python.

Set `DSH_DESKTOP_LINUX_MAINTAINER="Name <email>"` to change the deb/rpm maintainer field.

## What the patches change

All changes are scoped to Linux; macOS and Windows behaviour is untouched.

| Patch | What it does |
|---|---|
| 0001, 0002 | Add `linux-x64` / `linux-arm64` to the Desktop target model and the packaging entry point |
| 0003 | electron-builder Linux config: AppImage/deb/rpm targets, icon, `.desktop` entry, keeps the Chromium sandbox on |
| 0004 | Download and extract the Linux Electron distribution |
| 0005, 0011 | `.env.linux` release settings and deb/rpm package metadata |
| 0006 | `package:linux:*` scripts; keep the official brand and title in unsigned Linux builds |
| 0007 | Upstream tests accept the Linux targets |
| 0008, 0009, 0017 | Run the Host on the bundled standalone Node instead of Electron's Node mode (works around electron/electron#46323, where Electron's glib crashes libvips on Linux) and pass the resources path it needs |
| 0010 | Skip the mandatory-update policy, which has no Linux channel |
| 0012 | Read the build commit from the environment when building from a release archive |
| 0013 | System tray (StatusNotifierItem) with a Linux PNG icon |
| 0016 | Draw the same in-page caption menubar Windows uses, and hide the native menu bar |

Numbers 0014 and 0015 are intentionally unused.

## Credits

The patch series is derived from [ffyfox/dsh-desktop-linux](https://github.com/ffyfox/dsh-desktop-linux) (MIT). That project's optional extras (glass and frameless window modes) are left out here so the app stays a 1:1 match with the official Desktop app. DeepSeek Harness is © DeepSeek-AI, MIT licensed.

## Updating to a new upstream release

1. Change `UPSTREAM_TAG` and `UPSTREAM_COMMIT` in `upstream.env`.
2. `REFRESH=1 ./scripts/fetch-upstream.sh && ./scripts/apply-patches.sh --check`
3. Fix any patch that no longer applies, regenerate it with `git -C upstream diff -- <files>`, and rebuild.
