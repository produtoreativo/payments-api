---
name: sync/align
description: Align ProdOps artifacts with the current implementation. Use when BDD Features, Event Storming, architecture diagrams, or the Release Trail are stale relative to what was implemented in Hack.
---

# SYNC → ALIGN

Execute only the artifact alignment step of the Sync flow.

**Responsibility:** guarantee **ProdOps artifact integrity** — review the branch diff and update only the canonical artifacts that are inconsistent with what was implemented. This is a **traceability** step, not a git step (that is `rebase`) and not a product step (upstream decisions are preserved, not rewritten).

## Inputs

- Current diff (`git diff main...HEAD`) — what changed in this branch
- `prodops/artifacts/business/bdd/` — BDD Features
- `prodops/journeys/assessment/event-storming/plan.json` — Event Storming
- `prodops/artifacts/product/architecture/overview.md` — architecture diagram
- `prodops/artifacts/governance/trails/sessions/` — active session trail
- Relevant OBC in `prodops/artifacts/business/obcs/`

## Action

### 1. Identify what changed

Review the branch diff and list:

- behaviors added, changed, or removed
- domain events added, renamed, or removed
- structural changes (new module, route, external dependency, table, event topic)
- contracts changed (OpenAPI, AsyncAPI, BDD Feature)

### 2. Trace the source of truth

For each item identified, locate the canonical artifact in `prodops/`. Use this mapping as the source of truth — when in doubt, the artifact path wins over heuristics from module filenames:

| Change in the code | Canonical artifact |
|---|---|
| New or altered behavior | BDD Feature in `prodops/artifacts/business/bdd/` |
| Domain event added, renamed, or removed | `prodops/journeys/assessment/event-storming/plan.json` |
| New module, route, external dependency, or table | `prodops/artifacts/product/architecture/overview.md` |
| OBC satisfied or altered | `prodops/artifacts/business/obcs/<slug>.md` |

When a change does not fit any row of the table, that is a sign of a missing canonical artifact — record it as a gap (see Guardrails) rather than inventing a new artifact.

### 3. Update only stale artifacts

Update each artifact that is inconsistent with the implementation:

- **BDD Feature** — reflect the behavior as implemented, not as originally speculated.
- **Event Storming** — add/rename/remove events in `customEvents`; update flow bands; add `sloSuggestions` if on critical path; update `assumptions[last]` with today's date.
- **Architecture** — edit the Mermaid diagram; add a row to the History table.

Do not touch artifacts that are already consistent. Do not rewrite product decisions made upstream of this branch.

### 4. Validate links and Markdown

Check that all internal links in updated files resolve. Verify changed Markdown renders correctly (headings, tables, code blocks).

### 5. Record in the Release Trail

Append an entry to the active session trail (`prodops/artifacts/governance/trails/sessions/YYYY-MM-DD-<session-id>.md`) when the alignment is meaningful (behavior change, structural update, or contract correction). Include:

- what artifact was updated
- why it was stale (what the implementation introduced)
- date

Preserve all historical entries — append only, never replace.

## Post-conditions

**Completion criterion — ProdOps artifact integrity:** complete when **all** of the following are true:

- All ProdOps artifacts reflect the current implementation.
- No stale BDD Features, Event Storming entries, or architecture descriptions remain for this branch's changes.
- Release Trail updated when the alignment was meaningful.
- No product decisions were rewritten.

## Guardrails

- Do not rewrite product decisions while doing consistency work.
- Do not duplicate Product Deck, Service Deck, OBC, or Reliability Plan content — prefer references to canonical paths.
- Do not update artifacts that are unrelated to this branch's changes.
- Preserve historical Release Trail entries — append, never replace.
- If an artifact is missing entirely (e.g. no BDD Feature exists for the behavior), record it as a gap rather than inventing content.

## Out of scope — not the responsibility of `align`

- `align` **does not** resolve git conflicts or integrate the base — that is `rebase`.
- `align` **does not** validate quality gates of code (lint, tests, coverage) — that is Hack (Yellow Bar) and Finish.
- `align` **does not** open a pull request — that is Finish.
- `align` **does not** rewrite product decisions made upstream. If the diff diverges from a BDD Feature or OBC in a way that changes intent (not just detail), record the divergence in the Release Trail and surface it to Finish — do not silently re-specify the product here.
