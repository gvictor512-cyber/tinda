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
exports.CompatibilityService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const compatibility_settings_entity_1 = require("./entities/compatibility-settings.entity");
const profile_entity_1 = require("../profiles/entities/profile.entity");
const user_entity_1 = require("../users/entities/user.entity");
const compatibility_calculator_1 = require("./algorithm/compatibility-calculator");
let CompatibilityService = class CompatibilityService {
    constructor(compatibilitySettingsRepository, profilesRepository, usersRepository) {
        this.compatibilitySettingsRepository = compatibilitySettingsRepository;
        this.profilesRepository = profilesRepository;
        this.usersRepository = usersRepository;
        this.calculator = new compatibility_calculator_1.CompatibilityCalculator();
    }
    async calculateCompatibility(firebaseUid, targetUserId) {
        const user = await this.usersRepository.findOne({
            where: { firebaseUid },
        });
        if (!user) {
            throw new common_1.NotFoundException('User not found');
        }
        const targetUser = await this.usersRepository.findOne({
            where: { id: targetUserId },
        });
        if (!targetUser) {
            throw new common_1.NotFoundException('Target user not found');
        }
        const userSettings = await this.compatibilitySettingsRepository.findOne({
            where: { userId: user.id },
        });
        const targetSettings = await this.compatibilitySettingsRepository.findOne({
            where: { userId: targetUser.id },
        });
        const userProfile = await this.profilesRepository.findOne({
            where: { userId: user.id },
        });
        const targetProfile = await this.profilesRepository.findOne({
            where: { userId: targetUser.id },
        });
        return this.calculator.calculate({
            settings: userSettings,
            profile: userProfile,
        }, {
            settings: targetSettings,
            profile: targetProfile,
        });
    }
    async getRecommendations(firebaseUid, limit = 20) {
        const user = await this.usersRepository.findOne({
            where: { firebaseUid },
        });
        if (!user) {
            throw new common_1.NotFoundException('User not found');
        }
        const userProfile = await this.profilesRepository.findOne({
            where: { userId: user.id },
        });
        if (!userProfile) {
            throw new common_1.NotFoundException('User profile not found');
        }
        const potentialMatches = await this.profilesRepository.find({
            where: { city: userProfile.city },
            relations: ['user'],
            take: limit * 2,
        });
        const recommendations = [];
        for (const match of potentialMatches) {
            if (match.userId === user.id)
                continue;
            const compatibility = await this.calculateCompatibility(firebaseUid, match.userId);
            recommendations.push({
                profile: match,
                compatibility: compatibility.score,
                explanation: compatibility.explanation,
            });
        }
        recommendations.sort((a, b) => b.compatibility - a.compatibility);
        return recommendations.slice(0, limit);
    }
};
exports.CompatibilityService = CompatibilityService;
exports.CompatibilityService = CompatibilityService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(compatibility_settings_entity_1.CompatibilitySettings)),
    __param(1, (0, typeorm_1.InjectRepository)(profile_entity_1.Profile)),
    __param(2, (0, typeorm_1.InjectRepository)(user_entity_1.User)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository])
], CompatibilityService);
//# sourceMappingURL=compatibility.service.js.map