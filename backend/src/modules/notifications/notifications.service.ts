import { Injectable } from '@nestjs/common';
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

  async sendMatchNotification(userId: string, matchedUserId: string, matchId: string) {
    // Save to database
    const notification = this.notificationsRepository.create({
      userId,
      notificationType: 'new_match',
      title: '¡Nuevo Match!',
      body: '¡Parece que podríais ser grandes compañeros de piso!',
      data: {
        matchedUserId,
        matchId,
      },
    });

    await this.notificationsRepository.save(notification);

    // Send push notification via FCM
    // TODO: Get user's device token and send FCM notification
    try {
      // const user = await this.usersRepository.findOne({ where: { id: userId } });
      // if (user?.deviceToken) {
      //   await admin.messaging().send({
      //     token: user.deviceToken,
      //     notification: {
      //       title: '¡Nuevo Match!',
      //       body: '¡Parece que podríais ser grandes compañeros de piso!',
      //     },
      //     data: {
      //       matchId,
      //       type: 'new_match',
      //     },
      //   });
      // }
    } catch (error) {
      console.error('Error sending FCM notification:', error);
    }
  }

  async sendNewMessageNotification(userId: string, senderId: string, matchId: string) {
    const notification = this.notificationsRepository.create({
      userId,
      notificationType: 'new_message',
      title: 'Nuevo mensaje',
      body: 'Tienes un nuevo mensaje',
      data: {
        senderId,
        matchId,
      },
    });

    await this.notificationsRepository.save(notification);

    // Send FCM notification
    // TODO: Implement FCM sending
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
}
