# CMP625 Project Log

Project: Evaluating Signal-Trend-Aware AODV-PLR Routing in Vehicular Ad Hoc Networks

Owner: Mehmet Yusuf Sezgi

Started: 2026-10-31 (Europe/Istanbul)

## Logging agreement

Keep this document updated after each project step discussed in this conversation. Record the purpose, commands or code changes, observed results, errors, fixes, and next action. Preserve earlier findings when adding corrections. Label commands as pending until execution output or another check confirms the result. User PC execution and assistant-side inspection are separate sources of evidence. Raw terminal logs can only contain output actually received or captured; do not reconstruct missing output.

## Current checkpoint

Restart update (2026-11-25): the user created a public Git repository at `/home/ekin/Desktop/cmp625/CMP625`. The work computer has now built the baseline successfully (2m5.072s) and passed the smoke test with 595/595 packets and exit status 0. The assistant's separate validation also passed. Preserve both sets of evidence. The source/scripts/logs/results have not yet been confirmed committed and pushed.

- Proposal and both supplied archives inspected.
- All 14 supplied AODV model files match official ns-3.29 exactly; no ETX/LETX/PLR implementation was found in the supplied simulator archive.
- An earlier published PLR-ETX implementation was located and inspected as a candidate baseline.
- User successfully cloned its repository on the development PC.
- User PC environment confirmed: Ubuntu 22.04.5 LTS, Python 3.10.12, G++ 11.4.0.
- User supplied successful build output from `/home/yusuf/Desktop/cmp625_project/ns3-plr`; build elapsed time was 2m3.107s.
- The working simulator tree and a successful configuration/build are established by that output. Exact dependency installation, source-overlay contents, configuration flags and cloned commit have not been independently verified on the user PC.
- First baseline smoke run completed with exit status 0: five flows, 595 application packets sent and 595 received, reported packet delivery ratio 100%.
- User confirmed upstream commit `4a7ee58a624de5a13a33e8fc47f7eda988f3f7e3`.
- Multihop behavior and routing correctness remain to be validated. Our signal-trend modification has not been implemented.

## Step 01 - Review the proposal

Date: 2026-10-31

Status: COMPLETE - assistant inspected the supplied PDF.

Input: `CMP625_V2X_Project_Proposal.pdf`.

Core scope:

- Compare unchanged AODV-PLR with the same implementation plus a bounded penalty for declining received signal strength.
- Retain a short, smoothed, timestamped signal history per neighbor.
- Candidate cost: `modified_cost = baseline_cost + lambda * penalty`, with `penalty` bounded to `[0, 1]`.
- Stable/improving signal and insufficient/stale history add no penalty; `lambda = 0` must recover baseline behavior.
- Reuse existing probes and baseline routing validity/freshness rules. Do not force proactive repair or switching solely because the signal trend changes.
- Audit cost encoding, rounding and saturation before interpreting experiments.
- Compare delivery ratio, delay and routing overhead under matched inputs; include repetitions and report mixed/negative results.
- First feasibility milestone: compile the baseline and run an unchanged PLR scenario.

Terminology: PLR in AODV-PLR refers to Power-based Light Reverse ETX, not Packet Loss Ratio. The latter is an evaluation metric.

## Step 02 - Inspect the supplemental archives

Date: 2026-10-31

Status: COMPLETE - assistant inspected the uploaded archive bytes.

Inputs:

| Archive | Identified contents |
| --- | --- |
| `code.tar.bz2` | `ns-allinone-3.29`, including `ns-3.29`; its `VERSION` file reads `3.29` |
| `bonnmotion.zip` | BonnMotion 3.0.1, including a Nomadic mobility model |

Inspection method:

1. Listed archive members and checked for nested archives, alternate AODV implementations and scenario files.
2. Extracted temporary inspection copies on the assistant environment.
3. Searched for ETX, LETX, PLR, link-cost and RSSI-related implementation code.
4. Inspected AODV neighbor state, routing logic and RREQ/RREP serialization.
5. Computed Git blob SHA-1 values for all 14 files under `ns-3.29/src/aodv/model` and compared them with the official `ns-3.29` tag.

Result: 14/14 AODV model files match the official release exactly. No ETX/LETX/PLR implementation was found in this archive. The scratch directory contains the standard scratch examples. The presence of the simulator archive does not establish that the paper's evaluated protocol implementation or experimental inputs were supplied.

