#!/usr/bin/env bash
# TeamSpeak 3 music bot - installer for Linux WITHOUT Docker.
# Run:  bash install.sh
# Unattended example:
#   bash install.sh --non-interactive --server 192.168.1.10:9987 --nickname MusicBot --access lan --port 58913 --autostart
set -u
cd "$(dirname "$0")"

LANG_CODE=""; NONINT=0; SERVER=""; SRVPASS=""; NICK=""; CHANNEL=""; PORT=""; ACCESS=""; KEY=""; PROXY=""; NOSTART=0; AUTOSTART=0; NODOWNLOAD=0
while [ $# -gt 0 ]; do
  case "$1" in
    --lang) LANG_CODE="$2"; shift 2;;
    --non-interactive) NONINT=1; shift;;
    --server) SERVER="$2"; shift 2;;
    --server-password) SRVPASS="$2"; shift 2;;
    --nickname) NICK="$2"; shift 2;;
    --channel) CHANNEL="$2"; shift 2;;
    --port) PORT="$2"; shift 2;;
    --access) ACCESS="$2"; shift 2;;
    --key) KEY="$2"; shift 2;;
    --proxy) PROXY="$2"; shift 2;;
    --autostart) AUTOSTART=1; shift;;
    --no-start) NOSTART=1; shift;;
    --no-download) NODOWNLOAD=1; shift;;
    -h|--help) sed -n 2,6p "$0"; exit 0;;
    *) echo "Unknown option: $1"; exit 1;;
  esac
done

