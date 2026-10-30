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
sed -i 's|if (!string.IsNullOrEmpty(s))|if (string.IsNullOrEmpty(s)) s = (System.Environment.GetEnvironmentVariable("BOT_LANG") == "ru" ? "✔ Выполнено: " : "✔ Done: ") + (command.Length > 80 ? command.Substring(0, 80) + "…" : command);\n\t\t\t\tif (!string.IsNullOrEmpty(s))|' TS3AudioBot/Bot.cs
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
			return System.Environment.GetEnvironmentVariable("BOT_LANG") == "ru" ? "Перезапускаюсь, вернусь секунд через 10..." : "Restarting, back in about 10 seconds...";
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
		public static string CommandCommands() => System.Environment.GetEnvironmentVariable("BOT_LANG") == "ru" ? CommandsRu : CommandsEn;

		private const string CommandsRu = @"[b]Воспроизведение[/b]
/yt <название> — найти и включить: /yt imagine dragons believer
/play <ссылка> — включить ссылку: /play https://youtu.be/...
/add <ссылка> — добавить в очередь: /add https://youtu.be/...
/search from youtube <название> — поиск; /search play 2 — включить результат №2
/pause — пауза/продолжить · /stop — остановить
/next · /previous — следующий/предыдущий трек · /song — что играет
/volume 40 — громкость (без числа: показать текущую)
/seek 1:30 — перемотка · /clear — очистить очередь
/loop — повтор всего · /repeat one | off
/shuffle — перемешать · /random off — выключить
[b]Плейлисты[/b] (имена с пробелами — в кавычках)
/newlist rock — создать · /playlists — все плейлисты
/addto rock <ссылка> — добавить трек
/playlist rock — включить · /showlist rock — показать треки
/list item delete rock 3 — удалить трек №3
/list delete rock — удалить плейлист
/list import rock <ссылка на плейлист YouTube> — импорт
[b]Разное[/b]
/history last — последние треки; /history play 2 — повторить
/restart — перезапуск бота (около 10-15 с)
/help command play — подробности о команде
/commands — этот список";

		private const string CommandsEn = @"[b]Playback[/b]
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
# 6. /uninstall DELETE: removes the whole installation (native installs only; Docker installs are removed with docker compose)
if grep -q 'Command("uninstall"' TS3AudioBot/MainCommands.cs; then echo "the uninstall command already exists in the sources"; exit 1; fi
cat > /tmp/uninstall.cs <<'EOF2'
		[Command("uninstall", "_undocumented")]
		public static string CommandUninstall(string confirm = null)
		{
			bool ru = System.Environment.GetEnvironmentVariable("BOT_LANG") == "ru";
			string script = System.Environment.GetEnvironmentVariable("BOT_UNINSTALL");
			if (string.IsNullOrEmpty(script) || !System.IO.File.Exists(script))
				return ru
					? "Это установка в Docker: удалите её на компьютере командой «docker compose down -v --rmi local» в папке установки, затем удалите папку."
					: "This is a Docker install: remove it on the computer with \"docker compose down -v --rmi local\" in the install folder, then delete the folder.";
			if (confirm != "DELETE")
				return ru ? "Это удалит бота полностью. Подтверждение: /uninstall DELETE" : "This deletes the bot completely. To confirm: /uninstall DELETE";
			var psi = System.OperatingSystem.IsWindows()
				? new System.Diagnostics.ProcessStartInfo("powershell.exe", "-NoProfile -ExecutionPolicy Bypass -File \"" + script + "\" -Yes")
				: new System.Diagnostics.ProcessStartInfo("setsid", "bash \"" + script + "\" --yes");
			psi.UseShellExecute = false;
			psi.CreateNoWindow = true;
			System.Diagnostics.Process.Start(psi);
			return ru ? "Удаляю бота и его файлы..." : "Deleting the bot and its files...";
		}

EOF2
line=$(grep -n '\[Command("seek")\]' TS3AudioBot/MainCommands.cs | head -1 | cut -d: -f1)
[ -n "$line" ]
sed -i "$((line - 1))r /tmp/uninstall.cs" TS3AudioBot/MainCommands.cs
grep -q 'Command("uninstall"' TS3AudioBot/MainCommands.cs
# 7. Graceful stop: stop.cmd / stop.sh / uninstall create "stop.request" in the data folder, the bot disconnects cleanly
#    (otherwise the server keeps a ghost client for about a minute and the next start cannot join)
line='await injector.GetModuleOrThrow<BotManager>().RunBots(setup.Interactive);'
[ "$(grep -cF "$line" TS3AudioBot/Core.cs)" = 1 ]
cat > /tmp/stopwatch.cs <<'EOF3'
			_ = System.Threading.Tasks.Task.Run(async () =>
			{
				while (true)
				{
					await System.Threading.Tasks.Task.Delay(500);
					try
					{
						if (!System.IO.File.Exists("stop.request")) continue;
						System.IO.File.Delete("stop.request");
						Log.Info("Stop requested (stop.request).");
						Stop();
						await System.Threading.Tasks.Task.Delay(5000);
						System.Environment.Exit(0);
					}
					catch (System.Exception) { }
				}
			});
EOF3
ln=$(grep -nF "$line" TS3AudioBot/Core.cs | cut -d: -f1)
sed -i "$((ln - 1))r /tmp/stopwatch.cs" TS3AudioBot/Core.cs
grep -q 'stop.request' TS3AudioBot/Core.cs
# 8. Search results can contain channels/playlists (ids longer than 11 chars, e.g. "UC..." for a channel): keep videos only, otherwise /yt fails on the first channel
sed -i "/SearchYoutubeDlAsync(string keyword)/,/ToArray/ s/entry => entry.id != null/entry => entry.id != null \&\& entry.id.Length == 11/" TS3AudioBot/ResourceFactories/Youtube/YoutubeResolver.cs
grep -q "entry.id.Length == 11" TS3AudioBot/ResourceFactories/Youtube/YoutubeResolver.cs
echo "patch ok"
