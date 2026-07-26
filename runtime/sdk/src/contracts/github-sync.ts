import type { DerivedState } from '../models/derived-state.js';
import type { Finding } from '../models/finding.js';

export interface GitHubSync {
  sync(workItemId: string, state: DerivedState): Promise<void>;
  reportFindings(workItemId: string, findings: ReadonlyArray<Finding>): Promise<void>;
}
