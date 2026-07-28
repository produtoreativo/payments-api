# ProdOps Runtime — Event Contract

**runtime-version:** 0.3.0
**contract-version:** 1.0.0
**last-updated:** 2026-07-27

---

## 1. Overview

All events produced by the ProdOps Runtime conform to **CloudEvents 1.0** (https://cloudevents.io). The CloudEvents envelope provides interoperability; the ProdOps operational model lives exclusively inside the `data` field.

No OEM attributes appear outside of `data`. No proprietary envelope exists. This is the canonical and only format used by the Runtime starting from runtime-version `0.3.0`.

---

## 2. CloudEvents Envelope

Every event produced by the Runtime contains the following top-level fields:

| Field | Type | Required | Description |
|---|---|---|---|
| `specversion` | String | Yes | Always `"1.0"` |
| `id` | UUID | Yes | Unique event identifier (UUIDv4, lowercase) |
| `source` | URI | Yes | Source of the event — GitHub repository URI |
| `type` | String | Yes | CloudEvent type in reverse-domain notation (see catalog) |
| `subject` | String | Yes | GitHub issue number as string (the Work Item) |
| `time` | RFC3339 | Yes | UTC timestamp of event occurrence |
| `datacontenttype` | String | Yes | Always `"application/json"` |
| `dataschema` | URI | Yes | Schema URI for the `data` object |
| `data` | Object | Yes | ProdOps operational payload (see Section 3) |

**Fixed values (from `runtime.yaml`):**

| Field | Value |
|---|---|
| `specversion` | `1.0` |
| `source` | `https://github.com/produtoreativo/payments-api` |
| `datacontenttype` | `application/json` |

---

## 3. ProdOps Payload (`data`)

The `data` object contains all ProdOps/OEM attributes:

| Field | Type | Description |
|---|---|---|
| `issue` | String | GitHub issue number (matches `subject`) |
| `journey` | String | OEM Journey (`Delivery`, `Diligence`, `Assessment`) |
| `cycle` | String | OEM Cycle (`Bootstrap`, `Hack`, `Sync`, …) |
| `phase` | String | OEM Phase (`Started`, `Completed`) |
| `alters-state` | Boolean | Whether this event changes the Derived State |
| `new-state` | String | The new Derived State (when `alters-state` is true) |
| `runtime-correlation-id` | UUID | Links all events in a single bootstrap execution |
| `runtime-version` | String | Runtime version that produced this event |
| `framework-version` | String | ProdOps Framework version |
| `schema-version` | String | Schema version for `data` (for future migrations) |

---

## 4. Event Type Convention

CloudEvent types follow reverse-domain notation:

```
prodops.<journey>.<cycle>.<phase>
```

All components are lowercase. Example:

| Logical name | CloudEvent type |
|---|---|
| `Delivery.Bootstrap.Started` | `prodops.delivery.bootstrap.started` |

The mapping is defined in `catalog/events.yaml` and is authoritative.

---

## 5. Event Catalog (`catalog/events.yaml`)

The catalog is the single source of truth for event definitions. Format per event:

```yaml
events:
  <Logical.Event.Name>:
    cloud-event-type:  # CloudEvents type (reverse-domain)
    description:       # Human-readable description
    data-schema:       # URI of the JSON Schema for data
    journey:           # OEM Journey
    cycle:             # OEM Cycle
    phase:             # OEM Phase
    alters-state:      # Boolean
    new-state:         # Derived State value (when alters-state: true)
```

The producer reads metadata exclusively from the catalog. Adding a new event requires only a catalog entry — no producer code changes.

---

## 6. Complete Event Example

```json
{
  "specversion": "1.0",
  "id": "2c073dc7-b105-432b-bab8-4795a47ab0d4",
  "source": "https://github.com/produtoreativo/payments-api",
  "type": "prodops.delivery.bootstrap.started",
  "subject": "76",
  "time": "2026-07-27T14:34:39Z",
  "datacontenttype": "application/json",
  "dataschema": "https://prodops.produtoreativo.io/schemas/events/delivery/bootstrap/started/v1.0.0",
  "data": {
    "issue": "76",
    "journey": "Delivery",
    "cycle": "Bootstrap",
    "phase": "Started",
    "alters-state": true,
    "new-state": "BOOTSTRAPPING",
    "runtime-correlation-id": "f53e3483-9ba6-4161-97a9-6df8aa2c8536",
    "runtime-version": "0.3.0",
    "framework-version": "1.0.0",
    "schema-version": "1"
  }
}
```

---

## 7. Timeline

The Timeline is an append-only JSON array of CloudEvents:

```json
[
  { ...CloudEvent 1... },
  { ...CloudEvent 2... }
]
```

**Storage:** `prodops/artifacts/runtime/timelines/<issue>.json`

No event that fails validation by `validate-event.sh` may be appended. The producer validates before emitting; the timeline validates before appending. Two gates, zero exceptions.

---

## 8. Derived State

The Consumer (`consumer/derive-state.sh`) reads the Timeline and computes:

- **Rule:** the last CloudEvent with `data["alters-state"] == true` determines the current state.
- **State** is read from `data["new-state"]`.
- **Correlation** is read from `data["runtime-correlation-id"]`.
- **Event type** is read from the envelope (`.type`), not from `data`.

Output (`derived-state.json`):

```json
{
  "issue": "76",
  "state": "BOOTSTRAPPING",
  "last-event-type": "prodops.delivery.bootstrap.started",
  "runtime-correlation-id": "f53e3483-9ba6-4161-97a9-6df8aa2c8536",
  "runtime-version": "0.3.0",
  "framework-version": "1.0.0",
  "schema-version": "1",
  "computed-at": "2026-07-27T14:34:40Z"
}
```

---

## 9. Validation

`validate-event.sh` enforces:

1. All 9 required fields are present: `specversion`, `id`, `source`, `type`, `subject`, `time`, `datacontenttype`, `dataschema`, `data`
2. `specversion` equals `"1.0"`
3. `data` is a JSON object (not null, not array, not primitive)

**Invocation points:**
- Producer (`emit.sh`) — validates before emitting output
- Timeline (`append.sh`) — validates before appending

**Exit codes:** `0` = PASS, `1` = FAIL with specific field message.

---

## 10. Versioning and Compatibility

| Version | Change |
|---|---|
| `runtime-version: 0.1.0` | Proprietary event format (Iteration 1) |
| `runtime-version: 0.2.0` | Kebab-case keys, correlation-id, config-driven (Iteration 2) |
| `runtime-version: 0.3.0` | **CloudEvents 1.0 format** — all events use CE envelope (Iteration 3) |

**Breaking change at 0.3.0:** Timelines from 0.1.0 and 0.2.0 use the proprietary format. The Consumer (`derive-state.sh`) reads `.data["alters-state"]` — old events stored this at the top level. Timelines should be reset when upgrading from < 0.3.0.

**Forward compatibility:** The `schema-version` field inside `data` is reserved for future migrations of the `data` payload schema. The CloudEvents envelope schema is fixed at `specversion: 1.0`.

---

## 11. Naming Conventions

All Runtime artifacts use **kebab-case**:

| Context | Convention | Example |
|---|---|---|
| JSON keys | kebab-case | `alters-state`, `new-state` |
| GitHub field names | kebab-case | `oem-state`, `oem-last-event` |
| CloudEvent type | reverse-domain, lowercase | `prodops.delivery.bootstrap.started` |
| Logical event name | PascalCase with dots | `Delivery.Bootstrap.Started` (catalog key only) |
| File names | kebab-case | `validate-event.sh`, `derive-state.sh` |
| Config keys | kebab-case | `runtime-version`, `cloud-events.source` |
