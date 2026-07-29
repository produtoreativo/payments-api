# EXP-015 Iteration 1 — Conformance Report

Date: 2026-07-28. Spike version: 1.0.0-spike.

## Status

| Player | Run Status | Evidence |
|---|---|---|
| Claude | COMPLETE | `claude-run.json` |
| Codex | PENDING | `codex-run.json` (placeholder) |
| Copilot | PENDING | `copilot-run.json` (placeholder) |

## Claude Run — Conformance Check

Event: `Delivery.Bootstrap.Started` / Issue: #76

### CloudEvent Envelope

| Field | Value | Conformant? |
|---|---|---|
| `specversion` | `1.0` | ✓ |
| `source` | `https://github.com/produtoreativo/payments-api` | ✓ |
| `type` | `prodops.delivery.bootstrap.started` | ✓ |
| `subject` | `76` | ✓ |
| `datacontenttype` | `application/json` | ✓ |
| `dataschema` | catalog URI | ✓ |

### CloudEvent Data

| Field | Value | Conformant? |
|---|---|---|
| `issue` | `76` | ✓ |
| `journey` | `Delivery` | ✓ |
| `cycle` | `Bootstrap` | ✓ |
| `phase` | `Started` | ✓ |
| `alters-state` | `true` | ✓ |
| `new-state` | `BOOTSTRAPPING` | ✓ |
| `runtime-correlation-id` | `9c81a3c7-5d1d-4faf-b386-5b41ff7c7f41` | ✓ |
| `runtime-version` | `0.3.0` | ✓ |

### Pipeline

| Step | Result |
|---|---|
| emit | success |
| timeline | success |
| derive-state | success |
| datadog | success (HTTP 202) |
| github | success |

### Derived State

| Field | Value | Expected |
|---|---|---|
| `state` | `BOOTSTRAPPING` | `BOOTSTRAPPING` ✓ |
| `last-event-type` | `prodops.delivery.bootstrap.started` | `prodops.delivery.bootstrap.started` ✓ |

### Idempotency

| Re-run result | Expected |
|---|---|
| exit code 4 | 4 ✓ |
| status: skipped | skipped ✓ |
| github-sync: skipped | skipped ✓ |
| datadog-sync: skipped | skipped ✓ |

### Tool Output Contract

All required fields present. `status: accepted`. No errors. Output is pure JSON on stdout.

## Cross-Player Comparison Template

To be completed after Codex and Copilot runs.

| Field | Claude | Codex | Copilot | Conformant? |
|---|---|---|---|---|
| `event-type` | `prodops.delivery.bootstrap.started` | — | — | — |
| `derived-state` | `BOOTSTRAPPING` | — | — | — |
| CloudEvent `type` | `prodops.delivery.bootstrap.started` | — | — | — |
| CloudEvent `data.journey` | `Delivery` | — | — | — |
| CloudEvent `data.cycle` | `Bootstrap` | — | — | — |
| CloudEvent `data.alters-state` | `true` | — | — | — |
| CloudEvent `data.new-state` | `BOOTSTRAPPING` | — | — | — |
| `github-sync` | `success` | — | — | — |
| `datadog-sync` | `success` | — | — | — |
| exit code | `0` | — | — | — |
| `actor.player` | `claude` | `codex` | `copilot` | ✓ (allowed to differ) |
| `correlation-id` | distinct | distinct | distinct | ✓ (allowed to differ) |
| `event-id` (UUID) | distinct | distinct | distinct | ✓ (allowed to differ) |

## Gate Assessment

- [x] Spike is executable (bash CLI, no MCP)
- [x] Input/output schemas defined
- [x] Claude executed `Delivery.Bootstrap.Started` with real pipeline (DD + GitHub confirmed)
- [x] Idempotency verified (exit 4, no side effects on re-run)
- [ ] Codex player execution — **PENDING**
- [ ] Copilot player execution — **PENDING**
- [ ] Three-way conformance comparison — blocked on above

**Gate status: PARTIALLY MET.** Claude run is real and complete. Codex and Copilot require independent execution of the spike following the instructions in `contract.md`.
