import { listLabels, ensureLabel } from '../github/labels.js';
import type { ProviderMeta } from './strategy.js';

export const LabelProvider = {
  name: 'LabelProvider' as const,

  meta: {
    providerName: 'LabelProvider',
    strategies: ['gh-cli', 'rest'] as const,
    autoCorrectPossible: true,
  } satisfies ProviderMeta,

  list: listLabels,
  ensure: ensureLabel,
};
