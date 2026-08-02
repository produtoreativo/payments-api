---
name: downstream
description: Orchestrates the governed ProdOps delivery flow. Without arguments, reads the Iteration Plan and executes Entrou items in priority order. With a Downstream ID, executes only that item.
---

# DOWNSTREAM

Downstream is the commitment mode of the ProdOps Framework. Every delivery must pass through readiness gates and the CI Sync and CI Async cycles. The orchestrator never bypasses prerequisites or invents artifacts.

## Downstream ID

Each Downstream item has a **Downstream ID** — the stable identifier of the feature across iterations:

```
DS-<feature-slug-number>
```

The DS-ID identifies the **feature** (stable), not the GitHub Issue (ephemeral — changes each iteration). The mapping `DS-ID → issue` is declared in the active iteration's `plan.md`. The agent resolves `DS-39 → issue #106` by reading the mapping table from the plan, never inferring from the DS-ID number.

## Skill resolution

All skill paths are resolved from the index at `prodops/runtime/runtime.yaml`, section `skills:`. Read that file once at the start of execution — **never use `find` or `ls` to locate skill files**. Example:

```yaml
# prodops/runtime/runtime.yaml
skills:
  bootstrap: prodops/skills/bootstrap/SKILL.md
  hack:      prodops/skills/hack/SKILL.md
  # ...
```

To invoke a skill: read `runtime.yaml` → extract the path → read the file directly using the canonical path.

## Iteration Directory

At the start of any execution, the agent resolves the **ITERATION_DIR** from the `iteration-id` declared in the active plan:

```
ITERATION_DIR = prodops/artifacts/iterations/<iteration-id>/
```

All runtime artifacts for this iteration live exclusively inside this directory:
- Timelines: `ITERATION_DIR/runtime/timelines/<issue>.json`
- Plan Bootstrap: `ITERATION_DIR/runtime/plan-bootstrap.json`
- Plan Validate: `ITERATION_DIR/runtime/plan-validate.json`
- Context capsules: `ITERATION_DIR/cards/<slug>/context.md`
- Session trails: `ITERATION_DIR/trails/`

The `--iteration-id` is propagated to all calls of `emit-event`, `append.sh`, `derive-state.sh`, and `derive-diligence-state.sh`. No runtime artifact is written outside the ITERATION_DIR of the current iteration.

## Commands

| Command | Scope |
|---|---|
| `/downstream` | Reads the Iteration Plan, lists `Entrou` items in priority order and executes CI Sync one by one |
| `/downstream <DS-ID>` | Executes CI Sync only for the item with that Downstream ID (e.g. `/downstream DS-40`) |
| `/downstream ci-sync <DS-ID or capability>` | Readiness → Bootstrap → Hack → Sync → Finish for the given item |
| `/downstream ci-async <DS-ID or capability>` | Verify CI Sync evidence → Ship → Validate → Promote |
| `/downstream full <DS-ID or capability>` | Full CI Sync → Full CI Async |
| `/downstream recheck` | Delete `readiness-gate.json` and run full gate check — bypass cache |
| `/readiness <capability>` | Verify prerequisites and generate context capsule — does not start implementation |

Use `/readiness` when you want to verify gates and prepare the context capsule without starting implementation. Use `/downstream <DS-ID>` when ready to begin Bootstrap and Hack for a specific item.

## No-argument mode — `/downstream`

When invoked without arguments:

1. Read `prodops/artifacts/plans/iteration-plan.md` → identify the active version (e.g. `v0.6.0`).
2. Read `prodops/artifacts/iterations/<version>/plan.md` → resolve `ITERATION_ID` and collect all items with status `Entrou` from the scope table, using the DS-ID → Issue mapping table to obtain the correct issue numbers.
3. **Readiness Cache Check** — check `ITERATION_DIR/runtime/readiness-gate.json` **before any gate check or Plan Bootstrap**:
   a. If the file does not exist: continue normally to step 4.
   b. If `"result": "ready"`: continue normally to step 4.
   c. If `"result": "blocked"`:
      - For each capability in `capabilities`, check if any `missing-artifacts` now exist on disk:
        ```bash
        test -f <artifact-path>
        ```
      - If **no** new artifact appeared: display the cached result below and **stop immediately** — save tokens.
        ```
        ⛔ Readiness blocked (cached result — <checked-at>)
        Failing gates: <capability list and gates>
        Missing artifacts: <path list>
        Next step: <next-action>
        Force recheck: /downstream recheck
        ```
      - If **any** missing artifact now exists: ignore the cache, delete the file, and continue to step 4 with a full gate check.

