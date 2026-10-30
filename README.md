# TS3 Sound Bot

A music bot for TeamSpeak 3 with a modern web panel, easy installers and no Chinese-only leftovers. It is a set of patches and a new web
panel on top of the maintained [TS3AudioBot fork by goD0S](https://github.com/goD0S/TS3AudioBot), plus installers for Docker and for
Windows / Linux without Docker.

[Русская версия](README.ru.md)

![Home tab, dark theme](docs/screenshots/home-dark.jpg)

## Features

- Plays YouTube (search by title or artist, links, playlists) and direct links; queue, playlists you create and edit in the panel.
- **Web panel** (Vue 3): player, queue, playlists, channel tree where you drag the bot to another channel, instances, server info,
  a console and a list of all commands with descriptions. Works on phones.
- **English / Russian** interface (add a language with one JSON file), **dark / light / hacker** themes, keyboard shortcuts.
- Commands in the TeamSpeak chat start with `/` (for example `/play <link>`, `/help`).
- Interactive installers (English / Russian) that ask for the server address, nickname, panel access and key.
- yt-dlp updates itself on every start (YouTube changes often).

| | |
|---|---|
| ![Light theme](docs/screenshots/settings-light.jpg) | ![Hacker theme on a phone](docs/screenshots/home-hacker-mobile.jpg) |

## Install

Download an archive from the [Releases](../../releases) page, or build it yourself (see below).

| Archive | For whom | Needs |
|---|---|---|
| `*-docker-installer.zip` | Windows, Linux, macOS | [Docker](https://docs.docker.com/get-docker/) |
| `*-native-win-x64.zip` | Windows | nothing (the installer downloads yt-dlp, deno and ffmpeg) |
| `*-native-linux-x64.tar.gz` | Linux | `libicu` and `libopus0` (the installer checks and tells you) |

Unpack, run the installer (`install.cmd` / `install.ps1` / `install.sh`), answer the questions. Each archive has its own short README.
The panel is served over HTTPS with a self-signed certificate: the browser warns once, this is expected.

## Repository layout

| Folder | What it is |
|---|---|
| `bot/` | Patches applied to the upstream fork at build time (`patch*.sh`, `api-playlists.patch`) and `ApiTree.cs` with the extra API. |
| `webui/` | The web panel (Vue 3 + Vite). Translations: `webui/src/locales`. `npm run mock` + `npm run dev:mock` develop it without a bot. |
| `docker/` | Docker installer (Dockerfile, compose file, `install.ps1`, `install.sh`). |
| `native/` | Installers without Docker and the script that builds the packages (`native/build.ps1`). |
| `templates/` | Config templates used by the installers. |
| `scripts/` | `package.ps1` builds the release archives. |

## Build from source

```bash
# Docker installer straight from the repository
cd docker && ./install.sh          # or install.ps1 on Windows

# Release archives (needs Docker and PowerShell 5.1+ / pwsh)
pwsh scripts/package.ps1 -Version 1.0.0     # result in dist/
```

The bot itself is compiled from the pinned upstream commit (see `REF` in the Dockerfiles); the patches in `bot/` are written for that commit.

## Security notes

The panel has one shared access key. By default the installers make it reachable from the same computer only; choose "local network"
only on networks you trust, and put a reverse proxy with a real certificate in front of it before exposing it to the internet.
Never publish your `data/` folder (it holds the key, the bot identity and your server password).

## Made with AI

This project was created with the help of an AI assistant (Claude by Anthropic) under the author's direction: the code, the installers
and the documentation were written and tested together with it. As with any software, read the code and test it before relying on it.

## Disclaimer

Not affiliated with or endorsed by TeamSpeak Systems or YouTube. TeamSpeak is a trademark of its owner. Playing content from YouTube may be
restricted by its terms of service in your country; use the bot responsibly and for personal, non-commercial purposes.

## License and credits

Everything here is licensed under the [Open Software License 3.0](LICENSE), because it is built on, and derived from, the upstream
TS3AudioBot code (Splamy/TS3AudioBot, goD0S fork), which uses that license. See [NOTICE.md](NOTICE.md) for third-party components
(yt-dlp, deno, ffmpeg are downloaded at install or build time and keep their own licenses).