Official comparison source:

https://github.com/nsnam/ns-3-dev-git/tree/ns-3.29/src/aodv/model

Build probe on the ASSISTANT environment only:

```bash
python3 /tmp/cmp625-source-audit/ns-allinone-3.29/ns-3.29/waf --version
```

Observed environment: Python 3.12.14, G++ 13.3.0.

Observed failure: `ModuleNotFoundError: No module named 'imp'` in bundled Waf 2.0.9. The launcher also emitted deprecation/syntax warnings. No simulator compilation was attempted in that probe. This is not a failure observed on the user's Python 3.10 PC.

## Step 03 - Locate a candidate PLR baseline

Date: 2026-10-31

Status: COMPLETE for source discovery and selected source inspection. A user-side simulator build later succeeded (Step 07); baseline runtime behavior and equivalence to the 2024 paper remain UNVERIFIED.

Repository: https://github.com/neje/IeeeAccess2019

Associated earlier work: N. Jevtic and M. Malnar, "Novel ETX-based metrics for overhead reduction in dynamic ad hoc networks," IEEE Access, 2019.

Assistant-inspected upstream commit: `4a7ee58a624de5a13a33e8fc47f7eda988f3f7e3` (commit date 2020-07-01). The user subsequently confirmed this exact commit after the first smoke run.

Verified relevant paths:

| Path in repository | Purpose |
| --- | --- |
| `ns-3.29/src/aodv-power-light-reverse-etx/` | PLR-ETX AODV implementation |
| `ns-3.29/src/wifi-power-tag/` | Received-power packet tag and Wi-Fi channel support |
| `ns-3.29/src/applications/` | NPAF measurement utilities and application additions |
| `ns-3.29/scratch/multi-run-power.cc` | Example simulation driver |
| `ns-3.29/multi-run-power.sh` | Upstream batch-run script |

The README's PLR directory name omits "reverse" in one instruction. The actual verified directory is `aodv-power-light-reverse-etx`; the supplied assembly commands use that actual path.

Selected implementation findings:

- `aodv-neighbor-etx.cc` stores recent received LPP/probe counts and the latest received power per neighbor.
- `UpdateNeighborEtx(...)` overwrites the stored power with the latest measurement.
- `CalculateBinaryShiftedEtx(...)` combines reception counts and power, rounds the represented metric and returns an 8-bit cost. Encoding and accumulation require further audit before adding a penalty.
- `wifi-power-tag/model/yans-wifi-channel.cc` adds/updates `RxPowerTag` using received power and receiver gain.
- The example accepts routing, scenario, node-count, source-count, duration and random-run arguments.

Limit: this earlier implementation has NOT been proven identical to the 2024 reference paper's implementation. If adopted, document its provenance explicitly rather than claiming exact reproduction of the 2024 experiments. No full experiment batch has been started.

## Step 04 - Clone the repository on the user PC

Date: 2026-10-31

Status: COMPLETE - confirmed by user terminal output.

Working directory: `/home/yusuf/Desktop/cmp625_project`

Command:

```bash
git clone https://github.com/neje/IeeeAccess2019.git
```

Observed result:

```text
Cloning into 'IeeeAccess2019'...
Receiving objects: 100% (331/331), 20.90 MiB | 11.54 MiB/s, done.
Resolving deltas: 100% (110/110), done.
```

Repository path: `/home/yusuf/Desktop/cmp625_project/IeeeAccess2019`.

## Step 05 - Record the user PC environment

Date: 2026-10-31

Status: COMPLETE - confirmed by user terminal output.

Commands:

```bash
cat /etc/os-release
python3 --version
g++ --version
```

Observed values:

| Item | Value |
| --- | --- |
| Terminal user / hostname | `root@yusuf` |
| Working directory | `/home/yusuf/Desktop/cmp625_project` |
| OS | Ubuntu 22.04.5 LTS (Jammy Jellyfish) |
| Python | 3.10.12 |
| G++ | 11.4.0, Ubuntu package `11.4.0-1ubuntu1~22.04.3` |

Decision: try this environment with the supplied ns-3.29 Waf build. The assistant's Python 3.12 `imp` failure does not establish a failure on Python 3.10. GCC compatibility remains to be tested. No system Python replacement has been requested.

## Step 06 - Assemble and build the baseline

Date: 2026-10-31

