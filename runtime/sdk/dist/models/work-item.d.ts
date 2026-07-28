import type { Journey } from '../enums/journey.js';
export interface WorkItem {
    readonly id: string;
    readonly title: string;
    readonly repository: string;
    readonly feature: string;
    readonly obc: string;
    readonly release: string;
    readonly iteration: string;
    readonly journey: Journey;
}
//# sourceMappingURL=work-item.d.ts.map