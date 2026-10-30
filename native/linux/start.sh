#!/usr/bin/env bash
# Starts the bot in the background.
cd "$(dirname "$0")" || exit 1
if systemctl --user is-enabled ts3musicbot >/dev/null 2>&1; then
  systemctl --user start ts3musicbot && echo "Bot started (systemd user service ts3musicbot). Stop it with ./stop.sh"
else
  nohup ./run-bot.sh >/dev/null 2>&1 &
  echo "Bot started in the background. Stop it with ./stop.sh"
fi
