import type { OperationalEvent, DerivedState } from '@prodops/runtime-sdk';
import { deduplicateEvents, orderEvents } from './ordering.js';
import { applyCorrections } from './corrections.js';
import { computeDerivedState } from './derived-state.js';

/**
 * Canonical preparation pipeline: dedup → order → corrections.
 * Applied before any replay operation when working on a raw event stream.
 * This function is exposed so callers can inspect the prepared stream.
 */
export function prepareStream(
  rawEvents: ReadonlyArray<OperationalEvent>,
): ReadonlyArray<OperationalEvent> {
  return applyCorrections(orderEvents(deduplicateEvents(rawEvents)));
}

/**
 * Replays a prepared event stream and returns the resulting DerivedState.
 *
 * Pre-condition: events are already ordered, deduplicated, corrections applied.
 * Use prepareStream() first when working with a raw Timeline.
 */
export function replayPrepared(
  events: ReadonlyArray<OperationalEvent>,
): DerivedState | null {
  return computeDerivedState(events);
}

/**
 * Replays all events in a raw stream (applies full pipeline internally).
 * Convenience wrapper for direct raw-stream replay.
 */
export function replayRaw(
  rawEvents: ReadonlyArray<OperationalEvent>,
): DerivedState | null {
  return computeDerivedState(prepareStream(rawEvents));
}

/**
 * Replays a prepared event stream up to and including `until` (ISO-8601 timestamp).
 *
 * Events with timestamp > `until` are excluded.
 * Corrections are applied only within the filtered set (strict temporal semantics:
 * "what was the state AT time T, knowing only events known at T").
 *
 * Pre-condition: events are ordered (so filter is efficient).
 */
export function replayUntilPrepared(
  events: ReadonlyArray<OperationalEvent>,
  until: string,
): DerivedState | null {
  const filtered = events.filter((e) => e.timestamp <= until);
  return computeDerivedState(filtered);
}
