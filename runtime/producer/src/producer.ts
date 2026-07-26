import type {
  OperationalEvent,
  CloudEventEnvelope,
  CloudEventEncoder,
  CloudEventEncodingContext,
  EventPublisher,
} from '@prodops/runtime-sdk';
import { validateOperationalEvent } from './validator.js';

export class ProducerValidationError extends Error {
  readonly violations: ReadonlyArray<string>;

  constructor(violations: ReadonlyArray<string>) {
    super(
      `Operational Event validation failed:\n${violations.map((v) => `  - ${v}`).join('\n')}`,
    );
    this.name = 'ProducerValidationError';
    this.violations = violations;
  }
}

export interface OperationalEventProducerOptions {
  /** Encodes OperationalEvent → CloudEventEnvelope. Use OemCloudEventEncoder. */
  readonly encoder: CloudEventEncoder;
  /** Transport adapter. Implemented by RT-04 (Datadog) or any compatible sink. */
  readonly publisher: EventPublisher;
  /** Deployment-time source URI. Never derived from producer_identity. */
  readonly context: CloudEventEncodingContext;
}

/**
 * RT-01 — Operational Event Producer.
 *
 * Orchestrates the full production pipeline:
 *   1. validate(event)          — structural + semantic checks
 *   2. encoder.encode(event, ctx) — OEM → CloudEvents 1.0 envelope
 *   3. publisher.publish(envelope) — hand off to transport layer
 *
 * Does NOT:
 *   - Connect to Datadog directly
 *   - Interact with GitHub
 *   - Execute Replay or Timeline reconstruction
 *   - Calculate metrics
 */
export class OperationalEventProducer {
  private readonly encoder: CloudEventEncoder;
  private readonly publisher: EventPublisher;
  private readonly context: CloudEventEncodingContext;

  constructor(options: OperationalEventProducerOptions) {
    this.encoder = options.encoder;
    this.publisher = options.publisher;
    this.context = options.context;
  }

  /**
   * Validates, encodes, and publishes an OperationalEvent.
   * Returns the generated CloudEventEnvelope for inspection or logging.
   * Throws ProducerValidationError if the event fails validation.
   */
  async publish(event: OperationalEvent): Promise<CloudEventEnvelope<OperationalEvent>> {
    const result = validateOperationalEvent(event);
    if (!result.valid) {
      throw new ProducerValidationError(result.violations);
    }

    const envelope = this.encoder.encode(event, this.context);
    await this.publisher.publish(envelope);
    return envelope as CloudEventEnvelope<OperationalEvent>;
  }
}
