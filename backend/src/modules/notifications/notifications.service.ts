import { Injectable, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Notification } from './entities/notification.entity';
import * as admin from 'firebase-admin';

@Injectable()
export class NotificationsService {
  constructor(
    @InjectRepository(Notification)
    private notificationsRepository: Repository<Notification>,
  ) {}

  async sendMatchNotification(senderId: string, userId: string, matchedUserId: string, matchId: string) {
    return this.sendToUser(
      senderId,
      userId,
      'new_match',
      '¡Nuevo Match!',
      '¡Parece que podríais ser grandes compañeros de piso!',
      { matchedUserId, matchId },
    );
  }

  async sendNewMessageNotification(senderId: string, userId: string, originalSenderId: string, matchId: string) {
    return this.sendToUser(
      senderId,
      userId,
      'new_message',
      'Nuevo mensaje',
      'Tienes un nuevo mensaje',
      { originalSenderId, matchId },
    );
  }

  async getUserNotifications(userId: string, limit: number = 20) {
    return this.notificationsRepository.find({
      where: { userId },
      order: { createdAt: 'DESC' },
      take: limit,
    });
  }

  async markAsRead(notificationId: string) {
    await this.notificationsRepository.update(notificationId, { isRead: true });
    return { success: true };
  }

  async markAllAsRead(userId: string) {
    await this.notificationsRepository.update(
      { userId, isRead: false },
      { isRead: true },
    );
    return { success: true };
  }

  private async _verifyRelationship(
    senderId: string,
    receiverId: string,
    notificationType: string,
  ): Promise<void> {
    const collection = notificationType === 'new_match' ? 'matches' : 'chats';
    const field = notificationType === 'new_match' ? 'users' : 'participants';

    const docs = await admin.firestore()
      .collection(collection)
      .where(field, 'array-contains', senderId)
      .get();

    const hasRelationship = docs.docs.some((doc) => {
      const list = (doc.data()[field] as string[]) || [];
      return list.includes(receiverId);
    });

    if (!hasRelationship) {
      throw new ForbiddenException('No estás autorizado para notificar a este usuario');
    }
  }

  async sendToUser(
    senderId: string,
    userId: string,
    notificationType: string,
    title: string,
    body: string,
    data: Record<string, any>,
  ) {
    await this._verifyRelationship(senderId, userId, notificationType);

    const notification = this.notificationsRepository.create({
      userId,
      notificationType,
      title,
      body,
      data,
    });
    await this.notificationsRepository.save(notification);

    try {
      const userDoc = await admin.firestore().collection('users').doc(userId).get();
      const fcmToken = userDoc.data()?.fcmToken as string | undefined;

      if (fcmToken) {
        const stringData: Record<string, string> = { type: notificationType };
        for (const [key, value] of Object.entries(data)) {
          stringData[key] = typeof value === 'string' ? value : JSON.stringify(value);
        }

        await admin.messaging().send({
          token: fcmToken,
          notification: { title, body },
          data: stringData,
        });
      }
    } catch (error) {
      console.error('Error sending FCM notification:', error);
    }

    return { success: true };
  }
}
