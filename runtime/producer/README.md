# @prodops/runtime-producer

**RT-01 — Operational Event Producer**

Validates and encodes `OperationalEvent` instances into CloudEvents 1.0 envelopes, then hands them off to a transport adapter via the `EventPublisher` interface.

## Objective

Transform an OEM `OperationalEvent` into a transport-ready `CloudEventEnvelope<OperationalEvent>`. The Producer knows nothing about Datadog, GitHub, Replay, Timelines, or metrics — it does one thing: produce.

## Relationship with the SDK

This package depends exclusively on `@prodops/runtime-sdk` for all types and contracts:
- `OperationalEvent` (domain model)
- `CloudEventEnvelope`, `CloudEventEncoder`, `CloudEventEncodingContext`, `CloudEventSource` (CloudEvents contracts)
- `EventPublisher` (transport port)
- `ProducerType` (enum for validation)

It adds no new data model — it only implements the runtime behavior behind the SDK contracts.

## Architecture

```
OperationalEvent
      │
      ▼
OperationalEventProducer.publish(event)
      │
      ├─ 1. validateOperationalEvent(event)   ← src/validator.ts
      │        UUID v7, event_type format, timestamp, work_item_id,
      │        schema_version, producer_type, producer_identity
      │        → throws ProducerValidationError if invalid
      │
      ├─ 2. OemCloudEventEncoder.encode(event, context)   ← src/encoder.ts
      │        OEM → CloudEvents 1.0 field mapping
      │        context.source → envelope.source (NOT producer_identity)
      │
      └─ 3. EventPublisher.publish(envelope)   ← SDK interface, injected
               Implemented by RT-04 (Datadog Adapter) or any sink
```

## Field mapping

| EventInstance field | CloudEventEnvelope field | Notes |
|---|---|---|
| `id` | `id` | UUID v7, unchanged |
| `event_type` | `type` | `<Namespace>.<Subject>.<Action>` |
| `work_item_id` | `subject` | unchanged |
| `context.source` | `source` | deployment-time URI — **never** `producer_identity` |
| `timestamp` | `time` | ISO-8601, unchanged |
| `event` (whole record) | `data` | `producer_identity` preserved here |

## Source vs Producer Identity

These are distinct concepts that must never be conflated:

| Concept | Where | Meaning |
|---|---|---|
| `producer_identity` | `EventInstance.producer_identity` | Identity of the specific agent/human/system that produced this event |
| `source` | `CloudEventEnvelope.source` | Stable technical URI of the emitting context (deployment concern) |

Canonical ProdOps source URIs:
- `prodops://payments-api/runtime`
- `prodops://payments-api/github-actions`
- `prodops://payments-api/human-cli`

## Validation rules

| Field | Rule |
|---|---|
| `id` | UUID v7 (`xxxxxxxx-xxxx-7xxx-[89ab]xxx-xxxxxxxxxxxx`) |
| `event_type` | `<Namespace>.<Subject>.<Action>[.<Qualifier>]` — min 3 dot-separated segments |
| `timestamp` | Valid ISO-8601 datetime |
| `work_item_id` | Non-empty, non-blank string |
| `schema_version` | Non-empty, non-blank string |
| `producer_type` | Valid `ProducerType` enum value (`Human`, `System`, `Agent`) |
| `producer_identity` | Non-empty, non-blank string |

Validation is pure — no external I/O.

## Usage

```typescript
import {
  OperationalEventProducer,
  OemCloudEventEncoder,
  toCloudEventSource,
} from '@prodops/runtime-producer';
import type { EventPublisher } from '@prodops/runtime-sdk';

// Configure once at application start-up
const source = toCloudEventSource('prodops://payments-api/runtime');
const context = { source };

// EventPublisher is injected — implement in RT-04 or use a test stub
const publisher: EventPublisher = { /* ... */ };

const producer = new OperationalEventProducer({
  encoder: new OemCloudEventEncoder(),
  publisher,
  context,
});

// Produce an event
const event: OperationalEvent = {
  id: uuidv7() as EventId,
  event_type: 'Delivery.Hack.Started',
  work_item_id: 'wf-delivery-0042',
  timestamp: new Date().toISOString(),
  producer_type: ProducerType.Agent,
  producer_identity: 'agent:hack-start-agent',
  schema_version: '1.0',
};

const envelope = await producer.publish(event);
// envelope is the CloudEventEnvelope sent to publisher
```

## Error handling

```typescript
import { ProducerValidationError } from '@prodops/runtime-producer';

try {
  await producer.publish(event);
} catch (err) {
  if (err instanceof ProducerValidationError) {
    console.error('Validation violations:', err.violations);
    // handle: log, DLQ, alert
  }
  // other errors: publisher transport failures — propagated as-is
}
```

## What this component deliberately does NOT do

| Capability | Responsible component |
|---|---|
| Push to Datadog | RT-04 Datadog Adapter (implements `EventPublisher`) |
| Query the event store | RT-02 Timeline Processor (implements `EventQuery`) |
| Replay or Lookback | RT-02 Timeline Processor (implements `OperationalStateEngine`) |
| Synchronize GitHub Projects | RT-03 GitHub Synchronizer |
| Calculate metrics | RT-04 Datadog Adapter |
| Serve dashboards | RT-05 / RT-06 Dashboards |
| Generate UUID v7 | Caller responsibility (use `uuidv7` package) |

## Development

```bash
npm install         # install dependencies (SDK must be built first)
npm test            # run all 37 tests
npm run typecheck   # tsc --noEmit, Exit 0
npm run build       # compile to dist/
```

SDK must be built before `npm install`:

```bash
cd ../sdk && npx tsc   # build SDK dist/
cd ../producer && npm install
```
