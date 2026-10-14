import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  OnGatewayConnection,
  OnGatewayDisconnect,
  OnGatewayInit,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { createClient } from 'redis';
import { createAdapter } from '@socket.io/redis-adapter';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ChatService } from './chat.service';
import { User } from '../users/entities/user.entity';
import { admin } from '../../common/config/firebase.config';

@WebSocketGateway({
  cors: {
    origin: process.env.CORS_ORIGIN?.split(',') ?? '*',
    credentials: true,
  },
})
export class ChatGateway
  implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer()
  server: Server;

  constructor(
    private readonly chatService: ChatService,
    @InjectRepository(User)
    private readonly usersRepository: Repository<User>,
  ) {}

  /**
   * Resolves the authenticated Postgres user id for a socket. The handshake
   * must carry a Firebase ID token (`auth.token`); the uid is mapped to the
   * internal users.id, which is what matches/messages store. Returns null
   * when the token is missing/invalid or the user has no account row.
   */
  private async resolveUserId(client: Socket): Promise<string | null> {
    const token = client.handshake.auth?.token as string | undefined;
    if (!token) return null;
    try {
      const decoded = await admin.auth().verifyIdToken(token);
      const user = await this.usersRepository.findOne({
        where: { firebaseUid: decoded.uid },
      });
      return user?.id ?? null;
    } catch {
      return null;
    }
  }

  async afterInit(server: Server) {
    const redisUrl = process.env.REDIS_URL;
    if (!redisUrl) {
      return;
    }

    const pubClient = createClient({ url: redisUrl });
    const subClient = pubClient.duplicate();

    await Promise.all([pubClient.connect(), subClient.connect()]);
    server.adapter(createAdapter(pubClient, subClient));
  }

  async handleConnection(client: Socket) {
    const userId = await this.resolveUserId(client);
    if (!userId) {
      client.disconnect(true);
      return;
    }
    client.data.userId = userId;
    client.join(`user_${userId}`);
  }

  handleDisconnect(client: Socket) {
    console.log(`Client disconnected: ${client.id}`);
  }

  @SubscribeMessage('joinMatch')
  async handleJoinMatch(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { matchId: string },
  ) {
    const userId = client.data.userId as string;

    // Verify user is part of the match
    const match = await this.chatService.verifyMatchAccess(
      userId,
      data.matchId,
    );

    if (match) {
      client.join(`match_${data.matchId}`);
      client.emit('joinedMatch', { matchId: data.matchId });
    } else {
      client.emit('error', { message: 'Access denied' });
    }
  }

  @SubscribeMessage('leaveMatch')
  async handleLeaveMatch(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { matchId: string },
  ) {
    client.leave(`match_${data.matchId}`);
    client.emit('leftMatch', { matchId: data.matchId });
  }

  @SubscribeMessage('sendMessage')
  async handleSendMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody()
    data: {
      matchId: string;
      messageType: string;
      content?: string;
      mediaUrl?: string;
      locationData?: any;
    },
  ) {
    const userId = client.data.userId as string;

    try {
      const message = await this.chatService.createMessage({
        matchId: data.matchId,
        senderId: userId,
        messageType: data.messageType,
        content: data.content,
        mediaUrl: data.mediaUrl,
        locationData: data.locationData,
      });

      // Send to all users in the match room
      this.server.to(`match_${data.matchId}`).emit('newMessage', message);

      // Send notification to receiver if not in room
      const match = await this.chatService.getMatch(data.matchId);
      const receiverId =
        match.user1Id === userId ? match.user2Id : match.user1Id;

      const receiverSockets = await this.server
        .in(`user_${receiverId}`)
        .allSockets();
      if (receiverSockets.size === 0) {
        // User is offline, send push notification
        await this.chatService.sendNewMessageNotification(
          receiverId,
          userId,
          data.matchId,
        );
      }

      return message;
    } catch (error) {
      client.emit('error', { message: 'Failed to send message' });
    }
  }

  @SubscribeMessage('markAsRead')
  async handleMarkAsRead(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { matchId: string },
  ) {
    const userId = client.data.userId as string;

    await this.chatService.markMessagesAsRead(data.matchId, userId);

    // Notify other user
    const match = await this.chatService.getMatch(data.matchId);
    const otherUserId =
      match.user1Id === userId ? match.user2Id : match.user1Id;

    this.server.to(`match_${data.matchId}`).emit('messagesRead', {
      matchId: data.matchId,
      userId,
    });
  }

  @SubscribeMessage('typing')
  async handleTyping(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { matchId: string; isTyping: boolean },
  ) {
    const userId = client.data.userId as string;

    client.to(`match_${data.matchId}`).emit('userTyping', {
      matchId: data.matchId,
      userId,
      isTyping: data.isTyping,
    });
  }
}
