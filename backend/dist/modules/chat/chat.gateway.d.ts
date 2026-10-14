import { OnGatewayConnection, OnGatewayDisconnect, OnGatewayInit } from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Repository } from 'typeorm';
import { ChatService } from './chat.service';
import { User } from '../users/entities/user.entity';
export declare class ChatGateway implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect {
    private readonly chatService;
    private readonly usersRepository;
    server: Server;
    constructor(chatService: ChatService, usersRepository: Repository<User>);
    private resolveUserId;
    afterInit(server: Server): Promise<void>;
    handleConnection(client: Socket): Promise<void>;
    handleDisconnect(client: Socket): void;
    handleJoinMatch(client: Socket, data: {
        matchId: string;
    }): Promise<void>;
    handleLeaveMatch(client: Socket, data: {
        matchId: string;
    }): Promise<void>;
    handleSendMessage(client: Socket, data: {
        matchId: string;
        messageType: string;
        content?: string;
        mediaUrl?: string;
        locationData?: any;
    }): Promise<import("./entities/message.entity").Message>;
    handleMarkAsRead(client: Socket, data: {
        matchId: string;
    }): Promise<void>;
    handleTyping(client: Socket, data: {
        matchId: string;
        isTyping: boolean;
    }): Promise<void>;
}
