# Builds the self-contained bot (Windows x64 + Linux x64) with our patches and the web panel.
# Used by build.ps1: docker build -f build/Dockerfile --target export --output type=local,dest=build/out build/ctx
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG REPO=https://github.com/goD0S/TS3AudioBot.git
ARG REF=d939067d524f3cfe1f3ce9c42e2cab407e4313b7
RUN git init /src && cd /src && git remote add origin ${REPO} && git fetch --depth 1 origin ${REF} && git checkout -q FETCH_HEAD
WORKDIR /src
COPY bot/api-playlists.patch /tmp/api-playlists.patch
RUN git apply --whitespace=nowarn /tmp/api-playlists.patch
COPY bot/patch.sh /tmp/patch.sh
RUN sh /tmp/patch.sh
RUN sed -i -E '\#new Route\("[A-Z]+", "/(bot/\{id\}/netease/|netease/|cache",)#d' TS3AudioBot/Web/ApiV2.cs && ! grep -E 'new Route\(' TS3AudioBot/Web/ApiV2.cs | grep -qiE 'netease|"/cache"'
COPY bot/ApiTree.cs /src/TS3AudioBot/Web/ApiTree.cs
COPY bot/patch-tree.sh /tmp/patch-tree.sh
RUN sh /tmp/patch-tree.sh
COPY bot/patch-en.sh /tmp/patch-en.sh
RUN sh /tmp/patch-en.sh
RUN dotnet publish TS3AudioBot -c Release -r win-x64 --self-contained true -o /out/win-x64
RUN dotnet publish TS3AudioBot -c Release -r linux-x64 --self-contained true -o /out/linux-x64

FROM node:22-bookworm AS web
WORKDIR /src/WebInterfaceV2
COPY webui/package.json webui/package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY webui/ ./
RUN npm run build

FROM scratch AS export
COPY --from=build /out /
COPY --from=web /src/WebInterfaceV2/dist /win-x64/WebInterface
COPY --from=web /src/WebInterfaceV2/dist /linux-x64/WebInterface