4. Present the execution queue in the order they appear in the Iteration Plan (PM/PO priority order):

```
Downstream Queue — Active Iteration Plan
─────────────────────────────────────────
1. DS-40  create-invoice-boleto
...
```

6. **Plan Bootstrap** — run once before the issue loop:
   a. Check if `ITERATION_DIR/runtime/plan-bootstrap.json` already exists with `"status": "completed"`. If so, skip to step 7 (environment already ready).
   b. **Project cleanup** — remove the issues from the last completed iteration before adding the new ones:
      ```bash
      # 1. Find the last iteration with "Concluido" status in the history
      LAST_DONE=$(grep -oP '\[v[\d.]+\]' prodops/artifacts/plans/iteration-plan.md \
        | grep -oP 'v[\d.]+' | while read v; do
            grep -q "Conclu" "prodops/artifacts/iterations/$v/plan.md" 2>/dev/null && echo "$v"
          done | tail -1)

      # 2. Extract issue numbers from the DS-ID → Issue mapping table of that iteration
      CLOSED_ISSUES=$(grep -oP '#\d+' "prodops/artifacts/iterations/${LAST_DONE}/plan.md" \
        | grep -oP '\d+' | sort -u)

      # 3. For each issue, locate and remove the item from the Project
      for ISSUE_NUM in $CLOSED_ISSUES; do
        ITEM_ID=$(gh project item-list 25 --owner produtoreativo --format json \
          | jq -r --argjson n "$ISSUE_NUM" '.items[] | select(.content.number == $n) | .id')
        [[ -n "$ITEM_ID" ]] && gh project item-delete 25 --owner produtoreativo --id "$ITEM_ID"
      done
      ```
      - Do not block if the project is empty, if no items are found, or if `LAST_DONE` is empty.
      - Do not remove open issues from ongoing iterations.
   c. Emit `Delivery.Plan.Bootstrap.Started` with `subject: <iteration-id>`, `work-item-id: null` and `--iteration-id <iteration-id>`.
   d. Execute Bootstrap work: install dependencies, verify runtimes and local services, confirm environment variables, run the manifest smoke gate.
   e. If any step fails: report the blocker and **stop the entire queue** — do not start any issue.
   f. Emit `Delivery.Plan.Bootstrap.Completed` with `subject: <iteration-id>` and `--iteration-id <iteration-id>`.
   g. Write `ITERATION_DIR/runtime/plan-bootstrap.json`:
   ```json
   {
     "iteration-id": "<iteration-id>",
     "status": "completed",
     "correlation-id": "<uuid-generated-at-started>",
     "completed-at": "<iso8601-timestamp>",
     "issues": ["<issue-1>", "<issue-2>", "..."]
   }
   ```
   h. Commit the file to the repository before starting the loop.

7. For each item in the queue, in order, without requesting confirmation between them:
   a. Run `/readiness <capability>` — if it fails: write `readiness-gate.json` with `"result": "blocked"` (see **Readiness Cache** section) and **stop the entire queue**.
   b. Execute CI Sync: Bootstrap (fast path via plan-bootstrap) → Hack → Sync → Finish.
   c. Report evidence for the completed item and automatically advance to the next.

Stop only when: (1) a readiness check fails, (2) a quality gate does not pass, (3) the queue is exhausted.

## Downstream ID mode — `/downstream DS-<n>`

When invoked with a Downstream ID:

