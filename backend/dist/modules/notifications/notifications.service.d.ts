import { Repository } from 'typeorm';
import { Notification } from './entities/notification.entity';
export declare class NotificationsService {
    private notificationsRepository;
    constructor(notificationsRepository: Repository<Notification>);
    sendMatchNotification(senderId: string, userId: string, matchedUserId: string, matchId: string): Promise<{
        success: boolean;
    }>;
    sendNewMessageNotification(senderId: string, userId: string, originalSenderId: string, matchId: string): Promise<{
        success: boolean;
    }>;
    getUserNotifications(userId: string, limit?: number): Promise<Notification[]>;
    markAsRead(notificationId: string): Promise<{
        success: boolean;
    }>;
    markAllAsRead(userId: string): Promise<{
        success: boolean;
    }>;
    private _verifyRelationship;
    sendToUser(senderId: string, userId: string, notificationType: string, title: string, body: string, data: Record<string, any>): Promise<{
        success: boolean;
    }>;
}
