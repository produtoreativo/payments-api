import type { OperationalEvent } from '@prodops/runtime-sdk';

/**
 * A correction event has Action = 'Corrected' in its event_type.
 * Its payload must contain corrected_event_id pointing to the superseded event.
 *
 * Canonical type: <Namespace>.Event.Corrected
 * Example:        Delivery.Event.Corrected
 *
 * The correction event itself remains in the stream — it is the new truth.
 * Only the superseded (original) event is removed from the effective stream.
 *
 * The Timeline is append-only: corrections are never applied by mutating stored events.
 * They are applied during Replay by filtering the effective stream.
 */
export function isCorrectionEvent(event: OperationalEvent): boolean {
  const parts = event.event_type.split('.');
  return parts.length >= 3 && parts[2] === 'Corrected';
}

/**
 * Returns the event id targeted by a correction event.
 * Returns undefined if the correction event has no corrected_event_id in payload.
 */
export function getCorrectedEventId(event: OperationalEvent): string | undefined {
  if (!isCorrectionEvent(event)) return undefined;
  const id = event.payload?.corrected_event_id;
  return typeof id === 'string' && id !== '' ? id : undefined;
}

/**
 * Applies Event.Corrected records to produce the effective event stream.
 *
 * Rules:
 *   - Correction events remain in the output (they contribute state context).
 *   - Events superseded by a correction event (via corrected_event_id) are removed.
 *   - The Timeline is not mutated — only the view used for Replay is filtered.
 *   - Input not mutated. Idempotent.
 *
 * Note: corrections that happen AFTER a `replayUntil` boundary are not applied
 * for that lookback (strict temporal semantics — "what was known at time T").
 */
export function applyCorrections(
  events: ReadonlyArray<OperationalEvent>,
): ReadonlyArray<OperationalEvent> {
  const superseded = new Set<string>();

  for (const event of events) {
    const correctedId = getCorrectedEventId(event);
    if (correctedId) superseded.add(correctedId);
  }

  return events.filter((e) => !superseded.has(e.id));
}