# ---------------------------------------------------------------- texts
msg() { printf -v "M_${1}_${2}" '%s' "$3"; }
# English
msg en title        'TeamSpeak 3 music bot - installer'
msg en dockerMissing 'Docker was not found. Install Docker (https://docs.docker.com/engine/install/) and run this installer again.'
msg en dockerDown   'Docker is installed but not running (or your user may not use it). Start the Docker service, or add yourself to the "docker" group, and run this installer again.'
msg en composeMissing 'The "docker compose" command is missing. Install the Docker compose plugin.'
msg en existsTitle  'An installation already exists in this folder (.env found).'
msg en exists1      '1) Update: rebuild the bot and restart it, keep all settings'
msg en exists2      '2) Reconfigure: ask the questions again (playlists and bot identity are kept)'
msg en exists3      '3) Exit'
msg en choose       'Your choice'
msg en intro        'Answer the questions below. Press Enter to accept the value in [brackets].'
msg en qServer      'TeamSpeak server address (IP or host name, optional :port)'
msg en eServer      'The address is required.'
msg en warnLocal    'The bot runs inside Docker, so "{0}" would point to the container itself, not to this computer.'
msg en qReplace     'Use host.docker.internal instead (reaches TeamSpeak running on this computer)? (Y/n)'
msg en qSrvPass     'TeamSpeak server password (Enter = none)'
msg en qNick        'Bot nickname on the server'
msg en qChannel     'Channel to join (path like Lobby/Music or /ID; Enter = default channel)'
msg en qAccess      'Who may open the web panel?  1) only this computer   2) other devices in the local network'
msg en ePort        'Enter a port number from 1 to 65535.'
msg en qPort        'Web panel port'
msg en qKey         'Web panel access key (at least 12 letters/digits/-/_; Enter = generate a random one)'
msg en eKey         'The key must be at least 12 characters: letters, digits, - or _.'
msg en qProxy       'Proxy for YouTube (for example socks5://127.0.0.1:1080; Enter = none)'
msg en qAdvanced    'Show advanced settings (YouTube proxy)? (y/N)'
msg en sumHead      'Summary'
msg en sServer      'TeamSpeak server'
msg en sNick        'Bot nickname'
msg en sChannel     'Channel'
msg en sPanel       'Web panel'
msg en sKey         'Access key'
msg en sProxy       'YouTube proxy'
msg en sGenerated   '(generated)'
msg en sDefault     '(default)'
msg en sNone        '(none)'
msg en sLocal       'this computer only'
msg en sLan         'local network'
msg en qConfirm     'Install with these settings? (Y/n)'
msg en aborted      'Cancelled, nothing was changed.'
msg en writing      'Writing configuration...'
msg en building     'Building and starting the bot (the first build takes several minutes)...'
msg en buildFailed  'Docker could not build or start the bot. Read the messages above.'
msg en waiting      'Waiting for the web panel...'
msg en notYet       'The panel did not answer yet. The bot may still be starting: check "docker compose logs".'
msg en ready        'Done! The bot is running.'
msg en panelUrl     'Web panel'
msg en keyLabel     'Access key'
msg en keySave      'Save the key: it is also stored in data/websecrets.ini'
msg en certNote     'The browser warns about the certificate: it is self-signed, this is normal. Choose "Advanced" and continue.'
msg en fwNote       'If other devices cannot open the panel, allow this TCP port in your firewall.'
msg en tsNote       'The bot appears on your TeamSpeak server under the chosen nickname within a minute. Type /help in its chat.'
msg en manageHead   'Management (run in this folder):'
msg en mLogs        'logs:            docker compose logs -f'
msg en mStop        'stop:            docker compose stop'
msg en mStart       'start:           docker compose start'
msg en mUpdate      'update:          run  bash install.sh  again and choose 1'
msg en mRemove      'remove:          docker compose down -v   (then delete this folder)'
# Russian
msg ru title        'Музыкальный бот TeamSpeak 3 - установщик'
msg ru dockerMissing 'Docker не найден. Установите Docker (https://docs.docker.com/engine/install/) и снова запустите установщик.'
msg ru dockerDown   'Docker установлен, но не запущен (или у вашего пользователя нет доступа). Запустите службу Docker или добавьте себя в группу "docker" и снова запустите установщик.'
msg ru composeMissing 'Нет команды "docker compose". Установите плагин Docker compose.'
msg ru existsTitle  'В этой папке уже есть установка (найден .env).'
msg ru exists1      '1) Обновить: пересобрать бота и перезапустить, все настройки сохраняются'
msg ru exists2      '2) Перенастроить: задать вопросы заново (плейлисты и личность бота сохраняются)'
msg ru exists3      '3) Выход'
msg ru choose       'Ваш выбор'
msg ru intro        'Ответьте на вопросы. Enter - принять значение в [скобках].'
msg ru qServer      'Адрес сервера TeamSpeak (IP или имя, можно с :портом)'
msg ru eServer      'Адрес обязателен.'
msg ru warnLocal    'Бот работает внутри Docker, поэтому "{0}" указывает на сам контейнер, а не на этот компьютер.'
msg ru qReplace     'Использовать вместо этого host.docker.internal (достучится до TeamSpeak на этом компьютере)? (Y/n)'
msg ru qSrvPass     'Пароль сервера TeamSpeak (Enter - нет)'
msg ru qNick        'Ник бота на сервере'
msg ru qChannel     'Канал для входа (путь вроде Лобби/Музыка или /ID; Enter - канал по умолчанию)'
msg ru qAccess      'Кто может открывать веб-панель?  1) только этот компьютер   2) другие устройства в локальной сети'
msg ru ePort        'Введите номер порта от 1 до 65535.'
msg ru qPort        'Порт веб-панели'
msg ru qKey         'Ключ доступа к панели (минимум 12 букв/цифр/-/_; Enter - создать случайный)'
msg ru eKey         'Ключ должен быть не короче 12 символов: буквы, цифры, - или _.'
msg ru qProxy       'Прокси для YouTube (например socks5://127.0.0.1:1080; Enter - без прокси)'
msg ru qAdvanced    'Показать дополнительные настройки (прокси для YouTube)? (y/N)'
msg ru sumHead      'Итог'
msg ru sServer      'Сервер TeamSpeak'
msg ru sNick        'Ник бота'
msg ru sChannel     'Канал'
msg ru sPanel       'Веб-панель'
msg ru sKey         'Ключ доступа'
msg ru sProxy       'Прокси YouTube'
msg ru sGenerated   '(создан случайно)'
msg ru sDefault     '(по умолчанию)'
msg ru sNone        '(нет)'
msg ru sLocal       'только этот компьютер'
msg ru sLan         'локальная сеть'
msg ru qConfirm     'Установить с этими настройками? (Y/n)'
msg ru aborted      'Отменено, ничего не изменено.'
msg ru writing      'Записываю настройки...'
msg ru building     'Собираю и запускаю бота (первая сборка занимает несколько минут)...'
msg ru buildFailed  'Docker не смог собрать или запустить бота. Прочитайте сообщения выше.'
msg ru waiting      'Жду запуска веб-панели...'
msg ru notYet       'Панель пока не ответила. Возможно, бот ещё запускается: посмотрите "docker compose logs".'
msg ru ready        'Готово! Бот запущен.'
msg ru panelUrl     'Веб-панель'
msg ru keyLabel     'Ключ доступа'
msg ru keySave      'Сохраните ключ: он также лежит в data/websecrets.ini'
msg ru certNote     'Браузер предупредит о сертификате: он самоподписанный, так и должно быть. Нажмите "Дополнительно" и продолжите.'
msg ru fwNote       'Если другие устройства не открывают панель, разрешите этот TCP-порт в брандмауэре.'
msg ru tsNote       'В течение минуты бот появится на сервере TeamSpeak под выбранным ником. Напишите ему /help.'
msg ru manageHead   'Управление (команды выполнять в этой папке):'
msg ru mLogs        'логи:            docker compose logs -f'
msg ru mStop        'остановить:      docker compose stop'
msg ru mStart       'запустить:       docker compose start'
msg ru mUpdate      'обновить:        снова запустите  bash install.sh  и выберите 1'
msg ru mRemove      'удалить:         docker compose down -v   (потом удалите папку)'

