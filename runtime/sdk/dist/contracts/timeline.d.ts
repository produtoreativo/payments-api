import type { EventInstance } from '../models/event-instance.js';
import type { DerivedState } from '../models/derived-state.js';
import type { TimelineState } from '../models/timeline-state.js';
/**
 * Read-only view of a Work Item's Operational Timeline, reconstructed from the event store.
 * The Timeline is NOT stored — it is rebuilt by querying EventQuery and processing via OperationalStateEngine.
 * Implemented by RT-02 (Timeline Processor).
 *
 * BREAKING CHANGE (v0.1.0 reconciliation): `append()` removed. Publishing is the
 * responsibility of EventProducer + CloudEventEncoder + EventPublisher, not the Timeline.
 */
export interface Timeline {
    replay(workItemId: string): Promise<ReadonlyArray<EventInstance>>;
    replayUntil(workItemId: string, timestamp: string): Promise<ReadonlyArray<EventInstance>>;
    currentState(workItemId: string): Promise<DerivedState | null>;
    lookback(workItemId: string, until: string | {
        readonly eventId: string;
    }): Promise<DerivedState | null>;
    history(workItemId: string): Promise<TimelineState>;
}
//# sourceMappingURL=timeline.d.ts.map