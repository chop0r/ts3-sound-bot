# Removes the bot completely: stops it, deletes the autostart task and the whole installation folder (settings, playlists, keys included).
# Run uninstall.cmd, or press "Delete the bot" in the web panel. -Yes skips the question.
param([switch]$Yes, [string]$Target = '')
$ErrorActionPreference = 'Continue'
$root = if ($Target) { $Target } else { $PSScriptRoot }
$lang = 'en'
$st = Join-Path $root 'settings.env'
if (Test-Path -LiteralPath $st) { Get-Content -LiteralPath $st | ForEach-Object { if ($_ -match '^BOT_LANG=ru$') { $lang = 'ru' } } }
function T([string]$en, [string]$ru) { if ($lang -eq 'ru') { return $ru } else { return $en } }

# sanity check: never delete a folder that is not a bot installation
if (-not ((Test-Path -LiteralPath (Join-Path $root 'app\TS3AudioBot.exe')) -and (Test-Path -LiteralPath (Join-Path $root 'run-bot.ps1')))) {
    Write-Host (T 'This is not a bot installation folder. Nothing was deleted.' 'Это не папка установки бота. Ничего не удалено.') -ForegroundColor Red
    exit 1
}
if (-not $Yes) {
    Write-Host (T "This will delete the bot completely, with all settings and playlists:`n  $root" "Бот будет удалён полностью, вместе с настройками и плейлистами:`n  $root")
    $a = (Read-Host (T 'Type DELETE to continue' 'Введите DELETE, чтобы продолжить')).Trim()
    if ($a -cne 'DELETE') { Write-Host (T 'Cancelled.' 'Отменено.'); exit 0 }
}

# run the actual removal from a copy in %TEMP%: this script lives inside the folder that is being deleted
if (-not $Target) {
    $copy = Join-Path $env:TEMP ('tmb-uninstall-' + [guid]::NewGuid().ToString('N') + '.ps1')
    Copy-Item -LiteralPath $PSCommandPath -Destination $copy -Force
    Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"' + $copy + '"'), '-Yes', '-Target', ('"' + $root.TrimEnd('\') + '"')) -WindowStyle Hidden
    exit 0
}

Start-Sleep -Seconds 2   # let the panel receive its answer
Set-Content -LiteralPath (Join-Path $root 'stop.flag') -Value 'stop' -ErrorAction SilentlyContinue
Set-Content -LiteralPath (Join-Path $root 'data\stop.request') -Value 'stop' -ErrorAction SilentlyContinue   # clean disconnect from the server
Start-Sleep -Seconds 6
& schtasks.exe /Delete /TN 'TS3MusicBot' /F 2>$null | Out-Null
# the run-bot.ps1 loop of this installation, then the bot and its tools
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object { $_.CommandLine -like '*run-bot.ps1*' -and $_.CommandLine -like ('*' + $root.TrimEnd('\') + '*') } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
foreach ($n in 'TS3AudioBot', 'yt-dlp', 'ffmpeg', 'deno') {
    Get-Process -Name $n -ErrorAction SilentlyContinue | Where-Object { $_.Path -and $_.Path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase) } | Stop-Process -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 2
for ($i = 0; $i -lt 5; $i++) {
    Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
    if (-not (Test-Path -LiteralPath $root)) { break }
    Start-Sleep -Seconds 2
}
if (Test-Path -LiteralPath $root) { exit 1 }
Remove-Item -LiteralPath $PSCommandPath -Force -ErrorAction SilentlyContinue
