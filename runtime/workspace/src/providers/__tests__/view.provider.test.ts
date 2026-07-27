import { describe, it, expect, beforeEach, vi } from 'vitest';
import { resetProbeCache } from '../../strategies/capability-probe.js';

vi.mock('../../github/project.js', () => ({
  listViews: vi.fn(),
  ensureView: vi.fn(),
}));

vi.mock('../../github/views.browser.js', () => ({
  ensureViewViaBrowser: vi.fn(),
}));

vi.mock('../../github/views.rest.js', () => ({
  createOrganizationProjectView: vi.fn(),
  ViewRESTError: class ViewRESTError extends Error {
    constructor(public statusCode: number, public endpoint: string, message: string) {
      super(message);
      this.name = 'ViewRESTError';
    }
  },
}));

vi.mock('../../strategies/capability-probe.js', async (importOriginal) => {
  const actual = await importOriginal<typeof import('../../strategies/capability-probe.js')>();
  return {
    ...actual,
    probeGraphQL: vi.fn(),
    probeREST: vi.fn(),
    probeGhCLI: vi.fn(),
    probeBrowser: vi.fn(),
    resetProbeCache: vi.fn(),
  };
});

import { listViews } from '../../github/project.js';
import { ensureViewViaBrowser } from '../../github/views.browser.js';
import { createOrganizationProjectView } from '../../github/views.rest.js';
import { probeREST, probeBrowser } from '../../strategies/capability-probe.js';

const mockListViews = vi.mocked(listViews);
const mockEnsureViewViaBrowser = vi.mocked(ensureViewViaBrowser);
const mockCreateREST = vi.mocked(createOrganizationProjectView);
const mockREST = vi.mocked(probeREST);
const mockBrowser = vi.mocked(probeBrowser);

import { ViewProvider } from '../view.provider.js';
import type { ViewConfig } from '../../types.js';

const OWNER = 'test-org';
const PROJECT_ID = 'PVT_test';
const PROJECT_NUMBER = 42;

const tableView: ViewConfig = {
  name: 'Iteration Backlog',
  layout: 'TABLE',
  description: 'Test view',
};

const filteredView: ViewConfig = {
  name: 'Delivery',
  layout: 'TABLE',
  description: 'Delivery journey view',
  filter: 'label:journey:delivery',
};

const boardView: ViewConfig = {
  name: 'Delivery Board',
  layout: 'BOARD',
  description: 'Test board view',
};

const REST_VIEW_RESULT = {
  id: 12345,
  number: 7,
  name: 'Iteration Backlog',
  layout: 'table',
  url: 'https://github.com/orgs/test-org/projects/42/views/7',
  nodeId: 'PVTV_test',
};

beforeEach(() => {
  resetProbeCache();
  vi.clearAllMocks();
  // Default: REST available, browser unavailable
  mockREST.mockReturnValue({ available: true, reason: 'GET /orgs/test-org/projectsV2/42 → 200' });
  mockBrowser.mockReturnValue({ available: false, reason: 'GH_BROWSER_AUTH_STATE not set' });
});

describe('ViewProvider.ensure — idempotency', () => {
  it('returns immediately when view already exists (no creation call)', async () => {
    mockListViews.mockReturnValue([{ id: 'v1', name: 'Iteration Backlog', layout: 'TABLE_LAYOUT', filter: null }]);

    const result = await ViewProvider.ensure(OWNER, PROJECT_ID, PROJECT_NUMBER, tableView);

    expect(result.alreadyExisted).toBe(true);
    expect(result.created).toBe(false);
    expect(mockCreateREST).not.toHaveBeenCalled();
    expect(mockEnsureViewViaBrowser).not.toHaveBeenCalled();
  });

  it('does not duplicate view on second call when view exists', async () => {
    mockListViews.mockReturnValue([{ id: 'v1', name: 'Delivery Board', layout: 'BOARD_LAYOUT', filter: null }]);

    const r1 = await ViewProvider.ensure(OWNER, PROJECT_ID, PROJECT_NUMBER, boardView);
    const r2 = await ViewProvider.ensure(OWNER, PROJECT_ID, PROJECT_NUMBER, boardView);

    expect(r1.alreadyExisted).toBe(true);
    expect(r2.alreadyExisted).toBe(true);
    expect(mockCreateREST).not.toHaveBeenCalled();
  });
});

