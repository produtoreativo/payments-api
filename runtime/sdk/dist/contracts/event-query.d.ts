import type { EventInstance } from '../models/event-instance.js';
export interface EventQueryOptions {
    readonly from?: string;
    readonly to?: string;
    readonly limit?: number;
    readonly cursor?: string;
}
export interface EventQueryResult {
    readonly events: ReadonlyArray<EventInstance>;
    readonly nextCursor?: string;
    readonly total?: number;
}
/**
 * Queries Operational Events from the event store by Work Item.
 * Implemented by RT-04 (Datadog Adapter). Order is deterministic (timestamp ASC, sequence_number ASC).
 * The event store (Datadog) is the authoritative source — the Timeline is reconstructed from these events.
 */
export interface EventQuery {
    queryByWorkItem(workItemId: string, options?: EventQueryOptions): Promise<EventQueryResult>;
}
//# sourceMappingURL=event-query.d.ts.map