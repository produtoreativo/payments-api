import type { WorkspaceConfig, DoctorReport, DriftItem } from './types.js';
import { findProject, listFields, listViews, listProjectItems, sanitizeFieldName } from './github/project.js';
import { listLabels } from './github/labels.js';
import { findMilestone } from './github/milestone.js';
import { listIssues } from './github/issues.js';

export async function doctor(config: WorkspaceConfig): Promise<DoctorReport> {
  const { owner, repository } = config.metadata;
  const report: DoctorReport = {
    ok: true,
    project: { found: false },
    milestone: { found: false },
    fields: { total: config.fields.length, drifts: [] },
    labels: { total: config.labels.length, drifts: [] },
    views: { total: config.views.length, drifts: [] },
    issues: { total: config.issues.length, drifts: [] },
    summary: '',
  };

  // ── Project ───────────────────────────────────────────────────────────────
  const project = findProject(owner, config.project.title);
  if (!project) {
    report.project.found = false;
    report.ok = false;
    report.summary = `Project "${config.project.title}" not found. Run: workspace provision`;
    return report;
  }
  report.project = { found: true, number: project.number };

  // ── Milestone ─────────────────────────────────────────────────────────────
  const milestone = findMilestone(owner, repository, config.milestone.title);
  if (!milestone) {
    report.milestone.found = false;
    report.ok = false;
    report.fields.drifts.push({
      resource: 'milestone',
      name: config.milestone.title,
      severity: 'missing',
      recommendation: `gh api repos/${owner}/${repository}/milestones --method POST -f title="${config.milestone.title}"`,
    });
  } else {
    report.milestone = { found: true, number: milestone.number };
  }

  // ── Fields ────────────────────────────────────────────────────────────────
  const actualFields = listFields(owner, project.number);
  const actualFieldNames = new Set(actualFields.map((f) => f.name));

  for (const expected of config.fields) {
    const ghName = sanitizeFieldName(expected.name);
    if (!actualFieldNames.has(ghName)) {
      const opts =
        expected.type === 'SINGLE_SELECT' && expected.options?.length
          ? `--single-select-options "${expected.options.join(',')}"`
          : '';
      report.fields.drifts.push({
        resource: 'field',
        name: ghName,
        severity: 'missing',
        recommendation: `gh project field-create ${project.number} --owner "${owner}" --name "${ghName}" --data-type ${expected.type} ${opts}`.trim(),
      });
      report.ok = false;
    }
  }

  // Extra fields (in GitHub but not in config — informational)
  const configFieldNames = new Set(config.fields.map((f) => sanitizeFieldName(f.name)));
  const nativeFields = new Set(['Title', 'Assignees', 'Status', 'Labels', 'Linked pull requests', 'Milestone', 'Repository']);
  for (const actual of actualFields) {
    if (!configFieldNames.has(actual.name) && !nativeFields.has(actual.name)) {
      report.fields.drifts.push({
        resource: 'field',
        name: actual.name,
        severity: 'extra',
        recommendation: 'Review: this field is in GitHub but not in workspace.yaml',
      });
    }
  }

  // ── Labels ────────────────────────────────────────────────────────────────
  const actualLabels = listLabels(owner, repository);
  const actualLabelMap = Object.fromEntries(actualLabels.map((l) => [l.name, l]));

  for (const expected of config.labels) {
    const actual = actualLabelMap[expected.name];
    if (!actual) {
      report.labels.drifts.push({
        resource: 'label',
        name: expected.name,
        severity: 'missing',
        recommendation: `gh label create "${expected.name}" --repo "${owner}/${repository}" --color "${expected.color}" --description "${expected.description}"`,
      });
      report.ok = false;
    } else {
      const colorMismatch =
        actual.color.replace('#', '').toLowerCase() !== expected.color.toLowerCase();
      const descMismatch = actual.description !== expected.description;
      if (colorMismatch || descMismatch) {
        const diff: DriftItem = {
          resource: 'label',
          name: expected.name,
          severity: 'divergent',
          expected: { color: expected.color, description: expected.description },
          actual: { color: actual.color, description: actual.description },
          recommendation: `gh label edit "${expected.name}" --repo "${owner}/${repository}" --color "${expected.color}" --description "${expected.description}"`,
        };
        report.labels.drifts.push(diff);
        report.ok = false;
      }
    }
  }

  // ── Views ─────────────────────────────────────────────────────────────────
  const actualViews = listViews(project.id);
  const actualViewNames = new Set(actualViews.map((v) => v.name));

  for (const expected of config.views) {
    if (!actualViewNames.has(expected.name)) {
      report.views.drifts.push({
        resource: 'view',
        name: expected.name,
        severity: 'missing',
        recommendation: `Manual: https://github.com/orgs/${owner}/projects/${project.number}/views/new — create "${expected.name}" with ${expected.layout} layout (API does not support createProjectV2View)`,
      });
      report.ok = false;
    }
  }

  // ── Issues ────────────────────────────────────────────────────────────────
  const actualIssues = listIssues(owner, repository);
  const actualIssueTitles = new Set(actualIssues.map((i) => i.title));
  const projectItems = listProjectItems(owner, project.number);
  const projectItemTitles = new Set(
    projectItems.map((i) => i.content?.title).filter(Boolean)
  );

  for (const expected of config.issues) {
    if (!actualIssueTitles.has(expected.title)) {
      report.issues.drifts.push({
        resource: 'issue',
        name: expected.title,
        severity: 'missing',
        recommendation: `gh issue create --repo "${owner}/${repository}" --title "${expected.title}" --label "${expected.labels.join(',')}"`,
      });
      report.ok = false;
    } else if (!projectItemTitles.has(expected.title)) {
      const issue = actualIssues.find((i) => i.title === expected.title)!;
      report.issues.drifts.push({
        resource: 'issue-membership',
        name: expected.title,
        severity: 'missing',
        recommendation: `gh project item-add ${project.number} --owner "${owner}" --url "${issue.url}"`,
      });
      report.ok = false;
    }
  }

  // ── Summary ───────────────────────────────────────────────────────────────
  const totalDrifts =
    report.fields.drifts.length +
    report.labels.drifts.length +
    report.views.drifts.length +
    report.issues.drifts.length;

  report.summary = report.ok
    ? `✅ Workspace is consistent — ${totalDrifts} drift(s) found (extras only)`
    : `❌ Workspace has ${totalDrifts} drift(s) — run 'workspace provision' to repair`;

  return report;
}

