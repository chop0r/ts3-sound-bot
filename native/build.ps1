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

# ffmpeg is bundled into the archives (with its license files); downloaded once into build/cache
$cache = Join-Path $PSScriptRoot 'build/cache'
function Fetch([string]$url, [string]$file) {
    $dest = Join-Path $cache $file
    if (-not (Test-Path $dest)) {
        New-Item -ItemType Directory -Force -Path $cache | Out-Null
        & $(if ($IsWindows -or $env:OS) { 'curl.exe' } else { 'curl' }) -fL --retry 3 -# -o $dest $url
        if ($LASTEXITCODE -ne 0) { Remove-Item -Force $dest -ErrorAction SilentlyContinue; throw "download failed: $url" }
    }
    return $dest
}
function BundleFfmpeg([string]$rid, [string]$stage) {
    $bin = Join-Path $stage 'bin'
    $lic = Join-Path $stage 'licenses/ffmpeg'
    New-Item -ItemType Directory -Force -Path $bin, $lic | Out-Null
    $tmp = Join-Path $PSScriptRoot "build/ff-$rid"
    if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }
    New-Item -ItemType Directory -Force -Path $tmp | Out-Null
    if ($rid -eq 'win-x64') {
        $url = 'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip'
        $zip = Fetch $url 'ffmpeg-win.zip'
        Expand-Archive -LiteralPath $zip -DestinationPath $tmp -Force   # GNU tar (CI) cannot read zip
        $exe = Get-ChildItem $tmp -Recurse -Filter ffmpeg.exe | Select-Object -First 1
        Copy-Item $exe.FullName (Join-Path $bin 'ffmpeg.exe')
        $root = $exe.Directory.Parent.FullName
        foreach ($f in 'LICENSE', 'README.txt') { if (Test-Path (Join-Path $root $f)) { Copy-Item (Join-Path $root $f) (Join-Path $lic $f) } }
        $src = 'https://www.gyan.dev/ffmpeg/builds/  (build and source links; the source is also at https://ffmpeg.org/download.html)'
    } else {
        $url = 'https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz'
        $tgz = Fetch $url 'ffmpeg-linux.tar.xz'
        & tar -xf $tgz -C $tmp
        $exe = Get-ChildItem $tmp -Recurse -Filter ffmpeg | Where-Object { -not $_.PSIsContainer } | Select-Object -First 1
        Copy-Item $exe.FullName (Join-Path $bin 'ffmpeg')
        foreach ($f in 'GPLv3.txt', 'readme.txt') { $p = Join-Path $exe.Directory.FullName $f; if (Test-Path $p) { Copy-Item $p (Join-Path $lic $f) } }
        $src = 'https://johnvansickle.com/ffmpeg/  (build and source tarballs: https://johnvansickle.com/ffmpeg/release-source/)'
    }
    @"
This folder contains the unmodified ffmpeg binary taken from a public build:

  $url
  Source and build information: $src

ffmpeg is free software (GPL v3 for these builds; see the license files in this folder). It is bundled
unchanged and is not part of TS3 Sound Bot's own code. The license of the bot (OSL-3.0) does not apply to it.
You can replace bin/ffmpeg with any other ffmpeg build.
"@ | Set-Content -Encoding utf8 (Join-Path $lic 'SOURCE.txt')
    Remove-Item -Recurse -Force $tmp
}
function Pack([string]$rid, [string]$scriptDir, [string]$archive) {
    $stage = Join-Path $PSScriptRoot "build/stage/ts3musicbot-native-$rid"
    if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
    New-Item -ItemType Directory -Force -Path $stage | Out-Null
    Copy-Item -Recurse -Force (Join-Path $out $rid) (Join-Path $stage 'app')
    Copy-Item -Recurse -Force (Join-Path $PSScriptRoot "$scriptDir/*") $stage
    Copy-Item -Recurse -Force (Join-Path $PSScriptRoot '../templates') $stage
    BundleFfmpeg $rid $stage
    Copy-Item -Force (Join-Path $PSScriptRoot '../LICENSE'), (Join-Path $PSScriptRoot '../NOTICE.md'), (Join-Path $PSScriptRoot 'README.md'), (Join-Path $PSScriptRoot 'README.ru.md') $stage
    $parent = Join-Path $PSScriptRoot 'build/stage'
    if ($archive.EndsWith('.zip') -and -not ($IsWindows -or $env:OS)) {   # GNU tar (Linux CI) cannot write zip
        Push-Location $parent; & zip -qr (Join-Path $dist $archive) "ts3musicbot-native-$rid"; Pop-Location
    } else {
        & tar -a -c -f (Join-Path $dist $archive) -C $parent "ts3musicbot-native-$rid"
    }
}
Pack 'win-x64' 'win' 'ts3musicbot-native-win-x64.zip'
Pack 'linux-x64' 'linux' 'ts3musicbot-native-linux-x64.tar.gz'
Get-ChildItem $dist | Format-Table Name, Length
