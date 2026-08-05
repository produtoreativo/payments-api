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

## Skill resolution and project configuration

Read `prodops/runtime/runtime.yaml` **once** at the start of execution and extract:

- **Skill paths** — section `skills:`. Never use `find` or `ls` to locate skill files.
- **GitHub Project configuration** — section `github:`, fields `owner` and `project-number`.

```yaml
# prodops/runtime/runtime.yaml
github:
  owner: produtoreativo
  project-number: 25
skills:
  bootstrap: prodops/skills/bootstrap/SKILL.md
  hack:      prodops/skills/hack/SKILL.md
  # ...
```

Store the values as variables for use in all `gh project` commands:

```bash
PROJECT_OWNER=$(python3 -c "import yaml; d=yaml.safe_load(open('prodops/runtime/runtime.yaml')); print(d['github']['owner'])")
PROJECT_NUMBER=$(python3 -c "import yaml; d=yaml.safe_load(open('prodops/runtime/runtime.yaml')); print(d['github']['project-number'])")
```

To invoke a skill: extract the path from the `skills:` section → read the file directly using the canonical path.

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

5. **Plan Bootstrap** — run once before the issue loop:
   a. Check if `ITERATION_DIR/runtime/plan-bootstrap.json` already exists with `"status": "completed"`. If so, skip to step 6 (environment already ready).
   b. Emit `Delivery.Plan.Bootstrap.Started` with `subject: <iteration-id>`, `work-item-id: null` and `--iteration-id <iteration-id>`. Check `"datadog-sync"` and `"github-sync"` in the output — display a warning if error.

   **Step 1 — Project Cleanup:** remove all existing items from the GitHub Project.
   ```bash
   bash prodops/runtime/scripts/project-cleanup.sh
   ```
   Safe when the project is empty — exits 0. After running, emit `Delivery.Plan.Bootstrap.Project.Cleaned`.

   **Step 2 — Tracking issue:** check if an issue with title `[Iteration <iteration-id>]:` already exists:
   ```bash
   gh issue list --search "[Iteration <iteration-id>]" --state all --json number,title | jq '.[0].number // empty'
   ```
   - If **not found**: create. Before creating, obtain the authenticated user's login:
     ```bash
     CE_LOGIN=$(gh api user --jq '.login')
     ```
     Create the issue including the assignee (non-fatal — if GitHub rejects `--assignee`, create without it and log a warning in the trail):
     ```bash
     gh issue create \
       --title "[Iteration <iteration-id>]: <scope-summary>" \
       --label "prodops,artifact-type:iteration-plan" \
       --assignee "$CE_LOGIN" \
       --body "Iteration Plan: prodops/artifacts/iterations/<iteration-id>/plan.md\n\nCapabilities: <DS-IDs>\nIssues: <issue-numbers>"
     ```
     If the command fails only because of `--assignee`, retry without `--assignee` and log a warning:
     `⚠️ Assignee could not be added to tracking issue — issue created without assignee`.
   - If already exists: record the number and continue.
   Emit `Delivery.Plan.Bootstrap.Issue.Registered` with the registered number in the payload.

   **Step 3 — Register issues in the plan:** for each issue in the Iteration Plan (all with status `Entrou`), in priority order:
   1. Generate a new UUID — this will be the `correlation-id` for the entire journey of this issue.
   2. Emit `Delivery.Plan.Bootstrap.Issue.Entered` with `work-item-id: <issue-number>`:
      ```json
      {
        "event": "Delivery.Plan.Bootstrap.Issue.Entered",
        "work-item-id": "<issue-number>",
        "iteration-id": "<iteration-id>",
        "correlation-id": "<new-uuid>",
        "execution-id": "<new-uuid>",
        "actor": { "player": "<player>", "agent": "downstream-agent" },
        "payload": { "ds-id": "<DS-ID>", "slug": "<capability-slug>" }
      }
      ```
   3. Write `ITERATION_DIR/cards/<card-slug>/context.md` from `prodops/templates/delivery/context-capsule.md` with the generated `correlation-id` and all template fields (ds-id, work-item-id, iteration-id, paths, BDD scenarios etc.).

   The dispatcher reacts to each `Plan.Bootstrap.Issue.Entered` and automatically triggers `Diligence.Capture` for that issue.

   **Step 4 — Add issues to Project:** add the iteration tracking issue **and** all feature issues with status `Entrou` to the GitHub Project:
   ```bash
   # TRACKING_ISSUE was obtained in Step 2 (tracking issue number)
   for ISSUE_NUMBER in "$TRACKING_ISSUE" <feature-issue-list>; do
     gh project item-add "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --url "https://github.com/$PROJECT_OWNER/payments-api/issues/$ISSUE_NUMBER"
   done
   ```
   The tracking issue must be added **first**. After adding all, emit `Delivery.Plan.Bootstrap.Issues.Added`.

   **Step 5 — Install dependencies:** install dependencies with the declared package manager. If it fails: stop the entire queue. After installing, emit `Delivery.Plan.Bootstrap.Dependencies.Installed`.

   **Step 6 — Local infrastructure:** verify runtimes and CLIs, start local services (Docker, LocalStack). If any service is not reachable: stop the entire queue. After all services confirmed, emit `Delivery.Plan.Bootstrap.Services.Ready`.

   **Step 7 — Smoke gate:** run the `smoke` gate defined in `prodops/exec/manifest.yaml`. If it fails: stop the entire queue. After passing, emit `Delivery.Plan.Bootstrap.Smoke.Passed`.

   c. Write `ITERATION_DIR/runtime/plan-bootstrap.json` **before** emitting `Plan.Bootstrap.Completed` — the dispatcher reacts to the event and `trail.sh` needs the file to build the issue comment:
   ```json
   {
     "iteration-id": "<iteration-id>",
     "status": "completed",
     "correlation-id": "<uuid-generated-at-started>",
     "completed-at": "<iso8601-timestamp>",
     "plan-issue": <tracking-issue-number>,
     "issues": ["<issue-1>", "<issue-2>", "..."]
   }
   ```
   d. Emit `Delivery.Plan.Bootstrap.Completed` with `subject: <iteration-id>` and `--iteration-id <iteration-id>`. Check `"datadog-sync"`, `"github-sync"` and `"dispatch.status"` in the output — display a warning if any field returns `"error"` or `"failed"`.
   e. Commit the file to the repository before starting the loop.

