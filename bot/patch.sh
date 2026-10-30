#!/bin/sh
# Source patches applied to TS3AudioBot before the build (run from the Dockerfile, in /src).
set -e
# 1. Commands start with "/" instead of "!"
sed -i "s/public const char DefaultCommandChar = '!';/public const char DefaultCommandChar = '\/';/" TS3AudioBot/CommandSystem/CommandParser.cs
grep -q "DefaultCommandChar = '/'" TS3AudioBot/CommandSystem/CommandParser.cs
sed -i "s/strb.Append('!').Append(InvokeName)/strb.Append('\/').Append(InvokeName)/" TS3AudioBot/CommandSystem/BotCommand.cs
# Bot.cs also drops messages that do not start with "!", so "/..." commands would never reach the parser
sed -i 's|textMessage.Message.StartsWith("!", StringComparison.Ordinal)|textMessage.Message.StartsWith("/", StringComparison.Ordinal)|' TS3AudioBot/Bot.cs
grep -q 'StartsWith("/", StringComparison.Ordinal)' TS3AudioBot/Bot.cs
# 4. Chat confirmation: if a command ran silently (/play, /stop, /add ...) the bot answers "✔ Done: <command>"
[ "$(grep -c 'if (!string.IsNullOrEmpty(s))' TS3AudioBot/Bot.cs)" = 1 ]
sed -i 's|if (!string.IsNullOrEmpty(s))|if (string.IsNullOrEmpty(s)) s = "✔ Done: " + (command.Length > 80 ? command.Substring(0, 80) + "…" : command);\n\t\t\t\tif (!string.IsNullOrEmpty(s))|' TS3AudioBot/Bot.cs
grep -q 'Done: ' TS3AudioBot/Bot.cs
# 2. /restart command: the process exits and Docker (restart: unless-stopped) or run-bot.* starts the bot again
cat > /tmp/restart.cs <<'EOF'
		[Command("restart", "_undocumented")]
		public static string CommandRestart(Bot bot)
		{
			// stop the bot cleanly first (like /bot disconnect), otherwise the server keeps a ghost client with the same identity for about a minute
			_ = System.Threading.Tasks.Task.Run(async () =>
			{
				await System.Threading.Tasks.Task.Delay(800);
				try { await bot.Scheduler.InvokeAsync(async () => await bot.Stop()); }   // like BotManager: Stop only on the bot thread
				catch (System.Exception ex) { System.Console.WriteLine("restart: stop failed: " + ex.Message); }
				await System.Threading.Tasks.Task.Delay(1500);
				System.Environment.Exit(0);
			});
			return "Restarting, back in about 10 seconds...";
		}

EOF
line=$(grep -n '\[Command("seek")\]' TS3AudioBot/MainCommands.cs | head -1 | cut -d: -f1)
[ -n "$line" ]
sed -i "$((line - 1))r /tmp/restart.cs" TS3AudioBot/MainCommands.cs
grep -q 'Command("restart"' TS3AudioBot/MainCommands.cs
# 3. Allow Cyrillic command names (aliases such as /стоп)
sed -i 's/\[a-z\\d\]/[a-z\\dа-яё]/g' TS3AudioBot/CommandSystem/CommandManager.cs
grep -q 'а-яё' TS3AudioBot/CommandSystem/CommandManager.cs
echo "patch cyrillic ok"
# 5. /commands: list of all commands with short examples (keep in sync with the README)
if grep -q 'Command("commands"' TS3AudioBot/MainCommands.cs; then echo "the commands command already exists in the sources"; exit 1; fi
cat > /tmp/commands.cs <<'EOF'
		[Command("commands", "_undocumented")]
		public static string CommandCommands() => @"[b]Playback[/b]
/yt <title> — search and play: /yt imagine dragons believer
/play <link> — play a link: /play https://youtu.be/...
/add <link> — add to the queue: /add https://youtu.be/...
/search from youtube <title> — search; /search play 2 — play result no. 2
/pause — pause/resume · /stop — stop
/next · /previous — next/previous track · /song — what is playing
/volume 40 — set the volume (no number: show the current one)
/seek 1:30 — seek · /clear — clear the queue
/loop — repeat all · /repeat one | off
/shuffle — shuffle · /random off — turn it off
[b]Playlists[/b] (quote names with spaces)
/newlist rock — create · /playlists — list all playlists
/addto rock <link> — add a track
/playlist rock — play · /showlist rock — show tracks
/list item delete rock 3 — remove track no. 3
/list delete rock — delete the playlist
/list import rock <YouTube playlist link> — import
[b]Misc[/b]
/history last — recent tracks; /history play 2 — play again
/restart — restart the bot (about 10-15 s)
/help command play — details about a command
/commands — this list";

EOF
line=$(grep -n '\[Command("seek")\]' TS3AudioBot/MainCommands.cs | head -1 | cut -d: -f1)
[ -n "$line" ]
sed -i "$((line - 1))r /tmp/commands.cs" TS3AudioBot/MainCommands.cs
grep -q 'Command("commands"' TS3AudioBot/MainCommands.cs
echo "patch ok"
