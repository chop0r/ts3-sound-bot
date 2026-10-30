# Notices

This project was created with the help of an AI assistant (Claude by Anthropic).

# Third-party components

- **TS3AudioBot** by Splamy and contributors, in the maintained fork by goD0S
  (https://github.com/goD0S/TS3AudioBot), Open Software License 3.0. It is fetched from the upstream repository at build time and
  patched by the files in `bot/`. The web panel in `webui/` started from that fork's `WebInterfaceV2` and is a derivative work.
- **yt-dlp** (Unlicense) and **deno** (MIT) are downloaded by the installers; **ffmpeg** (LGPL/GPL, depending on the build) is installed
  with the Docker image. None of them is part of this repository and each keeps its own license.
- The Docker-free release archives bundle an unmodified **ffmpeg** build (GPL v3: gyan.dev for Windows, johnvansickle.com for Linux)
  in `bin/`; its license text and source links are in `licenses/ffmpeg/`. It is a separate program, and you can replace it with any other build.
- **Vue 3** (MIT) and **Vite** (MIT) build the web panel.
