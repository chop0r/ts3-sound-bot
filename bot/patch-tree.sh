#!/bin/sh
# Channel tree for the web panel: expose the client Book, make ApiV2 partial and register the routes (code in ApiTree.cs). Runs in /src.
set -e
sed -i 's|public Task DeleteAvatar() => ts3FullClient.DeleteAvatar().UnwrapThrow();|&\n\t\tpublic TSLib.Full.Book.Connection Book => ts3FullClient.Book;|' TS3AudioBot/Ts3Client.cs
grep -q 'Connection Book' TS3AudioBot/Ts3Client.cs
sed -i 's|public static class ApiV2|public static partial class ApiV2|' TS3AudioBot/Web/ApiV2.cs
grep -q 'static partial class ApiV2' TS3AudioBot/Web/ApiV2.cs
sed -i 's|^\(\s*\)new Route("GET", "/bots",|\1new Route("GET", "/bot/{id}/tree", (c, p) => ServerTree(c)),\n\1new Route("POST", "/bot/{id}/tree/move", (c, p) => TreeMove(c)),\n\1new Route("POST", "/bot/{id}/queue/clear", (c, p) => QueueClear(c)),\n\1new Route("GET", "/commands", (c, p) => CommandList(c)),\n\1new Route("POST", "/bot/{id}/cmd", (c, p) => CommandRun(c)),\n\1new Route("GET", "/bot/{id}/serverinfo", (c, p) => ServerInfo(c)),\n&|' TS3AudioBot/Web/ApiV2.cs
grep -q 'ServerTree(c)' TS3AudioBot/Web/ApiV2.cs
