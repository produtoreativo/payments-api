# Runtime Timelines

Append-only CloudEvent records per issue and per plan. These files are the
authoritative source of truth for event history. Derived state is computed
from them — never the reverse.

## File naming and routing

| Pattern | Produced by | Contains |
|---|---|---|
| `<issue>.json` | `emit-event` tool (standard path) | All Delivery events + Diligence *signal* events from dispatcher |
| `diligence-<issue>.json` | Diligence Async SKILL when executed with rich context | Diligence-only events with extended payload (`delivery-derived-state`, `diligence-status`) |
| `plan-<iteration-id>.json` | `emit-event` when `work-item-id` is null | Plan-level events: `Plan.Bootstrap.Started/Completed`, `Plan.Validated` |

## Canonical source for each consumer

| What you need to know | Read from |
|---|---|
| Current Delivery state (oem-state) | `<issue>.json` → `derive-state.sh` |
| Current Diligence checkpoint (CAPTURED/ATTACHED/PROMOTED/CLOSED) | `diligence-<issue>.json` if exists, else `<issue>.json` → `derive-diligence-state.sh` |
| Plan-level Bootstrap/Validate state | `plan-<iteration-id>.json` |
| Restart history | `<issue>.json` (Restart events) + `restarts/<issue>/` |

## Two Diligence timeline sources — why both exist

`<issue>.json` contains Diligence *signal* events emitted automatically by the
dispatcher (`dispatch.sh`) when Delivery events are processed:
- `Diligence.Capture.Started/Completed` — triggered by Bootstrap.Completed
- `Diligence.Attach.Started/Completed` — triggered by Validate.Completed
- `Diligence.Promote.Started/Completed` — triggered by Promote.Completed

These signal events confirm that the Diligence cycle was triggered. They do
NOT confirm that the actual Diligence work (OBC update, Work Item creation)
was done. They use minimal payloads.

`diligence-<issue>.json` contains events produced when a Diligence agent
executes the full Diligence Async SKILL (Scan → Flag → Repair). These events:
- Have richer payloads (`obc-id`, `severity`, `delivery-derived-state`)
- Include `Divergence.Detected`, `Block.Declared/Resolved`, `Repair.Completed`
- Represent actual work done, not just signals

**Rule:** `diligence-<issue>.json` is the canonical audit source for Diligence.
`<issue>.json` is the canonical audit source for Delivery. When `derive-diligence-state.sh`
runs, it prefers `diligence-<issue>.json` and notes the source in `timeline-source` field.

## Append-only guarantee

No event is ever deleted or modified after being written. All files grow
monotonically. If a derived-state file is stale or wrong, regenerate it by
re-running `derive-state.sh` or `derive-diligence-state.sh` — do not edit
the timeline directly.
