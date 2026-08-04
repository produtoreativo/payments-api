# Release Trail — v0.12.0

## DS-58 — RT Iteration Lifecycle Automation

**Date:** 2026-08-04
**Actor:** claude
**Branch:** feat/147-rt-iteration-lifecycle-automation
**Correlation-ID:** 104c2034-4284-4907-b498-95930dc03713

---

### RED — Gap Evidence

Confirmed that `prodops/skills/downstream/SKILL.md` (before this TDD session) was missing:

1. **Assignee filling in Plan Bootstrap:** Etapa 2 (tracking issue creation) used `gh issue create` without `--assignee`. Gate 5 (feature issue creation when absent) also had no `--assignee` parameter. No instruction to capture `CE_LOGIN` via `gh api user --jq '.login'`.

2. **Auto-close of tracking issue in Iteration Closure:** The "Fechamento de iteração" section listed 3 actions (update plan.md, update iteration-plan.md, commit) with no step to comment on or close the tracking issue.

3. **Idempotency guard:** No check to skip auto-close if tracking issue already closed.

4. **Pending issues guard:** No warning or block when not all issues reached Promote.Completed before Iteration Closure is invoked.

---

### GREEN — Changes Applied

**File changed:** `prodops/skills/downstream/SKILL.md`

1. **Etapa 2 — Issue de acompanhamento:** added capture of `CE_LOGIN=$(gh api user --jq '.login')` before `gh issue create`, added `--assignee "$CE_LOGIN"` to the create command. Added non-fatal fallback: if GitHub rejects the assignee, create without it and log a warning — Plan Bootstrap continues without interruption.

2. **Gate 5 — criação de Issue quando ausente:** added step to capture `CE_LOGIN` (or reuse from Plan Bootstrap), added `--assignee "$CE_LOGIN"` to `gh issue create`. Same non-fatal fallback.

3. **Iteration Closure — Gatilho:** added guard block — if any issue has not reached Promote.Completed, Iteration Closure logs a warning with the list of pending issues and does NOT close the tracking issue.

4. **Iteration Closure — Ação 0 (auto-close):** added new step before the existing plan.md update:
   - Resolve tracking issue number from `plan-bootstrap.json` field `plan-issue`
   - Check `gh issue view <plan-issue> --json state --jq '.state'`
   - If CLOSED: skip silently (idempotent), log info, continue
   - If OPEN: post closing comment (with DS-IDs, merged PRs, date) then `gh issue close <plan-issue>`

All 5 BDD scenarios are covered:
- Scenario 1 (assignee in each feature issue): covered by Etapa 2 + Gate 5 changes
- Scenario 2 (auto-close after all promotes): covered by Ação 0 in closure
- Scenario 3 (no auto-close with pending issues): covered by Gatilho guard block
- Scenario 4 (assignee failure non-blocking): covered by non-fatal fallback in Etapa 2 and Gate 5
- Scenario 5 (idempotent auto-close): covered by CLOSED state check in Ação 0

---

### YELLOW — Gate Results

| Gate | Command | Result |
|---|---|---|
| lint | `cd api && npm run lint` | EXIT 0 (30 warnings, 0 errors — pre-existing, no api/src changes) |
| no_mocks | `grep jest.fn( api/test` | 0 hits |
| emit-event tests | `bash prodops/runtime/tools/emit-event/tests/run-all.sh` | 7/7 PASS |

**Security:** diff contains only instruction text in SKILL.md — no secrets, tokens, PII, or credentials.

**Quality:** no jest.fn(), no .overrideProvider(), no .only — no api/src changes made.

**Event Storming:** no new domain events added — no update required.

**Architecture:** no structural change (new module, route, table, external dependency) — no update required.
