import { gh, ghJson, ghGraphql } from './client.js';
import type { FieldConfig, ViewConfig } from '../types.js';

/** GitHub Projects v2 does not allow ':' in field names. Convert to space. */
export const sanitizeFieldName = (name: string): string => name.replaceAll(':', ' ');

interface GhProject {
  number: number;
  id: string;
  title: string;
  url: string;
}

interface GhField {
  id: string;
  name: string;
  type: string;
}

interface GhView {
  id: string;
  name: string;
  layout: string;
}

export function listProjects(owner: string): GhProject[] {
  return ghJson<{ projects: GhProject[] }>(
    `project list --owner "${owner}" --format json --limit 100`
  ).projects;
}

export function findProject(owner: string, title: string): GhProject | undefined {
  return listProjects(owner).find((p) => p.title === title);
}

export function createProject(owner: string, title: string, description: string): GhProject {
  const raw = gh(`project create --owner "${owner}" --title "${title}" --format json`);
  const project = JSON.parse(raw) as GhProject;
  // Set description via GraphQL since gh project create doesn't support --readme/description flag
  if (description) {
    ghGraphql(
      `mutation($id: ID!, $desc: String!) {
        updateProjectV2(input: {projectId: $id, shortDescription: $desc}) {
          projectV2 { id }
        }
      }`,
      { id: project.id, desc: description.slice(0, 255) }
    );
  }
  return project;
}

export function ensureProject(owner: string, title: string, description: string): GhProject {
  const existing = findProject(owner, title);
  if (existing) {
    console.log(`  ✓ Project exists: "${title}" (#${existing.number})`);
    return existing;
  }
  console.log(`  + Creating project: "${title}"`);
  return createProject(owner, title, description);
}

export function listFields(owner: string, projectNumber: number): GhField[] {
  return ghJson<{ fields: GhField[] }>(
    `project field-list ${projectNumber} --owner "${owner}" --format json --limit 100`
  ).fields;
}

export function createField(owner: string, projectNumber: number, field: FieldConfig): void {
  const ghName = sanitizeFieldName(field.name);
  if (field.type === 'SINGLE_SELECT' && field.options?.length) {
    gh(
      `project field-create ${projectNumber} --owner "${owner}" --name "${ghName}" --data-type SINGLE_SELECT --single-select-options "${field.options.join(',')}"`
    );
  } else {
    gh(
      `project field-create ${projectNumber} --owner "${owner}" --name "${ghName}" --data-type ${field.type}`
    );
  }
}

export function ensureField(
  owner: string,
  projectNumber: number,
  field: FieldConfig,
  existingNames?: Set<string>
): void {
  const ghName = sanitizeFieldName(field.name);
  const names = existingNames ?? new Set(listFields(owner, projectNumber).map((f) => f.name));
  if (names.has(ghName)) {
    console.log(`  ✓ Field exists: "${ghName}"`);
    return;
  }
  console.log(`  + Creating field: "${ghName}" (${field.type})`);
  createField(owner, projectNumber, field);
}

export function listViews(projectId: string): GhView[] {
  const result = ghGraphql<{ data: { node: { views: { nodes: GhView[] } } } }>(
    `query($id: ID!) { node(id: $id) { ... on ProjectV2 { views(first: 20) { nodes { id name layout } } } } }`,
    { id: projectId }
  );
  return result.data.node.views.nodes;
}

export function ensureView(projectId: string, view: ViewConfig): void {
  const existing = listViews(projectId);
  if (existing.some((v) => v.name === view.name)) {
    console.log(`  ✓ View exists: "${view.name}"`);
    return;
  }
  const layout = view.layout === 'BOARD' ? 'BOARD_LAYOUT' : 'TABLE_LAYOUT';
  console.log(`  ! View "${view.name}" (${layout}) requires manual creation — GitHub Projects API does not expose createProjectV2View.`);
  console.log(`    Create at: https://github.com/orgs/produtoreativo/projects/24/views/new`);
}

export function addIssueToProject(
  owner: string,
  projectNumber: number,
  issueUrl: string
): string {
  const raw = gh(
    `project item-add ${projectNumber} --owner "${owner}" --url "${issueUrl}" --format json`
  );
  return (JSON.parse(raw) as { id: string }).id;
}

export function listProjectItems(
  owner: string,
  projectNumber: number
): Array<{ id: string; content: { title: string; url: string; number: number } }> {
  return ghJson<{
    items: Array<{ id: string; content: { title: string; url: string; number: number } }>;
  }>(`project item-list ${projectNumber} --owner "${owner}" --format json --limit 200`).items;
}

export function setItemField(
  projectId: string,
  itemId: string,
  fieldId: string,
  value: string,
  fieldType: string
): void {
  if (fieldType === 'SINGLE_SELECT') {
    ghGraphql(
      `mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
        updateProjectV2ItemFieldValue(input: {
          projectId: $projectId itemId: $itemId fieldId: $fieldId
          value: { singleSelectOptionId: $optionId }
        }) { projectV2Item { id } }
      }`,
      { projectId, itemId, fieldId, optionId: value }
    );
  } else if (fieldType === 'NUMBER') {
    ghGraphql(
      `mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!) {
        updateProjectV2ItemFieldValue(input: {
          projectId: $projectId itemId: $itemId fieldId: $fieldId
          value: { number: ${Number.parseFloat(value)} }
        }) { projectV2Item { id } }
      }`,
      { projectId, itemId, fieldId }
    );
  } else {
    ghGraphql(
      `mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $text: String!) {
        updateProjectV2ItemFieldValue(input: {
          projectId: $projectId itemId: $itemId fieldId: $fieldId
          value: { text: $text }
        }) { projectV2Item { id } }
      }`,
      { projectId, itemId, fieldId, text: value }
    );
  }
}
