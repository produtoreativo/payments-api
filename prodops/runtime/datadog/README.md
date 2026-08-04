# ProdOps Runtime Datadog Dashboard

## Overview

`runtime-dashboard.json` defines the ProdOps Runtime observability dashboard for Datadog.
It tracks **cycle time per delivery phase**, filterable by iteration, using the
`iteration:<id>` tags introduced by DS-57.

## Prerequisites

DS-57 must be complete. `send.sh` must be called with `--iteration-id <id>` so that
every event carries the `iteration:<iteration_id>` tag in Datadog.

## Template Variable: `$iteration_id`

The dashboard exposes a template variable named `iteration_id` with prefix `iteration`.

- Default value: `*` (all iterations)
- To filter a specific iteration, select or type its value (e.g. `v0.12.0`)
- Every widget query uses `iteration:$iteration_id.value` — selecting a value
  instantly scopes all widgets to that iteration

## Cycle Time Widgets

The dashboard contains **7 query_value widgets** (one per phase) and **7 timeseries
widgets** (one per phase) showing average cycle time in hours.

| Widget title          | Phase tag | Metric                                              |
|-----------------------|-----------|-----------------------------------------------------|
| Bootstrap Cycle Time  | bootstrap | `avg:prodops.delivery.cycle_time{...,phase:bootstrap}` |
| Hack Cycle Time       | hack      | `avg:prodops.delivery.cycle_time{...,phase:hack}`      |
| Sync Cycle Time       | sync      | `avg:prodops.delivery.cycle_time{...,phase:sync}`      |
| Finish Cycle Time     | finish    | `avg:prodops.delivery.cycle_time{...,phase:finish}`    |
| Ship Cycle Time       | ship      | `avg:prodops.delivery.cycle_time{...,phase:ship}`      |
| Validate Cycle Time   | validate  | `avg:prodops.delivery.cycle_time{...,phase:validate}`  |
| Promote Cycle Time    | promote   | `avg:prodops.delivery.cycle_time{...,phase:promote}`   |

Cycle time is the duration between `<Phase>.Started` and `<Phase>.Completed` events
for the same `work-item-id`. The gauge metric `prodops.delivery.cycle_time` should be
emitted at the Completed event with the phase label and the iteration tag.

Widget labels use **canonical phase names** (Bootstrap, Hack, Sync, Finish, Ship,
Validate, Promote) — not internal CloudEvent names such as
`prodops.delivery.bootstrap.started`.

## How to Import the Dashboard into Datadog

1. Log in to your Datadog account.
2. Navigate to **Dashboards > New Dashboard** or open an existing dashboard.
3. Click the settings icon (gear) in the top-right corner and select
   **Import dashboard JSON**.
4. Paste or upload the contents of `runtime-dashboard.json`.
5. Click **Yes, Replace** to confirm.
6. Use the `$iteration_id` template variable selector at the top of the dashboard
   to filter by a specific iteration (e.g. `v0.12.0`).

## How `iteration:<id>` Tags Are Set

`send.sh` accepts `--iteration-id <value>` and appends `iteration:<value>` to the
Datadog metric tags for every event sent. Example:

```bash
bash prodops/runtime/datadog/send.sh \
  --issue 149 \
  --event prodops.delivery.hack.started \
  --state started \
  --correlation-id 8fd9297d-4751-47ef-8cc5-d16d2d12ade9 \
  --iteration-id v0.12.0
```

This emits the metric `runtime.event.received` with tags including
`iteration:v0.12.0`, `issue:149`, `event:prodops.delivery.hack.started`, etc.

## Scope and Limitations

- The `iteration` filter works only for events emitted **after DS-57** was deployed.
  Historical events without the tag will not appear when filtering by iteration.
- Cycle time widgets require the `prodops.delivery.cycle_time` gauge to be emitted
  explicitly at each `<Phase>.Completed` event. If the gauge is not yet sent,
  the widgets will show no data (not an error).
- Alerts based on cycle time thresholds are out of scope for DS-60.
