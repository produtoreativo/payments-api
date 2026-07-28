/**
 * Operational Cycle — the rhythm at which a Journey executes.
 * Canonical source: framework/journeys/delivery/ci-sync.md, ci-async.md,
 *                   framework/journeys/diligence/diligence-sync.md, diligence-async.md
 *
 * NOTE: The COR field `oem:cycle` (workspace.yaml) incorrectly contains Phase values
 * (Bootstrap, Hack, etc.). Those belong to the Phase enum, not here.
 */
export enum Cycle {
  CISync = 'CI Sync',
  CIAsync = 'CI Async',
  DiligenceSync = 'Diligence Sync',
  DiligenceAsync = 'Diligence Async',
}
