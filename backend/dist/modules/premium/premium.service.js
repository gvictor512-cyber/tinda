"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.PremiumService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const subscription_entity_1 = require("./entities/subscription.entity");
const user_entity_1 = require("../users/entities/user.entity");
const daily_limits_entity_1 = require("../daily-limits/entities/daily-limits.entity");
let PremiumService = class PremiumService {
    constructor(subscriptionsRepository, usersRepository, dailyLimitsRepository) {
        this.subscriptionsRepository = subscriptionsRepository;
        this.usersRepository = usersRepository;
        this.dailyLimitsRepository = dailyLimitsRepository;
    }
    async getPremiumStatus(firebaseUid) {
        const user = await this.usersRepository.findOne({
            where: { firebaseUid },
        });
        if (!user) {
            throw new common_1.NotFoundException('User not found');
        }
        const subscription = await this.subscriptionsRepository.findOne({
            where: { userId: user.id, isActive: true },
        });
        return {
            isPremium: user.isPremium,
            premiumExpiresAt: user.premiumExpiresAt,
            subscription: subscription ? {
                planType: subscription.planType,
                startDate: subscription.startDate,
                endDate: subscription.endDate,
                autoRenew: subscription.autoRenew,
            } : null,
        };
    }
    async getPremiumFeatures() {
        return {
            free: {
                dailyLikes: 10,
                dailySuperLikes: 1,
                filters: ['basic'],
                seeWhoLikedYou: false,
                profileBoost: false,
                invisibleMode: false,
            },
            premium: {
                dailyLikes: -1,
                dailySuperLikes: -1,
                filters: ['advanced'],
                seeWhoLikedYou: true,
                profileBoost: true,
                invisibleMode: true,
            },
        };
    }
    async createSubscription(firebaseUid, createSubscriptionDto) {
        const user = await this.usersRepository.findOne({
            where: { firebaseUid },
        });
        if (!user) {
            throw new common_1.NotFoundException('User not found');
        }
        const existingSubscription = await this.subscriptionsRepository.findOne({
            where: { userId: user.id, isActive: true },
        });
        if (existingSubscription) {
            throw new common_1.BadRequestException('User already has an active subscription');
        }
        const startDate = new Date();
        const endDate = new Date();
        if (createSubscriptionDto.planType === 'premium_monthly') {
            endDate.setMonth(endDate.getMonth() + 1);
        }
        else if (createSubscriptionDto.planType === 'premium_yearly') {
            endDate.setFullYear(endDate.getFullYear() + 1);
        }
        const subscription = this.subscriptionsRepository.create({
            userId: user.id,
            planType: createSubscriptionDto.planType,
            startDate,
            endDate,
            isActive: true,
            autoRenew: createSubscriptionDto.autoRenew ?? false,
            paymentMethod: createSubscriptionDto.paymentMethod,
        });
        await this.subscriptionsRepository.save(subscription);
        user.isPremium = true;
        user.premiumExpiresAt = endDate;
        await this.usersRepository.save(user);
        return {
            success: true,
            subscription,
            premiumExpiresAt: endDate,
        };
    }
    async cancelSubscription(firebaseUid) {
        const user = await this.usersRepository.findOne({
            where: { firebaseUid },
        });
        if (!user) {
            throw new common_1.NotFoundException('User not found');
        }
        const subscription = await this.subscriptionsRepository.findOne({
            where: { userId: user.id, isActive: true },
        });
        if (!subscription) {
            throw new common_1.BadRequestException('No active subscription found');
        }
        subscription.isActive = false;
        subscription.autoRenew = false;
        await this.subscriptionsRepository.save(subscription);
        return { success: true, message: 'Subscription cancelled' };
    }
    async getDailyLimits(firebaseUid) {
        const user = await this.usersRepository.findOne({
            where: { firebaseUid },
        });
        if (!user) {
            throw new common_1.NotFoundException('User not found');
        }
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        let dailyLimits = await this.dailyLimitsRepository.findOne({
            where: { userId: user.id, date: today },
        });
        if (!dailyLimits) {
            dailyLimits = this.dailyLimitsRepository.create({
                userId: user.id,
                date: today,
                likesUsed: 0,
                superLikesUsed: 0,
                boostsUsed: 0,
            });
            await this.dailyLimitsRepository.save(dailyLimits);
        }
        const isPremium = user.isPremium && (!user.premiumExpiresAt || user.premiumExpiresAt > new Date());
        return {
            isPremium,
            likesUsed: dailyLimits.likesUsed,
            likesRemaining: isPremium ? -1 : 10 - dailyLimits.likesUsed,
            superLikesUsed: dailyLimits.superLikesUsed,
            superLikesRemaining: isPremium ? -1 : 1 - dailyLimits.superLikesUsed,
            boostsUsed: dailyLimits.boostsUsed,
            boostsRemaining: isPremium ? -1 : 0,
        };
    }
    async useLike(firebaseUid) {
        const user = await this.usersRepository.findOne({
            where: { firebaseUid },
        });
        if (!user) {
            throw new common_1.NotFoundException('User not found');
        }
        const isPremium = user.isPremium && (!user.premiumExpiresAt || user.premiumExpiresAt > new Date());
        if (isPremium) {
            return { success: true, remaining: -1 };
        }
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        let dailyLimits = await this.dailyLimitsRepository.findOne({
            where: { userId: user.id, date: today },
        });
        if (!dailyLimits) {
            dailyLimits = this.dailyLimitsRepository.create({
                userId: user.id,
                date: today,
                likesUsed: 0,
                superLikesUsed: 0,
                boostsUsed: 0,
            });
        }
        if (dailyLimits.likesUsed >= 10) {
            throw new common_1.BadRequestException('Daily like limit reached');
        }
        dailyLimits.likesUsed++;
        await this.dailyLimitsRepository.save(dailyLimits);
        return { success: true, remaining: 10 - dailyLimits.likesUsed };
    }
    async useSuperLike(firebaseUid) {
        const user = await this.usersRepository.findOne({
            where: { firebaseUid },
        });
        if (!user) {
            throw new common_1.NotFoundException('User not found');
        }
        const isPremium = user.isPremium && (!user.premiumExpiresAt || user.premiumExpiresAt > new Date());
        if (isPremium) {
            return { success: true, remaining: -1 };
        }
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        let dailyLimits = await this.dailyLimitsRepository.findOne({
            where: { userId: user.id, date: today },
        });
        if (!dailyLimits) {
            dailyLimits = this.dailyLimitsRepository.create({
                userId: user.id,
                date: today,
                likesUsed: 0,
                superLikesUsed: 0,
                boostsUsed: 0,
            });
        }
        if (dailyLimits.superLikesUsed >= 1) {
            throw new common_1.BadRequestException('Daily super like limit reached');
        }
        dailyLimits.superLikesUsed++;
        await this.dailyLimitsRepository.save(dailyLimits);
        return { success: true, remaining: 1 - dailyLimits.superLikesUsed };
    }
    async boostProfile(firebaseUid) {
        const user = await this.usersRepository.findOne({
            where: { firebaseUid },
        });
        if (!user) {
            throw new common_1.NotFoundException('User not found');
        }
        const isPremium = user.isPremium && (!user.premiumExpiresAt || user.premiumExpiresAt > new Date());
        if (!isPremium) {
            throw new common_1.BadRequestException('Boost is a premium feature');
        }
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        let dailyLimits = await this.dailyLimitsRepository.findOne({
            where: { userId: user.id, date: today },
        });
        if (!dailyLimits) {
            dailyLimits = this.dailyLimitsRepository.create({
                userId: user.id,
                date: today,
                likesUsed: 0,
                superLikesUsed: 0,
                boostsUsed: 0,
            });
        }
        dailyLimits.boostsUsed++;
        await this.dailyLimitsRepository.save(dailyLimits);
        return { success: true, message: 'Profile boosted for 30 minutes' };
    }
};
exports.PremiumService = PremiumService;
exports.PremiumService = PremiumService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(subscription_entity_1.Subscription)),
    __param(1, (0, typeorm_1.InjectRepository)(user_entity_1.User)),
    __param(2, (0, typeorm_1.InjectRepository)(daily_limits_entity_1.DailyLimits)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository])
], PremiumService);
//# sourceMappingURL=premium.service.js.map