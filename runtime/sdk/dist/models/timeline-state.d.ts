import type { EventInstance } from './event-instance.js';
import type { DerivedState } from './derived-state.js';
export interface TimelineState {
    readonly work_item_id: string;
    readonly events: ReadonlyArray<EventInstance>;
    readonly derived_state: DerivedState | null;
    readonly event_count: number;
    readonly first_event_at?: string;
    readonly last_event_at?: string;
}
//# sourceMappingURL=timeline-state.d.ts.map