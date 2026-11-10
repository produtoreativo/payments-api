---
name: obc
description: Creates or fixes a Local OBC following the prodops/templates/obcs/local-obc.en.md template. Use to create a new OBC from a decision already made, or to audit and fix an existing OBC (missing sections, non-standard Status, events that do not exist in the code, SLIs without a source). Verifies the result with scripts/check-obc.sh.
---

# OBC — create or fix a Local OBC

This skill produces or fixes a **Local OBC** (`prodops/artifacts/obcs/<slug>.md`) according to the template
[`prodops/templates/obcs/local-obc.en.md`](../../templates/obcs/local-obc.en.md) and the definition in
[`prodops/framework/obc.en.md`](../../framework/obc.en.md). The OBC is the source of truth for the contract; this
skill never generates parallel information that replaces it.

## When to use

| Situation | Mode |
|---|---|
| A canonical decision exists (completed experiment, Assessment decision, Operation signal, approved Business Intent) and no OBC exists yet | `create` |
| The OBC exists but does not follow the template, or was flagged as divergent | `fix` |
| I only want to know what is wrong, without changing anything | `check` |

Do not use this skill to:
- record a business decision that has not been made yet — stop and ask for the decision (see Guardrails);
- change BDD Features, code or the Reliability Plan — that belongs to Delivery/Assessment;
- handle a **global** OBC (`global-obc.en.md`), which has a different structure and lives in the portfolio repository.

## Required input

- `mode`: `create`, `fix` or `check`.
- `slug`: capability identifier (e.g. `chargeback-handling`). In `fix` and `check`, it is the existing file name.
- In `create`: the **canonical trigger** (path to the experiment, Assessment decision, Business Intent or Issue).

## Mandatory pre-reading

1. [`prodops/templates/obcs/local-obc.en.md`](../../templates/obcs/local-obc.en.md) — structure and rules (the `<!-- -->` comments are instructions).
2. [`prodops/framework/obc.en.md`](../../framework/obc.en.md) — states, lifecycle, traceability, location.
3. In `fix`/`check`: the whole OBC. In `create`: the Business Intent, the Business Signal and the BDD (if it exists).

## Where the OBC lives

| State | Location |
|---|---|
| Draft / Refining inside an Upstream experiment | `prodops/artifacts/experiments/<NNN-slug>/obcs/<slug>.md` |
| Committed or later | `prodops/artifacts/obcs/<slug>.md` |

Do not move an experiment OBC to `artifacts/obcs/` here — that is the `upstream/move-to-downstream` step.

## Sources of truth (where each section comes from)

Never fill a section by assumption. Each one has a source:

| OBC section | Source |
|---|---|
| Metadata, Status | Iteration Plan (`prodops/artifacts/plans/iteration-plan.md`), `iterations/<vX.Y.Z>/plan.md` |
| Origin | `prodops/artifacts/business-signals/`, `business-intents/`, tracking list |
| Business Outcome, Scope, Business Rules | Business Intent, BDD Feature, originating decision |
| Acceptance Criteria | scenarios in `prodops/artifacts/bdd/<slug>.feature` (each criterion points to ≥ 1 scenario) |
| Enterprise Context | Product Deck and Service Deck (`prodops/artifacts/product/context/`) |
| **Observable Events** | **the code** — see the naming rule below |
| APIs, Response Contract | controllers and DTOs in `api/src/modules/**` |
| Initial SLIs | existing OBC, Reliability Plan, metrics in `api/src/observability/metrics.ts` and `event-storming/plan.json` |
| Risks | `prodops/artifacts/risks/risks.md`, Reliability Plan |
| Dependencies | code (modules and providers), `prodops/artifacts/architecture/overview.md` |
| Decisions | the experiment, trail or Issue that originated the change |

## Event naming rule (the most important one)

Business events follow the **`payments.<aggregate>.<fact>`** convention (lowercase, snake_case, English) — rules, catalog and eliminated duplicates in [`prodops/artifacts/architecture/domain-events.en.md`](../../artifacts/architecture/domain-events.en.md). The single source of names in the code is `api/src/events/payments-events.ts`.

The name in the `Event` column must be **identical** to the event actually emitted in the code. Observability keys (`event_key`) and external webhook types do not follow this convention. To find out what exists:

```bash
# domain events (EventEmitter)
grep -rn "\.emit(" api/src --include='*.ts' | grep -v '\.spec\.'
# Portuguese observability keys (emitObservable) and English event_key
grep -rhoE "'pagamento(\.[a-z_]+)+'" api/src | sort -u
grep -rn "event_key:" api/src | grep -v '\.spec\.'
# events already mapped to the dashboard
jq -r '.customEvents[].title' prodops/artifacts/event-storming/plan.json | sort -u
```

For each OBC event, classify the **Status** column:

| Status | When |
|---|---|
| `Emitted` | the exact name exists in the code |
| `Planned` | the contract promises the event, but the code does not emit it yet |

**Never** rename an OBC event "to look like" the code's without confirming it is the same behavior, and **never** invent a name. If the promised event does not exist, mark it `Planned` and record the divergence in the report — choosing between implementing the event or removing the promise is the OBC owner's decision, not the skill's. An `Operational` OBC cannot have `Planned` events.

