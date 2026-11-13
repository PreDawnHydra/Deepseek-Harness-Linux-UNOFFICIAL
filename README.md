# DeepSeek Harness Desktop for Linux (unofficial)

An unofficial port of the [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) **Desktop app** (`apps/desktop`, the Electron shell) to Linux. It produces an AppImage, a `.deb` and an `.rpm` for x64 and arm64.

Upstream ships the Desktop app only for macOS and Windows (`apps/desktop/packaging/README.md`: *"Linux is not a supported Desktop release target."*). This port is the same official Electron application built from upstream source with a small patch series. It is not a separate reimplementation.

> **Not affiliated with DeepSeek.** The builds are unsigned. Read the upstream [safety notice](https://github.com/deepseek-ai/deepseek-harness/blob/master/SAFETY.md) before you run it.

**You may not need this.** The harness CLI and Web UI already run on Linux officially:

```sh
npx @deepseek-ai/dsh web     # Node 24.9+, opens http://127.0.0.1:3080
```

This port is for people who want the native Desktop window, tray and bundled runtime.

## Upstream version

| | |
|---|---|
| Upstream tag | `dsh-v0.2.2-rc.3` |
| Upstream commit | `38a6a5c965aa99ab525161efb7cc5cf1fe62fced` |

The pin lives in [`upstream.env`](upstream.env).

## Install

Download the newest package from this repo's [Releases](../../releases/latest) page. You only do this once: after that, the app updates itself.

| Distribution | Format | How |
|---|---|---|
| Any | AppImage | `chmod +x deepseek-harness-*.AppImage && ./deepseek-harness-*.AppImage` |
| Debian / Ubuntu | deb | `sudo apt install ./deepseek-harness-*.deb` |
| Fedora / RHEL | rpm | `sudo dnf install ./deepseek-harness-*.rpm` |

The app keeps its data in `~/.dsh/profiles/desktop`, the same layout as on macOS and Windows.

## Automatic updates

Installed copies keep themselves current with DeepSeek's releases, and nobody has to rebuild anything.

1. **Tracking upstream.** The [`track-upstream`](.github/workflows/track-upstream.yml) workflow checks DeepSeek's `dsh-v*` tags every six hours. When a newer tag appears, it checks that the patch series still applies, moves the pin in `upstream.env`, builds x64 and arm64, and publishes a release here. If a patch no longer applies, it opens an issue and ships nothing.
2. **Updating installed apps.** Upstream's own updater (the same check, download and restart flow macOS and Windows use, plus **Check for Updates** in the app menu) is enabled on Linux by patch 0020. It polls `releases/latest/download/nightly-linux.yml` (or `nightly-linux-arm64.yml`) in this repo.
   - **AppImage:** the file replaces itself in place. Keep it somewhere you can write to, such as `~/Applications`.
   - **deb / rpm:** the new package downloads and installs after a password prompt (pkexec).
   - **Update channel:** the Stable / Nightly choice under Settings → General works, but this port has one release stream, so both channels get the same builds. Each release carries matching `stable-linux*.yml` files for that.

The feed has to be public, so this repository must stay public for updates to work. You can run the tracker by hand under Actions → track-upstream → Run workflow. GitHub disables scheduled workflows in a repo with no activity for 60 days, so the tracker makes a small keep-alive commit when upstream has been quiet for 45 days.

Builds from source get updates only when you set `DSH_DESKTOP_LINUX_UPDATE_URL` (see below).

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

Set `DSH_DESKTOP_LINUX_MAINTAINER="Name <email>"` to change the deb/rpm maintainer field, and `DSH_DESKTOP_LINUX_UPDATE_URL=https://github.com/<owner>/<repo>/releases/latest/download` to make the build auto-update from a feed.

## What the patches change

All changes are scoped to the Linux build. 0001–0020 keep the app 1:1 with the official one; 0021 is the one deliberate addition.

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
| 0020 | Turn on upstream's electron-updater for Linux when an https feed is configured (AppImage in place, deb/rpm through pkexec) |
| 0021 | Add a **Don't ask again** checkbox to the welcome screen's API-key page, so **Set up later** can skip the sign-in prompt on every launch. Saving a key clears it. Signing out still shows the welcome screen. |

Numbers 0014, 0015, 0018 and 0019 are intentionally unused.

## Credits

The patch series is derived from [ffyfox/dsh-desktop-linux](https://github.com/ffyfox/dsh-desktop-linux) (MIT). That project's optional extras (glass and frameless window modes) are left out here so the app stays a 1:1 match with the official Desktop app. DeepSeek Harness is © DeepSeek-AI, MIT licensed.

## Shipping a port-only fix

To ship a change to the patches before DeepSeek's next release, run Actions → **build** → Run workflow with *release* checked and *revision* set to `1` (then `2`, …). That publishes `v<upstream>.<date>.<revision>`, for example `v0.2.2-rc.1.20261104.1`. Installed apps see it as newer than the plain upstream version and older than the next upstream release. This only works while upstream is on a prerelease (`-rc.N`) version.

## Updating to a new upstream release by hand

The tracker normally does this for you. When it opens a "patches no longer apply" issue:

1. Change `UPSTREAM_TAG` and `UPSTREAM_COMMIT` in `upstream.env`.
2. `REFRESH=1 ./scripts/fetch-upstream.sh && ./scripts/apply-patches.sh --check`
3. Fix any patch that no longer applies, regenerate it with `git -C upstream diff -- <files>`, and push. The next tracker run publishes the release.
