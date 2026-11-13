#!/usr/bin/env bash

if [ "$#" -gt 1 ] || { [ "$#" -eq 1 ] && [ "$1" != "--generate" ]; }; then
    printf 'Использование: %s [--generate]\n' "$0" >&2
    exit 1
fi

log_file="access.log"

generate_log() {
    local i ip method path code

    for ((i = 0; i < 360; i++)); do
        case $((i % 12)) in
            0|1|2|3) ip="192.168.1.10" ;;
            4|5|6) ip="10.0.0.5" ;;
            7|8) ip="192.168.1.20" ;;
            9) ip="10.0.0.8" ;;
            10) ip="172.16.0.2" ;;
            11) ip="192.168.1.30" ;;
        esac

        method="GET"
        path="/api/users"
        code=200

        case $((i % 10)) in
            3) method="POST"; path="/api/login"; code=401 ;;
            7) path="/missing"; code=404 ;;
            9) code=500 ;;
        esac

        printf '%s - - [15/Aug/2026:10:%02d:%02d] "%s %s HTTP/1.1" %s\n' \
            "$ip" "$((i / 60))" "$((i % 60))" "$method" "$path" "$code" || return 1
    done
}

if [ "${1:-}" = "--generate" ] || [ ! -e "$log_file" ]; then
    if ! generate_log > "$log_file"; then
        printf 'Ошибка: не удалось создать %s.\n' "$log_file" >&2
        exit 1
    fi
    printf 'Создан тестовый файл %s (360 строк).\n' "$log_file"
fi

if [ ! -f "$log_file" ] || [ ! -r "$log_file" ]; then
    printf 'Ошибка: файл %s недоступен для чтения.\n' "$log_file" >&2
    exit 1
fi

total=$(awk 'NF {count++} END {print count+0}' "$log_file") || exit 1
errors_4xx=$(awk '$NF ~ /^4[0-9][0-9]$/ {count++} END {print count+0}' "$log_file") || exit 1
errors_5xx=$(awk '$NF ~ /^5[0-9][0-9]$/ {count++} END {print count+0}' "$log_file") || exit 1

printf 'Общее количество запросов: %s\n' "$total"
printf 'Топ-3 IP-адреса:\n'

grep -Eo '^([0-9]{1,3}\.){3}[0-9]{1,3}[[:space:]]' "$log_file" \
    | awk '{print $1}' \
    | sort \
    | uniq -c \
    | sort -k1,1nr -k2,2 \
    | awk 'NR <= 3 {printf "  %s — %s запросов\n", $2, $1}'

printf 'Количество запросов 4xx: %s\n' "$errors_4xx"
printf 'Количество запросов 5xx: %s\n' "$errors_5xx"
printf 'Всего ошибок 4xx и 5xx: %s\n' "$((errors_4xx + errors_5xx))"
