import { CompatibilitySettings } from '../entities/compatibility-settings.entity';
import { Profile } from '../../profiles/entities/profile.entity';
interface UserData {
    settings: CompatibilitySettings;
    profile: Profile;
}
interface FactorResult {
    factor: string;
    weight: number;
    score: number;
    contribution: number;
    details: string;
}
interface CompatibilityResult {
    score: number;
    explanation: string;
    factors: FactorResult[];
}
export declare class CompatibilityCalculator {
    private weights;
    calculate(user1: UserData, user2: UserData): CompatibilityResult;
    private calculateScheduleCompatibility;
    private calculateCleanlinessCompatibility;
    private calculateSmokingCompatibility;
    private calculatePetsCompatibility;
    private calculatePersonalityCompatibility;
    private calculateGuestsCompatibility;
    private calculateCookingCompatibility;
    private calculateMusicCompatibility;
    private calculateWorkFromHomeCompatibility;
    private generateExplanation;
}
export {};
