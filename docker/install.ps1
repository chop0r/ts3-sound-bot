<#
  TeamSpeak 3 music bot - installer for Windows (needs Docker Desktop).
  Double-click install.cmd, or run:  powershell -ExecutionPolicy Bypass -File install.ps1

  Unattended example:
    install.ps1 -NonInteractive -Server 192.168.1.10:9987 -Nickname MusicBot -Access lan -Port 58913
#>
[CmdletBinding()]
param(
    [ValidateSet('', 'en', 'ru')][string]$Language = '',
    [switch]$NonInteractive,
    [string]$Server = '',
    [string]$ServerPassword = '',
    [string]$Nickname = '',
    [string]$Channel = '',
    [int]$Port = 0,
    [ValidateSet('', 'local', 'lan')][string]$Access = '',
    [string]$Key = '',
    [string]$Proxy = '',
    [string]$ContainerName = '',
    [switch]$NoStart
)

$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch { }

# ---------------------------------------------------------------- texts
$M = @{
  en = @{
    title        = 'TeamSpeak 3 music bot - installer'
    pickLang     = 'Language / Язык:  1) English   2) Русский'
    dockerMissing = 'Docker was not found. Install Docker Desktop (https://www.docker.com/products/docker-desktop/), start it and run this installer again.'
    dockerDown   = 'Docker is installed but not running. Start Docker Desktop, wait until it is ready and run this installer again.'
    composeMissing = 'The "docker compose" command is missing. Update Docker Desktop to a recent version.'
    existsTitle  = 'An installation already exists in this folder (.env found).'
    exists1      = '1) Update: rebuild the bot and restart it, keep all settings'
    exists2      = '2) Reconfigure: ask the questions again (playlists and bot identity are kept)'
    exists3      = '3) Exit'
    choose       = 'Your choice'
    intro        = 'Answer the questions below. Press Enter to accept the value in [brackets].'
    qServer      = 'TeamSpeak server address (IP or host name, optional :port)'
    eServer      = 'The address is required.'
    warnLocal    = 'The bot runs inside Docker, so "{0}" would point to the container itself, not to this computer.'
    qReplace     = 'Use host.docker.internal instead (reaches TeamSpeak running on this computer)? (Y/n)'
    qSrvPass     = 'TeamSpeak server password (Enter = none)'
    qNick        = 'Bot nickname on the server'
    qChannel     = 'Channel to join (path like Lobby/Music or /ID; Enter = default channel)'
    qAccess      = 'Who may open the web panel?  1) only this computer   2) other devices in the local network'
    ePort        = 'Enter a port number from 1 to 65535.'
    qPort        = 'Web panel port'
    qKey         = 'Web panel access key (at least 12 letters/digits/-/_; Enter = generate a random one)'
    eKey         = 'The key must be at least 12 characters: letters, digits, - or _.'
    qProxy       = 'Proxy for YouTube (for example socks5://host.docker.internal:1080; Enter = none)'
    qAdvanced    = 'Show advanced settings (YouTube proxy)? (y/N)'
    sumHead      = 'Summary'
    sServer      = 'TeamSpeak server'
    sNick        = 'Bot nickname'
    sChannel     = 'Channel'
    sPanel       = 'Web panel'
    sKey         = 'Access key'
    sProxy       = 'YouTube proxy'
    sGenerated   = '(generated)'
    sDefault     = '(default)'
    sNone        = '(none)'
    sLocal       = 'this computer only'
    sLan         = 'local network'
    qConfirm     = 'Install with these settings? (Y/n)'
    aborted      = 'Cancelled, nothing was changed.'
    writing      = 'Writing configuration...'
    building     = 'Building and starting the bot (the first build takes several minutes)...'
    buildFailed  = 'Docker could not build or start the bot. Read the messages above.'
    waiting      = 'Waiting for the web panel...'
    notYet       = 'The panel did not answer yet. The bot may still be starting: check "docker compose logs".'
    ready        = 'Done! The bot is running.'
    panelUrl     = 'Web panel'
    keyLabel     = 'Access key'
    keySave      = 'Save the key: it is also stored in data\websecrets.ini'
    certNote     = 'The browser warns about the certificate: it is self-signed, this is normal. Choose "Advanced" and continue.'
    fwNote       = 'If other devices cannot open the panel, allow this TCP port in Windows Firewall.'
    tsNote       = 'The bot appears on your TeamSpeak server under the chosen nickname within a minute. Type /help in its chat.'
    manageHead   = 'Management (run in this folder):'
    mLogs        = 'logs:            docker compose logs -f'
    mStop        = 'stop:            docker compose stop'
    mStart       = 'start:           docker compose start'
    mUpdate      = 'update:          run install.cmd again and choose 1'
    mRemove      = 'remove:          docker compose down -v   (then delete this folder)'
  }
  ru = @{
    title        = 'Музыкальный бот TeamSpeak 3 - установщик'
    pickLang     = 'Language / Язык:  1) English   2) Русский'
    dockerMissing = 'Docker не найден. Установите Docker Desktop (https://www.docker.com/products/docker-desktop/), запустите его и снова запустите установщик.'
    dockerDown   = 'Docker установлен, но не запущен. Запустите Docker Desktop, дождитесь готовности и снова запустите установщик.'
    composeMissing = 'Нет команды "docker compose". Обновите Docker Desktop до свежей версии.'
    existsTitle  = 'В этой папке уже есть установка (найден .env).'
    exists1      = '1) Обновить: пересобрать бота и перезапустить, все настройки сохраняются'
    exists2      = '2) Перенастроить: задать вопросы заново (плейлисты и личность бота сохраняются)'
    exists3      = '3) Выход'
    choose       = 'Ваш выбор'
    intro        = 'Ответьте на вопросы. Enter - принять значение в [скобках].'
    qServer      = 'Адрес сервера TeamSpeak (IP или имя, можно с :портом)'
    eServer      = 'Адрес обязателен.'
    warnLocal    = 'Бот работает внутри Docker, поэтому "{0}" указывает на сам контейнер, а не на этот компьютер.'
    qReplace     = 'Использовать вместо этого host.docker.internal (достучится до TeamSpeak на этом компьютере)? (Y/n)'
    qSrvPass     = 'Пароль сервера TeamSpeak (Enter - нет)'
    qNick        = 'Ник бота на сервере'
    qChannel     = 'Канал для входа (путь вроде Лобби/Музыка или /ID; Enter - канал по умолчанию)'
    qAccess      = 'Кто может открывать веб-панель?  1) только этот компьютер   2) другие устройства в локальной сети'
    ePort        = 'Введите номер порта от 1 до 65535.'
    qPort        = 'Порт веб-панели'
    qKey         = 'Ключ доступа к панели (минимум 12 букв/цифр/-/_; Enter - создать случайный)'
    eKey         = 'Ключ должен быть не короче 12 символов: буквы, цифры, - или _.'
    qProxy       = 'Прокси для YouTube (например socks5://host.docker.internal:1080; Enter - без прокси)'
    qAdvanced    = 'Показать дополнительные настройки (прокси для YouTube)? (y/N)'
    sumHead      = 'Итог'
    sServer      = 'Сервер TeamSpeak'
    sNick        = 'Ник бота'
    sChannel     = 'Канал'
    sPanel       = 'Веб-панель'
    sKey         = 'Ключ доступа'
    sProxy       = 'Прокси YouTube'
    sGenerated   = '(создан случайно)'
    sDefault     = '(по умолчанию)'
    sNone        = '(нет)'
    sLocal       = 'только этот компьютер'
    sLan         = 'локальная сеть'
    qConfirm     = 'Установить с этими настройками? (Y/n)'
    aborted      = 'Отменено, ничего не изменено.'
    writing      = 'Записываю настройки...'
    building     = 'Собираю и запускаю бота (первая сборка занимает несколько минут)...'
    buildFailed  = 'Docker не смог собрать или запустить бота. Прочитайте сообщения выше.'
    waiting      = 'Жду запуска веб-панели...'
    notYet       = 'Панель пока не ответила. Возможно, бот ещё запускается: посмотрите "docker compose logs".'
    ready        = 'Готово! Бот запущен.'
    panelUrl     = 'Веб-панель'
    keyLabel     = 'Ключ доступа'
    keySave      = 'Сохраните ключ: он также лежит в data\websecrets.ini'
    certNote     = 'Браузер предупредит о сертификате: он самоподписанный, так и должно быть. Нажмите "Дополнительно" и продолжите.'
    fwNote       = 'Если другие устройства не открывают панель, разрешите этот TCP-порт в брандмауэре Windows.'
    tsNote       = 'В течение минуты бот появится на сервере TeamSpeak под выбранным ником. Напишите ему /help.'
    manageHead   = 'Управление (команды выполнять в этой папке):'
    mLogs        = 'логи:            docker compose logs -f'
    mStop        = 'остановить:      docker compose stop'
    mStart       = 'запустить:       docker compose start'
    mUpdate      = 'обновить:        снова запустите install.cmd и выберите 1'
    mRemove      = 'удалить:         docker compose down -v   (потом удалите папку)'
  }
}
$script:Lang = 'en'
function T([string]$k, [object[]]$a = @()) {
    $s = $M[$script:Lang][$k]
    if ($null -eq $s) { $s = $M['en'][$k] }
    if ($a.Count -gt 0) { return ($s -f $a) }
    return $s
}
function Say([string]$text, [string]$color = '') {
    if ($color) { Write-Host $text -ForegroundColor $color } else { Write-Host $text }
}

