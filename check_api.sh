#!/usr/bin/env bash

if [ "$#" -ne 1 ]; then
    printf 'Использование: %s URL\n' "$0" >&2
    exit 1
fi

case "$1" in
    http://?*|https://?*) ;;
    *)
        printf 'Ошибка: укажите URL, начинающийся с http:// или https://.\n' >&2
        exit 1
        ;;
esac

if ! command -v curl > /dev/null 2>&1; then
    printf 'Ошибка: команда curl не установлена.\n' >&2
    exit 1
fi

code=$(curl --silent --show-error --globoff \
    --output /dev/null --write-out '%{http_code}' \
    --connect-timeout 5 --max-time 10 -- "$1")
curl_status=$?

if [ "$curl_status" -eq 0 ] && [ "$code" = "200" ]; then
    printf 'API доступен\n'
    exit 0
fi

printf 'API недоступен, код ответа: %s\n' "${code:-000}"
exit 1
