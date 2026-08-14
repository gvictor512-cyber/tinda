import { Repository } from 'typeorm';
import { Message } from './entities/message.entity';
import { Match } from '../matches/entities/match.entity';
import { User } from '../users/entities/user.entity';
import { NotificationsService } from '../notifications/notifications.service';
interface CreateMessageDto {
    matchId: string;
    senderId: string;
    messageType: string;
    content?: string;
    mediaUrl?: string;
    locationData?: any;
}
export declare class ChatService {
    private messagesRepository;
    private matchesRepository;
    private usersRepository;
    private notificationsService;
    constructor(messagesRepository: Repository<Message>, matchesRepository: Repository<Match>, usersRepository: Repository<User>, notificationsService: NotificationsService);
    createMessage(createMessageDto: CreateMessageDto): Promise<Message>;
    getMatchMessages(matchId: string, userId: string, limit?: number): Promise<Message[]>;
    getMatch(matchId: string): Promise<Match>;
    verifyMatchAccess(userId: string, matchId: string): Promise<Match>;
    markMessagesAsRead(matchId: string, userId: string): Promise<{
        success: boolean;
    }>;
    sendNewMessageNotification(receiverId: string, senderId: string, matchId: string): Promise<void>;
    getUserConversations(userId: string): Promise<{
        matchId: string;
        otherUserId: string;
        lastMessage: Message;
        unreadCount: number;
        compatibilityScore: number;
    }[]>;
}
export {};