# ---------------------------------------------------------------- input helpers
function Ask([string]$prompt, [string]$default = '', [switch]$Secret) {
    if ($NonInteractive) { return $default }
    $label = $prompt
    if ($default) { $label = "$prompt [$default]" }
    if ($Secret) {
        $sec = Read-Host -Prompt $label -AsSecureString
        $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
        try { $v = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) } finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
    } else {
        $v = Read-Host -Prompt $label
    }
    if ([string]::IsNullOrWhiteSpace($v)) { return $default }
    return $v.Trim()
}
function AskYesNo([string]$prompt) {
    if ($NonInteractive) { return $true }
    $v = (Read-Host -Prompt $prompt).Trim().ToLower()
    return ($v -eq '' -or $v -in @('y', 'yes', 'д', 'да'))
}
function AskYesNoDefaultNo([string]$prompt) {
    if ($NonInteractive) { return $false }
    $v = (Read-Host -Prompt $prompt).Trim().ToLower()
    return ($v -in @('y', 'yes', 'д', 'да'))
}
function TomlStr([string]$s) {
    return '"' + (($s -replace '\\', '\\') -replace '"', '\"' -replace "[\r\n]", '') + '"'
}
function NewKey {
    $b = New-Object byte[] 32
    $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
    $rng.GetBytes($b)
    $rng.Dispose()
    return ([Convert]::ToBase64String($b).TrimEnd('=').Replace('+', '-').Replace('/', '_'))
}
function WriteUtf8([string]$path, [string]$text) {
    $dir = Split-Path -Parent $path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [IO.File]::WriteAllText((Join-Path $PSScriptRoot $path), $text, (New-Object Text.UTF8Encoding($false)))
}

