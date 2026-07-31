/**
 * Example: Constructing a valid OperationalEvent (EventInstance).
 *
 * Demonstrates how an Event Producer builds an event before publishing.
 * EventId must be a UUID v7 — generation is outside this SDK.
 * Cast `as EventId` in tests/examples; real producers use a uuidv7 library.
 *
 * Event Type format: <Namespace>.<Subject>.<Action>[.<Qualifier>]
 *   'Delivery.Hack.Started'   — correct
 *   'Delivery.Hack.Phase Lifecycle.Started'  — WRONG: Event Category must not appear in type
 *   EventCategory is metadata for routing and classification, not part of the type identifier.
 */
import type { OperationalEvent, EventId } from '../index.js';
import { ProducerType, Phase } from '../index.js';

// In production: import { uuidv7 } from 'uuidv7'; const id = uuidv7() as EventId;
const eventId = '018f7e9a-b5d0-7b4a-8b3e-9a2c1d4e5f6a' as EventId;

const hackStarted: OperationalEvent = {
  id: eventId,
  // Format: <Namespace>.<Subject>.<Action> — Event Category does NOT appear here
  event_type: `Delivery.${Phase.Hack}.Started`,
  work_item_id: 'wf-delivery-0042',
  timestamp: '2026-07-26T09:00:00.000Z',
  producer_type: ProducerType.Agent,
  producer_identity: 'agent:hack-start-agent',
  schema_version: '1.0',
  payload: {
    branch: 'feat/wf-delivery-0042-payment-retry',
  },
};

// OperationalEvent is the domain alias for EventInstance — identical at runtime
const asEventInstance: OperationalEvent = hackStarted;

console.log('event_type:', hackStarted.event_type);
console.log('work_item_id:', hackStarted.work_item_id);
console.log('is same reference:', hackStarted === asEventInstance);
