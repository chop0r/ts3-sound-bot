# TeamSpeak 3 music bot: maintained TS3AudioBot fork (goD0S, .NET 8) + our patches + web panel + fresh yt-dlp and deno.
# Build context is the repository root (docker/docker-compose.yml sets it). Normally built by install.ps1 / install.sh.

# ---- 1. bot from source (the fork is pinned to a commit the patches are written for)
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG REPO=https://github.com/goD0S/TS3AudioBot.git
ARG REF=d939067d524f3cfe1f3ce9c42e2cab407e4313b7
RUN git init /src && cd /src && git remote add origin ${REPO} && git fetch --depth 1 origin ${REF} && git checkout -q FETCH_HEAD
WORKDIR /src
# playlist create/edit API
COPY bot/api-playlists.patch /tmp/api-playlists.patch
RUN git apply --whitespace=nowarn /tmp/api-playlists.patch
# commands via "/" instead of "!", /restart, chat confirmations
COPY bot/patch.sh /tmp/patch.sh
RUN sh /tmp/patch.sh
# NetEase and its cache are not used: drop their HTTP routes
RUN sed -i -E '\#new Route\("[A-Z]+", "/(bot/\{id\}/netease/|netease/|cache",)#d' TS3AudioBot/Web/ApiV2.cs && ! grep -E 'new Route\(' TS3AudioBot/Web/ApiV2.cs | grep -qiE 'netease|"/cache"'
# extra panel API: channel tree, queue clear, command list/run, server info
COPY bot/ApiTree.cs /src/TS3AudioBot/Web/ApiTree.cs
COPY bot/patch-tree.sh /tmp/patch-tree.sh
RUN sh /tmp/patch-tree.sh
# API error messages in English
COPY bot/patch-en.sh /tmp/patch-en.sh
RUN sh /tmp/patch-en.sh
RUN dotnet publish TS3AudioBot -c Release -r linux-x64 --self-contained true -o /out

# ---- 1b. web panel (Vue 3 + Vite), translations in webui/src/locales
FROM node:22-bookworm AS web
WORKDIR /src/WebInterfaceV2
COPY webui/package.json webui/package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY webui/ ./
RUN npm run build

# ---- 2. runtime image
FROM debian:bookworm-slim
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl unzip ffmpeg libopus0 libicu72 python3 \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/lib/x86_64-linux-gnu/libopus.so.0 /usr/lib/x86_64-linux-gnu/libopus.so
# deno: JS engine yt-dlp needs for YouTube signatures
RUN curl -fsSL https://github.com/denoland/deno/releases/latest/download/deno-x86_64-unknown-linux-gnu.zip -o /tmp/deno.zip \
    && unzip -q /tmp/deno.zip -d /usr/local/bin && rm /tmp/deno.zip && deno --version
# yt-dlp (updated on every container start, see entrypoint.sh)
RUN curl -fsSL https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux -o /usr/local/bin/yt-dlp \
    && chmod +x /usr/local/bin/yt-dlp && ln -sf /usr/local/bin/yt-dlp /usr/local/bin/youtube-dl && yt-dlp --version
COPY --from=build /out /app
COPY --from=web /src/WebInterfaceV2/dist /app/WebInterface
COPY bot/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
WORKDIR /app/data
EXPOSE 58913
ENTRYPOINT ["/entrypoint.sh"]