# ---------------------------------------------------------------- start
Say ''
if ($Language) {
    $script:Lang = $Language
} elseif (-not $NonInteractive) {
    Say (T 'pickLang')
    $c = Ask '>' '1'
    if ($c -eq '2') { $script:Lang = 'ru' }
}
Say ''
Say (T 'title') 'Cyan'
Say ('=' * 50) 'Cyan'

# Docker
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { Say (T 'dockerMissing') 'Red'; exit 1 }
& docker info *> $null
if ($LASTEXITCODE -ne 0) { Say (T 'dockerDown') 'Red'; exit 1 }
& docker compose version *> $null
if ($LASTEXITCODE -ne 0) { Say (T 'composeMissing') 'Red'; exit 1 }

# existing installation (previous container name is kept)
$envFile = Join-Path $PSScriptRoot '.env'
if ((Test-Path -LiteralPath $envFile) -and -not $ContainerName) {
    $mc = [regex]::Match((Get-Content -LiteralPath $envFile -Raw), '(?m)^BOT_CONTAINER=(\S+)')
    if ($mc.Success) { $ContainerName = $mc.Groups[1].Value }
}
$mode = 'new'
if (Test-Path -LiteralPath (Join-Path $PSScriptRoot '.env')) {
    if ($NonInteractive) {
        if ($Server) { $mode = 'reconfigure' } else { $mode = 'update' }
    } else {
        Say ''
        Say (T 'existsTitle') 'Yellow'
        Say (T 'exists1'); Say (T 'exists2'); Say (T 'exists3')
        $c = Ask (T 'choose') '1'
        if ($c -eq '3') { exit 0 }
        if ($c -eq '2') { $mode = 'reconfigure' } else { $mode = 'update' }
    }
}

