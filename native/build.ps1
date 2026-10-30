# Builds the Docker-free packages: dist/ts3musicbot-native-win-x64.zip and dist/ts3musicbot-native-linux-x64.tar.gz
# (needs Docker only to compile the bot; the packages themselves do not need it).
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
$ctx = Join-Path $PSScriptRoot 'build/ctx'
$out = Join-Path $PSScriptRoot 'build/out'
$dist = Join-Path $PSScriptRoot 'dist'
foreach ($d in @($ctx, $out, $dist)) { if (Test-Path $d) { Remove-Item -Recurse -Force $d } }
New-Item -ItemType Directory -Force -Path $ctx, $dist | Out-Null
Copy-Item -Recurse -Force (Join-Path $PSScriptRoot '../bot') (Join-Path $ctx 'bot')
Copy-Item -Recurse -Force (Join-Path $PSScriptRoot '../webui') (Join-Path $ctx 'webui')
Remove-Item -Recurse -Force (Join-Path $ctx 'webui/node_modules'), (Join-Path $ctx 'webui/dist') -ErrorAction SilentlyContinue

$ErrorActionPreference = 'Continue'
docker build -f build/Dockerfile --target export --output "type=local,dest=$out" $ctx
if ($LASTEXITCODE -ne 0) { throw 'docker build failed' }
$ErrorActionPreference = 'Stop'

function Pack([string]$rid, [string]$scriptDir, [string]$archive) {
    $stage = Join-Path $PSScriptRoot "build/stage/ts3musicbot-native-$rid"
    if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
    New-Item -ItemType Directory -Force -Path $stage | Out-Null
    Copy-Item -Recurse -Force (Join-Path $out $rid) (Join-Path $stage 'app')
    Copy-Item -Recurse -Force (Join-Path $PSScriptRoot "$scriptDir/*") $stage
    Copy-Item -Recurse -Force (Join-Path $PSScriptRoot '../templates') $stage
    Copy-Item -Force (Join-Path $PSScriptRoot '../LICENSE'), (Join-Path $PSScriptRoot '../NOTICE.md'), (Join-Path $PSScriptRoot 'README.md'), (Join-Path $PSScriptRoot 'README.ru.md') $stage
    & tar -a -c -f (Join-Path $dist $archive) -C (Join-Path $PSScriptRoot 'build/stage') "ts3musicbot-native-$rid"
}
Pack 'win-x64' 'win' 'ts3musicbot-native-win-x64.zip'
Pack 'linux-x64' 'linux' 'ts3musicbot-native-linux-x64.tar.gz'
Get-ChildItem $dist | Format-Table Name, Length
