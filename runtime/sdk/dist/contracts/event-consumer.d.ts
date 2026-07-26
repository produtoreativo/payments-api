import type { EventInstance } from '../models/event-instance.js';
import type { ConsumerType } from '../enums/consumer.js';
export interface EventConsumer {
    readonly consumerType: ConsumerType;
    consume(event: EventInstance): Promise<void>;
}
//# sourceMappingURL=event-consumer.d.ts.map