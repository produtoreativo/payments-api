import type {
  WorkspaceConfig,
  DoctorReport,
  DriftItem,
  DriftSeverity,
  ProviderSummary,
  ViewConformance,
} from './types.js';
import type { ProviderMeta } from './providers/strategy.js';
import { primaryStrategy, alternativeStrategy } from './providers/strategy.js';
import { WorkspaceManagementCapability as WMC } from './capability.js';
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
    providers: {},
    summary: '',
  };

  // ── Project ───────────────────────────────────────────────────────────────
  const project = WMC.project.find(owner, config.project.title);
  if (!project) {
    report.project.found = false;
    report.ok = false;
    report.providers[WMC.project.name] = providerSummary(WMC.project.meta, 1, 0);
    report.summary = `Project "${config.project.title}" not found. Run: workspace provision`;
    return report;
  }
  report.project = { found: true, number: project.number };

  // ── Milestone ─────────────────────────────────────────────────────────────
  const milestone = WMC.milestone.find(owner, repository, config.milestone.title);
  let milestoneDrifts = 0;
  if (!milestone) {
    report.milestone.found = false;
    report.ok = false;
    milestoneDrifts = 1;
    report.fields.drifts.push(makeDrift({
      resource: 'milestone',
      name: config.milestone.title,
      severity: 'missing',
      recommendation: `gh api repos/${owner}/${repository}/milestones --method POST -f title="${config.milestone.title}"`,
      provider: WMC.milestone,
    }));
  } else {
    report.milestone = { found: true, number: milestone.number };
  }
  report.providers[WMC.milestone.name] = providerSummary(WMC.milestone.meta, 1, milestoneDrifts);

  // ── Fields ────────────────────────────────────────────────────────────────
  const actualFields = WMC.field.list(owner, project.number);
  const actualFieldNames = new Set(actualFields.map((f) => f.name));

  for (const expected of config.fields) {
    const ghName = WMC.field.sanitizeName(expected.name);
    if (!actualFieldNames.has(ghName)) {
      const opts =
        expected.type === 'SINGLE_SELECT' && expected.options?.length
          ? `--single-select-options "${expected.options.join(',')}"`
          : '';
      report.fields.drifts.push(makeDrift({
        resource: 'field',
        name: ghName,
        severity: 'missing',
        recommendation: `gh project field-create ${project.number} --owner "${owner}" --name "${ghName}" --data-type ${expected.type} ${opts}`.trim(),
        provider: WMC.field,
      }));
      report.ok = false;
    }
  }

  const configFieldNames = new Set(config.fields.map((f) => WMC.field.sanitizeName(f.name)));
  const nativeFields = new Set(['Title', 'Assignees', 'Status', 'Labels', 'Linked pull requests', 'Milestone', 'Repository']);
  for (const actual of actualFields) {
    if (!configFieldNames.has(actual.name) && !nativeFields.has(actual.name)) {
      report.fields.drifts.push(makeDrift({
        resource: 'field',
        name: actual.name,
        severity: 'extra',
        recommendation: 'Review: this field is in GitHub but not in workspace.yaml',
        provider: WMC.field,
      }));
    }
  }

  report.providers[WMC.field.name] = providerSummary(
    WMC.field.meta,
    config.fields.length,
    report.fields.drifts.filter((d) => d.providerUsed === WMC.field.name && d.severity === 'missing').length
  );

  // ── Labels ────────────────────────────────────────────────────────────────
  const actualLabels = WMC.label.list(owner, repository);
  const actualLabelMap = Object.fromEntries(actualLabels.map((l) => [l.name, l]));

  for (const expected of config.labels) {
    const actual = actualLabelMap[expected.name];
    if (!actual) {
      report.labels.drifts.push(makeDrift({
        resource: 'label',
        name: expected.name,
        severity: 'missing',
        recommendation: `gh label create "${expected.name}" --repo "${owner}/${repository}" --color "${expected.color}" --description "${expected.description}"`,
        provider: WMC.label,
      }));
      report.ok = false;
    } else {
      const colorMismatch =
        actual.color.replace('#', '').toLowerCase() !== expected.color.toLowerCase();
      const descMismatch = actual.description !== expected.description;
      if (colorMismatch || descMismatch) {
        report.labels.drifts.push(makeDrift({
          resource: 'label',
          name: expected.name,
          severity: 'divergent',
          expected: { color: expected.color, description: expected.description },
          actual: { color: actual.color, description: actual.description },
          recommendation: `gh label edit "${expected.name}" --repo "${owner}/${repository}" --color "${expected.color}" --description "${expected.description}"`,
          provider: WMC.label,
        }));
        report.ok = false;
      }
    }
  }

  report.providers[WMC.label.name] = providerSummary(
    WMC.label.meta,
    config.labels.length,
    report.labels.drifts.filter((d) => d.severity !== 'extra').length
  );

  // ── Views — Strategy-aware validation ────────────────────────────────────
  for (const expected of config.views) {
    const validation = WMC.view.validate(owner, project.id, project.number, expected);
    const resolution = validation.resolution;

    const autoCorrect = resolution.selectedStrategy !== 'manual-intervention';
    const restEndpoint = `POST /orgs/${owner}/projectsV2/${project.number}/views`;
    const resolutionTrace = {
      attemptedStrategies: resolution.attemptedStrategies,
      unavailableStrategies: resolution.unavailableStrategies,
      fallbackReason: resolution.fallbackReason,
    };
    const providerFields = {
      providerUsed: WMC.view.name,
      strategyUsed: primaryStrategy(WMC.view.meta),
      alternativeStrategy: alternativeStrategy(WMC.view.meta),
      resolutionTrace,
    };

    if (!validation.exists) {
      // View is completely missing — can be auto-corrected via REST if available
      report.views.drifts.push({
        resource: 'view',
        name: expected.name,
        severity: 'missing',
        recommendation: autoCorrect
          ? `Run 'workspace provision' to create via ${resolution.selectedStrategy} [${restEndpoint}]`
          : `Manual: https://github.com/orgs/${owner}/projects/${project.number}/views/new — create "${expected.name}" with ${expected.layout} layout`,
        autoCorrectPossible: autoCorrect,
        conformance: validation.conformance,
        ...providerFields,
      });
      report.ok = false;
    } else if (validation.layoutMatch === false) {
      // View exists but with wrong layout — delete not available via API, always manual
      report.views.drifts.push({
        resource: 'view',
        name: expected.name,
        severity: 'divergent',
        expected: { layout: expected.layout },
        actual: { layout: 'DIFFERENT_LAYOUT' },
        recommendation: `Delete and recreate "${expected.name}" with ${expected.layout} layout via GitHub UI`,
        autoCorrectPossible: false,
        conformance: 'drift-manual-required',
        ...providerFields,
      });
      report.ok = false;
    } else if (validation.filterMatch === false) {
      // View exists with correct layout but wrong filter.
      // No REST PATCH and no updateProjectV2View GraphQL mutation — always manual fix.
      report.views.drifts.push({
        resource: 'view',
        name: expected.name,
        severity: 'divergent',
        expected: { filter: expected.filter ?? null },
        actual: { filter: 'DIFFERENT_FILTER' },
        recommendation: `Update filter for "${expected.name}" manually via GitHub UI: https://github.com/orgs/${owner}/projects/${project.number}`,
        autoCorrectPossible: false,
        conformance: 'drift-manual-required',
        ...providerFields,
      });
      report.ok = false;
    } else {
      // View exists with correct layout and filter. groupBy/sort not verifiable via any API.
      report.views.drifts.push({
        resource: 'view',
        name: expected.name,
        severity: 'extra',
        recommendation: `View "${expected.name}" exists with correct layout/filter. Configure groupBy manually: https://github.com/orgs/${owner}/projects/${project.number}`,
        autoCorrectPossible: false,
        conformance: 'unverifiable',
        ...providerFields,
      });
      // unverifiable is NOT conformant — do not set ok=false but flag in report
    }
  }

  report.providers[WMC.view.name] = providerSummary(
    WMC.view.meta,
    config.views.length,
    report.views.drifts.filter((d) => d.severity === 'missing' || d.severity === 'divergent').length
  );

  // ── Issues ────────────────────────────────────────────────────────────────
  const actualIssues = listIssues(owner, repository);
  const actualIssueTitles = new Set(actualIssues.map((i) => i.title));
  const projectItems = WMC.membership.listItems(owner, project.number);
  const projectItemTitles = new Set(
    projectItems.map((i) => i.content?.title).filter(Boolean)
  );

  for (const expected of config.issues) {
    if (!actualIssueTitles.has(expected.title)) {
      report.issues.drifts.push(makeDrift({
        resource: 'issue',
        name: expected.title,
        severity: 'missing',
        recommendation: `gh issue create --repo "${owner}/${repository}" --title "${expected.title}" --label "${expected.labels.join(',')}"`,
        provider: WMC.project,
      }));
      report.ok = false;
    } else if (!projectItemTitles.has(expected.title)) {
      const issue = actualIssues.find((i) => i.title === expected.title)!;
      report.issues.drifts.push(makeDrift({
        resource: 'issue-membership',
        name: expected.title,
        severity: 'missing',
        recommendation: `gh project item-add ${project.number} --owner "${owner}" --url "${issue.url}"`,
        provider: WMC.membership,
      }));
      report.ok = false;
    }
  }

  report.providers[WMC.membership.name] = providerSummary(
    WMC.membership.meta,
    config.issues.length,
    report.issues.drifts.filter((d) => d.resource === 'issue-membership').length
  );

  // ── Summary ───────────────────────────────────────────────────────────────
  const blockingDrifts =
    report.fields.drifts.filter((d) => d.severity !== 'extra').length +
    report.labels.drifts.filter((d) => d.severity !== 'extra').length +
    report.views.drifts.filter((d) => d.severity === 'missing' || d.severity === 'divergent').length +
    report.issues.drifts.length;

  const unverifiable = report.views.drifts.filter((d) => d.conformance === 'unverifiable').length;

  report.summary = report.ok
    ? `✅ Workspace structural conformance OK — ${unverifiable} view(s) exist but filter/groupBy unverifiable via API`
    : `❌ Workspace has ${blockingDrifts} blocking drift(s) — run 'workspace provision' to repair`;

  return report;
}

