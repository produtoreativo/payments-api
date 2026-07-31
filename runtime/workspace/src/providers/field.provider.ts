import {
  listFields,
  createField,
  ensureField,
  sanitizeFieldName,
} from '../github/project.js';
import type { ProviderMeta } from './strategy.js';

export const FieldProvider = {
  name: 'FieldProvider' as const,

  meta: {
    providerName: 'FieldProvider',
    strategies: ['gh-cli'] as const,
    autoCorrectPossible: true,
  } satisfies ProviderMeta,

  list: listFields,
  create: createField,
  ensure: ensureField,
  sanitizeName: sanitizeFieldName,
};
