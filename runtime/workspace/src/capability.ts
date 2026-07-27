import { ProjectProvider } from './providers/project.provider.js';
import { FieldProvider } from './providers/field.provider.js';
import { ViewProvider } from './providers/view.provider.js';
import { LabelProvider } from './providers/label.provider.js';
import { MilestoneProvider } from './providers/milestone.provider.js';
import { IterationProvider } from './providers/iteration.provider.js';
import { MembershipProvider } from './providers/membership.provider.js';

export type { ProviderMeta, ProviderStrategy } from './providers/strategy.js';
export type { StrategyResolutionResult } from './strategies/strategy-result.js';

/**
 * WorkspaceManagementCapability
 *
 * Single entry point for all GitHub workspace management responsibilities.
 * Consolidates seven Providers, each with a declared strategy chain.
 * The Strategy Resolver probes capabilities at runtime and selects
 * the first available strategy — the consumer never knows the difference.
 *
 * Strategy chain (ordered preference):
 *   graphql → rest → gh-cli → browser-automation → manual-intervention
 *
 * Provider strategies:
 *   - ProjectProvider      : gh-cli → graphql
 *   - FieldProvider        : gh-cli
 *   - ViewProvider         : graphql → rest → gh-cli → browser-automation → manual
 *   - LabelProvider        : gh-cli → rest
 *   - MilestoneProvider    : rest → gh-cli
 *   - IterationProvider    : manual (TEXT field pattern: delegates to FieldProvider)
 *   - MembershipProvider   : gh-cli → graphql
 *
 * COR invariant:
 *   GitHub Project is a read projection of Derived State.
 *   This Capability materializes and reconciles the COR — it never originates state.
 *   No Journey (Delivery, Diligence) imports from this Capability.
 */
export const WorkspaceManagementCapability = {
  project: ProjectProvider,
  field: FieldProvider,
  view: ViewProvider,
  label: LabelProvider,
  milestone: MilestoneProvider,
  iteration: IterationProvider,
  membership: MembershipProvider,

  allProviders: [
    ProjectProvider,
    MilestoneProvider,
    FieldProvider,
    LabelProvider,
    ViewProvider,
    MembershipProvider,
    IterationProvider,
  ] as const,
} as const;