## Flow — `create` mode

1. **Confirm the canonical trigger.** If there is no completed experiment, Assessment decision, Operation signal or approved Business Intent, **stop** and ask the user. Do not create an OBC without a trigger.
2. **Check for duplicates**: `ls prodops/artifacts/obcs prodops/artifacts/experiments/*/obcs` — if an OBC for the capability already exists, switch to `fix`.
3. **Copy the template** to the location for the state (table above), renaming it to `<slug>.md`.
4. **Fill each section** from its source. Anything without a documented source becomes `[to be determined]` — never an invented value (SLO, target, stakeholder name, date).
5. **Initial state**: `Draft` (or `Refining`). Moving to `Committed` requires Owner approval (PM + Tech Lead) and all "required for Committed" sections complete — the skill does **not** promote on its own.
6. **Remove** optional sections that do not apply (APIs, Response Contract, "In executive language") and the `<!-- -->` comments.
7. **Run the verification** (below) and fix until there are no failures that depend only on editing.
8. **Create the PT/EN counterpart** (`<slug>.en.md` or `<slug>.md`) only if the project keeps PT/EN pairs for OBCs; otherwise note in the report that it was not generated.

## Flow — `fix` mode

1. **Audit**: `scripts/check-obc.sh prodops/artifacts/obcs/<slug>.md` and keep the output as the "before" report.
2. **Map the existing content to the template**, without losing information:

   | If the OBC has… | Move to… |
   |---|---|
   | `**Status:** x`, `DS-ID`, `Iteration`, `Last updated` at the top | `## Metadata` and `## Status` |
   | "Trigger", "Pre-conditions", "Observable Behavior Contract" | `## Business Outcome`, `## Business Rules`, `## Scope` |
   | "Premortem" | `## Risks` |
   | "Out of scope" / "Scope" | `## Scope` |
   | long text after the state in `## Status` ("Downstream. Status `Entered` in…") | a `**Tracked in:**` line; the state stays alone |
   | events table without Status | add the column and classify each row |
   | SLI table without Source | add the `Source` column |

3. **Fix the Status**: exactly one of `Draft | Refining | Committed | In Delivery | Operational | Archived`. Choose based on what is **proven** (Iteration Plan, merged PR, release trail) — do not leave a delivered OBC as `Committed`/"Entered" if there is evidence it is in production, but confirm with the user before marking `Operational`.
4. **Reconcile the events** with the code (naming rule) and classify the Status.
5. **Fill in what is missing** with `[to be determined]` when there is no source (Origin, Enterprise Context, Risks, Dependencies, Decisions).
6. **Preserve the language and style** of the existing OBC; keep the `.en.md`/PT pair in sync if one exists (or warn that it became stale).
7. **Record the change** in `## Decisions` (date, what was fixed, why, source).
8. **Run the verification** and produce the "after" report.

## Flow — `check` mode

Only runs the verification and reports. It edits no file.

## Verification

```bash
prodops/skills/obc/scripts/check-obc.sh prodops/artifacts/obcs/<slug>.md
# platform/framework OBCs, whose events are not emitted by api/src:
prodops/skills/obc/scripts/check-obc.sh prodops/artifacts/obcs/<slug>.md --skip-code-events
```

The script checks: required sections, a single valid state, traceable Origin, no `<...>` placeholders (from Committed on), the Status column, event names against the code, the Source column in SLIs, an existing BDD, and the `prodops/…` paths cited. Exit 0 = no failures.

Failures that **cannot** be solved just by editing the OBC (e.g. a promised event the code does not emit, a missing BDD) do not block the skill: they go into the report as **decision items**.

## Expected output (report)

```
OBC: <slug>   mode: <create|fix|check>
Before: <N failures, M warnings>      After: <N failures, M warnings>
Changed: <sections created/moved/fixed>
[to be determined]: <fields without a source, for the owner to fill in>
Decision items:
  - <event X promised and not emitted: implement it or remove the promise?>
  - <Operational state to confirm with evidence Y>
```

## Guardrails

- **Do not invent** business decisions, SLOs, targets, stakeholders, dates or names. No source → `[to be determined]`.
- **Do not promote** the state to `Committed`/`Operational` without evidence and Owner confirmation.
- **Do not change code, tests, BDD Features or the Reliability Plan.** If an event needs to start being emitted, that is a Delivery item, not this skill's.
- **Do not delete content** from the existing OBC: whatever does not fit the template goes to the closest section or to `## Decisions`.
- **Do not edit the template** (`templates/obcs/*.md`) from this skill.
- **Commit** only when the caller authorizes it (e.g. `diligence/capture`, `upstream/move-to-downstream`). Message: `docs(obc): <create|fix> <slug>`.
- If creating/fixing requires a product decision that is not documented, **stop and surface it as a blocker**.

## Integration with other skills

- `diligence/capture` — when creating a new OBC, it should call this skill in `create` mode instead of copying the template by hand.
- `upstream/move-to-downstream` — before promoting an OBC to `artifacts/obcs/`, run `check` and require exit 0.
- `downstream` — the "OBC committed" prerequisite can be validated with `check`.

This skill does not emit Delivery events (`prodops_emit_event`): it is not a CI Sync/Async phase.