if ($mode -ne 'update') {
    if (-not $NonInteractive) { Say ''; Say (T 'intro') }

    # server address
    while ($true) {
        $Server = Ask (T 'qServer') $Server
        if ($Server) { break }
        if ($NonInteractive) { Say (T 'eServer') 'Red'; exit 1 }
        Say (T 'eServer') 'Red'
    }
    $Server = $Server.Trim()
    if ($Server -match '^(localhost|127\.\d+\.\d+\.\d+|::1)(:\d+)?$') {
        Say (T 'warnLocal' @($Server)) 'Yellow'
        if (AskYesNo (T 'qReplace')) {
            $Server = $Server -replace '^(localhost|127\.\d+\.\d+\.\d+|::1)', 'host.docker.internal'
        }
    }
    $ServerPassword = Ask (T 'qSrvPass') $ServerPassword -Secret
    if (-not $Nickname) { $Nickname = 'MusicBot' }
    $Nickname = Ask (T 'qNick') $Nickname
    $Channel = Ask (T 'qChannel') $Channel

    # web panel
    if (-not $Access) {
        if ($NonInteractive) { $Access = 'local' } else {
            Say (T 'qAccess')
            $c = Ask '>' '1'
            if ($c -eq '2') { $Access = 'lan' } else { $Access = 'local' }
        }
    }
    if ($Port -le 0) { $Port = 58913 }
    while ($true) {
        $p = Ask (T 'qPort') ([string]$Port)
        if ($p -match '^\d+$' -and [int]$p -ge 1 -and [int]$p -le 65535) { $Port = [int]$p; break }
        if ($NonInteractive) { Say (T 'ePort') 'Red'; exit 1 }
        Say (T 'ePort') 'Red'
    }
    $generated = $false
    while ($true) {
        $k = Ask (T 'qKey') $Key
        if (-not $k) { $k = NewKey; $generated = $true; $Key = $k; break }
        if ($k -match '^[A-Za-z0-9_\-]{12,}$') { $Key = $k; break }
        if ($NonInteractive) { Say (T 'eKey') 'Red'; exit 1 }
        Say (T 'eKey') 'Red'
    }
    if (AskYesNoDefaultNo (T 'qAdvanced')) { $Proxy = Ask (T 'qProxy') $Proxy }

    if (-not $ContainerName) { $ContainerName = 'ts3musicbot' }

    # summary
    $bind = '127.0.0.1'; $accText = T 'sLocal'
    if ($Access -eq 'lan') { $bind = '0.0.0.0'; $accText = T 'sLan' }
    if (-not $NonInteractive) {
        Say ''
        Say (T 'sumHead') 'Cyan'
        Say ('  {0,-18} {1}' -f (T 'sServer'), $Server)
        Say ('  {0,-18} {1}' -f (T 'sNick'), $Nickname)
        $chText = $Channel; if (-not $chText) { $chText = T 'sDefault' }
        Say ('  {0,-18} {1}' -f (T 'sChannel'), $chText)
        Say ('  {0,-18} port {1}, {2}' -f (T 'sPanel'), $Port, $accText)
        $keyText = $Key; if ($generated) { $keyText = T 'sGenerated' }
        Say ('  {0,-18} {1}' -f (T 'sKey'), $keyText)
        $pxText = $Proxy; if (-not $pxText) { $pxText = T 'sNone' }
        Say ('  {0,-18} {1}' -f (T 'sProxy'), $pxText)
        Say ''
        if (-not (AskYesNo (T 'qConfirm'))) { Say (T 'aborted'); exit 0 }
    }

    # ------------------------------------------------------------ write configuration
    Say (T 'writing')
    # repository layout (docker\ next to bot\) or the flattened release zip (bot\ next to this script)
    $layoutEnv = ''
    if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot '..\bot\patch.sh')) -and (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'bot\patch.sh'))) { $layoutEnv = "BUILD_CONTEXT=.`nBUILD_DOCKERFILE=Dockerfile`n" }
    $envText = "BOT_CONTAINER=$ContainerName`nBOT_IMAGE=${ContainerName}:latest`nBIND_ADDR=$bind`nWEB_PORT=$Port`nYTDLP_PROXY=$Proxy`n$layoutEnv"
    WriteUtf8 '.env' $envText

    $global = @"
# Generated by the installer. The bot adds all other settings with their defaults on first start.
[bot]
language = "en"

[configs]
send_stats = false

[db]
path = "/app/db/ts3audiobot.db"

[rights]
path = "rights.toml"

[web]
hosts = ["*"]
port = 58913
use_ssl = true

