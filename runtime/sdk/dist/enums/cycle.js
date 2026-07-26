/**
 * Operational Cycle — the rhythm at which a Journey executes.
 * Canonical source: framework/journeys/delivery/ci-sync.md, ci-async.md,
 *                   framework/journeys/diligence/diligence-sync.md, diligence-async.md
 *
 * NOTE: The COR field `oem:cycle` (workspace.yaml) incorrectly contains Phase values
 * (Bootstrap, Hack, etc.). Those belong to the Phase enum, not here.
 */
export var Cycle;
(function (Cycle) {
    Cycle["CISync"] = "CI Sync";
    Cycle["CIAsync"] = "CI Async";
    Cycle["DiligenceSync"] = "Diligence Sync";
    Cycle["DiligenceAsync"] = "Diligence Async";
})(Cycle || (Cycle = {}));
//# sourceMappingURL=cycle.js.map