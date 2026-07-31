import {
  addIssueToProject,
  listProjectItems,
  setItemField,
} from '../github/project.js';
import type { ProviderMeta } from './strategy.js';

export const MembershipProvider = {
  name: 'MembershipProvider' as const,

  meta: {
    providerName: 'MembershipProvider',
    strategies: ['gh-cli', 'graphql'] as const,
    autoCorrectPossible: true,
  } satisfies ProviderMeta,

  listItems: listProjectItems,
  addToProject: addIssueToProject,
  setField: setItemField,
};
