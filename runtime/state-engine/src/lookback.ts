import type { OperationalEvent, DerivedState } from '@prodops/runtime-sdk';
import { deduplicateEvents, orderEvents } from './ordering.js';
import { applyCorrections } from './corrections.js';
import { computeDerivedState } from './derived-state.js';

/**
 * Computes the DerivedState as of a given timestamp reference.
 *
 * The lookback is temporally strict: only events with timestamp ≤ reference are
 * included, so corrections that arrive after the reference are NOT applied.
 * This answers "what was the operational state AT time T?"
 *
 * The Timeline is not mutated — lookback operates on a filtered view.
 *
 * Resolution during lookback:
 *   - Impediment.Resolved  → restored if both Raised and Resolved are ≤ reference
 *   - Rework.Completed     → restored if both Started and Completed are ≤ reference
 *   - Event.Corrected      → applied if both original and correction are ≤ reference
 *
 * @param events  Raw event stream (not required to be pre-sorted or deduplicated)
 * @param reference  ISO-8601 timestamp — inclusive upper bound
 */
export function lookback(
  events: ReadonlyArray<OperationalEvent>,
  reference: string,
): DerivedState | null {
  // Apply full pipeline on the temporally-bounded stream
  const deduped = deduplicateEvents(events);
  const ordered = orderEvents(deduped);
  const bounded = ordered.filter((e) => e.timestamp <= reference);
  const prepared = applyCorrections(bounded);
  return computeDerivedState(prepared);
}
