import type { ProviderMeta } from './strategy.js';

/**
 * IterationProvider — manages iteration tracking in GitHub ProjectsV2.
 *
 * ## Decision: IP-001 uses a TEXT field, not a native GitHub Iteration field
 *
 * In the Operational Pilot (IP-001), iteration identity is stored in the
 * `witem:iteration` TEXT custom field (e.g., value = "IP-001"). This field
 * is created and managed by FieldProvider, and its values are set by
 * MembershipProvider.setField() via GraphQL.
 *
 * GitHub Projects v2 also has a native "Iteration" field type (sprint cycles
 * with start/end dates). The pilot does NOT use this native Iteration field —
 * `witem:iteration` is a plain TEXT field that records the iteration ID string.
 *
 * Therefore, for the current pilot scope:
 *   - Iteration field creation → FieldProvider (type: TEXT)
 *   - Iteration field value setting → MembershipProvider.setField()
 *   - IterationProvider has no active operations
 *
 * ## Future: native GitHub Iteration field
 *
 * If the pilot evolves to use GitHub's native Iteration field type (with sprint
 * dates and cycle management), IterationProvider would be upgraded to implement
 * Strategy Resolution for creating/managing sprint cycles. The GitHub Projects v2
 * public API does not currently expose a mutation for creating iteration cycles —
 * they must be created via the UI, making the strategy 'manual-intervention'.
 *
 * Upgrade path when native Iteration field is needed:
 *   1. Change strategy from 'manual-intervention' to ['graphql', 'manual-intervention']
 *   2. Implement probe for the iteration mutation (once GitHub exposes it)
 *   3. Remove this comment
 */
export const IterationProvider = {
  name: 'IterationProvider' as const,

  meta: {
    providerName: 'IterationProvider',
    strategies: ['manual-intervention'] as const,
    autoCorrectPossible: false,
  } satisfies ProviderMeta,

  /**
   * Returns true if the workspace config uses plain TEXT field for iteration
   * (the current pilot pattern). In this case, IterationProvider defers to
   * FieldProvider for field management and MembershipProvider for value setting.
   */
  isTextFieldPattern(): boolean {
    return true; // IP-001 confirmed: witem:iteration is a TEXT field
  },
};
