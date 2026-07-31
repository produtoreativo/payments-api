import type { MetricQueryParams, MetricResult } from './telemetry.js';
/** Queries derived operational metrics from the observability backend. */
export interface MetricQuery {
    query(params: MetricQueryParams): Promise<MetricResult>;
    metrics(): Promise<ReadonlyArray<string>>;
}
//# sourceMappingURL=metric-query.d.ts.map