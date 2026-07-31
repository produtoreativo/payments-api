/**
 * Shared data types for metrics contracts.
 * Behavioral interfaces are in metric-publisher.ts and metric-query.ts.
 *
 * BREAKING CHANGE (v0.1.0 reconciliation): `MetricQuery` renamed to `MetricQueryParams`
 * to free the `MetricQuery` name for the behavioral interface. The `Telemetry` interface
 * was removed — replaced by the focused `MetricPublisher` and `MetricQuery` interfaces.
 */

export interface MetricPoint {
  readonly name: string;
  readonly value: number;
  readonly tags: Readonly<Record<string, string>>;
  readonly timestamp: string;
}

export interface MetricQueryParams {
  readonly name: string;
  readonly from: string;
  readonly to: string;
  readonly tags?: Readonly<Record<string, string>>;
}

export interface MetricResult {
  readonly name: string;
  readonly points: ReadonlyArray<{ readonly timestamp: string; readonly value: number }>;
}
