import type { ProviderStrategy } from '../types.js';

export type { ProviderStrategy };

/**
 * Canonical metadata all Workspace Providers must declare.
 *
 * `strategies` replaces the old static `strategyUsed / alternativeStrategy` pair
 * with an ordered chain. The Strategy Resolver probes each in order and selects
 * the first available strategy at runtime.
 *
 * `autoCorrectPossible` reflects whether any strategy in the chain (other than
 * manual-intervention) can programmatically fix a detected drift.
 */
export interface ProviderMeta {
  providerName: string;
  /** Ordered strategy preference chain — Resolver selects first available */
  strategies: ReadonlyArray<ProviderStrategy>;
  /** True if at least one non-manual strategy in the chain can correct drifts */
  autoCorrectPossible: boolean;
}

/**
 * Returns the first (primary) strategy in the chain.
 * Used when static metadata is needed without running the Resolver.
 */
export function primaryStrategy(meta: ProviderMeta): ProviderStrategy {
  return meta.strategies[0] ?? 'manual-intervention';
}

/**
 * Returns the second strategy in the chain, or null if only one strategy declared.
 * Used to populate DriftItem.alternativeStrategy for backward compatibility.
 */
export function alternativeStrategy(meta: ProviderMeta): ProviderStrategy | null {
  return meta.strategies[1] ?? null;
}
