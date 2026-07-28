import type { OperationalEvent, ValidationResult } from '@prodops/runtime-sdk';
import { ProducerType } from '@prodops/runtime-sdk';

// UUID v7: version nibble = 7, variant bits = [89ab]
const UUID_V7_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

// Minimum 3 dot-separated non-empty segments: Namespace.Subject.Action
const EVENT_TYPE_RE = /^[^.\s][^.]*(\.[^.\s][^.]*){2,}$/;

const VALID_PRODUCER_TYPES = new Set<string>(Object.values(ProducerType));

function isValidIso8601(value: string): boolean {
  return !isNaN(new Date(value).getTime());
}

/**
 * Validates a single OperationalEvent for structural and semantic correctness.
 * Pure function — no external I/O.
 */
export function validateEvent(event: OperationalEvent): ValidationResult {
  const violations: string[] = [];

  if (!event.id) {
    violations.push('id is required');
  } else if (!UUID_V7_RE.test(event.id)) {
    violations.push(
      `id must be UUID v7 (xxxxxxxx-xxxx-7xxx-[89ab]xxx-xxxxxxxxxxxx), got: "${event.id}"`,
    );
  }

  if (!event.event_type) {
    violations.push('event_type is required');
  } else if (!EVENT_TYPE_RE.test(event.event_type)) {
    violations.push(
      `event_type must follow <Namespace>.<Subject>.<Action>[.<Qualifier>] (min 3 segments), got: "${event.event_type}"`,
    );
  }

  if (!event.timestamp) {
    violations.push('timestamp is required');
  } else if (!isValidIso8601(event.timestamp)) {
    violations.push(`timestamp must be ISO-8601, got: "${event.timestamp}"`);
  }

  if (!event.work_item_id || event.work_item_id.trim() === '') {
    violations.push('work_item_id is required and must not be blank');
  }

  if (!event.schema_version || event.schema_version.trim() === '') {
    violations.push('schema_version is required and must not be blank');
  }

  if (!VALID_PRODUCER_TYPES.has(event.producer_type as string)) {
    violations.push(
      `producer_type must be one of: ${[...VALID_PRODUCER_TYPES].join(', ')}, got: "${event.producer_type}"`,
    );
  }

  if (!event.producer_identity || event.producer_identity.trim() === '') {
    violations.push('producer_identity is required and must not be blank');
  }

  return { valid: violations.length === 0, violations };
}
