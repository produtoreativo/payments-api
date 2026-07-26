import type { EventInstance } from '../models/event-instance.js';
import type { DerivedState } from '../models/derived-state.js';
/**
 * A set of observability tags derived from OEM data.
 * Keys: lowercase + snake_case (e.g., 'work_item_id', 'journey', 'phase').
 *
 * Tag rules (not enforced at type level — runtime responsibility of the adapter):
 *   - Keys: lowercase + snake_case only
 *   - High-cardinality IDs (e.g., work_item_id, event id) are NOT tags — they are indexed fields
 *   - env, service, version belong to the observability backend configuration, not to TagSet
 */
export interface TagSet {
    readonly tags: Readonly<Record<string, string>>;
}
/**
 * Projects OEM data into observability tags for the metrics backend.
 * Implemented by RT-04 (Datadog Adapter). Tags are derived by the adapter, NOT stored
 * in EventInstance or DerivedState — they are computed at publish time.
 */
export interface TagProjection {
    fromEvent(event: EventInstance): TagSet;
    fromState(state: DerivedState): TagSet;
}
//# sourceMappingURL=tag-projection.d.ts.map