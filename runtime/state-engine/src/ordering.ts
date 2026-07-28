import type { OperationalEvent } from '@prodops/runtime-sdk';

/**
 * Removes duplicate events by id. First occurrence wins. Input not mutated.
 * Idempotent — safe to call multiple times on the same stream.
 */
export function deduplicateEvents(
  events: ReadonlyArray<OperationalEvent>,
): ReadonlyArray<OperationalEvent> {
  const seen = new Set<string>();
  return events.filter((e) => {
    if (seen.has(e.id)) return false;
    seen.add(e.id);
    return true;
  });
}

/**
 * Sorts events deterministically and stably by:
 *   1. timestamp (ISO-8601 lexicographic — equivalent to chronological for UTC)
 *   2. sequence_number (ascending; events without a sequence_number sort last)
 *   3. id (UUID v7 lexicographic — time-ordered, so a valid tiebreaker)
 *
 * Tie-breaking rationale:
 *   Two events with identical timestamps and no sequence_number are rare but valid
 *   (e.g. bulk correction imports). UUID v7 ordering is used as a stable last resort.
 *   The caller should assign sequence_numbers to events expected to be co-temporal.
 *
 * Input not mutated. Uses Array.sort() which is stable in Node ≥ 11.
 */
export function orderEvents(
  events: ReadonlyArray<OperationalEvent>,
): ReadonlyArray<OperationalEvent> {
  return [...events].sort((a, b) => {
    const tA = a.timestamp;
    const tB = b.timestamp;
    if (tA < tB) return -1;
    if (tA > tB) return 1;

    const sA = a.sequence_number ?? Number.MAX_SAFE_INTEGER;
    const sB = b.sequence_number ?? Number.MAX_SAFE_INTEGER;
    if (sA !== sB) return sA - sB;

    return a.id < b.id ? -1 : a.id > b.id ? 1 : 0;
  });
}
