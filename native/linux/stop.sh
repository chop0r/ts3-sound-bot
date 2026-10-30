#!/usr/bin/env bash
# Stops the bot.
cd "$(dirname "$0")" || exit 1
echo stop > stop.flag
systemctl --user stop ts3musicbot >/dev/null 2>&1
[ -f bot.pid ] && kill "$(cat bot.pid)" 2>/dev/null
sleep 1
[ -f bot.pid ] && kill -9 "$(cat bot.pid)" 2>/dev/null
rm -f bot.pid
echo "Bot stopped."
