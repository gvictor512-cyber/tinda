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
exports.DailyLimitsService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const daily_limits_entity_1 = require("./entities/daily-limits.entity");
const user_entity_1 = require("../users/entities/user.entity");
let DailyLimitsService = class DailyLimitsService {
    constructor(dailyLimitsRepository, usersRepository) {
        this.dailyLimitsRepository = dailyLimitsRepository;
        this.usersRepository = usersRepository;
    }
    async getDailyLimits(userId) {
        const user = await this.usersRepository.findOne({
            where: { id: userId },
        });
        if (!user) {
            throw new Error('User not found');
        }
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        let dailyLimits = await this.dailyLimitsRepository.findOne({
            where: { userId, date: today },
        });
        if (!dailyLimits) {
            dailyLimits = this.dailyLimitsRepository.create({
                userId,
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
    async incrementLikes(userId) {
        const user = await this.usersRepository.findOne({
            where: { id: userId },
        });
        const isPremium = user.isPremium && (!user.premiumExpiresAt || user.premiumExpiresAt > new Date());
        if (isPremium) {
            return { success: true, remaining: -1 };
        }
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        let dailyLimits = await this.dailyLimitsRepository.findOne({
            where: { userId, date: today },
        });
        if (!dailyLimits) {
            dailyLimits = this.dailyLimitsRepository.create({
                userId,
                date: today,
                likesUsed: 0,
                superLikesUsed: 0,
                boostsUsed: 0,
            });
        }
        if (dailyLimits.likesUsed >= 10) {
            return { success: false, remaining: 0 };
        }
        dailyLimits.likesUsed++;
        await this.dailyLimitsRepository.save(dailyLimits);
        return { success: true, remaining: 10 - dailyLimits.likesUsed };
    }
    async incrementSuperLikes(userId) {
        const user = await this.usersRepository.findOne({
            where: { id: userId },
        });
        const isPremium = user.isPremium && (!user.premiumExpiresAt || user.premiumExpiresAt > new Date());
        if (isPremium) {
            return { success: true, remaining: -1 };
        }
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        let dailyLimits = await this.dailyLimitsRepository.findOne({
            where: { userId, date: today },
        });
        if (!dailyLimits) {
            dailyLimits = this.dailyLimitsRepository.create({
                userId,
                date: today,
                likesUsed: 0,
                superLikesUsed: 0,
                boostsUsed: 0,
            });
        }
        if (dailyLimits.superLikesUsed >= 1) {
            return { success: false, remaining: 0 };
        }
        dailyLimits.superLikesUsed++;
        await this.dailyLimitsRepository.save(dailyLimits);
        return { success: true, remaining: 1 - dailyLimits.superLikesUsed };
    }
    async resetDailyLimits() {
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const expiredLimits = await this.dailyLimitsRepository
            .createQueryBuilder('limits')
            .where('limits.date < :today', { today })
            .getMany();
        for (const limit of expiredLimits) {
            await this.dailyLimitsRepository.remove(limit);
        }
        return { success: true };
    }
};
exports.DailyLimitsService = DailyLimitsService;
exports.DailyLimitsService = DailyLimitsService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(daily_limits_entity_1.DailyLimits)),
    __param(1, (0, typeorm_1.InjectRepository)(user_entity_1.User)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository])
], DailyLimitsService);
//# sourceMappingURL=daily-limits.service.js.map