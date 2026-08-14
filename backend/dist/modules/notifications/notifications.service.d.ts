import { Repository } from 'typeorm';
import { Notification } from './entities/notification.entity';
export declare class NotificationsService {
    private notificationsRepository;
    constructor(notificationsRepository: Repository<Notification>);
    sendMatchNotification(userId: string, matchedUserId: string, matchId: string): Promise<void>;
    sendNewMessageNotification(userId: string, senderId: string, matchId: string): Promise<void>;
    getUserNotifications(userId: string, limit?: number): Promise<Notification[]>;
    markAsRead(notificationId: string): Promise<{
        success: boolean;
    }>;
    markAllAsRead(userId: string): Promise<{
        success: boolean;
    }>;
}
