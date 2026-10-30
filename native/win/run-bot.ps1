# Runs the bot in a loop (the /restart command exits the process; this script starts it again). Used by start.cmd and by autostart.
# stop.cmd creates stop.flag, which ends the loop.
$root = $PSScriptRoot
$bin = Join-Path $root 'bin'
$data = Join-Path $root 'data'
$flag = Join-Path $root 'stop.flag'
Remove-Item -LiteralPath $flag -ErrorAction SilentlyContinue
$env:Path = "$bin;$env:Path"

# settings written by the installer
$proxy = ''
$st = Join-Path $root 'settings.env'
if (Test-Path -LiteralPath $st) {
    Get-Content -LiteralPath $st | ForEach-Object { if ($_ -match '^YTDLP_PROXY=(.*)$') { $proxy = $Matches[1].Trim() } }
}

# yt-dlp config (rebuilt on every start): JS runtime for YouTube, optional proxy and cookies (data\cookies.txt)
$conf = @('--js-runtimes deno:' + (Join-Path $bin 'deno.exe'), '--no-warnings')
if ($proxy) { $conf += "--proxy $proxy" }
if (Test-Path -LiteralPath (Join-Path $data 'cookies.txt')) { $conf += '--cookies "' + (Join-Path $data 'cookies.txt') + '"' }
[IO.File]::WriteAllText((Join-Path $bin 'yt-dlp.conf'), (($conf -join "`r`n") + "`r`n"), (New-Object Text.UTF8Encoding($false)))

# yt-dlp updates itself on every start (YouTube changes often)
$ytdlp = Join-Path $bin 'yt-dlp.exe'
if (Test-Path -LiteralPath $ytdlp) {
    try {
        $p = Start-Process -FilePath $ytdlp -ArgumentList '-U' -WindowStyle Hidden -PassThru
        if (-not $p.WaitForExit(60000)) { $p.Kill() }
    } catch { }
}

Set-Location -LiteralPath $data
while ($true) {
    & (Join-Path $root 'app\TS3AudioBot.exe') --non-interactive --stats-disabled
    if (Test-Path -LiteralPath $flag) { break }
    Start-Sleep -Seconds 3
}
