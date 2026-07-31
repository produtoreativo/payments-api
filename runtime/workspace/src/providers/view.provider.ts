import { listViews } from '../github/project.js';
import { ensureViewViaBrowser } from '../github/views.browser.js';
import { createOrganizationProjectView, ViewRESTError } from '../github/views.rest.js';
import { resolveStrategy } from '../strategies/resolver.js';
import type { ResolverProbeConfig } from '../strategies/resolver.js';
import type { ProviderMeta } from './strategy.js';
import type { ViewConfig, ViewConformance } from '../types.js';
import type { StrategyResolutionResult } from '../strategies/strategy-result.js';

/**
 * ViewProvider — manages GitHub ProjectsV2 views using Strategy Resolution.
 *
 * Strategy chain for CREATE operations (ordered):
 *   1. rest              → POST /orgs/{org}/projectsV2/{number}/views (official REST API)
 *   2. browser-automation → Playwright + GH_BROWSER_AUTH_STATE (fallback if REST fails)
 *   3. manual-intervention → always available as last resort
 *
 * GraphQL is used for LIST operations only (query ProjectV2.views is available;
 * createProjectV2View mutation is absent from the public API schema).
 *
 * Probe for REST availability: GET /orgs/{org}/projectsV2/{number} (non-destructive).
 * Returns HTTP 200 when project is accessible and token has project scope.
 */

const CREATE_STRATEGIES = ['rest', 'browser-automation', 'manual-intervention'] as const;

/** Build probe config for a specific project — non-destructive GET on the project resource. */
function makeProbeConfig(owner: string, projectNumber: number): ResolverProbeConfig {
  return {
    rest: { endpoint: `/orgs/${owner}/projectsV2/${projectNumber}`, method: 'GET' },
    browser: true,
  };
}

export interface ViewEnsureResult {
  name: string;
  alreadyExisted: boolean;
  created: boolean;
  resolution: StrategyResolutionResult;
}

export interface ViewValidationResult {
  name: string;
  /** Whether the view was found in the project at all */
  exists: boolean;
  conformance: ViewConformance;
  layoutMatch: boolean | 'unverifiable';
  filterMatch: boolean | 'unverifiable';
  groupByMatch: boolean | 'unverifiable';
  resolution: StrategyResolutionResult;
}

