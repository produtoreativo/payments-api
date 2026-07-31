import {
  findProject,
  createProject,
  ensureProject,
  listProjects,
} from '../github/project.js';
import type { ProviderMeta } from './strategy.js';

export const ProjectProvider = {
  name: 'ProjectProvider' as const,

  meta: {
    providerName: 'ProjectProvider',
    strategies: ['gh-cli', 'graphql'] as const,
    autoCorrectPossible: true,
  } satisfies ProviderMeta,

  list: listProjects,
  find: findProject,
  create: createProject,
  ensure: ensureProject,
};
