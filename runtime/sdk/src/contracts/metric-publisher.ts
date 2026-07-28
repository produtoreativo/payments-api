import type { MetricPoint } from './telemetry.js';

/**
 * Publishes derived operational metrics to the observability backend.
 * Implemented by RT-04 (Datadog Adapter). Metric tags are NOT part of MetricPoint —
 * they are derived by the TagProjection contract and injected by the adapter.
 */
export interface MetricPublisher {
  publish(metric: MetricPoint): Promise<void>;
}
