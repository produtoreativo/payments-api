import { gh, ghJson } from './client.js';
import type { IssueConfig } from '../types.js';

interface GhIssue {
  number: number;
  title: string;
  url: string;
  state: string;
  labels: Array<{ name: string }>;
}

export function listIssues(owner: string, repo: string): GhIssue[] {
  return ghJson<GhIssue[]>(
    `issue list --repo "${owner}/${repo}" --json number,title,url,state,labels --state all --limit 500`
  );
}

export function findIssue(owner: string, repo: string, title: string): GhIssue | undefined {
  return listIssues(owner, repo).find((i) => i.title === title);
}

export function ensureIssue(
  owner: string,
  repo: string,
  milestoneTitle: string,
  config: IssueConfig
): GhIssue {
  const existing = findIssue(owner, repo, config.title);
  if (existing) {
    console.log(`  ✓ Issue exists: "${config.title}" (#${existing.number})`);
    return existing;
  }

  console.log(`  + Creating issue: "${config.title}"`);

  const labelArgs = config.labels.map((l) => `--label "${l}"`).join(' ');
  gh(
    `issue create --repo "${owner}/${repo}" --title "${config.title}" --body "${config.body.replace(/"/g, '\\"').replace(/\n/g, '\\n')}" ${labelArgs} --milestone "${milestoneTitle}"`
  );

  return findIssue(owner, repo, config.title)!;
}
