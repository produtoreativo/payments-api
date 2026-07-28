import type { ProviderStrategy } from '../types.js';

export type { ProviderStrategy };

/**
 * Result of a Strategy Resolver execution.
 * Records which strategy was selected, which were attempted, and why each
 * unavailable strategy was skipped — never falls silently to manual-intervention.
 */
export interface StrategyResolutionResult {
  /** The strategy selected for execution */
  selectedStrategy: ProviderStrategy;
  /** All strategies probed in order, including the selected one */
  attemptedStrategies: ProviderStrategy[];
  /** Strategies probed and found unavailable, with reason */
  unavailableStrategies: Array<{ strategy: ProviderStrategy; reason: string }>;
  /** Why the resolver fell back from the primary strategy, or null if primary was used */
  fallbackReason: string | null;
  /** True only when selectedStrategy === 'manual-intervention' */
  manualRequired: boolean;
}

/** Probe outcome for a single strategy */
export interface ProbeOutcome {
  available: boolean;
  reason: string;
}
