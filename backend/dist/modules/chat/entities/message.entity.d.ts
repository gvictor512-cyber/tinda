export declare class Message {
    id: string;
    matchId: string;
    senderId: string;
    receiverId: string;
    messageType: string;
    content: string;
    mediaUrl: string;
    locationData: Record<string, any>;
    isRead: boolean;
    createdAt: Date;
}
