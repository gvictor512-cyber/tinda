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
exports.ChatService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const message_entity_1 = require("./entities/message.entity");
const match_entity_1 = require("../matches/entities/match.entity");
const user_entity_1 = require("../users/entities/user.entity");
const notifications_service_1 = require("../notifications/notifications.service");
let ChatService = class ChatService {
    constructor(messagesRepository, matchesRepository, usersRepository, notificationsService) {
        this.messagesRepository = messagesRepository;
        this.matchesRepository = matchesRepository;
        this.usersRepository = usersRepository;
        this.notificationsService = notificationsService;
    }
    async createMessage(createMessageDto) {
        const match = await this.matchesRepository.findOne({
            where: { id: createMessageDto.matchId },
        });
        if (!match) {
            throw new common_1.NotFoundException('Match not found');
        }
        if (match.user1Id !== createMessageDto.senderId && match.user2Id !== createMessageDto.senderId) {
            throw new common_1.BadRequestException('Sender is not part of this match');
        }
        const receiverId = match.user1Id === createMessageDto.senderId ? match.user2Id : match.user1Id;
        const message = this.messagesRepository.create({
            matchId: createMessageDto.matchId,
            senderId: createMessageDto.senderId,
            receiverId,
            messageType: createMessageDto.messageType,
            content: createMessageDto.content,
            mediaUrl: createMessageDto.mediaUrl,
            locationData: createMessageDto.locationData,
            isRead: false,
        });
        return this.messagesRepository.save(message);
    }
    async getMatchMessages(matchId, userId, page = 1, limit = 50) {
        const match = await this.matchesRepository.findOne({
            where: { id: matchId },
        });
        if (!match) {
            throw new common_1.NotFoundException('Match not found');
        }
        if (match.user1Id !== userId && match.user2Id !== userId) {
            throw new common_1.BadRequestException('Access denied');
        }
        const safeLimit = Math.min(limit, 100);
        const skip = (Math.max(page, 1) - 1) * safeLimit;
        return this.messagesRepository.find({
            where: { matchId },
            order: { createdAt: 'ASC' },
            take: safeLimit,
            skip,
        });
    }
    async getMatch(matchId) {
        return this.matchesRepository.findOne({
            where: { id: matchId },
        });
    }
    async verifyMatchAccess(userId, matchId) {
        const match = await this.matchesRepository.findOne({
            where: { id: matchId },
        });
        if (!match) {
            return null;
        }
        if (match.user1Id !== userId && match.user2Id !== userId) {
            return null;
        }
        return match;
    }
    async markMessagesAsRead(matchId, userId) {
        const match = await this.matchesRepository.findOne({
            where: { id: matchId },
        });
        if (!match) {
            throw new common_1.NotFoundException('Match not found');
        }
        if (match.user1Id !== userId && match.user2Id !== userId) {
            throw new common_1.BadRequestException('Access denied');
        }
        const otherUserId = match.user1Id === userId ? match.user2Id : match.user1Id;
        await this.messagesRepository.update({
            matchId,
            senderId: otherUserId,
            isRead: false,
        }, { isRead: true });
        return { success: true };
    }
    async sendNewMessageNotification(receiverId, senderId, matchId) {
        await this.notificationsService.sendNewMessageNotification(senderId, receiverId, senderId, matchId);
    }
    async getUserConversations(userId, limit = 50) {
        const matches = await this.matchesRepository
            .createQueryBuilder('match')
            .where('(match.user1Id = :userId OR match.user2Id = :userId)', { userId })
            .andWhere('match.isActive = :isActive', { isActive: true })
            .orderBy('match.createdAt', 'DESC')
            .limit(Math.min(limit, 100))
            .getMany();
        const matchIds = matches.map((m) => m.id);
        const [lastMessages, unreadCounts] = await Promise.all([
            Promise.all(matchIds.map((matchId) => this.messagesRepository.findOne({
                where: { matchId },
                order: { createdAt: 'DESC' },
            }))),
            Promise.all(matchIds.map((matchId) => this.messagesRepository.count({
                where: { matchId, receiverId: userId, isRead: false },
            }))),
        ]);
        const conversations = matches.map((match, index) => ({
            matchId: match.id,
            otherUserId: match.user1Id === userId ? match.user2Id : match.user1Id,
            lastMessage: lastMessages[index],
            unreadCount: unreadCounts[index],
            compatibilityScore: match.compatibilityScore,
        }));
        return conversations;
    }
};
exports.ChatService = ChatService;
exports.ChatService = ChatService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(message_entity_1.Message)),
    __param(1, (0, typeorm_1.InjectRepository)(match_entity_1.Match)),
    __param(2, (0, typeorm_1.InjectRepository)(user_entity_1.User)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        notifications_service_1.NotificationsService])
], ChatService);
//# sourceMappingURL=chat.service.js.map