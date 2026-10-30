# TS3 Sound Bot - Docker installer

A ready-to-install music bot for TeamSpeak 3 (patched [TS3AudioBot fork](https://github.com/goD0S/TS3AudioBot) plus a new web panel).
It plays YouTube and direct links, has playlists, a queue, and a web panel (English / Russian, dark / light / hacker themes,
works on phones). Everything runs in Docker, nothing is installed on your system besides Docker itself.

[Русская версия](README.ru.md)

## Install

You need **Docker** (Docker Desktop on Windows / macOS, Docker Engine with the compose plugin on Linux) and internet access
(the first build downloads the bot sources and takes a few minutes).

- **Windows:** double-click `install.cmd` (or run `powershell -ExecutionPolicy Bypass -File install.ps1`).
- **Linux / macOS:** `bash install.sh`

The installer asks (English or Russian) for:

| Question | Notes |
|---|---|
| TeamSpeak server address | IP or host name, optional `:port`. `localhost` is replaced with `host.docker.internal` (the bot lives in a container). |
| Server password | Optional. |
| Bot nickname, channel | Channel is optional (`Lobby/Music` or `/12`). |
| Who opens the web panel | Only this computer, or the local network. |
| Panel port and access key | The key is generated if you press Enter. It is the only password of the panel. |
| Advanced settings | Optional: a YouTube proxy, asked only if you answer yes. |

Then it builds the image, starts the bot and prints the panel address and the key.
The panel uses HTTPS with a self-signed certificate: the browser warns once, this is expected.

Unattended: `install.ps1 -NonInteractive -Server 192.168.1.10:9987 -Nickname MusicBot -Access lan -Port 58913`
or `bash install.sh --non-interactive --server 192.168.1.10:9987 --nickname MusicBot --access lan --port 58913`
(more options: `-Language`, `-ServerPassword`, `-Channel`, `-Key`, `-Proxy`, `-ContainerName`, `-NoStart`).

## Use

- Open the panel, sign in with the key. Type a title or paste a link on the Home tab.
- In TeamSpeak chat write commands starting with `/` to the bot, for example `/play <link>`, `/help`.
  All commands with descriptions and a console are in the panel under Settings > Commands.
- Optional: put a YouTube `cookies.txt` (Netscape format) into `data/` if YouTube asks to confirm you are not a bot.

## Manage

Run in this folder: `docker compose logs -f`, `docker compose stop`, `docker compose start`.
To update the bot (new yt-dlp, rebuild) run the installer again and choose "Update". "Reconfigure" asks the questions again
and keeps playlists and the bot identity. Remove everything: `docker compose down -v`, then delete the folder.

## Files

`data/` holds your settings, playlists and logs (created by the installer, never shipped). `.env` holds the ports and names.
`bot/` holds our patches for the bot and `webui/` the web panel (Vue 3 + Vite; translations in `webui/src/locales`).
