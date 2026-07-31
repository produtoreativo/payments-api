import type { CloudEventEnvelope } from './cloud-events.js';
import type { EventInstance } from '../models/event-instance.js';
/**
 * Transport-layer contract for publishing CloudEvent envelopes to the event store.
 * Implemented by RT-04 (Datadog Adapter). Has no dependency on Datadog internals.
 *
 * Separation of concerns:
 *   EventProducer → creates and validates EventInstance
 *   CloudEventEncoder → wraps EventInstance in CloudEventEnvelope
 *   EventPublisher → sends CloudEventEnvelope to the transport (this interface)
 */
export interface EventPublisher {
    publish(envelope: CloudEventEnvelope<EventInstance>): Promise<void>;
}
//# sourceMappingURL=event-publisher.d.ts.map