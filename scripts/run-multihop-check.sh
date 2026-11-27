#!/usr/bin/env bash
set -uo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"

mkdir -p "$CMP625_ROOT/results"
machine=$(hostname | tr -d '\n' | tr -c '[:alnum:]_-' '_')
run_dir=$(mktemp -d "$CMP625_ROOT/results/multihop-${machine}-$(date +%Y%m%d-%H%M%S)-XXXXXX")

main() {
    require_python310
    [[ -d "$CMP625_ROOT/ns3/build" ]]
    cd "$CMP625_ROOT/ns3"
    for case_name in chain chain-relay-off direct-relay-off; do
        local layout=chain forwarding=1
        case "$case_name" in
            chain-relay-off) forwarding=0 ;;
            direct-relay-off) layout=direct; forwarding=0 ;;
        esac
        local case_dir="$run_dir/$case_name"
        local arguments="plr-chain-check --layout=$layout --relayForwarding=$forwarding"
        mkdir "$case_dir"
        printf '%s\n' "$arguments" > "$case_dir/arguments.txt"
        cp NS3_COMMIT.txt UPSTREAM_COMMIT.txt "$case_dir/"
        NS_LOG='AodvRoutingProtocol=level_debug|prefix_time|prefix_node' \
            "$CMP625_PYTHON" waf --cwd="$case_dir" --run "$arguments" \
            > "$case_dir/console.log" 2>&1
        cat "$case_dir/summary.csv"
        grep -aE '^Case:' "$case_dir/console.log"
    done
    printf 'All three controlled cases passed. Results: %s\n' "$run_dir"
}

run_logged multihop main
validation_status=$?
printf '%s\n' "$validation_status" > "$run_dir/exit-status.txt"
{
    printf '\n## Step 17 - Controlled multihop check\n\n'
    printf 'Date: %s\n\n' "$(date -Is)"
    printf 'Command: bash scripts/run-multihop-check.sh\n\n'
    printf 'Purpose: test a forced two-hop path, disable its relay, and check a direct-link control.\n\n'
    printf 'Source commit: %s (see raw log for working-tree status).\n\n' "$(git -C "$CMP625_ROOT" rev-parse HEAD)"
    printf 'Stage exit status: %s\n\nResults: %s\n\n' "$validation_status" "$run_dir"
    if [[ $validation_status -eq 0 ]]; then
        printf 'Outcome: all three case assertions passed; see per-case summary.csv, forwarding.csv and routing-tables.txt.\n'
    else
        printf 'Outcome: validation failed; retain this attempt and inspect logs before making changes.\n'
    fi
    printf '\nThe routing algorithm is unchanged. This checks one controlled topology, not loop freedom or performance under mobility.\n'
} >> "$CMP625_ROOT/docs/PROJECT_LOG.md"
exit "$validation_status"
