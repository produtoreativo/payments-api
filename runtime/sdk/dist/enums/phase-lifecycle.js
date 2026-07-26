/**
 * Phase lifecycle actions — what happened to a Phase.
 * Canonical source: framework/events/taxonomy.md (Phase Lifecycle category).
 *
 * BREAKING CHANGE (v0.1.0 reconciliation): Renamed from `PhaseAction` to `PhaseLifecycle`
 * to align with the OEM taxonomy category name. COR field `oem:phase` uses these values.
 */
export var PhaseLifecycle;
(function (PhaseLifecycle) {
    PhaseLifecycle["Started"] = "Started";
    PhaseLifecycle["Completed"] = "Completed";
})(PhaseLifecycle || (PhaseLifecycle = {}));
//# sourceMappingURL=phase-lifecycle.js.map