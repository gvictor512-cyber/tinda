"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
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
const admin = __importStar(require("firebase-admin"));
let NotificationsService = class NotificationsService {
    constructor(notificationsRepository) {
        this.notificationsRepository = notificationsRepository;
    }
    async sendMatchNotification(senderId, userId, matchedUserId, matchId) {
        return this.sendToUser(senderId, userId, 'new_match', '¡Nuevo Match!', '¡Parece que podríais ser grandes compañeros de piso!', { matchedUserId, matchId });
    }
    async sendNewMessageNotification(senderId, userId, originalSenderId, matchId) {
        return this.sendToUser(senderId, userId, 'new_message', 'Nuevo mensaje', 'Tienes un nuevo mensaje', { originalSenderId, matchId });
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
    async _verifyRelationship(senderId, receiverId, notificationType) {
        const collection = notificationType === 'new_match' ? 'matches' : 'chats';
        const field = notificationType === 'new_match' ? 'users' : 'participants';
        const docs = await admin.firestore()
            .collection(collection)
            .where(field, 'array-contains', senderId)
            .get();
        const hasRelationship = docs.docs.some((doc) => {
            const list = doc.data()[field] || [];
            return list.includes(receiverId);
        });
        if (!hasRelationship) {
            throw new common_1.ForbiddenException('No estás autorizado para notificar a este usuario');
        }
    }
    async sendToUser(senderId, userId, notificationType, title, body, data) {
        await this._verifyRelationship(senderId, userId, notificationType);
        const notification = this.notificationsRepository.create({
            userId,
            notificationType,
            title,
            body,
            data,
        });
        await this.notificationsRepository.save(notification);
        try {
            const userDoc = await admin.firestore().collection('users').doc(userId).get();
            const fcmToken = userDoc.data()?.fcmToken;
            if (fcmToken) {
                const stringData = { type: notificationType };
                for (const [key, value] of Object.entries(data)) {
                    stringData[key] = typeof value === 'string' ? value : JSON.stringify(value);
                }
                await admin.messaging().send({
                    token: fcmToken,
                    notification: { title, body },
                    data: stringData,
                });
            }
        }
        catch (error) {
            console.error('Error sending FCM notification:', error);
        }
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