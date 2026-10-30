# Notices

This project was created with the help of an AI assistant (Claude by Anthropic).

# Third-party components

- **TS3AudioBot** by Splamy and contributors, in the maintained fork by goD0S
  (https://github.com/goD0S/TS3AudioBot), Open Software License 3.0. It is fetched from the upstream repository at build time and
  patched by the files in `bot/`. The web panel in `webui/` started from that fork's `WebInterfaceV2` and is a derivative work.
- **yt-dlp** (Unlicense), **deno** (MIT) and **ffmpeg** (LGPL/GPL, depending on the build) are downloaded by the installers or while
  building the Docker image; they are not part of this repository and keep their own licenses.
- **Vue 3** (MIT) and **Vite** (MIT) build the web panel.
