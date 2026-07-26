export declare const FindingType: {
    readonly Drift: "Drift";
    readonly MissingEvidence: "MissingEvidence";
    readonly MissingEvent: "MissingEvent";
    readonly RuntimeError: "RuntimeError";
    readonly ManualReview: "ManualReview";
};
export type FindingType = (typeof FindingType)[keyof typeof FindingType];
export declare const FindingSeverity: {
    readonly High: "High";
    readonly Medium: "Medium";
    readonly Low: "Low";
};
export type FindingSeverity = (typeof FindingSeverity)[keyof typeof FindingSeverity];
export interface Finding {
    readonly id: string;
    readonly type: FindingType;
    readonly severity: FindingSeverity;
    readonly work_item_id: string;
    readonly description: string;
    readonly detected_at: string;
    readonly evidence?: string;
    readonly resolved: boolean;
    readonly resolved_at?: string;
}
//# sourceMappingURL=finding.d.ts.map