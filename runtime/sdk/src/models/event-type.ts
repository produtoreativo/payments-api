/**
 * Namespaces permitted in Event Type identifiers (pilot scope: Delivery, Diligence, Assessment, Shared).
 * Full Framework namespaces include Discovery and Operation.
 * Canonical source: framework/events/taxonomy.md section 5.1
 */
export type EventNamespace = 'Delivery' | 'Diligence' | 'Assessment' | 'Shared' | 'Discovery' | 'Operation';

/**
 * Template literal enforcing the canonical Event Type naming convention:
 *   <Namespace>.<Subject>.<Action>[.<Qualifier>]
 *
 * Rules (taxonomy.md section 5.2):
 *   - All components in PascalCase
 *   - Namespace is required in all cross-journey references and in the RT SDK
 *   - Subject is the entity affected (e.g., Bootstrap, Gate, Impediment)
 *   - Action describes the fact in past tense (e.g., Started, Completed, Declared)
 *   - No technology references in any component
 *
 * This type constrains the namespace component at compile time.
 * Subject and Action are not further constrained here — validation is the catalog's responsibility.
 *
 * Examples: 'Delivery.Bootstrap.Started', 'Shared.Gate.Passed', 'Diligence.Drift.Detected'
 */
export type EventTypeId = `${EventNamespace}.${string}.${string}`;
