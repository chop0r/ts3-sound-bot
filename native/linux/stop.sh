#!/usr/bin/env bash
# Stops the bot.
cd "$(dirname "$0")" || exit 1
echo stop > stop.flag
# ask the bot to disconnect cleanly first (up to 10 s)
[ -d data ] && echo stop > data/stop.request
for i in $(seq 20); do pgrep -f "$PWD/app/TS3AudioBot" >/dev/null || break; sleep 0.5; done
rm -f data/stop.request
systemctl --user stop ts3musicbot >/dev/null 2>&1
[ -f bot.pid ] && kill "$(cat bot.pid)" 2>/dev/null
sleep 1
[ -f bot.pid ] && kill -9 "$(cat bot.pid)" 2>/dev/null
rm -f bot.pid
echo "Bot stopped."
