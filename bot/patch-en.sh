#!/bin/sh
# Error messages of the web API are Chinese in the fork: translate them to English (the panel itself is translated through webui/src/locales). Runs in /src.
set -e
A=TS3AudioBot/Web/ApiV2.cs
W=TS3AudioBot/Web/WebServer.cs
sed -i \
  -e 's|不存在或未运行|does not exist or is not running|g' \
  -e 's|当前没有正在运行的 bot|No bot is running|g' \
  -e 's|需要 url 或 listId|url or listId is required|g' \
  -e 's|需要 url|url is required|g' \
  -e 's|需要网易云歌单链接或 id|NetEase playlist link or id is required|g' \
  -e 's|netease resolver 不可用|netease resolver unavailable|g' \
  -e 's|缺少搜索词|search query is missing|g' \
  -e 's|缺少 url 参数|url parameter is missing|g' \
  -e 's|密钥错误或尝试过于频繁，请稍后再试|Wrong key or too many attempts, try again later|g' \
  -e 's|请先粘贴 MUSIC_U cookie|Paste the MUSIC_U cookie first|g' \
  -e 's|cookie 无效或已过期|cookie is invalid or expired|g' \
  -e 's|需要实例名 name|instance name is required|g' \
  -e 's|实例名只能包含字母数字下划线连字符|instance name may contain only letters, digits, underscores and hyphens|g' \
  -e 's|找不到该 bot 实例|Bot instance not found|g' \
  -e 's|该实例未在运行|This instance is not running|g' \
  -e 's|name 不能为空|name must not be empty|g' \
  -e 's|需要 autoRun 布尔值|autoRun (boolean) is required|g' \
  $A
sed -i \
  -e 's|需要密钥登录|Access key required|g' \
  -e 's|请求格式无效或请求体过大|Invalid request or request body too large|g' \
  -e 's|服务器内部错误|Internal server error|g' \
  $W
# if Chinese strings remain in response texts, the build stops so they are not missed
export LC_ALL=C.UTF-8
! grep -nP '(WriteError|LocalStr|WriteAsync|message =|error =).*[\x{4e00}-\x{9fff}]' $A $W
