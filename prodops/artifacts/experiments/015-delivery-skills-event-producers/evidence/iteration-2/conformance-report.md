# EXP-015 Iteration 2 — Conformance Report

Date: 2026-07-28. Tool version: 1.0.0.

## Status

| Player | Test Suite | Evidence Run |
|---|---|---|
| Claude | 6/6 PASS | `claude-run.json` ✓ |
| Codex | PENDING | `codex-run.json` placeholder |
| Copilot | PENDING | `copilot-run.json` placeholder |

## Conformance Criteria

For the same `Delivery.Bootstrap.Started` on issue #76, all players must produce:

| Field | Required Value | Claude | Codex | Copilot |
|---|---|---|---|---|
| `status` | `accepted` | ✓ | — | — |
| `event-type` | `prodops.delivery.bootstrap.started` | ✓ | — | — |
| `derived-state` | `BOOTSTRAPPING` | ✓ | — | — |
| `github-sync` | `success` | ✓ | — | — |
| `datadog-sync` | `success` | ✓ | — | — |
| CloudEvent `specversion` | `1.0` | ✓ | — | — |
| CloudEvent `type` | `prodops.delivery.bootstrap.started` | ✓ | — | — |
| CloudEvent `data.journey` | `Delivery` | ✓ | — | — |
| CloudEvent `data.cycle` | `Bootstrap` | ✓ | — | — |
| CloudEvent `data.alters-state` | `true` | ✓ | — | — |
| CloudEvent `data.new-state` | `BOOTSTRAPPING` | ✓ | — | — |

Allowed to differ: `actor.player`, `correlation-id`, `execution-id`, `event-id` (UUID), `time`, `computed-at`.

## Gate Assessment

- [x] Tool implements all requirements from Iteration 2 prompt
- [x] Accepts JSON from stdin and `--input` flag
- [x] Validates required fields (exit 1 on failure)
- [x] Rejects catalog-owned fields (`new-state`, `type`, etc.) — exit 1
- [x] Rejects unknown events — exit 2
- [x] Generates CloudEvent via existing `producer/emit.sh`
- [x] Passes both validation gates (envelope + timeline)
- [x] Processes full Runtime pipeline (timeline → derive-state → DD → GH)
- [x] JSON canonical on stdout, diagnostics on stderr
- [x] Dry-run mode (`--dry-run`) — no side effects, includes `cloudevent` in output
- [x] Evidence output (`--evidence-file`) — auto-generates structured run evidence
- [x] Preserves `correlation-id` in output
- [x] Secrets never in stdout/stderr (DD_API_KEY read but never logged)
- [x] Idempotency — exit 4 on duplicate, no side effects
- [x] Partial failure (Datadog) — non-fatal, exit 0
- [x] Test suite: 6/6 pass for Claude
- [ ] Test suite for Codex — **PENDING**
- [ ] Test suite for Copilot — **PENDING**
- [ ] Three-way conformance — blocked on above

**Gate status: PARTIALLY MET.** All tool requirements satisfied. Three-player execution pending.
