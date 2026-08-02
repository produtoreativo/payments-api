---
name: bootstrap
description: Prepare the local environment required by a ProdOps execution before Git flow, tests, or implementation begin. Emits Bootstrap.Started, Bootstrap.Dependencies.Installed, Bootstrap.Services.Ready, Bootstrap.Smoke.Passed, and Bootstrap.Completed via prodops_emit_event.
---

# BOOTSTRAP

Bootstrap prepares the execution environment and records its lifecycle via `prodops_emit_event`. It does not assess product readiness, read implementation code or tests, create branches, or implement behavior.

Product readiness belongs to the `/downstream` orchestrator. Git flow belongs to `/hack start`.

## Required input context

Before starting, read the context capsule at
`prodops/artifacts/iterations/<iteration-id>/cards/<slug>/context.md`.
All fields below must be available — either from the capsule or explicitly provided by the caller:

- `work-item-id` — from capsule field `work-item-id` (issue number for the current iteration)
- `iteration-id` — from capsule field `iteration-id`
- `correlation-id` — from capsule field `correlation-id` (generated at `Delivery.Plan.Entered`)
- `actor.player` — from capsule field `actor-player`
- `plan-bootstrap-path` — from capsule field `plan-bootstrap-path`

If the capsule is absent or any field is blank, ask the caller to provide them before proceeding. Do not generate placeholder values.

## Fast path — Plan Bootstrap already ran

Before executing any Bootstrap work, read `plan-bootstrap-path` from the capsule (or resolve `ITERATION_DIR/runtime/plan-bootstrap.json`) and verify:

If the file exists and contains `"status": "completed"`:

1. Emit `Delivery.Bootstrap.Started` with `"fast-path": true` in the payload.
2. Emit `Delivery.Bootstrap.Completed` with `"fast-path": true` in the payload — using the same `correlation-id`.
3. Report to caller: `Bootstrap fast path — environment ready from Plan Bootstrap (iteration: <iteration-id>)`.
4. Stop. Do not run Bootstrap work below.

If the file does not exist or `status != "completed"`: proceed with the full flow below.

---

## Preconditions

1. `prodops/skills/prodops-emit-event/SKILL.md` has been read and the agent understands how to invoke the tool.
2. The tool is available at `prodops/runtime/tools/emit-event/scripts/emit-event`.
3. The repository is accessible from the current working directory.

## Phase: Bootstrap.Started

**Moment**: after input context is verified, before any Bootstrap work begins.

Generate a correlation ID (UUID) for this Bootstrap execution. Use this same UUID for the Bootstrap.Completed call.

Emit:

```json
{
  "event": "Delivery.Bootstrap.Started",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<generated-uuid>",
  "execution-id": "<new-uuid>",
  "actor": {
    "player": "<player>",
    "agent": "bootstrap-agent"
  },
  "payload": {}
}
```

If the tool returns `status: error` (exit 1 or 2): report the error to the caller, fix the input, and do not proceed with Bootstrap work until the event is accepted.

If the tool returns `status: accepted` (exit 0): record the `event-id` for tracing and proceed.

## Bootstrap work

Execute the steps below in order. Each step has a checkpoint event — do not emit the event if the step fails. On failure, emit `Delivery.Block.Declared` and stop.

### Step 1 — Verify runtimes and CLIs

Identify the packages and services required by the repository. Verify that required runtimes and command-line tools are available (e.g. `node`, `npm`, `docker`). This step does not emit an event — failures are covered by `Block.Declared`.

### Step 2 — Install dependencies

Install dependencies using the repository's declared package manager.

**Moment**: after installation completes without errors.

Emit `Delivery.Bootstrap.Dependencies.Installed`:

```json
{
  "event": "Delivery.Bootstrap.Dependencies.Installed",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<same-uuid-as-started>",
  "execution-id": "<new-uuid>",
  "actor": {
    "player": "<player>",
    "agent": "bootstrap-agent"
  },
  "payload": {}
}
```

### Step 3 — Start local infrastructure

Prepare local infrastructure through the repository setup scripts (e.g. Docker, LocalStack, local database). Verify that all required services are reachable.

**Moment**: after all services are reachable.

Emit `Delivery.Bootstrap.Services.Ready`:

```json
{
  "event": "Delivery.Bootstrap.Services.Ready",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<same-uuid-as-started>",
  "execution-id": "<new-uuid>",
  "actor": {
    "player": "<player>",
    "agent": "bootstrap-agent"
  },
  "payload": {}
}
```

### Step 4 — Verify environment variables

Confirm that the required environment variable names are present. Do not read or expose values, tokens, credentials, or PII. This step does not emit an event — failures are covered by `Block.Declared`.

### Step 5 — Run smoke gate

Run the smoke gate defined in `prodops/exec/manifest.yaml`.

**Moment**: after the smoke gate passes without errors.

Emit `Delivery.Bootstrap.Smoke.Passed`:

```json
{
  "event": "Delivery.Bootstrap.Smoke.Passed",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<same-uuid-as-started>",
  "execution-id": "<new-uuid>",
  "actor": {
    "player": "<player>",
    "agent": "bootstrap-agent"
  },
  "payload": {}
}
```

## Phase: Bootstrap.Completed

**Moment**: after `Bootstrap.Smoke.Passed` is accepted — all steps completed successfully.

Emit using the same `correlation-id` generated at Bootstrap.Started:

```json
{
  "event": "Delivery.Bootstrap.Completed",
  "work-item-id": "<work-item-id>",
  "iteration-id": "<iteration-id>",
  "correlation-id": "<same-uuid-as-started>",
  "execution-id": "<new-uuid>",
  "actor": {
    "player": "<player>",
    "agent": "bootstrap-agent"
  },
  "payload": {}
}
```

If the tool returns `status: error` for Bootstrap.Completed: report the error explicitly. Do not invent a `Completed` event; the timeline will show only `Bootstrap.Started` and the checkpoints reached so far.

If the tool returns `status: skipped` (exit 4): the event was already recorded. This is acceptable if Bootstrap ran twice with the same correlation ID; continue.

## Guardrails

- Do not read or modify production implementation code.
- Do not inspect or execute behavior tests; those belong to Hack and Finish.
- Do not create, switch, merge, rebase, stash, or delete Git branches.
- Do not read or create OBCs, BDD Features, risks, Reliability Plans or Iteration Plan entries.
- Do not generate a context capsule.
- Do not expose `.env` values, tokens, credentials or PII.
- Do not silently discard local work.
- Do not call GitHub, Datadog, or any external service directly. All external state is managed by `prodops_emit_event`.
- Do not construct a CloudEvent manually.
- Do not emit Bootstrap.Completed if the completion gate has not been reached.

## Post-conditions

- Dependencies are installed.
- Required local services are available.
- Environment configuration requirements are known without secrets being exposed.
- The smoke gate passes, or the environment blocker is explicit.
- Timeline for `work-item-id` contains `Delivery.Bootstrap.Started`, `Bootstrap.Dependencies.Installed`, `Bootstrap.Services.Ready`, `Bootstrap.Smoke.Passed`, and `Delivery.Bootstrap.Completed`.
- GitHub Project shows `oem-state: BOOTSTRAPPING` updated after Started; last-event updated after Completed.
- `/hack start` can establish the Git flow after Downstream readiness is reached.
