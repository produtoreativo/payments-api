export const FindingType = {
  Drift: 'Drift',
  MissingEvidence: 'MissingEvidence',
  MissingEvent: 'MissingEvent',
  RuntimeError: 'RuntimeError',
  ManualReview: 'ManualReview',
} as const;
export type FindingType = (typeof FindingType)[keyof typeof FindingType];

export const FindingSeverity = {
  High: 'High',
  Medium: 'Medium',
  Low: 'Low',
} as const;
export type FindingSeverity = (typeof FindingSeverity)[keyof typeof FindingSeverity];

export interface Finding {
  readonly id: string;
  readonly type: FindingType;
  readonly severity: FindingSeverity;
  readonly work_item_id: string;
  readonly description: string;
  readonly detected_at: string;
  readonly evidence?: string;
  readonly resolved: boolean;
  readonly resolved_at?: string;
}
