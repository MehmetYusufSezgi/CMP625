#!/usr/bin/env bash
set -uo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"

main() {
    require_python310
    [[ -d "$CMP625_ROOT/ns3/build" ]]
    mkdir -p "$CMP625_ROOT/results"
    local machine stamp run_dir arguments
    machine=$(hostname | tr -d '\n' | tr -c '[:alnum:]_-' '_')
    stamp=$(date +%Y%m%d-%H%M%S)
    run_dir=$(mktemp -d "$CMP625_ROOT/results/smoke-${machine}-${stamp}-XXXXXX")
    arguments='multi-run-power --scenario=3 --nNodes=50 --nSources=5 --simTime=30 --width=1000 --height=1000 --nodeSpeed=10 --routingProtocol=2 --routingProtocolName=APLRE --a=0.005 --b=60 --startRngRun=1 --stopRngRun=1 --currentRngRun=1 --externalRngRunControl=1 --csvFileNamePrefix=plr-smoke'
    printf '%s\n' "$arguments" > "$run_dir/arguments.txt"
    cp "$CMP625_ROOT/ns3/NS3_COMMIT.txt" "$run_dir/"
    cp "$CMP625_ROOT/ns3/UPSTREAM_COMMIT.txt" "$run_dir/"

    cd "$CMP625_ROOT/ns3"
    "$CMP625_PYTHON" waf --cwd="$run_dir" --run "$arguments"
    "$CMP625_PYTHON" - "$run_dir/plr-smoke-Summary.csv" <<'PY'
import csv
import sys

with open(sys.argv[1], newline="") as stream:
    rows = csv.reader(stream)
    next(rows)
    next(rows)
    row = next(rows)
flows, sent, received, lost = (int(row[i]) for i in (1, 5, 7, 9))
if flows != 5 or sent <= 0 or not 0 < received <= sent or lost != sent - received:
    raise SystemExit("Smoke check failed: inconsistent or empty application counters: " + repr(row))
print("Flows: {}; sent: {}; received: {}; lost: {}".format(flows, sent, received, lost))
print("Reported delivery ratio: {}%".format(row[13]))
print("Smoke check passed; multihop behavior and metric correctness need separate validation.")
PY
    printf 'Results: %s\n' "$run_dir"
}

run_logged smoke main
