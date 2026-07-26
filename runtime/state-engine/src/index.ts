// Main engine class
export { OemOperationalStateEngine } from './state-engine.js';

// Extended types (beyond SDK contract)
export type {
  ExtendedStateHistory,
  ExtendedStateHistoryEntry,
  EffectiveOperationalState,
} from './history.js';

// Utilities (exposed for testing and downstream consumers)
export { validateEvent } from './validation.js';
export { deduplicateEvents, orderEvents } from './ordering.js';
export { applyCorrections, isCorrectionEvent, getCorrectedEventId } from './corrections.js';
export { computeDerivedState, parseEventType } from './derived-state.js';
export type { EventTypeParts } from './derived-state.js';
export { prepareStream, replayPrepared, replayRaw, replayUntilPrepared } from './replay.js';
export { lookback } from './lookback.js';
export { buildStateHistory, buildExtendedHistory, buildEffectiveState } from './history.js';
