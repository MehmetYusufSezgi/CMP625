# CMP625

Course project: evaluating a bounded signal-trend penalty added to AODV-PLR routing in ns-3.

- [Setup and work on both computers](docs/SETUP.md)
- [Project log, verified results and pending work](docs/PROJECT_LOG.md)

On Ubuntu 22.04 with Python 3.10 and the dependencies listed in the setup guide, run these separately from the repository root:

```bash
bash scripts/setup-baseline.sh
bash scripts/build-baseline.sh
bash scripts/run-smoke.sh
```

Each script saves a separate dated log under `logs/`. The source appears in `ns3/`; generated build files stay local to each computer. The proposed trend extension is still pending.

For manual commands, start a recorded shell with `bash scripts/start-session.sh` and type `exit` when finished. Keep step explanations in `docs/PROJECT_LOG.md`; commit the relevant `logs/` and small `results/` files with the code.
