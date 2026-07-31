import { spawnSync } from 'node:child_process';
import type { ViewConfig } from '../types.js';

const API_VERSION = '2022-11-28';

export interface RestViewResult {
  id: number;
  number: number;
  name: string;
  layout: string;
  url: string;
  nodeId: string;
}

export class ViewRESTError extends Error {
  constructor(
    public readonly statusCode: number,
    public readonly endpoint: string,
    message: string
  ) {
    super(message);
    this.name = 'ViewRESTError';
  }
}

/**
 * Creates a view in a GitHub ProjectsV2 via the REST API.
 * Endpoint: POST /orgs/{org}/projectsV2/{project_number}/views
 *
 * Layout mapping: TABLE → table, BOARD → board (REST API uses lowercase).
 *
 * Supported fields in request body (empirically verified 2026-07-26 on Project #23):
 *   - name        ✅ required
 *   - layout      ✅ required
 *   - filter      ✅ supported — applied on creation
 *   - visible_fields ✅ supported — array of numeric field database IDs
 *
 * NOT supported (HTTP 422 "not a permitted key" confirmed empirically):
 *   - group_by           ❌ configure manually in GitHub UI after creation
 *   - vertical_group_by  ❌ configure manually in GitHub UI after creation
 *   - sort_by            ❌ configure manually in GitHub UI after creation
 *
 * Auth: requires `project` scope on the GitHub token.
 * Idempotency: caller must verify the view does not already exist before calling.
 *   A second POST with the same name creates a DUPLICATE — GitHub does not deduplicate.
 */
export function createOrganizationProjectView(
  owner: string,
  projectNumber: number,
  view: ViewConfig
): RestViewResult {
  const endpoint = `/orgs/${owner}/projectsV2/${projectNumber}/views`;
  const layout = view.layout.toLowerCase();

  const args = [
    'api', '--method', 'POST',
    endpoint,
    '-H', 'Accept: application/vnd.github+json',
    '-H', `X-GitHub-Api-Version: ${API_VERSION}`,
    '-f', `name=${view.name}`,
    '-f', `layout=${layout}`,
  ];

  // filter is supported by REST API on creation (confirmed empirically 2026-07-26)
  if (view.filter) {
    args.push('-f', `filter=${view.filter}`);
  }

  // Use spawnSync with args array to avoid shell escaping issues with spaces in view names.
  const result = spawnSync('gh', args, { encoding: 'utf-8' });

  if (result.error) {
    throw new ViewRESTError(0, endpoint, `Process error: ${result.error.message}`);
  }

  const stdout = result.stdout ?? '';
  const stderr = result.stderr ?? '';

  if (result.status === 0) {
    const data = JSON.parse(stdout) as {
      id: number;
      number: number;
      name: string;
      layout: string;
      html_url: string;
      node_id: string;
    };
    return {
      id: data.id,
      number: data.number,
      name: data.name,
      layout: data.layout,
      url: data.html_url,
      nodeId: data.node_id,
    };
  }

  const combined = stdout + '\n' + stderr;

  if (/\b403\b|[Ff]orbidden/.test(combined)) {
    throw new ViewRESTError(403, endpoint,
      `Permission denied creating view "${view.name}". ` +
      `Token requires "Projects organization permission: write". ` +
      `Verify scopes: gh auth status`
    );
  }
  if (/\b404\b|[Nn]ot [Ff]ound/.test(combined)) {
    throw new ViewRESTError(404, endpoint,
      `Project not found at ${endpoint}. ` +
      `Verify owner="${owner}" and projectNumber=${projectNumber} are correct.`
    );
  }
  if (/\b422\b|[Uu]nprocessable/.test(combined)) {
    throw new ViewRESTError(422, endpoint,
      `Invalid payload for view "${view.name}": ${(stderr || stdout).trim()}. ` +
      `Layout must be one of: [table, board, roadmap]`
    );
  }
  if (/\b401\b|[Uu]nauthorized/.test(combined)) {
    throw new ViewRESTError(401, endpoint, `Authentication failed. Run: gh auth login`);
  }

  throw new ViewRESTError(result.status ?? 0, endpoint,
    `REST view creation failed (exit ${result.status}): ${combined.trim()}`
  );
}