describe('ViewProvider.ensure — REST strategy (primary)', () => {
  it('creates view via REST when probe succeeds', async () => {
    mockListViews.mockReturnValue([]);
    mockCreateREST.mockReturnValue(REST_VIEW_RESULT);

    const result = await ViewProvider.ensure(OWNER, PROJECT_ID, PROJECT_NUMBER, tableView);

    expect(result.created).toBe(true);
    expect(result.alreadyExisted).toBe(false);
    expect(result.resolution.selectedStrategy).toBe('rest');
    expect(result.resolution.manualRequired).toBe(false);
    expect(mockCreateREST).toHaveBeenCalledWith(OWNER, PROJECT_NUMBER, tableView);
    expect(mockEnsureViewViaBrowser).not.toHaveBeenCalled();
  });

  it('passes filter to REST when ViewConfig.filter is set', async () => {
    mockListViews.mockReturnValue([]);
    mockCreateREST.mockReturnValue({
      ...REST_VIEW_RESULT,
      name: 'Delivery',
      layout: 'table',
    });

    await ViewProvider.ensure(OWNER, PROJECT_ID, PROJECT_NUMBER, filteredView);

    // filter is forwarded to createOrganizationProjectView — the adapter sends it in the payload
    expect(mockCreateREST).toHaveBeenCalledWith(OWNER, PROJECT_NUMBER, filteredView);
  });

  it('calls REST with correct owner and projectNumber', async () => {
    mockListViews.mockReturnValue([]);
    mockCreateREST.mockReturnValue({ ...REST_VIEW_RESULT, name: 'Delivery Board', layout: 'board' });

    await ViewProvider.ensure('my-org', PROJECT_ID, 99, boardView);

    expect(mockCreateREST).toHaveBeenCalledWith('my-org', 99, boardView);
  });

  it('absence of GH_BROWSER_AUTH_STATE does not block REST creation', async () => {
    mockListViews.mockReturnValue([]);
    mockBrowser.mockReturnValue({ available: false, reason: 'GH_BROWSER_AUTH_STATE not set' });
    mockCreateREST.mockReturnValue(REST_VIEW_RESULT);

    const result = await ViewProvider.ensure(OWNER, PROJECT_ID, PROJECT_NUMBER, tableView);

    expect(result.created).toBe(true);
    expect(result.resolution.selectedStrategy).toBe('rest');
  });

  it('falls back to browser-automation when REST probe fails', async () => {
    mockListViews.mockReturnValue([]);
    mockREST.mockReturnValue({ available: false, reason: 'project not accessible' });
    mockBrowser.mockReturnValue({ available: true, reason: 'playwright + auth state found' });
    mockEnsureViewViaBrowser.mockResolvedValue({
      name: tableView.name,
      created: true,
      alreadyExisted: false,
      layout: 'TABLE',
      url: 'https://github.com/orgs/test-org/projects/42',
      evidence: {
        timestamp: '2026-07-26T00:00:00Z',
        strategy: 'browser-automation',
        sessionSource: '/tmp/auth.json',
        viewTabFound: true,
        layoutConfirmed: true,
      },
    });

    const result = await ViewProvider.ensure(OWNER, PROJECT_ID, PROJECT_NUMBER, tableView);

    expect(result.created).toBe(true);
    expect(result.resolution.selectedStrategy).toBe('browser-automation');
    expect(result.resolution.unavailableStrategies.map((u) => u.strategy)).toContain('rest');
    expect(mockCreateREST).not.toHaveBeenCalled();
  });

  it('falls back to manual-intervention when REST and browser both fail', async () => {
    mockListViews.mockReturnValue([]);
    mockREST.mockReturnValue({ available: false, reason: 'project not accessible' });
    mockBrowser.mockReturnValue({ available: false, reason: 'no auth state' });

    const result = await ViewProvider.ensure(OWNER, PROJECT_ID, PROJECT_NUMBER, tableView);

    expect(result.created).toBe(false);
    expect(result.resolution.selectedStrategy).toBe('manual-intervention');
    expect(result.resolution.manualRequired).toBe(true);
    expect(result.resolution.unavailableStrategies.length).toBe(2);
    expect(mockCreateREST).not.toHaveBeenCalled();
  });
});