Status: BUILD SUCCESS REPORTED subsequently in Step 07. The commands below are the supplied procedure, not a complete record of the user's executed shell history. Exact flags and overlay execution have not been confirmed individually.

Purpose: combine the provided ns-3.29 simulator with the earlier upstream PLR implementation, without implementing our signal-trend extension.

### 6.1 Dependencies - pending

```bash
apt-get update
apt-get install -y build-essential python3-dev python3-distutils pkg-config
```

### 6.2 Extract and make a working copy - pending

Assumption: the archive is at `/home/yusuf/Downloads/code.tar.bz2`. Its location on the user's PC is unconfirmed; adjust if needed. Run the initial copy only when `ns3-plr` does not already exist, to avoid nesting an additional source tree inside it.

```bash
cd /home/yusuf/Desktop/cmp625_project
tar -xjf /home/yusuf/Downloads/code.tar.bz2
cp -a ns-allinone-3.29/ns-3.29 ns3-plr
```

Intended layout:

| Directory | Role |
| --- | --- |
| `IeeeAccess2019/` | Cloned upstream additions |
| `ns-allinone-3.29/ns-3.29/` | Untouched extracted simulator reference |
| `ns3-plr/` | Working simulator with PLR additions |

### 6.3 Overlay upstream code - pending

```bash
cd /home/yusuf/Desktop/cmp625_project

cp -a IeeeAccess2019/ns-3.29/src/aodv-power-light-reverse-etx/. \
    ns3-plr/src/aodv/

cp -a IeeeAccess2019/ns-3.29/src/wifi-power-tag/. \
    ns3-plr/src/wifi/

cp -a IeeeAccess2019/ns-3.29/src/applications/. \
    ns3-plr/src/applications/

cp IeeeAccess2019/ns-3.29/scratch/multi-run-power.cc \
    ns3-plr/scratch/

git -C IeeeAccess2019 rev-parse HEAD > ns3-plr/UPSTREAM_COMMIT.txt
```

These changes copy existing upstream code, not our proposed extension. They overwrite files in the working tree while preserving the extracted reference tree.

### 6.4 Configure - prerequisite satisfied by later build; exact flags unconfirmed

```bash
cd /home/yusuf/Desktop/cmp625_project/ns3-plr
set -o pipefail

python3 waf configure \
    --build-profile=debug \
    --disable-python \
    --disable-tests \
    --disable-examples \
    --disable-werror \
    --enable-modules=aodv,wave,applications,netanim,dsr,olsr,dsdv \
    2>&1 | tee configure.log
```

Choices:

- Compile the C++ simulator; disable optional Python bindings.
- Disable stock test/example targets for the first build attempt; `scratch/multi-run-power.cc` remains the intended simulation target.
- Keep assertions/debug support through the debug profile.
- Disable treating warnings as errors for this older code on a newer compiler.
- Build relevant modules and their dependencies.

### 6.5 Build - completed; see Step 07

Only proceed if configuration succeeds.

```bash
python3 waf build -j4 2>&1 | tee build.log
```

Expected raw logs IF these commands are executed:

- `/home/yusuf/Desktop/cmp625_project/ns3-plr/configure.log`
- `/home/yusuf/Desktop/cmp625_project/ns3-plr/build.log`

The full log files have not been received or verified; the user supplied the successful build tail. `tee` overwrites the same filename if the command is rerun; retain failed-attempt logs under distinct filenames before retries. Subsequent commands should use separate attempt directories or numbered attempt logs when needed.

## Step 07 - Confirm successful simulator build

Date: 2026-10-31

Status: COMPLETE - confirmed by user terminal output.

User directory: `/home/yusuf/Desktop/cmp625_project/ns3-plr`

Decisive received output (excerpt):

