#!/usr/bin/env bash
set -uo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
source "$CMP625_ROOT/scripts/sources.sh"

fetch_source() {
    local name=$1 url=$2 revision=$3
    local cache="$CMP625_ROOT/.cache/$name.git"
    if [[ ! -d "$cache" ]]; then
        git init --bare "$cache"
    fi
    if ! git --git-dir="$cache" cat-file -e "$revision^{commit}" 2>/dev/null; then
        git --git-dir="$cache" fetch --depth=1 "$url" "$revision"
    fi
    git --git-dir="$cache" cat-file -e "$revision^{commit}"
}

main() {
    command -v git
    command -v tar
    mkdir -p "$CMP625_ROOT/.cache"

    if [[ -e "$CMP625_ROOT/ns3" ]]; then
        [[ $(cat "$CMP625_ROOT/ns3/VERSION") == 3.29 ]]
        [[ $(cat "$CMP625_ROOT/ns3/NS3_COMMIT.txt") == "$NS3_COMMIT" ]]
        [[ $(cat "$CMP625_ROOT/ns3/UPSTREAM_COMMIT.txt") == "$PLR_COMMIT" ]]
        printf 'Existing baseline found; keeping its source and any local changes.\n'
        return
    fi

    fetch_source ns3 "$NS3_REPOSITORY" "$NS3_COMMIT"
    fetch_source plr "$PLR_REPOSITORY" "$PLR_COMMIT"

    local stage
    stage=$(mktemp -d "$CMP625_ROOT/.cache/setup-XXXXXX")
    mkdir "$stage/ns3"
    git --git-dir="$CMP625_ROOT/.cache/ns3.git" archive "$NS3_COMMIT" \
        | tar -xf - -C "$stage/ns3"
    # The release tag contains VERSION=3-dev; the distributed 3.29 tarball
    # stamps this file during release packaging. Match its library naming.
    [[ $(cat "$stage/ns3/VERSION") == 3-dev || $(cat "$stage/ns3/VERSION") == 3.29 ]]
    printf '3.29\n' > "$stage/ns3/VERSION"
    git --git-dir="$CMP625_ROOT/.cache/plr.git" archive "$PLR_COMMIT" \
        ns-3.29/src/aodv-power-light-reverse-etx \
        ns-3.29/src/wifi-power-tag \
        ns-3.29/src/applications \
        ns-3.29/scratch/multi-run-power.cc \
        | tar -xf - -C "$stage"

    cp -a "$stage/ns-3.29/src/aodv-power-light-reverse-etx/." "$stage/ns3/src/aodv/"
    cp -a "$stage/ns-3.29/src/wifi-power-tag/." "$stage/ns3/src/wifi/"
    cp -a "$stage/ns-3.29/src/applications/." "$stage/ns3/src/applications/"
    cp "$stage/ns-3.29/scratch/multi-run-power.cc" "$stage/ns3/scratch/"
    printf '%s\n' "$NS3_COMMIT" > "$stage/ns3/NS3_COMMIT.txt"
    printf '%s\n' "$PLR_COMMIT" > "$stage/ns3/UPSTREAM_COMMIT.txt"
    [[ $(cat "$stage/ns3/VERSION") == 3.29 ]]
    mv "$stage/ns3" "$CMP625_ROOT/ns3"
    printf 'Baseline source is ready in %s/ns3\n' "$CMP625_ROOT"
    printf 'Imported source retains its upstream license headers and LICENSE file.\n'
}

run_logged setup main
