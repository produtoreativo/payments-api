import { gh, ghJson } from './client.js';
import type { MilestoneConfig } from '../types.js';

interface GhMilestone {
  number: number;
  title: string;
  description: string;
  state: string;
}

export function listMilestones(owner: string, repo: string): GhMilestone[] {
  return ghJson<GhMilestone[]>(
    `api repos/${owner}/${repo}/milestones --jq '[.[] | {number, title, description, state}]'`
  );
}

export function findMilestone(
  owner: string,
  repo: string,
  title: string
): GhMilestone | undefined {
  return listMilestones(owner, repo).find((m) => m.title === title);
}

export function ensureMilestone(
  owner: string,
  repo: string,
  config: MilestoneConfig
): GhMilestone {
  const existing = findMilestone(owner, repo, config.title);
  if (existing) {
    console.log(`  ✓ Milestone exists: "${config.title}" (#${existing.number})`);
    return existing;
  }
  console.log(`  + Creating milestone: "${config.title}"`);
  gh(
    `api repos/${owner}/${repo}/milestones --method POST -f title="${config.title}" -f description="${config.description}" -f state=open`
  );
  return findMilestone(owner, repo, config.title)!;
}
