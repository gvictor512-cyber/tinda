import { NotificationsService } from './notifications.service';
declare class SendNotificationDto {
    userId: string;
    title: string;
    body: string;
    data?: Record<string, any>;
}
export declare class NotificationsController {
    private readonly notificationsService;
    constructor(notificationsService: NotificationsService);
    getNotifications(req: any): Promise<import("./entities/notification.entity").Notification[]>;
    markAsRead(id: string): Promise<{
        success: boolean;
    }>;
    markAllAsRead(req: any): Promise<{
        success: boolean;
    }>;
    send(req: any, dto: SendNotificationDto): Promise<{
        success: boolean;
    }>;
}
export {};
