import { execSync } from 'child_process';

/**
 * Executes a `gh` CLI command and returns stdout as a string.
 * Throws with a descriptive message on failure.
 */
export function gh(args: string): string {
  try {
    return execSync(`gh ${args}`, {
      encoding: 'utf-8',
      stdio: ['inherit', 'pipe', 'pipe'],
    }).trim();
  } catch (error: unknown) {
    const e = error as { stderr?: string; message?: string };
    throw new Error(`gh ${args}\n→ ${e.stderr?.trim() ?? e.message ?? 'unknown error'}`);
  }
}

/**
 * Executes a `gh` CLI command and parses the JSON output.
 */
export function ghJson<T>(args: string): T {
  return JSON.parse(gh(args)) as T;
}

/**
 * Executes a GraphQL mutation/query via `gh api graphql`.
 */
export function ghGraphql<T>(query: string, variables: Record<string, string> = {}): T {
  const varFlags = Object.entries(variables)
    .map(([k, v]) => `-f ${k}="${v}"`)
    .join(' ');
  const raw = gh(`api graphql -f query='${query}' ${varFlags}`);
  return JSON.parse(raw) as T;
}
