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
exports.NotificationsService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const notification_entity_1 = require("./entities/notification.entity");
let NotificationsService = class NotificationsService {
    constructor(notificationsRepository) {
        this.notificationsRepository = notificationsRepository;
    }
    async sendMatchNotification(userId, matchedUserId, matchId) {
        const notification = this.notificationsRepository.create({
            userId,
            notificationType: 'new_match',
            title: '¡Nuevo Match!',
            body: '¡Parece que podríais ser grandes compañeros de piso!',
            data: {
                matchedUserId,
                matchId,
            },
        });
        await this.notificationsRepository.save(notification);
        try {
        }
        catch (error) {
            console.error('Error sending FCM notification:', error);
        }
    }
    async sendNewMessageNotification(userId, senderId, matchId) {
        const notification = this.notificationsRepository.create({
            userId,
            notificationType: 'new_message',
            title: 'Nuevo mensaje',
            body: 'Tienes un nuevo mensaje',
            data: {
                senderId,
                matchId,
            },
        });
        await this.notificationsRepository.save(notification);
    }
    async getUserNotifications(userId, limit = 20) {
        return this.notificationsRepository.find({
            where: { userId },
            order: { createdAt: 'DESC' },
            take: limit,
        });
    }
    async markAsRead(notificationId) {
        await this.notificationsRepository.update(notificationId, { isRead: true });
        return { success: true };
    }
    async markAllAsRead(userId) {
        await this.notificationsRepository.update({ userId, isRead: false }, { isRead: true });
        return { success: true };
    }
};
exports.NotificationsService = NotificationsService;
exports.NotificationsService = NotificationsService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(notification_entity_1.Notification)),
    __metadata("design:paramtypes", [typeorm_2.Repository])
], NotificationsService);
//# sourceMappingURL=notifications.service.js.map