describe('ViewProvider.validate — conformance', () => {
  it('returns drift-auto-correctable for missing view when REST is available', () => {
    mockListViews.mockReturnValue([]);
    mockREST.mockReturnValue({ available: true, reason: '200 OK' });

    const result = ViewProvider.validate(OWNER, PROJECT_ID, PROJECT_NUMBER, tableView);

    expect(result.exists).toBe(false);
    expect(result.conformance).toBe('drift-auto-correctable');
    expect(result.layoutMatch).toBe(false);
    expect(result.resolution.selectedStrategy).toBe('rest');
  });

  it('returns drift-manual-required for missing view when only manual available', () => {
    mockListViews.mockReturnValue([]);
    mockREST.mockReturnValue({ available: false, reason: 'not accessible' });
    mockBrowser.mockReturnValue({ available: false, reason: 'no auth state' });

    const result = ViewProvider.validate(OWNER, PROJECT_ID, PROJECT_NUMBER, tableView);

    expect(result.exists).toBe(false);
    expect(result.conformance).toBe('drift-manual-required');
    expect(result.resolution.manualRequired).toBe(true);
  });

  it('returns drift-manual-required for wrong layout (delete not available via API)', () => {
    mockListViews.mockReturnValue([{ id: 'v1', name: 'Delivery Board', layout: 'TABLE_LAYOUT', filter: null }]);
    mockREST.mockReturnValue({ available: true, reason: '200 OK' });

    const result = ViewProvider.validate(OWNER, PROJECT_ID, PROJECT_NUMBER, boardView);

    expect(result.exists).toBe(true);
    expect(result.layoutMatch).toBe(false);
    expect(result.conformance).toBe('drift-manual-required');
  });

  it('returns unverifiable for existing view with correct layout and no filter configured', () => {
    mockListViews.mockReturnValue([{ id: 'v1', name: 'Iteration Backlog', layout: 'TABLE_LAYOUT', filter: null }]);

    const result = ViewProvider.validate(OWNER, PROJECT_ID, PROJECT_NUMBER, tableView);

    expect(result.exists).toBe(true);
    expect(result.conformance).toBe('unverifiable');
    expect(result.layoutMatch).toBe(true);
    expect(result.filterMatch).toBe(true); // both null → match
    expect(result.groupByMatch).toBe('unverifiable');
  });

  it('returns unverifiable when filter matches config', () => {
    mockListViews.mockReturnValue([
      { id: 'v1', name: 'Delivery', layout: 'TABLE_LAYOUT', filter: 'label:journey:delivery' },
    ]);

    const result = ViewProvider.validate(OWNER, PROJECT_ID, PROJECT_NUMBER, filteredView);

    expect(result.exists).toBe(true);
    expect(result.filterMatch).toBe(true);
    expect(result.conformance).toBe('unverifiable'); // groupBy still unverifiable
    expect(result.groupByMatch).toBe('unverifiable');
  });

  it('returns drift-manual-required when filter does not match (no REST PATCH available)', () => {
    mockListViews.mockReturnValue([
      { id: 'v1', name: 'Delivery', layout: 'TABLE_LAYOUT', filter: null }, // wrong: should have filter
    ]);
    mockREST.mockReturnValue({ available: true, reason: '200 OK' });

    const result = ViewProvider.validate(OWNER, PROJECT_ID, PROJECT_NUMBER, filteredView);

    expect(result.exists).toBe(true);
    expect(result.layoutMatch).toBe(true);
    expect(result.filterMatch).toBe(false);
    // filter drift on existing view always requires manual fix — no REST PATCH, no GraphQL updateProjectV2View
    expect(result.conformance).toBe('drift-manual-required');
  });

  it('returns drift-manual-required when actual filter differs from config filter', () => {
    mockListViews.mockReturnValue([
      { id: 'v1', name: 'Delivery', layout: 'TABLE_LAYOUT', filter: 'label:journey:old' },
    ]);

    const result = ViewProvider.validate(OWNER, PROJECT_ID, PROJECT_NUMBER, filteredView);

    expect(result.filterMatch).toBe(false);
    expect(result.conformance).toBe('drift-manual-required');
  });

  it('does not treat unverifiable as conformant', () => {
    mockListViews.mockReturnValue([{ id: 'v1', name: 'Delivery Board', layout: 'BOARD_LAYOUT', filter: null }]);

    const result = ViewProvider.validate(OWNER, PROJECT_ID, PROJECT_NUMBER, boardView);

    expect(result.conformance).toBe('unverifiable');
    expect(result.conformance).not.toBe('conformant');
  });
});

describe('IterationProvider — delegates to FieldProvider pattern', () => {
  it('confirms IP-001 uses TEXT field pattern', async () => {
    const { IterationProvider } = await import('../iteration.provider.js');
    expect(IterationProvider.isTextFieldPattern()).toBe(true);
  });

  it('has manual-intervention as only strategy (native Iteration API not available)', async () => {
    const { IterationProvider } = await import('../iteration.provider.js');
    expect(IterationProvider.meta.strategies).toEqual(['manual-intervention']);
    expect(IterationProvider.meta.autoCorrectPossible).toBe(false);
  });
});
