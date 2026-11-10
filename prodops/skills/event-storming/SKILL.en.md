---
name: event-storming
description: Generates an Event Storming script from a Business Signal/Intent/OBC, documents it, builds the Datadog dashboard and publishes it. Use when a signal or capability needs an Event Storming (event timeline, policies, hot spots, observability) or when an existing spec changed and the dashboard must be regenerated. The single source is the JSON spec; script and dashboard are derived.
---

# Event Storming — script, documentation, dashboard and publishing

This skill turns a business signal into a **documented Event Storming** and a **Datadog dashboard**, around one file, the **spec**:

```
prodops/artifacts/event-storming/<slug>.spec.json      ← single source (edited by a human/agent)
        ├─ render-roteiro.py   → <slug>.md              script and documentation
        ├─ build-dashboard.py  → <slug>.datadog.json    dashboard (Datadog API JSON)
        └─ publish-dashboard.sh→ Datadog + <slug>.datadog.state.json (dashboard id)
```

Never edit the script or dashboard by hand: change the spec and regenerate. Scripts live in `prodops/skills/event-storming/scripts/` (run with `python3`, without `-I`).

## Modes

`create` (signal/OBC without a storming), `update` (spec changed), `check` (does the spec match the code?), `publish` (dashboard to Datadog).

## Flow — `create`

1. **Gather facts from the code**, not assumptions (what is emitted, guards, listeners). Where a question can be settled by a test, write a throwaway investigation test, run it, record the result, then turn it into a real test.
2. **Write the spec** (schema in the Portuguese `SKILL.md`). Promised-but-not-emitted events are `planned`; never invent a name.
3. **Validate**: `python3 prodops/skills/event-storming/scripts/build-dashboard.py <spec> --check` (fails if an `emitted` event is not in `api/src/events/payments-events.ts`, or an `available` widget uses a metric the code does not emit).
4. **Render the script**: `python3 prodops/skills/event-storming/scripts/render-roteiro.py <spec>` (refuses to overwrite without `--force`).
5. **Build the dashboard**: `python3 prodops/skills/event-storming/scripts/build-dashboard.py <spec>`.
6. **Publish**, only with authorization. Link the script from the OBC and the Business Signal.

## Publishing

```bash
prodops/skills/event-storming/scripts/publish-dashboard.sh <slug>.datadog.json            # dry-run: validates key and JSON, sends nothing
prodops/skills/event-storming/scripts/publish-dashboard.sh <slug>.datadog.json --apply    # create (POST) or update (PUT)
```

Publishing is an **external effect**: run the dry-run, show the owner what will be created/updated and **ask for confirmation** before `--apply`. Credentials come from the environment or `api/.env`; **never print keys**. The id is kept in `<slug>.datadog.state.json` so the next publish updates the same dashboard. If the state file is missing but the dashboard exists, stop and ask.

## Testing the dashboard with synthetic metrics

`python3 prodops/skills/event-storming/scripts/emit-test-events.py <spec> [--count N] [--dry-run]` sends, over DogStatsD, the same metric increments the widgets query (tags `env`, `service`, the query filters, `source:event-storming-test`, `storming:<slug>`). It writes real data to Datadog: confirm with the owner first. Once the code emits the metric for real, mark the widget `available` and regenerate.

## Guardrails

Do not invent decisions, SLI targets, stakeholders or metrics (`[apurar]` / `planned`). Do not change code, tests, BDD or OBC from this skill. Do not commit without the caller's authorization. Never delete Datadog dashboards. Never write secrets into any artifact.
