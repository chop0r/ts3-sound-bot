#!/usr/bin/env bash
# Runs the bot in a loop (the /restart command exits the process; this script starts it again).
# stop.sh creates stop.flag, which ends the loop. Used by start.sh and by the systemd service.
cd "$(dirname "$0")" || exit 1
ROOT="$(pwd)"
rm -f stop.flag
export PATH="$ROOT/bin:$PATH"
export BOT_UNINSTALL="$ROOT/uninstall.sh"   # used by the "uninstall" command (web panel button)

proxy=""
BOT_LANG="$(sed -n 's/^BOT_LANG=//p' settings.env 2>/dev/null | head -1)"; export BOT_LANG
[ -f settings.env ] && proxy="$(sed -n 's/^YTDLP_PROXY=//p' settings.env | head -1)"
{
  echo "--js-runtimes deno"
  echo "--no-warnings"
  [ -n "$proxy" ] && echo "--proxy $proxy"
  [ -f data/cookies.txt ] && echo "--cookies \"$ROOT/data/cookies.txt\""
} > bin/yt-dlp.conf

# yt-dlp updates itself on every start (YouTube changes often)
[ -x bin/yt-dlp ] && timeout 60 bin/yt-dlp -U >/dev/null 2>&1

cd data || exit 1
while true; do
  "$ROOT/app/TS3AudioBot" --non-interactive --stats-disabled &
  echo $! > "$ROOT/bot.pid"
  wait $!
  [ -f "$ROOT/stop.flag" ] && break
  sleep 3
done
