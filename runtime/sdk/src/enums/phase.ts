/**
 * Delivery Journey Phases — the sequential steps within a CI cycle.
 * Canonical source: framework/journeys/delivery/phases/
 *
 * BREAKING CHANGE (v0.1.0 reconciliation): The previous SDK incorrectly exported these
 * values under the `Cycle` enum. Renamed to `Phase` to match Framework terminology.
 * The COR field `oem:cycle` (workspace.yaml) uses these values but names the field
 * "cycle" — this is a COR naming issue, not a Framework naming issue.
 */
export enum Phase {
  Bootstrap = 'Bootstrap',
  Hack = 'Hack',
  Sync = 'Sync',
  Finish = 'Finish',
  Ship = 'Ship',
  Validate = 'Validate',
  Promote = 'Promote',
  Rework = 'Rework',
}
