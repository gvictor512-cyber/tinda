import { CompatibilityService, CompatibilityResult, FactorResult } from './compatibility.service';
export declare class CompatibilityController {
    private readonly compatibilityService;
    constructor(compatibilityService: CompatibilityService);
    calculateCompatibility(req: any, targetUserId: string): Promise<CompatibilityResult>;
    getCompatibilityScore(req: any, userId: string): Promise<CompatibilityResult>;
    getCompatibilityExplanation(req: any, userId: string): Promise<{
        score: number;
        explanation: string;
        factors: FactorResult[];
    }>;
    getRecommendations(req: any): Promise<any[]>;
}