export const ViewProvider = {
  name: 'ViewProvider' as const,

  meta: {
    providerName: 'ViewProvider',
    strategies: CREATE_STRATEGIES,
    autoCorrectPossible: true,
  } satisfies ProviderMeta,

  list: listViews,

  /**
   * Ensures a view exists in the project.
   * Idempotent: returns immediately if view already exists.
   * Create strategy chain: REST → Browser → Manual.
   */
  async ensure(
    owner: string,
    projectId: string,
    projectNumber: number,
    view: ViewConfig
  ): Promise<ViewEnsureResult> {
    const probeConfig = makeProbeConfig(owner, projectNumber);

    // Check idempotency first (GraphQL list always works for reads)
    const existing = listViews(projectId);
    if (existing.some((v) => v.name === view.name)) {
      const resolution = resolveStrategy(CREATE_STRATEGIES, probeConfig);
      console.log(`  ✓ View exists: "${view.name}"`);
      return { name: view.name, alreadyExisted: true, created: false, resolution };
    }

    const resolution = resolveStrategy(CREATE_STRATEGIES, probeConfig);
    logResolution(view.name, resolution);

    switch (resolution.selectedStrategy) {
      case 'rest': {
        try {
          const result = createOrganizationProjectView(owner, projectNumber, view);
          console.log(
            `  + View created: "${view.name}" [rest, ${view.layout}, view #${result.number}]`
          );
          console.log(
            `    Endpoint: POST /orgs/${owner}/projectsV2/${projectNumber}/views`
          );
          if (view.groupBy) {
            console.log(
              `    Note: groupBy="${view.groupBy}" — configure manually in the GitHub UI (REST API does not support group_by on creation)`
            );
          }
          return { name: view.name, alreadyExisted: false, created: true, resolution };
        } catch (e: unknown) {
          if (e instanceof ViewRESTError) {
            console.error(`  ✗ REST failed (${e.statusCode}): ${e.message}`);
          }
          throw e;
        }
      }

      case 'browser-automation': {
        const result = await ensureViewViaBrowser(owner, projectNumber, view);
        console.log(
          `  ${result.created ? '+' : '✓'} View "${view.name}" [browser-automation, ${view.layout}]`
        );
        return {
          name: view.name,
          alreadyExisted: result.alreadyExisted,
          created: result.created,
          resolution,
        };
      }

      case 'manual-intervention': {
        console.log(
          `  ! View "${view.name}" (${view.layout}) requires manual creation.`
        );
        console.log(
          `    Strategies tried: ${resolution.unavailableStrategies.map((u) => u.strategy).join(', ')}`
        );
        if (resolution.fallbackReason) {
          console.log(`    Reason: ${resolution.fallbackReason.split('. ')[0]}`);
        }
        console.log(
          `    Create at: https://github.com/orgs/${owner}/projects/${projectNumber}/views/new`
        );
        return { name: view.name, alreadyExisted: false, created: false, resolution };
      }

      default:
        throw new Error(`Unexpected strategy for view creation: ${resolution.selectedStrategy}`);
    }
  },

  /**
   * Validates an existing view's conformance.
   *
   * Layout:  verifiable via GraphQL (listViews returns layout field).
   * Filter:  verifiable via GraphQL (listViews now returns filter field).
   *          Also settable on creation via REST — drift on existing views requires manual fix
   *          (no REST PATCH and no updateProjectV2View GraphQL mutation in the public API).
   * GroupBy: NOT verifiable — group_by is readable via GraphQL but no mutation/REST to set it.
   *          Configure manually in GitHub UI after creation.
   *
   * Conformance outcomes:
   *   - conformant             → view exists, layout and filter correct, groupBy manually verified
   *   - drift-auto-correctable → missing view when REST is available (can recreate with correct filter)
   *   - drift-manual-required  → missing when only manual available, wrong layout, or filter drift on existing view
   *   - unverifiable           → view exists with correct layout/filter; groupBy cannot be verified via API
   */
  validate(
    owner: string,
    projectId: string,
    projectNumber: number,
    view: ViewConfig
  ): ViewValidationResult {
    const probeConfig = makeProbeConfig(owner, projectNumber);
    const resolution = resolveStrategy(CREATE_STRATEGIES, probeConfig);
    const existing = listViews(projectId).find((v) => v.name === view.name);
    const canAutoCorrect = resolution.selectedStrategy !== 'manual-intervention';

    if (!existing) {
      return {
        name: view.name,
        exists: false,
        conformance: canAutoCorrect ? 'drift-auto-correctable' : 'drift-manual-required',
        layoutMatch: false,
        filterMatch: 'unverifiable',
        groupByMatch: 'unverifiable',
        resolution,
      };
    }

    const ghLayout = view.layout === 'BOARD' ? 'BOARD_LAYOUT' : 'TABLE_LAYOUT';
    const layoutMatch = existing.layout === ghLayout;

    if (!layoutMatch) {
      // Wrong layout: GitHub Projects REST API has no delete endpoint — always manual.
      return {
        name: view.name,
        exists: true,
        conformance: 'drift-manual-required',
        layoutMatch: false,
        filterMatch: 'unverifiable',
        groupByMatch: 'unverifiable',
        resolution,
      };
    }

    // Layout matches. Now compare filter (readable via GraphQL, settable on creation via REST).
    // Normalize: null/undefined both mean "no filter".
    const expectedFilter = view.filter ?? null;
    const actualFilter = existing.filter ?? null;
    const filterMatch: boolean | 'unverifiable' = expectedFilter === actualFilter;

    // Filter drift on an existing view requires manual intervention:
    // REST has no PATCH/update endpoint and GraphQL has no updateProjectV2View mutation.
    if (!filterMatch) {
      return {
        name: view.name,
        exists: true,
        conformance: 'drift-manual-required',
        layoutMatch: true,
        filterMatch: false,
        groupByMatch: 'unverifiable',
        resolution,
      };
    }

    // Layout and filter match. groupBy is not verifiable via any available API.
    return {
      name: view.name,
      exists: true,
      conformance: 'unverifiable',
      layoutMatch: true,
      filterMatch: true,
      groupByMatch: 'unverifiable',
      resolution,
    };
  },
};

function logResolution(viewName: string, resolution: StrategyResolutionResult): void {
  if (resolution.unavailableStrategies.length > 0) {
    console.log(`  ~ Resolving strategy for view "${viewName}":`);
    for (const { strategy, reason } of resolution.unavailableStrategies) {
      console.log(`    ✗ ${strategy}: ${reason}`);
    }
    console.log(`    ✓ selected: ${resolution.selectedStrategy}`);
  }
}
