#!/usr/bin/env bash

CMP625_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
CMP625_PYTHON=${CMP625_PYTHON:-python3}

require_python310() {
    "$CMP625_PYTHON" -c '
import sys
if sys.version_info[:2] != (3, 10):
    raise SystemExit("Use Python 3.10 for this baseline; set CMP625_PYTHON to its executable.")
print(sys.version)
'
}

run_logged() {
    local label=$1
    shift
    local machine stamp log
    machine=$(hostname | tr -d '\n' | tr -c '[:alnum:]_-' '_')
    stamp=$(date +%Y%m%d-%H%M%S)
    mkdir -p "$CMP625_ROOT/logs"
    log=$(mktemp "$CMP625_ROOT/logs/${label}-${machine}-${stamp}-XXXXXX.log")
    printf 'Log: %s\n' "$log"

    (
        set -euo pipefail
        trap 'printf "Stage exit code: %s\n" "$?"' EXIT
        date -Is
        hostname
        printf 'Project: %s\n' "$CMP625_ROOT"
        git -C "$CMP625_ROOT" rev-parse HEAD
        git -C "$CMP625_ROOT" status --short
        set -x
        "$@"
    ) 2>&1 | tee "$log"
    local -a statuses=("${PIPESTATUS[@]}")
    printf '%s\n' "${statuses[0]}" > "$log.exit-status"
    if [[ ${statuses[1]} -ne 0 ]]; then
        printf 'Could not finish writing the log.\n' >&2
        return "${statuses[1]}"
    fi
    return "${statuses[0]}"
}
