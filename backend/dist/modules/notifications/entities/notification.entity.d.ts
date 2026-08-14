export declare class Notification {
    id: string;
    userId: string;
    notificationType: string;
    title: string;
    body: string;
    data: Record<string, any>;
    isRead: boolean;
    createdAt: Date;
}
