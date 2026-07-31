import { describe, it, expect, beforeEach, vi } from 'vitest';
import { resolveStrategy } from '../resolver.js';
import { resetProbeCache } from '../capability-probe.js';

// Mock capability-probe to control probe outcomes without real API calls
vi.mock('../capability-probe.js', async (importOriginal) => {
  const actual = await importOriginal<typeof import('../capability-probe.js')>();
  return {
    ...actual,
    probeGraphQL: vi.fn(),
    probeREST: vi.fn(),
    probeGhCLI: vi.fn(),
    probeBrowser: vi.fn(),
    resetProbeCache: vi.fn(),
  };
});

import {
  probeGraphQL,
  probeREST,
  probeGhCLI,
  probeBrowser,
} from '../capability-probe.js';

const mockGraphQL = vi.mocked(probeGraphQL);
const mockREST = vi.mocked(probeREST);
const mockGhCLI = vi.mocked(probeGhCLI);
const mockBrowser = vi.mocked(probeBrowser);

beforeEach(() => {
  resetProbeCache();
  vi.clearAllMocks();
});

describe('resolveStrategy', () => {
  it('selects graphql when available (first in chain)', () => {
    mockGraphQL.mockReturnValue({ available: true, reason: 'mutation found' });

    const result = resolveStrategy(
      ['graphql', 'rest', 'gh-cli', 'browser-automation', 'manual-intervention'],
      { graphql: { mutationName: 'createSomething' }, rest: { endpoint: '/test' }, ghCli: { subcommand: 'project create' } }
    );

    expect(result.selectedStrategy).toBe('graphql');
    expect(result.attemptedStrategies).toEqual(['graphql']);
    expect(result.unavailableStrategies).toHaveLength(0);
    expect(result.fallbackReason).toBeNull();
    expect(result.manualRequired).toBe(false);
  });

  it('falls back from graphql → rest when graphql unavailable', () => {
    mockGraphQL.mockReturnValue({ available: false, reason: 'mutation not in schema' });
    mockREST.mockReturnValue({ available: true, reason: 'endpoint accessible' });

    const result = resolveStrategy(
      ['graphql', 'rest', 'manual-intervention'],
      { graphql: { mutationName: 'someOp' }, rest: { endpoint: '/orgs/x/projects/1/views' } }
    );

    expect(result.selectedStrategy).toBe('rest');
    expect(result.attemptedStrategies).toEqual(['graphql', 'rest']);
    expect(result.unavailableStrategies).toHaveLength(1);
    expect(result.unavailableStrategies[0]?.strategy).toBe('graphql');
    expect(result.fallbackReason).toContain('graphql');
    expect(result.manualRequired).toBe(false);
  });

  it('falls back graphql → rest → gh-cli → browser (full chain)', () => {
    mockGraphQL.mockReturnValue({ available: false, reason: 'mutation absent' });
    mockREST.mockReturnValue({ available: false, reason: '404 not found' });
    mockGhCLI.mockReturnValue({ available: false, reason: 'command not found' });
    mockBrowser.mockReturnValue({ available: true, reason: 'playwright + auth state available' });

    const result = resolveStrategy(
      ['graphql', 'rest', 'gh-cli', 'browser-automation', 'manual-intervention'],
      {
        graphql: { mutationName: 'createProjectV2View' },
        rest: { endpoint: '/orgs/x/projects/24/views' },
        ghCli: { subcommand: 'project view-create' },
        browser: true,
      }
    );

    expect(result.selectedStrategy).toBe('browser-automation');
    expect(result.attemptedStrategies).toEqual(['graphql', 'rest', 'gh-cli', 'browser-automation']);
    expect(result.unavailableStrategies).toHaveLength(3);
    expect(result.manualRequired).toBe(false);
    expect(result.fallbackReason).toContain('graphql');
  });

  it('never falls silently to manual — records all skipped strategies with reasons', () => {
    mockGraphQL.mockReturnValue({ available: false, reason: 'not in schema' });
    mockREST.mockReturnValue({ available: false, reason: '404' });
    mockGhCLI.mockReturnValue({ available: false, reason: 'no command' });
    mockBrowser.mockReturnValue({ available: false, reason: 'no auth state' });

    const result = resolveStrategy(
      ['graphql', 'rest', 'gh-cli', 'browser-automation', 'manual-intervention'],
      {
        graphql: { mutationName: 'createProjectV2View' },
        rest: { endpoint: '/test' },
        ghCli: { subcommand: 'project view-create' },
        browser: true,
      }
    );

    expect(result.selectedStrategy).toBe('manual-intervention');
    expect(result.manualRequired).toBe(true);
    // All 4 automated strategies must be recorded with reasons
    expect(result.unavailableStrategies).toHaveLength(4);
    const strategies = result.unavailableStrategies.map((u) => u.strategy);
    expect(strategies).toContain('graphql');
    expect(strategies).toContain('rest');
    expect(strategies).toContain('gh-cli');
    expect(strategies).toContain('browser-automation');
    // Each must have a non-empty reason
    for (const u of result.unavailableStrategies) {
      expect(u.reason.length).toBeGreaterThan(0);
    }
  });

  it('selects manual-intervention directly when it is the only strategy', () => {
    const result = resolveStrategy(
      ['manual-intervention'],
      {}
    );

    expect(result.selectedStrategy).toBe('manual-intervention');
    expect(result.manualRequired).toBe(true);
    expect(result.unavailableStrategies).toHaveLength(0);
    expect(result.fallbackReason).toBeNull();
  });

  it('returns manual when no probe config provided for non-manual strategies', () => {
    const result = resolveStrategy(
      ['graphql', 'rest', 'gh-cli', 'manual-intervention'],
      {} // no probe config — all non-manual strategies unavailable
    );

    expect(result.selectedStrategy).toBe('manual-intervention');
    expect(result.manualRequired).toBe(true);
    expect(result.unavailableStrategies).toHaveLength(3);
  });

  it('marks manualRequired=false for any automated strategy', () => {
    mockGhCLI.mockReturnValue({ available: true, reason: 'found' });

    const result = resolveStrategy(
      ['gh-cli', 'manual-intervention'],
      { ghCli: { subcommand: 'project field-create' } }
    );

    expect(result.selectedStrategy).toBe('gh-cli');
    expect(result.manualRequired).toBe(false);
  });
});
