import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import type {
  OperationalEvent,
  EventId,
  CloudEventSource,
  CloudEventEncodingContext,
  CloudEventEnvelope,
  EventInstance,
  EventPublisher,
} from '@prodops/runtime-sdk';
import { ProducerType } from '@prodops/runtime-sdk';
import { OemCloudEventEncoder } from '../src/encoder.js';
import { OperationalEventProducer, ProducerValidationError } from '../src/producer.js';

const SOURCE = 'prodops://payments-api/runtime' as CloudEventSource;
const VALID_UUID_V7 = '018f7e9a-b5d0-7b4a-8b3e-9a2c1d4e5f6a' as EventId;

function validEvent(): OperationalEvent {
  return {
    id: VALID_UUID_V7,
    event_type: 'Delivery.Hack.Started',
    work_item_id: 'wf-delivery-0042',
    timestamp: '2026-07-26T09:00:00.000Z',
    producer_type: ProducerType.Agent,
    producer_identity: 'agent:hack-start-agent',
    schema_version: '1.0',
  };
}

function makePublisherSpy(): {
  publisher: EventPublisher;
  captured: CloudEventEnvelope<EventInstance>[];
} {
  const captured: CloudEventEnvelope<EventInstance>[] = [];
  const publisher: EventPublisher = {
    async publish(envelope: CloudEventEnvelope<EventInstance>): Promise<void> {
      captured.push(envelope);
    },
  };
  return { publisher, captured };
}

function makeProducer(publisher: EventPublisher): OperationalEventProducer {
  const context: CloudEventEncodingContext = { source: SOURCE };
  return new OperationalEventProducer({
    encoder: new OemCloudEventEncoder(),
    publisher,
    context,
  });
}

describe('OperationalEventProducer', () => {
  describe('happy path', () => {
    it('publishes a valid event and returns the envelope', async () => {
      const { publisher, captured } = makePublisherSpy();
      const producer = makeProducer(publisher);
      const event = validEvent();

      const envelope = await producer.publish(event);

      assert.equal(captured.length, 1);
      assert.equal(envelope.id, event.id);
      assert.equal(envelope.type, event.event_type);
      assert.equal(envelope.source, SOURCE);
      assert.equal(envelope.subject, event.work_item_id);
    });

    it('passes the generated envelope to the publisher', async () => {
      const { publisher, captured } = makePublisherSpy();
      const producer = makeProducer(publisher);

      const envelope = await producer.publish(validEvent());

      assert.deepEqual(captured[0], envelope);
    });

    it('source in envelope is context.source, not producer_identity', async () => {
      const { publisher } = makePublisherSpy();
      const producer = makeProducer(publisher);
      const event = validEvent();

      const envelope = await producer.publish(event);

      assert.equal(envelope.source, SOURCE);
      assert.notEqual(envelope.source, event.producer_identity as string);
    });

    it('preserves producer_identity inside envelope.data', async () => {
      const { publisher } = makePublisherSpy();
      const producer = makeProducer(publisher);
      const event = validEvent();

      const envelope = await producer.publish(event);

      assert.equal(envelope.data?.producer_identity, event.producer_identity);
    });
  });

  describe('validation failures', () => {
    it('throws ProducerValidationError for an invalid UUID id', async () => {
      const { publisher } = makePublisherSpy();
      const producer = makeProducer(publisher);
      const event = { ...validEvent(), id: 'not-a-uuid' as EventId };

      await assert.rejects(
        () => producer.publish(event),
        (err: unknown) => {
          assert.ok(err instanceof ProducerValidationError);
          assert.ok(err.violations.some((v) => v.includes('id')));
          return true;
        },
      );
    });

    it('throws ProducerValidationError for invalid event_type', async () => {
      const { publisher } = makePublisherSpy();
      const producer = makeProducer(publisher);
      const event = { ...validEvent(), event_type: 'Delivery.Hack' };

      await assert.rejects(() => producer.publish(event), ProducerValidationError);
    });

    it('throws ProducerValidationError for invalid timestamp', async () => {
      const { publisher } = makePublisherSpy();
      const producer = makeProducer(publisher);
      const event = { ...validEvent(), timestamp: 'not-a-date' };

      await assert.rejects(() => producer.publish(event), ProducerValidationError);
    });

    it('throws ProducerValidationError for blank producer_identity', async () => {
      const { publisher } = makePublisherSpy();
      const producer = makeProducer(publisher);
      const event = { ...validEvent(), producer_identity: '' };

      await assert.rejects(() => producer.publish(event), ProducerValidationError);
    });

    it('does NOT call publisher.publish when validation fails', async () => {
      const { publisher, captured } = makePublisherSpy();
      const producer = makeProducer(publisher);
      const event = { ...validEvent(), id: 'bad-uuid' as EventId };

      await assert.rejects(() => producer.publish(event));
      assert.equal(captured.length, 0);
    });

    it('ProducerValidationError.violations contains all failures', async () => {
      const { publisher } = makePublisherSpy();
      const producer = makeProducer(publisher);
      const event = {
        ...validEvent(),
        id: 'bad' as EventId,
        event_type: 'OnlyOneSegment',
        timestamp: 'nope',
      };

      await assert.rejects(
        () => producer.publish(event),
        (err: unknown) => {
          assert.ok(err instanceof ProducerValidationError);
          assert.ok(err.violations.length >= 2);
          return true;
        },
      );
    });
  });

  describe('publisher behavior', () => {
    it('awaits publisher completion before returning envelope', async () => {
      const order: string[] = [];
      const publisher: EventPublisher = {
        async publish(): Promise<void> {
          await new Promise<void>((resolve) => setTimeout(resolve, 5));
          order.push('published');
        },
      };
      const producer = makeProducer(publisher);

      await producer.publish(validEvent());
      order.push('returned');

      assert.deepEqual(order, ['published', 'returned']);
    });

    it('propagates publisher errors to the caller', async () => {
      const publisher: EventPublisher = {
        async publish(): Promise<void> {
          throw new Error('transport failure');
        },
      };
      const producer = makeProducer(publisher);

      await assert.rejects(
        () => producer.publish(validEvent()),
        (err: unknown) => {
          assert.ok(err instanceof Error);
          assert.ok((err as Error).message.includes('transport failure'));
          return true;
        },
      );
    });
  });
});
