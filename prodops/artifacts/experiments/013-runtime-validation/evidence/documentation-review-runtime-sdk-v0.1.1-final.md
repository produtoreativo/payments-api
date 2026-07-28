# Documentation Review — Runtime SDK v0.1.1 Final (Hardening)

**Date:** 2026-07-26
**Reviewer:** Claude (automated)
**Scope:** `runtime/sdk/` — pre-tag hardening for `runtime-v0.1.1`
**Previous review:** `prodops/documentation-review-runtime-sdk-v0.1.1.md`

---

## Summary

Two architectural inconsistencies found during remote branch review were corrected:

1. `CloudEvent.source` was being derived from `producer_identity` in example code and JSDoc.
2. Example event types were including `EventCategory` as a type segment (e.g. `Delivery.Hack.Phase Lifecycle.Started`).

Both contradicted consolidated architectural decisions. All fixes are purely in contracts, examples, and documentation — no implementation code (RT-01..RT-06) was touched.

**tsc --noEmit:** Exit 0 ✅
**grep producer_identity.*source / source.*producer_identity:** No live code mapping — only explanatory text confirming separation ✅
**grep Phase Lifecycle.Started:** Only appears in "incorrect example" documentation — no live type strings ✅

---

## Fix 1 — Source separated from Producer Identity

### Problem

`CloudEventEncoder.encode()` had no explicit context parameter. Example code derived `source` from `event.producer_identity`:

```typescript
// BEFORE (wrong)
source: event.producer_identity as CloudEventSource,
```

This conflated two distinct concepts:
- `producer_identity` = identity of the human, agent, or system that produced the event (event-schema field)
- `source` = stable technical URI of the emitting context (deployment-time concern)

### Resolution

**`CloudEventEncodingContext` interface added** (`src/contracts/cloud-events.ts`):

```typescript
export interface CloudEventEncodingContext {
  readonly source: CloudEventSource;
}
```

**`CloudEventEncoder.encode()` signature updated:**

```typescript
encode(
  event: EventInstance,
  context: CloudEventEncodingContext,
): CloudEventEnvelope<EventInstance>;
```

**OEM → CloudEvents field mapping corrected:**

| Source | CloudEventEnvelope field |
|---|---|
| `EventInstance.id` | `id` |
| `EventInstance.event_type` | `type` |
| `EventInstance.work_item_id` | `subject` |
| `CloudEventEncodingContext.source` | `source` (technical producer origin) |
| `EventInstance.timestamp` | `time` |
| `EventInstance` (full record, retains `producer_identity`) | `data` |

`producer_identity` is preserved inside `data` — it is not lost, just not promoted to `source`.

**`CloudEventSource` JSDoc updated:** removed mention of `producer_identity`; replaced with examples of stable technical URIs:
- `prodops://payments-api/github-actions`
- `prodops://payments-api/runtime`
- `prodops://payments-api/human-cli`

**`index.ts` updated:** `CloudEventEncodingContext` added to public exports.

---

## Fix 2 — Event Type format corrected

### Problem

Example event types embedded `EventCategory` as a type segment:

```
Delivery.Hack.Phase Lifecycle.Started   ← WRONG
```

The canonical format is:

```
<Namespace>.<Subject>.<Action>[.<Qualifier>]
```

`EventCategory` is metadata for routing and classification — it is a field on `EventInstance`, not a segment of `event_type`.

### Resolution

All four example files corrected:

| File | Before | After |
|---|---|---|
| `operational-event.example.ts` | `Delivery.Hack.Phase Lifecycle.Started` | `Delivery.Hack.Started` |
| `cloud-event-envelope.example.ts` | `Delivery.Hack.Phase Lifecycle.Started` | `Delivery.Hack.Started` |
| `event-query.example.ts` | `Delivery.Bootstrap.Phase Lifecycle.Started` | `Delivery.Bootstrap.Started` |
| `operational-state-engine.example.ts` | `Delivery.Bootstrap.Phase Lifecycle.Started` | `Delivery.Bootstrap.Started` |

Unused `EventCategory` imports removed from `operational-event.example.ts`, `event-query.example.ts`, and `operational-state-engine.example.ts`.

---

## Files Changed

| File | Change |
|---|---|
| `runtime/sdk/src/contracts/cloud-events.ts` | Added `CloudEventEncodingContext`; updated `CloudEventEncoder.encode()` signature; corrected `CloudEventSource` JSDoc; corrected envelope field mapping comment |
| `runtime/sdk/src/index.ts` | Added `CloudEventEncodingContext` export |
| `runtime/sdk/src/examples/cloud-event-envelope.example.ts` | Use `CloudEventEncodingContext`; fix event type; remove `producer_identity` as source |
| `runtime/sdk/src/examples/operational-event.example.ts` | Fix event type; remove `EventCategory` import |
| `runtime/sdk/src/examples/event-query.example.ts` | Fix event types; remove `EventCategory` import |
| `runtime/sdk/src/examples/operational-state-engine.example.ts` | Fix event types; remove `EventCategory` import |
| `runtime/sdk/README.md` | Added `CloudEventEncodingContext` row; added source vs producer_identity section; corrected field mapping table; added Event Type format section |
| `runtime/sdk/CHANGELOG.md` | Added `### Fixed` block under `[0.1.1]` |

---

## Validation Results

### typecheck

```
cd runtime/sdk && npx tsc --noEmit
Exit: 0
```

### grep — no live producer_identity → source mapping

```bash
grep -Rn "producer_identity.*source\|source.*producer_identity" src/ README.md CHANGELOG.md
```

All matches are explanatory text confirming the separation (e.g. "NOT producer_identity", "never derived from producer_identity"). No live code maps `producer_identity` to `source`. ✅

### grep — no Phase Lifecycle in type strings

```bash
grep -Rn "Phase Lifecycle\.Started\|Phase Lifecycle\.Completed" src/ README.md CHANGELOG.md
```

All matches appear only in documentation sections labeled "WRONG" or "Incorrect". No live event type string contains `Phase Lifecycle`. ✅

---

## Architectural Invariants Verified

| Invariant | Status |
|---|---|
| `CloudEvent.source` = stable technical URI, provided via `CloudEventEncodingContext` | ✅ |
| `producer_identity` preserved in `EventInstance` inside `data` — not promoted to `source` | ✅ |
| Event Type format: `<Namespace>.<Subject>.<Action>[.<Qualifier>]` — no EventCategory segment | ✅ |
| `CloudEventEncodingContext` exported from `index.ts` | ✅ |
| tsc --noEmit Exit 0 | ✅ |
| No RT-01..RT-06 implementations written | ✅ |
| No canonical OEM/COR documents altered | ✅ |
| Git tag `runtime-v0.1.0` not altered | ✅ |
| No commit created | ✅ |

---

## SDK readiness for tag `runtime-v0.1.1`

The SDK is architecturally correct and typecheck-clean. All known inconsistencies between the contract/examples and the consolidated architectural decisions have been resolved. The branch `release/prodops-runtime-pilot` is ready for tagging `runtime-v0.1.1`.
