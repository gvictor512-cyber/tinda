import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
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

@Injectable()
export class ChatService {
  constructor(
    @InjectRepository(Message)
    private messagesRepository: Repository<Message>,
    @InjectRepository(Match)
    private matchesRepository: Repository<Match>,
    @InjectRepository(User)
    private usersRepository: Repository<User>,
    private notificationsService: NotificationsService,
  ) {}

  async createMessage(createMessageDto: CreateMessageDto) {
    const match = await this.matchesRepository.findOne({
      where: { id: createMessageDto.matchId },
    });

    if (!match) {
      throw new NotFoundException('Match not found');
    }

    // Verify sender is part of the match
    if (match.user1Id !== createMessageDto.senderId && match.user2Id !== createMessageDto.senderId) {
      throw new BadRequestException('Sender is not part of this match');
    }

    const receiverId = match.user1Id === createMessageDto.senderId ? match.user2Id : match.user1Id;

    const message = this.messagesRepository.create({
      matchId: createMessageDto.matchId,
      senderId: createMessageDto.senderId,
      receiverId,
      messageType: createMessageDto.messageType,
      content: createMessageDto.content,
      mediaUrl: createMessageDto.mediaUrl,
      locationData: createMessageDto.locationData,
      isRead: false,
    });

    return this.messagesRepository.save(message);
  }

  async getMatchMessages(matchId: string, userId: string, page: number = 1, limit: number = 50) {
    const match = await this.matchesRepository.findOne({
      where: { id: matchId },
    });

    if (!match) {
      throw new NotFoundException('Match not found');
    }

    // Verify user is part of the match
    if (match.user1Id !== userId && match.user2Id !== userId) {
      throw new BadRequestException('Access denied');
    }

    const safeLimit = Math.min(limit, 100);
    const skip = (Math.max(page, 1) - 1) * safeLimit;

    return this.messagesRepository.find({
      where: { matchId },
      order: { createdAt: 'ASC' },
      take: safeLimit,
      skip,
    });
  }

  async getMatch(matchId: string) {
    return this.matchesRepository.findOne({
      where: { id: matchId },
    });
  }

  async verifyMatchAccess(userId: string, matchId: string) {
    const match = await this.matchesRepository.findOne({
      where: { id: matchId },
    });

    if (!match) {
      return null;
    }

    if (match.user1Id !== userId && match.user2Id !== userId) {
      return null;
    }

    return match;
  }

  async markMessagesAsRead(matchId: string, userId: string) {
    const match = await this.matchesRepository.findOne({
      where: { id: matchId },
    });

    if (!match) {
      throw new NotFoundException('Match not found');
    }

    // Verify user is part of the match
    if (match.user1Id !== userId && match.user2Id !== userId) {
      throw new BadRequestException('Access denied');
    }

    // Mark messages from the other user as read
    const otherUserId = match.user1Id === userId ? match.user2Id : match.user1Id;

    await this.messagesRepository.update(
      {
        matchId,
        senderId: otherUserId,
        isRead: false,
      },
      { isRead: true },
    );

    return { success: true };
  }

  async sendNewMessageNotification(receiverId: string, senderId: string, matchId: string) {
    await this.notificationsService.sendNewMessageNotification(
      senderId,
      receiverId,
      senderId,
      matchId,
    );
  }

  async getUserConversations(userId: string, limit: number = 50) {
    const matches = await this.matchesRepository
      .createQueryBuilder('match')
      .where('(match.user1Id = :userId OR match.user2Id = :userId)', { userId })
      .andWhere('match.isActive = :isActive', { isActive: true })
      .orderBy('match.createdAt', 'DESC')
      .limit(Math.min(limit, 100))
      .getMany();

    const matchIds = matches.map((m) => m.id);

    const [lastMessages, unreadCounts] = await Promise.all([
      Promise.all(
        matchIds.map((matchId) =>
          this.messagesRepository.findOne({
            where: { matchId },
            order: { createdAt: 'DESC' },
          }),
        ),
      ),
      Promise.all(
        matchIds.map((matchId) =>
          this.messagesRepository.count({
            where: { matchId, receiverId: userId, isRead: false },
          }),
        ),
      ),
    ]);

    const conversations = matches.map((match, index) => ({
      matchId: match.id,
      otherUserId: match.user1Id === userId ? match.user2Id : match.user1Id,
      lastMessage: lastMessages[index],
      unreadCount: unreadCounts[index],
      compatibilityScore: match.compatibilityScore,
    }));

    return conversations;
  }
}
