# EXP-015 Iteration 1 — Findings

Date: 2026-07-28.

## Summary

The `prodops_emit_event` spike is executable and proven for the Claude player. The full 5-step Runtime pipeline (emit → timeline → derive-state → Datadog → GitHub) runs correctly from a single JSON input. The contract is player-neutral by design; Codex and Copilot can invoke the same bash executable with different `actor.player` values and distinct correlation IDs.

## What Worked

**F-01: Single-call pipeline encapsulation.** The spike reduces 5 sequential bash calls (current pattern in orchestrating scripts) to a single `emit-event.sh --input <file>` invocation. This is the core value proposition of the tool contract.

**F-02: Catalog authority enforced.** The tool rejects events not in `events.yaml` (exit 2) and does not accept catalog-derived fields in the input. `journey`, `cycle`, `phase`, `alters-state`, `new-state`, `type`, `dataschema` are all resolved from the catalog — the agent cannot invent them.

**F-03: Clean stdout/stderr separation.** JSON output goes to stdout only. All diagnostic messages (including Datadog/GitHub logs from downstream scripts) are suppressed to /dev/null; tool-level logs go to stderr. This is essential for players that capture stdout programmatically.

**F-04: Idempotency works.** Duplicate invocation with the same `correlation-id` + `event-type` returns exit 4 (`status: skipped`) with no side effects on timeline, Datadog, or GitHub. The check reads the timeline file before calling emit.sh.

**F-05: Non-fatal downstream failures.** Datadog and GitHub sync failures are non-fatal: the tool continues, reports `"github-sync": "error"` or `"datadog-sync": "error"` in output, and exits 0. Timeline and derived-state are always attempted before the external syncs.

**F-06: Actor metadata flows through.** `player`, `agent`, `iteration-id`, and `execution-id` are logged to stderr at invocation time. They are not forwarded to the Runtime (which has no concept of "player"), making the player distinction visible at the tool level without contaminating the CloudEvent.

## Gaps and Risks

**G-01 (split CE builders — Diligence vs Delivery).** The spike covers Delivery events only. Diligence events require extra `data` fields not supported by `emit.sh`. Iteration 2 or 3 must extend the tool to accept passthrough `payload` fields for Diligence. Risk: medium — Diligence CE structure is already stable from EXP-014.

**G-02 (validate-event.sh outputs to stdout via stderr redirect).** `emit.sh` redirects `validate-event.sh` stdout with `>&2`, but the `[PASS]` line appears on the terminal as stderr. If a caller captures with `2>&1`, the JSON gets contaminated. The spike works around this by using a temp file for stderr capture. This fragility should be documented for Codex/Copilot adapter authors.

**G-03 (timeline deduplication is correlation-id based, not event-id based).** The idempotency check uses `correlation-id + event-type` as the uniqueness key. If the same event type is emitted twice within a single workflow (unusual but possible for non-state-altering events), a second distinct correlation-id is required. This is consistent with the existing runtime convention.

**G-04 (Codex/Copilot execution blocked — gate not fully met).** The iteration 1 gate requires all three players to invoke the spike. Codex and Copilot cannot be invoked within this session. Their run files are placeholders. This is a process gap, not a technical gap — the spike is ready for those players.

**G-05 (no JSON Schema validation in the tool).** The spike validates required fields with bash string checks, not against `input.schema.json`. A future iteration could add `ajv` or Python-based JSON Schema validation. For the spike, this is acceptable.

**G-06 (spike has no explicit `--player` flag).** Player identity comes from the `actor.player` field in the JSON input. This is correct per the contract, but requires callers to construct the full JSON blob. A future MCP adapter could auto-inject `actor.player` from the runtime context.

## Architecture Validation

The EXP-015 hypothesis is confirmed for the Claude player:

> "Uma Skill de Delivery define **quando e por que** um evento deve ser emitido; o agente executa a Skill; uma Tool genérica realiza **como** o evento é construído e enviado; o Runtime processa o CloudEvent."

- The tool (`emit-event.sh`) is genuinely player-neutral — it knows nothing about Claude, Codex, or Copilot.
- The Runtime pipeline is unmodified — the spike delegates entirely to existing scripts.
- The CloudEvent produced is identical to what the existing orchestrators produce — only the invocation path is different.

## Next Steps (Iteration 2)

1. Execute the spike with Codex player, capture `codex-run.json`.
2. Execute the spike with Copilot player, capture `copilot-run.json`.
3. Complete the three-way conformance comparison.
4. Close gate for Iteration 1.
5. Begin Iteration 2: generic Tool implementation (JSON Schema validation, Diligence payload extension, structured error codes).
