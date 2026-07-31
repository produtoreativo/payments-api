import type { EventInstance } from '../models/event-instance.js';
export interface EventProducer {
    publish(event: EventInstance): Promise<void>;
}
//# sourceMappingURL=event-producer.d.ts.map