6. For each item in the queue, in order, without requesting confirmation between them:
   a. Run `/readiness <capability>` — if it fails: write `readiness-gate.json` with `"result": "blocked"` (see **Readiness Cache** section) and **stop the entire queue**.
   b. Execute CI Sync: Bootstrap → Hack → Sync → Finish — **in strict sequential synchronous order**. Each phase is a sub-agent invoked with `run_in_background: false`. Never spawn a phase in background. Never start the next phase before receiving the result of the previous one. After **each completed phase**:

      **6b-i — Verify output of each emit-event:** emit-event returns JSON with fields `"datadog-sync"`, `"github-sync"` and `"dispatch.status"`. After **each** emit-event call (in any phase), capture the JSON and verify the three fields:
      ```bash
      RESULT=$(bash prodops/runtime/tools/emit-event/scripts/emit-event --input <event.json>)
      echo "$RESULT" | jq -r '"datadog-sync: \(."datadog-sync") | github-sync: \(."github-sync") | dispatch: \(.dispatch.status)"'
      ```
      If `"datadog-sync": "error"` → display: `⚠️ Datadog sync failed — event recorded in local timeline but not sent to Datadog`.
      If `"github-sync": "error"` → display: `⚠️ GitHub sync failed — oem-state was NOT updated in the Project`. In this case **do not advance** to the next phase without resolving, as the Project state will be inconsistent.
      If `"dispatch.status": "failed"` → display: `⚠️ Dispatch failed — subscribers not notified (trail and diligence may be incomplete)`. Non-fatal: continue but log in the issue trail.

      **6b-ii — Post mandatory trail entry on issue (per phase):**

      This step consists of two trail entries per phase: one when **starting** the phase and one when **completing** (or failing). Both must be posted before advancing any state.

      **Required fields in every trail entry:** `phase-name`, `work-item-id`, `status`, `timestamp`. The absence of any field invalidates the entry as auditable evidence.

      **Phase start entry** — post immediately before invoking the phase sub-agent:
      ```bash
      gh issue comment <work-item-id> --body "## Trail — <Phase> Started — <YYYY-MM-DDTHH:MM:SSZ>

      **phase:** <Phase>
      **work-item-id:** <work-item-id>
      **status:** started
      **timestamp:** <YYYY-MM-DDTHH:MM:SSZ>

      ---
      *correlation-id: <uuid> · iteration: <iteration-id> · actor: <player>*"
      ```

      **Phase completion entry** — post after receiving the sub-agent result and **before advancing to the next phase**:
      ```bash
      gh issue comment <work-item-id> --body "## Trail — <Phase> — <YYYY-MM-DDTHH:MM:SSZ>

      **phase:** <Phase>
      **work-item-id:** <work-item-id>
      **status:** <completed | failed | blocked>
      **timestamp:** <YYYY-MM-DDTHH:MM:SSZ>

      <summary in up to 5 lines: what was done, key evidence, next step>

      ---
      *correlation-id: <uuid> · iteration: <iteration-id> · actor: <player>*"
      ```

      **Trail rules:**
      - The completion entry must be posted **before advancing to the next phase or issue** — never after.
      - Post even on failure or block — the comment must describe the reason and the action required to resolve it.
      - **Failure to post trail is non-fatal:** if `gh issue comment` returns an error, log an internal warning (`⚠️ Trail entry failed — <reason>`) and continue execution normally. The inability to record trail must not block or interrupt the execution loop.
      - A partial trail (start entries without completion entries) is sufficient to diagnose the last executed phase in case of mid-flight interruption.
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