```text
[1777/1777] Linking build/src/tap-bridge/ns3.29-tap-creator-debug
Waf: Leaving directory `/home/yusuf/Desktop/cmp625_project/ns3-plr/build'
Build commands will be stored in build/compile_commands.json
'build' finished successfully (2m3.107s)
```

Modules reported built include `aodv`, `applications`, `core`, `internet`, `mobility`, `netanim`, `network`, `propagation`, `wave`, `wifi`, `dsr`, `dsdv` and `olsr`. The output lists additional modules such as LTE, WiMAX, tap-bridge and fd-net-device beyond the earlier requested selection; the actual configure command/cache is unconfirmed. No reconfiguration is needed solely for that difference.

Not built: `brite`, `click`, `openflow`, `visualizer`. None is needed for the planned initial smoke run.

No compiler failure or compatibility fix was reported in the received excerpt. This confirms a successful build, not packet delivery, PLR metric behavior, or exact reproduction of the paper. The full build log and source version are still to be retained from the user's PC.

## Step 08 - First baseline smoke run

Date: 2026-10-31

Status: COMPLETE for first functional smoke run - user supplied successful execution and CSV output.

Purpose: check that the upstream example runs, sends/receives traffic and produces its summary. This is a functional check, not an experiment supporting the research hypothesis.

Source inspection findings relevant to the run:

- Example: `scratch/multi-run-power.cc` at the previously inspected upstream commit.
- The example selects source nodes with `vehicles.Get(50-1-i)` rather than using `nNodes`. Use 50 nodes and 5 sources for this unchanged example. Generalizing this index is a later scenario-driver fix, not part of the routing extension.
- `scenario=3` uses built-in Random Waypoint mobility and does not require an external movement trace. It is NOT the proposal's Nomadic mobility model.
- `routingProtocol=2` selects the compiled AODV implementation. The `routingProtocolName` string is a label with a special parameter-setting branch, not a general switch between stock AODV and PLR binaries.
- `routingProtocolName=APLRE` activates that parameter-setting branch. Pass `a=0.005`, `b=60`, matching the upstream batch script's settings; these are baseline power-metric coefficients, not our proposed trend-penalty parameters.
- Applications start after 10 simulated seconds. `simTime=30` gives a simulator stop time of 41 seconds, not 30 seconds.
- The driver emits `current-status.txt`, `routing_table` and a summary named `<csvFileNamePrefix>-Summary.csv` relative to its working directory.

Proposed commands (first use of `smoke-001`; use a new directory for retries to preserve prior output):

```bash
cd /home/yusuf/Desktop/cmp625_project/ns3-plr
mkdir -p results/smoke-001
set -o pipefail

python3 waf --cwd="$PWD/results/smoke-001" --run \
"multi-run-power --scenario=3 --nNodes=50 --nSources=5 --simTime=30 --width=1000 --height=1000 --nodeSpeed=10 --routingProtocol=2 --routingProtocolName=APLRE --a=0.005 --b=60 --startRngRun=1 --stopRngRun=1 --currentRngRun=1 --externalRngRunControl=1 --csvFileNamePrefix=plr-smoke" \
    2>&1 | tee results/smoke-001/run.log

printf 'Simulation command exit code: %s\n' "${PIPESTATUS[0]}" \
    | tee results/smoke-001/exit-status.txt

