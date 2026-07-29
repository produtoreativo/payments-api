# EXP-015 Iteration 1 — Current Event Emission Inventory

Surveyed: 2026-07-28. Branch: `experiment/015-delivery-skills-event-producers`.

## Summary

All ProdOps CloudEvent emission occurs in bash scripts under `prodops/runtime/`. No HTTP endpoint exists — the runtime is entirely file-based and CLI-driven. No Skills emit events directly; they delegate to orchestrating scripts. No `prodops_emit_event` tool existed before this iteration.

## Emission Points

| File | Mechanism | Events Emitted |
|---|---|---|
| `prodops/runtime/producer/emit.sh` | Canonical producer. `jq -n` constructs CloudEvent; validates with `validate-event.sh`; outputs to stdout. Called by all scripts via `--issue`, `--event`, `--correlation-id` flags. | Any catalog event (14 Delivery + 1 Shared) |
| `prodops/runtime/scripts/bootstrap-runtime.sh` | Calls `emit.sh` once | `Delivery.Bootstrap.Started` |
| `prodops/runtime/scripts/bootstrap-happy-path.sh` | Loop calling `emit.sh` for 15 events in sequence | All 15 Delivery events |
| `prodops/runtime/scripts/bootstrap-multi-feature.sh` | Loop per-feature (issues 76/77/78) calling `emit.sh` | Delivery events × 3 features |
| `prodops/runtime/scripts/bootstrap-non-uniform.sh` | Local `emit_event()` wrapper calling `emit.sh` | Non-uniform Delivery events per feature |
| `prodops/runtime/scripts/bootstrap-diligence.sh` | `emit_diligence_event()` — constructs CE **directly via `jq -n`** (bypasses `emit.sh`) to support extended payload fields | All Diligence catalog events |
| `prodops/runtime/scripts/demo-delivery-with-diligence.sh` | `emit_delivery_event()` wrapper calling `emit.sh`; `emit_diligence_event()` building CE directly | Delivery events (issues 76/77/78) + Diligence events |

## Pipeline Steps (per emission)

Each emission orchestrator is responsible for calling downstream steps in sequence:

```
1. emit.sh            → CloudEvent JSON (stdout)
2. timeline/append.sh → persists to prodops/artifacts/runtime/timelines/<issue>.json
3. consumer/derive-state.sh → reads timeline, writes derived-state-<issue>.json
4. datadog/send.sh    → posts runtime.event.received metric to Datadog v2 API
5. github/sync.sh     → updates oem-state + oem-last-event in GitHub Project #25
```

## Structural Forks (Gaps)

### G-1: Split CE builders (Delivery vs Diligence)

`emit.sh` handles Delivery events with a fixed payload shape. Diligence events are built inline with `jq -n` in `bootstrap-diligence.sh` and `demo-delivery-with-diligence.sh` because they require extra cross-reference fields (`diligence-correlation-id`, `delivery-correlation-id`, `delivery-derived-state`, etc.) that `emit.sh` does not accept.

**Impact on spike**: Iteration 1 spike (`emit-event.sh`) covers Delivery events only. Diligence support requires extending the `payload` passthrough.

### G-2: Caller-owned pipeline orchestration

No single executable runs the full 5-step pipeline. Each orchestrating script assembles the pipeline manually. Duplication is high.

**Impact on spike**: The `emit-event.sh` spike is the first tool to encapsulate all 5 steps behind a single interface.

### G-3: No player-neutral abstraction

All scripts hardcode issue numbers (76/77/78) and read config directly from `runtime.yaml`. There is no concept of "player" or "actor" in the current system.

**Impact on spike**: The `work-item-id` input field decouples the tool from hardcoded issue lists.

### G-4: No deduplication in timeline

`timeline/append.sh` is append-only with no deduplication check. Re-running with the same arguments creates duplicate CloudEvents in the timeline.

**Impact on spike**: The `emit-event.sh` spike adds a pre-emit idempotency check (correlation-id + event-type) as minimum protection.

### G-5: `validate-event.sh` validates envelope only

The validator checks required CE fields and JSON structure but does not validate `data` content against the `dataschema` URI (which is a placeholder, not a live registry).

### G-6: No existing tool registry

No MCP tool definition, no `.claude/tools/`, no `prodops_emit_event` anywhere before this iteration. The spike creates the first executable that matches the target tool contract.

## Skills Inventory

No Delivery Skill emits events directly. The only skill that triggers CE emission is `prodops/skills/delivery/SKILL.md`, which delegates to `demo-delivery-with-diligence.sh`. All other skills (bootstrap, hack, sync, finish, ship, validate, promote) orchestrate git/code/artifact operations without emitting any CloudEvents.

**This is the primary architectural gap EXP-015 addresses**: Skills should instruct agents to call `prodops_emit_event` at defined lifecycle points, not delegate to monolithic orchestration scripts.
