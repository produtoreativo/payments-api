import type { ProviderStrategy } from '../types.js';
import type { StrategyResolutionResult } from './strategy-result.js';
import { probeGraphQL, probeREST, probeGhCLI, probeBrowser } from './capability-probe.js';

/**
 * Probe configuration per strategy type.
 * Pass only the strategies your Provider supports.
 */
export interface ResolverProbeConfig {
  graphql?: { mutationName: string };
  rest?: { endpoint: string; method?: string };
  ghCli?: { subcommand: string };
  /** browser-automation is probed automatically (GH_BROWSER_AUTH_STATE + playwright) */
  browser?: true;
}

/**
 * Strategy Resolver — selects and executes the first available strategy from the chain.
 *
 * Algorithm:
 *   For each strategy in `strategies` (ordered preference):
 *     1. Run the probe (no side effects)
 *     2. If available → return resolution result
 *     3. If unavailable → record reason, continue
 *
 * Never falls silently to manual-intervention: all skipped strategies are recorded
 * with explicit reasons in `unavailableStrategies`.
 */
export function resolveStrategy(
  strategies: ReadonlyArray<ProviderStrategy>,
  probeConfig: ResolverProbeConfig
): StrategyResolutionResult {
  const attempted: ProviderStrategy[] = [];
  const unavailable: Array<{ strategy: ProviderStrategy; reason: string }> = [];

  for (const strategy of strategies) {
    attempted.push(strategy);

    const probe = runProbe(strategy, probeConfig);

    if (probe.available) {
      const fallbackReason =
        unavailable.length > 0
          ? `Fell back from: ${unavailable.map((u) => u.strategy).join(' → ')}. ` +
            `Last reason: ${unavailable.at(-1)?.reason ?? ''}`
          : null;

      return {
        selectedStrategy: strategy,
        attemptedStrategies: attempted,
        unavailableStrategies: unavailable,
        fallbackReason,
        manualRequired: strategy === 'manual-intervention',
      };
    }

    unavailable.push({ strategy, reason: probe.reason });
  }

  // Safety: if the caller omitted 'manual-intervention' from the chain and all probes failed
  return {
    selectedStrategy: 'manual-intervention',
    attemptedStrategies: attempted,
    unavailableStrategies: unavailable,
    fallbackReason: `All ${attempted.length} strategies unavailable — defaulting to manual intervention`,
    manualRequired: true,
  };
}

function runProbe(
  strategy: ProviderStrategy,
  config: ResolverProbeConfig
): { available: boolean; reason: string } {
  switch (strategy) {
    case 'graphql':
      return config.graphql
        ? probeGraphQL(config.graphql.mutationName)
        : { available: false, reason: 'No GraphQL probe config provided for this operation' };

    case 'rest':
      return config.rest
        ? probeREST(config.rest.endpoint, config.rest.method)
        : { available: false, reason: 'No REST probe config provided for this operation' };

    case 'gh-cli':
      return config.ghCli
        ? probeGhCLI(config.ghCli.subcommand)
        : { available: false, reason: 'No gh CLI probe config provided for this operation' };

    case 'browser-automation':
      return probeBrowser();

    case 'manual-intervention':
      return { available: true, reason: 'Manual intervention: always available as last resort' };

    default: {
      const _exhaustive: never = strategy;
      return { available: false, reason: `Unknown strategy: ${String(_exhaustive)}` };
    }
  }
}
