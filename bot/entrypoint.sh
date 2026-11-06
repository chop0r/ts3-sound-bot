#!/bin/sh
# Before the bot starts: update yt-dlp (YouTube changes often) and build its config.
#   YTDLP_PROXY        - proxy for YouTube, e.g. socks5://host.docker.internal:1080. Empty = direct.
#   /app/data/cookies.txt - YouTube cookies (Netscape format), if YouTube asks to "confirm you are not a bot".
# before the bot starts, so the update never competes with its first requests (120 s: the binary is ~40 MB, on a slow link 60 s was not enough)
timeout 120 yt-dlp -U >/dev/null 2>&1 || echo "yt-dlp: update failed, using the current version"
CONF=/etc/yt-dlp.conf
{
  echo "--js-runtimes deno"
  echo "--no-warnings"
  [ -n "$YTDLP_PROXY" ] && echo "--proxy $YTDLP_PROXY"
  [ -f /app/data/cookies.txt ] && echo "--cookies /app/data/cookies.txt"
} > "$CONF"
echo "yt-dlp $(yt-dlp --version), settings:"; sed 's/^/  /' "$CONF"
# docker stop sends SIGTERM: turn it into the bot's own graceful stop (stop.request), otherwise the server keeps a ghost client for about a minute
/app/TS3AudioBot "$@" &
pid=$!
trap 'touch /app/data/stop.request' TERM INT
while kill -0 "$pid" 2>/dev/null; do wait "$pid"; done
wait "$pid"
