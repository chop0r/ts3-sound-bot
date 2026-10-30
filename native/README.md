# TS3 Sound Bot - installer without Docker

The bot is included in this archive, ready to run (self-contained, no .NET needed). The installer downloads three helper
tools from their official sites: **yt-dlp** and **deno** (needed by yt-dlp for YouTube). **ffmpeg** is bundled unchanged (GPL, see `licenses/ffmpeg/`). No Python is required.

[Русская версия](README.ru.md)

## Windows (x64)

1. Unpack the zip anywhere you want to keep the bot (for example `C:\TS3MusicBot`).
2. Double-click `install.cmd` and answer the questions (English / Russian).
3. The installer downloads the tools, writes the settings, starts the bot and prints the panel address and the access key.

Optional: the installer can start the bot automatically when you log in to Windows (a Task Scheduler task `TS3MusicBot`).

Daily use: `start.cmd` and `stop.cmd`. Logs: `data\logs\`. Update the tools: run `install.cmd` again, choose 1.
Unattended: `install.ps1 -NonInteractive -Server 192.168.1.10:9987 -Nickname MusicBot -Access lan -Port 58913 -Autostart`.
Remove completely: `uninstall.cmd` (or the "Delete the bot" button in the panel, Settings): stops the bot, removes autostart and the folder.

## Linux (x64)

1. `tar xzf ts3musicbot-native-linux-x64.tar.gz && cd ts3musicbot-native-linux-x64`
2. Install the system libraries once: `sudo apt install libicu72 libopus0` (Debian/Ubuntu names; other distributions: ICU and libopus).
3. `bash install.sh` and answer the questions. The installer downloads yt-dlp and deno into `bin/` (ffmpeg is bundled).

Optional: `--autostart` (or the question) creates a systemd **user** service `ts3musicbot`.
Remove completely: `./uninstall.sh` (or the panel button). Daily use: `./start.sh`, `./stop.sh`; logs in `data/logs/`. Unattended: `bash install.sh --non-interactive --server 192.168.1.10:9987 --nickname MusicBot --access lan --port 58913`.

## Using the bot

Open the panel (HTTPS with a self-signed certificate: the browser warns once, this is expected), sign in with the key, type a
title or paste a link. In TeamSpeak chat write commands starting with `/` to the bot, for example `/play <link>`, `/help`.
Put a YouTube `cookies.txt` (Netscape format) into `data/` if YouTube asks to confirm you are not a bot.

## Folders

`app/` the bot, `bin/` downloaded tools, `data/` your settings, playlists and logs (created by the installer), `settings.env` ports and proxy.
