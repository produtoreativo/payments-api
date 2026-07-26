import type { WorkspaceConfig } from './types.js';
import {
  ensureProject,
  ensureField,
  ensureView,
  addIssueToProject,
  listProjectItems,
  listFields,
  sanitizeFieldName,
  setItemField,
} from './github/project.js';
import { ensureLabel } from './github/labels.js';
import { ensureMilestone } from './github/milestone.js';
import { ensureIssue } from './github/issues.js';

export async function provision(config: WorkspaceConfig): Promise<void> {
  const { owner, repository } = config.metadata;

  // ── 1. Project ────────────────────────────────────────────────────────────
  console.log('\n[1/7] Project');
  const project = ensureProject(owner, config.project.title, config.project.description);

  // ── 2. Milestone ──────────────────────────────────────────────────────────
  console.log('\n[2/7] Milestone');
  const milestone = ensureMilestone(owner, repository, config.milestone);

  // ── 3. Fields ─────────────────────────────────────────────────────────────
  console.log('\n[3/7] Fields');
  const existingFieldNames = new Set(listFields(owner, project.number).map((f) => f.name));
  for (const field of config.fields) {
    ensureField(owner, project.number, field, existingFieldNames);
  }

  // ── 4. Labels ─────────────────────────────────────────────────────────────
  console.log('\n[4/7] Labels');
  for (const label of config.labels) {
    ensureLabel(owner, repository, label);
  }

  // ── 5. Views ──────────────────────────────────────────────────────────────
  console.log('\n[5/7] Views');
  for (const view of config.views) {
    ensureView(project.id, view);
  }

  // ── 6. Issues + Project membership ────────────────────────────────────────
  console.log('\n[6/7] Issues');

  const fields = listFields(owner, project.number);
  const fieldMap = Object.fromEntries(fields.map((f) => [f.name, f]));

  for (const issueConfig of config.issues) {
    const issue = ensureIssue(owner, repository, milestone.title, issueConfig);

    // Add to project (idempotent: skip if already a member)
    const projectItems = listProjectItems(owner, project.number);
    const alreadyInProject = projectItems.some((i) => i.content?.number === issue.number);

    let itemId: string;
    if (alreadyInProject) {
      console.log(`  ✓ Already in project: "${issue.title}"`);
      itemId = projectItems.find((i) => i.content?.number === issue.number)?.id ?? '';
    } else {
      console.log(`  + Adding to project: "${issue.title}"`);
      itemId = addIssueToProject(owner, project.number, issue.url);
    }

    // Set identity fields (TEXT) via GraphQL updateProjectV2ItemFieldValue.
    // Keys use colon convention from workspace.yaml; GitHub stores sanitized names (spaces).
    const textFields: Record<string, string> = {
      'witem:repository': repository,
      'witem:feature': issueConfig.feature,
      'witem:obc': config.metadata.obc,
      'witem:release': config.metadata.release,
      'witem:iteration': config.metadata.iteration,
    };

    for (const [fieldName, value] of Object.entries(textFields)) {
      const field = fieldMap[sanitizeFieldName(fieldName)];
      if (field?.type !== 'TEXT') continue;
      try {
        setItemField(project.id, itemId, field.id, value, 'TEXT');
      } catch {
        console.warn(`  ! Could not set "${fieldName}" on "${issue.title}"`);
      }
    }
  }

  // ── 7. Summary ────────────────────────────────────────────────────────────
  console.log('\n[7/7] Done');
  console.log(`
  Project   : ${config.project.title} (#${project.number})
  Milestone : ${config.milestone.title} (#${milestone.number})
  Fields    : ${config.fields.length} defined
  Labels    : ${config.labels.length} defined
  Views     : ${config.views.length} defined
  Issues    : ${config.issues.length} provisioned

  URL: https://github.com/orgs/${owner}/projects/${project.number}

  NOTE: SINGLE_SELECT field values require a follow-up step — option IDs
  are project-specific. Run 'workspace doctor' to check current state.
  `);
}