head -n 3 results/smoke-001/plr-smoke-Summary.csv
cat UPSTREAM_COMMIT.txt
```

Planned evidence:

- `results/smoke-001/run.log`: simulator/Waf output including stderr.
- `results/smoke-001/exit-status.txt`: actual Waf/simulator command exit code from Bash `PIPESTATUS`.
- `results/smoke-001/plr-smoke-Summary.csv`: inspect the first three lines (two header rows and one run row).
- `results/smoke-001/current-status.txt`: simulated-time progress written by the example.
- `UPSTREAM_COMMIT.txt`: source revision, if the earlier recording command was executed.

Success criteria: exit status 0, a nonempty run summary and nonzero transmitted/received application packets. This small scenario does not establish useful multihop behavior, loop freedom, matched random streams, accounting correctness, or performance improvement. Audit those separately before comparative experiments.

## Step 09 - Successful smoke-run results and progress checkpoint

Date: 2026-10-31

Status: COMPLETE for recording the smoke-run outcome.

Observed command exit status: 0. Waf reported its incremental build phase completed in 1.572s; that value is not a measured simulation runtime.

Confirmed user source revision: `4a7ee58a624de5a13a33e8fc47f7eda988f3f7e3`.

Exact CSV data row supplied by the user:

```csv
1,5,2065.34,10187.7,119,595,119,595,0,0,0,0,100,100,,3255,,16.0743,0.217163,0.216456,7.49687,9.89024,0.279074,0.279074,0.25,0.25,0.667317,0.681276
```

| Metric | Reported value |
| --- | --- |
| Random-run identifier | 1 |
| Flows | 5 |
| Total application packets sent | 595 |
| Total application packets received | 595 |
| Application packets lost | 0 |
| Packet delivery ratio | 100% |

Interpretation: the example ran, exchanged application traffic and produced summary statistics. This one case does not establish multihop routing, metric correctness, loop freedom, or comparative performance. Perfect delivery here does not imply that the trend extension will help. Raw logs remain on the user PC under `results/smoke-001/`; only pasted output has been received here.

Estimated overall project progress: about 20%. This is a planning estimate, not a measured percentage. Setup, compilation and an initial baseline run are complete. Baseline audit, controlled multihop validation, the trend extension, correctness/equivalence checks, repeated matched experiments, analysis and final reporting remain.

## Next action

Commit and push the verified baseline source, scripts, progress notes, raw logs and small result files so both computers share the checkpoint. Then audit the baseline metric, cost encoding and route-update path, establish a controlled multihop validation case, and implement/validate the selectable trend penalty before comparative experiments.

## Future step-entry template

```text
Step ID / title:
Date (Europe/Istanbul):
Status (pending / running / completed / failed / blocked):
Purpose:
Environment and source version:
Commands / changed files:
Observed output and raw log paths:
Result / validation:
Errors and fixes:
Next action:
```

## Step 10 - Restart on a new computer using a shared Git repository

Date: 2026-11-25 (Europe/Istanbul)

Status: INITIAL STATE REPORTED; new environment check and setup pending.

User supplied terminal state:

```text
root@ekin:/home/ekin/Desktop/cmp625/CMP625# la
.git  README.md
```

The repository URL, new host OS, Python/compiler versions and remote branch state have not yet been supplied. The new repository is intended for use on both the work and home computers. Do not assume the previous computer's build dependencies or paths are present.

Carry forward the verified baseline: ns-3.29 with the earlier PLR-ETX additions at upstream commit `4a7ee58a624de5a13a33e8fc47f7eda988f3f7e3`. The previous smoke test used 50 nodes, five flows and Random Waypoint mobility, delivering 595/595 packets. The signal-trend extension is still pending.

Repository plan: track source changes, setup/build/run scripts, experiment settings, progress notes and selected small result logs. Keep generated binaries, per-machine build caches and bulky temporary output outside version control. Inspect the existing README and repository state before changing its contents. Record environment and commands on each host. No commit or push has been performed by the assistant.

First proposed commands (PENDING execution on the new PC):

```bash
cd /home/ekin/Desktop/cmp625/CMP625
mkdir -p docs logs scripts results
set -o pipefail

env_log="logs/environment-$(hostname)-$(date +%Y%m%d-%H%M%S).log"

{
    date -Is
    hostname
    pwd
    cat /etc/os-release
    python3 --version
    g++ --version
    git --version
    git status --short --branch
    git remote -v
} 2>&1 | tee "$env_log"
```

Next: receive this output, inspect the repository and establish its ignore rules, source provenance and reproducible baseline setup. The old results remain historical evidence; no successful new-host build is claimed.


## Step 11 - Confirm new host and prepare repository workflow

Date: 2026-11-25 (Europe/Istanbul)

New user-host environment confirmed from pasted output:

| Item | Value |
| --- | --- |
| Host | ekin |
| Project root | /home/ekin/Desktop/cmp625/CMP625 |
| OS | Ubuntu 22.04.5 LTS |
| Python | 3.10.12 |
| G++ | 11.4.0, Ubuntu 11.4.0-1ubuntu1~22.04.3 |
| Git | 2.34.1 |
| Branch | main tracking origin/main |
| Remote | https://github.com/MehmetYusufSezgi/CMP625.git |
| Untracked files reported | logs/ |
| Captured timestamp | 2026-11-25T07:23:59+03:00 |

The user made the repository public. Assistant read access was then verified. The initial main commit is `cf9db13ff73bf954206418b20f08b14180e87c0e`; README initially contains only `# CMP625`.

Plan: prepare a separate `setup/reproducible-baseline` branch for review with source setup, build and smoke scripts, Git ignore rules and this log. The source is exported as ordinary files into `ns3/`, with immutable source revisions recorded by `scripts/sources.sh`. Source edits and selected logs/results can be committed to the project repository. Each computer must build its own generated binaries. Setup preserves an existing matching source tree.

