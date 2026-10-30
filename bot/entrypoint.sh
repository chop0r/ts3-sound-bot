#!/bin/sh
# Before the bot starts: update yt-dlp (YouTube changes often) and build its config.
#   YTDLP_PROXY        - proxy for YouTube, e.g. socks5://host.docker.internal:1080. Empty = direct.
#   /app/data/cookies.txt - YouTube cookies (Netscape format), if YouTube asks to "confirm you are not a bot".
timeout 60 yt-dlp -U >/dev/null 2>&1 || echo "yt-dlp: update failed, using the current version"
CONF=/etc/yt-dlp.conf
{
  echo "--js-runtimes deno"
  echo "--no-warnings"
  [ -n "$YTDLP_PROXY" ] && echo "--proxy $YTDLP_PROXY"
  [ -f /app/data/cookies.txt ] && echo "--cookies /app/data/cookies.txt"
} > "$CONF"
echo "yt-dlp $(yt-dlp --version), settings:"; sed 's/^/  /' "$CONF"
exec /app/TS3AudioBot "$@"