export function printReport(report: DoctorReport): void {
  console.log('\n══ Workspace Doctor Report ══════════════════════════════\n');
  console.log(`Project   : ${report.project.found ? `found (#${report.project.number})` : '❌ NOT FOUND'}`);
  console.log(`Milestone : ${report.milestone.found ? `found (#${report.milestone.number})` : '❌ NOT FOUND'}`);
  console.log(`Fields    : ${report.fields.total} configured, ${report.fields.drifts.length} drift(s)`);
  console.log(`Labels    : ${report.labels.total} configured, ${report.labels.drifts.length} drift(s)`);
  console.log(`Views     : ${report.views.total} configured, ${report.views.drifts.length} drift(s)`);
  console.log(`Issues    : ${report.issues.total} configured, ${report.issues.drifts.length} drift(s)`);

  const allDrifts = [
    ...report.fields.drifts,
    ...report.labels.drifts,
    ...report.views.drifts,
    ...report.issues.drifts,
  ];

  if (allDrifts.length > 0) {
    console.log('\n── Drifts ───────────────────────────────────────────────\n');
    for (const drift of allDrifts) {
      const icon = drift.severity === 'missing' ? '❌' : drift.severity === 'extra' ? 'ℹ️ ' : '⚠️ ';
      console.log(`${icon} [${drift.resource}] ${drift.name}`);
      if (drift.severity === 'divergent') {
        console.log(`   expected : ${JSON.stringify(drift.expected)}`);
        console.log(`   actual   : ${JSON.stringify(drift.actual)}`);
      }
      console.log(`   fix      : ${drift.recommendation}`);
      console.log();
    }
  }

  console.log('── Summary ──────────────────────────────────────────────\n');
  console.log(`  ${report.summary}\n`);
}
