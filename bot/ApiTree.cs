// Channel tree, queue clear, command list/run and server info for the web panel. Compiled into ApiV2 (partial class) by the Dockerfile.
using Microsoft.AspNetCore.Http;
using System;
using System.Collections.Generic;
using System.Linq;
using TS3AudioBot.Algorithm;
using TS3AudioBot.CommandSystem;
using TS3AudioBot.Sessions;
using System.Threading.Tasks;
using TS3AudioBot.Audio;
using TS3AudioBot.Dependency;
using TSLib.Full.Book;

namespace TS3AudioBot.Web.Api
{
	public static partial class ApiV2
	{
		private static async Task ServerTree(HttpContext ctx)
		{
			var bot = GetBotOrFirst(ParseId(ctx));
			var book = bot.Injector.GetModuleOrThrow<Ts3Client>().Book;
			var self = book.Self();
			var channels = book.Channels.Values.ToArray()
				.Select((TSLib.Full.Book.Channel c) => new { id = c.Id.Value, parent = c.Parent.Value, order = c.Order.Value, name = c.Name }).ToArray();
			var clients = book.Clients.Values.ToArray()
				.Where(c => c.ClientType == TSLib.ClientType.Full)
				.Select(c => new
				{
					id = (int)c.Id.Value,
					name = c.Name,
					channel = c.Channel.Value,
					self = self != null && c.Id == self.Id,
					micMuted = c.InputMuted,
					spkMuted = c.OutputMuted,
				}).ToArray();
			await WriteJson(ctx, new { channels, clients, selfChannel = self?.Channel.Value }).ConfigureAwait(false);
		}

		private sealed class TreeMoveBody { public ulong ChannelId { get; set; } public string? Password { get; set; } }

		private static async Task TreeMove(HttpContext ctx)
		{
			var bot = GetBotOrFirst(ParseId(ctx));
			var body = await ReadBody<TreeMoveBody>(ctx).ConfigureAwait(false);
			var ts3 = bot.Injector.GetModuleOrThrow<Ts3Client>();
			// The TeamSpeak client may only be called from the bot scheduler thread, otherwise: "Cannot call from an outside thread"
			await bot.Scheduler.InvokeAsync(() => ts3.MoveTo((TSLib.ChannelId)body.ChannelId, body.Password)).ConfigureAwait(false);
			await WriteJson(ctx, new { ok = true }).ConfigureAwait(false);
		}

		// ---------- queue, commands, server info ----------

		private static async Task QueueClear(HttpContext ctx)
		{
			var bot = GetBotOrFirst(ParseId(ctx));
			PlaylistManagerOf(bot).Clear();
			await WriteJson(ctx, new { ok = true }).ConfigureAwait(false);
		}

		private static async Task CommandList(HttpContext ctx)
		{
			var manager = injector.GetModule<CommandManager>();
			var list = (manager?.AllCommands ?? Enumerable.Empty<BotCommand>())
				.Where(c => !c.InvokeName.StartsWith("_") && c.InvokeName != "wy" && !c.InvokeName.StartsWith("wy ") && c.InvokeName != "cache" && !c.InvokeName.StartsWith("cache "))
				.GroupBy(c => c.InvokeName)
				.Select(g => new
				{
					name = g.Key,
					description = g.Select(c => c.Description).FirstOrDefault(d => !string.IsNullOrEmpty(d)),
					overloads = g.Select(c => new
					{
						parameters = c.Parameter.Select(p => new { name = p.name, type = p.type, optional = p.optional }).ToArray(),
						usage = c.UsageList.Select(u => new { syntax = u.UsageSyntax, help = u.UsageHelp }).ToArray(),
						returns = c.Return,
					}).ToArray(),
				})
				.OrderBy(c => c.name, StringComparer.Ordinal)
				.ToArray();
			await WriteJson(ctx, new { commands = list }).ConfigureAwait(false);
		}

		private sealed class CmdBody { public string? Line { get; set; } }

		private static async Task CommandRun(HttpContext ctx)
		{
			var bot = GetBotOrFirst(ParseId(ctx));
			var body = await ReadBody<CmdBody>(ctx).ConfigureAwait(false);
			var line = (body.Line ?? "").Trim();
			if (line.Length > 0 && (line[0] == '!' || line[0] == CommandParser.DefaultCommandChar)) line = line.Substring(1).TrimStart();
			if (line.Length == 0)
			{
				await WriteError(ctx, "empty command").ConfigureAwait(false);
				return;
			}
			line = CommandParser.DefaultCommandChar + line; // without the command prefix (here "/") the parser treats the string as plain text
			var info = new ExecutionInformation(bot.Injector);
			info.AddModule(new CallerInfo(true) { SkipRightsChecks = true, CommandComplexityMax = 100, IsColor = false });
			info.AddModule<InvokerData>(InvokerData.Anonymous);
			info.AddModule(new AnonymousSession());
			info.AddModule(Filter.DefaultFilter);
			try
			{
				var res = await CommandManager.Execute(info, line).ConfigureAwait(false);
				await WriteJson(ctx, new { ok = true, result = res.AsString() }).ConfigureAwait(false);
			}
			catch (Exception ex)
			{
				await WriteJson(ctx, new { ok = false, error = ex.Message }).ConfigureAwait(false);
			}
		}

		private static async Task ServerInfo(HttpContext ctx)
		{
			var bot = GetBotOrFirst(ParseId(ctx));
			var book = bot.Injector.GetModuleOrThrow<Ts3Client>().Book;
			var s = book.Server;
			var self = book.Self();
			await WriteJson(ctx, new
			{
				name = s?.Name,
				nickname = s?.Nickname,
				platform = s?.Platform,
				version = s?.Version,
				protocol = s?.ProtocolVersion,
				created = s?.Created,
				maxClients = s?.MaxClients,
				virtualServerId = s?.VirtualServerId,
				welcome = s?.WelcomeMessage,
				ips = s == null ? new string[0] : s.Ips.Select(i => i.ToString()).ToArray(),
				clientsOnline = book.Clients.Values.Count(c => c.ClientType == TSLib.ClientType.Full),
				channels = book.Channels.Count,
				botName = self?.Name,
				botChannel = self?.Channel.Value,
			}).ConfigureAwait(false);
		}
	}
}
