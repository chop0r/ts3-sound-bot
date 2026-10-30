# Builds the release archives into dist/ :
#   ts3-sound-bot-<version>-docker-installer.zip
#   ts3-sound-bot-<version>-native-win-x64.zip
#   ts3-sound-bot-<version>-native-linux-x64.tar.gz
# Needs Docker (the bot is compiled in a container) and tar (Windows 10+, Linux, macOS).
param([string]$Version = 'dev')
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $root
$dist = Join-Path $root 'dist'
if (Test-Path $dist) { Remove-Item -Recurse -Force $dist }
New-Item -ItemType Directory -Force -Path $dist | Out-Null

# ---- Docker installer: the repository layout flattened (installer files next to bot/ and webui/)
$name = "ts3-sound-bot-$Version-docker-installer"
$stage = Join-Path $dist "stage/$name"
New-Item -ItemType Directory -Force -Path $stage | Out-Null
foreach ($f in 'Dockerfile', 'docker-compose.yml', 'install.ps1', 'install.sh', 'install.cmd', 'README.md', 'README.ru.md') {
    Copy-Item -LiteralPath (Join-Path $root "docker/$f") -Destination $stage
}
Copy-Item -Recurse -Path (Join-Path $root 'bot'), (Join-Path $root 'templates') -Destination $stage
Copy-Item -Recurse -LiteralPath (Join-Path $root 'webui') -Destination (Join-Path $stage 'webui')
Remove-Item -Recurse -Force (Join-Path $stage 'webui/node_modules'), (Join-Path $stage 'webui/dist'), (Join-Path $stage 'webui/dev') -ErrorAction SilentlyContinue
Copy-Item -LiteralPath (Join-Path $root 'LICENSE'), (Join-Path $root 'NOTICE.md'), (Join-Path $root '.dockerignore') -Destination $stage
& tar -a -c -f (Join-Path $dist "$name.zip") -C (Join-Path $dist 'stage') $name
if ($LASTEXITCODE -ne 0) { throw 'tar failed' }

# ---- installers without Docker
& (Join-Path $root 'native/build.ps1')
Copy-Item (Join-Path $root 'native/dist/ts3musicbot-native-win-x64.zip') (Join-Path $dist "ts3-sound-bot-$Version-native-win-x64.zip")
Copy-Item (Join-Path $root 'native/dist/ts3musicbot-native-linux-x64.tar.gz') (Join-Path $dist "ts3-sound-bot-$Version-native-linux-x64.tar.gz")

Remove-Item -Recurse -Force (Join-Path $dist 'stage')
Get-ChildItem $dist | Format-Table Name, Length