t() {
  local v="M_${LANG_CODE}_$1" s
  s="${!v-}"
  if [ -z "$s" ]; then v="M_en_$1"; s="${!v-}"; fi
  [ $# -gt 1 ] && s="${s//\{0\}/$2}"
  printf '%s' "$s"
}
say() { printf '%s\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
red() { printf '\033[31m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
cyan() { printf '\033[36m%s\033[0m\n' "$*"; }

# ---------------------------------------------------------------- helpers
# ask "prompt" "default" [secret]  -> result in $REPLY_VAL
ask() {
  local prompt="$1" def="${2-}" secret="${3-}" label v
  if [ "$NONINT" = 1 ]; then REPLY_VAL="$def"; return; fi
  label="$prompt"; [ -n "$def" ] && [ -z "$secret" ] && label="$prompt [$def]"
  if [ -n "$secret" ]; then read -rsp "$label: " v; echo; else read -rp "$label: " v; fi
  v="$(printf '%s' "$v" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  [ -z "$v" ] && v="$def"
  REPLY_VAL="$v"
}
ask_yes() {
  [ "$NONINT" = 1 ] && return 0
  local v; read -rp "$1: " v
  v="$(printf '%s' "$v" | tr 'A-Z' 'a-z')"
  case "$v" in ""|y|yes|д|да) return 0;; *) return 1;; esac
}
toml_str() { printf '"%s"' "$(printf '%s' "$1" | tr -d '\r\n' | sed 's/\\/\\\\/g; s/"/\\"/g')"; }
new_key() { head -c 32 /dev/urandom | base64 | tr '+/' '-_' | tr -d '=\n'; }
local_ip() {
  local ip=""
  ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
  [ -z "$ip" ] && ip="$(ipconfig getifaddr en0 2>/dev/null)"
  printf '%s' "$ip"
}


# ---------------------------------------------------------------- extra texts for the Docker-free version
msg en title        'TeamSpeak 3 music bot - installer (without Docker)'
msg en noApp        'The "app" folder with the bot was not found next to this script. Unpack the whole archive and run the installer from the unpacked folder.'
msg en existsTitle  'The bot is already installed in this folder.'
msg en exists1      '1) Update tools: download fresh yt-dlp, deno and ffmpeg, keep all settings'
msg en qAutostart   'Start the bot automatically (systemd user service)? (y/N)'
msg en sAutostart   'Autostart'
msg en sYes         'yes'
msg en sNo          'no'
msg en libsMissing  'Missing system libraries: {0}. Install them and run the installer again, for example:  sudo apt install libicu72 libopus0'
msg en toolMissing  'Missing command: {0}. Install it (for example: sudo apt install {0}) and run the installer again.'
msg en dlHead       'Downloading tools (yt-dlp, deno, ffmpeg)...'
msg en dlOne        '  downloading {0} ...'
msg en dlHave       '  {0}: already downloaded'
msg en dlFail       'Could not download {0}. Check your internet connection and run the installer again (choose "Update tools").'
msg en starting     'Starting the bot...'
msg en mLogs        'logs:            data/logs/ (open the newest file)'
msg en mStop        'stop:            ./stop.sh'
msg en mStart       'start:           ./start.sh'
msg en mUpdate      'update tools:    run  bash install.sh  again and choose 1'
msg en mRemove      'remove:          ./stop.sh, delete this folder (and: systemctl --user disable ts3musicbot, if you enabled autostart)'
msg ru title        'Музыкальный бот TeamSpeak 3 - установщик (без Docker)'
msg ru noApp        'Рядом со скриптом не найдена папка "app" с ботом. Распакуйте архив целиком и запустите установщик из распакованной папки.'
msg ru existsTitle  'Бот уже установлен в этой папке.'
msg ru exists1      '1) Обновить инструменты: скачать свежие yt-dlp, deno и ffmpeg, настройки сохраняются'
msg ru qAutostart   'Запускать бота автоматически (пользовательская служба systemd)? (y/N)'
msg ru sAutostart   'Автозапуск'
msg ru sYes         'да'
msg ru sNo          'нет'
msg ru libsMissing  'Не хватает системных библиотек: {0}. Установите их и снова запустите установщик, например:  sudo apt install libicu72 libopus0'
msg ru toolMissing  'Нет команды: {0}. Установите её (например: sudo apt install {0}) и снова запустите установщик.'
msg ru dlHead       'Скачиваю инструменты (yt-dlp, deno, ffmpeg)...'
msg ru dlOne        '  скачиваю {0} ...'
msg ru dlHave       '  {0}: уже скачан'
msg ru dlFail       'Не удалось скачать {0}. Проверьте интернет и запустите установщик снова (выберите "Обновить инструменты").'
msg ru starting     'Запускаю бота...'
msg ru mLogs        'логи:            data/logs/ (откройте самый новый файл)'
msg ru mStop        'остановить:      ./stop.sh'
msg ru mStart       'запустить:       ./start.sh'
msg ru mUpdate      'обновить:        снова запустите  bash install.sh  и выберите 1'
msg ru mRemove      'удалить:         ./stop.sh и удалите эту папку (и: systemctl --user disable ts3musicbot, если включали автозапуск)'

ask_yes_no_default_no() {
  [ "$NONINT" = 1 ] && return 1
  local v; read -rp "$1: " v
  v="$(printf '%s' "$v" | tr 'A-Z' 'a-z')"
  case "$v" in y|yes|д|да) return 0;; *) return 1;; esac
}
download() { # url dest what
  say "$(t dlOne "$3")"
  if command -v curl >/dev/null 2>&1; then curl -fL --retry 3 --connect-timeout 20 --speed-limit 1000 --speed-time 60 -# -o "$2" "$1"; else wget -q --show-progress -O "$2" "$1"; fi || { red "$(t dlFail "$3")"; exit 1; }
}
install_tools() {
  local tmp; tmp="$(mktemp -d)"
  mkdir -p bin
  cyan "$(t dlHead)"
  chmod +x bin/ffmpeg 2>/dev/null   # bundled in the release archive
  say "[1/3]"
  if [ "$MODE" = update ] || [ ! -x bin/yt-dlp ]; then
    download https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux bin/yt-dlp yt-dlp
    chmod +x bin/yt-dlp
  else say "$(t dlHave yt-dlp)"; fi
  say "[2/3]"
  if [ "$MODE" = update ] || [ ! -x bin/deno ]; then
    download https://github.com/denoland/deno/releases/latest/download/deno-x86_64-unknown-linux-gnu.zip "$tmp/deno.zip" deno
    unzip -qo "$tmp/deno.zip" -d bin && chmod +x bin/deno
  else say "$(t dlHave deno)"; fi
  say "[3/3]"
  if [ -x bin/ffmpeg ]; then say "$(t dlHave ffmpeg)"; else
    download https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz "$tmp/ffmpeg.tar.xz" ffmpeg
    tar -xJf "$tmp/ffmpeg.tar.xz" -C "$tmp" --wildcards '*/ffmpeg' && cp "$tmp"/*/ffmpeg bin/ffmpeg && chmod +x bin/ffmpeg || { red "$(t dlFail ffmpeg)"; exit 1; }
  fi
  rm -rf "$tmp"
}

# ---------------------------------------------------------------- start
echo
if [ -n "$LANG_CODE" ]; then :
elif [ "$NONINT" = 1 ]; then LANG_CODE=en
else
  say 'Language / Язык:  1) English   2) Русский'
  ask '>' 1; [ "$REPLY_VAL" = 2 ] && LANG_CODE=ru || LANG_CODE=en
fi
case "$LANG_CODE" in en|ru) ;; *) LANG_CODE=en;; esac
echo; cyan "$(t title)"; cyan "=================================================="

[ -f app/TS3AudioBot ] || { red "$(t noApp)"; exit 1; }
chmod +x app/TS3AudioBot run-bot.sh start.sh stop.sh 2>/dev/null

# system libraries the bot needs
MISSING=""
ldconfig -p 2>/dev/null | grep -q 'libopus\.so\.0' || MISSING="$MISSING libopus0"
ldconfig -p 2>/dev/null | grep -q 'libicuuc\.so' || MISSING="$MISSING libicu"
if [ -n "$MISSING" ]; then red "$(t libsMissing "${MISSING# }")"; exit 1; fi
command -v unzip >/dev/null 2>&1 || { red "$(t toolMissing unzip)"; exit 1; }
command -v xz >/dev/null 2>&1 || { red "$(t toolMissing xz-utils)"; exit 1; }
command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1 || { red "$(t toolMissing curl)"; exit 1; }
# the bot looks for libopus.so in its own folder
OPUS="$(ldconfig -p | awk '/libopus\.so\.0/{print $NF; exit}')"
[ -n "$OPUS" ] && ln -sf "$OPUS" app/libopus.so

MODE=new
if [ -f data/ts3audiobot.toml ]; then
  if [ "$NONINT" = 1 ]; then [ -n "$SERVER" ] && MODE=reconfigure || MODE=update
  else
    echo; yellow "$(t existsTitle)"; say "$(t exists1)"; say "$(t exists2)"; say "$(t exists3)"
    ask "$(t choose)" 1
    case "$REPLY_VAL" in 3) exit 0;; 2) MODE=reconfigure;; *) MODE=update;; esac
  fi
fi

# tools first: everything is downloaded before the first question
[ "$NODOWNLOAD" = 1 ] || install_tools

GENERATED=0; AUTO=""
if [ "$MODE" != update ]; then
  [ "$NONINT" = 1 ] || { echo; say "$(t intro)"; }
  while :; do
    ask "$(t qServer)" "$SERVER"; SERVER="$REPLY_VAL"
    [ -n "$SERVER" ] && break
    red "$(t eServer)"; [ "$NONINT" = 1 ] && exit 1
  done
  ask "$(t qSrvPass)" "$SRVPASS" secret; SRVPASS="$REPLY_VAL"
  [ -z "$NICK" ] && NICK=MusicBot
  ask "$(t qNick)" "$NICK"; NICK="$REPLY_VAL"
  ask "$(t qChannel)" "$CHANNEL"; CHANNEL="$REPLY_VAL"
  if [ -z "$ACCESS" ]; then
    if [ "$NONINT" = 1 ]; then ACCESS=local
    else say "$(t qAccess)"; ask '>' 1; [ "$REPLY_VAL" = 2 ] && ACCESS=lan || ACCESS=local; fi
  fi
  [ -z "$PORT" ] && PORT=58913
  while :; do
    ask "$(t qPort)" "$PORT"
    if printf '%s' "$REPLY_VAL" | grep -Eq '^[0-9]+$' && [ "$REPLY_VAL" -ge 1 ] && [ "$REPLY_VAL" -le 65535 ]; then PORT="$REPLY_VAL"; break; fi
    red "$(t ePort)"; [ "$NONINT" = 1 ] && exit 1
  done
  while :; do
    ask "$(t qKey)" "$KEY"
    if [ -z "$REPLY_VAL" ]; then KEY="$(new_key)"; GENERATED=1; break; fi
    if printf '%s' "$REPLY_VAL" | grep -Eq '^[A-Za-z0-9_-]{12,}$'; then KEY="$REPLY_VAL"; break; fi
    red "$(t eKey)"; [ "$NONINT" = 1 ] && exit 1
  done
  if ask_yes_no_default_no "$(t qAdvanced)"; then ask "$(t qProxy)" "$PROXY"; PROXY="$REPLY_VAL"; fi
  if [ "$NONINT" = 1 ]; then [ "$AUTOSTART" = 1 ] && AUTO=1 || AUTO=0
  else ask_yes_no_default_no "$(t qAutostart)" && AUTO=1 || AUTO=0; fi

  ACCTEXT="$(t sLocal)"; [ "$ACCESS" = lan ] && ACCTEXT="$(t sLan)"
  if [ "$NONINT" != 1 ]; then
    echo; cyan "$(t sumHead)"
    printf '  %-18s %s\n' "$(t sServer)" "$SERVER"
    printf '  %-18s %s\n' "$(t sNick)" "$NICK"
    printf '  %-18s %s\n' "$(t sChannel)" "${CHANNEL:-$(t sDefault)}"
    printf '  %-18s port %s, %s\n' "$(t sPanel)" "$PORT" "$ACCTEXT"
    if [ "$GENERATED" = 1 ]; then printf '  %-18s %s\n' "$(t sKey)" "$(t sGenerated)"; else printf '  %-18s %s\n' "$(t sKey)" "$KEY"; fi
    printf '  %-18s %s\n' "$(t sProxy)" "${PROXY:-$(t sNone)}"
    [ "$AUTO" = 1 ] && AUT="$(t sYes)" || AUT="$(t sNo)"
    printf '  %-18s %s\n' "$(t sAutostart)" "$AUT"
    echo
    ask_yes "$(t qConfirm)" || { say "$(t aborted)"; exit 0; }
  fi

  say "$(t writing)"
  HERE="$(pwd)"
  mkdir -p data/bots/default bin
  HOSTS='["localhost"]'; [ "$ACCESS" = lan ] && HOSTS='["*"]'
  cat > data/ts3audiobot.toml <<EOF
# Generated by the installer. The bot adds all other settings with their defaults on first start.
[bot]
language = "en"

[configs]
send_stats = false

[rights]
path = "rights.toml"

[web]
hosts = $HOSTS
port = $PORT
use_ssl = true

[factories.youtube]
prefer_resolver = "YoutubeDl"

[tools]
youtube-dl = { path = $(toml_str "$HERE/bin/yt-dlp") }

[tools.ffmpeg]
path = $(toml_str "$HERE/bin/ffmpeg")
EOF
  cp -f templates/rights.toml data/rights.toml

  BOTFILE=data/bots/default/bot.toml
  IDENTITY=""
  if [ -f "$BOTFILE" ]; then
    IDENTITY="$(awk '/^\[connect\.identity\]/{p=1;print;next} /^\[/{p=0} p' "$BOTFILE")"
    cp "$BOTFILE" "$BOTFILE.bak-$(date +%Y%m%d-%H%M%S)"
  fi
  {
    cat <<'EOF'
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
EOF
    echo "address = $(toml_str "$SERVER")"
    echo "name = $(toml_str "$NICK")"
    echo "channel = $(toml_str "$CHANNEL")"
    [ -n "$SRVPASS" ] && echo "server_password = { pw = $(toml_str "$SRVPASS") }"
    cat <<'EOF'

[audio]
volume = { default = 40.0, max = 100.0, min = 0.0 }
bitrate = 96

[reconnect]
onerror = ["5s", "5s", "10s", "30s", "repeat last"]
ontimeout = ["1s", "5s", "10s", "30s", "repeat last"]
EOF
    [ -n "$IDENTITY" ] && { echo; printf '%s\n' "$IDENTITY"; }
  } > "$BOTFILE"
  printf '# TS3AudioBot secrets - do not share this file\napi_key = %s\n' "$KEY" > data/websecrets.ini
  chmod 600 data/websecrets.ini 2>/dev/null || true
  printf 'YTDLP_PROXY=%s\nPORT=%s\nACCESS=%s\nBOT_LANG=%s\n' "$PROXY" "$PORT" "$ACCESS" "$LANG_CODE" > settings.env
else
  PORT="$(sed -n 's/^PORT=//p' settings.env 2>/dev/null | head -1)"; [ -z "$PORT" ] && PORT=58913
  ACCESS="$(sed -n 's/^ACCESS=//p' settings.env 2>/dev/null | head -1)"; [ -z "$ACCESS" ] && ACCESS=local
  KEY="$(sed -n 's/^api_key *= *//p' data/websecrets.ini 2>/dev/null | head -1)"
fi


if [ -n "$AUTO" ]; then
  UNITDIR="$HOME/.config/systemd/user"
  if [ "$AUTO" = 1 ] && command -v systemctl >/dev/null 2>&1; then
    mkdir -p "$UNITDIR"
    cat > "$UNITDIR/ts3musicbot.service" <<EOF
[Unit]
Description=TeamSpeak 3 music bot
After=network-online.target

[Service]
ExecStart=$(pwd)/run-bot.sh
WorkingDirectory=$(pwd)
Restart=on-failure

[Install]
WantedBy=default.target
EOF
    systemctl --user daemon-reload && systemctl --user enable ts3musicbot >/dev/null 2>&1
  elif [ "$AUTO" = 0 ]; then
    systemctl --user disable ts3musicbot >/dev/null 2>&1 || true
  fi
fi

[ "$NOSTART" = 1 ] && exit 0
echo; cyan "$(t starting)"
./stop.sh >/dev/null 2>&1
./start.sh

say "$(t waiting)"
OK=0
if command -v curl >/dev/null 2>&1; then
  for _ in $(seq 1 60); do
    code="$(curl -sk -o /dev/null -w '%{http_code}' "https://127.0.0.1:$PORT/api/v2/auth/state" 2>/dev/null)"
    [ "$code" = 200 ] && { OK=1; break; }
    sleep 2
  done
fi
[ "$OK" = 1 ] || yellow "$(t notYet)"

HOSTNAME_SHOWN=localhost
if [ "$ACCESS" = lan ]; then ip="$(local_ip)"; [ -n "$ip" ] && HOSTNAME_SHOWN="$ip"; fi
echo; green "$(t ready)"
green "  $(t panelUrl): https://$HOSTNAME_SHOWN:$PORT"
if [ -n "$KEY" ]; then green "  $(t keyLabel): $KEY"; say "  $(t keySave)"; fi
echo; say "$(t certNote)"
[ "$ACCESS" = lan ] && say "$(t fwNote)"
say "$(t tsNote)"
echo; say "$(t manageHead)"
say "  $(t mLogs)"; say "  $(t mStop)"; say "  $(t mStart)"; say "  $(t mUpdate)"; say "  $(t mRemove)"
