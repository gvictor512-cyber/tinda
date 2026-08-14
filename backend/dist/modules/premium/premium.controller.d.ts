import { PremiumService } from './premium.service';
import { CreateSubscriptionDto } from './dto/create-subscription.dto';
export declare class PremiumController {
    private readonly premiumService;
    constructor(premiumService: PremiumService);
    getPremiumStatus(req: any): Promise<{
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
    subscribe(req: any, createSubscriptionDto: CreateSubscriptionDto): Promise<{
        success: boolean;
        subscription: import("./entities/subscription.entity").Subscription;
        premiumExpiresAt: Date;
    }>;
    cancelSubscription(req: any): Promise<{
        success: boolean;
        message: string;
    }>;
    getDailyLimits(req: any): Promise<{
        isPremium: boolean;
        likesUsed: number;
        likesRemaining: number;
        superLikesUsed: number;
        superLikesRemaining: number;
        boostsUsed: number;
        boostsRemaining: number;
    }>;
    boostProfile(req: any): Promise<{
        success: boolean;
        message: string;
    }>;
}
