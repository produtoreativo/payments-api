import { findMilestone, ensureMilestone, listMilestones } from '../github/milestone.js';
import type { ProviderMeta } from './strategy.js';

export const MilestoneProvider = {
  name: 'MilestoneProvider' as const,

  meta: {
    providerName: 'MilestoneProvider',
    strategies: ['rest', 'gh-cli'] as const,
    autoCorrectPossible: true,
  } satisfies ProviderMeta,

  list: listMilestones,
  find: findMilestone,
  ensure: ensureMilestone,
};
