# Baseline route-discovery and forwarding checks

## Why this step was needed

On 2026-11-27 the work-host diagnostic reported working AODV logging, zero RREQ transmissions and 595 existing-route uses for 595 delivered application packets. The raw user log is `logs/route-audit-20261127-072149-iiC1dv.log`; its check output is in the sibling `.check.txt` file. This shows that the previous smoke run did not exercise route discovery. The likely explanation is direct-neighbor routes established by probes; that diagnostic did not itself measure forwarding hops.

The next check therefore imposes a topology in which the source cannot reach the receiver directly. It is a functional baseline check, before adding the signal-trend penalty.

## Run

From the repository root, after the baseline has been configured/built:

```bash
bash scripts/run-multihop-check.sh
```

The runner builds the new scratch scenario on demand and runs three independent simulator processes. It creates a unique `results/multihop-<host>-<time>-*/` directory and a `logs/multihop-*.log` file. It also appends the actual run status and result directory to `docs/PROJECT_LOG.md`, including failed attempts. `start-session.sh` is optional.

No existing AODV/PLR implementation files are changed. New scenario: `ns3/scratch/plr-chain-check.cc`.

## Topology and cases

Three stationary nodes are placed at x = 0, 100 and 200 metres. Node 0 sends 12 UDP packets, one per second starting at 15 seconds, to node 2. The run ends at 30 simulated seconds. Probe reception is allowed to warm up before traffic starts. Use the baseline power-metric parameters Alpha = 0.005, Beta = 60 and random seed/run = 1.

The channel combines a hard range cutoff with deterministic log-distance attenuation. The attenuation produces negative received-power values and positive link costs inside the allowed range. This artificial channel isolates connectivity for validation; it is not the mobility/propagation configuration for the final performance study.

| Case | Allowed radio range | Relay IP forwarding | Expected delivery | Expected data forwards by relay |
| --- | --- | --- | --- | --- |
| `chain` | 110 m | On | 12 | 12 |
| `chain-relay-off` | 110 m | Off | 0 | 0 |
| `direct-relay-off` | 250 m | Off | 12 | 0 |

At 110 m, node 0 can reach only node 1, and node 2 can reach only node 1. Successful delivery must therefore cross two radio links. Turning off IP forwarding at node 1 checks that delivery actually depends on the relay. The 250 m control makes direct delivery possible despite the disabled relay.

## What is measured

- Source data sends: IPv4 `Tx` events for this UDP flow on a physical interface; fake loopback transmissions used during route discovery are excluded.
- Relay data forwarding: IPv4 `UnicastForward` events at node 1, filtered by source/destination IP and UDP port 9000. Count both events and unique UDP sequence numbers.
- Delivered data: the UDP server's received-packet count at node 2.
- Source RREQ transmissions: the AODV `Tx` trace filtered by message type. The chain cases must emit at least one RREQ. Retransmissions/expanding-ring attempts count as transmissions, not separate unique discovery events.
- Route tables: snapshots at 16 and 27 seconds.

Each case saves `summary.csv`, `forwarding.csv`, `routing-tables.txt`, `console.log`, its arguments and upstream revision files. The C++ scenario returns failure if the case-specific assertions fail; the wrapper preserves that nonzero status.

## Assistant validation, 2026-11-27

Validation environment: Python 3.10.22 and G++ 14.2.0, separate from the user's Ubuntu 22.04 / Python 3.10.12 / G++ 11.4.0 work computer.

| Case | Source data sends | Relay data forwards | Received | Source RREQ transmissions | Outcome |
| --- | --- | --- | --- | --- | --- |
| chain | 12 | 12 | 12 | 3 | PASS |
| chain-relay-off | 12 | 0 | 0 | 3 | PASS |
| direct-relay-off | 12 | 0 | 12 | 0 | PASS |

The positive chain's source table recorded destination `10.2.0.3`, gateway `10.2.0.2` and hop count 2. The relay trace recorded 12 unique UDP sequences, each forwarded once, with TTL 63. This supports correct forwarding for this particular flow/topology. The suite returned exit status 0.

An initial assistant compile attempt failed because a test constant named `PACKETS` conflicted with ns-3's `QueueSizeUnit::PACKETS`. It was renamed to `TEST_PACKET_COUNT`; the next attempt compiled and all three cases passed. This affected only the new scenario. The failed attempt and successful logs are retained in `logs/assistant-multihop-validation-2026-11-27.tar.gz`.

User-PC execution of this new check is pending until its output is received.

## Remaining correctness questions

The controlled topology does not prove loop freedom, robust behavior under mobility, or correct route ranking among alternatives. The unchanged baseline still needs targeted review:

- Link costs are rounded integers and path costs saturate at 255. The proposed penalty must be represented correctly, including zero-penalty equivalence.
- `RecvReply` allows the non-newer-sequence branch to reach cost/hop comparisons without an explicit equal-sequence guard. A targeted stale-RREP regression is needed before deciding whether to apply a separately recorded baseline correctness fix.
- The positive chain's printed source routing table also contained an entry for the source's own address through the relay. Its effect was not established by this test and should be reviewed separately.
- The upstream ETX fields are printed as `uint8_t` characters in some debug/table output. Preserve the raw output; use explicit numeric tracing when auditing costs.

These observations are recorded without modifying the routing baseline or claiming a performance improvement. Next: review the targeted baseline correctness conditions, then create a controlled alternative-path case for penalty and route-selection validation.
