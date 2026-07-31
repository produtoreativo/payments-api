/** The 8 canonical Event Categories defined by the OEM Framework (taxonomy.md). Fixed — Journeys cannot add new categories. */
export enum EventCategory {
  PhaseLifecycle = 'Phase Lifecycle',
  Gate = 'Gate',
  HumanDecision = 'Human Decision',
  Blocking = 'Blocking',
  Rework = 'Rework',
  System = 'System',
  Diligence = 'Diligence',
  Correction = 'Correction',
}
