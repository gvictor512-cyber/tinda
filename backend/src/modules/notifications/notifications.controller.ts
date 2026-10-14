import {
  Controller,
  Get,
  Post,
  Body,
  UseGuards,
  Request,
  Param,
  ParseUUIDPipe,
  HttpCode,
  HttpStatus,
  BadRequestException,
} from '@nestjs/common';
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
    // Only relationship-verified types are allowed — an arbitrary "custom"
    // type would bypass _verifyRelationship and let anyone push phishing
    // notifications to users they have no connection with.
    const notificationType = (dto.data?.type as string) || '';
    if (!['new_match', 'new_message'].includes(notificationType)) {
      throw new BadRequestException('Unsupported notification type');
    }
    return this.notificationsService.sendToUser(
      senderId,
      dto.userId,
      notificationType,
      dto.title?.slice(0, 200) ?? '',
      dto.body?.slice(0, 500) ?? '',
      dto.data ?? {},
    );
  }
}
