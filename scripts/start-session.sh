#!/usr/bin/env bash
set -uo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"

if ! command -v script >/dev/null; then
    printf 'The script command is required (Ubuntu package: util-linux).\n' >&2
    exit 1
fi

machine=$(hostname | tr -d '\n' | tr -c '[:alnum:]_-' '_')
stamp=$(date +%Y%m%d-%H%M%S)
mkdir -p "$CMP625_ROOT/logs"
session_log=$(mktemp "$CMP625_ROOT/logs/session-${machine}-${stamp}-XXXXXX.log")
cd "$CMP625_ROOT" || exit 1
printf 'Session log: %s\n' "$session_log"
printf 'Run project commands in the new shell. Type exit to finish recording.\n'
script --return --flush --quiet --command 'bash -i' --log-out "$session_log"
session_status=$?
printf '%s\n' "$session_status" > "$session_log.exit-status"
printf 'Session finished with exit code %s. Log: %s\n' "$session_status" "$session_log"
exit "$session_status"