The official ns-3.29 release tag was resolved to `ac2ed49e020860381f9f69753dd94f6fc12e1edf`. Its Git tree contains `VERSION=3-dev`; release packaging stamps the version. During setup validation, the initial strict VERSION check failed with status 1. The setup script was corrected to stamp `3.29`, matching the distributed archive's library naming, and setup then succeeded. This is a packaging normalization, not a routing change.

Assistant validation performed separately from the user PC: successful source fetch/export/overlay, matching 37 overlaid files byte-for-byte against the pinned earlier PLR repository, no nested Git repository inside `ns3/`, successful repeat setup without overwriting the source, and Bash syntax checks. Fresh build and smoke validation subsequently passed on the assistant environment; new user-host build and simulation are pending. Details and raw evidence follow.



## Step 12 - Validate reproducible repository scripts

Date: 2026-11-25 (Europe/Istanbul)

Status: COMPLETE on assistant validation environment; user-PC execution pending.

Validation environment: Python 3.10.22, G++ 14.2.0 (Debian). Python 3.10 was installed in the assistant workspace cache for validation only. The user's environment remains Python 3.10.12 / G++ 11.4.0; no assistant-side action changed the user's computer.

| Check | Observed result |
| --- | --- |
| Bash syntax | All five scripts passed `bash -n` |
| Fresh source setup | Exit 0 after the documented release-version stamping correction |
| Repeat setup | Exit 0; existing source kept |
| Upstream overlay comparison | 37 files match pinned upstream bytes |
| Nested source Git repository | None inside `ns3/` |
| Ignore rules | Build, Waf and download-cache paths ignored |
| Logger failure propagation | Intentional `false` returned exit 1, logged the error and stopped before the next command |
| Configure | Exit 0; 1.308s reported by Waf |
| Build | Exit 0; 2m24.465s reported by Waf |
| Smoke script and CSV check | Exit 0; 5 flows, 595 sent, 595 received, 0 lost, reported PDR 100% |

No routing changes were introduced. Compiler deprecation warnings were emitted and retained in the compressed build log. The two smoke results match in sent/received counts; this does not prove exact equivalence of all metrics or validate multihop routing.

Raw validation evidence is included under `logs/assistant-validation-2026-11-25/`. The build log is gzip-compressed; use `gzip -dc logs/assistant-validation-2026-11-25/build.log.gz` to read it. The intentional-failure log is a logging-system check, not a failed simulator run. These are assistant-side logs, not results obtained on the user's new work computer.

Scripts supplied: `scripts/setup-baseline.sh`, `scripts/build-baseline.sh`, `scripts/run-smoke.sh`, plus shared logging and source-version definitions. Each invocation creates a unique host/time-stamped log and exit-status file. `docs/SETUP.md` explains dependencies, source provenance, working on both computers and the limits of the smoke check.

## Step 13 - Deliver setup changes for local application

Date: 2026-11-25 (Europe/Istanbul)

GitHub read access succeeded after the user made the repository public. A GitHub Git-blob write returned HTTP 403, `Resource not accessible by integration`. No remote branch, commit or pull request was created. The local implementation was prepared on `setup/reproducible-baseline`.

Delivery: a Git binary patch containing the scripts, documentation, ignore rules and validation logs, based on original main commit `cf9db13ff73bf954206418b20f08b14180e87c0e`. Apply it locally on a new branch, review the changes, run the three stages on the user's PC, and commit/push using the user's Git credentials. This avoids requiring a new repository clone or copying a nested `.git` directory.

The patch does not contain generated simulator binaries or the full exported source tree. `setup-baseline.sh` creates that source tree reproducibly. After successful user-side validation, commit `ns3/` source with the project so changes travel between home/work computers; the build and cache paths are ignored.

## Step 14 - Verify baseline build and smoke run on the work computer

Date: 2026-11-25 (Europe/Istanbul)

Status: COMPLETE - confirmed by the user's pasted terminal output.

Host/project: `ekin`, `/home/ekin/Desktop/cmp625/CMP625`.

Environment: Ubuntu 22.04.5 LTS, Python 3.10.12, G++ 11.4.0. The stage log records repository HEAD `cf9db13ff73bf954206418b20f08b14180e87c0e`, with README modified and `.gitignore`, docs, logs, ns3 and scripts untracked. This means the run used local uncommitted source and setup files; it does not demonstrate a committed/pushed checkpoint.

Commands: the user supplied the successful build tail and execution of `bash scripts/run-smoke.sh`. The earlier provided build script is `bash scripts/build-baseline.sh`; its invocation line and full log filename are not present in the received excerpt.

