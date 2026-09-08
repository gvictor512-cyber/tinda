import { Controller, Get, Post, Body, UseGuards, Request, Param, ParseUUIDPipe, HttpCode, HttpStatus } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { FirebaseAuthGuard } from '../../common/guards/auth.guard';

class SendNotificationDto {
  userId: string;
  title: string;
  body: string;
  data?: Record<string, any>;
}

@Controller('notifications')
@UseGuards(FirebaseAuthGuard)
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get()
  async getNotifications(@Request() req) {
    const user = req.user;
    // TODO: Get user ID from Firebase UID
    return this.notificationsService.getUserNotifications(user.uid);
  }

  @Post(':id/read')
  @HttpCode(HttpStatus.OK)
  async markAsRead(@Param('id', ParseUUIDPipe) id: string) {
    return this.notificationsService.markAsRead(id);
  }

  @Post('read-all')
  @HttpCode(HttpStatus.OK)
  async markAllAsRead(@Request() req) {
    const user = req.user;
    // TODO: Get user ID from Firebase UID
    return this.notificationsService.markAllAsRead(user.uid);
  }

  @Post('send')
  @HttpCode(HttpStatus.OK)
  async send(@Request() req, @Body() dto: SendNotificationDto) {
    const senderId = req.user?.uid ?? '';
    const notificationType = (dto.data?.type as string) || 'custom';
    return this.notificationsService.sendToUser(
      senderId,
      dto.userId,
      notificationType,
      dto.title,
      dto.body,
      dto.data ?? {},
    );
  }
}
