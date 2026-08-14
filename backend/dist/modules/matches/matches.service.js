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
exports.MatchesService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const match_entity_1 = require("./entities/match.entity");
const swipe_entity_1 = require("./entities/swipe.entity");
const user_entity_1 = require("../users/entities/user.entity");
const profile_entity_1 = require("../profiles/entities/profile.entity");
const compatibility_service_1 = require("../compatibility/compatibility.service");
const notifications_service_1 = require("../notifications/notifications.service");
let MatchesService = class MatchesService {
    constructor(matchesRepository, swipesRepository, usersRepository, profilesRepository, compatibilityService, notificationsService) {
        this.matchesRepository = matchesRepository;
        this.swipesRepository = swipesRepository;
        this.usersRepository = usersRepository;
        this.profilesRepository = profilesRepository;
        this.compatibilityService = compatibilityService;
        this.notificationsService = notificationsService;
    }
    async handleSwipe(firebaseUid, swipeDto) {
        const user = await this.usersRepository.findOne({
            where: { firebaseUid },
        });
        if (!user) {
            throw new common_1.NotFoundException('User not found');
        }
        const targetUser = await this.usersRepository.findOne({
            where: { id: swipeDto.targetUserId },
        });
        if (!targetUser) {
            throw new common_1.NotFoundException('Target user not found');
        }
        if (user.id === targetUser.id) {
            throw new common_1.BadRequestException('Cannot swipe yourself');
        }
        const existingSwipe = await this.swipesRepository.findOne({
            where: {
                swiperId: user.id,
                swipedId: targetUser.id,
            },
        });
        if (existingSwipe) {
            throw new common_1.BadRequestException('Already swiped this user');
        }
        const swipe = this.swipesRepository.create({
            swiperId: user.id,
            swipedId: targetUser.id,
            swipeType: swipeDto.type,
        });
        await this.swipesRepository.save(swipe);
        if (swipeDto.type === 'like' || swipeDto.type === 'super_like') {
            const reciprocalSwipe = await this.swipesRepository.findOne({
                where: {
                    swiperId: targetUser.id,
                    swipedId: user.id,
                    swipeType: ['like', 'super_like'],
                },
            });
            if (reciprocalSwipe) {
                return this.createMatch(user.id, targetUser.id);
            }
        }
        return { success: true, matched: false };
    }
    async createMatch(user1Id, user2Id) {
        const user1 = await this.usersRepository.findOne({ where: { id: user1Id } });
        const user2 = await this.usersRepository.findOne({ where: { id: user2Id } });
        const compatibility = await this.compatibilityService.calculateCompatibility(user1.firebaseUid, user2Id);
        const [smallerId, largerId] = [user1Id, user2Id].sort();
        const existingMatch = await this.matchesRepository.findOne({
            where: {
                user1Id: smallerId,
                user2Id: largerId,
            },
        });
        if (existingMatch) {
            return { success: true, matched: true, matchId: existingMatch.id };
        }
        const match = this.matchesRepository.create({
            user1Id: smallerId,
            user2Id: largerId,
            compatibilityScore: compatibility.score,
            compatibilityExplanation: compatibility.explanation,
        });
        const savedMatch = await this.matchesRepository.save(match);
        await this.notificationsService.sendMatchNotification(user1Id, user2Id, savedMatch.id);
        await this.notificationsService.sendMatchNotification(user2Id, user1Id, savedMatch.id);
        return {
            success: true,
            matched: true,
            matchId: savedMatch.id,
            compatibility: compatibility.score,
            explanation: compatibility.explanation,
        };
    }
    async getUserMatches(firebaseUid) {
        const user = await this.usersRepository.findOne({
            where: { firebaseUid },
        });
        if (!user) {
            throw new common_1.NotFoundException('User not found');
        }
        const matches = await this.matchesRepository
            .createQueryBuilder('match')
            .leftJoinAndSelect('match.user1', 'user1')
            .leftJoinAndSelect('match.user2', 'user2')
            .where('(match.user1Id = :userId OR match.user2Id = :userId)', { userId: user.id })
            .andWhere('match.isActive = :isActive', { isActive: true })
            .orderBy('match.createdAt', 'DESC')
            .getMany();
        const enrichedMatches = await Promise.all(matches.map(async (match) => {
            const otherUserId = match.user1Id === user.id ? match.user2Id : match.user1Id;
            const otherProfile = await this.profilesRepository.findOne({
                where: { userId: otherUserId },
                relations: ['user'],
            });
            return {
                ...match,
                otherUser: otherProfile,
            };
        }));
        return enrichedMatches;
    }
    async getMatch(firebaseUid, matchId) {
        const user = await this.usersRepository.findOne({
            where: { firebaseUid },
        });
        if (!user) {
            throw new common_1.NotFoundException('User not found');
        }
        const match = await this.matchesRepository.findOne({
            where: { id: matchId },
            relations: ['user1', 'user2'],
        });
        if (!match) {
            throw new common_1.NotFoundException('Match not found');
        }
        if (match.user1Id !== user.id && match.user2Id !== user.id) {
            throw new common_1.BadRequestException('Access denied');
        }
        const otherUserId = match.user1Id === user.id ? match.user2Id : match.user1Id;
        const otherProfile = await this.profilesRepository.findOne({
            where: { userId: otherUserId },
            relations: ['user'],
        });
        return {
            ...match,
            otherUser: otherProfile,
        };
    }
    async unmatch(firebaseUid, matchId) {
        const user = await this.usersRepository.findOne({
            where: { firebaseUid },
        });
        if (!user) {
            throw new common_1.NotFoundException('User not found');
        }
        const match = await this.matchesRepository.findOne({
            where: { id: matchId },
        });
        if (!match) {
            throw new common_1.NotFoundException('Match not found');
        }
        if (match.user1Id !== user.id && match.user2Id !== user.id) {
            throw new common_1.BadRequestException('Access denied');
        }
        match.isActive = false;
        await this.matchesRepository.save(match);
        return { message: 'Unmatched successfully' };
    }
    async getPendingLikes(firebaseUid) {
        const user = await this.usersRepository.findOne({
            where: { firebaseUid },
        });
        if (!user) {
            throw new common_1.NotFoundException('User not found');
        }
        const swipes = await this.swipesRepository
            .createQueryBuilder('swipe')
            .leftJoinAndSelect('swipe.swiper', 'swiper')
            .where('swipe.swipedId = :userId', { userId: user.id })
            .andWhere('swipe.swipeType IN (:...types)', { types: ['like', 'super_like'] })
            .getMany();
        const pendingLikes = [];
        for (const swipe of swipes) {
            const existingSwipe = await this.swipesRepository.findOne({
                where: {
                    swiperId: user.id,
                    swipedId: swipe.swiperId,
                },
            });
            if (!existingSwipe) {
                const profile = await this.profilesRepository.findOne({
                    where: { userId: swipe.swiperId },
                    relations: ['user'],
                });
                if (profile) {
                    pendingLikes.push({
                        profile,
                        swipeType: swipe.swipeType,
                        swipedAt: swipe.createdAt,
                    });
                }
            }
        }
        return pendingLikes;
    }
};
exports.MatchesService = MatchesService;
exports.MatchesService = MatchesService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(match_entity_1.Match)),
    __param(1, (0, typeorm_1.InjectRepository)(swipe_entity_1.Swipe)),
    __param(2, (0, typeorm_1.InjectRepository)(user_entity_1.User)),
    __param(3, (0, typeorm_1.InjectRepository)(profile_entity_1.Profile)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        compatibility_service_1.CompatibilityService,
        notifications_service_1.NotificationsService])
], MatchesService);
//# sourceMappingURL=matches.service.js.map