1. Resolve the capability from the issue number (`DS-40` → issue #40 → `create-invoice-boleto`).
2. Verify the item appears in the Iteration Plan with status `Entrou`.
3. Run `/readiness <capability>`.
4. If Ready: confirm with the user and execute CI Sync.

## Readiness gate

Before executing either cycle, evaluate the capability against all current Downstream prerequisites:

1. OBC committed in `prodops/artifacts/obcs/`.
2. BDD Feature committed in `prodops/artifacts/bdd/`.
3. Risks documented in `prodops/artifacts/risks/risks.md`.
4. Item in the Iteration Plan with status `Entrou`.
5. GitHub Issue existing and mapped in the `Issue` column of the active iteration's `plan.md`.

Treat commitment as **Downstream Declared** while any prerequisite is missing. Mark **Downstream Ready** only after all five gates pass. **Delivery Started** begins only when Bootstrap starts.

Reliability Plan (`prodops/artifacts/plans/reliability/<capability>.md`) is optional. If it exists, include `reliability-path` in the capsule and reference SLOs during Validate and Promote. Its absence does not block the flow.

## Readiness Cache

To avoid token consumption on repeated invocations with blocked gates, the gate check result is persisted in `ITERATION_DIR/runtime/readiness-gate.json`.

### Format

```json
{
  "iteration-id": "<iteration-id>",
  "checked-at": "<iso8601-timestamp>",
  "result": "blocked",
  "capabilities": {
    "<DS-ID>": {
      "slug": "<capability-slug>",
      "gates": {
        "obc": false,
        "bdd": false,
        "risks": false,
        "iteration-plan": true,
        "github-issue": true
      },
      "missing-artifacts": [
        "prodops/artifacts/obcs/<slug>.md",
        "prodops/artifacts/bdd/<slug>.feature"
      ]
    }
  },
  "next-action": "Create artifacts via /upstream before re-invoking /downstream"
}
```

### Rules

1. **Write on failure**: when any readiness gate fails, write the file with `"result": "blocked"` before stopping.
2. **Blocked fast path**: if the file exists with `"result": "blocked"` and **no** `missing-artifact` has appeared on disk, stop immediately without re-running the gate check.
3. **Auto-invalidation**: if any artifact listed in `missing-artifacts` now exists (`test -f <path>`), delete the file and run a full gate check.
4. **Cleanup after pass**: when all gates pass, write `"result": "ready"` (overwrites the previous blocked entry).
5. **Forced recheck**: `/downstream recheck` deletes the file and runs the full gate check regardless of current state.
6. **Commit**: after writing or updating the file, include it in the next runtime artifact commit for the iteration.

### Gate 5 — Issue creation when absent

If the item is in the Iteration Plan with status `Entrou` but without a mapped Issue:

1. Create the Issue via `gh issue create`:
   - **Title:** `[DS-<n>]: <capability-description>`
   - **Body:** include DS-ID, iteration-id, OBC path, BDD path and link to plan.md
   - **Labels:** `journey:delivery`, `artifact-type:local-obc`, `operation:implement`
2. Associate with Project 25:
   ```bash
   gh issue edit <number> --add-project "ProdOps Runtime"
   ```
3. Update the `Issue` column in `plan.md` with the created number.
4. Commit `plan.md` before continuing.

Never start Bootstrap without a mapped Issue — the `work-item-id` in the capsule and events depends on this number.

### Automatic phase registration — Issue Trail

After each completed phase (Readiness, Bootstrap, Hack, Sync, Finish, Ship, Validate, Promote), post a comment on the Issue with the phase result:

```bash
gh issue comment <work-item-id> --body "<phase summary>"
```

Comment format:

```
## <Phase> — <YYYY-MM-DD HH:MM UTC>

**Status:** <Completed | Blocked | Failed>

<summary in up to 5 lines: what was done, key evidence, next step>

---
*correlation-id: <uuid> · iteration: <iteration-id> · actor: <player>*
```

The comment is mandatory even in case of failure or blocker — the blocker comment must describe the reason and the action required to resolve it. This ensures full traceability of the work directly on the Issue, accessible to any agent or human without needing to read timelines or trails.

When all prerequisites exist:

1. Emit `Delivery.Plan.Entered` for the issue, generating the `correlation-id` for the entire flow:

```json
{
  "event": "Delivery.Plan.Entered",
  "work-item-id": "<issue-number>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<new-uuid>",
  "execution-id": "<new-uuid>",
  "actor": { "player": "<player>", "agent": "downstream-agent" },
  "payload": {}
}
```

2. Generate `ITERATION_DIR/cards/<card-slug>/context.md` from `prodops/templates/delivery/context-capsule.md`. Fill in **all** template fields, including:

**Runtime Context** — filled with data from the active iteration:
- `ds-id` — stable feature identifier (e.g. `DS-39`)
- `work-item-id` — issue number for the current iteration (resolved via DS-ID → Issue table in `plan.md`)
- `iteration-id` — iteration version (e.g. `v0.6.0`)
- `iteration-dir` — `prodops/artifacts/iterations/<version>/`
- `correlation-id` — UUID generated at `Delivery.Plan.Entered` above
- `actor-player` — current player (`claude`, `codex` or `copilot`)

**Runtime Paths** — pre-computed to eliminate derivation at each phase:
- `feature-branch` — `feat/<work-item-id>-<slug>`
- `base-branch` — base branch for the merge (normally `master`)
- `timeline-path` — `ITERATION_DIR/runtime/timelines/<work-item-id>.json`
- `plan-bootstrap-path` — `ITERATION_DIR/runtime/plan-bootstrap.json`
- `plan-validate-path` — `ITERATION_DIR/runtime/plan-validate.json`
- `session-trail-dir` — `ITERATION_DIR/trails/`
- `obc-path`, `bdd-path` — absolute paths to product artifacts
- `reliability-path` — path to the Reliability Plan if it exists, otherwise `"none"`

**Flow State** — leave blank; filled by Finish (`pr-number`) and Ship (`infra-scope`):
- `pr-number: (filled by Finish)`
- `infra-scope: (filled by Ship)`
- `oem-state: PENDING`

**BDD Scenarios** — include complete steps (Given/When/Then), not just one-liners, so that Hack/tdd can execute the Red phase without opening the `.feature` file.

The capsule is the only artifact the agent needs to load to execute the entire flow without re-reading infrastructure files. The `correlation-id` generated here is propagated to Bootstrap, Hack, Sync, Finish, Ship, Validate, and Promote.

## CI Sync

1. **Bootstrap** — when invoked inside the `/downstream` loop (no-argument mode or DS-ID from a plan), Bootstrap operates in fast path if the Plan Bootstrap already completed: emits only the Started/Completed events without re-executing dependencies or smoke gate. In isolated executions (without Plan Bootstrap), it runs the full flow.
2. **Hack** — run `start`, `tdd`, and `commit`; `start` owns Git flow and branch creation.
3. **Sync** — synchronize the branch and align impacted ProdOps artifacts.
4. **Finish** — execute final quality gates and prepare the PR.

## CI Async

CI Async operates in three sequential phases across all plan items:

**Phase 1 — Ship (per issue, in sequence)**
For each issue in the plan queue, in order:
1. Confirm that CI Sync evidence exists and was approved.
2. Trigger `staging-deploy.yml` via `gh workflow run` and wait for completion.
3. Advance to the next issue without waiting for Validate.

**Phase 2 — Validate (per issue, in sequence)**
For each issue in the plan queue, in order:
1. Validate BDD, OBC, observability, SLOs, and risks in the target environment.
2. After `Validate.Completed`: update `plan-validate-<iteration-id>.json` marking the issue as validated.
3. After the last issue validates: emit `Delivery.Plan.Validated` — the plan gate passes.
4. If any Validate fails: **stop all of phase 3**. No Promote occurs while issues are pending.

**Phase 3 — Promote (per issue, in sequence — mandatory plan gate)**
Only started after `Delivery.Plan.Validated` is emitted:
1. For each issue in the plan queue, in order: apply approval gates and record in the Release Trail.
2. The Promote for each issue verifies `plan-validate-<iteration-id>.json` before emitting `Promote.Started`.

**Note on standalone executions** (`/downstream ci-async DS-<n>`): without an Iteration Plan context, CI Async operates per issue independently (Ship → Validate → Promote) without a plan gate.

## Iteration closure

Closure is executed immediately after the last `Promote.Completed` of the iteration — never before, never deferred to the next session.

### Trigger

All of the following conditions must be true:

1. `ITERATION_DIR/runtime/plan-validate.json` has `"status": "all-validated"`.
2. All issues in the plan are `CLOSED` on GitHub (`gh issue view <n> --json state`).
3. All corresponding PRs are `MERGED`.

### Closure actions (in order)

1. **Update `ITERATION_DIR/plan.md`:**
   - Header: `# Iteration Plan — <iteration-id>` (remove `(Active)` suffix)
   - Status: `✅ Concluded — <YYYY-MM-DD>`
   - `Status` column for each item: `Entered` → `Concluded`
   - Add `PR` column with the merged PR number per item
   - Mark satisfied exit criteria with `[x]`; unsatisfied criteria remain `[ ]` with an explanatory note

2. **Update `prodops/artifacts/plans/iteration-plan.md`:**
   - Move the active iteration row to the history table
   - Status: `✅ Concluded — PRs #<n>–#<m>`
   - Replace the "Current iteration" section with: `No active iteration. Next iteration to be defined.`

3. **Commit:**
   ```
   chore(prodops): close iteration <iteration-id> — all <N> items promoted
   ```

### What NOT to do during closure

- Do not create a new iteration in the same closure commit — they are distinct acts.
- Do not delete or move `runtime/` — runtime artifacts belong to the iteration's history.
- Do not mark `[x]` for criteria that were not satisfied — record the exception as a note.

### Iteration with partial criteria

If at least one exit criterion was not met (e.g., missing timelines, pending Diligence):
- Close anyway if all operational gates passed (PRs merged, issues closed, plan-validate all-validated).
- Record the exception as a closure note in the iteration's `plan.md`.
- Apply the follow-up issue protocol below.

### Follow-up issues — inconsistencies and problems detected

At the end of each phase and when closing the iteration, the agent must identify and register every inconsistency, residual problem, or debt detected during execution. For each item identified:

**1. Create a GitHub Issue with:**
- **Title:** objective description of the problem (`[follow-up]: <concise description>` or canonical Work Item Schema title)
- **Body:** origin (phase where it was detected), impact, concrete next action
- **Labels:** `journey:diligence`, `artifact-type:business-signal`, `operation:capture`
- **References:** iteration issue that originated the problem, PR, iteration-id

**2. Add an entry to the Tracking List** (`prodops/artifacts/product/backlogs/tracking-list.md`):
- New row with: description, origin, dimension, owner, created issue number, status `Open`, next action

**3. Post a comment on the iteration issue** that originated the problem, referencing the new follow-up issue.

**When follow-up is mandatory:**

| Situation | Example |
|---|---|
| Unsatisfied exit criterion | Missing timelines, pending Diligence |
| Residual problem after delivery | Remaining Dependabot alert after update |
| Technical debt identified during Hack | Bug worked around without fix, insufficient test coverage |
| Partially satisfied gate | SLI below target after Validate |
| Anomaly observed in operational phase | Duplicate Datadog event, inconsistent Project state |

**When NOT to create follow-up:**
- Explicit risk acceptance decision already recorded in `risks.md`
- Item already tracked in an existing open issue

**Commit the updates:**
```
chore(prodops): register follow-up issues from iteration <iteration-id>
```

## Exception protocol — blockers

When a phase cannot advance (permission denied, gate failed, timeout, external blocker):

1. Emit `Delivery.Block.Declared` **before stopping**, recording the reason in the payload:

```json
{
  "event": "Delivery.Block.Declared",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<correlation-id>",
  "execution-id": "<new-uuid>",
  "actor": { "player": "<player>", "agent": "downstream-agent" },
  "payload": {}
}
```

This sets `oem-state = BLOCKED` in the GitHub Project and automatically triggers the Diligence Sync (`diligence.capture`) via dispatcher.

2. Report the blocker to the caller with: the phase where it occurred, the reason, and the action required to resolve it.

When the blocker is resolved and the flow resumes:

3. Emit `Delivery.Block.Resolved` **before continuing**, using the same `correlation-id`:

```json
{
  "event": "Delivery.Block.Resolved",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<correlation-id>",
  "execution-id": "<new-uuid>",
  "actor": { "player": "<player>", "agent": "downstream-agent" },
  "payload": {}
}
```

This sets `oem-state = PENDING` and allows Bootstrap to start again.

## Guardrails

- Do not start a delivery phase while readiness is incomplete.
- Do not treat an Iteration Plan entry alone as readiness.
- Do not invent OBCs, BDD scenarios, risks or acceptance criteria.
- Do not make Bootstrap perform Git flow or product-context work.
- Do not ship work supported only by Upstream evidence.
- Do not skip quality gates without an explicit recorded decision and risk acceptance.
- Do not promote unresolved high-risk items without explicit acceptance.
- Do not create GitHub Issues or PRs without declaring artifact_type, artifact_id, operation, and journey.
- In no-argument mode, stop only on readiness failure or gate failure — never wait for confirmation between items.
- Use the canonical Work Item title pattern: `[Artifact ID]: description`.
- Never stop silently — every blocker must emit `Delivery.Block.Declared` before reporting to the caller.

## References

→ [Readiness SKILL.md](../readiness/SKILL.md)
→ [Execution Mapping](../../framework/execution-mapping/README.md)
→ [Work Item Schema](../../framework/execution-mapping/work-item-schema.md)
→ [Mapping Matrix](../../framework/execution-mapping/matrix.md)
→ [Iteration Plan](../../artifacts/plans/iteration-plan.md)
