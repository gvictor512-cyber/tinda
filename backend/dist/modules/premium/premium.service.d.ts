import { Repository } from 'typeorm';
import { Subscription } from './entities/subscription.entity';
import { User } from '../users/entities/user.entity';
import { DailyLimits } from '../daily-limits/entities/daily-limits.entity';
import { CreateSubscriptionDto } from './dto/create-subscription.dto';
export declare class PremiumService {
    private subscriptionsRepository;
    private usersRepository;
    private dailyLimitsRepository;
    constructor(subscriptionsRepository: Repository<Subscription>, usersRepository: Repository<User>, dailyLimitsRepository: Repository<DailyLimits>);
    getPremiumStatus(firebaseUid: string): Promise<{
        isPremium: boolean;
        premiumExpiresAt: Date;
        subscription: {
            planType: string;
            startDate: Date;
            endDate: Date;
            autoRenew: boolean;
        };
    }>;
    getPremiumFeatures(): Promise<{
        free: {
            dailyLikes: number;
            dailySuperLikes: number;
            filters: string[];
            seeWhoLikedYou: boolean;
            profileBoost: boolean;
            invisibleMode: boolean;
        };
        premium: {
            dailyLikes: number;
            dailySuperLikes: number;
            filters: string[];
            seeWhoLikedYou: boolean;
            profileBoost: boolean;
            invisibleMode: boolean;
        };
    }>;
    createSubscription(firebaseUid: string, createSubscriptionDto: CreateSubscriptionDto): Promise<{
        success: boolean;
        subscription: Subscription;
        premiumExpiresAt: Date;
    }>;
    cancelSubscription(firebaseUid: string): Promise<{
        success: boolean;
        message: string;
    }>;
    getDailyLimits(firebaseUid: string): Promise<{
        isPremium: boolean;
        likesUsed: number;
        likesRemaining: number;
        superLikesUsed: number;
        superLikesRemaining: number;
        boostsUsed: number;
        boostsRemaining: number;
    }>;
    useLike(firebaseUid: string): Promise<{
        success: boolean;
        remaining: number;
    }>;
    useSuperLike(firebaseUid: string): Promise<{
        success: boolean;
        remaining: number;
    }>;
    boostProfile(firebaseUid: string): Promise<{
        success: boolean;
        message: string;
    }>;
}