[factories.youtube]
prefer_resolver = "YoutubeDl"
"@
    if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'data\ts3audiobot.toml'))) { WriteUtf8 'data\ts3audiobot.toml' ($global + "`n") }
    New-Item -ItemType Directory -Force -Path (Join-Path $PSScriptRoot 'data') | Out-Null
    $tpl = Join-Path $PSScriptRoot 'templates\rights.toml'
    if (-not (Test-Path -LiteralPath $tpl)) { $tpl = Join-Path $PSScriptRoot '..\templates\rights.toml' }
    Copy-Item -LiteralPath $tpl -Destination (Join-Path $PSScriptRoot 'data\rights.toml') -Force

    # keep the bot identity (otherwise TeamSpeak sees a new client) and the old file as a backup
    $botFile = Join-Path $PSScriptRoot 'data\bots\default\bot.toml'
    $identity = ''
    if (Test-Path -LiteralPath $botFile) {
        $old = Get-Content -LiteralPath $botFile -Raw -Encoding UTF8
        $idm = [regex]::Match($old, '(?ms)^\[connect\.identity\].*?(?=^\[|\z)')
        if ($idm.Success) { $identity = "`n" + $idm.Value.TrimEnd() + "`n" }
        Copy-Item -LiteralPath $botFile -Destination ($botFile + '.bak-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
    }
    $pw = ''
    if ($ServerPassword) { $pw = "server_password = { pw = $(TomlStr $ServerPassword) }" }
    $bot = @"
# Bot instance settings (generated by the installer). Stop the bot before editing by hand.
run = true
language = "en"

[commands]
long_message_split_limit = 3

[commands.alias]
yt = "/xecute (/search from youtube (/param 0)) (/search play 0)"
playlists = "/list list"
newlist = "/list create (/param 0)"
addto = "/list add (/param 0) (/param 1)"
playlist = "/list play (/param 0)"
showlist = "/list show (/param 0)"
shuffle = "/random on"
loop = "/repeat all"

[connect]
address = $(TomlStr $Server)
name = $(TomlStr $Nickname)
channel = $(TomlStr $Channel)
$pw

[audio]
volume = { default = 40.0, max = 100.0, min = 0.0 }
bitrate = 96

[reconnect]
onerror = ["5s", "5s", "10s", "30s", "repeat last"]
ontimeout = ["1s", "5s", "10s", "30s", "repeat last"]
"@
    WriteUtf8 'data\bots\default\bot.toml' ($bot + $identity)
    WriteUtf8 'data\websecrets.ini' ("# TS3AudioBot secrets - do not share this file`napi_key = $Key`n")
} else {
    # update: read the settings back from .env
    $envMap = @{}
    Get-Content -LiteralPath (Join-Path $PSScriptRoot '.env') | ForEach-Object { if ($_ -match '^([A-Z_]+)=(.*)$') { $envMap[$Matches[1]] = $Matches[2] } }
    if ($envMap['WEB_PORT']) { $Port = [int]$envMap['WEB_PORT'] } else { $Port = 58913 }
    if ($envMap['BIND_ADDR'] -eq '0.0.0.0') { $Access = 'lan' } else { $Access = 'local' }
    $Key = ''
    $sec = Join-Path $PSScriptRoot 'data\websecrets.ini'
    if (Test-Path -LiteralPath $sec) { $mm = [regex]::Match((Get-Content -LiteralPath $sec -Raw), 'api_key\s*=\s*(\S+)'); if ($mm.Success) { $Key = $mm.Groups[1].Value } }
}

# ---------------------------------------------------------------- build and start
if ($NoStart) { exit 0 }
Say ''
Say (T 'building') 'Cyan'
$ErrorActionPreference = 'Continue'   # docker prints progress to stderr, that is not an error
& docker compose up -d --build
$ErrorActionPreference = 'Stop'
if ($LASTEXITCODE -ne 0) { Say (T 'buildFailed') 'Red'; exit 1 }

Say (T 'waiting')
$ok = $false
if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
    for ($i = 0; $i -lt 60; $i++) {
        $code = & curl.exe -sk -o NUL -w '%{http_code}' "https://127.0.0.1:$Port/api/v2/auth/state"
        if ($code -eq '200') { $ok = $true; break }
        Start-Sleep -Seconds 2
    }
}
if (-not $ok) { Say (T 'notYet') 'Yellow' }

$hostName = 'localhost'
if ($Access -eq 'lan') {
    try {
        $ip = (Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -ne $null } | Select-Object -First 1).IPv4Address.IPAddress
        if ($ip) { $hostName = $ip }
    } catch { }
}
Say ''
Say (T 'ready') 'Green'
Say ('  {0}: https://{1}:{2}' -f (T 'panelUrl'), $hostName, $Port) 'Green'
if ($Key) {
    Say ('  {0}: {1}' -f (T 'keyLabel'), $Key) 'Green'
    Say ('  ' + (T 'keySave'))
}
Say ''
Say (T 'certNote')
if ($Access -eq 'lan') { Say (T 'fwNote') }
Say (T 'tsNote')
Say ''
Say (T 'manageHead')
Say ('  ' + (T 'mLogs')); Say ('  ' + (T 'mStop')); Say ('  ' + (T 'mStart')); Say ('  ' + (T 'mUpdate')); Say ('  ' + (T 'mRemove'))
