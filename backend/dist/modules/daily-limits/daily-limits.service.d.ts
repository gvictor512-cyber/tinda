import { Repository } from 'typeorm';
import { DailyLimits } from './entities/daily-limits.entity';
import { User } from '../users/entities/user.entity';
export declare class DailyLimitsService {
    private dailyLimitsRepository;
    private usersRepository;
    constructor(dailyLimitsRepository: Repository<DailyLimits>, usersRepository: Repository<User>);
    getDailyLimits(userId: string): Promise<{
        isPremium: boolean;
        likesUsed: number;
        likesRemaining: number;
        superLikesUsed: number;
        superLikesRemaining: number;
        boostsUsed: number;
        boostsRemaining: number;
    }>;
    incrementLikes(userId: string): Promise<{
        success: boolean;
        remaining: number;
    }>;
    incrementSuperLikes(userId: string): Promise<{
        success: boolean;
        remaining: number;
    }>;
    resetDailyLimits(): Promise<{
        success: boolean;
    }>;
}
