# TS3 Sound Bot - установщик без Docker

Бот уже лежит в архиве в готовом виде (самодостаточный, .NET ставить не нужно). Установщик скачивает с официальных сайтов
три вспомогательные программы: **yt-dlp**, **deno** (нужен yt-dlp для YouTube) и **ffmpeg**. Python не нужен.

[English version](README.md)

## Windows (x64)

1. Распакуйте zip туда, где хотите держать бота (например `C:\TS3MusicBot`).
2. Дважды щёлкните `install.cmd` и ответьте на вопросы (русский / английский).
3. Установщик скачает инструменты, запишет настройки, запустит бота и покажет адрес панели и ключ доступа.

По желанию установщик включит автозапуск бота при входе в Windows (задача `TS3MusicBot` в Планировщике заданий).

Повседневно: `start.cmd` и `stop.cmd`. Логи: `data\logs\`. Обновить инструменты: снова `install.cmd`, пункт 1.
Без вопросов: `install.ps1 -NonInteractive -Server 192.168.1.10:9987 -Nickname MusicBot -Access lan -Port 58913 -Autostart`.
Удалить: `stop.cmd`, удалить папку (и задачу `TS3MusicBot`, если включали автозапуск).

## Linux (x64)

1. `tar xzf ts3musicbot-native-linux-x64.tar.gz && cd ts3musicbot-native-linux-x64`
2. Один раз поставьте системные библиотеки: `sudo apt install libicu72 libopus0` (имена для Debian/Ubuntu; в других дистрибутивах ICU и libopus).
3. `bash install.sh` и ответьте на вопросы. Установщик скачает yt-dlp, deno и ffmpeg в `bin/`.

По желанию `--autostart` (или вопрос) создаст пользовательскую службу systemd `ts3musicbot`.
Повседневно: `./start.sh`, `./stop.sh`; логи в `data/logs/`. Без вопросов: `bash install.sh --non-interactive --server 192.168.1.10:9987 --nickname MusicBot --access lan --port 58913`.

## Использование

Откройте панель (HTTPS с самоподписанным сертификатом: браузер один раз предупредит, так и должно быть), войдите по ключу, введите
название или вставьте ссылку. В чате TeamSpeak пишите боту команды с `/`, например `/play <ссылка>`, `/help`.
Положите в `data/` файл `cookies.txt` с cookies YouTube (формат Netscape), если YouTube просит подтвердить, что вы не бот.

## Папки

`app/` бот, `bin/` скачанные инструменты, `data/` ваши настройки, плейлисты и логи (создаются установщиком), `settings.env` порты и прокси.
