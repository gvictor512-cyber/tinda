import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { ChatService } from './chat.service';
import { FirebaseAuthGuard } from '../../common/guards/auth.guard';

@WebSocketGateway({
  cors: {
    origin: '*',
  },
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  constructor(private readonly chatService: ChatService) {}

  async handleConnection(client: Socket) {
    try {
      const userId = client.handshake.auth.userId;
      if (userId) {
        client.join(`user_${userId}`);
        console.log(`User ${userId} connected`);
      }
    } catch (error) {
      client.disconnect();
    }
  }

  handleDisconnect(client: Socket) {
    console.log(`Client disconnected: ${client.id}`);
  }

  @SubscribeMessage('joinMatch')
  async handleJoinMatch(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { matchId: string },
  ) {
    const userId = client.handshake.auth.userId;
    
    // Verify user is part of the match
    const match = await this.chatService.verifyMatchAccess(userId, data.matchId);
    
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
    @MessageBody() data: {
      matchId: string;
      messageType: string;
      content?: string;
      mediaUrl?: string;
      locationData?: any;
    },
  ) {
    const userId = client.handshake.auth.userId;
    
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
      const receiverId = match.user1Id === userId ? match.user2Id : match.user1Id;
      
      const receiverSockets = await this.server.in(`user_${receiverId}`).allSockets();
      if (receiverSockets.size === 0) {
        // User is offline, send push notification
        await this.chatService.sendNewMessageNotification(receiverId, userId, data.matchId);
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
    const userId = client.handshake.auth.userId;
    
    await this.chatService.markMessagesAsRead(data.matchId, userId);
    
    // Notify other user
    const match = await this.chatService.getMatch(data.matchId);
    const otherUserId = match.user1Id === userId ? match.user2Id : match.user1Id;
    
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
    const userId = client.handshake.auth.userId;
    
    client.to(`match_${data.matchId}`).emit('userTyping', {
      matchId: data.matchId,
      userId,
      isTyping: data.isTyping,
    });
  }
}
