#!/usr/bin/env bash
set -uo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"

main() {
    require_python310
    g++ --version
    pkg-config --version
    [[ -f "$CMP625_ROOT/ns3/UPSTREAM_COMMIT.txt" ]]
    cd "$CMP625_ROOT/ns3"
    "$CMP625_PYTHON" waf configure \
        --build-profile=debug \
        --disable-python \
        --disable-tests \
        --disable-examples \
        --disable-werror \
        --enable-modules=aodv,wave,applications,netanim,dsr,olsr,dsdv
    "$CMP625_PYTHON" waf build -j "${JOBS:-4}"
}

run_logged build main