export function printReport(report: DoctorReport): void {
  console.log('\n══ Workspace Doctor Report ══════════════════════════════\n');
  console.log(`Project   : ${report.project.found ? `found (#${report.project.number})` : '❌ NOT FOUND'}`);
  console.log(`Milestone : ${report.milestone.found ? `found (#${report.milestone.number})` : '❌ NOT FOUND'}`);
  console.log(`Fields    : ${report.fields.total} configured, ${report.fields.drifts.length} drift(s)`);
  console.log(`Labels    : ${report.labels.total} configured, ${report.labels.drifts.length} drift(s)`);
  console.log(`Views     : ${report.views.total} configured, ${report.views.drifts.length} result(s)`);
  console.log(`Issues    : ${report.issues.total} configured, ${report.issues.drifts.length} drift(s)`);

  const blockingDrifts: DriftItem[] = [
    ...report.fields.drifts.filter((d) => d.severity !== 'extra'),
    ...report.labels.drifts.filter((d) => d.severity !== 'extra'),
    ...report.views.drifts.filter((d) => d.severity === 'missing' || d.severity === 'divergent'),
    ...report.issues.drifts,
  ];

  const unverifiableViews = report.views.drifts.filter((d) => d.conformance === 'unverifiable');

  if (blockingDrifts.length > 0) {
    console.log('\n── Blocking Drifts ──────────────────────────────────────\n');
    for (const drift of blockingDrifts) {
      const icon = drift.severity === 'missing' ? '❌' : '⚠️ ';
      console.log(`${icon} [${drift.resource}] ${drift.name}`);
      if (drift.severity === 'divergent') {
        console.log(`   expected : ${JSON.stringify(drift.expected)}`);
        console.log(`   actual   : ${JSON.stringify(drift.actual)}`);
      }
      console.log(`   fix      : ${drift.recommendation}`);
      console.log(`   provider : ${drift.providerUsed}  strategy: ${drift.strategyUsed}  auto-correct: ${drift.autoCorrectPossible ? 'yes' : 'no'}`);
      if (drift.conformance) {
        console.log(`   conform  : ${drift.conformance}`);
      }
      if (drift.resolutionTrace?.unavailableStrategies?.length) {
        const skipped = drift.resolutionTrace.unavailableStrategies
          .map((u) => `${u.strategy} (${u.reason.split('—')[0].trim()})`)
          .join('; ');
        console.log(`   skipped  : ${skipped}`);
      }
      console.log();
    }
  }

  if (unverifiableViews.length > 0) {
    console.log('── Views Unverifiable ───────────────────────────────────\n');
    for (const v of unverifiableViews) {
      console.log(`  ℹ️  [view] ${v.name} — layout: OK, filter/groupBy: unverifiable via GitHub API`);
    }
    console.log();
  }

  const extraFields = report.fields.drifts.filter((d) => d.severity === 'extra');
  if (extraFields.length > 0) {
    console.log('── Extra Fields (informational) ─────────────────────────\n');
    for (const f of extraFields) {
      console.log(`  ℹ️  ${f.name}: ${f.recommendation}`);
    }
    console.log();
  }

  if (Object.keys(report.providers).length > 0) {
    console.log('── Providers ────────────────────────────────────────────\n');
    for (const [name, p] of Object.entries(report.providers)) {
      const correctable = p.autoCorrectPossible ? 'yes' : 'no ⚠';
      console.log(`  ${name}: checked=${p.resourcesChecked} drifts=${p.driftsFound} strategy=${p.strategyUsed} auto-correct=${correctable}`);
    }
    console.log();
  }

  console.log('── Summary ──────────────────────────────────────────────\n');
  console.log(`  ${report.summary}\n`);
}

// ── Helpers ───────────────────────────────────────────────────────────────

function makeDrift(opts: {
  resource: string;
  name: string;
  severity: DriftSeverity;
  recommendation: string;
  provider: { name: string; meta: ProviderMeta };
  expected?: unknown;
  actual?: unknown;
  conformance?: ViewConformance;
}): DriftItem {
  return {
    resource: opts.resource,
    name: opts.name,
    severity: opts.severity,
    recommendation: opts.recommendation,
    expected: opts.expected,
    actual: opts.actual,
    providerUsed: opts.provider.name,
    strategyUsed: primaryStrategy(opts.provider.meta),
    alternativeStrategy: alternativeStrategy(opts.provider.meta),
    autoCorrectPossible: opts.provider.meta.autoCorrectPossible,
    conformance: opts.conformance,
  };
}

function providerSummary(
  meta: ProviderMeta,
  resourcesChecked: number,
  driftsFound: number
): ProviderSummary {
  return {
    strategyUsed: primaryStrategy(meta),
    alternativeStrategy: alternativeStrategy(meta),
    resourcesChecked,
    driftsFound,
    autoCorrectPossible: meta.autoCorrectPossible,
  };
}
