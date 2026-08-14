import { Repository } from 'typeorm';
import { CompatibilitySettings } from './entities/compatibility-settings.entity';
import { Profile } from '../profiles/entities/profile.entity';
import { User } from '../users/entities/user.entity';
export interface CompatibilityResult {
    score: number;
    explanation: string;
    factors: FactorResult[];
}
export interface FactorResult {
    factor: string;
    weight: number;
    score: number;
    contribution: number;
    details: string;
}
export declare class CompatibilityService {
    private compatibilitySettingsRepository;
    private profilesRepository;
    private usersRepository;
    private calculator;
    constructor(compatibilitySettingsRepository: Repository<CompatibilitySettings>, profilesRepository: Repository<Profile>, usersRepository: Repository<User>);
    calculateCompatibility(firebaseUid: string, targetUserId: string): Promise<CompatibilityResult>;
    getRecommendations(firebaseUid: string, limit?: number): Promise<any[]>;
}
