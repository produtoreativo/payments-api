export type FieldType = 'TEXT' | 'NUMBER' | 'DATE' | 'SINGLE_SELECT';
export type UpdatedBy = 'manual' | 'runtime' | 'both';
export type ViewLayout = 'TABLE' | 'BOARD';
export type IssueType = 'Feature' | 'Runtime Task' | 'Finding';

export interface WorkspaceMetadata {
  owner: string;
  repository: string;
  iteration: string;
  release: string;
  obc: string;
}

export interface ProjectConfig {
  title: string;
  description: string;
}

export interface MilestoneConfig {
  title: string;
  description: string;
}

export interface FieldConfig {
  name: string;
  type: FieldType;
  options?: string[];
  required: boolean;
  updatedBy: UpdatedBy;
}

export interface LabelConfig {
  name: string;
  color: string;
  description: string;
  category: string;
}

export interface ViewConfig {
  name: string;
  layout: ViewLayout;
  description: string;
  /**
   * Label/field filter expression (e.g. "label:journey:delivery").
   * Settable via REST POST on creation.
   * Readable and verifiable via GraphQL.
   */
  filter?: string;
  /**
   * Field to group rows by.
   * NOT settable via REST or GraphQL mutation — configure manually in GitHub UI.
   * group_by is returned in the REST response but "is not a permitted key" in the request body (HTTP 422).
   */
  groupBy?: string;
}

export interface IssueConfig {
  title: string;
  body: string;
  labels: string[];
  type: IssueType;
  feature: string;
  initialFields: Record<string, string | number>;
}

export interface WorkspaceConfig {
  metadata: WorkspaceMetadata;
  project: ProjectConfig;
  milestone: MilestoneConfig;
  fields: FieldConfig[];
  labels: LabelConfig[];
  views: ViewConfig[];
  issues: IssueConfig[];
}

// ── Provider strategy types ────────────────────────────────────────────────

/**
 * Ordered strategy hierarchy for Workspace Providers.
 * Each Provider declares its preferred chain; the Resolver selects the first available.
 *
 * Preference order (most to least capable):
 *   graphql → rest → gh-cli → browser-automation → manual-intervention
 */
export type ProviderStrategy =
  | 'graphql'
  | 'rest'
  | 'gh-cli'
  | 'browser-automation'
  | 'manual-intervention';

/**
 * View-specific conformance status.
 * Distinguishes between "correct", "fixable", "needs manual" and "can't verify".
 * `unverifiable` must NOT be treated as conformant — explicitly flags what could not be checked.
 */
export type ViewConformance =
  | 'conformant'
  | 'drift-auto-correctable'
  | 'drift-manual-required'
  | 'unverifiable';

// ── Doctor result types ────────────────────────────────────────────────────

export type DriftSeverity = 'missing' | 'divergent' | 'extra';

export interface DriftItem {
  resource: string;
  name: string;
  severity: DriftSeverity;
  expected?: unknown;
  actual?: unknown;
  recommendation: string;
  /** Provider responsible for detecting and correcting this drift */
  providerUsed: string;
  /** Strategy the Provider would use to correct this drift */
  strategyUsed: ProviderStrategy;
  /** Alternative strategy if primary is unavailable, or null */
  alternativeStrategy: ProviderStrategy | null;
  /** Whether 'workspace provision' can auto-correct this drift */
  autoCorrectPossible: boolean;
  /**
   * View-specific conformance status.
   * Present only for 'view' resource types.
   * `unverifiable` means the resource exists but its configuration (filter/groupBy/sort)
   * cannot be verified via the available strategy — NOT the same as conformant.
   */
  conformance?: ViewConformance;
  /**
   * Strategy resolution result — present when the Resolver was invoked for this drift.
   * Contains full audit trail: attempted strategies, reasons for fallback.
   */
  resolutionTrace?: {
    attemptedStrategies: ProviderStrategy[];
    unavailableStrategies: Array<{ strategy: ProviderStrategy; reason: string }>;
    fallbackReason: string | null;
  };
}

export interface ProviderSummary {
  strategyUsed: ProviderStrategy;
  alternativeStrategy: ProviderStrategy | null;
  resourcesChecked: number;
  driftsFound: number;
  autoCorrectPossible: boolean;
}

export interface DoctorReport {
  ok: boolean;
  project: { found: boolean; number?: number };
  milestone: { found: boolean; number?: number };
  fields: { total: number; drifts: DriftItem[] };
  labels: { total: number; drifts: DriftItem[] };
  views: { total: number; drifts: DriftItem[] };
  issues: { total: number; drifts: DriftItem[] };
  /** Per-provider summary: strategy used, resources checked, drifts found */
  providers: Record<string, ProviderSummary>;
  summary: string;
}
