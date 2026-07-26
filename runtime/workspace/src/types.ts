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

// ── Doctor result types ────────────────────────────────────────────────────

export type DriftSeverity = 'missing' | 'divergent' | 'extra';

export interface DriftItem {
  resource: string;
  name: string;
  severity: DriftSeverity;
  expected?: unknown;
  actual?: unknown;
  recommendation: string;
}

export interface DoctorReport {
  ok: boolean;
  project: { found: boolean; number?: number };
  milestone: { found: boolean; number?: number };
  fields: { total: number; drifts: DriftItem[] };
  labels: { total: number; drifts: DriftItem[] };
  views: { total: number; drifts: DriftItem[] };
  issues: { total: number; drifts: DriftItem[] };
  summary: string;
}
