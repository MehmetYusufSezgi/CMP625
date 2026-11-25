# Baseline setup on Ubuntu 22.04

The previously working host and the new work computer both use Ubuntu 22.04.5, Python 3.10.12 and G++ 11.4.0. The simulator is ns-3.29 with the earlier published PLR-ETX implementation. The proposed signal-trend penalty is not implemented yet.

## Install dependencies

```bash
sudo apt-get update
sudo apt-get install -y git build-essential python3-dev python3-distutils pkg-config
```

## Prepare, build and check

From the top of this repository, run each command separately. Continue only when the previous command succeeds.

```bash
bash scripts/setup-baseline.sh
bash scripts/build-baseline.sh
bash scripts/run-smoke.sh
```

Setup downloads the exact commits recorded in `scripts/sources.sh`, exports ordinary source files into `ns3/`, and applies the upstream routing, received-power and measurement additions. The official release tag contains `VERSION=3-dev`; setup stamps it as `3.29`, as in the distributed release archive, for matching library names. Download caches stay under `.cache/`. No upstream `.git` directory is placed inside `ns3/`. Setup keeps an existing source tree when its version/provenance files match, so rerunning setup does not overwrite project changes.

The scripts can be launched from any directory. Each invocation saves commands, output, project Git revision/status, hostname and time in a new file under `logs/`. A sibling `.exit-status` file records the stage's actual exit code. A failed step returns a nonzero shell status. Smoke runs also get a unique directory under `results/` and a copy of their arguments and source revisions.

The build uses Python 3.10; its Python bindings are disabled. To select an installed Python 3.10 explicitly, use `CMP625_PYTHON=/path/to/python3.10 bash scripts/build-baseline.sh`. Use `JOBS=2 bash scripts/build-baseline.sh` to reduce parallel compilation.

## Work on both computers

Start a recorded terminal session before manual project work:

```bash
bash scripts/start-session.sh
```

Run package-install, inspection, Git and other manual commands in the new shell. Type `exit` to close it. This records terminal output and echoed commands in a unique `logs/session-*.log`, with a separate session exit-status file. It covers work performed in that terminal; source changes made in an editor are recorded through Git. Stage scripts continue to save their own per-step logs, including individual stage exit codes.

After each meaningful step, update `docs/PROJECT_LOG.md` with the date, purpose, exact command or script, observed result, errors/fixes, relevant log/result paths and next action. Distinguish completed work from planned commands. Keep failed-attempt logs and record the source revision and parameters for experiments. Historical steps written as pending describe their state at that time; later numbered entries record their completion.

Track `ns3/` source files, scripts, documentation, settings and selected small logs/CSV results in this repository. Ignore generated binaries, Waf caches and large traces using `.gitignore`. Build separately on each computer. Keep upstream license files/headers with imported source.

After the initial source setup and successful checks, review `git status` and commit the source tree and relevant evidence, including the small files under `results/`. This makes subsequent source edits and the trend extension available on both computers. A fresh clone that already includes `ns3/` can go straight to the build script.

Before working on the other computer, commit and push intended changes; on that computer, pull the branch before editing. Local source edits must be committed to travel between computers. The scripts deliberately do not commit, push, change system Python or install packages automatically.

## What the smoke run checks

The unchanged driver uses Random Waypoint mobility, 50 nodes, five flows, random-run identifier 1, 30 seconds of application traffic, and the upstream `a=0.005`, `b=60` power-metric settings. It stops after 41 simulated seconds because the driver adds startup/drain time. Its source-node selection is hardcoded around 50 nodes; smaller node counts need a driver fix first.

The expected summary is `results/smoke-*/plr-smoke-Summary.csv`. The script checks nonzero transmitted/received application traffic and consistent packet totals. A prior run on the home computer delivered 595/595 packets. That is a historical result, not a claim about an unexecuted run on another host. The smoke check does not establish multihop behavior, loop freedom, accounting correctness or performance improvement.

## Source provenance

| Input | Commit |
| --- | --- |
| Official ns-3.29, `nsnam/ns-3-dev-git` | `ac2ed49e020860381f9f69753dd94f6fc12e1edf` |
| Earlier PLR-ETX implementation, `neje/IeeeAccess2019` | `4a7ee58a624de5a13a33e8fc47f7eda988f3f7e3` |

The first source is the official ns-3.29 tag. The second accompanies Jevtic and Malnar's 2019 IEEE Access work. The 2024 PeerJ supplement previously inspected contained stock AODV model files, so it did not establish an exact copy of that paper's evaluated implementation. Document this earlier baseline explicitly; do not claim exact reproduction of the 2024 paper's experiments.

Next project work: audit represented link/path costs and route-update rules, validate a controlled multihop case, then implement and test the selectable signal-trend penalty.
