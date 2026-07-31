import { gh, ghJson } from './client.js';
import type { LabelConfig } from '../types.js';

interface GhLabel {
  name: string;
  color: string;
  description: string;
}

export function listLabels(owner: string, repo: string): GhLabel[] {
  return ghJson<GhLabel[]>(
    `label list --repo "${owner}/${repo}" --json name,color,description --limit 200`
  );
}

export function ensureLabel(owner: string, repo: string, label: LabelConfig): void {
  const existing = listLabels(owner, repo);
  const found = existing.find((l) => l.name === label.name);

  if (found) {
    const colorMatch = found.color.replace('#', '').toLowerCase() === label.color.toLowerCase();
    if (colorMatch && found.description === label.description) {
      console.log(`  ✓ Label exists: "${label.name}"`);
      return;
    }
    console.log(`  ~ Updating label: "${label.name}"`);
    gh(
      `label edit "${label.name}" --repo "${owner}/${repo}" --color "${label.color}" --description "${label.description}"`
    );
    return;
  }

  console.log(`  + Creating label: "${label.name}"`);
  gh(
    `label create "${label.name}" --repo "${owner}/${repo}" --color "${label.color}" --description "${label.description}"`
  );
}