Observed build result:

```text
'build' finished successfully (2m5.072s)
Stage exit code: 0
```

The needed AODV, applications, mobility, internet, network, Wi-Fi and WAVE modules were built. Optional brite, click, openflow and visualizer modules were not built. No build fix or runtime error was reported in the supplied output.

Observed smoke result:

```text
Flows: 5; sent: 595; received: 595; lost: 0
Reported delivery ratio: 100%
Smoke check passed; multihop behavior and metric correctness need separate validation.
Stage exit code: 0
```

Evidence paths on the work computer:

- `logs/smoke-ekin-20261125-074134-YJYx3I.log`
- `logs/smoke-ekin-20261125-074134-YJYx3I.log.exit-status`
- `results/smoke-ekin-20261125-074134-hXvaDL/plr-smoke-Summary.csv`
- The same results directory contains `arguments.txt`, `NS3_COMMIT.txt` and `UPSTREAM_COMMIT.txt`.
- The script-generated build log is under `logs/build-ekin-*.log`; the exact name has not been supplied.

The smoke stage started at `2026-11-25T07:41:34+03:00`. Waf reported an incremental build of 1.393s during that invocation; that is not the simulation runtime. The scenario and parameters are the unchanged script settings documented in Step 08 and `scripts/run-smoke.sh`.

Interpretation: a functioning baseline has been re-established on the work computer. Sent/received totals match the earlier home and assistant runs. This does not validate useful multihop behavior, loop freedom, cost encoding or the proposed trend extension. No trend-routing code has been added yet.

## Step 15 - Make step logging explicit

Date: 2026-11-25 (Europe/Istanbul)

The user requested a record of every step that is understandable later. The scripts already record commands, output, host/time, repository revision/status and stage exit code. `docs/PROJECT_LOG.md` supplies the purpose, decisions, outcomes and next actions. Experiment directories keep the arguments, upstream revisions and result CSV files.

Coverage limit: earlier manual commands are recorded only when present in this narrative, pasted terminal output or separately saved logs. A complete raw transcript of every past terminal action is not available. Do not invent missing output or claim that it was captured. Some early entries retain pending labels from when they were written; later entries record their verified completion.

Added `scripts/start-session.sh` to record future manual project commands and terminal output. It starts a new shell and ends when the user types `exit`; per-stage script logs continue to be saved separately. Setup documentation now describes the logging procedure. Git diffs/commits preserve editor changes, and selected logs plus small results must be committed and pushed to travel between computers.

Correction to the earlier staging instruction: include `results/` as well as `logs/`; otherwise the CSV output would stay local. Large traces and build/cache files are covered by `.gitignore`.

Assistant validation of the new session recorder: Bash syntax passed; a recorded shell captured a test marker and preserved an explicit exit status of 7. The nonzero status was intentional to verify error-status recording.

## Step 16 - Inspect baseline route discovery

Date: 2026-11-27

Purpose: determine whether the existing smoke scenario discovers multihop routes.

Static source audit:
- Received probes update neighbor reception counts and the latest signal power.
- Link costs are rounded to 8-bit integers; cumulative route costs saturate at 255.
- RREQ and RREP processing accumulate these costs.
- The RREP sequence-number update conditions require a targeted correctness check before modifying routing.

Action: repeat the unchanged smoke test with AodvRoutingProtocol debug logging enabled.
Routing implementation and simulation settings remain unchanged.
Interpretation of the diagnostic output is pending.

Diagnostic exit status: 0
Diagnostic log: /home/ekin/Desktop/cmp625/CMP625/logs/route-audit-20261127-072149-iiC1dv.log

## Step 17 - Controlled multihop check

Date: 2026-11-27T07:37:01+03:00

Command: bash scripts/run-multihop-check.sh

Purpose: test a forced two-hop path, disable its relay, and check a direct-link control.

Source commit: f0555f68aacd706fdafab5c0e96fb13310691618 (see raw log for working-tree status).

Stage exit status: 0

Results: /home/ekin/Desktop/cmp625/CMP625/results/multihop-ekin-20261127-073654-K9hzU5

Outcome: all three case assertions passed; see per-case summary.csv, forwarding.csv and routing-tables.txt.

The routing algorithm is unchanged. This checks one controlled topology, not loop freedom or performance under mobility.
