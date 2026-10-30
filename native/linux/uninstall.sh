#!/usr/bin/env bash
# Removes the bot completely: stops it, disables the systemd user service (if any) and deletes the whole installation folder
# (settings, playlists, keys included). Run ./uninstall.sh, or press "Delete the bot" in the web panel. --yes skips the question.
ROOT="$(cd "$(dirname "$0")" && pwd)"
LANGC=en; grep -qx 'BOT_LANG=ru' "$ROOT/settings.env" 2>/dev/null && LANGC=ru
t() { if [ "$LANGC" = ru ]; then echo "$2"; else echo "$1"; fi; }
[ -f "$ROOT/app/TS3AudioBot" ] && [ -f "$ROOT/run-bot.sh" ] || { t "This is not a bot installation folder. Nothing was deleted." "Это не папка установки бота. Ничего не удалено."; exit 1; }
if [ "$1" != "--yes" ]; then
  t 'This will delete the bot completely, with all settings and playlists:' 'Бот будет удалён полностью, вместе с настройками и плейлистами:'
  echo "  $ROOT"
  read -r -p "$(t 'Type DELETE to continue: ' 'Введите DELETE, чтобы продолжить: ')" a
  [ "$a" = DELETE ] || { t Cancelled. Отменено.; exit 0; }
fi
sleep 2   # let the panel receive its answer
touch "$ROOT/stop.flag"
[ -d "$ROOT/data" ] && echo stop > "$ROOT/data/stop.request"   # clean disconnect from the server
sleep 6
if command -v systemctl >/dev/null 2>&1 && [ -f "$HOME/.config/systemd/user/ts3musicbot.service" ]; then
  systemctl --user disable --now ts3musicbot >/dev/null 2>&1
  rm -f "$HOME/.config/systemd/user/ts3musicbot.service"
  systemctl --user daemon-reload >/dev/null 2>&1
fi
pkill -f "$ROOT/run-bot.sh" 2>/dev/null
pkill -f "$ROOT/app/TS3AudioBot" 2>/dev/null
sleep 2
rm -rf "$ROOT"
