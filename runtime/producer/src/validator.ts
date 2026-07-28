import type { OperationalEvent } from '@prodops/runtime-sdk';
import { ProducerType } from '@prodops/runtime-sdk';

export interface ProducerValidationResult {
  readonly valid: boolean;
  readonly violations: ReadonlyArray<string>;
}

// UUID v7: time_high = 0x7xxx, variant = [89ab]xxx
const UUID_V7_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

// Minimum: <Namespace>.<Subject>.<Action> — 3+ non-empty dot-separated segments
const EVENT_TYPE_RE = /^[^.\s][^.]*(\.[^.\s][^.]*){2,}$/;

const VALID_PRODUCER_TYPES = new Set<string>(Object.values(ProducerType));

function isValidIso8601(value: string): boolean {
  const d = new Date(value);
  return !isNaN(d.getTime());
}

/**
 * Validates an OperationalEvent before encoding and publishing.
 * Pure function — no external I/O.
 */
export function validateOperationalEvent(event: OperationalEvent): ProducerValidationResult {
  const violations: string[] = [];

  // EventId — UUID v7 format
  if (!event.id) {
    violations.push('id is required');
  } else if (!UUID_V7_RE.test(event.id)) {
    violations.push(`id must be UUID v7 format (xxxxxxxx-xxxx-7xxx-[89ab]xxx-xxxxxxxxxxxx), got: "${event.id}"`);
  }

  // EventType — <Namespace>.<Subject>.<Action>[.<Qualifier>]
  if (!event.event_type) {
    violations.push('event_type is required');
  } else if (!EVENT_TYPE_RE.test(event.event_type)) {
    violations.push(
      `event_type must follow <Namespace>.<Subject>.<Action>[.<Qualifier>] format (min 3 segments), got: "${event.event_type}"`,
    );
  }

  // Timestamp — ISO-8601
  if (!event.timestamp) {
    violations.push('timestamp is required');
  } else if (!isValidIso8601(event.timestamp)) {
    violations.push(`timestamp must be a valid ISO-8601 datetime, got: "${event.timestamp}"`);
  }

  // WorkItemId
  if (!event.work_item_id || event.work_item_id.trim() === '') {
    violations.push('work_item_id is required and must not be blank');
  }

  // SchemaVersion
  if (!event.schema_version || event.schema_version.trim() === '') {
    violations.push('schema_version is required and must not be blank');
  }

  // ProducerType
  if (!VALID_PRODUCER_TYPES.has(event.producer_type as string)) {
    violations.push(
      `producer_type must be one of: ${[...VALID_PRODUCER_TYPES].join(', ')}, got: "${event.producer_type}"`,
    );
  }

  // ProducerIdentity
  if (!event.producer_identity || event.producer_identity.trim() === '') {
    violations.push('producer_identity is required and must not be blank');
  }

  return { valid: violations.length === 0, violations };
}
