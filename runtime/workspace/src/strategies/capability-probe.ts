import { execSync } from 'child_process';
import { existsSync } from 'fs';
import type { ProbeOutcome } from './strategy-result.js';

/**
 * In-process probe cache: avoids redundant API calls during a single provision/doctor run.
 * Cache is intentionally process-scoped — never persisted across runs.
 */
const cache = new Map<string, ProbeOutcome>();

function cached(key: string, fn: () => ProbeOutcome): ProbeOutcome {
  if (!cache.has(key)) cache.set(key, fn());
  return cache.get(key)!;
}

/** For testing: reset probe cache between test runs. */
export function resetProbeCache(): void {
  cache.clear();
}

/**
 * Probes the GitHub GraphQL API for a named mutation.
 * Uses schema introspection — does NOT assume support by name.
 */
export function probeGraphQL(mutationName: string): ProbeOutcome {
  return cached(`graphql:${mutationName}`, () => {
    try {
      const raw = execSync(
        `gh api graphql -f query='{ __schema { mutationType { fields { name } } } }'`,
        { encoding: 'utf-8', stdio: ['inherit', 'pipe', 'pipe'] }
      );
      const data = JSON.parse(raw) as {
        data: { __schema: { mutationType: { fields: Array<{ name: string }> } } };
      };
      const fields = data.data.__schema.mutationType.fields.map((f) => f.name);
      const available = fields.includes(mutationName);
      return {
        available,
        reason: available
          ? `GraphQL mutation '${mutationName}' confirmed in schema`
          : `GraphQL mutation '${mutationName}' absent from public API schema (introspection verified)`,
      };
    } catch (e: unknown) {
      return {
        available: false,
        reason: `GraphQL schema introspection failed: ${(e as Error).message ?? String(e)}`,
      };
    }
  });
}

/**
 * Probes a GitHub REST endpoint.
 * Distinguishes "resource not found" (404) from "operation not supported" (405/422).
 */
export function probeREST(endpoint: string, method = 'GET'): ProbeOutcome {
  return cached(`rest:${method}:${endpoint}`, () => {
    try {
      const flags = method !== 'GET' ? `--method ${method}` : '';
      execSync(`gh api ${endpoint} ${flags}`.trim(), {
        encoding: 'utf-8',
        stdio: ['inherit', 'pipe', 'pipe'],
      });
      return { available: true, reason: `REST ${method} ${endpoint} accessible` };
    } catch (e: unknown) {
      const stderr = (e as { stderr?: string }).stderr ?? '';
      const notFound = stderr.includes('404') || stderr.toLowerCase().includes('not found');
      const notAllowed = stderr.includes('405') || stderr.includes('Method Not Allowed');
      const reason = notFound
        ? `REST endpoint '${endpoint}' not found (404) — endpoint unavailable or resource does not exist`
        : notAllowed
        ? `REST ${method} '${endpoint}' not allowed (405) — operation not supported via REST`
        : `REST probe failed: ${stderr.trim()}`;
      return { available: false, reason };
    }
  });
}

/**
 * Probes whether a gh CLI subcommand exists and is usable.
 *
 * Strategy: run without args (exit 1 + "unknown command" if subcommand absent).
 * Do NOT use --help: gh CLI returns exit 0 and falls to parent help for unknown subcommands,
 * producing false positives (e.g., `gh project view-create --help` exits 0 via parent help).
 */
export function probeGhCLI(subcommand: string): ProbeOutcome {
  return cached(`gh-cli:${subcommand}`, () => {
    try {
      execSync(`gh ${subcommand}`, {
        encoding: 'utf-8',
        stdio: ['inherit', 'pipe', 'pipe'],
      });
      // Succeeded without args — subcommand exists (rare, but handle it)
      return { available: true, reason: `gh ${subcommand} available` };
    } catch (e: unknown) {
      const stderr = (e as { stderr?: string }).stderr ?? '';
      const stdout = (e as { stdout?: string }).stdout ?? '';
      const output = stderr + stdout;

      if (output.includes('unknown command') || output.includes('Unknown command')) {
        return {
          available: false,
          reason: `gh ${subcommand} not available in gh v${getGhVersion()} — subcommand does not exist`,
        };
      }
      // Exit non-zero but NOT "unknown command" → subcommand exists, just needs required args
      return { available: true, reason: `gh ${subcommand} available (requires arguments)` };
    }
  });
}

/**
 * Probes Browser Automation capability.
 * Requires:
 *   1. Playwright importable (local or global)
 *   2. GH_BROWSER_AUTH_STATE env var pointing to a valid storage state JSON file
 *
 * Never stores credentials — session state is provided externally by the operator.
 */
export function probeBrowser(): ProbeOutcome {
  return cached('browser:playwright', () => {
    const authStatePath = process.env['GH_BROWSER_AUTH_STATE'];

    if (!authStatePath) {
      return {
        available: false,
        reason:
          'GH_BROWSER_AUTH_STATE env var not set — set it to a Playwright storage state JSON file. ' +
          'Generate one with: npx playwright codegen github.com (save state after login)',
      };
    }

    if (!existsSync(authStatePath)) {
      return {
        available: false,
        reason: `Auth state file not found at GH_BROWSER_AUTH_STATE=${authStatePath}`,
      };
    }

    // Verify playwright is resolvable
    const playwrightAvailable = isPlaywrightAvailable();
    if (!playwrightAvailable) {
      return {
        available: false,
        reason: 'playwright package not found (install: npm install playwright)',
      };
    }

    return {
      available: true,
      reason: `Browser automation available: Playwright + auth state at ${authStatePath}`,
    };
  });
}

function isPlaywrightAvailable(): boolean {
  try {
    // Dynamic check without static import — keeps dependency optional at runtime
    execSync('node -e "import(\'playwright\').then(m => m.chromium ? process.exit(0) : process.exit(1))"', {
      encoding: 'utf-8',
      stdio: ['inherit', 'pipe', 'pipe'],
    });
    return true;
  } catch {
    return false;
  }
}

function getGhVersion(): string {
  try {
    return execSync('gh --version', { encoding: 'utf-8', stdio: ['inherit', 'pipe', 'pipe'] })
      .split('\n')[0]
      ?.match(/[\d.]+/)?.[0] ?? 'unknown';
  } catch {
    return 'unknown';
  }
}