1. Obtain the authenticated user's login (reuse `CE_LOGIN` if already captured in Plan Bootstrap, or capture now):
   ```bash
   CE_LOGIN=$(gh api user --jq '.login')
   ```
2. Create the Issue via `gh issue create` including the assignee (non-fatal — if GitHub rejects `--assignee`, create without it and log a warning in the trail: `⚠️ Assignee could not be added to issue DS-<n> — issue created without assignee`):
   - **Title:** `[DS-<n>]: <capability-description>`
   - **Body:** include DS-ID, iteration-id, OBC path, BDD path and link to plan.md
   - **Labels:** `journey:delivery`, `artifact-type:local-obc`, `operation:implement`
   - **Assignee:** `--assignee "$CE_LOGIN"`
3. Update the `Issue` column in `plan.md` with the created number.
4. Commit `plan.md` before continuing.

Do not associate with the Project here — adding all issues to the Project is handled centrally in Step 3 of Plan Bootstrap (`Plan.Bootstrap.Issues.Added`).

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

### Load the issue capsule

The capsule was written by Plan Bootstrap in Step 3 (`Delivery.Plan.Bootstrap.Issue.Entered`). Read `ITERATION_DIR/cards/<card-slug>/context.md`:

- If **restart** (timeline already has events from a previous run): overwrite the `correlation-id` field in the capsule with the new UUID generated in the Restart Protocol, and update `oem-state: PENDING`. Emit the three Restart events (`Delivery.Restart.Requested`, `Delivery.Restart.Started`, `Delivery.Restart.Completed`) using the previous `correlation-id` read from `.[0].data["runtime-correlation-id"]` in the timeline.
- If **first execution**: use the capsule without modification — the `correlation-id` from Plan Bootstrap Step 3 is already correct.

The capsule is the only artifact the agent needs to load to execute the entire flow without re-reading infrastructure files. The `correlation-id` is propagated to Bootstrap, Hack, Sync, Finish, Ship, Validate, and Promote.

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

0. **Close iteration tracking issue (auto-close):**
   Resolve the tracking issue number from `ITERATION_DIR/runtime/plan-bootstrap.json` (field `plan-issue`).
   Verify whether the tracking issue is already closed (idempotency):
   ```bash
   TRACKING_STATE=$(gh issue view <plan-issue> --json state --jq '.state')
   ```
   - If `TRACKING_STATE == "CLOSED"`: no action — do not reopen, do not post a duplicate comment. Log in the trail: `ℹ️ Tracking issue #<plan-issue> was already closed — no action taken.` and continue.
   - If `TRACKING_STATE == "OPEN"`:
     a. Post closure comment:
        ```bash
        gh issue comment <plan-issue> --body "## Iteration <iteration-id> — Automatic Closure

        **Date:** <YYYY-MM-DD>

        **DS-IDs delivered:** <DS-ID list, e.g.: DS-57, DS-58, DS-59, DS-60>

        **Merged PRs:** <PR list, e.g.: #148, #149, #150, #151>

        All Promotes completed. Iteration closed by downstream-agent.

        ---
        *iteration: <iteration-id> · actor: <player>*"
        ```
     b. Close the tracking issue:
        ```bash
        gh issue close <plan-issue>
        ```

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

3. **Commit — stage all modified files before committing:**
   ```bash
   git add prodops/artifacts/iterations/<iteration-id>/plan.md
   git add prodops/artifacts/plans/iteration-plan.md
   git add prodops/artifacts/iterations/<iteration-id>/runtime/
   git add prodops/artifacts/iterations/<iteration-id>/cards/
   git add prodops/artifacts/trails/
   git status  # verify no files are missing before committing
   git commit -m "chore(prodops): close iteration <iteration-id> — all <N> items promoted"
   ```
   Run `git status` after `git add` and before `commit` — if any modified files remain unstaged, add them before proceeding.

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
```bash
git add prodops/artifacts/product/backlogs/tracking-list.md
git status  # verify no files are missing before committing
git commit -m "chore(prodops): register follow-up issues from iteration <iteration-id>"
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
- **Never spawn phase sub-agents (Bootstrap, Hack, Sync, Finish, Ship, Validate, Promote) in background.** All sub-agents must use `run_in_background: false`. The downstream-agent waits for the result before invoking the next phase.
- **In restart (timeline with pre-existing events), always emit `Delivery.Restart.*` with the previous `correlation-id` before any phase event.** Never omit the Restart protocol — it is the auditable evidence that execution was resumed and the marker that separates executions in the timeline.
- **Duplicate events in the timeline are expected and correct in restart.** Each execution generates a new `correlation-id`; the Restart events with the previous correlation-id link the histories. Do not attempt to suppress phase events in restart.

## References

→ Readiness SKILL
→ [Execution Mapping](../../framework/execution-mapping/README.md)
→ [Work Item Schema](../../framework/execution-mapping/work-item-schema.md)
→ [Mapping Matrix](../../framework/execution-mapping/matrix.md)
→ [Iteration Plan](../../artifacts/plans/iteration-plan.md)
